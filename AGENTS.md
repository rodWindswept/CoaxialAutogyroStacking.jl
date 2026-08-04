# Working conventions — CoaxialAutogyroStacking.jl

Guidance for any developer or AI agent contributing to this package. Keep it
short and current; if a convention here drifts from reality, fix the doc.

## What this package is

Multiple independently-pitched autogyro rotors stacked on one kite line. Forces
resolve along the line axis; tension accumulates from the topmost rotor (which
terminates the line) down to the anchor (bottom). Blade-element momentum theory
(BEM) with NACA 0012/4412 airfoil polars, Prandtl tip-loss, Snel stall delay,
Jensen/PARK wake interaction, and Øye dynamic inflow. Designed to fold into
`KiteTurbineDynamics.jl`.

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
  airfoil_data.jl              NACA 0012 + NACA 4412 polar lookup tables
  bem.jl                       BEM solver, Prandtl tip-loss, Øye dynamic inflow
  line_section.jl              bare_line_drag
  optimisation.jl              optimal_rotor_tilt / optimal_rotor_tilts
  pca2_data.jl                 PCA-2 table + pca2_interp
  polygon_line.jl              polygon chain line geometry solver
  rotor.jl                     AutogyroRotor + single-rotor forces
  stack.jl                     AutogyroStack + stack_tension_profile
  stall_delay.jl               Snel 3-D stall delay correction
  sweep.jl                     parameter_sweep (PCA-2 and BEM)
  viability.jl                 rotor_tip_speed, rotor_reynolds_number, viability_report
  wake.jl                      Jensen/PARK wake deficit + stack effective wind

test/                          12 test_<module>.jl files (one per tested src/ module)
notebooks/                     Pluto notebooks (dashboard.jl, sweep_plots.jl, bem_charts.jl, bem_charts_v2.jl)
schematics/                    OpenSCAD 3D models and SVG/PDF cross-sections
scripts/                       runnable entrypoints (bem_full_sweep.jl, dashboard.jl, gen_pca2_sweep.jl, gen_comparison_sweep.jl)
```

## Conventions

- Mirror `KiteTurbineDynamics.jl` naming, dispatch, and unit conventions.
  This code must drop into it.
- Use SI units. Angles in degrees at the API boundary. Functions take
  `_deg` arguments. Use `sind` and `cosd`.
- Rotors in a stack are ordered top to bottom. Index 1 is the topmost rotor.
  It terminates the line.
- `section_lengths` has `n_rotors` entries. One per rotor pair plus the
  section below the bottom rotor to the anchor.
- Tension profiles have `n_rotors + 1` entries. `profile[1]` is zero at the
  topmost rotor. `profile[end]` is the anchor tension (maximum).
- Use pure functions. Structs are immutable.

## Writing discipline for diagrams and technical outputs

All diagram captions, SPEC.md, IMPLICATIONS.md, simulation result
summaries, and code comments must use shorter, clearer sentences.
These rules derive from ASD-STE100 (the aerospace simplified technical
English standard) and are machine-checkable.

### Rules

- Active voice. Write "The rotor adds 1,250 N." Do not write
  "1,250 N is added by the rotor."
- One name for one thing. Don't call the same quantity "tension" then "force"
  then "load" in the same block of text.
- No hedges. Not "it is important to note that..." or "this may help to..."
  State the finding directly.
- Short sentences. Max 25 words for descriptive text, 20 for instructions.
  Shorter is better. Two short sentences beat one long sentence.
- No semicolons. Write two sentences.
- No nominalizations. Write "We analyzed." Do not write "We performed an analysis."
- No marketing words. "Works" not "seamless." "Fast" not "blazing."
- No phrasal verbs. "Remove" not "take off."

### Code comments

Apply the same clarity rules to comments in `src/` and `test/`:
- One sentence per comment line. If you need two ideas, write two comments.
- Active voice. "This function computes the tension profile" not
  "The tension profile is computed by this function."
- No hedges in docstrings. State what the function does and what it returns.
- Keep `@assert` messages under 15 words.

### Mandatory lint check (Round 2)

Before presenting a diagram for Round 2 approval, run:
```
python3 ste-lint.py diagrams/<slug>/<slug>.py
```
Score must be < 2.0 violations per 100 words on the caption text.
If it fails, rewrite the caption before showing the user.

### Technical result format

When reporting simulation results, use this structure:
```
Finding: <one sentence>
Config:  <R, N, wind, profile>
Values:  <the key numbers>
Check:   <pass/fail against threshold or expectation>
Source:  <data file>
```

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
