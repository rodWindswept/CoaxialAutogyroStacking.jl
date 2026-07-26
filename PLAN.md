# Coaxial Autogyro Stacking — Implementation Plan

> **Goal:** A Julia package that sweeps parameter space for multiple
> independently-pitched autogyro rotors stacked on a kite line, computing
> forces, tension profiles, and viability metrics. Built TDD for eventual
> integration into `KiteTurbineDynamics.jl`.

**Source of truth:** [`SPEC.md`](SPEC.md) — scope, definitions, interface contracts, phased evolution.
`PLAN.md` is the implementation road map. When they conflict, SPEC.md wins.

**Architecture:** Standalone Julia package mirroring KiteTurbineDynamics naming,
dispatch, and unit conventions. PCA-2 empirical rotor-disk data drives lift/drag
in v1; blade-element momentum (BEM) planned for v2. Progressive tension
accumulation from topmost rotor (terminates the line) down to anchor.

---

## Phase Map

```
Phase 1–5  → DONE  ✓  (PCA-2 data, rotor model, line drag, stack, optimisation)
Phase 6    → DONE  ✓  (Quality gates: 84 tests green)
Phase 7    → DONE  ✓  (Disk tilt/collective refactor, GLMakie dashboard)
Phase 8    → DONE  ✓  (Parameter sweep, Pareto analysis, SPEC.md §6 findings)
Phase 8.5  → DONE  ✓  (Viability gates: line weight, noise, Reynolds — PR #3 merged)
Phase 8.6  → DONE  ✓  (Doc staleness sweep, pca2 assertion, HANDOVER.md)
Phase 9    → DONE  ✓  (Mechanical design specification)
Phase 10   → DONE  ✓  (v2.0 BEM autorotation, polygon line geometry)
Phase 10f  → DONE  ✓  (v2.1 Snel 3-D stall delay correction)
```

---

## Phase 8 — v1 Parameter Sweep

### Goal

Sweep rotor radius, stack count, spacing, tilt profile, wind speed, and line
elevation to discover viable stacked autogyro configurations. Output a
Pareto front of anchor tension vs mass efficiency vs gust stability.

### Sweep Configuration

| Parameter | Values |
|-----------|--------|
| Rotor radius (m) | 0.5, 1.0, 1.5, 2.0, 2.5, 3.0 |
| Stack count N | 1, 2, 3, 4 |
| Spacing (m) | 5, 10, 15, 20, 25, 30 |
| Tilt profile | uniform, top-draggy, bottom-lifty, graded |
| Wind speed (m/s) | 4, 6, 8, 10, 12 |
| Line elevation (°) | 45, 55, 65 |

**Fixed parameters:** 2 blades, 4 mm Dyneema, 5 kg mass per rotor, PCA-2 disk model, straight line (v1 limitation).

### Tasks

1. **Write `src/sweep.jl`** — `parameter_sweep(config)` function returning a DataFrame of results
2. **Write `notebooks/sweep_results.jl`** — Pluto notebook with interactive Pareto-front plots
3. **Run sweep** — ~8,640 evaluations (6×4×6×4×5×3), seconds on modern hardware
4. **Analyse** — identify Pareto-optimal configurations across the three figures of merit
5. **Backfill SPEC.md §6–7** — key findings, recommended configurations

### Figures of Merit

- Anchor tension (N) — raw lift
- Anchor tension per unit rotor mass (N/kg) — mass efficiency
- Tension coefficient of variation across wind speeds — gust stability

### Definition of Done

- [x] `parameter_sweep()` passes tests
- [x] Sweep completes and produces a results CSV
- [x] Notebook generates Pareto-front plots
- [x] SPEC.md §6 populated with key findings
- [x] All existing tests still green

---

## Phase 8.5 — Viability Gates (Post-PR #1 Integration)

### Goal

Wire Cameron's new functions (`rotor_tip_speed`, `rotor_reynolds_number`,
`line_mass_per_m`, `line_weight_along_line`) into the stack model and sweep
pipeline so every configuration is checked against physical viability
constraints.

### Tasks

| # | Task | Where | What | Status |
|---|------|-------|------|--------|
| 1 | Add `line_density` field | `AutogyroStack` struct | Dyneema density (default 970 kg/m³). | ✓ |
| 2 | Wire line weight into tension | `stack_tension_profile` | Add `line_weight_along_line` term to the `delta` accumulation. | ✓ |
| 3 | Add tip_speed column | `parameter_sweep` | Compute `rotor_tip_speed` for the top rotor (or max across stack). | ✓ |
| 4 | Add tip_reynolds column | `parameter_sweep` | Compute `rotor_reynolds_number` at each wind speed. | ✓ |
| 5 | Create `viability_report` | New function | Single entry point for physical viability checks. | ✓ |
| 6 | Add Re/noise to Pareto filter | `compute_figures_of_merit` | Optional keyword to exclude configurations below Re threshold or above noise limit. | ✓ |

### Definition of Done

- [x] `stack_tension_profile` includes line self-weight term
- [x] `parameter_sweep` outputs `tip_speed` and `tip_reynolds` columns
- [x] `viability_report()` function exists and is tested
- [x] Re/noise filters available on Pareto front
- [x] All existing tests still green
- [x] SPEC.md §5.1 (v1 limitations) updated to note Re regime awareness ✓

---

## Phase 8.6 — Doc Staleness Sweep & Agent Handover

### Goal

Fix stale documentation references, guard the `pca2_interp` external dependency,
and establish `HANDOVER.md` for Cameron's agent.

