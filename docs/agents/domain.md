# Domain Documentation — CoaxialAutogyroStacking.jl

> Agent onboarding guide. Covers what the project is, where everything lives,
> how to run it, what's active, and what the key physics are.

## What this project is

**Multiple independently-pitched autogyro rotors stacked on a single Dyneema line.**
Each rotor is a lifting element — it pulls the line taut from above. Tension
accumulates from the topmost rotor (which terminates the line) down to the
anchor (bottom, where it attaches to a kite turbine hub).

The stack is a **controllable, modulated lift source** — a replacement for the
single large soft lift kite in a kite turbine system. Built for eventual
integration into `KiteTurbineDynamics.jl`.

**Why autogyro rotors instead of soft kites:**
- Autorotation provides lift even in gusty conditions (apparent wind at blade tip >> freestream)
- Rigid disks are more predictable (no collapse, no luffing)
- Independent pitch per rotor enables graded stacking
- Smaller units are easier to manufacture, transport, and replace

## Quick start

```bash
cd ~/Documents/GitHub/CoaxialAutogyroStacking.jl

# First time only — install dependencies
julia --project=. -e 'import Pkg; Pkg.instantiate()'

# Run tests (143 tests, ~3s)
julia --project=. test/runtests.jl

# Launch GLMakie dashboard
julia --project=. scripts/dashboard.jl
```

**Minimal Julia API:**
```julia
using CoaxialAutogyroStacking

# Single rotor
rotor = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0)  # R, hub, blades, chord, tilt°, mass kg
F_line, F_lift, F_drag, cl, cd = rotor_force_along_line(rotor, 1.225, 8.0, 50.0)

# Three-rotor stack
stack = AutogyroStack([rotor, rotor, rotor], fill(10.0, 3), 0.004, 50.0)
profile = stack_tension_profile(stack, 1.225, 8.0)   # anchor tension = profile[end]
pitches = optimal_pitches(stack, 1.225, 8.0)
```

## Repository map

```
CoaxialAutogyroStacking.jl/
├── SPEC.md                         ← specification — source of truth for scope & design
├── PLAN.md                         ← implementation roadmap (Phases 1–10)
├── CONTEXT.md                      ← glossary of 23 domain terms
├── AGENTS.md                       ← working conventions (TDD, naming, file map)
├── CLAUDE.md                       ← quick entry point for Claude Code / AI agents
├── CONTEXT.md                      ← domain glossary
├── HANDOFF_2026-06-12_dashboard.md ← dashboard implementation handoff notes
├── PHASE9_PLAN.md                  ← mechanical design spec skeleton (active)
├── SOURCE_INVENTORY.md             ← all files with descriptions
│
├── src/
│   ├── CoaxialAutogyroStacking.jl  ← module entry — includes + exports
│   ├── pca2_data.jl                ← PCA-2 empirical CL/CD tables (NASA TM 20080022367)
│   ├── rotor.jl                    ← AutogyroRotor struct + single-rotor forces
│   ├── line_section.jl             ← bare line drag (cylinder crossflow)
│   ├── stack.jl                    ← AutogyroStack struct + tension accumulation
│   ├── optimisation.jl             ← optimal_pitch / optimal_pitches (grid search)
│   └── sweep.jl                    ← parameter_sweep + Pareto-front analysis (Phase 8)
│
├── test/
│   ├── runtests.jl                 ← suite entry (143 tests, all green)
│   ├── test_rotor.jl / test_pca2_data.jl / test_line_section.jl
│   ├── test_stack.jl / test_optimisation.jl / test_sweep.jl
│
├── notebooks/
│   ├── dashboard.jl                ← GLMakie interactive dashboard
│   └── sweep_plots.jl              ← sweep result visualisation
│
├── schematics/                     ← Phase 9 mechanical design (OpenSCAD + TikZ)
│   ├── assembly_v2.tex/pdf         ← cross-section of single autogyro unit
│   ├── rotor_assembly_v2.scad/png  ← 3D model single unit
│   ├── autogyro_stack.scad/png     ← 3D stack
│   ├── rotor_stack_world.scad/png  ← 3D stack in world space
│   ├── tube_capture.tex/pdf        ← webbing + spliced eye detail
│   ├── inline_autogyro_mech.tex/pdf← bearing approach comparison
│   ├── stacked_autogyro.tex/pdf    ← stacked assembly view
│   └── stack_system_overview.tex/pdf ← system-level overview
│
├── scripts/
│   └── dashboard.jl                ← standalone dashboard launcher
│
├── docs/
│   ├── src/index.md                ← Documenter.jl package docs
│   ├── src/api.md                  ← auto-generated API reference
│   ├── agents/domain.md            ← this file
│   └── audit-literature-crosscheck.md ← 11-point literature audit (2026-06-08)
│
├── sweep_results.tsv               ← 1,728 post-processed sweep configurations
└── sweep_*.png                     ← heatmap, Pareto, profile, tension plots
```

