# test/test_airfoil_data.jl — NACA 0012 airfoil table tests

@testset "naca0012_cl" begin
    # Symmetric airfoil: CL(0°) = 0
    @test naca0012_cl(0.0, 1e5) ≈ 0.0 atol=1e-6

    # Symmetry: CL(-α) = -CL(α)
    for α in [2.0, 5.0, 8.0, 10.0]
        @test naca0012_cl(-α, 1e5) ≈ -naca0012_cl(α, 1e5) atol=1e-10
    end

    # Positive CL at positive α (linear range)
    @test naca0012_cl(5.0, 1e5) > 0.4
    @test naca0012_cl(5.0, 1e5) < 0.7

    # CL increases monotonically in linear range
    cls = [naca0012_cl(α, 1e5) for α in 0.0:2.0:8.0]
    @test all(diff(cls) .> 0)

    # Lift slope ≈ 2π/rad ≈ 0.11/deg in linear range
    # Re=100k: slightly steeper (~0.13) due to transitional flow effects
    for Re in [1e5, 2e5, 5e5, 1e6]
        slope = naca0012_cl(4.0, Re) / 4.0
        @test 0.08 < slope < 0.14
    end

    # CL_max exists and is positive
    @test naca0012_cl(10.0, 1e5) > 0.9

    # Post-stall: CL should eventually drop at very high α
    @test naca0012_cl(20.0, 1e5) < naca0012_cl(10.0, 1e5) ||
          naca0012_cl(20.0, 1e5) < 1.0

    # Higher Re → higher CL_max
    @test naca0012_cl(12.0, 1e6) > naca0012_cl(12.0, 1e5)
end

@testset "naca0012_cd" begin
    # CD at α=0° should be near CD_min (wider tolerance for Re=100k
    # where laminar separation bubble puts CD_min at α≈2.5°, not 0°)
    for (Re, cd_min) in [(1e5, 0.017), (2e5, 0.011), (5e5, 0.009), (1e6, 0.008)]
        @test naca0012_cd(0.0, Re) ≈ cd_min rtol=0.4
    end

    # CD increases with |α| (except near α=0 for Re=100k laminar bubble)
    @test naca0012_cd(8.0, 1e5) > naca0012_cd(5.0, 1e5)
    # For higher Re, CD(|α| ≥ 3°) > CD(0°) always holds
    @test naca0012_cd(5.0, 1e5) > naca0012_cd(0.0, 1e5) || naca0012_cd(8.0, 1e5) > naca0012_cd(0.0, 1e5)
    @test naca0012_cd(8.0, 5e5) > naca0012_cd(0.0, 5e5)

    # CD is symmetric: CD(α) = CD(-α)
    for α in [2.0, 5.0, 8.0]
        @test naca0012_cd(-α, 1e5) ≈ naca0012_cd(α, 1e5) atol=1e-10
    end

    # Higher Re → lower CD_min
    @test naca0012_cd(0.0, 1e6) < naca0012_cd(0.0, 1e5)

    # Post-stall: CD should rise toward ~2.0
    @test naca0012_cd(30.0, 1e5) > naca0012_cd(10.0, 1e5)
end

@testset "naca0012 nearest-Re interpolation" begin
    # Re=150k should give same as Re=100k (nearest)
    @test naca0012_cl(5.0, 150_000) ≈ naca0012_cl(5.0, 100_000) atol=1e-6

    # Re=350k should give same as Re=500k
    @test naca0012_cl(5.0, 350_000) ≈ naca0012_cl(5.0, 500_000) atol=1e-6

    # Re=750k should give same as Re=1M
    @test naca0012_cl(5.0, 750_000) ≈ naca0012_cl(5.0, 1_000_000) atol=1e-6
end

@testset "naca0012 edge cases" begin
    # Very low Re still works
    @test naca0012_cl(5.0, 10_000) ≈ naca0012_cl(5.0, 100_000) atol=1e-6

    # Very high Re still works
    @test naca0012_cl(5.0, 10_000_000) ≈ naca0012_cl(5.0, 1_000_000) atol=1e-6

    # Extreme α doesn't crash
    for α in [-45.0, -20.0, 45.0, 90.0]
        cl = naca0012_cl(α, 1e5)
        cd = naca0012_cd(α, 1e5)
        @test isfinite(cl)
        @test isfinite(cd)
        @test cd > 0.0
    end
end

@testset "naca4412_cl — cambered airfoil" begin
    # Cambered: CL(0°) > 0 (positive lift at zero AoA)
    @test naca4412_cl(0.0, 1e5) > 0.0

    # Cambered CL > symmetric CL at same α (linear range)
    for α in [2.0, 5.0, 8.0]
        @test naca4412_cl(α, 5e5) > naca0012_cl(α, 5e5)
    end

    # CL increases monotonically in linear range (-2° to 8°)
    cls = [naca4412_cl(α, 1e5) for α in -2.0:2.0:8.0]
    @test all(diff(cls) .> 0)

    # CL at α=5° should be meaningfully positive
    @test naca4412_cl(5.0, 5e5) > 0.5

    # Higher Re → higher CL_max (test at α above Re=100k stall but below Re=1M stall)
    @test naca4412_cl(14.0, 1e6) > naca4412_cl(14.0, 1e5)

    # Deep stall: CL decays at high α
    @test naca4412_cl(30.0, 1e5) < 1.0

    # Extreme α doesn't crash
    for α in [-45.0, 0.0, 45.0, 90.0]
        cl = naca4412_cl(α, 1e5)
        @test isfinite(cl)
    end
end

@testset "naca4412_cd — cambered airfoil drag" begin
    # CD at α=0° near CD_min
    @test naca4412_cd(0.0, 1e6) < 0.015

    # CD increases with |α|
    @test naca4412_cd(8.0, 1e5) > naca4412_cd(4.0, 1e5)

    # Higher Re → lower CD
    @test naca4412_cd(0.0, 1e6) < naca4412_cd(0.0, 1e5)

    # Post-stall CD rises
    @test naca4412_cd(30.0, 1e5) > naca4412_cd(10.0, 1e5)
end
