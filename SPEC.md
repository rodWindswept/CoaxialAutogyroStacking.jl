# SPEC.md — Coaxial Autogyro Stacking

> Specification for a Julia package modelling multiple lifting autogyro kites
> stacked on a single Dyneema line, computing per-unit forces and cumulative
> line tension. Target: define the most viable, transportable, safe, buildable,
> cost-effective, and reliable stacked autogyro system for kite turbine lift
> operations.

## 1. Concept of Operations

### 1.1 Problem

A kite turbine needs a lift kite to hold its hub at altitude. A single lift
kite is simple but has limitations:

- **Scale:** large kites are hard to launch, land, and handle
- **Reliability:** a single kite failure means total lift loss
- **Gust response:** a single kite's tension varies strongly with wind speed
- **Transport:** a 100 m² kite is hard to handle across the wind range and in rigid wings will be much larger and heavier than 10 x 10 stacked kites

### 1.2 Solution

Stack multiple smaller autogyro lifting units on one Dyneema line. Each unit
is independently controllable. The stack accumulates tension from top
(terminates at the topmost rotor) to bottom (anchor, where it attaches to the
kite turbine hub).

**Why autogyro rotors instead of soft kites:**

- Autorotation provides lift even in gusty conditions (apparent wind at blade
  tip >> freestream wind)
- Rigid rotor disks are more predictable than soft kites (no collapse, no
  luffing)
- Independent pitch per rotor enables graded stacking (top rotors shape the
  line geometry; bottom rotors exploit it)
- Smaller individual units are easier to manufacture, transport, and replace

### 1.3 Operational Modes

The autogyro stack has one job: **pull up**. It operates as a throttle:

| Mode | Stack output | Turbine state |
|------|-------------|---------------|
| **Launch** | Moderate lift — sufficient to raise the turbine from ground | Leaving ground |
| **Cruise** | Steady lift — resist gusts, hold anchor tension within bounds | Generating power |
| **Lift-to-stall** | Maximum lift — pull turbine to zenith to stall its own aerodynamics | Stalled, descending for landing |

The stack **never** depowers. It is always lifting. The kite turbine below
handles its own stall/depower by being pulled to zenith.

## 2. Unit Definition — The Lifting Autogyro Kite

### 2.1 Geometry

A single unit consists of:

```
  Rotor blades (2, freely autorotating)
  Rotor disk (swept annulus, radius R, hub radius r_hub)
  Hollow hub (around Dyneema line, on thrust bearings)
  ─── Top molding (angled underside = disk tilt δ) ───
  Thrust bearing (top)
  ─── Tube (compression column, Dyneema through centre bore) ───
  Thrust bearing (bottom)
  ─── Bottom molding ───
  Swashplate (collective pitch control, 3 actuators)
  Empennage (tail boom + H-stab + V-fin, downwind, below line)
  Webbing capture → spliced eye in Dyneema
```

### 2.2 Aerodynamic Model

| Fidelity | Model | What it captures |
|----------|-------|-----------------|
| v1 (current) | PCA-2 empirical disk (NASA TM 20080022367) | CL(α), CD(α) as black-box disk; 1-D lookup on effective AoA |
| v2 | Blade-element momentum (BEM) | Autorotation RPM from torque balance; blade geometry matters |
| v3 | BEM + wake model | Rotor-to-rotor interaction; non-uniform inflow |

**Effective angle of attack:**

```
α_eff = 90° − θ_segment + δ
```

where θ_segment is the local line segment elevation angle and δ is the disk
tilt angle (leading edge forward-down into the wind).

### 2.3 Mechanical Design

Key design decisions (see `schematics/assembly_v2.pdf`):

- **Dual-molding sandwich bearing:** two moldings clamp the rotor hub via
  thrust bearings above and below. Hub autorotates; bearings see pure thrust.
- **Angled bearing face:** top molding underside and bottom molding topside
  are machined at the disk tilt angle δ.
- **Webbing capture:** Spectra loops pass through wall slots at tube bottom,
  attach to spliced eyes braided into the Dyneema line. Tube is physically
  trapped — no sliding, no rattling.
- **Empennage downwind and below:** tail boom droops ~15° below horizontal.
  V-fin hangs below boom. In clean inflow (not rotor wash — autogyro inflow
  enters from below).

