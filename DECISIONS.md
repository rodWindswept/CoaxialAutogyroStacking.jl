# DECISIONS.md — Resolved Design Decisions

> Record of decisions made during design reviews, grilling sessions, and
> post-analysis. Each entry captures what was decided, why, and what
> alternatives were rejected.

---

## D1: Q1 — BEM is not calibrated wrong (2026-07-27)

**Decision:** Answer (B) ruled out. The ~8× BEM→PCA-2 force gap is not a
calibration error in the BEM code. Single-station hand checks confirm
physically reasonable forces, the induction loop converges (1e-6 tolerance),
and autorotation RPM is in the expected range.

**Why:** The gap decomposes as ~2.4× from solidity mismatch (PCA-2 σ≈0.078
scales by disk area πR²; BEM σ≈0.032 scales by blade area n·c·R) and
~3.2× from CL differences + 3-D disk-averaging effects not captured by
2-D airfoil strip theory.

**Rejected:** Spending v3 effort on "BEM calibration." The BEM code is
computing correct physics at the blade-element level.

**Remaining:** The gap reduces to (A) "BEM is the design truth, PCA-2 was
never valid at our solidity" vs (C) "both are right in their own reference
frames." This is a fidelity choice, not a bug.

---

## D2: Q2 — Force projection bug in solve_polygon_angles (2026-07-27)

**Decision:** Confirmed bug. Three deviations from correct force equilibrium
(see `Desktop/Teach Co-ax-autoG/lessons/0002-force-projection.html`):

1. **Magnitude:** Used `F_line = T·cos(δ)` instead of full thrust `T`.
2. **Angle sign:** Used `θ + δ` instead of `θ − δ`. The sign of δ was
   flipped — code computed at effective angle 90°−θ−δ instead of
   90°−θ+δ.
3. **Trig swap:** Used `sin` for horizontal, `cos` for vertical —
   inconsistent with the `T_above` terms which used standard trig.

**Why:** The corrected equilibrium follows directly from the disk-normal
thrust vector at α_eff = 90° − θ + δ, which is the same angle used by
`effective_alpha()` in rotor.jl:
```
T_x = T_above·cos(θ) + T·cos(α_eff)    [= T_above·cos(θ) + T·sin(θ−δ)]
T_y = T_above·sin(θ) + T·sin(α_eff) − W  [= T_above·sin(θ) + T·cos(θ−δ) − W]
```

**Impact at design point (θ=55°, δ=20°):** Code computed −7° (clamped to 5°),
correct is 39° — a 46° error. The 5° clamp masked the bug.

**Why tests passed:** Most test cases used δ≈0° (error vanishes), tolerances
were large (±30°), and the clamp hid negative angles.

**Rejected:** The possibility that the trig swap was a deliberate coordinate
convention. The `T_above` terms used standard trig while `F_line` terms used
swapped trig — mixing conventions in the same equation.

**Fix applied:** See commit for polygon_line.jl changes.

---

## D3: Q2 follow-up — sweep tip speed inconsistency (2026-07-27)

**Decision:** `parameter_sweep_bem` used base elevation `elev` for tip
speed/RPM computation instead of polygon segment angles from
`solve_polygon_angles`. After Q2 fix, polygon angles diverge from base
elevation, so this produces wrong viability metrics.

**Fix applied:** Sweep now calls `solve_polygon_angles` to obtain segment
angles, uses those for per-rotor tip speed/RPM computation.

---

## D4: Under-relaxation damping in polygon solver (2026-07-27)

**Decision:** Added under-relaxation damping (ω=0.5) to the Jacobi iteration
in `solve_polygon_angles`. Without damping, the corrected force projection
exposed a stable oscillation in the thrust↔angle feedback loop:

- Flat θ → large α_eff → high through-disk velocity → large thrust → steep θ
- Steep θ → small α_eff → low through-disk velocity → small thrust → flat θ

At the design point (θ=55°, δ=10°, R=3m, 8 m/s): iter 1 gave θ≈28°, iter 2
gave θ≈68°, and the solver oscillated between these states without converging.
After 10 iterations the angle hit the 85° clamp.

**Why damping works:** The physical equilibrium exists at a single angle where
thrust, weight, and tension balance. The undamped Jacobi iteration overshoots
because the thrust responds nonlinearly to θ via `v_through = v_wind·sin(α_eff)`.
Under-relaxation (θ_new = θ_old + 0.5·(θ_computed − θ_old)) reduces the step
size, allowing the iteration to converge to the true equilibrium rather than
oscillating around it.