## Current state

| Phase | Status | What |
|-------|--------|------|
| 1–5 | ✓ DONE | PCA-2 data, rotor model, line drag, stack, optimisation |
| 6 | ✓ DONE | Quality gates — 143 tests green |
| 7 | ✓ DONE | Disk tilt/collective refactor, GLMakie dashboard |
| 8 | ✓ DONE | Parameter sweep (8,640 evaluations), Pareto analysis, SPEC.md §6 |
| **9** | **ACTIVE** | Mechanical design specification — dimensioning, empennage sizing, BOM |
| 10 | v2.0 | BEM autorotation, polygon line geometry, wake interaction |

**Key Phase 8 results** — best v1 configuration:
- Rotor radius: 3.0 m, stack count: 4, spacing: 15–30 m
- Anchor tension at 8 m/s: **5,086 N**
- Mass efficiency: **271 N/kg**
- Tension CV (gust stability): 0.72
- At 12 m/s: ~11.6 kN — comparable to a 5–10 m² soft kite

**Phase 9 open decisions:**
- Fixed vs adjustable disk tilt δ?
- Tube material: aluminium vs carbon fibre?
- Bearing selection: off-the-shelf thrust or custom?
- Actuator count: 3 (collective only) or more (cyclic, v3+)?

## Physics TL;DR

### Rotor aerodynamics
Uses **PCA-2 empirical disk data** (NASA TM 20080022367) — CL(α) and CD(α) as a
black-box disk model. 1-D lookup on effective angle of attack.

```
α_eff = 90° − line_elevation + tilt_deg
F_lift = 0.5·ρ·v²·A_disk·CL(α_eff)    // ⊥ wind
F_drag = 0.5·ρ·v²·A_disk·CD(α_eff)    // ∥ wind
F_line = F_lift·sin(elev) + F_drag·cos(elev)
```

### Tension accumulation
Tension propagates top→bottom. Each rotor's net along-line force (positive =
pulls taut) plus section drag adds to the running total. The anchor tension
(profile[end]) is the lift delivered to the kite turbine hub.

Critical rule: **rope cannot push** — `max(0, previous + delta)`. Negative
accumulation is clamped to zero (line goes slack).

### Tension-only discipline
Every line, bridle, and tether must only transmit force in tension. Slack =
failure. This is a core physics principle.

### Known v1 limitations
- **No wake interaction** — all rotors see freestream. Wake coupling deferred to v3.
- **Straight line** — single elevation angle. Polygon chain deferred to v2.
- **PCA-2 is a disk model** — blade geometry not resolved. BEM deferred to v2.
- **No blade pitch parameterisation** — PCA-2 is 1-D (AoA only).
- **Steady-state only** — no dynamics, no gust response, no transients.

### Key references
- PCA-2 CL/CD: NASA TM 20080022367
- Tension model: `KiteTurbineDynamics.jl/src/lift_kite.jl`
- Tether drag: `TetherDragODESolver` (Tallak Tveide)
- Coaxial autogyro aerodynamics: Harris (2003), Carceller (2020), Pfister & Blondel (2020)
- Literature audit: `docs/audit-literature-crosscheck.md` — 11 actionable findings

## Conventions

- **Strict TDD**: RED → GREEN → REFACTOR, one task at a time.
- **SI units** throughout; angles in **degrees** at API boundary (`sind`/`cosd`).
- **Rotors ordered top→bottom** (index 1 = topmost, terminates line).
- **section_lengths has n_rotors entries** — between rotors and below bottom to anchor.
- **Tension profile has n_rotors+1 entries** — profile[1]=0 at top, profile[end]=anchor.
- **Pure functions** where possible; **immutable structs**.
- **One commit per phase**, master stays green.
- **Mirror KTD.jl conventions** — naming, dispatch, units.
- **v1 scope guard**: no wake interaction without bumping to v2 and updating PLAN.md.
