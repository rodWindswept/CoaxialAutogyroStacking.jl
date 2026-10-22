# Handover — 2026-08-11 Session (Cameron + Hermes)

**For:** Rod
**Repo:** CoaxialAutogyroStacking.jl
**Status:** 423 tests green. Bastankhah 2026 wake model + slat/pitch/tailplane/yoyo authority sweeps.

---

## 1. BEM Overnight Sweep — 11,520 Configs

Largest parameter sweep yet run on this repo.

| Parameter | Values |
|-----------|--------|
| Radius | 1.0, 1.5, 2.0, 2.5, 3.0, 3.5 m |
| N rotors | 1, 2, 3, 4, 5 |
| Spacing | 5, 10, 15, 20 m |
| Profile | uniform, top_draggy, bottom_lifty, graded |
| Wind | 4, 6, 8, 10, 12, 14 m/s |
| Elevation | 35, 45, 55, 65° |

100% convergence. Output: `scripts/results/bem_overnight_sweep.tsv` (11,520 rows).

**Key findings:**
- Best config: R=3.5m, N=5, graded tilt, 65° elev, 14 m/s → 2,522 N anchor tension
- Tension scales with v² (verified against physics)
- Tilt profile effect is ~12% spread. Graded wins, uniform is practical for manufacturing.
- Wake deficit is visible: per-rotor tension drops from 233 N (N=1) to 214 N (N=5) — each downstream rotor sees ~8% less wind
- R=1.0m produces zero tension — below viability threshold

---

## 2. Gust/Lull Problem — Quantified

Using sweep data at R=3.5m, N=5, graded, 65°:

| Wind | Tension | vs baseline |
|------|---------|-------------|
| 4 m/s | 178 N | 20% |
| 6 m/s | 480 N | 54% |
| 8 m/s | 885 N | baseline |
| 10 m/s | 1,429 N | 161% |
| 12 m/s | 2,032 N | 230% |
| 14 m/s | 2,511 N | 284% |

**Gust 6→14 m/s: 5.3× surge** (469→2,479 N). 205 kg of additional lift in seconds.
**Lull 14→6 m/s: drops to 19%**. 205 kg of lift vanishing.

The v² problem is real. You design for the gusts, not the average.

---

## 3. Leading-Edge Slat — Research + BEM Model

### Physics
Passive spring-loaded slat at blade leading edge. Deploys automatically at high α (near stall) when leading-edge pressure drops. No actuator, no electronics. Retracts at high speed when dynamic pressure holds it closed.

Research (MDPI 2016, Re=75k–300k): slats increase CL_max 25–40%, delay stall 5–15° at low Reynolds numbers matching autogyro tip regime (Re=2–5×10⁵).

### Code (3 files changed)
- `src/rotor.jl`: added `slat_deployed::Bool` field to `AutogyroRotor`. 7-arg constructor unchanged (defaults to false).
- `src/airfoil_data.jl`: added `naca0012_cl_slat()` and `naca0012_cd_slat()` with tunable constants:
  - `SLAT_CL_BOOST = 1.30` (CL multiplier)
  - `SLAT_CD_PENALTY = 1.15` (drag penalty from slot flow)
- `src/bem.jl`: wired slat functions into `bem_induction()` (line 135)

### Slat Authority Sweep
`scripts/sweep_slat_authority.jl` — R=3.0m, N=3, compares slat on/off:

| Wind | No slat | Slat | Boost |
|------|---------|------|-------|
| 4 m/s | 58 N | 50 N | -15% |
| 6 m/s | 216 N | 243 N | +12% |
| 8 m/s | 410 N | 457 N | +12% |
| 10 m/s | 659 N | 709 N | +8% |
| 12 m/s | 949 N | 1,023 N | +8% |
| 14 m/s | 1,254 N | 1,408 N | +12% |

At 4 m/s the drag penalty dominates — slat reduces tension. At 6+ m/s the CL boost wins, giving 8–12% more tension. This directly helps the lull side of the gust/lull problem.

**However.** This was a single-config test at R=3.0m, N=3. The full-grid sweep tells a different story.

