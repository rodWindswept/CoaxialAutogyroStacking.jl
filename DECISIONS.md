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