### 2.4 Control Degrees of Freedom

| DOF | Mechanism | Scope | Essential? |
|-----|-----------|-------|-----------|
| Disk tilt δ | Empennage trim + molding angle | Set at manufacture? Adjustable? | Sets baseline AoA |
| Blade pitch (collective) | Swashplate, 3 actuators | Per rotor | Enables graded stacking |
| Cyclic pitch | Swashplate (differential) | Per rotor | Probably v3+ |
| Yaw (weathervane) | V-fin, free rotation around Dyneema | Passive | Built-in |

**Open question:** Is disk tilt a fixed manufacturing parameter or an active
control surface? The mechanical design allows either — the molding angle sets
the tilt, but could be made adjustable.

## 3. Stack Model

### 3.1 Ordering

Rotors are indexed **top → bottom** (index 1 = topmost, terminates the
line). Section lengths (n_rotors entries) are the Dyneema segments between:

```
section_lengths[1] = distance rotor_1 → rotor_2
section_lengths[2] = distance rotor_2 → rotor_3
...
section_lengths[n] = distance rotor_n → anchor
```

The topmost rotor terminates the line — no line section extends above it.

### 3.2 Tension Accumulation

```
profile = zeros(n_rotors + 1)
profile[1] = 0  # at topmost rotor, nothing pulls from above

for k in 2:n_rotors+1:
    section_drag = bare_line_drag(ρ, v, d_line, section_lengths[k-1])
    rotor_force = F_line(rotors[k-1]) − mass[k-1]·g·cos(θ)
    profile[k] = profile[k-1] + section_drag + rotor_force
```

`profile[end]` = anchor tension — the lift delivered to the kite turbine hub.

### 3.3 Line Geometry (v2+)

In v1 the line is assumed straight at a single elevation angle. In v2 the
line forms a polygon chain — each segment at a different angle as cumulative
rotor forces reshape the geometry. This couples the rotors: changing a top
rotor's tilt alters the effective AoA of every rotor below it.

### 3.4 Graded Stacking

Rotors need not be identical. A graded stack varies tilt (or pitch) by
position:

- **Top-draggy:** high tilt at top → drag shapes line outward → lower rotors
  see better angle
- **Bottom-lifty:** low tilt at top → line stays steep → lower rotors at
  optimal L/D
- **Uniform:** all rotors identical (baseline)

The optimal profile is unknown and is a primary output of the parameter sweep.

## 4. Interface Contract with KTD.jl

This package is designed for eventual integration into KiteTurbineDynamics.jl.

### 4.1 Integration Point

```julia
# KTD.jl already imports our PCA-2 data:
import CoaxialAutogyroStacking: pca2_interp

# Future: AutogyroStack <: KTD.LiftDevice
lift_force_steady(stack::AutogyroStack, rho, v_wind) -> (F_hub, T_anchor, elevation)
```

### 4.2 Conventions

- **SI units throughout** (N, m, kg, s, rad)
- **Angles in degrees** at API boundary (`sind`/`cosd` internally)
- **Rotors ordered top→bottom** (index 1 = topmost)
- **Tension profile:** `n_rotors + 1` entries, `profile[end]` = anchor
- **Pure functions** where possible; immutable structs

### 4.3 What This Package Does NOT Own

- Wind field / turbulence model → consume from KTD.jl
- Catenary / line shape ODE → consume from KTD.jl or Tveide model
- Moving anchor dynamics → KTD.jl simulation framework
- Structural FEA (tube buckling, bearing loads) → separate tool
- Control system logic (when to throttle, launch/land sequences) → separate
  controller

## 5. Known Limitations

### 5.1 v1 (current)

- **No wake interaction:** downstream rotors see freestream. Wake coupling
  deferred to v3.
- **Rigid straight line:** single shared elevation angle. Polygon chain
  deferred to v2.
- **PCA-2 is a disk model:** blade geometry (airfoil, twist, planform) not
  resolved. BEM deferred to v2.
- **No blade pitch parameterisation:** the PCA-2 lookup is 1-D (AoA only).
  Blade pitch field exists on struct but is unused.