**Rejected:** Removing the damping and relying on the 5°–85° clamp (which was
masking the oscillation in the pre-fix code). Newton's method considered but
deferred — damping is simpler and sufficient for current profiles.

**Pre-fix masking:** The bug's three deviations (wrong magnitude, sign-flipped
δ, trig swap) serendipitously produced angles near 5°, which the clamp then
held at 5°. The solver appeared to "converge" because the clamp suppressed
the oscillation that the correct physics exposes.

---

## D5: Q3 — HANDOVER framing of BEM→PCA-2 gap (2026-07-29)

**Context:** HANDOVER.md and README.md framed the BEM→PCA-2 force gap (~8×)
as justification for v3 wake modelling. This is scientifically wrong: wake
deficits reduce downstream rotor inflow, making BEM forces *lower*, not higher.
Wake modelling would widen the gap, not close it.

**Decision:** v3's primary goal is rotor-to-rotor interaction fidelity.
Wake modelling addresses a real problem (non-uniform inflow, downstream
sheltering) but does not close the PCA-2 gap. The gap is a fidelity choice
not a physics deficiency: BEM measures 2-D airfoil forces, PCA-2 measures
an empirical high-solidity disk. Both are "right" in their own reference
frames (D1, (C)).

**Action:** HANDOVER.md and README.md must stop citing the BEM→PCA-2 gap as
justification for wake modelling. v3 scope should be motivated by
rotor-to-rotor interaction fidelity, not gap-closing.

---

## D6: Q4 — Wake deficit keeps the freestream thrust coefficient (2026-09-29)

**Decision:** `stack_effective_wind` normalises CT with the freestream:
`CT = T / (0.5·rho·v²·A)`. This is correct. Do not divide by
`sin²(alpha_eff)`.

**Why:** `solve_polygon_angles` generates the thrust from the through-disk
component, `v_n = v·sin(alpha_eff)`. That fact alone does not make the
freestream CT wrong, because `sin(alpha_eff)` appears twice and cancels:

- Streamwise force on the disk: `F_x = T·sin(alpha_eff)`.
- Mass flow through the disk: `mdot = rho·A·v·sin(alpha_eff)`.
- Momentum deficit: `dv = F_x / mdot = T / (rho·A·v)`.

The last ratio is independent of disk inclination, and it equals
`CT/2` with the freestream CT. So the freestream CT is the one consistent
with the model's own streamwise momentum accounting.

Measured on master, R = 3 m, v = 8 m/s, elev 55°, alpha_eff = 45°:
T = 140.1 N, A = 28.27 m², v_n = 5.66 m/s, CT_freestream = 0.1264,
CT_through-disk = 0.2528 (ratio 2.000).
`F_x/mdot = 0.0632 v`. `CT_freestream/2 = 0.0632`. `CT_through-disk/2 = 0.1264`.
The Jensen near-wake deficit `1 − sqrt(1 − CT_freestream) = 0.0653` agrees
with the momentum value to 3%.

**Rejected:** Normalising CT with the through-disk velocity. That treats the
1/sin²(alpha_eff) factor as a lost correction. It is not lost. It cancels
against the force projection. Applying it would double the deficit and
double the reported power shed (14.7% → 28.8% at 5 m spacing).

**Consequences:**
- The 14.7% power shed at 5 m spacing, k = 0.075, R = 3 m stands. The 10.1%
  force and tension shed (v²) alongside it also stands.
- Two model errors remain, and they act in opposite directions. The mass flow
  ignores the rotor's own induced flow, which would shrink the deficit. `F_x`
  ignores the in-plane rotor force, which would grow it. Neither is ticketable
  before the spacing and k axes are settled.
- The larger lever is not the CT convention. It is the wake decay constant k.
  At 5 m spacing: shed 14.7% (k = 0.075), 13.7% (k = 0.10), 12.0% (k = 0.15).

---

## D7: Q4 follow-up — PCA-2 solidity gate is 0.098, not 0.078 (2026-09-29)

**Decision:** The PCA-2 solidity yardstick is σ ≈ 0.098. The PCA-2 has
**4 blades**, not 3. NASA TM 20080022367 tables 45 ft diameter, 22 in chord,
4 blades, blade area 155 ft² against disc area 1,590 ft². That gives
σ = 0.0976.

