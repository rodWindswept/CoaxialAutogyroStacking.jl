# Phase 10 — v2.0 BEM Autorotation + Polygon Line Geometry

> **For Hermes:** Use test-driven-development skill. RED → GREEN → REFACTOR per task.

**Goal:** Replace PCA-2 empirical disk model with blade-element momentum (BEM) and straight-line geometry with a polygon chain, enabling physics-based autorotation RPM and genuine graded-stacking optimisation.

**Architecture:** BEM splits each blade into N spanwise stations. At each station: induced velocity from momentum theory → local AoA → airfoil CL/CD → blade-element forces → integrate torque. RPM solved from torque equilibrium (Q_aero = 0). Polygon line: each segment's angle determined by force equilibrium of the rotor above it — tension + aerodynamic force + weight determine segment direction. Iterative outer loop: BEM needs local inflow angle → line geometry → BEM → ...

**Tech Stack:** Julia, existing package structure. New files: `src/bem.jl`, `src/airfoil_data.jl`, `src/polygon_line.jl`. Modified: `src/rotor.jl` (new rotor_force_bem function), `src/stack.jl` (polygon tension profile), `src/sweep.jl` (BEM-aware sweep), `src/optimisation.jl` (graded stacking with coupled geometry).

---

## Architecture Decisions (resolve before coding)

### D1. Airfoil data
- **Option A:** NACA 0012 (symmetric, well-characterised, CL_max ~1.0 at Re ~ 10⁵–10⁶). Covers our Re range (1.5×10⁵ at R=1.5m to 6×10⁵ at R=3m).
- **Option B:** NACA 4412 or similar cambered section (better L/D but less data).
- **Default:** NACA 0012 from Abbott & von Doenhoff tables. Pre-compute CL(α), CD(α) at relevant Re. Provide as lookup table like PCA-2 data.

### D2. BEM iteration
- Classic Glauert BEM: axial induction factor solved per annulus. For autorotation (windmill brake state), Glauert correction for a > 0.4.
- N spanwise stations (default 10-20). Trapezoidal integration for torque.
- RPM solved via root-find: f(Ω) = Q_aero(Ω) = 0. Use Brent's method on [Ω_min, Ω_max].

### D3. Polygon line solver
- N rotors → N segments. Tension at rotor i is known (accumulated from above). Force equilibrium at each rotor determines next segment angle.
- Top rotor: T_above = 0, segment angle set by rotor force direction.
- Each subsequent rotor: T_in known (from above), rotor force known → T_out magnitude and direction computed.
- Iterative: initialise with straight line, compute BEM forces, update geometry, repeat until segment angles converge (Δ < 0.1°).

### D4. What to keep from v1
- `AutogyroRotor` struct — add airfoil field, keep geometry fields.
- `AutogyroStack` struct — change `line_angle_deg` to `line_angles_deg::Vector{Float64}` (n_rotors entries, one per segment).
- `rotor_disk_area`, `rotor_solidity`, `effective_alpha` — keep as-is.
- `rotor_force_along_line` — becomes dispatch: same name, new method that uses BEM internally.
- `estimated_autorotation_rpm` — becomes `bem_autorotation_rpm` (solved, not estimated).
- `parameter_sweep` — update to use BEM and polygon line.
- `pareto_front`, `compute_figures_of_merit` — keep as-is.

### D5. Integration contract
- `lift_force_steady(stack, rho, v_wind)` must still return `(F_hub, T_anchor, elevation)`.
- KTD.jl dispatch pattern unchanged.

---

## Task List

### Phase 10a — Airfoil Data

#### Task 1: Create `src/airfoil_data.jl` — NACA 0012 tables
**Files:** Create `src/airfoil_data.jl`, `test/test_airfoil_data.jl`

NACA 0012 CL(α), CD(α) at Re = 1×10⁵, 2×10⁵, 5×10⁵, 1×10⁶. Data from Abbott & von Doenhoff "Theory of Wing Sections" (1949).

CL table: α from -10° to +20° in 1° steps. Linear lift slope ≈ 2π/rad up to stall at ~12-14° (Re-dependent). Post-stall CL drops.

CD table: CD_min ~0.008-0.012 depending on Re. CD ∝ CL² (induced + profile drag).

Provide `naca0012_cl(alpha_deg, Re)` and `naca0012_cd(alpha_deg, Re)` with linear interpolation.

Validation: CL(0°) ≈ 0 (symmetric), CL_max ≈ 0.9-1.1 for our Re range.

#### Task 2: Include and export airfoil functions
Wire into `src/CoaxialAutogyroStacking.jl` and `test/runtests.jl`.

---

### Phase 10b — BEM Core

#### Task 3: `bem_station(r, chord, cl, cd, rho, v_wind, omega, r_annulus)` 
Single blade-element station. Given local radius r, chord, CL(α_local), CD(α_local), computes dT (thrust) and dQ (torque) for an annulus of width dr.

