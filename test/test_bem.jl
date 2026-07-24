# test/test_bem.jl — Blade-element momentum tests

@testset "bem_station" begin
    # Test case: R=3m rotor, station at r=2m, 8 m/s wind, 45 RPM
    # Expected order-of-magnitude: v_rel ~ omega*r ~ 4.71*2 ~ 9.4 m/s
    # dT ~ 0.5 * 1.225 * 9.4^2 * 0.15 * CL*cos(phi) ~ small positive
    rho = 1.225
    v_wind = 8.0
    omega = 45.0 * 2π / 60.0  # 4.71 rad/s
    r = 2.0
    chord = 0.15
    dr = 0.3
    a = 0.3  # typical induction factor

    # At a=0.3: v_axial = 8*(1-0.3) = 5.6, v_tan = 4.71*2 = 9.42
    # phi = atan(5.6, 9.42) ≈ 0.537 rad ≈ 30.7°
    # At this phi, CL≈0.5, CD≈0.015 for NACA 0012 at moderate Re
    cl = 0.5
    cd = 0.015

    dT, dQ = bem_station(r, chord, cl, cd, rho, v_wind, omega, a, dr)

    # dT should be positive (thrust), order ~10 N for this station
    @test dT > 0.0
    @test dT < 100.0

    # dQ should be positive (torque aiding rotation in autorotation)
    @test dQ > 0.0
    @test dQ < 200.0  # N·m per station

    # Physical checks
    v_axial = v_wind * (1 - a)
    v_tan = omega * r
    v_rel = sqrt(v_axial^2 + v_tan^2)
    phi = atan(v_axial, v_tan)

    # v_rel should be dominated by tangential component for our params
    @test v_rel > v_tan
    @test v_rel > v_axial

    # phi should be acute
    @test 0.0 < phi < π/2

    # cn and ct make physical sense
    cn_expected = cl * cos(phi) + cd * sin(phi)
    ct_expected = cl * sin(phi) - cd * cos(phi)
    @test cn_expected > 0.0  # normal force positive
    @test ct_expected > 0.0  # tangential force positive for autorotation

    # dT formula: 0.5 * rho * v_rel^2 * chord * cn * dr
    dT_expected = 0.5 * rho * v_rel^2 * chord * cn_expected * dr
    @test dT ≈ dT_expected rtol=1e-10

    # dQ formula: 0.5 * rho * v_rel^2 * chord * ct * r * dr
    dQ_expected = 0.5 * rho * v_rel^2 * chord * ct_expected * r * dr
    @test dQ ≈ dQ_expected rtol=1e-10
end

@testset "bem_station edge cases" begin
    rho = 1.225
    chord = 0.15
    dr = 0.3

    # Zero omega: wind only, thrust from drag, zero torque
    dT, dQ = bem_station(2.0, chord, 0.0, 0.015, rho, 8.0, 1e-6, 0.3, dr)
    # With very small omega: v_axial dominates, phi ≈ 90°
    # dT ≈ ½ρ·v_axial²·chord·cd·dr (pure drag in axial direction)
    dT_expected = 0.5 * rho * (8.0 * 0.7)^2 * chord * 0.015 * dr
    @test dT ≈ dT_expected rtol=0.01
    @test abs(dQ) < 1e-6  # no rotation → negligible torque

    # Zero wind AND zero omega: no forces
    dT, dQ = bem_station(2.0, chord, 0.5, 0.015, rho, 0.0, 0.0, 0.3, dr)
    @test dT ≈ 0.0 atol=1e-10
    @test dQ ≈ 0.0 atol=1e-10

    # a=0 (no induction): higher velocities, higher forces
    dT_a0, _ = bem_station(2.0, chord, 0.5, 0.015, rho, 8.0, 4.71, 0.0, dr)
    dT_a3, _ = bem_station(2.0, chord, 0.5, 0.015, rho, 8.0, 4.71, 0.3, dr)
    @test dT_a0 > dT_a3  # less induction → more through-flow → more thrust
end
