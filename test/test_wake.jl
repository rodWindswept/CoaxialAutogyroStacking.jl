# test/test_wake.jl — Wake interaction model for stacked rotors
# Phase 11: Jensen/PARK wake deficit propagation between coaxial rotors.

@testset "wake_deficit — Jensen/PARK model" begin
    # Jensen model: v/v∞ = 1 − (1−√(1−CT)) × (R/(R + k·x))²
    # v_ratio ∈ [√(1−CT), 1.0] — minimum at rotor plane, recovers to 1 at ∞

    @test wake_deficit(0.5, 3.0, 0.0) ≈ sqrt(1 - 0.5)  # CT=0.5 → √0.5 ≈ 0.707
    @test wake_deficit(0.0, 3.0, 0.0) ≈ 1.0               # CT=0 → no deficit
    @test wake_deficit(0.8, 3.0, 0.0) ≈ sqrt(1 - 0.8)     # CT=0.8 → √0.2 ≈ 0.447

    @test wake_deficit(0.5, 3.0, 1e6) ≈ 1.0 atol=1e-4     # far downstream → full recovery

    d1 = wake_deficit(0.3, 3.0, 20.0)
    d2 = wake_deficit(0.6, 3.0, 20.0)
    @test d2 < d1  # more thrust → more momentum extracted

    d_small_r = wake_deficit(0.5, 1.5, 20.0)
    d_large_r = wake_deficit(0.5, 3.0, 20.0)
    @test d_large_r < d_small_r  # bigger rotor → wider wake → slower recovery

    d_near = wake_deficit(0.5, 3.0, 5.0)
    d_far  = wake_deficit(0.5, 3.0, 15.0)
    @test d_far > d_near  # further downstream → higher v_ratio

    @test wake_deficit(1.5, 3.0, 0.0) ≈ 0.0 atol=1e-4   # CT≥1 clamped
    @test wake_deficit(-0.3, 3.0, 0.0) ≈ 1.0 atol=1e-4   # CT≤0 clamped
end

@testset "stack_effective_wind — multi-rotor cumulative deficit" begin
    # stack_effective_wind(rotors, section_lengths, rho, v_wind, elev_deg; k=0.075)
    # Returns per-rotor effective wind after upstream wake deficits.
    # Uses one-pass freestream CT for each rotor (first-order approximation).

    r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
    rho, v_wind, elev = 1.225, 8.0, 55.0

    # Single rotor — always sees freestream
    v_eff = stack_effective_wind([r], [10.0], rho, v_wind, elev)
    @test length(v_eff) == 1
    @test v_eff[1] ≈ v_wind

    # Two identical rotors, 20 m spacing — rotor 2 sees deficit
    v_eff2 = stack_effective_wind([r, r], [20.0, 20.0], rho, v_wind, elev)
    @test length(v_eff2) == 2
    @test v_eff2[1] ≈ v_wind                   # top rotor: freestream
    @test v_eff2[2] < v_wind                    # bottom rotor: deficit
    @test v_eff2[2] > 0.0                       # but still positive

    # First rotor always sees freestream, regardless of stack size
    v_eff3 = stack_effective_wind([r, r, r], fill(15.0, 3), rho, v_wind, elev)
    @test length(v_eff3) == 3
    @test v_eff3[1] ≈ v_wind
    # With identical rotors and uniform spacing, rotor 1 dominates the wake.
    # Rotors 2 and 3 see the same deficit from rotor 1's wake.
    @test v_eff3[2] < v_wind
    @test v_eff3[3] ≤ v_eff3[2]  # at worst equal, never more wind than rotor above

    # Wider spacing → more recovery → less deficit at bottom
    v_close = stack_effective_wind([r, r], [5.0, 5.0], rho, v_wind, elev)
    v_far   = stack_effective_wind([r, r], [50.0, 50.0], rho, v_wind, elev)
    @test v_far[2] > v_close[2]   # more spacing → more recovery

    # Zero thrust rotor (tilt=90° → disk edge-on to wind) — minimal wake deficit
    r_dead = AutogyroRotor(0.5, 0.05, 2, 0.05, 90.0, 0.0, 1.0)
    v_eff_dead = stack_effective_wind([r_dead, r], [20.0, 20.0], rho, v_wind, elev)
    @test v_eff_dead[1] ≈ v_wind
    @test v_eff_dead[2] > 0.95 * v_wind   # tiny rotor edge-on → negligible deficit
end
