# CONTEXT.md — CoaxialAutogyroStacking.jl

## What this is

A Julia package that models lifting autogyro kites stacked on a single line.
The package computes per-device forces and the line tension profile from the
topmost rotor down to the anchor. Built to integrate into
KiteTurbineDynamics.jl as a modulated lift source.

## Glossary

| Term | Meaning |
|------|---------|
| **Lifting autogyro kite** | A single autorotating rotor disk mounted on the line via a hollow hub, thrust bearing, and tailplane. Generates lift by autorotation. The disk plane and blade pitch adjust independently. This device produces lift. The power autogyro kite in KiteTurbineDynamics.jl produces shaft torque. |
| **Disk tilt** | The angle between the rotor plane and the line-perpendicular direction. The kite-pitch degree of freedom. Controlled by tailplane geometry. Field: `tilt_deg`. |
| **Rotor blade pitch** | Collective pitch of the blades on the hub. Adjusts independently of disk tilt. Controls how aggressively the blades bite the air at a given disk angle of attack. Field: `blade_pitch_deg`. |
| **Stack** | All lifting autogyro kites staged along a single Dyneema line. Rotors are indexed top to bottom. Index 1 is the topmost. Each rotor pulls the line taut from above. Rotors are not suspended from the line. The bottom end connects to the anchor. |
| **Tension profile** | The line tension at each position in the stack. Has `n_rotors + 1` entries. Entry 1 is at the topmost rotor (near zero). The last entry is at the anchor (maximum). Tension increases downward when each rotor adds positive along-line force. |
| **Tension** | The scalar force (N) in the Dyneema line at a point. Equals the sum of all along-line forces and line drag above that point. Do not call it "force" or "load." |
| **Along-line force** | The component of a rotor's aerodynamic force projected onto the line. Each rotor adds along-line force to the tension below it. Use this term for what a rotor contributes. Use "tension" for the resulting line state. |
| **Anchor** | The structural ground attachment point. The anchor sees the maximum tension (full stack load). Not the same as the ground station. |
| **Ground station** | The complete ground assembly: winch, mounting structure, anchor, and control electronics. Includes the anchor but is broader. |
| **Rotor ordering** | R1 is the topmost rotor. RN is the rotor nearest the anchor. Codified in AGENTS.md. Never label the other way. |
| **PCA-2** | The Pitcairn PCA-2 autogyro (1930s). Source of empirical CL/CD data used in the v1 disk model. Superseded by BEM v2.1. The tables remain in `src/pca2_data.jl`. Not related to Principal Component Analysis. Always write "PCA-2." |
| **PCA** | Principal Component Analysis. A statistical method. Not related to the PCA-2 rotor. Always qualify which PCA you mean. |
| **Line elevation angle** | The angle of a line segment above horizontal (degrees). The v1 model uses a single value. The v2.1 polygon chain solver computes per-segment angles. |
| **PCA-2 data** | Empirical CL/CD tables from NASA TM 20080022367. A 1-D disk model keyed on angle of attack. Does not resolve blade geometry. |
| **Effective AoA** | The disk angle of attack: `α_eff = 90° − line_elevation + disk_tilt`. Lookup key for the PCA-2 table. |
| **Graded stacking** | A configuration where tilt angle varies by position. Top rotors can be draggier. Bottom rotors can be liftier. Contrasts with uniform stacking. |
| **Tilt profile** | The assignment of tilt angles across the stack. Tested profiles: uniform, top-draggy, bottom-lifty, graded. |
| **Parameter sweep** | Computational exploration of the design space. Sweeps radius, stack count, tilt profile, wind speed, and elevation. Outputs TSV files for charting. Defined in SPEC.md. Implemented in `src/sweep.jl` and `scripts/bem_full_sweep.jl`. |
| **Figure of merit** | A scalar metric for comparing configurations. The v1 sweep uses: anchor tension (N), tension per rotor mass (N/kg), and tension CV across wind speeds. |
| **Autorotation RPM** | The rotational speed where net torque is zero. Estimated from a nominal tip-speed ratio. The BEM solver computes this from torque equilibrium. |
| **Autorotation** | Self-sustaining rotation driven by airflow through the rotor disk. No external power. The rotor acts as a windmill. |
| **BEM** | Blade Element Momentum. The v2.1 aerodynamic model. Replaces the PCA-2 disk model. Resolves blade geometry and induction at each radial station. |
| **Polygon line** | The line geometry model. Each segment between rotors forms a different angle. The solver finds equilibrium angles from force balance at each rotor. |
| **Snel stall delay** | A 3-D correction for rotational augmentation. Boosts root thrust where solidity is highest. Negligible at the blade tip. |
| **Viability gate** | A physical constraint check. BEM v2.1 gates: Re > 5×10⁴ (transitional flow, NACA 0012), tip speed < 120 m/s (Mach 0.3 noise limit). Checked per configuration in `src/viability.jl`. |
| **BEM induction** | The velocity reduction factors a and a′. Axial induction a slows the freestream through the disk. Tangential induction a′ accounts for rotor swirl. Solved iteratively at each radial station. |
| **BEM station** | A single radial blade element at radius r. Defined by local chord, twist, inflow angle, and relative velocity. The BEM solver integrates forces across stations to get rotor-wide thrust and torque. |
| **NACA 0012** | The symmetric 12% thickness airfoil used in the BEM model. CL/CD tables at Re = 10⁵, 2×10⁵, 5×10⁵, 10⁶ from XFoil. Stored in `src/airfoil_data.jl`. |
| **Solidity** | Rotor solidity: σ = n_blades × blade_chord / (π × radius). Controls blade loading. PCA-2 σ ≈ 0.098. Typical lifting-autogyro σ ≈ 0.03–0.05. |
| **Tip-speed ratio (λ)** | λ = ΩR / v_through. The ratio of blade tip speed to through-disk velocity. Autogyro rotors operate at λ ≈ 2–3. Wind turbines operate at λ ≈ 6–8. |
