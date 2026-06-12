# Literature Cross-Check Audit — CoaxialAutogyroStacking.jl

Generated: 2026-06-08 | Source: Hermes cross-reference of code vs. AWE wiki & academic literature
Status: OPEN — issues requiring resolution, confirmation, or rework

---

## HIGH CONFIDENCE — Action Required

### 1. PCA-2 data applied universally (dead geometry fields)
**File:** `src/rotor.jl`, `src/pca2_data.jl`
**Severity:** Critical (incorrect physics)

`AutogyroRotor` has `n_blades`, `blade_chord`, and `radius` — but only `radius` (for disk area) and `tilt_deg` (for AoA) are used in force calculations. A 2-blade 0.1 m chord rotor and a 12-blade 0.5 m chord rotor with identical radius produce identical CL/CD/forces.

The PCA-2 data (NASA TM 20080022367) is specific to that rotor system's blade geometry, solidity, hub, and tailplane. Applying its CL/CD to arbitrary rotors without solidity scaling is physically incorrect.

**Academic basis:**
- Duquette & Visser (2003): σ=0.25 vs σ=0.05 changes torque by ~900% at λ=2
- Solidity σ = N_blades × c / (π × R) is a first-order aerodynamic parameter
- Pfister & Blondel (2020): validated BEM model fidelity hierarchy

**Recommendation:** Either (a) parameterize CL/CD with solidity, or (b) retire the empirical PCA-2 model in favor of BEM with blade-resolved geometry, or (c) clearly scope PCA-2 as valid ONLY for PCA-2-similar rotors and add geometry fields as unused placeholders with explicit documentation.

---

### 2. `optimal_pitch` sweeps disk tilt, not blade pitch
**File:** `src/optimisation.jl:29-43`
**Severity:** High (naming/docs misleading)

Docstring: "Grid-search the blade pitch (−30° to 30° in 0.5° steps)"

Code passes the swept value as the 5th constructor argument = `tilt_deg`, not `blade_pitch_deg`:
```julia
test_rotor = AutogyroRotor(
    rotor.radius, rotor.hub_radius, rotor.n_blades,
    rotor.blade_chord, pitch, rotor.blade_pitch_deg, rotor.mass)
```

Since `blade_pitch_deg` is unused in `rotor_force_along_line`, this function can only optimize disk tilt angle (effective AoA). The function name `optimal_pitch` and docstring are misleading.

**Recommendation:** Rename to `optimal_tilt` or refactor to sweep the correct parameter once blade pitch is implemented.

---

### 3. `optimal_pitches` returns identical values for all rotors
**File:** `src/optimisation.jl:73-74`
**Severity:** Medium (correct for v1 scope, but documents a known gap)

Because v1 has no wake interaction and uniform line elevation, every rotor gets the same optimal setting. In reality:

- Carceller (2020): RPM-dependent pitch crossover — negative pitch better at low RPM, positive pitch better at high RPM
- Rotors at different stack positions have different cumulative tension → different RPM → different optimal settings
- Tulloch (2019/2021): TRPT bistability (TSR=1.2 and TSR=5.3 at 8 m/s)

**Recommendation:** Document as v1 limitation. Add per-rotor RPM estimation to enable differential pitch in v2.

---

## MEDIUM CONFIDENCE — Investigation Needed

### 4. Line drag uses full wind speed, not crossflow component
**File:** `src/line_section.jl:26-31`
**Severity:** Medium (quantitatively wrong, directionally conservative)

```julia
q = 0.5 * rho * v_wind^2    # should be v_wind * cosd(elev) for crossflow
```

For a line at elevation φ, the crossflow velocity component perpendicular to the line is `v_wind × cos(φ)`, making dynamic pressure `½ρ(v_wind × cos φ)²`. At φ=50°, this overestimates line drag by `1/cos²(50°) ≈ 2.42×`.

**Academic basis:**
- CONTEXT.md already flags Tveide ODE solver as planned replacement
- Tulloch (2022): two tether drag models — simple parametric and torsional-deformation-improved

**Recommendation:** Apply cos²(elev) correction immediately as a stopgap; integrate Tveide model as planned.

---

### 5. CD_cylinder = 1.2 is a single-point Reynolds assumption
**File:** `src/line_section.jl:27`
**Severity:** Low-Medium

Smooth cylinder CD varies significantly with Re:
- Re ~ 10³: CD ≈ 1.0
- Re ~ 10⁵: CD ≈ 0.3–0.6 (drag crisis)
- Re > 10⁵: CD ≈ 0.9–1.2

4 mm Dyneema at 8 m/s → Re ≈ 2,100 (CD ≈ 1.0). At 20 m/s → Re ≈ 5,300.

**Recommendation:** Use Re-dependent CD lookup, or validate that CD=1.2 is conservative across the operating envelope.

---

### 6. Kheiri (2018): 21% power overestimation from neglected induction
**Severity:** Medium (v1 scope exclusion, but magnitude documented)

Even at extremely low solidity σ=0.005, neglected induction causes ~21% power overestimation per Kheiri et al. (2018). All rotors in v1 see freestream wind regardless of upstream rotors.

**Academic basis:**
- Kheiri et al. (2018): crosswind induction for AWE — power coefficient perspective
- Kheiri (2019): refined power coefficient with induction
- Leuthold et al. (2019): MAWES engineering wake model

