# test/test_optimisation.jl — Optimal pitch search and integration API

@testset "Optimisation" begin

    @testset "optimal_pitch — single rotor" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
        rho = 1.225
        v_wind = 8.0
        elev = 50.0

        pitch_opt, F_max = CoaxialAutogyroStacking.optimal_pitch(rotor, rho, v_wind, elev)

        # Optimal tilt should be in a reasonable range
        @test -20.0 <= pitch_opt <= 30.0

        # F_max should match the force at optimal tilt
        F_line_check, _, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(
            CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, pitch_opt, 0.0, 5.0),
            rho, v_wind, elev)
        @test F_max ≈ F_line_check atol=1.0
    end

    @testset "optimal_pitch — compared to zero tilt" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
        rho = 1.225
        v_wind = 8.0
        elev = 50.0

        pitch_opt, F_opt = CoaxialAutogyroStacking.optimal_pitch(rotor, rho, v_wind, elev)

        # Zero-tilt force for comparison
        _, F_zero, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(
            rotor, rho, v_wind, elev)

        # Optimal tilt should give at least as much force as zero tilt
        @test F_opt >= F_zero
    end

    @testset "optimal_pitches — multi-rotor stack" begin
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.2, 0.05, 3, 0.12, 0.0, 0.0, 3.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r1, r2],
            [2.0, 3.0, 9.0],
            0.004,
            50.0,
        )
        rho = 1.225
        v_wind = 8.0

        pitches = CoaxialAutogyroStacking.optimal_pitches(stack, rho, v_wind)

        @test length(pitches) == 2
        # Each tilt should be in reasonable range
        @test all(-20.0 .<= pitches .<= 30.0)
    end

    @testset "lift_force_steady — integration API" begin
        # Mirror the KiteTurbineDynamics.jl dispatch pattern:
        # (F_hub, T_anchor, elevation) = lift_force_steady(stack, rho, v_wind)
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r1, r2],
            [2.0, 3.0, 9.0],
            0.004,
            50.0,
        )
        rho = 1.225
        v_wind = 8.0

        F_hub, T_anchor, elev = CoaxialAutogyroStacking.lift_force_steady(stack, rho, v_wind)

        # Elevation should match the stack's line angle
        @test elev == 50.0

        # T_anchor should match the last entry of stack_tension_profile
        profile = CoaxialAutogyroStacking.stack_tension_profile(stack, rho, v_wind)
        @test T_anchor ≈ profile[end] atol=1.0

        # F_hub should be the total line force contributed by all rotors
        total_F_line = 0.0
        for rotor in stack.rotors
            fl, _, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(rotor, rho, v_wind, 50.0)
            total_F_line += fl
        end
        @test F_hub ≈ total_F_line atol=1.0
    end

    @testset "lift_force_steady — single rotor" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [rotor],
            [1.0, 10.0],
            0.004,
            50.0,
        )
        F_hub, T_anchor, elev = CoaxialAutogyroStacking.lift_force_steady(stack, 1.225, 8.0)

        # Single rotor: F_hub = F_line of the rotor
        F_line, _, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(rotor, 1.225, 8.0, 50.0)
        @test F_hub ≈ F_line atol=1.0
        @test elev == 50.0
    end

    @testset "lift_force_steady — zero wind" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [rotor],
            [1.0, 10.0],
            0.004,
            50.0,
        )
        F_hub, T_anchor, elev = CoaxialAutogyroStacking.lift_force_steady(stack, 1.225, 0.0)

        @test elev == 50.0
        # At zero wind, no aerodynamic forces
        @test F_hub == 0.0
        # T_anchor reflects negative weight (rotor pulls down, line would be slack)
        @test T_anchor < 0.0
    end
end