- **Re regime awareness:** `viability_report()` and sweep viability columns
  (`tip_speed`, `tip_reynolds`) flag configurations outside PCA-2's valid
  Re range (Re < 5×10⁵) or above the 120 m/s noise limit. (Added Phase 8.5)
- **Steady-state only:** no time dynamics, no gust response, no launch/land
  transients.

### 5.2 v2 (current)

- Blade-element momentum (BEM) replaces PCA-2 disk lookup
- Autorotation RPM solved from torque equilibrium (Q = 0 via bisection on
  `bem_induction`)
- Polygon line geometry: segment angles determined by force equilibrium at
  each rotor (`solve_polygon_angles`). Graded stacking is now meaningful —
  top-rotor tilt reshapes the line, altering effective AoA for rotors below.
- Airfoil data: NACA 0012 CL/CD tables at Re = 10⁵, 2×10⁵, 5×10⁵, 10⁶
  (XFoil 6.96, airfoiltools.com). Higher-Re tables scaled from Re=10⁵
  using Abbott & von Doenhoff (1959).
- BEM-aware parameter sweep (`parameter_sweep_bem`) and multivariate
  coordinate-descent tilt optimisation (`optimal_rotor_tilts_bem`).

**Known limitations (v2.0):**
- 1-D axial BEM — does not model cross-flow (rotor-disk AoA effects
  are projected via `v_through = v_wind × sin(α_eff)`). Under-predicts
  forces compared to PCA-2 disk model (~10×) due to 2-D airfoil data
  not capturing rotational augmentation and disk-averaging effects.
- Steady-state only — no time dynamics, gust response, or launch/land
  transients.
- No tip-loss model (Prandtl factor). Conservative near blade tips.
- No 3-D rotational corrections to airfoil data (Snel, Du & Selig).
- Polygon line uses Jacobi iteration — may not converge for extreme
  tilt profiles.
- BEM is ~100× slower than PCA-2 lookup — parameter sweeps use reduced
  grids (default 8 configurations vs 8,640).

### 5.3 v3 (future)

- Multi-rotor dynamics with time-varying wind
- Blade pitch control (collective + cyclic)
- Wake interaction between rotors

## 6. Parameter Space & Sweep Results

> Sweep run 2026-06-15. 1,728 post-processed configurations from 8,640 raw
> evaluations. Data: `sweep_results.tsv`. Plots: `sweep_*.png`.

### 6.1 Sweep Configuration

| Parameter | Values |
|-----------|--------|
| Rotor radius (m) | 0.5, 1.0, 1.5, 2.0, 2.5, 3.0 |
| Stack count N | 1, 2, 3, 4 |
| Rotor spacing (m) | 5, 10, 15, 20, 25, 30 |
| Tilt profile | uniform, top-draggy, bottom-lifty, graded |
| Wind speed (m/s) | 4, 6, 8, 10, 12 |
| Line elevation (°) | 45, 55, 65 |

Fixed: 2 blades, 4 mm Dyneema, 5 kg per rotor, PCA-2 disk model, straight line.

### 6.2 Figures of Merit

- **Anchor tension (N):** cumulative lift delivered at anchor — the raw output
  passed to the kite turbine hub.
- **Tension per rotor mass (N/kg):** mass efficiency — how much lift each kg of
  rotor hardware buys you. Higher is better.
- **Tension CV:** coefficient of variation in anchor tension across the 5 wind
  speeds; lower = more stable through gusts.

### 6.3 Key Findings

#### Scaling is dominated by radius (quadratic)

Mean anchor tension vs rotor radius across all configurations:

| Radius (m) | Mean tension (N) | Mean N/kg |
|------------|-------------------|-----------|
| 3.0 | 3,365 | 275 |
| 2.5 | 2,318 | 190 |
| 2.0 | 1,462 | 120 |
| 1.5 | 796 | 65 |
| 1.0 | 320 | 26 |
| 0.5 | 35 | 3 |

Tension scales with disk area ∝ R², as expected from the PCA-2 disk model.
Radii below ~1.5 m produce marginal lift-to-weight ratios; R ≥ 2.0 m is the
practical floor.

#### Stack count scales nearly linearly with negligible efficiency penalty

