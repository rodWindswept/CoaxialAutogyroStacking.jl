# Design Decisions — CoaxialAutogyroStacking.jl

> Record of decisions made during development, with rationale. Prevents
> re-litigation and documents the "why" behind the code. Modeled on
> `KiteTurbineDynamics.jl/DECISIONS.md`.

---

## 2026-07-02 — Deep Audit & Physics Fixes

*Session: grill → audit → fix loop. Model: deepseek-v4-pro.*

### 1. PCA-2 axes convention verified: wind axes

**Decision:** The PCA-2 CL/CD data (NASA/CR-2003-212799, Harris 2003 Fig 1-19)
uses standard **wind axes**: lift perpendicular to freestream, drag parallel
to freestream. Verified from the source text: `L = W cos γ`, `D = W sin γ`
(gliding polar derivation), with "Hub Plane Angle of Attack" as the independent
variable. Our force resolution in `rotor_force_along_line` is correct.

**Action:** No code change needed. Literature audit finding #9 resolved.

**Reference:** Harris 2003 §Fig 1-19, NACA TR 434 (Wheatley 1932).

### 2. Line drag crossflow correction

**Decision:** `bare_line_drag` now uses the crossflow velocity component
`v_wind × cos(line_elevation)` rather than full `v_wind`. This is physically
correct — only the velocity component perpendicular to the line creates drag
on a cylinder in crossflow. At 50° elevation, the old model overestimated line
drag by ~2.4×.

**Action:** Added `line_angle_deg` parameter. All callers updated. Tests pass (149).

**Impact:** Anchor tension estimates decreased by ~1–3 N per section (negligible
at operating conditions — Dyneema drag is swamped by rotor forces). The fix is
correct physics even if the quantitative impact is small.

### 3. `optimal_pitch` renamed to `optimal_rotor_tilt`

**Decision:** The function sweeps `tilt_deg` (disk plane angle), not
`blade_pitch_deg` (collective blade incidence). The old name was actively
misleading — a user reading "optimal_pitch" would reasonably assume it
optimises blade pitch. Renamed to `optimal_rotor_tilt` and `optimal_rotor_tilts`.
The docstring now clearly distinguishes disk tilt (design-time, set at
manufacture via bearing face machining) from blade pitch (control-time,
adjustable via swashplate, not yet modelled).

**Rationale:** Rod chose `optimal_rotor_tilt` over `optimal_tilt` to keep
"rotor" in the name — distinct from blade pitch. The docstring now explains
the design-time vs control-time distinction explicitly.

### 4. Disk tilt is design-time, not control-time

**Decision:** Disk tilt δ is the angle machined into the molding bearing faces —
fixed for the life of the rotor unit. `optimal_rotor_tilt` answers the
manufacturing question: "what bearing angle should I machine?" It is NOT
a per-flight control parameter. Per-flight control belongs to blade pitch
(swashplate), which the current PCA-2 model does not parameterise (1-D lookup
on AoA only).

**Rationale:** Prevents confusion between design parameters and control inputs.
This distinction matters for Phase 9 mechanical design (bearing face angle is
a dimension on the fabrication drawing) and for v2 BEM (blade pitch becomes
the active control variable).

### 5. Solidity documented as known limitation

**Decision:** Added `rotor_solidity()` function. The PCA-2 rotor has σ ≈ 0.098
(3 blades, R=6.86 m, c=0.56 m). Our sweep optimum (R=3.0 m, 2 blades,
c=0.15 m) has σ ≈ 0.032 — a 3× difference. Duquette & Visser (2003) show
solidity changes torque by hundreds of percent. The PCA-2 CL/CD lookup is
applied without solidity correction — this is a first-order systematic error,
documented but not fixed in v1.

**Action:** BEM (v2) will resolve this by computing forces from blade geometry
rather than from a disk-level lookup table.

### 6. Autorotation RPM estimation added

**Decision:** Added `estimated_autorotation_rpm(rotor, v_wind, α_eff; λ=2.5)`.
Uses a nominal tip-speed ratio λ to estimate RPM from through-disk velocity.
Default λ=2.5 is based on PCA-2 gliding data (Vt≈340 fps at ~130 fps axial
inflow → λ≈2.6). For our best sweep config (R=3m, α=50°, v=8 m/s): ~49 RPM,
tip speed ~15.3 m/s — well below the 120 m/s noise constraint from KTD.jl.

**Caveat:** This is a first-order estimate. Actual RPM depends on blade
geometry, airfoil, and Reynolds number. BEM (v2) will compute RPM from
torque equilibrium. The function exists to give Phase 9 mechanical design
a ballpark RPM for bearing speed ratings and centrifugal stress checks.

### 7. `rotor_disk_area` now subtracts hub radius

**Decision:** Changed from πR² to π(R² − r_hub²). The `hub_radius` field was
dead — present on the struct but unused. Now it contributes. Impact: ~0.4%
area reduction for typical hub sizes (negligible for forces, but correct).

### 8. `compute_figures_of_merit` mass parameter exposed

**Decision:** Added `rotor_mass_per_unit` keyword argument (default 5.0).
The old code hardcoded `mass_total = n_rotors × 5.0`, silently corrupting
N/kg figures of merit if a sweep used a different rotor mass. Now the default
is explicit and overridable.

### 9. PCA-2 solidity mismatch: BEM required for v2

**Confirmed:** The PCA-2 empirical data is valid ONLY for PCA-2-similar rotors
(σ≈0.10, 3 articulated blades, Göttingen 429 airfoil, high advance ratio).
Applying it to our rotors (σ≈0.03, 2 rigid blades, unknown airfoil, pure axial
flow) introduces systematic error of unknown magnitude — potentially factor-of-2
or more in both lift and drag. The current model is a **qualitative exploration
tool**, not a quantitative prediction. Quantitative fidelity requires BEM (v2).

---

## Open Questions (from Phase 9)

- **Fixed vs adjustable disk tilt δ?** Machined bearing face (fixed) or
  adjustable mechanism? Current design assumes fixed — `optimal_rotor_tilt`
  picks the manufacturing value.
- **Tube material:** aluminium vs carbon fibre?
- **Bearing selection:** off-the-shelf thrust bearing or custom?
- **Actuator count:** 3 for collective only, or more for cyclic (v3+)?
- **`section_angles` on `AutogyroStack`:** Add now for v2 polygon line
  compatibility, or wait for the struct redesign?

---

## Key References

- Harris, F.D. (2003). "An Overview of Autogyros and The McDonnell XV-1
  Convertiplane." NASA/CR-2003-212799.
- Wheatley, J.B. (1932). "Lift and Drag Characteristics and Gliding
  Performance of an Autogiro as Determined in Flight." NACA TR 434.
- Duquette, M. & Visser, K. (2003). "Numerical Implications of Solidity
  and Blade Number on Rotor Performance." *J. Solar Energy Engineering.*
- Pfister, J. & Blondel, F. (2020). "Comparing blade-element theory and
  vortex computations intended for modelling of yaw aerodynamics of a
  tethered rotorcraft." *J. Phys.: Conf. Ser.* 1618 032012.
