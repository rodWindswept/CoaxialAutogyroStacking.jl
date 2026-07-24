# test/test_stack.jl — AutogyroStack struct and multi-rotor tension profile

@testset "AutogyroStack" begin

    @testset "AutogyroStack construction" begin
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.2, 0.05, 3, 0.12, 5.0, 0.0, 3.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r1, r2],           # rotors top→bottom
            [3.0, 9.0],         # section lengths: R1→R2, R2→anchor (n entries)
            0.004,              # line diameter (m)
            50.0,               # base line elevation (deg)
        )
        @test length(stack.rotors) == 2
        @test length(stack.section_lengths) == 2   # n rotors → n sections
        @test stack.rotors[1].radius == 1.5
        @test stack.rotors[2].radius == 1.2
        @test stack.line_diameter == 0.004
        @test stack.line_angle_deg == 50.0
    end

    @testset "stack_tension_profile — single rotor" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [rotor],
            [10.0],             # single section: rotor → anchor (n entries)
            0.004,
            50.0,
        )
        rho = 1.225
        v_wind = 8.0
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, rho, v_wind)

        # Should have n_rotors + 1 = 2 entries
        @test length(profile) == 2

        # profile[1] = at topmost rotor = 0 (nothing pulls from above)
        @test profile[1] ≈ 0.0 atol=0.01

        # profile[2] = anchor: F_line − W·cosθ + line_drag below
        # F_line ≈ 327 N, W = 5*9.81=49.05, cosd(50)≈0.6428, W·cosθ≈31.5
        # line_drag below ≈ 1.88 N (for 10m)
        # anchor ≈ 327 − 31.5 + 1.9 ≈ 297 N
        @test profile[2] > 250.0
        @test profile[2] < 350.0
    end

    @testset "stack_tension_profile — monotonic downward increase" begin
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        r3 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r1, r2, r3],
            [3.0, 3.0, 9.0],    # R1→R2, R2→R3, R3→anchor (n entries)
            0.004,
            50.0,
        )
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, 1.225, 8.0)

        @test length(profile) == 4  # n_rotors + 1
        # Monotonic increase: each position has MORE tension than the one above
        for i in 1:(length(profile)-1)
            @test profile[i+1] > profile[i]
        end

        # First entry (at topmost rotor) should be zero
        @test profile[1] ≈ 0.0 atol=0.01

        # Last entry (anchor) should be largest
        @test profile[end] > profile[2] * 2  # anchor >> first rotor's contribution
    end

    @testset "stack_tension_profile — different tilts give different contributions" begin
        # Two rotors: one with high tilt, one with low tilt
        r_high = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)  # high lift
        r_low  = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, -20.0, 0.0, 5.0) # near-flat

        # Stack: low tilt on top, high tilt below
        stack_1 = CoaxialAutogyroStacking.AutogyroStack(
            [r_low, r_high],
            [3.0, 9.0],          # R1→R2, R2→anchor (n entries)
            0.004,
            50.0,
        )
        profile_1 = CoaxialAutogyroStacking.stack_tension_profile(stack_1, 1.225, 8.0)

        # Stack: high tilt on top, low tilt below
        stack_2 = CoaxialAutogyroStacking.AutogyroStack(
            [r_high, r_low],
            [3.0, 9.0],          # R1→R2, R2→anchor (n entries)
            0.004,
            50.0,
        )
        profile_2 = CoaxialAutogyroStacking.stack_tension_profile(stack_2, 1.225, 8.0)

        # Total anchor tension should be the same (same total lift, same weight)
        @test profile_1[end] ≈ profile_2[end] atol=1.0

        # But intermediate tensions differ because order matters
        # In stack_1: r_low on top → profile_1[2] (below r_low) should be less than
        # profile_2[2] (below r_high in stack_2)
        @test profile_1[2] < profile_2[2]
    end

    @testset "stack_tension_profile — zero wind, tension from weight only" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [rotor],
            [10.0],              # single section: rotor → anchor (n entries)
            0.004,
            50.0,
        )

        # At zero wind, F_line = 0, so the line goes slack below the rotor.
        # Rope cannot push — tension clamps to zero.
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, 1.225, 0.0)

        @test profile[1] ≈ 0.0 atol=0.01     # at topmost rotor
        @test profile[2] == 0.0               # slack below hanging rotor, not negative
    end

    @testset "AutogyroStack — line_density default" begin
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r], [10.0], 0.004, 50.0)
        @test stack.line_density == 970.0   # Dyneema default
    end

    @testset "AutogyroStack — line_density override" begin
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r], [10.0], 0.004, 50.0, line_density=1440.0)  # Spectra
        @test stack.line_density == 1440.0
    end

    @testset "stack_tension_profile — line weight adds to anchor tension" begin
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)

        # Stack with zero-density line (no line weight) — like the old model
        stack_no_weight = CoaxialAutogyroStacking.AutogyroStack(
            [r], [30.0], 0.004, 50.0, line_density=0.0)
        profile_no_weight = CoaxialAutogyroStacking.stack_tension_profile(
            stack_no_weight, 1.225, 8.0)

        # Stack with Dyneema-density line (with line weight)
        stack_with_weight = CoaxialAutogyroStacking.AutogyroStack(
            [r], [30.0], 0.004, 50.0, line_density=970.0)
        profile_with_weight = CoaxialAutogyroStacking.stack_tension_profile(
            stack_with_weight, 1.225, 8.0)

        # Line weight should increase anchor tension
        @test profile_with_weight[end] > profile_no_weight[end]

        # The difference should match expected line weight for 30m of 4mm Dyneema:
        # mass_per_m = 970 × π × (0.002)² ≈ 0.0122 kg/m
        # total mass = 0.0122 × 30 = 0.366 kg
        # weight = 0.366 × 9.81 = 3.59 N
        # along-line = 3.59 × sin(50°) ≈ 2.75 N
        expected_extra = 0.0122 * 30.0 * 9.81 * sind(50.0)
        @test profile_with_weight[end] - profile_no_weight[end] ≈ expected_extra atol=0.1
    end

    @testset "stack_tension_profile_polygon" begin
        # Single rotor: should match polygon solver
        r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
        stack = AutogyroStack([r], [15.0], 0.004, 55.0)
        profile = stack_tension_profile_polygon(stack, 1.225, 8.0)

        @test length(profile) == 2  # top + anchor
        @test profile[1] ≈ 0.0 atol=1e-6
        @test profile[2] > 0.0

        # Two rotors: tension monotonically increasing
        stack2 = AutogyroStack([r, r], [10.0, 15.0], 0.004, 55.0)
        profile2 = stack_tension_profile_polygon(stack2, 1.225, 8.0)
        @test length(profile2) == 3
        @test profile2[1] ≈ 0.0 atol=1e-6
        @test profile2[3] > profile2[2] > profile2[1]

        # Three rotors: all positive tensions
        stack3 = AutogyroStack([r, r, r], fill(10.0, 3), 0.004, 55.0)
        profile3 = stack_tension_profile_polygon(stack3, 1.225, 8.0)
        @test all(profile3 .>= 0.0)
        @test profile3[end] > profile2[end]  # more rotors → more tension
    end
end