### Full-Grid Slat Sweep (23,040 configs, 66 min)
`scripts/sweep_slat_full.jl` — same grid as the overnight BEM sweep, slat on/off.

**Mean boost across ALL viable configs (R≥2.0m):**

| Wind | Mean off | Mean on | Boost |
|------|----------|---------|-------|
| 4 m/s | 36 N | 41 N | +14% |
| 6 m/s | 170 N | 155 N | -9% |
| 8 m/s | 359 N | 340 N | -5% |
| 10 m/s | 584 N | 549 N | -6% |
| 12 m/s | 845 N | 806 N | -5% |
| 14 m/s | 1,106 N | 1,105 N | -0.1% |

On average, slats REDUCE tension at 6–14 m/s. The drag penalty dominates across the full parameter space. Only at 4 m/s (barely any wind) do they help on average.

**Best-case boost (single best config per wind speed):**

| Wind | Boost | Best config |
|------|-------|-------------|
| 6 m/s | +48% | R=2.5, N=1, uniform, 35° |
| 8 m/s | +43% | R=2.5, N=2, top_draggy, 45° |
| 10 m/s | +19% | R=2.5, N=1, uniform, 55° |
| 12 m/s | +17% | R=2.5, N=5, uniform, 65° |
| 14 m/s | +22% | R=3.5, N=1, uniform, 55° |

Slats help in specific niches: low-to-mid wind, one or two rotors, small-to-mid radius (R=2.5m). They are NOT a universal solution. The single-config test at R=3.0 N=3 was misleading — it happened to be in a favorable regime.

### Sketch
`diagrams/slat-sketch/slat-sketch.png` — two-panel diagram showing slat retracted (flush, for gusts) and deployed (slot open, for lulls).

---

## 4. Blade Pitch Authority

`scripts/sweep_pitch_authority.jl` — R=3.0m, N=3, pitch -5° to +20°:

Pitch gives 5.5–6.6× tension range at higher wind. At 14 m/s: 306 N (pitch=-5°) to 1,678 N (pitch=-2°). Enough authority for active gust rejection. Optimum sits at -2° to 0° (slight nose-down).

---

## 5. Tail Plane Wake Interaction Model

`src/wake.jl`: added `tailplane_effective_wind()` and `tailplane_force()`.

Computes wake deficit + momentum-induced downwash at the empennage. At 0.9m behind rotor, the tail sees 90–93% of freestream with 2–3° downwash. Tail lift: 0.2 N (4 m/s) to 1.7 N (14 m/s). These forces are small — a 9g micro servo has 5× more torque than needed.

---

## 6. Yo-Yo Reeling (Ground-Based Altitude Control)

Cameron's idea: during a wind lull, reel the system in (descend). When wind returns, let line out (climb). Uses altitude as a control variable with one winch on the ground instead of actuators in the air.

### Physics Model
`scripts/sweep_yoyo_authority.jl` — R=3.0m, N=3, wind shear (1/7 power law), reeling speeds 0–3 m/s. 180 configs.

**Steady-state altitude change** (no reeling, just different elevations via line length):

| v_ref | Tension range | Ratio |
|-------|---------------|-------|
| 6 m/s | 112→294 N | 2.6× |
| 10 m/s | 372→845 N | 2.3× |
| 14 m/s | 758→1,519 N | 2.0× |

Changing altitude from 17m (5° elev) to 197m (85° elev) gives 2.0–2.6× tension range through wind shear alone.

**Active reeling at 2 m/s descent** (adds vertical velocity to rotor inflow):

| v_ref | Static | Reeling | Boost |
|-------|--------|---------|-------|
| 6 m/s | 241 N | 399 N | +66% |
| 10 m/s | 723 N | 960 N | +33% |
| 14 m/s | 1,337 N | 1,612 N | +21% |

The boost is strongest at low wind (+66% at 6 m/s) — exactly when you need it during a lull.

**Winch power (P = T × v_reel):** 800 W at 6 m/s to 3.2 kW at 14 m/s. Ground-based, so weight is not a constraint.

### Comparison to Other Approaches