```
v_axial = v_wind * (1 - a)      # induced axial velocity
v_tangential = omega * r        # blade speed
v_rel = sqrt(v_axial^2 + v_tangential^2)
phi = atan(v_axial, v_tangential)  # inflow angle
alpha_local = phi - theta         # AoA = inflow - blade pitch
dT = 0.5 * rho * v_rel^2 * chord * (cl*cos(phi) + cd*sin(phi)) * dr
dQ = 0.5 * rho * v_rel^2 * chord * (cl*sin(phi) - cd*cos(phi)) * r * dr
```

#### Task 4: `bem_induction(rotor, rho, v_wind, omega, n_stations)`
Full BEM loop for one rotor at given RPM. 
- Discretise blade into N stations from hub_radius to radius.
- At each station: iterate to find induction factor a (momentum theory + Glauert correction).
- Return total thrust T and torque Q (integrated across blade, multiplied by n_blades).

```
For each station r_i:
  a = 0.3 (initial guess)
  Repeat until |a - a_new| < 1e-6:
    v_axial = v_wind * (1 - a)
    phi = atan(v_axial, omega * r_i)
    alpha = phi - theta(r_i)   # blade pitch + twist
    cl, cd = naca0012_cl(alpha, Re), naca0012_cd(alpha, Re)
    cn = cl*cos(phi) + cd*sin(phi)
    ct = cl*sin(phi) - cd*cos(phi)
    sigma_local = n_blades * chord / (2*pi*r_i)
    # Glauert correction for a > 0.4 (windmill brake state)
    if cn * sigma_local / (4*sin(phi)^2) > 0.4:
        a_new = glauert_correction(cn, sigma_local, phi)
    else:
        a_new = 1 / (4*sin(phi)^2 / (cn * sigma_local) + 1)
  end
  dT_i = 0.5 * rho * v_rel^2 * chord * cn * dr
  dQ_i = 0.5 * rho * v_rel^2 * chord * ct * r_i * dr
end
T = n_blades * sum(dT_i)
Q = n_blades * sum(dQ_i)
```

#### Task 5: `bem_autorotation_rpm(rotor, rho, v_wind, elev_deg)` 
Root-find for Ω where Q_aero(Ω) = 0 (autorotation equilibrium). Brent's method.

```
f(omega) = bem_induction(rotor, rho, v_wind, omega)[2]  # torque
omega_root = brent(f, omega_min, omega_max)
```

Omega bounds: Ω_min = 0.1 rad/s (just turning), Ω_max = tip_speed_limit / R (noise gate).

#### Task 6: `rotor_force_bem(rotor, rho, v_wind, elev_deg)` 
Full BEM force computation for one rotor. Calls `bem_autorotation_rpm` to find Ω, then runs final BEM pass at that Ω to get T (thrust). Converts thrust to along-line force.

```
omega = bem_autorotation_rpm(rotor, rho, v_wind, elev_deg)
T, Q = bem_induction(rotor, rho, v_wind, omega)
# Thrust is along rotor axis. Project to line:
# Rotor axis ≈ line direction + tilt. F_line ≈ T * cos(tilt).
# Full: F_lift = T*cos(tilt), F_drag from blade drag integration.
F_line = T * cosd(rotor.tilt_deg)  # first-order
```

---

### Phase 10c — Polygon Line Geometry

#### Task 7: `solve_polygon_line(rotors, T_top, rho, v_wind)` 
Given N rotors and tension above top rotor (= 0), compute segment angles iteratively.

```
segment_angles = zeros(N)   # one per segment, from rotor i to rotor i+1 (or anchor)
T = zeros(N+1)              # tension at each position
T[1] = 0                    # above top rotor

For each rotor i (top→bottom):
  F_i, F_lift, F_drag = rotor_force_bem(rotor[i], rho, v_wind, segment_angles[i-1])
  # Force triangle: T[i] from above, F_i from rotor, determine T[i+1] direction
  # T[i+1] = T[i] + F_i (vector sum), segment i runs along T[i+1] direction
  T[i+1] = norm(vector_sum)
  segment_angles[i] = angle_of(T[i+1])
```

Iterate outer loop until all segment angles converge. This couples all rotors — changing tilt on rotor 1 changes the line shape, which changes effective AoA for all rotors below.

#### Task 8: Update `AutogyroStack` struct
Replace `line_angle_deg::Float64` with `line_angles_deg::Vector{Float64}` (one per segment, n_rotors entries for the segments between rotors + to anchor). Or: keep single angle as initial guess, compute polygon internally.

Decision: Keep backward compat. `line_angle_deg` becomes the *anchor* elevation — the angle of the bottom segment. Polygon line angles computed internally. Or: add a `PolygonLineStack` wrapper. 

