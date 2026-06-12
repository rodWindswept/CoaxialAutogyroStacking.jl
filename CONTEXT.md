# CONTEXT.md — CoaxialAutogyroStacking.jl

## What this is

A Julia package modelling multiple **lifting autogyro kites** staged at intervals up a single kite line, computing per-device forces and the cumulative line tension profile from free end to anchor. Built for eventual integration into `KiteTurbineDynamics.jl` as a controllable, modulated lift source for the kite turbine system.

---

## Glossary

| Term | Meaning |
|------|---------|
| **Lifting autogyro kite** | A single freely-autorotating rotor disk mounted on the kite line via a hollow hub, thrust bearing, and tailplane frame. Generates lift by autorotation; disk plane and blade pitch are independently adjustable. Distinct from the *power autogyro kite* in `KiteTurbineDynamics.jl`, which generates shaft torque rather than lift. |
| **Disk tilt** | The angle the rotor plane is pitched away from perpendicular to the kite line — the kite-pitch degree of freedom. Controlled by tailplane geometry. Tilting the leading edge forward-down into the wind (like a kite pitching) increases the disk's effective angle of attack and shifts its operating point along the PCA-2 curve. Field: `tilt_deg`. |
| **Rotor blade pitch** | Collective pitch of the individual blades on the autogyro hub. Adjustable independently of disk tilt. Modulates how aggressively the blades bite the air at a given disk AoA. Not yet modelled — the current PCA-2 lookup is 1-D (AoA only) and does not parameterise blade pitch. Field placeholder: `blade_pitch_deg`. |
| **Stack** | The full assembly of lifting autogyro kites staged at intervals along a single Dyneema line. Rotors are indexed top → bottom (index 1 = topmost). Each rotor is a lifting element — it pulls the line taut from above, like a kite on a string. The line hangs in tension below each rotor due to aerodynamic forces; rotors are not suspended from the line. The bottom end (anchor) connects to the ground or to the kite turbine lift line. |
| **Tension profile** | The along-line tension at each position in the stack, from free end (above topmost rotor, ≈ 0 N) to anchor (maximum). Has `n_rotors + 1` entries. Monotonically non-decreasing downward when each rotor's net along-line force is positive. The **anchor tension** — the bottom entry — is the lift force delivered to the attachment point (ground or kite turbine). |
| **Anchor tension** | The tension at the bottom end of the stack. The output quantity passed to `KiteTurbineDynamics.jl` as the lift force input. Represents the cumulative upward pull of all lifting autogyro kites in the stack, minus rotor weights and line drag losses. |
| **Line elevation angle** | The angle of a line segment above horizontal (degrees). In v1, a single value `line_angle_deg` is shared across the whole stack — a known simplification. In reality the line forms a polygon chain, each segment at a slightly different angle as cumulative rotor forces reshape the geometry. A moving-anchor case (kite turbine attachment point in motion) is a further dynamic to be studied. |
| **PCA-2 data** | Empirical rotor-disk lift and drag coefficients (CL, CD) as a function of disk angle of attack, from NASA TM 20080022367. Treated as a black-box disk model — blade geometry is not resolved. The data is 1-D (AoA only); effects of rotor blade pitch are not captured in the current lookup. |
| **Effective AoA** | The angle of attack the rotor disk presents to the wind, in degrees: `α_eff = 90° − line_elevation + disk_tilt`. Used as the lookup key into the PCA-2 table. |
| **Line drag (Tveide model)** | Aerodynamic drag on bare Dyneema line sections between rotors. To be modelled using Tallak Tveide's quasi-static ODE solver for 3D tether shape and drag under apparent wind (https://github.com/tallakt/TetherDragODESolver). The model verifies the ¼-tether-drag assumption for AWE systems. Currently approximated as simple cylinder crossflow drag (`CD = 1.2`) in `bare_line_drag` — replacing this with the Tveide model is a planned improvement. |
