# test/test_stack.jl — AutogyroStack struct and multi-rotor tension profile

@testset "AutogyroStack" begin

    @testset "AutogyroStack construction" begin
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.2, 0.05, 3, 0.12, 5.0, 3.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r1, r2],           # rotors top→bottom
            [2.0, 3.0, 9.0],    # section lengths (n+1 entries)
            0.004,              # line diameter (m)
            50.0,               # base line elevation (deg)
        )
        @test length(stack.rotors) == 2
        @test length(stack.section_lengths) == 3
        @test stack.rotors[1].radius == 1.5
        @test stack.rotors[2].radius == 1.2
        @test stack.line_diameter == 0.004
        @test stack.line_angle_deg == 50.0
    end

    @testset "stack_tension_profile — single rotor" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [rotor],
            [0.1, 10.0],   # short free end, 10m to anchor
            0.004,
            50.0,
        )
        rho = 1.225
        v_wind = 8.0
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, rho, v_wind)

        # Should have n_rotors + 1 = 2 entries
        @test length(profile) == 2

        # profile[1] = free end ≈ 0 (only tiny section above contributes basically nothing)
        @test profile[1] ≈ 0.0 atol=0.2

        # profile[2] = anchor: F_line − W·cosθ + line_drag below
        # F_line ≈ 327 N, W = 5*9.81=49.05, cosd(50)≈0.6428, W·cosθ≈31.5
        # line_drag below ≈ 1.88 N (for 10m)
        # anchor ≈ 327 − 31.5 + 1.9 ≈ 297 N
        @test profile[2] > 250.0
        @test profile[2] < 350.0
    end

    @testset "stack_tension_profile — monotonic downward increase" begin
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        r3 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r1, r2, r3],
            [2.0, 3.0, 3.0, 9.0],
            0.004,
            50.0,
        )
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, 1.225, 8.0)

        @test length(profile) == 4  # n_rotors + 1
        # Monotonic increase: each position has MORE tension than the one above
        for i in 1:(length(profile)-1)
            @test profile[i+1] > profile[i]
        end

        # First entry (free end) should be very small
        @test profile[1] < 50.0

        # Last entry (anchor) should be largest
        @test profile[end] > profile[1] * 10  # anchor >> free end
    end

    @testset "stack_tension_profile — different pitches give different contributions" begin
        # Two rotors: one with high pitch, one with low pitch
        r_high = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)  # high lift
        r_low  = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, -20.0, 5.0) # near-flat

        # Stack: low pitch on top, high pitch below
        stack_1 = CoaxialAutogyroStacking.AutogyroStack(
            [r_low, r_high],
            [2.0, 3.0, 9.0],
            0.004,
            50.0,
        )
        profile_1 = CoaxialAutogyroStacking.stack_tension_profile(stack_1, 1.225, 8.0)

        # Stack: high pitch on top, low pitch below
        stack_2 = CoaxialAutogyroStacking.AutogyroStack(
            [r_high, r_low],
            [2.0, 3.0, 9.0],
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
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [rotor],
            [0.1, 10.0],
            0.004,
            50.0,
        )

        # At zero wind, F_line = 0, so the line tension below the rotor is
        # −W·cosθ (negative = rotor pulls line downward, line would be slack).
        # The magnitude equals the rotor's weight component along the line.
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, 1.225, 0.0)

        @test profile[1] ≈ 0.0 atol=0.2     # free end
        # Weight component: 5 kg × 9.81 × cosd(50°) ≈ 31.5 N, negative (pull-down)
        @test abs(profile[2]) ≈ 31.5 atol=3.0
        @test profile[2] < 0.0              # verified: pulls downward at zero wind
    end
end
