# test/test_pca2_data.jl — PCA-2 empirical autogyro rotor disk data
# Data from NASA TM 20080022367

@testset "PCA-2 Data Module" begin

    @testset "Exact data points" begin
        # At α=0°: CL=0.00, CD=0.01
        cl0, cd0 = CoaxialAutogyroStacking.pca2_interp(0.0)
        @test cl0 ≈ 0.00 atol=1e-12
        @test cd0 ≈ 0.01 atol=1e-12

        # At α=15°: CL=0.45, CD=0.10
        cl15, cd15 = CoaxialAutogyroStacking.pca2_interp(15.0)
        @test cl15 ≈ 0.45 atol=1e-12
        @test cd15 ≈ 0.10 atol=1e-12

        # At α=40°: CL=0.95, CD=0.62
        cl40, cd40 = CoaxialAutogyroStacking.pca2_interp(40.0)
        @test cl40 ≈ 0.95 atol=1e-12
        @test cd40 ≈ 0.62 atol=1e-12

        # At α=90°: CL=0.00, CD=1.25
        cl90, cd90 = CoaxialAutogyroStacking.pca2_interp(90.0)
        @test cl90 ≈ 0.00 atol=1e-12
        @test cd90 ≈ 1.25 atol=1e-12
    end

    @testset "Linear interpolation midpoint" begin
        # At α=12.5° (midpoint between 10° and 15°):
        # CL = (0.30 + 0.45) / 2 = 0.375
        # CD = (0.06 + 0.10) / 2 = 0.08
        cl_mid, cd_mid = CoaxialAutogyroStacking.pca2_interp(12.5)
        @test cl_mid ≈ 0.375 atol=1e-12
        @test cd_mid ≈ 0.08 atol=1e-12
    end

    @testset "Interpolation between 15° and 20°" begin
        # At α=17.5°: CL = (0.45+0.60)/2=0.525, CD = (0.10+0.16)/2=0.13
        cl, cd = CoaxialAutogyroStacking.pca2_interp(17.5)
        @test cl ≈ 0.525 atol=1e-12
        @test cd ≈ 0.13 atol=1e-12
    end

    @testset "Boundary clamping" begin
        # Below range: -10° → clamp to 0°
        cl_neg, cd_neg = CoaxialAutogyroStacking.pca2_interp(-10.0)
        @test cl_neg ≈ 0.00 atol=1e-12
        @test cd_neg ≈ 0.01 atol=1e-12

        # Above range: 100° → clamp to 90°
        cl_high, cd_high = CoaxialAutogyroStacking.pca2_interp(100.0)
        @test cl_high ≈ 0.00 atol=1e-12
        @test cd_high ≈ 1.25 atol=1e-12
    end
end
