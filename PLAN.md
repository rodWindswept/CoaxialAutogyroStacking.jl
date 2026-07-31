# Coaxial Autogyro Stacking — Implementation Plan

> **Goal:** A Julia package that sweeps parameter space for multiple
> independently-pitched autogyro rotors stacked on a kite line, computing
> forces, tension profiles, and viability metrics. Built TDD for eventual
> integration into `KiteTurbineDynamics.jl`.

**Source of truth:** [`SPEC.md`](SPEC.md) — scope, definitions, interface contracts, phased evolution.
`PLAN.md` is the implementation road map. When they conflict, SPEC.md wins.

**Architecture:** Standalone Julia package mirroring KiteTurbineDynamics naming,
dispatch, and unit conventions. v1 uses PCA-2 empirical rotor-disk data for
lift/drag; v2.1 upgrades to blade-element momentum (BEM) with NACA 0012
airfoil data, polygon line geometry, and Snel 3-D stall-delay correction.
Progressive tension accumulation from topmost rotor (terminates the line)
down to anchor.

---

## Phase Map

```
Phase 1–5  → DONE  ✓  (PCA-2 data, rotor model, line drag, stack, optimisation)
Phase 6    → DONE  ✓  (Quality gates: 84 tests green)
Phase 7    → DONE  ✓  (Disk tilt/collective refactor, GLMakie dashboard)
Phase 8    → DONE  ✓  (Parameter sweep, Pareto analysis, SPEC.md §6 findings)
Phase 8.5  → DONE  ✓  (Viability gates: line weight, noise, Reynolds — PR #3 merged)
Phase 9    → DONE  ✓  (Mechanical design specification)
Phase 10   → DONE  ✓  (BEM autorotation, polygon line geometry, Snel stall delay)
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
- [x] Sweep completes and produces a results TSV (1,728 configs, `sweep_results.tsv`)
- [x] Notebook generates Pareto-front plots (`sweep_*.png`)
- [x] SPEC.md §6 populated with key findings
- [x] All existing tests still green

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
- [x] SPEC.md §5.1 (v1 limitations) updated to note Re regime awareness ✓

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

## Phase 10 — v2.1 BEM + Polygon Line + Stall Delay (done)

### Goal

Upgraded from steady-state PCA-2 disk model to blade-element momentum with
polygon line geometry and 3-D stall-delay correction.

### What Was Delivered

- **BEM autorotation** (`src/bem.jl`): RPM solved from torque equilibrium via
  bisection on `bem_induction`. NACA 0012 airfoil data (`src/airfoil_data.jl`)
  at Re = 10⁵, 2×10⁵, 5×10⁵, 10⁶ from XFoil/tables.
- **Polygon line geometry** (`src/polygon_line.jl`): segment angles solved by
  force equilibrium at each rotor (`solve_polygon_angles`). Graded stacking is
  now meaningful — top-rotor tilt reshapes the line, altering effective AoA
  for rotors below.
- **3-D stall delay** (`src/stall_delay.jl`): Snel correction for rotational
  augmentation. Improves root thrust but negligible at design-point tip stations.
  The BEM vs PCA-2 gap (~10× force difference at R=0.5 m) is a 2-D/disk-averaged
  fundamental limit, not a bug.
- **BEM-aware sweep** (`parameter_sweep_bem`, `optimal_rotor_tilts_bem`):
  384 configurations, 15.6 s runtime. Graded stacking confirmed: top_draggy
  profile yields +12.7% tension vs uniform at R=3.0 m, N=2.

### Key Findings (from SPEC.md §6.6)

- R=1.5m below viability threshold with NACA 0012; R=3.0m is practical minimum
- Tip speeds 23–38 m/s — well below 120 m/s noise limit
- RPM ∝ √v (sub-linear); tension ∝ v² (dynamic pressure)
- Profile optimum depends on radius: small rotors prefer bottom-lifty, large
  rotors prefer top-draggy

### Definition of Done

- [x] BEM autorotation via bisection on torque equilibrium
- [x] NACA 0012 airfoil tables at 4 Reynolds numbers
- [x] Polygon line force equilibrium solver (Jacobi iteration)
- [x] Snel 3-D stall-delay correction
- [x] BEM-aware parameter sweep and tilt optimisation
- [x] SPEC.md §6.6 populated with BEM sweep findings
- [x] All 345 tests green

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
│   ├── CoaxialAutogyroStacking.jl   ← module entry, includes + exports
│   ├── pca2_data.jl                 ← PCA-2 empirical data (v1)
│   ├── airfoil_data.jl              ← NACA 0012 CL/CD tables (v2, 4 Re values)
│   ├── rotor.jl                     ← AutogyroRotor + forces
│   ├── bem.jl                       ← BEM autorotation + bisection solver (v2)
│   ├── polygon_line.jl              ← polygon chain geometry solver (v2)
│   ├── line_section.jl              ← bare line drag
│   ├── stack.jl                     ← AutogyroStack + tension profile
│   ├── optimisation.jl              ← optimal_rotor_tilt / optimal_rotor_tilts / lift_force_steady
│   ├── sweep.jl                     ← parameter_sweep + Pareto-front (v1 PCA-2)
│   ├── viability.jl                 ← physical viability checks (Phase 8.5)
│   └── stall_delay.jl               ← Snel 3-D rotational correction (v2.1)
├── test/
│   ├── runtests.jl
│   ├── test_pca2_data.jl
│   ├── test_airfoil_data.jl
│   ├── test_bem.jl
│   ├── test_polygon_line.jl
│   ├── test_rotor.jl
│   ├── test_line_section.jl
│   ├── test_stack.jl
│   ├── test_optimisation.jl
│   ├── test_sweep.jl
│   ├── test_viability.jl
│   └── test_stall_delay.jl
├── notebooks/
│   ├── dashboard.jl                 ← GLMakie interactive dashboard
│   └── sweep_plots.jl               ← Pluto Pareto-front notebook (Phase 8)
├── scripts/
│   ├── dashboard.jl                 ← standalone dashboard launcher
│   ├── bem_full_sweep.jl            ← BEM parameter sweep runner (v2.1)
│   ├── gen_pca2_sweep.jl            ← PCA-2 sweep generator
│   ├── gen_comparison_sweep.jl      ← Snel on/off + solver iterations
│   ├── pca_analysis.py              ← PCA statistical analysis
│   └── pca_charts.py                ← PCA chart generator
├── schematics/
│   ├── parameters.scad              ← auto-generated from generate_params.jl
│   ├── single_unit.scad             ← full 3D assembly (344 lines)
│   ├── stack.scad                   ← 4-unit stack assembly
│   ├── generate_params.jl           ← Julia → OpenSCAD parameter exporter
│   ├── PRD.md                       ← Product Requirements Document
│   ├── DIMENSIONS.md                ← dimensioned component spec
│   ├── assembly_v4.pdf              ← LaTeX cross-section
│   └── renders/                     ← isometric, front, side renders
└── docs/
    ├── make.jl                      ← Documentation builder
    ├── agents/                      ← agent domain docs
    ├── archive/                     ← historical handovers
    ├── ACADEMIC_REPORT.md           ← thesis/investor framing
    ├── ASSEMBLY.md                  ← assembly instructions
    ├── FLIGHT_TESTING.md            ← flight test procedures
    ├── GROUND_TESTING.md            ← ground test procedures
    ├── MANUFACTURING.md             ← manufacturing notes
    └── MATERIAL_SOURCING.md         ← materials and suppliers
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
