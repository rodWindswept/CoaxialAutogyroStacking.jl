# test/test_line_section.jl — Bare line drag and L/D comparison

@testset "Line Section" begin

    @testset "bare_line_drag — crossflow at 50° elevation" begin
        rho = 1.225       # kg/m³
        v_wind = 8.0      # m/s
        diameter = 0.004  # 4 mm
        length = 10.0     # m
        elev = 50.0       # degrees

        # Crossflow velocity = v_wind * cos(elev)
        # v_cross = 8.0 * cosd(50) = 5.142
        # q = 0.5 * 1.225 * (5.142)^2 = 0.5 * 1.225 * 26.44 = 16.20
        # A_projected = 0.004 * 10 = 0.04
        # F_drag = 16.20 * 0.04 * 1.2 = 0.7776
        F = CoaxialAutogyroStacking.bare_line_drag(rho, v_wind, diameter, length, elev)
        @test F ≈ 0.778 atol=0.01
    end

    @testset "bare_line_drag — perpendicular flow (90°) matches uncorrected" begin
        rho = 1.225
        v_wind = 8.0
        # At 90° elevation, cosd(90)=0 → zero crossflow → zero drag
        F = CoaxialAutogyroStacking.bare_line_drag(rho, v_wind, 0.004, 10.0, 90.0)
        @test F == 0.0
    end

    @testset "bare_line_drag — horizontal line (0°) gets full crossflow" begin
        rho = 1.225
        v_wind = 8.0
        # At 0° (horizontal), cosd(0)=1 → full wind speed
        # Same as old uncorrected value: 1.88 N
        F = CoaxialAutogyroStacking.bare_line_drag(rho, v_wind, 0.004, 10.0, 0.0)
        @test F ≈ 1.88 atol=0.01
    end

    @testset "bare_line_drag scales with length" begin
        rho = 1.225
        v_wind = 10.0
        # Double length → double drag
        F1 = CoaxialAutogyroStacking.bare_line_drag(rho, v_wind, 0.004, 5.0, 45.0)
        F2 = CoaxialAutogyroStacking.bare_line_drag(rho, v_wind, 0.004, 10.0, 45.0)
        @test F2 ≈ 2 * F1 atol=1e-12
    end

    @testset "bare_line_drag scales with v² (at fixed elevation)" begin
        rho = 1.225
        dia = 0.004
        len = 10.0
        elev = 30.0
        F1 = CoaxialAutogyroStacking.bare_line_drag(rho, 5.0, dia, len, elev)
        F2 = CoaxialAutogyroStacking.bare_line_drag(rho, 10.0, dia, len, elev)
        @test F2 ≈ 4 * F1 atol=1e-12
    end

    @testset "bare_line_drag zero wind → zero drag" begin
        F = CoaxialAutogyroStacking.bare_line_drag(1.225, 0.0, 0.004, 10.0, 50.0)
        @test F == 0.0
    end

    @testset "Rotor L/D >> bare line L/D" begin
        # Bare line has zero lift → L/D ≈ 0
        # Rotor at optimal pitch should have L/D > 1
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
        rho = 1.225
        v_wind = 8.0
        _, F_lift, F_drag, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(
            rotor, rho, v_wind, 50.0)

        rotor_LD = F_lift / F_drag
        @test rotor_LD > 1.0  # rotor provides useful lift
        @test rotor_LD > 1.3  # at optimal pitch it's much better
    end
end
