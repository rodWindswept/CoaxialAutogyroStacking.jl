```@meta
CurrentModule = CoaxialAutogyroStacking
```

# CoaxialAutogyroStacking.jl

Modelling of multiple independently-pitched autogyro rotors stacked inline on a
single kite line — computing per-rotor forces and the line tension profile from
the free end (top) down to the anchor (bottom).

Built test-first for eventual integration into `KiteTurbineDynamics.jl`. Each
rotor carries its own collective pitch, decoupled from line elevation; forces
resolve along the line axis using PCA-2 empirical rotor-disk data.

## Installation

```julia
julia> ]
pkg> activate .
pkg> instantiate
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

## Conventions

- SI units throughout; angles in **degrees** at the API boundary.
- Rotors in a stack are ordered **top → bottom** (index 1 = topmost / free end).
- Tension profiles have `n_rotors + 1` entries; `profile[end]` is the anchor (max).

## Scope (v1)

No wake interaction — downstream rotors see freestream. Wake coupling is deferred
to v2.

## References

- PCA-2 rotor-disk CL/CD data: NASA TM 20080022367.
- Stacked-line tension model: `KiteTurbineDynamics.jl/src/lift_kite.jl`.

See the [API Reference](@ref) for the full function listing.
