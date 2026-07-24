# Phase 10b Task 4 — BEM induction loop tests (appended to test_bem.jl)

@testset "bem_induction" begin
    rho = 1.225
    v_wind = 8.0
    omega = 45.0 * 2π / 60.0  # 4.71 rad/s

    # Rotor matching best sweep config: R=3m, 2 blades, 0.15m chord
    rotor = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)

    T, Q = bem_induction(rotor, rho, v_wind, omega, 10)

    # Thrust should be positive and meaningful order-of-magnitude
    # PCA-2 model gives ~997 N lift at this config; BEM thrust should be similar
    @test T > 100.0
    @test T < 5000.0

    # Torque should be near zero for autorotation (this omega is a guess)
    # |Q| < 500 N·m is a loose bound — autorotation RPM will be found later
    @test abs(Q) < 500.0

    # More stations → better convergence (but same ballpark)
    T20, Q20 = bem_induction(rotor, rho, v_wind, omega, 20)
    @test T20 ≈ T rtol=0.1  # within 10% of 10-station result

    # Higher omega → higher thrust (more blade speed)
    T_fast, _ = bem_induction(rotor, rho, v_wind, omega * 1.5, 10)
    @test T_fast > T

    # Zero wind with spinning rotor: no through-flow → zero thrust,
    # but drag torque opposes rotation (rotor acts as a mixer/fan)
    T0, Q0 = bem_induction(rotor, rho, 0.0, omega, 10)
    @test T0 ≈ 0.0 atol=1e-6
    @test Q0 < 0.0  # drag torque, rotor consumes power

    # No rotation → drag-only thrust
    T_drag, Q_drag = bem_induction(rotor, rho, v_wind, 1e-6, 10)
    @test T_drag > 0.0
    @test abs(Q_drag) < 1.0  # negligible torque at near-zero RPM
end

@testset "bem_induction convergence" begin
    rotor = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)

    # Should not throw for any reasonable omega
    for omega in [1.0, 2.0, 5.0, 10.0, 20.0]
        T, Q = bem_induction(rotor, 1.225, 8.0, omega, 10)
        @test isfinite(T)
        @test isfinite(Q)
    end

    # Small rotor should also work and produce less thrust
    small = AutogyroRotor(1.5, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    T_big, _ = bem_induction(AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0), 1.225, 8.0, 4.71, 10)
    T_s, Q_s = bem_induction(small, 1.225, 8.0, 4.71, 10)
    @test T_s > 0.0
    @test T_s < T_big  # smaller rotor → less thrust
end

@testset "bem_autorotation_rpm" begin
    rotor = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    rho = 1.225
    v_wind = 8.0

    rpm = bem_autorotation_rpm(rotor, rho, v_wind)

    # RPM should be in a physically plausible range
    @test rpm > 10.0
    @test rpm < 500.0

    # At autorotation RPM, torque should be near zero
    omega = rpm * 2π / 60.0
    T, Q = bem_induction(rotor, rho, v_wind, omega, 15)
    @test abs(Q) < 10.0  # near torque equilibrium

    # Thrust at autorotation should be positive and meaningful
    @test T > 50.0

    # Higher wind → higher RPM
    rpm_12 = bem_autorotation_rpm(rotor, rho, 12.0)
    @test rpm_12 > rpm

    # Smaller rotor: RPM may be higher or lower depending on v_through/R ratio
    # Just verify it returns a physically plausible value
    small = AutogyroRotor(1.5, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    rpm_small = bem_autorotation_rpm(small, rho, v_wind)
    @test rpm_small > 1.0
    @test rpm_small < 800.0  # wide bound for small rotors
end