At any given radius, N/kg is essentially constant across N = 1–4. The penalty
from line drag and rotor weight is ~2% per added rotor at R=3.0 m, falling to
~0.7% at R=1.0 m. Stacking does not degrade per-rotor efficiency — you get N×
the lift for N× the mass, minus a tiny drag tax.

**N/kg for R=3.0 m across stack counts:**

| N | Mean N/kg | Anchor tension (N) |
|---|-----------|---------------------|
| 1 | 275.1 | 1,434 |
| 2 | 275.1 | 2,868 |
| 4 | 270.0 | 5,697 |

#### Tilt profile barely matters in v1 (this is expected)

| Profile | Mean N/kg | Mean CV |
|---------|-----------|---------|
| uniform | 113.1 | 1.024 |
| graded | 112.0 | 1.036 |
| top-draggy | 109.2 | 1.050 |
| bottom-lifty | 109.2 | 1.050 |

The differences are ~3% in N/kg and negligible in CV. **This is a v1 artefact,
not a null result.** With a rigid straight line, changing a rotor's tilt only
changes that rotor's effective AoA — it cannot reshape the line geometry for
the rotors below. The whole premise of graded stacking depends on polygon line
geometry (v2), where a top rotor's tilt angles the segment below it, altering
the effective AoA of every downstream rotor.

**Conclusion:** v1 confirms that tilt profile differentiation requires the
polygon line model. The sweep validates the measurement machinery; the
interesting optimisation belongs in v2.

#### Spacing has negligible effect

Across 5–30 m spacing, mean anchor tension varies from 1,376 to 1,389 N — a
<1% spread. Line drag (Dyneema, 4 mm) is swamped by rotor forces at all
reasonable configurations. Spacing is a mechanical/packaging concern, not an
aerodynamic one in v1.

#### Elevation angle trades lift for reach

Mean tension: 45° = 1,433 N, 55° = 1,427 N, 65° = 1,288 N. Flatter elevations
(lower angle) produce more lift because the rotor presents more disk area to the
wind, but the stack reaches less altitude. At 65° the rotor is nearly
edge-on to the wind — the PCA-2 disk model barely produces lift.

**Recommended envelope:** 45–55° for useful lift; 65° only for low-drag loiter.

#### Gust stability (tension CV) is nearly uniform

All viable configurations (R ≥ 1.5 m) have CV ≈ 0.72–0.85 — tightly clustered.
The autogyro rotor's natural lift curve (CL increasing with α up to stall)
gives it a self-limiting characteristic: as wind rises, effective α decreases
slightly, moderating the tension increase. Tension varies roughly as v² but
sub-quadratically, giving better gust stability than a fixed-pitch soft kite.

#### Pareto front is thin

Only 2–3 configurations lie on each Pareto frontier because tension, N/kg, and
CV are nearly co-linear for viable rotors — the same configurations win on all
fronts. This will change in v2 when tilt profile creates genuine trade-offs
between raw lift and gust stability.

### 6.4 Best Configuration (v1)

| Parameter | Value |
|-----------|-------|
| Rotor radius | 3.0 m |
| Stack count | 4 |
| Spacing | 15–30 m |
| Tilt profile | uniform (any profile works) |
| Line elevation | 55° |
| **Anchor tension (8 m/s)** | **5,086 N** |
| **N/kg efficiency** | **271 N/kg** |
| **Tension CV** | **0.72** |

At 12 m/s this configuration delivers ~11.6 kN — sufficient to lift a small
kite turbine hub (comparable to a 5–10 m² soft kite at similar wind). The mass
penalty: 4 rotors × 5 kg + Dyneema + bearings ≈ 25–30 kg total for ~5 kN
continuous lift at cruise wind.

### 6.5 Limitations of This Sweep

- Run before the rope-can't-push fix (2026-06-19). Pathological configurations
  (R ≤ 0.5 m at 4 m/s) show negative `min_tension` entries because the old
  `stack_tension_profile` permitted negative accumulated tension. These are
  clamped to zero in the fixed model. Viable configurations (R ≥ 1.0 m) are
  unaffected — all intermediate tensions are positive.
- Straight-line geometry collapses tilt-profile differentiation. The sweep
  validates the pipeline; tilt-profile optimisation is a v2 deliverable.

### 6.6 BEM Sweep (v2.0)