| Approach | Authority | Complexity | Weight aloft |
|----------|-----------|------------|--------------|
| Slats | +8–12% (passive) | Low — spring mechanism | ~50g per blade tip |
| Variable pitch | 5.5× (active) | High — actuators on every rotor | Servos + linkages |
| Yo-yo reeling | 2.6× altitude + 21–66% reeling | Medium — ground winch | Zero |

The yo-yo trades airborne complexity for ground complexity. One winch replaces N rotor actuators. Response time is the critical unknown — can a winch accelerate from 0 to 2 m/s in under a second?

---

## 7. Bastankhah 2026 Generalised Actuator Disk Wake Model

Bastankhah, Hydon, Shapiro, Gayme & Meneveau (2026, J. Fluid Mech.) published a generalised actuator disk wake model. It replaces the simple Jensen/PARK cone with a model that includes turbulent entrainment.

### Physics

The model integrates two wake ODEs (Eqs. 2.17a,b) downstream from the rotor disk with RK4. Two effects drive wake recovery:
- Wake shear entrainment (Eq. 2.5)
- Background turbulence entrainment (Eq. 2.6)

### Functions (src/wake.jl)

- `wake_deficit_bastankhah_upstream` — analytical upstream solution (Eq. 2.18a)
- `entrainment_velocity_bastankhah` — entrainment velocity
- `wake_deficit_bastankhah_downstream` — RK4 downstream integration
- `bastankhah_downstream_solution` — full position, width, velocity arrays
- `bastankhah_ct_from_a` — CT-a relationship (Eqs. 2.23-2.24)
- `bastankhah_a_from_ct` — inverse CT-a relationship
- `wake_deficit(model=:bastankhah)` — unified entry point
- `stack_effective_wind(model=:bastankhah)` — threaded through the stack solver

### Validation

16 new tests in `test/test_wake.jl` match the companion code (AtWIND-lab/Generalised-Actuator-Disk-theory). They cover upstream, downstream, and CT-a iteration.

### Status

Implemented and validated. The default model stays `:jensen` for backward compatibility. The sweeps in this session all used Jensen. The Bastankhah model is ready for future sweeps.

---

## Decision for Rod

Three approaches to the gust/lull problem are now modeled and quantified:

| Approach | Authority | Complexity | Weight aloft | Status |
|----------|-----------|------------|--------------|--------|
| Slats | Niche: +17–48% best-case, -5% avg | Low | ~50g/tip | Code done, full-grid sweep done |
| Variable pitch | 5.5× active | High | Servos/linkages | Code done, sweep done |
| Yo-yo reeling | 2.6× + 21–66% | Medium | Zero | Code done, sweep done |

The question: which combination? Slats are NOT a universal solution — the full-grid sweep shows they hurt on average. They help in specific niches (low wind, few rotors, R≈2.5m). Pitch gives the most authority but needs airborne actuators. Yo-yo offloads complexity to the ground but has unknown response time. They could be layered: yo-yo for altitude management, pitch for fine trim. Slats only if operating in their niche regime.

---

## Files Changed

| File | Change |
|------|--------|
| `src/rotor.jl` | +5 lines: `slat_deployed::Bool` field + outer constructor |
| `src/airfoil_data.jl` | +37 lines: slat CL/CD correction functions |
| `src/bem.jl` | +2/-2 lines: wire slat into induction solver |
| `src/wake.jl` | +390/-29 lines: Bastankhah 2026 wake model + tailplane effective wind/force model |
| `test/test_wake.jl` | +48/-17 lines: Bastankhah 2026 validation tests |
| `scripts/bem_overnight_sweep.jl` | NEW: 11,520-config BEM sweep |
| `scripts/sweep_pitch_authority.jl` | NEW: pitch authority sweep |
| `scripts/sweep_slat_authority.jl` | NEW: slat on/off comparison (single config) |
| `scripts/sweep_slat_full.jl` | NEW: full-grid slat sweep (23,040 configs) |
| `scripts/sweep_yoyo_authority.jl` | NEW: yo-yo reeling authority sweep |
| `diagrams/slat-sketch/slat-sketch.png` | NEW: slat geometry sketch |

All 423 tests green.
