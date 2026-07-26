# Source Inventory — CoaxialAutogyroStacking.jl

> Every file in the repository with a one-line purpose. Update when files are
> added, renamed, or deleted. Used by agents to understand the project structure.

## Project docs (7 files)

| File | Purpose |
|------|---------|
| `SPEC.md` | Specification — source of truth for scope, design, interface contracts, sweep results (v1 PCA-2 + v2.1 BEM) |
| `PLAN.md` | Implementation roadmap — Phases 1–10 with task breakdowns, key decisions |
| `CONTEXT.md` | Domain glossary — terms (autogyro, stack, tension profile, PCA-2, BEM, etc.) |
| `AGENTS.md` | Working conventions — TDD loop, file map, naming, scope guard |
| `CLAUDE.md` | Quick entry point — redirects to AGENTS.md + PLAN.md |
| `PHASE9_PLAN.md` | Mechanical design specification — tasks 9a–9f, complete |
| `SOURCE_INVENTORY.md` | This file — complete file inventory |

## Source (11 files)

| File | Purpose |
|------|---------|
| `src/CoaxialAutogyroStacking.jl` | Module entry — includes all source files, exports all public names |
| `src/pca2_data.jl` | PCA-2 empirical CL/CD data tables + `pca2_interp()` linear interpolation (v1) |
| `src/airfoil_data.jl` | NACA 0012 CL/CD tables at Re = 10⁵, 2×10⁵, 5×10⁵, 10⁶ (v2) |
| `src/rotor.jl` | `AutogyroRotor` struct + `rotor_disk_area()`, `effective_alpha()`, `rotor_force_along_line()`, `rotor_tip_speed()`, `rotor_reynolds_number()`, `estimated_autorotation_rpm()` |
| `src/bem.jl` | BEM autorotation solver — `bem_induction()` bisection, `bem_rotor_forces()` (v2) |
| `src/polygon_line.jl` | Polygon chain geometry — `solve_polygon_angles()` Jacobi iteration (v2) |
| `src/line_section.jl` | `bare_line_drag()`, `line_mass_per_m()`, `line_weight_along_line()` — Dyneema line physics |
| `src/stack.jl` | `AutogyroStack` struct + `stack_tension_profile()` — progressive tension accumulation with line weight |
| `src/optimisation.jl` | `optimal_rotor_tilt()`, `optimal_rotor_tilts()`, `lift_force_steady()`, `optimal_rotor_tilts_bem()` — grid-search optimisation |
| `src/sweep.jl` | `parameter_sweep()`, `parameter_sweep_bem()`, `compute_figures_of_merit()`, `pareto_front()` — v1 PCA-2 + v2 BEM sweeps |
| `src/viability.jl` | `viability_report()` — physical viability checks (Re, tip speed, line weight) |
| `src/stall_delay.jl` | `snel_cl_3d()` — Snel 3-D rotational augmentation correction (v2.1) |

## Tests (12 files, 345 tests)

| File | Purpose |
|------|---------|
| `test/runtests.jl` | Suite entry — includes all test files, runs full suite |
| `test/test_pca2_data.jl` | PCA-2 interpolation tests |
| `test/test_airfoil_data.jl` | NACA 0012 table integrity, Re coverage |
| `test/test_bem.jl` | BEM induction bisection, torque convergence, force scaling |
| `test/test_polygon_line.jl` | Polygon angle solver convergence, force equilibrium |
| `test/test_rotor.jl` | Rotor construction, area, effective α, forces, tip speed, Reynolds |
| `test/test_line_section.jl` | Line drag, mass per metre, weight along line |
| `test/test_stack.jl` | Stack construction, tension profile monotonicity, anchor tension, line weight |
| `test/test_optimisation.jl` | Optimal pitch grid search, constraint handling, BEM tilt optimisation |
| `test/test_sweep.jl` | Parameter sweep correctness, figure-of-merit computation, viability columns |
| `test/test_viability.jl` | Viability report fields, Re/noise/weight checks |
| `test/test_stall_delay.jl` | Snel correction at design-point and root stations |

## Notebooks (2 active)

| File | Purpose |
|------|---------|
| `notebooks/dashboard.jl` | GLMakie interactive dashboard — sliders for all parameters, HUD |
| `notebooks/sweep_plots.jl` | Pluto notebook for sweep result visualisation |

## Scripts (3 files)

| File | Purpose |
|------|---------|
| `scripts/dashboard.jl` | Standalone dashboard launcher — `julia --project=. scripts/dashboard.jl` |
| `scripts/bem_full_sweep.jl` | BEM parameter sweep runner — 384 configurations, ~15 s (v2.1) |
| `schematics/generate_params.jl` | Julia → OpenSCAD parameter exporter — auto-generates `schematics/parameters.scad` |

## Schematics (Phase 9, ~30 files)

| File | Purpose |
|------|---------|
| `schematics/PRD.md` | Product Requirements Document — element inventory, coordinate system, forces |
| `schematics/DIMENSIONS.md` | Dimensioned components with safety margins |
| `schematics/parameters.scad` | Shared parameters — auto-generated from Julia model |
| `schematics/single_unit.scad` | Full 3D assembly of single autogyro unit (344 lines) |
| `schematics/stack.scad` | 4-unit stack assembly in world space (128 lines) |
| `schematics/generate_params.jl` | Parameter export script (see Scripts above) |
| `schematics/assembly_v4.pdf` | LaTeX dimensioned cross-section (103 KB) |
| `schematics/renders/single_unit_iso_v2.png` | Isometric render |
| `schematics/renders/single_unit_front_v2.png` | Front view render |
| `schematics/renders/single_unit_side_v2.png` | Side view render |
| `schematics/renders/assembly_cross_section_v4.svg` | Vector cross-section |
| `schematics/archive/` | Archived earlier versions (v2 scad, tex renders, test renders) |

## Sweep outputs (6 files)

| File | Purpose |
|------|---------|
| `sweep_results.tsv` | 1,728 post-processed sweep configurations (from 8,640 raw evaluations) |
| `bem_full_sweep.tsv` | 384 BEM sweep configurations (v2.1) |
| `sweep_heatmap_radius_stack.png` | Heatmap: anchor tension vs radius × stack count |
| `sweep_pareto_tension_cv.png` | Pareto front: anchor tension vs gust stability (CV) |
| `sweep_pareto_tension_mass.png` | Pareto front: anchor tension vs mass efficiency (N/kg) |
| `sweep_profile_comparison.png` | Tilt profile comparison: uniform vs graded vs top-draggy vs bottom-lifty |
| `sweep_tension_vs_wind.png` | Anchor tension vs wind speed for best configuration |

## Docs (4 files)

| File | Purpose |
|------|---------|
| `docs/make.jl` | Documenter.jl build script |
| `docs/agents/domain.md` | Agent onboarding — quick start, repo map, physics TL;DR, current state |
| `docs/agents/issue-tracker.md` | GitHub Issues workflow |
| `docs/agents/triage-labels.md` | Standard triage label state machine |

## Package config (2 files)

| File | Purpose |
|------|---------|
| `Project.toml` | Julia package manifest — name, UUID, dependencies, compat bounds |
| `Manifest.toml` | Exact dependency versions (auto-generated) |

---

**Last updated:** 2026-07-26 (post-v2.1 — BEM, polygon line, Snel stall delay all complete. 345 tests green.)
