# test/test_sky_anchor.jl — sky anchor boundary: gates, static coupling, dynamics
#
# Repo-grounded specs under test:
# - RigidSkyAnchor reproduces stack_tension_profile output bit-for-bit.
# - Mode gates: f_p report only, f_whirl and f_ax at soft EA hard gates.
# - Free decay matches sqrt(T_b0 / (m_eff L)).  The direction rebuilds each step.
# - Energy ledger stays <= 0 across slack crossings.
# - Slack events report dwell times.  Sustained slack is flagged.

# Frequency from zero crossings of a sampled signal. Returns (freq, n_cross).
function _sa_zero_crossing_frequency(t, x)
    crossings = Float64[]
    for i in 1:(length(x) - 1)
        if (x[i] < 0.0) != (x[i + 1] < 0.0)
            tcross = t[i] + (t[i + 1] - t[i]) * (-x[i]) / (x[i + 1] - x[i])
            push!(crossings, tcross)
        end
    end
    n = length(crossings)
    n < 2 && return (0.0, n)
    span = crossings[end] - crossings[1]
    return ((n - 1) / (2 * span), n)
end

@testset "SkyAnchorBoundary" begin

    # 6 mm Dyneema backline, 20 m.  Lumped backline mass at A.
    mb3 = line_mass_per_m(0.006, 970.0) * 20.0 / 3.0

    @testset "SingleBacklineSkyAnchor construction" begin
        b = SingleBacklineSkyAnchor(
            50.0, (0.0, 0.0, 30.0), 20.0; EA_b=1.0e6, I_t=12.6, pretension=0.0
        )

        @test b.anchor_mass == 50.0
        @test b.backline_anchor == (0.0, 0.0, 30.0)
        @test b.L_b0 == 20.0
        @test b.EA_b == 1.0e6
        @test b.EA_soft_factor == 0.25      # constructional stretch multiplier
        @test b.backline_diameter == 0.006  # 6 mm default
        @test b.line_density == 970.0       # Dyneema
        @test b.pretension == 0.0
        @test b.c_b > 0.0                   # axial damping from zeta_b default
        @test b.c_lat > 0.0                 # swing damping from zeta_p default

        # Explicit damping overrides the ratio defaults.
        b2 = SingleBacklineSkyAnchor(
            50.0, (0.0, 0.0, 30.0), 20.0; EA_b=1.0e6, I_t=12.6, c_b=12.0, c_lat=3.0
        )
        @test b2.c_b == 12.0
        @test b2.c_lat == 3.0

        @test_throws AssertionError SingleBacklineSkyAnchor(
            -1.0, (0.0, 0.0, 30.0), 20.0; EA_b=1.0e6, I_t=12.6
        )
    end

    @testset "derived quantities" begin
        b = SingleBacklineSkyAnchor(50.0, (0.0, 0.0, 30.0), 20.0; EA_b=1.0e6, I_t=12.6)

        @test backline_mass(b) ≈ 0.0274261 * 20.0 rtol=1e-6
        @test anchor_effective_mass(b) ≈ 50.0 + mb3 rtol=1e-12
        @test backline_stiffness(b) == 50_000.0        # EA / L
        @test soft_backline_stiffness(b) == 12_500.0   # 0.25 x elastic
        @test backline_tension_static(b) ≈ 50.0 * 9.81 rtol=1e-12
    end

    @testset "mode frequencies — pinned values" begin
        # m_eff = 20 kg and T_b0 = m_eff g, so f_p = sqrt(g/L) / 2pi.
        b = SingleBacklineSkyAnchor(
            20.0 - mb3, (0.0, 0.0, 30.0), 20.0; EA_b=1.0e6, I_t=12.6, pretension=mb3 * 9.81
        )

        @test anchor_effective_mass(b) ≈ 20.0 rtol=1e-12
        @test anchor_pendulum_frequency(b) ≈ 0.11147 atol=1e-4
        @test anchor_axial_frequency(b) ≈ 7.9577 atol=1e-3            # EA = 1 MN
        @test anchor_axial_frequency(b; soft=true) ≈ 3.9789 atol=1e-3 # EA = 250 kN
        @test anchor_pendulum_frequency(b; heavy=true) ≈ 0.13652 atol=2e-4
    end

    @testset "whirl gate — pinned thresholds" begin
        @test whirl_stiffness_required(12.6, 45.0; n_blades=3) ≈ 2073.3 rtol=1e-3
        @test whirl_stiffness_required(12.6, 121.0; n_blades=3) ≈ 14990.5 rtol=1e-3

        # The free pivot puts the fast whirl root at 2/rev.  At n_b = 3 the
        # 3/rev BPF gives sep = 1/3.  That clears the 0.300 rule by one
        # point.  At n_b = 2 the root sat on the 2/rev BPF and failed.
        bpf3 = blade_passing_frequency(45.0; n_blades=3)
        @test abs(whirl_frequency(0.0, 12.6, 45.0) - bpf3) / bpf3 ≈ 1 / 3 rtol=1e-9

        k_req = whirl_stiffness_required(12.6, 45.0; n_blades=3)
        @test whirl_frequency(k_req, 12.6, 45.0) ≈ 1.3 * bpf3 rtol=1e-9

        # Slow root sits at 1.9 omega at the threshold.  It reaches 1P at
        # k_mom = 3 I_t omega^2.
        omega = 2pi * 45.0 / 60.0
        @test whirl_precession_frequency(k_req, 12.6, 45.0) ≈ 1.9 * omega / (2pi) rtol=1e-9
        @test whirl_precession_frequency(3.0 * 12.6 * omega^2, 12.6, 45.0) ≈ 45.0 / 60.0 rtol=1e-9

        # BPF and 1P of the machine.
        @test blade_passing_frequency(45.0) == 1.5
        @test blade_passing_frequency(45.0; n_blades=3) == 2.25
    end

    @testset "rotor 1P from estimated autorotation" begin
        r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0)
        @test rotor_1p_frequency(r, 8.0, 50.0) ≈
            estimated_autorotation_rpm(r, 8.0, 50.0) / 60.0
    end

    @testset "anchor_mode_report fields" begin
        b = SingleBacklineSkyAnchor(
            20.0 - mb3,
            (0.0, 0.0, 30.0),
            20.0;
            EA_b=1.0e6,
            I_t=12.6,
            k_mom=3000.0,
            pretension=mb3 * 9.81,
        )
        rep = anchor_mode_report(b; rpm=45.0, n_blades=3)

        @test rep.bpf == 2.25
        @test rep.f_1p == 0.75
        @test rep.f_p ≈ 0.11147 atol=1e-4
        @test rep.k_mom_required ≈ 2073.3 rtol=1e-3
        @test rep.sep_whirl_bpf ≥ 0.3     # k_mom = 3,000 clears the whirl gate
        @test rep.sep_p_bpf > 0.9         # pendulum is far from BPF, report only
    end

    @testset "anchor_gate verdicts" begin
        make_b =
            (; k_mom=0.0, EA_b=1.0e6) -> SingleBacklineSkyAnchor(
                20.0 - mb3,
                (0.0, 0.0, 30.0),
                20.0;
                EA_b=EA_b,
                I_t=12.6,
                k_mom=k_mom,
                pretension=mb3 * 9.81,
            )

        # 45 rpm: the stiff side clears with k_mom = 3,000, axial clears with
        # the stiff rope.
        g1 = anchor_gate(make_b(k_mom=3000.0); rpm=45.0, n_blades=3)
        @test g1.ok
        @test g1.whirl_pass && g1.axial_pass

        # The free pivot clears the 0.300 rule at n_b = 3 (sep = 1/3).  At
        # n_b = 2 it sat on the 2/rev BPF and failed.
        g2 = anchor_gate(make_b(k_mom=0.0); rpm=45.0, n_blades=3)
        @test g2.ok
        @test g2.whirl_pass

        # The old 600 pin sits inside the fail band (58.8 to 2,073.3).
        g3 = anchor_gate(make_b(k_mom=600.0); rpm=45.0, n_blades=3)
        @test !g3.ok
        @test !g3.whirl_pass

        # 121 rpm: 3,500 sits inside the fail band (424.8 to 14,990.5).  The
        # 1 MN rope clears axial now that the 3/rev BPF (6.05 Hz) is off the
        # 3.98 Hz soft-EA mode.
        g4 = anchor_gate(make_b(k_mom=3500.0, EA_b=1.0e6); rpm=121.0, n_blades=3)
        @test !g4.ok
        @test !g4.whirl_pass && g4.axial_pass

        # 121 rpm: the stiff rail (k_mom ≥ 14,990) clears with the 400 kN
        # rope.
        g5 = anchor_gate(make_b(k_mom=20000.0, EA_b=4.0e5); rpm=121.0, n_blades=3)
        @test g5.ok
    end

    @testset "RigidSkyAnchor — bit-for-bit passthrough" begin
        r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
        stack = AutogyroStack([r, r], [10.0, 15.0], 0.004, 55.0)

        p0 = stack_tension_profile(stack, 1.225, 8.0)
        p1 = stack_tension_profile(stack, 1.225, 8.0; boundary=RigidSkyAnchor())
        @test p1 == p0
        @test p1[1] === 0.0

        # Fixed anchor position does not change the profile.
        p2 = stack_tension_profile(
            stack, 1.225, 8.0; boundary=RigidSkyAnchor((1.0, 2.0, 3.0))
        )
        @test p2 == p0

        q0 = stack_tension_profile_polygon(stack, 1.225, 8.0)
        q1 = stack_tension_profile_polygon(stack, 1.225, 8.0; boundary=RigidSkyAnchor())
        @test q1 == q0
        @test q1[1] === 0.0
    end

    @testset "anchor-segment tension flows into the profile" begin
        r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
        stack = AutogyroStack([r, r], [10.0, 15.0], 0.004, 55.0)
        p0 = stack_tension_profile(stack, 1.225, 8.0)

        b = SingleBacklineSkyAnchor(
            50.0, (0.0, 0.0, 30.0), 20.0; EA_b=1.0e6, I_t=12.6, pretension=600.0
        )

        # Default: mean stack pull at A is zero, so the segment stays slack.
        @test anchor_segment_tension(b) == 0.0

        # Backline payout lets the kite load the segment.  KTD furl mechanism:
        # relaxing the backline raises the anchor and tensions the segment.
        ta = anchor_segment_tension(b; backline_tension=100.0)
        @test ta ≈ 600.0 - 100.0 - 50.0 * 9.81 atol=1e-9
        @test ta ≈ 9.5 atol=1e-9

        p2 = stack_tension_profile(stack, 1.225, 8.0; boundary=b, anchor_segment=ta)
        @test p2[1] ≈ ta rtol=1e-12
        @test all(p2[2:end] .≈ p0[2:end] .+ ta)

        # The tension-only rule clamps a negative sum to zero.
        @test anchor_segment_tension(b; backline_tension=10_000.0) == 0.0
    end

    @testset "swing free decay matches sqrt(T_b0 / (m_eff L))" begin
        b = SingleBacklineSkyAnchor(
            50.0,
            (0.0, 0.0, 30.0),
            20.0;
            EA_b=1.0e6,
            I_t=12.6,
            pretension=mb3 * 9.81,
            zeta_p=0.05,
        )

        meff = anchor_effective_mass(b)
        T_b0 = backline_tension_static(b)
        eps0 = T_b0 / backline_stiffness(b)
        z_eq = 30.0 - (b.L_b0 + eps0)

        sim = simulate_anchor(
            b; r0=[0.5, 0.0, z_eq], v0=[0.0, 0.0, 0.0], tspan=(0.0, 55.0), dt=0.002
        )

        freq, n_cross = _sa_zero_crossing_frequency(sim.t, [p[1] for p in sim.r])
        f_expected = sqrt(T_b0 / (meff * b.L_b0)) / (2pi)

        @test n_cross ≥ 10          # a frozen direction would drift, not oscillate
        @test freq ≈ f_expected rtol=0.02
        @test freq ≈ 0.1115 atol=3.0e-3

        # Smooth regime: the ledger closes to near machine precision.
        led = energy_ledger(sim)
        @test led.ok
        @test led.max_gain ≤ 1.0e-6
        @test led.max_residual ≤ 1.0e-5
    end

    @testset "triangulated dual backline adds lateral stiffness" begin
        s = SingleBacklineSkyAnchor(
            50.0,
            (0.0, 0.0, 30.0),
            20.0;
            EA_b=1.0e6,
            I_t=12.6,
            pretension=mb3 * 9.81,
            zeta_p=0.05,
        )
        k_lat = 25.0
        t = TriangulatedDualBacklineSkyAnchor(s, k_lat)

        # Unit check: the lateral spring pulls toward the vertical axis.
        r = [0.5, 0.0, 10.0]
        v = [0.0, 0.0, 0.0]
        a_s = anchor_acceleration(s, r, v)
        a_t = anchor_acceleration(t, r, v)
        meff = anchor_effective_mass(s)
        @test a_t[1] - a_s[1] ≈ -k_lat * 0.5 / meff rtol=1e-9
        @test a_t[2] ≈ a_s[2]

        # Swing frequency rises by sqrt(1 + k_lat L / T) for a taut line.
        T_b0 = backline_tension_static(s)
        k_lat2 = T_b0 / s.L_b0          # this choice gives f_tri = sqrt(2) f0
        t2 = TriangulatedDualBacklineSkyAnchor(s, k_lat2)
        eps0 = T_b0 / backline_stiffness(s)
        z_eq = 30.0 - (s.L_b0 + eps0)

        sim_t = simulate_anchor(
            t2; r0=[0.5, 0.0, z_eq], v0=[0.0, 0.0, 0.0], tspan=(0.0, 35.0), dt=0.002
        )
        freq_tri, n_cross = _sa_zero_crossing_frequency(sim_t.t, [p[1] for p in sim_t.r])
        f0 = sqrt(T_b0 / (meff * s.L_b0)) / (2pi)

        @test n_cross ≥ 8
        @test freq_tri ≈ sqrt(2.0) * f0 rtol=0.03

        # Zero lateral stiffness equals the single backline.
        t0 = TriangulatedDualBacklineSkyAnchor(s, 0.0)
        sim_0 = simulate_anchor(
            t0; r0=[0.5, 0.0, z_eq], v0=[0.0, 0.0, 0.0], tspan=(0.0, 20.0), dt=0.002
        )
        freq_0, _ = _sa_zero_crossing_frequency(sim_0.t, [p[1] for p in sim_0.r])
        @test freq_0 ≈ f0 rtol=0.02
    end

    @testset "slack crossing — energy ledger and dwell reporting" begin
        b = SingleBacklineSkyAnchor(
            50.0,
            (0.0, 0.0, 30.0),
            20.0;
            EA_b=1.0e6,
            I_t=12.6,
            pretension=mb3 * 9.81,
            zeta_p=0.05,
        )

        # Drop from 2 m inside the natural length, from rest.
        r0 = [0.0, 0.0, 30.0 - 18.0]
        sim = simulate_anchor(b; r0=r0, v0=[0.0, 0.0, 0.0], tspan=(0.0, 25.0), dt=0.002)

        led = energy_ledger(sim)
        # Pointwise no-pump requirement: the smoothing must not inject energy
        # at slack crossings.  max_gain is exactly 0.0 in practice.
        @test led.max_gain ≤ 1.0e-3
        # The residual converges with step size.  The dominant error sits in
        # the stiff catch/release transitions (order ~2.4 in dt).  Measured:
        # 0.24 J at dt = 2 ms, 3.0e-3 J at dt = 0.25 ms, against a 5.9e-3 J
        # default tolerance.
        @test led.max_residual ≤ 0.5

        # At resolvable step size the ledger closes to the default tolerance.
        sim_fine = simulate_anchor(
            b; r0=r0, v0=[0.0, 0.0, 0.0], tspan=(0.0, 6.0), dt=0.00025
        )
        led_fine = energy_ledger(sim_fine)
        @test led_fine.ok

        ev = slack_events(sim; min_dwell=0.8)
        @test ev.n_total ≥ 2
        @test ev.events[1].dwell ≈ sqrt(2 * 2.0 / 9.81) rtol=0.05
        @test ev.events[1].dwell < 0.8   # the initiating free fall is transient
        # The elastic catch re-launches the node.  Slack recurs in bounces.
        # The first bounce arc is a sustained unload.
        @test ev.events[2].dwell ≥ 0.8
        @test ev.n_sustained ≥ 1
        @test ev.sustained[1].dwell ≈ ev.events[2].dwell
    end

    @testset "sustained slack is flagged, transient is not" begin
        b = SingleBacklineSkyAnchor(
            50.0,
            (0.0, 0.0, 30.0),
            20.0;
            EA_b=1.0e6,
            I_t=12.6,
            pretension=mb3 * 9.81,
            zeta_p=0.05,
        )

        # 5 m of slack slack pays out over 1.0 s: sustained by the KTD rule
        # (wobble gate, T < 1 N for delta t > 0.8 s).
        sim5 = simulate_anchor(
            b; r0=[0.0, 0.0, 30.0 - 15.0], v0=[0.0, 0.0, 0.0], tspan=(0.0, 15.0), dt=0.002
        )
        ev5 = slack_events(sim5; min_dwell=0.8)
        @test ev5.n_sustained ≥ 1
        @test ev5.sustained[1].dwell ≈ sqrt(2 * 5.0 / 9.81) rtol=0.05

        # 0.15 m of slack pays out in 0.17 s: transient, never flagged.
        sim1 = simulate_anchor(
            b; r0=[0.0, 0.0, 30.0 - 19.85], v0=[0.0, 0.0, 0.0], tspan=(0.0, 8.0), dt=0.002
        )
        ev1 = slack_events(sim1; min_dwell=0.8)
        @test ev1.n_sustained == 0
    end
end