Simpler: `AutogyroStack` gains a `line_angles_deg::Vector{Float64}` field, initialised from the single `line_angle_deg` in the constructor. `stack_tension_profile` calls `solve_polygon_line` internally.

#### Task 9: Rewrite `stack_tension_profile` for polygon line
Accumulate tension along polygon segments. Each segment at its own angle. Line drag uses segment-specific angle.

---

### Phase 10d — Integration & Sweep

#### Task 10: Dispatch `rotor_force_along_line` to BEM
When BEM data is available (airfoil set on rotor), use BEM. Fallback to PCA-2 for backward compatibility. Or: new function `rotor_force_bem` alongside existing PCA-2 version.

**Simpler:** Keep PCA-2 path as-is (tests stay green). Add `rotor_force_bem` as new public function. v2 sweep uses BEM; v1 sweep still works.

#### Task 11: BEM-aware `parameter_sweep` 
Key change: tilt profile now matters (polygon line couples rotors). Sweep must iterate polygon line solver per config. Add BEM-specific output columns: `autorotation_rpm`, `tip_speed_bem`, `rotor_efficiency` (CP).

#### Task 12: BEM-aware `optimal_rotor_tilts`
Graded stacking with polygon line. Optimise all tilts simultaneously — tilts affect ALL downstream rotors via line geometry. Multivariate optimisation (simplex/Nelder-Mead on N tilt variables).

---

### Phase 10e — Validation & SPEC

#### Task 13: Validation against PCA-2
At the PCA-2 operating point (R=6.86m, c=0.56m, 3 blades, α=10°), BEM should approximately reproduce PCA-2 CL ≈ 0.8–0.9. Test tolerance ±20% (different solidity, airfoil, Re).

#### Task 14: Quality gates (BEM edition)
- Torque → 0 at autorotation RPM (|Q| < 1 N·m)
- RPM is physical: 20 < RPM < 500 for our rotor sizes
- Thrust > 0 at positive α
- Polygon line segment angles monotonic? (Not necessarily — but check for pathological kinks)
- All v1 tests still green (PCA-2 path unchanged)

#### Task 15: Update SPEC.md §5.2, §7
Document BEM limitations: steady-state only, no dynamic inflow, 2-D airfoil data (no 3-D corrections), uniform induced velocity (no tip-loss model in v2.0).

#### Task 16: Re-run sweep
Full BEM + polygon sweep (same parameter grid as Phase 8). Compare Pareto fronts to v1. Document key findings in SPEC.md §6.

---

## File Map

```
src/
  CoaxialAutogyroStacking.jl   ← include new files, export new names
  airfoil_data.jl              ← NEW: NACA 0012 tables
  bem.jl                       ← NEW: BEM core (station, induction, autorotation RPM)
  rotor.jl                     ← MODIFY: add rotor_force_bem
  polygon_line.jl              ← NEW: polygon line solver
  stack.jl                     ← MODIFY: AutogyroStack gains line_angles_deg, polygon tension profile
  optimisation.jl              ← MODIFY: BEM-aware optimal_rotor_tilts
  sweep.jl                     ← MODIFY: BEM-aware sweep
  pca2_data.jl, line_section.jl, viability.jl  ← UNCHANGED

test/
  runtests.jl                  ← include new test files
  test_airfoil_data.jl         ← NEW
  test_bem.jl                  ← NEW
  test_polygon_line.jl         ← NEW
  test_rotor.jl                ← MODIFY: add BEM tests (alongside PCA-2 tests)
  test_stack.jl                ← MODIFY: polygon tension profile tests
  test_optimisation.jl         ← MODIFY: BEM-aware tilt optimisation tests
  test_sweep.jl                ← MODIFY: BEM sweep tests
```

## Risks

1. **BEM convergence failure** — some (Ω, α) combinations may not converge. Need robust fallback.
2. **Polygon line iteration may diverge** — need damping or trust-region for angle updates.
3. **Airfoil data accuracy** — tabulated 2-D data doesn't capture 3-D effects, dynamic stall, or rotation augmentation. This is a known limitation.
4. **Performance** — BEM is ~100× slower than PCA-2 lookup table. Sweep goes from seconds to minutes. Acceptable for design exploration but may need caching.
5. **Breaking the KTD.jl integration contract** — must keep `lift_force_steady` signature identical.

## Open Questions

1. **Blade twist?** Current design has 0° twist. BEM can handle twist via θ(r). Add to AutogyroRotor?
2. **Tip-loss model?** Prandtl tip-loss factor F(r). Improves accuracy near tips. Add in v2.1?
3. **Dynamic inflow?** Pitt-Peters or similar. Needed for gust response. v3?
4. **Wake interaction?** Not yet (v3 per SPEC.md). v2 still has all rotors in freestream — only line geometry couples them, not wakes.
