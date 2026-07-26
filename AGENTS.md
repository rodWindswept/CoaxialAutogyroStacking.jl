# Working conventions — CoaxialAutogyroStacking.jl

Guidance for any developer or AI agent contributing to this package. Keep it
short and current; if a convention here drifts from reality, fix the doc.

## What this package is

Multiple independently-pitched autogyro rotors stacked on one kite line. Forces
resolve along the line axis; tension accumulates from the topmost rotor (which
terminates the line) down to the anchor (bottom). Empirical PCA-2 rotor-disk data drives lift/drag. Designed to
fold into `KiteTurbineDynamics.jl`.

Read [`PLAN.md`](PLAN.md) first — it is the source of truth for scope, task
order, and key decisions. Read [`HANDOVER.md`](HANDOVER.md) for post-pull workflows,
academic/investor result framing, and chart exploration guidelines.

## The loop (non-negotiable)

Strict TDD, RED → GREEN → REFACTOR, one task at a time:

1. Write the failing test in `test/test_<module>.jl` first.
2. Implement the minimum in `src/<module>.jl` to pass.
3. Refactor with tests green.
4. Run the full suite before committing: `julia --project=. test/runtests.jl`.

Every new `src/` file is `include`d in `src/CoaxialAutogyroStacking.jl` and its
public names added to the `export` block. Every new test file is `include`d in
`test/runtests.jl`.

## Post-Pull Action (Mandatory for Agents)

Upon pulling `master`:
1. Run `julia --project=. test/runtests.jl` (must be 100% green).
2. **Run a Doc Staleness Sweep**: Verify file maps in `PLAN.md` and `AGENTS.md` match `src/` and `test/`. Check constructor signatures (e.g. `AutogyroStack(..., line_density=970.0)`).
3. Read [`HANDOVER.md`](HANDOVER.md) for current phase objectives.

## File map

```
src/
  CoaxialAutogyroStacking.jl   module entry — includes + exports
  airfoil_data.jl              NACA 0012 polar lookup tables
  bem.jl                       BEM solver + autorotation RPM
  line_section.jl              bare_line_drag
  optimisation.jl              optimal_rotor_tilt / optimal_rotor_tilts
  pca2_data.jl                 PCA-2 table + pca2_interp
  polygon_line.jl              polygon chain line geometry solver
  rotor.jl                     AutogyroRotor + single-rotor forces
  stack.jl                     AutogyroStack + stack_tension_profile
  stall_delay.jl               Snel 3-D stall delay correction
  sweep.jl                     parameter_sweep (PCA-2 and BEM)
  viability.jl                 rotor_tip_speed, rotor_reynolds_number, viability_report

test/                          12 test_<module>.jl files (one per src/ module)
notebooks/                     Pluto dashboards (dashboard.jl, sweep_plots.jl)
schematics/                    OpenSCAD 3D models and SVG/PDF cross-sections
scripts/                       runnable entrypoints (bem_full_sweep.jl, dashboard.jl)
```

## Conventions

- Mirror `KiteTurbineDynamics.jl` naming, dispatch, and unit conventions — this
  code is meant to drop into it.
- SI units throughout. Angles in **degrees** at the API boundary (functions take
  `_deg` args; use `sind`/`cosd`).
- Rotors in a stack are ordered **top → bottom** (index 1 = topmost, terminates the line).
- `section_lengths` has `n_rotors` entries: between each rotor pair and below bottom rotor to anchor.
- Tension profiles have `n_rotors + 1` entries; `profile[1]` = 0 at topmost rotor,
  `profile[end]` = anchor (max).
- Pure functions where possible; structs are immutable.

## Definition of done (per task)

- Test written first and passing.
- Exported from the module if public.
- Quality-gate invariants still hold (see Phase 6): forces scale with v²,
  zero wind → tension from weight only, more rotors → more lift, tension
  monotonic increasing downward.

## Commits

One commit per task/phase, message prefixed with the phase: e.g.
`Phase 4 Tasks 8-9: AutogyroStack + stack_tension_profile`. Keep `master` green.

## References

- PCA-2 CL/CD data: NASA TM 20080022367.
- Tension model: `KiteTurbineDynamics.jl/src/lift_kite.jl`.
