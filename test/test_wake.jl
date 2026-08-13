# test/test_wake.jl — Wake interaction model for stacked rotors
# Phase 11: Jensen/PARK wake deficit propagation between coaxial rotors.
# Phase 12: Bastankhah 2026 generalised actuator disk theory.

@testset "wake_deficit — Jensen/PARK model" begin
    # Jensen model: v/v∞ = 1 − (1−√(1−CT)) × (R/(R + k·x))²
    # v_ratio ∈ [√(1−CT), 1.0] — minimum at rotor plane, recovers to 1 at ∞

    @test wake_deficit(0.5, 3.0, 0.0) ≈ sqrt(1 - 0.5)  # CT=0.5 → √0.5 ≈ 0.707
    @test wake_deficit(0.0, 3.0, 0.0) ≈ 1.0               # CT=0 → no deficit
    @test wake_deficit(0.8, 3.0, 0.0) ≈ sqrt(1 - 0.8)     # CT=0.8 → √0.2 ≈ 0.447

    @test wake_deficit(0.5, 3.0, 1e6) ≈ 1.0 atol=1e-4     # far downstream → full recovery

    d1 = wake_deficit(0.3, 3.0, 20.0)
    d2 = wake_deficit(0.6, 3.0, 20.0)
    @test d2 < d1  # more thrust → more momentum extracted

    d_small_r = wake_deficit(0.5, 1.5, 20.0)
    d_large_r = wake_deficit(0.5, 3.0, 20.0)
    @test d_large_r < d_small_r  # bigger rotor → wider wake → slower recovery

    d_near = wake_deficit(0.5, 3.0, 5.0)
    d_far  = wake_deficit(0.5, 3.0, 15.0)
    @test d_far > d_near  # further downstream → higher v_ratio

    @test wake_deficit(1.5, 3.0, 0.0) ≈ 0.0 atol=1e-4   # CT≥1 clamped
    @test wake_deficit(-0.3, 3.0, 0.0) ≈ 1.0 atol=1e-4   # CT≤0 clamped
end

@testset "stack_effective_wind — multi-rotor cumulative deficit" begin
    r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    rho, v_wind, elev = 1.225, 8.0, 55.0

    v_eff = stack_effective_wind([r], [10.0], rho, v_wind, elev)
    @test length(v_eff) == 1
    @test v_eff[1] ≈ v_wind

    v_eff2 = stack_effective_wind([r, r], [20.0, 20.0], rho, v_wind, elev)
    @test length(v_eff2) == 2
    @test v_eff2[1] ≈ v_wind
    @test v_eff2[2] < v_wind
    @test v_eff2[2] > 0.0

    v_eff3 = stack_effective_wind([r, r, r], fill(15.0, 3), rho, v_wind, elev)
    @test length(v_eff3) == 3
    @test v_eff3[1] ≈ v_wind
    @test v_eff3[2] < v_wind
    @test v_eff3[3] ≤ v_eff3[2]

    v_close = stack_effective_wind([r, r], [5.0, 5.0], rho, v_wind, elev)
    v_far   = stack_effective_wind([r, r], [50.0, 50.0], rho, v_wind, elev)
    @test v_far[2] > v_close[2]

    r_dead = AutogyroRotor(0.5, 0.05, 2, 0.05, 90.0, 0.0, 1.0)
    v_eff_dead = stack_effective_wind([r_dead, r], [20.0, 20.0], rho, v_wind, elev)
    @test v_eff_dead[1] ≈ v_wind
    @test v_eff_dead[2] > 0.95 * v_wind
end

@testset "wake_deficit_bastankhah — Bastankhah 2026 entrainment model" begin
    # Phase 12: Bastankhah et al. (2026) J. Fluid Mech.
    # Validation from companion code: AtWIND-lab/Generalised-Actuator-Disk-theory
    # Parameters: E1=0.1, E2=0.3, I=0.05

    # --- Upstream (analytical, Eq 2.18) ---
    @test wake_deficit_bastankhah_upstream(0.2, -2.0) ≈ 0.994621 atol=1e-4
    @test wake_deficit_bastankhah_upstream(0.2, -1.0) ≈ 0.980846 atol=1e-4
    @test wake_deficit_bastankhah_upstream(0.3, 0.0) ≈ 0.7 atol=1e-8
    @test wake_deficit_bastankhah_upstream(0.4, 0.0) ≈ 0.6 atol=1e-8

    # --- Downstream ODE (Eqs 2.17a,b) with spatial shielding (Eq 2.6) ---
    # a=0.2, converged CT=0.6016
    @test wake_deficit_bastankhah_downstream(0.2, 0.6016, 1.0; E2=0.3) ≈ 0.694674 atol=2e-3
    @test wake_deficit_bastankhah_downstream(0.2, 0.6016, 2.0; E2=0.3) ≈ 0.722966 atol=2e-3

    # a=0.3, converged CT=0.8267
    @test wake_deficit_bastankhah_downstream(0.3, 0.8267, 1.0; E2=0.3) ≈ 0.568275 atol=3e-3
    @test wake_deficit_bastankhah_downstream(0.3, 0.8267, 0.0; E2=0.3) ≈ 0.7 atol=1e-8

    # --- CT-a iteration (Eqs 2.23-2.24) ---
    ct_iter = bastankhah_ct_from_a(0.2; I=0.05, E2=0.3)
    @test ct_iter ≈ 0.6016 atol=0.005
    @test bastankhah_ct_from_a(0.3; I=0.05, E2=0.3) ≈ 0.8267 atol=0.01
    @test bastankhah_ct_from_a(0.2; I=0.05, E2=0.3) < bastankhah_ct_from_a(0.3; I=0.05, E2=0.3)
    @test bastankhah_ct_from_a(0.3; I=0.05, E2=0.3) < bastankhah_ct_from_a(0.4; I=0.05, E2=0.3)

    # --- a-from-CT inverse iteration ---
    a_from_ct = bastankhah_a_from_ct(0.6016; I=0.05, E2=0.3)
    @test a_from_ct ≈ 0.2 atol=0.008

    # --- Unified wake_deficit with :bastankhah ---
    v_ratio = wake_deficit(0.6016, 3.0, 3.0; model=:bastankhah, I=0.05, E2=0.3)
    @test v_ratio < 0.8
    @test v_ratio > 0.7

    # Default model is still Jensen/PARK for backward compat
    v_jensen = wake_deficit(0.5, 3.0, 0.0)
    @test v_jensen ≈ sqrt(0.5)
end
