# test/test_viability.jl — viability_report: single entry point for physical
# viability checks (Phase 8.5 Task 5)

@testset "viability_report" begin

    @testset "Reynolds gate fails for small rotors at low wind" begin
        # Standard test rotor: chord 0.15 m, tilt 10° on a 50° line → α_eff = 50°
        # v_tip = λ·v·sind(50°) = 2.5 × 8 × 0.766 ≈ 15.3 m/s
        # Re = ρ·v_tip·c/μ = 1.225 × 15.3 × 0.15 / 1.81e-5 ≈ 1.6e5  < 5e5
        # → PCA-2 data untrustworthy at this scale; the gate must say so.
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r, r, r],
            [3.0, 3.0, 9.0],
            0.004,
            50.0,
        )
        rep = CoaxialAutogyroStacking.viability_report(stack, 1.225, 8.0)
        @test rep.reynolds_ok == false
    end

    @testset "noise gate — max tip speed across stack vs 120 m/s" begin
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r, r, r], [3.0, 3.0, 9.0], 0.004, 50.0)

        # Quiet case: v_tip = λ·v·sind(α_eff) = 2.5 × 8 × sind(50°) ≈ 15.3 m/s ≤ 120
        rep = CoaxialAutogyroStacking.viability_report(stack, 1.225, 8.0)
        @test rep.noise_ok == true

        # Loud case: storm wind 65 m/s → v_tip ≈ 2.5 × 65 × 0.766 ≈ 124.5 > 120
        rep_loud = CoaxialAutogyroStacking.viability_report(stack, 1.225, 65.0)
        @test rep_loud.noise_ok == false

        # Worst-case-across-stack: quiet rotor on top (tilt −20° → α_eff = 20°,
        # v_tip ≈ 2.5 × 65 × sind(20°) ≈ 55.6 m/s) but loud rotor below (124.5).
        # The LOUDEST rotor sets the verdict — checking only the top rotor
        # would wrongly pass this stack.
        r_quiet = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, -20.0, 0.0, 5.0)
        r_loud  = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        graded = CoaxialAutogyroStacking.AutogyroStack(
            [r_quiet, r_loud], [3.0, 9.0], 0.004, 50.0)
        rep_graded = CoaxialAutogyroStacking.viability_report(graded, 1.225, 65.0)
        @test rep_graded.noise_ok == false
    end

    @testset "line_weight_fraction — line self-weight / total rotor lift" begin
        # Single rotor, 30 m of 4 mm Dyneema at 50°:
        # mass_per_m = 970 × π × 0.002² ≈ 0.0122 kg/m
        # line weight along line = 0.0122 × 30 × 9.81 × sind(50°) ≈ 2.75 N
        # rotor F_line ≈ 327 N  →  fraction ≈ 0.0084
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r], [30.0], 0.004, 50.0)
        rep = CoaxialAutogyroStacking.viability_report(stack, 1.225, 8.0)

        mass_per_m = CoaxialAutogyroStacking.line_mass_per_m(0.004, 970.0)
        expected_weight = CoaxialAutogyroStacking.line_weight_along_line(
            mass_per_m, 30.0, 9.81, 50.0)
        F_line, _, _, _, _ = CoaxialAutogyroStacking.rotor_force_along_line(
            r, 1.225, 8.0, 50.0)

        @test rep.line_weight_fraction ≈ expected_weight / F_line rtol=1e-6
        @test 0.0 < rep.line_weight_fraction < 0.05   # sanity: line is a small tax

        # Zero wind → zero rotor lift → the line weight infinitely dominates.
        rep_calm = CoaxialAutogyroStacking.viability_report(stack, 1.225, 0.0)
        @test isinf(rep_calm.line_weight_fraction)
    end

    @testset "warnings — empty when viable, informative when not" begin
        # PCA-2-scale rotor (R = 6.86 m, chord 0.56 m) at 15 m/s:
        # v_tip = 2.5 × 15 × sind(50°) ≈ 28.7 m/s  → quiet (≤ 120) ✓
        # Re = 1.225 × 28.7 × 0.56 / 1.81e-5 ≈ 1.1e6 → trustworthy (≥ 5e5) ✓
        big = CoaxialAutogyroStacking.AutogyroRotor(6.86, 0.2, 3, 0.56, 10.0, 0.0, 30.0)
        big_stack = CoaxialAutogyroStacking.AutogyroStack(
            [big], [30.0], 0.006, 50.0)
        rep_ok = CoaxialAutogyroStacking.viability_report(big_stack, 1.225, 15.0)
        @test rep_ok.reynolds_ok == true
        @test rep_ok.noise_ok == true
        @test rep_ok.warnings isa Vector{String}
        @test isempty(rep_ok.warnings)

        # Small rotors at 8 m/s: Reynolds gate fails → warning names the problem
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        small_stack = CoaxialAutogyroStacking.AutogyroStack(
            [r, r, r], [3.0, 3.0, 9.0], 0.004, 50.0)
        rep_re = CoaxialAutogyroStacking.viability_report(small_stack, 1.225, 8.0)
        @test any(w -> occursin("Reynolds", w), rep_re.warnings)

        # Storm wind 65 m/s: noise gate also fails → warning mentions tip speed
        rep_storm = CoaxialAutogyroStacking.viability_report(small_stack, 1.225, 65.0)
        @test any(w -> occursin("tip speed", w), rep_storm.warnings)
    end

    @testset "thresholds are keyword-adjustable" begin
        r = CoaxialAutogyroStacking.AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0)
        stack = CoaxialAutogyroStacking.AutogyroStack(
            [r, r, r], [3.0, 3.0, 9.0], 0.004, 50.0)

        # Lenient Reynolds floor (1e5): the small stack (Re ≈ 1.6e5) now passes
        rep = CoaxialAutogyroStacking.viability_report(
            stack, 1.225, 8.0; reynolds_min=1.0e5)
        @test rep.reynolds_ok == true
        @test isempty(rep.warnings)

        # Strict noise limit (10 m/s): the same stack (v_tip ≈ 15.3) now fails
        rep_strict = CoaxialAutogyroStacking.viability_report(
            stack, 1.225, 8.0; tip_speed_limit=10.0)
        @test rep_strict.noise_ok == false
        @test any(w -> occursin("tip speed", w), rep_strict.warnings)
    end
end
