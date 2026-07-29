# GRILLING_HANDOVER.md — Unresolved Design Questions

> Rolling handover from grilling sessions. Each question is a decision that
> could change architecture, scientific interpretation, final visuals, or
> obviate expensive work. Answer before committing to the direction implied
> by the current code/docs.

---

## Q1: BEM vs PCA-2 force discrepancy (~7–10×)

**Context:** SPEC.md §6.6 shows BEM delivering 649 N at R=3.0m, N=4, 8 m/s
vs PCA-2 v1 delivering 5,086 N — a ~7.8× gap. HANDOVER.md frames this as
"the fundamental limit of 1-D axial BEM" and justification for v3 wake
modeling. Simultaneously, HANDOVER credits Snel 3-D stall delay with "+35%
root thrust, ~3% net boost" — a 1.03× correction that doesn't address the
order-of-magnitude gap.

**The decision:** Is the BEM model:
- (A) Physically correct but incomplete — missing 3-D disk-averaging and
  rotational augmentation effects that will come in v3, and the 649 N figure
  is the design truth. PCA-2 was never valid at σ ≈ 0.032.
- (B) Calibrated wrong — induction loop, Re selection, NACA 0012 data,
  geometry assumptions, or v_through projection could be fixed now with
  modest effort.
- (C) The gap is expected and both numbers are "right" in their own
  reference frames — PCA-2 is an empirical high-solidity disk, BEM is a
  2-D airfoil strip theory; neither is "wrong," they measure different physics.

**Impact:** If (A), v3 scope is correct. If (B), v3 should be preceded by
a BEM calibration phase. If (C), the HANDOVER framing needs to stop selling
the gap as a "physics boundary" and present it as a fidelity choice.

**Answer:** **(B) ruled out.** BEM is not calibrated wrong — single-station hand
checks confirm physically reasonable forces, the induction loop converges
(1e-6 tolerance), and autorotation RPM is in the expected range. The ~8× gap
decomposes as: ~2.4× from solidity mismatch (PCA-2 σ≈0.078 vs our σ≈0.032;
PCA-2 scales with disk area πR², BEM scales with blade area n·c·R), and
~3.2× from CL differences + 3-D disk-averaging effects not captured by 2-D
airfoil strip theory. The question reduces to (A) vs (C): is BEM the design
truth (649 N) or just a different fidelity lens on the same physics?

---

## Q2: Force projection error in `solve_polygon_angles` (polygon_line.jl:56-57)

**Context:** `rotor_force_bem` (bem.jl:301) returns `F_line = T * cosd(tilt_deg)` —
the thrust magnitude projected onto the line axis. Its docstring confirms:
"F_line: force projected onto the line axis (N)."

In `solve_polygon_angles` (polygon_line.jl:56-57), this along-line force gets
applied at the disk-normal angle `θ + δ`:

```julia
δ = rotors[i].tilt_deg
T_x = T_above * cosd(θ[i]) + F_line * sind(θ[i] + δ)
T_y = T_above * sind(θ[i]) + F_line * cosd(θ[i] + δ) - W
```

Two issues:

1. **Magnitude mismatch:** Uses `F_line = T·cosd(δ)` instead of the full
   thrust `T`. If the intended physical model is "thrust acts at disk-normal
   angle," the magnitude should be `T`, not `T·cosd(δ)`.

2. **Trig swap:** Uses `sind(θ+δ)` for the horizontal component and
   `cosd(θ+δ)` for the vertical component — reversed from standard vector
   decomposition where `cosd` gives horizontal and `sind` gives vertical.
   This swap is also encoded in the docstring (polygon_line.jl:20-21).

**Effect at design points** (T_above=0, ignoring weight):

| θ | δ | Code θ | Along-line | Full thrust |
|---|---|--------|------------|-------------|
| 55° | 20° | **15°** | 55° | 75° |
| 50° | 10° | **30°** | 50° | 60° |
| 45° | 0° | 45° | 45° | 45° |
| 55° | 5° | **30°** | 55° | 60° |

At δ=0 the errors cancel (sind(45°)=cosd(45°)). At all other tilts the
resultant angle is wrong by 20–40°. The error affects the core v2 mechanism:
polygon line geometry is what makes graded stacking meaningful, and the
SPEC §6.6 finding ("top_draggy +12.7% over uniform at R=3m") comes from
this solver.

**The decision:** Is this:
- (A) A bug — both the magnitude (F_line vs T) and the trig swap need fixing.
  The sind/cosd swap alone means every polygon angle is systematically wrong
  (computes complement angle when δ=0).
- (B) A deliberate sign/axis convention where the coordinate frame is rotated
  or horizontal/vertical axes are transposed. If so, the convention needs to
  be documented because it contradicts standard vector decomposition.

