# Phase 9 — Mechanical Design Specification (skeleton)

> Drafted 2026-06-19. Pick up when ready.

## Inventory of existing work

| File | Covers |
|------|--------|
| `schematics/assembly_v2.tex` | Full cross-section: dual-molding bearing, swashplate, empennage |
| `schematics/rotor_assembly_v2.scad` | 3D model of single unit |
| `schematics/tube_capture.tex` | Webbing capture + spliced-eye Dyneema detail |
| `schematics/inline_autogyro_mech.tex` | Bearing approach comparison |
| `schematics/autogyro_stack.scad` | 3D stack |
| `schematics/rotor_stack_world.scad` | Stack in world space |
| `schematics/stack_system_overview.tex` | System overview diagram |

All schematics are sketched qualitatively. They need **dimensions**, not redesign.

## Task breakdown

### 9a. Dimension the single-unit assembly
- Anchor: R = 3.0 m (best config from Phase 8 sweep)
- Work backward: rotor disk → hub diameter → tube → Dyneema → bearings
- Swashplate travel from δ range (0–30° disk tilt)
- Key outputs: dimensioned assembly_v2.tex with numbers on the drawing
- **Effort:** 1-2 sessions

### 9b. Empennage sizing
- H-stab area for pitch trim at α_eff = 45° (cruise)
- V-fin area for passive weathervane alignment
- Rule-of-thumb or quick analytical pass (no CFD needed at this TRL)
- **Effort:** 1 session

### 9c. OpenSCAD → dimensioned fabrication drawings
- Add dimension annotations to existing .scad files
- Export SVG/PDF with `--projection=ortho`
- Front, side, top orthographic views with callouts
- **Effort:** 1 session

### 9d. Actuator selection + pushrod linkage
- Off-the-shelf servo (torque from swashplate loads at max δ, max v)
- Pushrod geometry, mounting points
- Document in assembly drawing
- **Effort:** 1 session

### 9e. Bill of materials + sourcing
- Tabulate: Dyneema (4 mm), tube material, bearings, swashplate, actuators, fasteners, Spectra webbing
- Per-unit mass budget (target: ~5 kg/rotor from sweep assumptions — verify)
- **Effort:** light (spreadsheet work)

### 9f. SPEC.md §8 write-up
- Consolidate all mechanical decisions
- Reference schematics, justify choices
- Open questions table (e.g., fixed vs adjustable disk tilt)
- **Effort:** 1 session after 9a-9e complete

## Total estimate: ~4-6 sessions

## Key decisions already made

- Dual-molding sandwich bearing (from assembly_v2.tex)
- Webbing capture via spliced eyes (from tube_capture.tex)
- Empennage below line, V-fin below boom (from inline_autogyro_mech.tex)
- 2 blades, hollow hub, Dyneema through centre bore

## Open decisions

- Fixed vs adjustable disk tilt δ? SPEC.md flags this as open
- Tube material: aluminium vs carbon fibre?
- Bearing selection: off-the-shelf thrust bearing or custom?
- Actuator count: 3 for collective only, or more for cyclic (v3+)?
