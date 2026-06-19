# Working conventions — CoaxialAutogyroStacking.jl

Guidance for any developer or AI agent contributing to this package. Keep it
short and current; if a convention here drifts from reality, fix the doc.

## What this package is

Multiple independently-pitched autogyro rotors stacked on one kite line. Forces
resolve along the line axis; tension accumulates from the topmost rotor (which
terminates the line) down to the anchor (bottom). Empirical PCA-2 rotor-disk data drives lift/drag. Designed to
fold into `KiteTurbineDynamics.jl`.

Read [`PLAN.md`](PLAN.md) first — it is the source of truth for scope, task
order, and key decisions.

## The loop (non-negotiable)

Strict TDD, RED → GREEN → REFACTOR, one task at a time:

1. Write the failing test in `test/test_<module>.jl` first.
2. Implement the minimum in `src/<module>.jl` to pass.
3. Refactor with tests green.
4. Run the full suite before committing: `julia --project=. test/runtests.jl`.

Every new `src/` file is `include`d in `src/CoaxialAutogyroStacking.jl` and its
public names added to the `export` block. Every new test file is `include`d in
`test/runtests.jl`.

## File map

```
src/
  CoaxialAutogyroStacking.jl   module entry — includes + exports
  pca2_data.jl                 PCA-2 table + pca2_interp
  rotor.jl                     AutogyroRotor + single-rotor forces
  line_section.jl              bare_line_drag
  stack.jl                     AutogyroStack + stack_tension_profile
  optimisation.jl              optimal_pitch / optimal_pitches
test/   one test_<module>.jl per src module, all run by runtests.jl
notebooks/  Pluto dashboards
scripts/    runnable entrypoints
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

## Scope guard (v1)

No wake interaction — downstream rotors see freestream. Do not add wake coupling
without bumping scope to v2 and updating `PLAN.md`.

## References

- PCA-2 CL/CD data: NASA TM 20080022367.
- Tension model: `KiteTurbineDynamics.jl/src/lift_kite.jl`.