**Impact:** If (A), all polygon-line results in SPEC §6.6 need recomputation
— the graded stacking advantage may change or vanish. The sind↔cosd swap
means the existing results compute segment angles as their complements,
which cascades into wrong effective AoA for every downstream rotor.

**Answer:** **(A) — confirmed bug.** Three deviations from correct force equilibrium
(see `Desktop/Teach Co-ax-autoG/lessons/0002-force-projection.html`):

1. **Magnitude:** Uses `F_line = T·cos(δ)` instead of `T`.
2. **Angle sign:** Uses `θ + δ` instead of `θ − δ`. The thrust acts at
   α_eff = 90° − θ + δ; the code effectively computes at 90° − θ − δ.
   The sign of δ is flipped.
3. **Trig swap:** Uses `sin` for horizontal, `cos` for vertical — inconsistent
   with the `T_above` terms which use standard trig. This alone produces
   the complement angle.

At θ=55°, δ=20° (top_draggy): code computes −7° (clamped to 5°), correct is
39° — a 46° error. The 5° clamp saved the code from producing negative angles
at the design point. Tests pass because δ≈0 in most test cases (error
vanishes), tolerances are large (±30°), and the clamp masks negatives.

**Corrected equilibrium:**
```
T_x = T_above·cos(θ) + T·sin(θ − δ)    [or T·cos(α_eff)]
T_y = T_above·sin(θ) + T·cos(θ − δ) − W  [or T·sin(α_eff) − W]
where α_eff = 90° − θ + δ
```

**Impact confirmed:** All polygon-line results in SPEC §6.6 need
recomputation. The `top_draggy +12.7%` finding may change. The qualitative
result likely survives but optimal profile and advantage magnitude will shift.

---

## Q3: HANDOVER framing of BEM→PCA-2 gap misdirects v3 scope

**Context:** HANDOVER.md §2A frames the BEM vs PCA-2 gap as:

> "Document the fundamental limit of 1-D axial BEM. BEM under-predicts forces
> (~10×) due to lack of disk-averaged cross-flow components and 3D tip vortex
> interaction. This establishes the theoretical justification for Phase 11 /
> v3.0 wake modeling."

Two scientific problems with this framing:

1. **The gap isn't primarily a BEM limitation.** Q1 established it
   decomposes as ~2.4× solidity mismatch (PCA-2 scales by disk area πR²;
   BEM scales by blade area n·c·R) + ~3.2× CL/disk-averaging differences.
   These are not "missing cross-flow" — they're different physical
   quantities being measured.

2. **Wake modeling won't close the gap.** Wake deficits reduce downstream
   rotor inflow — that makes BEM forces *lower*, not higher. Adding wake
   interaction to v3 would widen the PCA-2 gap, not close it. Wake
   modeling addresses a real but *different* problem: rotor-to-rotor
   interaction fidelity.

**The decision:** Is v3's primary goal:
- (A) Closing the BEM→PCA-2 force gap — in which case the current v3 scope
  (wake modeling) is the wrong remedy and v3 planning needs to restart from
  the correct diagnosis.
- (B) Adding rotor-rotor wake interaction as a fidelity improvement
  independent of the PCA-2 gap — in which case the HANDOVER needs to stop
  citing the gap as justification for wake modeling, and v3 scope is fine
  but differently motivated.

**Impact:** If (A), v3 scope is misdirected. If (B), the HANDOVER framing
is scientifically misleading and needs correction before it propagates into
papers, investor decks, or Cameron's agent's planning.

**Answer:** _[to be filled]_

---

## Q4: Polygon solver robustness after Q2 fix

**Context:** After fixing Q2, the polygon solver will produce correct segment
angles (e.g., 39° instead of clamped 5° at the top_draggy design point).
`solve_polygon_angles` uses Jacobi iteration with `max_iter=10` and `tol=0.1°`.
The pre-fix code was computing wrong-but-stable angles (5° clamp everywhere);
post-fix, the correct physics may expose convergence issues that the clamp
was masking.

SPEC §5.2 already notes: "Polygon line uses Jacobi iteration — may not
converge for extreme tilt profiles."

Potential failure modes: (a) oscillation between angle states without
converging, (b) convergence to wrong local equilibrium, (c) clamp (5°–85°)
becoming an active constraint at correct angles, masking real physics.

**The decision:** Should the solver be upgraded (e.g., Newton's method with
line search) as part of the Q2 fix, or is Jacobi-with-more-iterations
sufficient? If an upgrade is needed, that changes the solver reliability
guarantees and may affect which tilt profiles are computable.

**Impact:** If Jacobi is insufficient post-fix, the polygon line model — the
core v2 mechanism — may not be reliable for extreme profiles without a
solver rewrite.

**Answer:** _[to be filled]_
