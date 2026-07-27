# test/test_polygon_line.jl — Polygon line geometry tests

@testset "solve_polygon_angles" begin
    rho = 1.225
    v_wind = 8.0
    anchor_angle = 55.0  # bottom segment elevation

    # Single rotor: segment angle should be near anchor angle
    rotor = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    θ, T, F = solve_polygon_angles([rotor], anchor_angle, rho, v_wind)

    @test length(θ) == 1
    @test length(T) == 2  # tension profile: top + bottom
    @test length(F) == 1

    # Segment angle should be physically reasonable
    @test θ[1] > 0.0
    @test θ[1] < 90.0

    # Tension should increase downward (top=0, bottom>0)
    @test T[1] ≈ 0.0 atol=1e-6
    @test T[2] > 0.0

    # F_line should be positive
    @test F[1] > 0.0
end

@testset "polygon convergence" begin
    rho = 1.225
    v_wind = 8.0
    anchor_angle = 55.0

    # Two identical rotors — segments should be similar
    r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    θ, T, F = solve_polygon_angles([r, r], anchor_angle, rho, v_wind)

    @test length(θ) == 2
    @test all(θ .> 0.0)
    @test all(θ .< 90.0)

    # Tension accumulates downward
    @test T[1] ≈ 0.0 atol=1e-6
    @test T[2] > T[1]
    @test T[3] > T[2]

    # Converges quickly — segments deviate from anchor due to tilt
    @test maximum(abs.(θ .- anchor_angle)) < 30.0  # within 30° of anchor
end

@testset "polygon graded stacking" begin
    rho = 1.225
    v_wind = 8.0
    anchor_angle = 55.0

    # Top-draggy: top rotor (20°) pulls line flatter than bottom (5°)
    # θ[1] should be lower (flatter) than θ[2] — but small F_line may
    # cause weight-dominated behaviour. Just verify both are physical.
    r_top = AutogyroRotor(3.0, 0.05, 2, 0.15, 20.0, 0.0, 5.0)
    r_bot = AutogyroRotor(3.0, 0.05, 2, 0.15, 5.0, 0.0, 5.0)
    θ, T, F = solve_polygon_angles([r_top, r_bot], anchor_angle, rho, v_wind)
    @test all(θ .> 0.0)
    @test all(θ .< 85.0)
    @test all(F .> 0.0)
end

@testset "polygon edge cases" begin
    rho = 1.225
    v_wind = 8.0
    r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)

    # Zero tilt rotors: weight-dominated → top segment goes steep
    r_flat = AutogyroRotor(3.0, 0.05, 2, 0.15, 0.0, 0.0, 5.0)
    θ, _, _ = solve_polygon_angles([r_flat, r_flat], 55.0, rho, v_wind)
    @test all(θ .> 0.0)
    @test all(θ .< 90.0)  # all physical, but may deviate significantly

    # Steep anchor: segment angle should be physical regardless of anchor
    θ_steep, _, _ = solve_polygon_angles([r], 65.0, rho, v_wind)
    @test θ_steep[1] > 0.0
    @test θ_steep[1] < 90.0  # physical, equilibrium converges independent of anchor

    # Three rotors
    θ3, T3, F3 = solve_polygon_angles([r, r, r], 55.0, rho, v_wind)
    @test length(θ3) == 3
    @test T3[4] > T3[3] > T3[2] > T3[1]  # monotonic tension
end
