# test/test_optimisation.jl — Optimal pitch search and integration API

@testset "Optimisation" begin

    @testset "optimal_pitch — single rotor" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 5.0)
        rho = 1.225
        v_wind = 8.0
        elev = 50.0

        pitch_opt, F_max = CoaxialAutogyroStacking.optimal_pitch(rotor, rho, v_wind, elev)

        # Optimal pitch should be in a reasonable range
        @test -20.0 <= pitch_opt <= 30.0

        # F_max should match the force at optimal pitch
        F_line_check, _, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(
            CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, pitch_opt, 5.0),
            rho, v_wind, elev)
        @test F_max ≈ F_line_check atol=1.0
    end

    @testset "optimal_pitch — compared to zero pitch" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 5.0)
        rho = 1.225
        v_wind = 8.0
        elev = 50.0

        pitch_opt, F_opt = CoaxialAutogyroStacking.optimal_pitch(rotor, rho, v_wind, elev)

        # Zero-pitch force for comparison
        _, F_zero, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(
            rotor, rho, v_wind, elev)

        # Optimal pitch should give at least as much force as zero pitch
        @test F_opt >= F_zero
    end

    @testset "optimal_pitches — multi-rotor stack" begin
        r1 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 5.0)
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.2, 0.05, 3, 0.12, 0.0, 3.0)
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
        # Each pitch should be in reasonable range
        @test all(-20.0 .<= pitches .<= 30.0)
    end
end
