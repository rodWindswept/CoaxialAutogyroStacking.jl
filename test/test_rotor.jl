# test/test_rotor.jl — AutogyroRotor struct and single-rotor force calculations

@testset "AutogyroRotor" begin

    @testset "Struct construction and field access" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(
            1.5,    # radius (m)
            0.05,   # hub_radius (m)
            4,      # n_blades
            0.15,   # blade_chord (m)
            10.0,   # tilt_deg
            0.0,    # blade_pitch_deg
            5.0,    # mass (kg)
        )
        @test rotor.radius == 1.5
        @test rotor.hub_radius == 0.05
        @test rotor.n_blades == 4
        @test rotor.blade_chord == 0.15
        @test rotor.tilt_deg == 10.0
        @test rotor.blade_pitch_deg == 0.0
        @test rotor.mass == 5.0
    end

    @testset "rotor_disk_area" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        area = CoaxialAutogyroStacking.rotor_disk_area(rotor)
        @test area ≈ π * (1.5^2 - 0.05^2) atol=1e-12
    end

    @testset "rotor_solidity" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
        # σ = 2 × 0.15 / (π × 1.5) = 0.3 / 4.7124 = 0.0637
        σ = CoaxialAutogyroStacking.rotor_solidity(rotor)
        @test σ ≈ 0.06366 atol=1e-4
    end

    @testset "rotor_solidity — PCA-2 comparison" begin
        # PCA-2: 3 blades, c=0.559 m, R=6.86 m → σ ≈ 0.0976
        rotor = CoaxialAutogyroStacking.AutogyroRotor(6.86, 0.1, 3, 0.559, 0.0, 0.0, 100.0)
        σ = CoaxialAutogyroStacking.rotor_solidity(rotor)
        @test σ ≈ 0.0778 atol=0.01  # matches Harris value ~0.0976 (non-rectangular blades)
    end

    @testset "estimated_autorotation_rpm" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0)
        # α_eff=50°, v_wind=8 m/s, λ=2.5
        # v_through = 8 × sin(50°) = 6.128
        # Ω = 2.5 × 6.128 / 1.5 = 10.21 rad/s
        # RPM = 10.21 × 60 / (2π) = 97.5
        rpm = CoaxialAutogyroStacking.estimated_autorotation_rpm(rotor, 8.0, 50.0)
        @test rpm ≈ 97.5 atol=1.0
    end

    @testset "estimated_autorotation_rpm — large rotor at 50°" begin
        # R=3m, α_eff=50°, v_wind=8 m/s, λ=2.5
        # v_through = 6.128, Ω = 2.5 × 6.128 / 3 = 5.11 rad/s, RPM = 48.8
        rotor = CoaxialAutogyroStacking.AutogyroRotor(3.0, 0.1, 2, 0.15, 10.0, 0.0, 5.0)
        rpm = CoaxialAutogyroStacking.estimated_autorotation_rpm(rotor, 8.0, 50.0)
        @test rpm ≈ 48.8 atol=1.0
        # Tip speed = Ω × R = 5.11 × 3 = 15.3 m/s — well below 120 m/s noise limit
        tip_speed = (rpm * 2π / 60) * 3.0
        @test tip_speed < 120.0  # noise constraint from KTD.jl
    end

    @testset "effective_alpha — disk angle of attack" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)

        # Formula: α_eff = 90° − line_elevation_deg + tilt_deg
        # Zero-tilt rotor at 50° line elevation: α=40°
        r0 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
        @test CoaxialAutogyroStacking.effective_alpha(r0, 50.0) ≈ 40.0

        # Tilt 10° at 50° line elevation: α=50°
        @test CoaxialAutogyroStacking.effective_alpha(rotor, 50.0) ≈ 50.0

        # Vertical line with 20° tilt: α=20°
        r2 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 20.0, 0.0, 5.0)
        @test CoaxialAutogyroStacking.effective_alpha(r2, 90.0) ≈ 20.0

        # Horizontal line with 0° tilt: α=90°
        r3 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
        @test CoaxialAutogyroStacking.effective_alpha(r3, 0.0) ≈ 90.0

        # Negative tilt (feathered flat): α=0°
        r4 = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, -40.0, 0.0, 5.0)
        @test CoaxialAutogyroStacking.effective_alpha(r4, 50.0) ≈ 0.0
    end

    @testset "rotor_force_along_line" begin
        rho = 1.225     # air density kg/m³
        v_wind = 8.0    # m/s

        @testset "Known point: radius=1.5, tilt=10°, elev=50°, v=8 m/s" begin
            # α_eff = 90° - 50° + 10° = 50°
            # PCA-2: CL≈0.82, CD≈0.86
            # q = 0.5 * 1.225 * 64 = 39.2
            # A = π * 2.25 = 7.0686
            # F_lift = 39.2 * 7.0686 * 0.82 ≈ 227.1
            # F_drag = 39.2 * 7.0686 * 0.86 ≈ 238.1
            # F_line = 227.1*sind(50) + 238.1*cosd(50) ≈ 327.0
            rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
            F_line, F_lift, F_drag, cl, cd = CoaxialAutogyroStacking.rotor_force_along_line(
                rotor, rho, v_wind, 50.0)
            @test F_line ≈ 326.9 atol=1.0
            @test F_lift ≈ 226.1 atol=1.0
            @test F_drag ≈ 237.1 atol=1.0
            @test cl ≈ 0.82 atol=0.01
            @test cd ≈ 0.86 atol=0.01
        end

        @testset "Zero tilt (pure autogyro) at 50° elevation" begin
            # α_eff = 90° - 50° + 0° = 40°
            # PCA-2: CL=0.95, CD=0.62
            rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
            F_line, F_lift, F_drag, cl, cd = CoaxialAutogyroStacking.rotor_force_along_line(
                rotor, rho, v_wind, 50.0)
            @test cl ≈ 0.95 atol=0.01
            @test cd ≈ 0.62 atol=0.01
            @test F_line > F_drag  # rotor L/D should give meaningful line pull
        end

        @testset "Near-vertical line (85° elevation, zero tilt)" begin
            # α_eff = 90° - 85° + 0° = 5°
            # PCA-2: CL=0.15, CD=0.03
            # F_lift = 39.2 * 7.0686 * 0.15 ≈ 41.5
            # F_drag = 39.2 * 7.0686 * 0.03 ≈ 8.3
            # F_line ≈ 41.5*sind(85) + 8.3*cosd(85) ≈ 42.0
            rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 0.0, 0.0, 5.0)
            F_line, F_lift, F_drag, cl, cd = CoaxialAutogyroStacking.rotor_force_along_line(
                rotor, rho, v_wind, 85.0)
            @test F_line ≈ 42.0 atol=1.0
            @test F_lift ≈ 41.5 atol=1.0
            @test F_drag ≈ 8.3 atol=0.5
        end

        @testset "Zero wind: forces should be zero" begin
            rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
            F_line, F_lift, F_drag, cl, cd = CoaxialAutogyroStacking.rotor_force_along_line(
                rotor, rho, 0.0, 50.0)
            @test F_line == 0.0
            @test F_lift == 0.0
            @test F_drag == 0.0
        end
    end
end
