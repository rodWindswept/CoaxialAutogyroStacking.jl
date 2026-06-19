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
Phase 9    → NOW      (Mechanical design specification)
Phase 10   → v2.0     (BEM autorotation, polygon line geometry)
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

## Phase 9 — Mechanical Design Specification

### Goal

Complete the mechanical design of a single lifting autogyro kite unit,
documented in schematics and 3D models.

### Tasks

1. Finalise dual-molding sandwich bearing geometry with correct tilt axis
2. Dimension swashplate, actuator mounts, pushrod linkage
3. Size empennage (H-stab, V-fin) for trim authority at target AoA
4. Specify webbing capture and spliced-eye Dyneema integration
5. Generate fabrication-ready drawings (OpenSCAD → dimensioned SVG/PDF)

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
│   ├── optimisation.jl              ← optimal_pitch / optimal_pitches
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
