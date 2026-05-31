# test/test_rotor.jl — AutogyroRotor struct and single-rotor force calculations

@testset "AutogyroRotor" begin

    @testset "Struct construction and field access" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(
            1.5,    # radius (m)
            0.05,   # hub_radius (m)
            4,      # n_blades
            0.15,   # blade_chord (m)
            10.0,   # pitch_deg
            5.0,    # mass (kg)
        )
        @test rotor.radius == 1.5
        @test rotor.hub_radius == 0.05
        @test rotor.n_blades == 4
        @test rotor.blade_chord == 0.15
        @test rotor.pitch_deg == 10.0
        @test rotor.mass == 5.0
    end

    @testset "rotor_disk_area" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 5.0)
        area = CoaxialAutogyroStacking.rotor_disk_area(rotor)
        @test area ≈ π * 1.5^2 atol=1e-12
    end

    @testset "rotor_disk_area for different radius" begin
        rotor = CoaxialAutogyroStacking.AutogyroRotor(2.0, 0.1, 3, 0.2, 0.0, 8.0)
        @test CoaxialAutogyroStacking.rotor_disk_area(rotor) ≈ π * 4.0 atol=1e-12
    end
end