> Sweep run 2026-07-24. 384 configurations (3 radii × 4 counts × 4 profiles × 4 wind speeds × 2 elevations).
> Data: `bem_full_sweep.tsv`. Run time: 15.6 s.

#### Viability threshold

R=1.5m is below the BEM viability threshold with NACA 0012 — at all wind
speeds the rotor cannot overcome its own weight (T=0, rope-can't-push clamp).
R=2.0m is the minimum viable radius; R=3.0m is the practical design point.

#### Graded stacking confirmed

At R=3.0m, N=2, 8 m/s:
| Profile | Anchor tension (N) | vs uniform |
|---------|-------------------|------------|
| uniform | 245 | baseline |
| top_draggy | 276 | **+12.7%** |
| bottom_lifty | 256 | +4.5% |
| graded | 253 | +3.3% |

At 12 m/s the advantage narrows: top_draggy +6.9%, bottom_lifty +2.4%.
Tilt-profile differentiation is meaningful with polygon line geometry —
the v1 null result (≤3% difference) was a straight-line artefact.

#### Profile optimum depends on radius

| Radius | N=2 best profile | Tension (N) | RPM |
|--------|-----------------|-------------|-----|
| 2.0m | bottom_lifty | 121 | 133 |
| 3.0m | top_draggy | 276 | 84 |

Smaller rotors prefer bottom-lifty (concentrate tilt at lower rotors where
tension is higher); larger rotors prefer top-draggy (use top rotor to pull
line outward, improving AoA for rotors below). This radius-dependent optimum
is a new result not visible in the v1 PCA-2 sweep.

#### Top 5 configurations (8 m/s)

| Radius | N | Profile | Elev | Tension (N) |
|--------|---|---------|------|-------------|
| 3.0m | 4 | top_draggy | 45°/55° | 649 |
| 3.0m | 4 | uniform | 45°/55° | 622 |
| 3.0m | 4 | graded | 45° | 609 |
| 3.0m | 3 | top_draggy | 45° | 450 |
| 3.0m | 3 | uniform | 45°/55° | 418 |

#### Scaling laws (BEM)

- Tension ∝ v² (as expected from dynamic pressure)
- Tension ∝ N (linear with rotor count, ~2% efficiency loss per added rotor)
- RPM ∝ √v (sub-linear, 74→105 RPM for 8→12 m/s at R=3m)
- Elevation effect: 45° gives marginally more tension than 55° (~4%)
- Tip speeds: 23-38 m/s at R=3m — well below 120 m/s noise limit

#### Recommended configuration (v2.0 BEM)

| Parameter | Value |
|-----------|-------|
| Rotor radius | 3.0 m |
| Stack count | 4 |
| Tilt profile | top_draggy (20°/5°/0°) |
| Line elevation | 45–55° |
| **Anchor tension (8 m/s)** | **649 N** |
| **Per-rotor efficiency** | **32.5 N/kg** |
| **Autorotation RPM** | **~84** |
| **Tip speed** | **~26 m/s** |
- No wake interaction. All rotors see freestream. Wake coupling (v3) will
  reduce downstream rotor performance.



## 7. Phased Evolution

| Phase | TRL | Deliverable | Status |
|-------|-----|-------------|--------|
| **v1.0** | 1–2 | Steady-state force model, PCA-2 disk, parameter sweep results, SPEC.md | ✓ DONE |
| **v1.1** | 2–3 | Mechanical design specification, schematics, 3D models | ✓ DONE |
| **v2.0** | 3–4 | BEM autorotation model, polygon line geometry, graded stacking optimisation | ✓ DONE |
| **v3.0** | 5–6 | Multi-rotor dynamics, gust response, blade pitch control, fabrication drawings | planned |
| **v4.0** | 7+ | KTD.jl integration, moving anchor, wake interaction | planned |

---

## References

- PCA-2 CL/CD data: NASA TM 20080022367
- Stacked-kite tension model: KiteTurbineDynamics.jl/src/lift_kite.jl
- AWES standards: IEA Wind Task 48, AWEC 2024 proceedings
- Inner Kite / SkySails: lightweight wing manufacturing techniques
- Tveide tether drag: https://github.com/tallakt/TetherDragODESolver