**Recommendation:** Quantify expected induction error for the specific stack geometry. Add as a known systematic error in documentation.

---

### 7. Pfister & Blondel (2020): α=40°–65° is worst-case for linear models
**Severity:** Medium (v1 uses empirical data, but geometry effects are unvalidated)

Pfister & Blondel find closed-form linear BEM is poor at high disk AoA (40°–65°) — exactly where the code operates (α_eff=50° for elev=50°, tilt=10°). Their recommendation is numerical BEM + Mangler & Squire inflow as the design baseline. v1 sidesteps BEM by using empirical PCA-2 data, but the PCA-2 data doesn't parameterize geometry and is unvalidated for non-PCA-2 rotors.

**Recommendation:** Validate PCA-2 empirical model against Pfister & Blondel's free-vortex reference cases for the specific rotor geometry. If discrepancy exceeds 15%, plan BEM migration.

---

## DISCUSSION POINTS — Design Decisions to Confirm

### 8. Operating L/D ≈ 1.0 vs. rotor capability of 11.5–16.8
The code's optimal operating point (α_eff=50° at elev=50°) gives PCA-2 L/D≈0.95. The same PCA-2 rotor achieves L/D≈11.5 at lower AoA in aircraft configuration. The code maximizes along-line force (F_line = L·sin φ + D·cos φ) — at steep elevation, drag contributes significantly along the line, so the optimizer pushes toward high-α regimes where L/D is poor.

This is a design choice, not a bug, but contrasts with the wiki's emphasis on the coaxial architecture potentially approaching rotor-alone L/D (~16.8). The stacked kite configuration appears to operate rotors as drag-augmented lift devices rather than high-L/D airfoils.

**Question for review:** Is this the intended operating regime? At shallower elevations (20–30°), the optimal α would shift toward higher L/D.

---

### 9. PCA-2 axes convention unverified
**Severity:** Potentially critical if wrong

The code assumes PCA-2 CL is ⊥ wind (lift direction) and CD is ∥ wind (drag direction) — standard aircraft wind axes. Helicopter/autogyro literature sometimes uses disk axes where CL is normal to the rotor disk plane.

**Recommendation:** Verify NASA TM 20080022367 axis convention. If disk axes, the force resolution `F_line = L·sin(elev) + D·cos(elev)` must be recomputed.

---

### 10. Carceller (2020): 18% power overestimation from neglected dynamic inflow
**Severity:** Medium (v2 scope, but magnitude is first-order)

Carceller's RAWES simulator with Pitt & Peters 3-state dynamic inflow shows 18% power overestimation without the inflow model. This is a first-order effect, not a refinement.

**Recommendation:** Add to v2 scope. Quantify the expected correction for coaxial (non-RAWES) rotors specifically.

---

### 11. Carceller (2020): 3-blade oscillation rules out 3-blade coaxial stacks
Carceller found 13% amplitude oscillation for 3 blades vs. ~1% for 4+ blades. The Daisy's 6-tether-per-ring geometry effectively provides 6 blades. This constrains minimum blade count for coaxial configurations.

**Question for review:** Should `n_blades < 4` be warned against or constrained at the API level?

---

## SUMMARY TABLE

| # | Issue | Confidence | Severity | Action |
|---|-------|-----------|----------|--------|
| 1 | PCA-2 applied to all geometries | High | Critical | Rework |
| 2 | `optimal_pitch` sweeps tilt not pitch | High | High | Rename/Fix |
| 3 | Identical pitch for all rotors | High | Medium | Document v2 |
| 4 | Line drag crossflow overestimate | Medium | Medium | Fix or roadmap |
| 5 | Fixed CD=1.2 for line drag | Medium | Low-Med | Validate |
| 6 | 21% induction power error | Medium | Medium | Document |
| 7 | High-α operating range unvalidated | Medium | Medium | Validate |
| 8 | L/D ~1.0 vs 11.5 capability | Discussion | — | Confirm intent |
| 9 | PCA-2 axes convention | Unverified | High if wrong | Verify |
| 10 | 18% dynamic inflow error | Medium | Medium | v2 roadmap |
| 11 | 3-blade oscillation constraint | Medium | Low | Consider guard |

---

## References (from wiki)

- Duquette & Visser (2003): Solidity effects on small rotors — `raw/papers/duquette-visser-solidity-2003.md`
- Kheiri et al. (2018): Crosswind induction for AWE — `concepts/crosswind-power-law.md`
- Carceller (2020): RAWES dynamic simulator — `raw/papers/carceller-rawes-dynamic-simulator-2020.md`
- Pfister & Blondel (2020): BEM vs. vortex for rotary AWE — `raw/papers/pfister-blondel-bem-vortex-rotary-2020.md`
- Tulloch (2019): TRPT 2nd year review — `raw/papers/tulloch-2nd-year-review-2019.txt`
- Tulloch (2021): Rotary AWE PhD — `raw/papers/tulloch-rotary-awe-phd-2021.md`
- Tulloch et al. (2022): TRPT modelling — `raw/papers/tulloch-energies2022-trpt.md`
- Pfister & Blondel (2020): Mangler & Squire inflow — `concepts/autogyro-aerodynamics.md` §Mangler & Squire
- NASA TM 20080022367: PCA-2 wind tunnel tests — source of `pca2_data.jl`
- Harris (2003): Autogyro overview / XV-1 — `raw/papers/harris-autogyro-overview-xv1-2003.md`
