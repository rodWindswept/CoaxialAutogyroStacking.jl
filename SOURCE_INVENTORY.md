# Source Inventory — CoaxialAutogyroStacking.jl

> Every file in the repository with a one-line purpose. Update when files are
> added, renamed, or deleted. Used by agents to understand the project structure.

## Project docs (7 files)

| File | Purpose |
|------|---------|
| `SPEC.md` | Specification — source of truth for scope, design, interface contracts, sweep results |
| `PLAN.md` | Implementation roadmap — Phases 1–10 with task breakdowns, key decisions |
| `CONTEXT.md` | Domain glossary — 23 terms (autogyro, stack, tension profile, PCA-2, etc.) |
| `AGENTS.md` | Working conventions — TDD loop, file map, naming, scope guard |
| `CLAUDE.md` | Quick entry point — redirects to AGENTS.md + PLAN.md |
| `PHASE9_PLAN.md` | Mechanical design specification skeleton — tasks 9a–9f |
| `HANDOFF_2026-06-12_dashboard.md` | Dashboard implementation handoff — what was done, what remains |

## Source (6 files)

| File | Purpose |
|------|---------|
| `src/CoaxialAutogyroStacking.jl` | Module entry — includes all source files, exports all public names |
| `src/pca2_data.jl` | PCA-2 empirical CL/CD data tables + `pca2_interp()` linear interpolation |
| `src/rotor.jl` | `AutogyroRotor` struct + `rotor_disk_area()`, `effective_alpha()`, `rotor_force_along_line()` |
| `src/line_section.jl` | `bare_line_drag()` — cylinder crossflow drag on Dyneema sections |
| `src/stack.jl` | `AutogyroStack` struct + `stack_tension_profile()` — progressive tension accumulation |
| `src/optimisation.jl` | `optimal_pitch()`, `optimal_pitches()`, `lift_force_steady()` — grid-search optimisation |
| `src/sweep.jl` | `parameter_sweep()`, `compute_figures_of_merit()`, `pareto_front()` — Phase 8 sweep |

## Tests (7 files, 143 tests)

| File | Purpose |
|------|---------|
| `test/runtests.jl` | Suite entry — includes all test files, runs full suite |
| `test/test_pca2_data.jl` | PCA-2 interpolation tests |
| `test/test_rotor.jl` | Rotor construction, area, effective α, forces |
| `test/test_line_section.jl` | Line drag scaling with velocity, diameter, length |
| `test/test_stack.jl` | Stack construction, tension profile monotonicity, anchor tension |
| `test/test_optimisation.jl` | Optimal pitch grid search, constraint handling |
| `test/test_sweep.jl` | Parameter sweep correctness, figure-of-merit computation |

## Notebooks (2 files)

| File | Purpose |
|------|---------|
| `notebooks/dashboard.jl` | GLMakie interactive dashboard — sliders for all parameters, HUD, power comparison |
| `notebooks/sweep_plots.jl` | Pluto notebook for sweep result visualisation |

## Scripts (1 file)

| File | Purpose |
|------|---------|
| `scripts/dashboard.jl` | Standalone dashboard launcher — `julia --project=. scripts/dashboard.jl` |

## Schematics (16 files, Phase 9)

| File | Purpose |
|------|---------|
| `schematics/assembly_v2.tex` | TikZ cross-section of single autogyro unit (dual-molding bearing, swashplate, empennage) |
| `schematics/assembly_v2.pdf` | Rendered assembly cross-section |
| `schematics/assembly_v2-1.png` | PNG export of assembly cross-section |
| `schematics/rotor_assembly_v2.scad` | OpenSCAD 3D model of single unit |
| `schematics/rotor_assembly_v2.png` | Rendered 3D view of single unit |
| `schematics/autogyro_stack.scad` | OpenSCAD 3D model of stacked rotors |
| `schematics/autogyro_stack.png` | Rendered 3D view of stacked rotors |
| `schematics/rotor_stack_world.scad` | OpenSCAD 3D model of stack in world space (with ground plane) |
| `schematics/rotor_stack_world.png` | Rendered 3D view of stack in world space |
| `schematics/tube_capture.tex` | TikZ detail of webbing capture + spliced-eye Dyneema integration |
| `schematics/tube_capture.pdf` | Rendered tube capture detail |
| `schematics/tube_capture-1.png` | PNG export of tube capture detail |
| `schematics/inline_autogyro_mech.tex` | TikZ comparison of bearing approach alternatives |
| `schematics/inline_autogyro_mech.pdf` | Rendered bearing comparison |
| `schematics/inline_autogyro_mech-1.png` | PNG export of bearing comparison |
| `schematics/stack_system_overview.tex` | TikZ system-level overview diagram |
| `schematics/stack_system_overview.pdf` | Rendered system overview |
| `schematics/stack_system_overview.png` | PNG export of system overview |

## Docs (7 files)

| File | Purpose |
|------|---------|
| `docs/src/index.md` | Documenter.jl package docs — installation, quickstart, conventions |
| `docs/src/api.md` | Auto-generated API reference — `@autodocs` from source docstrings |
| `docs/agents/domain.md` | Agent onboarding — quick start, repo map, physics TL;DR, current state |
| `docs/agents/issue-tracker.md` | GitHub Issues workflow — create/list/view/edit via `gh` CLI |
| `docs/agents/triage-labels.md` | Standard triage label state machine (needs-triage → ready-for-agent → wontfix) |
| `docs/audit-literature-crosscheck.md` | 11-point literature audit (2026-06-08) — critical findings against AWE wiki |
| `docs/make.jl` | Documenter.jl build script |

## Package config (2 files)

| File | Purpose |
|------|---------|
| `Project.toml` | Julia package manifest — name, UUID, dependencies, compat bounds |
| `Manifest.toml` | Exact dependency versions (auto-generated) |

## Sweep outputs (6 files)

| File | Purpose |
|------|---------|
| `sweep_results.tsv` | 1,728 post-processed sweep configurations (from 8,640 raw evaluations) |
| `sweep_heatmap_radius_stack.png` | Heatmap: anchor tension vs radius × stack count |
| `sweep_pareto_tension_cv.png` | Pareto front: anchor tension vs gust stability (CV) |
| `sweep_pareto_tension_mass.png` | Pareto front: anchor tension vs mass efficiency (N/kg) |
| `sweep_profile_comparison.png` | Tilt profile comparison: uniform vs graded vs top-draggy vs bottom-lifty |
| `sweep_tension_vs_wind.png` | Anchor tension vs wind speed for best configuration |

## Root (3 files)

| File | Purpose |
|------|---------|
| `Project.toml` | Julia package manifest |
| `Manifest.toml` | Exact dependency versions |
| `.gitignore` | Git ignore rules |

---

**Total: 52 tracked files** (7 project docs, 7 source, 7 test, 2 notebooks, 1 script, 18 schematics, 7 docs, 6 sweep outputs, 2 package config, 1 gitignore)

**Last updated:** 2026-06-22 (post-Phase 8 sweep, pre-Phase 9 mechanical design)
