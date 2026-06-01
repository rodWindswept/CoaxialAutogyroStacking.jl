# CoaxialAutogyroStacking.jl

Modelling of multiple independently-pitched autogyro rotors stacked inline on a
single kite line — computing per-rotor forces and the line tension profile from
the free end down to the anchor.

Built test-first for eventual integration into
[`KiteTurbineDynamics.jl`](#integration). Each rotor carries its own collective
pitch, decoupled from line elevation; forces resolve along the line axis using
PCA-2 empirical rotor-disk data.

## Status

Early development (v0.1.0). Phases 1–5 implemented and committed:

| Phase | Scope | State |
|-------|-------|-------|
| 1 | PCA-2 data + `pca2_interp` | done |
| 2 | `AutogyroRotor`, disk area, `rotor_force_along_line` | done |
| 3 | `bare_line_drag`, L/D comparison | done |
| 4 | `AutogyroStack`, `stack_tension_profile` | done |
| 5 | `optimal_pitch` / `optimal_pitches` | done |
| 5 (Task 11) | `lift_force_steady` integration API | **open** |
| 6 | Quality gates (v² scaling, zero-wind, monotonicity) | **open** |

See [`PLAN.md`](PLAN.md) for the full implementation roadmap and
[`AGENTS.md`](AGENTS.md) for working conventions.

## Install

```julia
julia> ]                          # enter Pkg mode
pkg> activate .
pkg> instantiate                  # resolves Manifest.toml (committed for reproducibility)
```

## Quickstart

```julia
using CoaxialAutogyroStacking

rotor = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0)  # radius, hub, blades, chord, pitch°, mass
F_line, F_lift, F_drag, cl, cd = rotor_force_along_line(rotor, 1.225, 8.0, 50.0)

stack = AutogyroStack([rotor, rotor, rotor], fill(10.0, 4), 0.004, 50.0)
profile = stack_tension_profile(stack, 1.225, 8.0)   # tension free-end → anchor
pitches = optimal_pitches(stack, 1.225, 8.0)
```

## Tests

```bash
julia --project=. test/runtests.jl
```

## Interactive dashboard

A Pluto.jl dashboard (side view, tension profile, HUD, scenarios, turbulence)
lives in [`notebooks/dashboard.jl`](notebooks/dashboard.jl).

## Integration

The package mirrors `KiteTurbineDynamics.jl/src/lift_kite.jl` conventions (PCA-2
tables, stack tension accumulation). The planned `lift_force_steady(stack, rho,
v_wind)` will mirror the parent package's dispatch pattern for drop-in use.

## Physics references

- PCA-2 rotor-disk CL/CD data: NASA TM 20080022367.
- Stacked-line tension model: `KiteTurbineDynamics.jl/src/lift_kite.jl`.

## Scope (v1)

No wake interaction — downstream rotors see freestream; wake coupling is
deferred to v2.

## License

MIT — see [`LICENSE`](LICENSE).
