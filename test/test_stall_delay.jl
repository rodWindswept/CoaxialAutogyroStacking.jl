# test/test_stall_delay.jl — Snel stall-delay correction tests
# Phase 10f (v2.1): 3-D rotational augmentation for BEM

const C = CoaxialAutogyroStacking

@testset "snel_cl_3d" begin

    # ── Basic existence and return type ──────────────────────────────────────
    result = C.snel_cl_3d(0.5, 10.0, 2.0, 0.1)
    @test result isa Float64

    # ── Zero at zero lift ────────────────────────────────────────────────────
    @test C.snel_cl_3d(0.0, 0.0, 2.0, 0.1) ≈ 0.0 atol=1e-12

    # ── Linear range: no correction when CL_2D ≥ CL_pot ─────────────────────
    # At α=5°, XFoil CL ≈ 0.61 > CL_pot(2π×5°≈0.55), so CL_3D = CL_2D
    cl_2d_5 = C.naca0012_cl(5.0, 1e5)
    cl_3d_5 = C.snel_cl_3d(cl_2d_5, 5.0, 3.0, 0.1)
    @test cl_3d_5 ≈ cl_2d_5 atol=1e-12

    # ── Post-stall: CL_3D > CL_2D (stall delay adds lift) ───────────────────
    cl_post = C.snel_cl_3d(0.3, 20.0, 3.0, 0.1)
    @test cl_post > 0.3

    # ── Stronger correction at higher c/r (near root) ────────────────────────
    cl_root = C.snel_cl_3d(0.3, 20.0, 3.0, 0.5)
    cl_tip = C.snel_cl_3d(0.3, 20.0, 3.0, 0.05)
    @test cl_root > cl_tip

    # ── Deep stall (α > 60°): g=0 → CL_3D = CL_2D ───────────────────────────
    cl_deep = C.snel_cl_3d(0.2, 65.0, 3.0, 0.1)
    @test cl_deep ≈ 0.2 atol=0.02

    # ── Higher local TSR → stronger correction ───────────────────────────────
    cl_tsr_low = C.snel_cl_3d(0.3, 20.0, 1.0, 0.1)
    cl_tsr_high = C.snel_cl_3d(0.3, 20.0, 10.0, 0.1)
    @test cl_tsr_high > cl_tsr_low

    # ── Sanity: correction is never negative ─────────────────────────────────
    for alpha_deg in [0.0, 5.0, 15.0, 25.0, 40.0, 55.0, 70.0, 85.0]
        cl_2d = C.naca0012_cl(alpha_deg, 1e5)
        cl_3d = C.snel_cl_3d(cl_2d, alpha_deg, 3.0, 0.15)
        @test cl_3d >= cl_2d - 1e-12  # never worse than 2-D
    end
end

@testset "snel_blending_g" begin
    # g(α) blending function
    # g=1 for 0<α<30, g=0.5(1+cos(6α-180)) for 30<α<60, g=0 for α≥60

    @test C._snel_blending_g(0.0) ≈ 1.0
    @test C._snel_blending_g(15.0) ≈ 1.0
    @test C._snel_blending_g(30.0) ≈ 1.0 atol=0.01
    @test C._snel_blending_g(45.0) ≈ 0.5 atol=0.01
    @test C._snel_blending_g(60.0) ≈ 0.0 atol=0.01
    @test C._snel_blending_g(90.0) ≈ 0.0 atol=0.01

    # Continuity at boundaries
    @test C._snel_blending_g(30.0) ≈ 1.0 atol=0.01
end