### Tasks

| # | Task | Where | What |
|---|------|-------|------|
| 1 | Fix broken/stale file maps | `PLAN.md`, `AGENTS.md` | Synchronise `src/` (12 modules) and `test/` (12 modules) file maps |
| 2 | Guard `pca2_interp` output | `test/test_pca2_data.jl` | One `@test pca2_interp(α, λ) ≈ KNOWN_VALUE` assertion locking PCA-2 table for KTD |
| 3 | Create `HANDOVER.md` | root | Comprehensive handover guide with academic/investor result framing and chart exploration framework |

### Definition of Done

- [x] File maps in PLAN.md and AGENTS.md match `src/` and `test/` contents
- [x] `pca2_interp` has a locked-down output assertion in the test suite
- [x] `HANDOVER.md` exists in root with post-pull checklist & charting exploration guide
- [x] All existing tests still green

---

## Phase 9 — Mechanical Design Specification

### Goal

Complete the mechanical design of a single lifting autogyro kite unit,
documented in schematics and 3D models.

### Definition of Done

- [x] Schematics/PRD.md — complete element inventory, coordinate system, forces ✓
- [x] Schematics/DIMENSIONS.md — dimensioned components with safety margins ✓
- [x] Schematics/parameters.scad — auto-generated from Julia model ✓
- [x] Schematics/single_unit.scad — full 3D assembly (343 lines) ✓
- [x] Schematics/assembly_v4.pdf — dimensioned LaTeX cross-section (103 KB) ✓
- [x] Schematics/renders/single_unit_iso_v2.png — isometric render ✓
- [x] Schematics/renders/single_unit_front_v2.png — front view ✓
- [x] Schematics/renders/single_unit_side_v2.png — side view ✓
- [x] Schematics/renders/assembly_cross_section_v4.svg — vector cross-section ✓

---

## Phase 10 & 10f — v2.0 & v2.1 BEM Dynamics

### Goal

Upgrade from steady-state disk model to BEM autorotation, polygon line geometry,
and 3-D Snel stall delay.

### Key Features Completed

- Blade-element momentum replaces PCA-2 lookup ([`src/bem.jl`](src/bem.jl))
- Airfoil polars for NACA 0012 ([`src/airfoil_data.jl`](src/airfoil_data.jl))
- Snel 3-D stall-delay correction ([`src/stall_delay.jl`](src/stall_delay.jl))
- Polygon line geometry equilibrium solver ([`src/polygon_line.jl`](src/polygon_line.jl))
- Full 384-configuration BEM parameter sweep ([`bem_full_sweep.tsv`](bem_full_sweep.tsv))

---

## File Map

```
CoaxialAutogyroStacking.jl/
├── SPEC.md                    ← specification (source of truth)
├── PLAN.md                    ← implementation roadmap (this file)
├── HANDOVER.md                ← agent handover, result framing & charting guide
├── CONTEXT.md                 ← glossary of domain terms
├── AGENTS.md                  ← working conventions for contributors
├── Project.toml
├── src/
│   ├── CoaxialAutogyroStacking.jl   ← module entry
│   ├── airfoil_data.jl              ← NACA 0012 polar lookup tables
│   ├── bem.jl                       ← BEM solver + autorotation RPM
│   ├── line_section.jl              ← bare line drag
│   ├── optimisation.jl              ← optimal_rotor_tilt / optimal_rotor_tilts
│   ├── pca2_data.jl                 ← PCA-2 empirical data + pca2_interp
│   ├── polygon_line.jl              ← polygon chain line geometry
│   ├── rotor.jl                     ← AutogyroRotor + forces
│   ├── stack.jl                     ← AutogyroStack + tension profile
│   ├── stall_delay.jl               ← Snel 3-D stall delay correction
│   ├── sweep.jl                     ← parameter_sweep (PCA-2 and BEM)
│   └── viability.jl                 ← tip speed, Reynolds & viability checks
├── test/
│   ├── runtests.jl
│   ├── test_airfoil_data.jl
│   ├── test_bem.jl
│   ├── test_line_section.jl
│   ├── test_optimisation.jl
│   ├── test_pca2_data.jl
│   ├── test_polygon_line.jl
│   ├── test_rotor.jl
│   ├── test_stack.jl
│   ├── test_stall_delay.jl
│   ├── test_sweep.jl
│   └── test_viability.jl
├── notebooks/
│   ├── dashboard.jl                 ← Pluto interactive dashboard
│   └── sweep_plots.jl               ← Pluto / CairoMakie Pareto plots
├── schematics/
│   ├── single_unit.scad             ← 3D single unit
│   ├── assembly_cross_section_v4.svg← vector cross-section
│   └── renders/                     ← PNG renders
└── scripts/
    ├── bem_full_sweep.jl            ← full BEM parameter sweep script
    └── dashboard.jl                 ← GLMakie standalone dashboard launcher
```

---

## Key Decisions

1. **PCA-2 empirical data** — validated tables for v1 steady disk model.
2. **BEM + Snel 3D Stall Delay** — physics baseline for v2; 2D $C_L$ solves induction, 3D $C_{L,3D}$ computes force.
3. **No wake interaction (v1 & v2)** — downstream rotors see freestream; wakes deferred to v3.
4. **Standalone, integration-ready** — `lift_force_steady` dispatch pattern mirrors KTD.jl.
5. **Strict TDD throughout** — RED → GREEN → REFACTOR for all tasks.
