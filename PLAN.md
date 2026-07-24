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
Phase 9    → DONE  ✓  (Mechanical design specification)
Phase 10   → NEXT    (BEM autorotation, polygon line geometry)
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

- [ ] `parameter_sweep()` passes tests
- [ ] Sweep completes and produces a results CSV
- [ ] Notebook generates Pareto-front plots
- [ ] SPEC.md §6 populated with key findings
- [ ] All existing tests still green

---

## Phase 8.5 — Viability Gates (Post-PR #1 Integration)

### Goal

Wire Cameron's new functions (`rotor_tip_speed`, `rotor_reynolds_number`,
`line_mass_per_m`, `line_weight_along_line`) into the stack model and sweep
pipeline so every configuration is checked against physical viability
constraints.

### Background

PR #1 (cameron-read-git, 2026-07-13) added four functions that give us the
physics to answer three questions the model couldn't ask before:

1. **Noise:** Is the blade tip speed below 120 m/s (Mach 0.3)?
2. **Trust:** Is Re > 5×10⁵ (PCA-2 data valid)?
3. **Weight:** How much does the line itself weigh, and is it accounted for
   in the tension budget?

These functions exist and are tested (159/159 green) but aren't yet wired
into `stack_tension_profile`, `parameter_sweep`, or any consumer API.

### Tasks

| # | Task | Where | What | Status |
|---|------|-------|------|--------|
| 1 | Add `line_density` field | `AutogyroStack` struct | Dyneema density (default 970 kg/m³). | ✓ |
| 2 | Wire line weight into tension | `stack_tension_profile` | Add `line_weight_along_line` term to the `delta` accumulation. | ✓ |
| 3 | Add tip_speed column | `parameter_sweep` | Compute `rotor_tip_speed` for the top rotor (or max across stack). | ✓ |
| 4 | Add tip_reynolds column | `parameter_sweep` | Compute `rotor_reynolds_number` at each wind speed. | ✓ |
| 5 | Create `viability_report` | New function | Single entry point for physical viability checks. | ✓ |
| 6 | Add Re/noise to Pareto filter | `compute_figures_of_merit` | Optional keyword to exclude configurations below Re threshold or above noise limit. | ✓ |

### Design Decision Needed

**Task 1:** Adding `line_density` to `AutogyroStack` is a breaking struct
change. Alternative: pass `line_density` as a keyword argument to
`stack_tension_profile` with default 970.0. The struct approach is cleaner
(long-term — line properties belong with the line) but breaks existing
constructor calls. **Decide before implementing.**

### Definition of Done

- [x] `stack_tension_profile` includes line self-weight term
- [x] `parameter_sweep` outputs `tip_speed` and `tip_reynolds` columns
- [x] `viability_report()` function exists and is tested
- [x] Re/noise filters available on Pareto front
- [x] All existing tests still green
- [ ] SPEC.md §5.1 (v1 limitations) updated to note Re regime awareness

---

## Phase 9 — Mechanical Design Specification

### Goal

Complete the mechanical design of a single lifting autogyro kite unit,
documented in schematics and 3D models.

### Tasks

1. Finalise dual-molding sandwich bearing geometry with correct tilt axis ✓
2. Dimension swashplate, actuator mounts, pushrod linkage ✓
3. Size empennage (H-stab, V-fin) for trim authority at target AoA ✓
4. Specify webbing capture and spliced-eye Dyneema integration ✓
5. Generate fabrication-ready drawings (OpenSCAD → dimensioned SVG/PDF) ✓

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
- [x] All 193 tests green ✓

---

## Phase 10 — v2.0 Dynamics (planned)

### Goal

Upgrade from steady-state disk model to time-stepping BEM with polygon line
geometry.

### Key Changes

- Blade-element momentum replaces PCA-2 lookup
- Rotor RPM solved from torque equilibrium each timestep
- Line segments at independent angles (polygon chain, not straight line)
- Graded stacking becomes the primary optimisation variable
- SPEC.md updated with v2 limitations and interface contracts

---

## File Map

```
CoaxialAutogyroStacking.jl/
├── SPEC.md                    ← specification (source of truth)
├── PLAN.md                    ← this file (implementation road map)
├── CONTEXT.md                 ← glossary of domain terms
├── AGENTS.md                  ← working conventions for contributors
├── Project.toml
├── src/
│   ├── CoaxialAutogyroStacking.jl   ← module entry
│   ├── pca2_data.jl                 ← PCA-2 empirical data
│   ├── rotor.jl                     ← AutogyroRotor + forces
│   ├── line_section.jl              ← bare line drag
│   ├── stack.jl                     ← AutogyroStack + tension profile
│   ├── optimisation.jl              ← optimal_rotor_tilt / optimal_rotor_tilts / lift_force_steady
│   └── sweep.jl                     ← parameter_sweep (Phase 8)
├── test/
│   ├── runtests.jl
│   ├── test_pca2_data.jl
│   ├── test_rotor.jl
│   ├── test_line_section.jl
│   ├── test_stack.jl
│   ├── test_optimisation.jl
│   └── test_sweep.jl                (Phase 8)
├── notebooks/
│   ├── dashboard.jl                 ← GLMakie interactive dashboard
│   └── sweep_results.jl             ← Pluto Pareto-front notebook (Phase 8)
├── schematics/
│   ├── assembly_v2.tex/pdf          ← cross-section of single unit
│   ├── rotor_assembly_v2.scad/png   ← 3D single unit
│   ├── rotor_stack_world.scad/png   ← 3D stack in world space
│   ├── tube_capture.tex/pdf         ← webbing + spliced eye detail
│   └── inline_autogyro_mech.tex/pdf ← bearing approach comparison
└── scripts/
    └── dashboard.jl                 ← standalone dashboard launcher
```

---

## Key Decisions

1. **PCA-2 empirical data** — same validated tables as KTD.jl/src/lift_kite.jl
2. **No wake interaction** — downstream rotors see freestream; wakes deferred to v3
3. **Independent pitch → effective AoA shift** — computationally cheap, physically grounded
4. **Standalone, integration-ready** — `lift_force_steady` dispatch pattern mirrors KTD.jl
5. **TDD throughout** — every function: RED → GREEN → REFACTOR
6. **Topmost rotor terminates the line** — no phantom free-end section (fixed Phase 7)
7. **SPEC.md is the source of truth** — PLAN.md is implementation only

---

## Working Conventions

See [`AGENTS.md`](AGENTS.md). Key points:

- Strict TDD: RED → GREEN → REFACTOR, one task at a time
- SI units, angles in degrees at API boundary
- Rotors ordered top→bottom, section_lengths has n_rotors entries
- Pure functions, immutable structs
- One commit per phase, master stays green
