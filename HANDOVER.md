# HANDOVER.md — CoaxialAutogyroStacking.jl Handover & Agent Guide

Target audience: Cameron and Cameron's AI agent.
Repository: `CoaxialAutogyroStacking.jl`.
Status: All 348 tests green (`julia --project=. test/runtests.jl`).

## 1. Post-Pull Checklist

After pulling `master`, do these three steps:

1. Run the test suite:
   ```
   julia --project=. test/runtests.jl
   ```
   All 348 tests must pass.

2. Run the doc staleness sweep:
   - Check that new `src/` modules appear in `AGENTS.md` and `PLAN.md`.
   - Check that doc examples use the current constructor signatures.
   - Check that exports in `CoaxialAutogyroStacking.jl` match docstrings.

3. Check quality invariants:
   - Tension increases from top rotor to anchor. No decreases.
   - Forces scale with v².
   - Zero wind returns only the mass-based tension.

## 2. Current BEM Performance Data

The best configuration (post polygon-fix, commit 473a316):

| Parameter | Value |
|-----------|-------|
| Radius | 3.0 m |
| Stack count | 4 |
| Profile | graded |
| Elevation | 45° |
| Mean anchor tension | 839 N (across 4,6,8,10,12 m/s) |
| Peak anchor tension | 1,412 N (at 12 m/s) |
| Tip speed | 23–38 m/s |
| Tip Reynolds | 2×10⁵ to 4×10⁵ |

Tilt profile has a small effect. The spread across all four profiles is
under 4%. Graded tilt is best. Uniform tilt is the pragmatic choice for
manufacturing.

## 3. Chart Reference

All charts live in `diagrams/<slug>/` with SPEC.md, script, PNG, and PDF.
See `DIAGRAM_REGISTRY.md` for the complete index — 32+ diagrams total
(7 approved, 11 R1 data-integrity passed, 14 R1 prototype conversions).

## 4. File Map

```
src/
  CoaxialAutogyroStacking.jl   module entry
  airfoil_data.jl              NACA 0012 tables
  bem.jl                       BEM solver and autorotation RPM
  line_section.jl              bare line drag
  optimisation.jl              tilt profile optimisation
  pca2_data.jl                 PCA-2 empirical data
  polygon_line.jl              polygon chain solver
  rotor.jl                     AutogyroRotor and forces
  stack.jl                     AutogyroStack and tension profile
  stall_delay.jl               Snel 3-D stall delay
  sweep.jl                     parameter sweep (PCA-2 and BEM)
  viability.jl                 viability checks

test/                          11 test files (348 tests)
notebooks/                     dashboard.jl, sweep_plots.jl
schematics/                    OpenSCAD models and renders
scripts/                       bem_full_sweep.jl, dashboard.jl, gen_pca2_sweep.jl, gen_comparison_sweep.jl
```

## 5. Definition of Done

1. Strict TDD: failing test, minimal implementation, refactor.
2. Export public functions. Add docstrings.
3. One commit per task. Prefix with the phase.
4. Full test suite passes before every commit.