**Why:** `rotor.jl:65` and `test_rotor.jl:38` state "3 blades". With 3 blades
the repo formula returns 0.0778. `test_rotor.jl:41` asserts 0.0778 against a
comment that claims 0.0976, so the test cannot fail on the value it claims to
check. The 4-blade count gives 0.104. The residual against 0.0976 is taper and
root cutout.

**Rejected:** Moving the yardstick to 0.078 to match the docstring. The
docstring blade count is the defect.

**Consequences:**
- D1 decomposes the ~8× BEM→PCA-2 gap as ~2.4× solidity and ~3.2× CL and 3-D
  effects. With σ = 0.0976 the solidity factor is 0.0976/0.032 = 3.05×. The
  residual becomes 8/3.05 = 2.6×. The gap still decomposes. The split moves.
- Any sweep that varies rotor radius at a fixed chord leaves the PCA-2
  calibration range. σ = 0.098 at 2 blades needs chord = 0.154·R. The repo
  default chord 0.15 m gives σ = 0.0955 at R = 1.0 m and σ = 0.0318 at
  R = 3.0 m. A size sweep at fixed chord is a solidity sweep.

## D8: Wake interaction — Jensen/PARK, then Bastankhah 2026 (2026-09)

**Decision:** The stack wake model moved in two steps. Phase 11
(`8be8585`) adopted the Jensen/PARK deficit: `wake_deficit(CT, R, x)`
and `stack_effective_wind` apply a cumulative upstream deficit to each
downstream rotor. Phase 12 (`34104ae`) replaced it with the Bastankhah
2026 generalised actuator disk model, run RK4 upstream, downstream and
CT-a, validated against the AtWIND-lab companion code.

**Why:** A stacked rotor flies in the wake of every rotor above it. A
momentum-only stack over-predicts the low rotors. The engineering
Jensen/PARK form gave the first order; the Bastankhah 2026 form keeps
the actuator-disk physics the later authority sweeps depend on. The
companion-code check is the calibration anchor.

**Consequence:** Wake interaction is the model's newest physics. The
v1 scope guard ("no wake coupling before v2") is superseded. Sweeps
that pre-date Phase 11 do not carry wake effects, and comparisons
across that line must name it.

## D9: Prandtl tip-loss enters the BEM (2026-09)

**Decision:** `prandtl_tip_loss_factor(r, R, B, phi)` scales the
induction: `a = 1/(1 + 4F·sin²φ/(σ'·cn))`, with F in (0,1]. Landed in
`354997d`, suite 378/378.

**Why:** Pressure bleed around the blade tip shrinks the effective disk
area. Without F the BEM under-predicts induction near the tip.

**Consequence:** Tip station loads read lower, and the tip-speed
viability gate reads a truer load. Any pre-`354997d` sweep lacks the
correction.

## D10: Øye dynamic inflow, ready for the time domain (2026-09)

**Decision:** `dynamic_inflow_filter` models wake inertia as a
first-order lag on the induction factor, with the Øye time constant
`τ = 1.1·R/((1−1.3·a)·v_wind)` clamped to 0.01 to 10.0 s. Landed in
`57b7e1b`, suite 407/407.

**Why:** The induced velocity field does not respond instantly to a
load change. Quasi-static sweeps hide that; a gust or a pitch step does
not. The filter is built now so the time-domain integration can call it
unchanged.

**Consequence:** No current sweep exercises the filter. It ships with
unit tests only until a dynamics campaign calls it.

## D11: NACA 4412 joins NACA 0012 (2026-09)

**Decision:** The airfoil tables now carry both the NACA 0012 and the
cambered NACA 4412 (4 per cent camber at 40 per cent chord). Landed in
`9cc8ce9`.

**Why:** A cambered section lifts at zero incidence and stalls
differently. The stack's bottom rotors fly at higher incidence, where
camber matters.

**Consequence:** Every sweep must state its airfoil. The reference
design stays NACA 0012 until a sweep justifies the switch.

## D12: Snel stall-delay correction (2026-08)

**Decision:** `snel_cl_3d` applies the Snel/Himmelskamp rotational
augmentation from QBlade:
`CL_3D = CL_2D + (3.1·λ²/(1+λ²))·g(α)·(c/r)²·(CL_pot − CL_2D)`.
The correction clamps to non-negative and vanishes above 60 degrees
angle of attack. Landed in `8dc2fd4` (Phase 10f).

**Why:** Rotation delays separation at the root, where solidity is
highest and the 2-D polar under-predicts thrust.

**Consequence:** Root stations carry higher CL than the table alone
would give. The correction is strongest near the hub and negligible at
the tip.
