# Session Summary — 2026-07-03

**Agent:** Desktop Hermes  
**Repo:** CoaxialAutogyroStacking.jl  
**Rod:** In Harris next few days, reachable via Signal gateway

---

## What We Shipped

### Audit & Physics Fixes (Phase 9 prep)
- PCA-2 axes convention VERIFIED — wind axes, our code correct
- PCA-2 solidity mismatch documented (σ_PCA2=0.098 vs ours σ=0.032, 3× difference)
- 6 code bugs fixed:
  - Line drag crossflow correction (bare_line_drag now uses v·cos(elev))
  - optimal_pitch → optimal_rotor_tilt (docstring now explains disk tilt vs blade pitch)
  - compute_figures_of_merit hardcoded mass → kwarg rotor_mass_per_unit
  - rotor_disk_area now subtracts hub_radius² (annulus)
  - Added rotor_solidity() and estimated_autorotation_rpm()
- 6 new tests, 149 total, all green

### Mechanical Design (Phase 9a-e)
- PRD.md: 10-section mechanical design spec, 16 elements, dimensioned
- DIMENSIONS.md: engineering calculations (bearings, tube, generator, actuators)
- Real components selected: SKF 51105 bearings, 25×15mm carbon tube, 3× micro servos
- Mass budget: 4.2 kg/unit (0.8 kg margin vs sweep assumption)
- Empennage: 1.8m boom, torque reaction verified (0.59 N needed, easily met)
- Generator: 5W hub-driven, empennage provides torque reaction

### Schematics (Assembly Cross-Section)
- 3-round generate→critique→fix cycle delivered 9/10 diagram
- assembly_v4.tex: scale 2.0, 38×30cm single page
- Labels staggered left/right with 3-5cm leader lines
- Corrected tilt: windward edge UP (Rod's correction, applied everywhere)
- tikz_lint.py clean, article+geometry (not banned standalone)
- PRD §10 acceptance criteria met

### Schematics (Stack Overview)
stack_overview.tex: 4 rotors at 15m spacing, 55° elevation, tension staircase, 9/10

### Schematics (OpenSCAD)
- single_unit.scad: corrected tube=tension tie-rod, rope ties both ends, SKF 51105, generator, swashplate
- stack.scad: 4 units at 15m spacing
- generate_params.jl → parameters.scad: live Julia→OpenSCAD parameter chain

### Dashboard Fixes
- scripts/dashboard.jl: line terminates at top rotor, rotors shifted up, colour legend added
- Tension chart: cumulative stepped line (purple) + per-rotor bars (blue)
- notebooks/PRD_DASHBOARD.md: geometry spec for correct kite physics

### Skills Audit (Matt Pocock Framework)
- 133→87 model-invoked (35% reduction)
- 10→49 user-invoked
- 9 diagramming skills consolidated to 2 (technical-diagrams + scientific-diagrams)
- writing-great-skills installed from upstream
- Router skills: /skills and /ask-matt
- 39 rarely-triggered skills converted to user-invoked
- Description tokens: ~3,882 → ~3,200 (−18%)

### Documentation
- DECISIONS.md: 9 decisions logged with rationale
- CHANGELOG.md: full [Unreleased] section
- CONTEXT.md: 7 new glossary terms
- Project.toml: v0.1.0 → v0.1.1
- notebooks/README.md: dashboard launch guide
- CAMERON_STARTER_PACK.md + HERMES_SETUP.md: updated with routers, consolidated skills

---

## Key Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Disk tilt: windward edge UP | Like a kite — wind hits underside. Rod corrected this. Old "forward-down" convention was backwards. |
| 2 | Tube = tension tie-rod, not compression column | Rotor lifts UP, line holds DOWN. Force path: rotor→bearing→molding→tube(tension)→tie→dyneema |
| 3 | Tube tied at BOTH ends | Top tie for zero-wind weight, bottom tie for operational loads |
| 4 | Empennage = torque reaction only | Control authority from swashplate. Generator torque reaction via tail moment arm |
| 5 | Generator hub-driven from autorotation | Rotor hub spins relative to tube — built-in generator. No separate turbine needed |
| 6 | PCA-2 data used despite 3× solidity mismatch | Documented limitation. BEM needed for v2 |
| 7 | Autorotation RPM ≈ 45 (λ=2.5 estimate) | Tip speed 14 m/s, well under 120 m/s noise constraint |
| 8 | Diagramming: 2 skills, not 9 | technical-diagrams (engineering) + scientific-diagrams (data-driven) |
| 9 | Skills: 35% model-invoked reduction | Converted toys/external services to user-invoked, zero context cost |

---

## Plan Progress

| Phase | Status | Artifacts |
|-------|--------|-----------|
| 1-8 | Complete | 149 tests, sweep, Pareto, quality gates |
| 9a (dimension) | Complete | DIMENSIONS.md, SKF 51105, carbon tube |
| 9b (empennage) | Complete | 1.8m boom, torque reaction verified |
| 9d (actuators) | Complete | 3× micro servos, 5W budget |
| 9e (BOM/mass) | Complete | 4.2 kg/unit, live in PRD §4 |
| 9f (SPEC consolidation) | Pending | All schematics are live, PRD is source of truth |

---

## Lessons Learned

1. **vision_analyze is mandatory.** Every diagram fix round was driven by it. Without it we'd have shipped the wrong tilt direction.
2. **TikZ standalone class is banned.** Use article+geometry. Silent failures are real.
3. **tikz_lint.py before every compile.** Unicode, documentclass, page overflow — catches them all.
4. **Two diagramming skills, not nine.** Consolidation cuts context load and eliminates duplication.
5. **Rod catches tilt errors fast.** The windward-edge-UP correction came from Rod's visual check, not physics analysis.
6. **Line terminates at top rotor.** No extension above R1 — the kite pulls the line UP.
7. **OpenSCAD text is invisible at distance.** Labels need TikZ overlay or separate annotation pass.
8. **Skill routers (/skills, /ask-matt) cure cognitive load.** Browse all user-invoked skills without memorizing them.
