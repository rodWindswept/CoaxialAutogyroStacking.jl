# Mechanical Design PRD — Single Lifting Autogyro Unit

> **Purpose:** Define every mechanical element, its spatial relationship to every
> other element, and the visual requirements for schematic generation. This is
> the source of truth for `schematics/single_unit.scad`. Read this before
> writing or reviewing any OpenSCAD or TikZ.

---

## 1. Coordinate System & Reference Frame

The unit is defined in a **local frame** where:

- **+Z** = Dyneema line direction (from anchor toward free end)
- **Line elevation φ** = angle of +Z above horizontal (typically 45–55°)
- **Wind direction** = horizontal, blowing from −X toward **+X**
- **Tilt axis** = Y axis (disk tilts around Y)
- **Disk tilt:** The **leading edge (−X, windward) tilts UP** into the oncoming wind. The **trailing edge (+X, downwind) tilts DOWN**. Like a kite — the wind hits the underside, driving autorotation.

```
        +Z (up the line, toward free end)
        |
        |   
        |  Wind blows THIS way →
        |  ─────────────────────→
        | /  φ (line elevation)
        |/
   ─────+────────── +X (downwind, horizontal)
       /
      /
     +Y (out of page, tilt axis)
```

**Key relationship:** The rotor disk plane is tilted so the **leading edge (−X, windward side) is higher** than the trailing edge (+X, downwind). The wind hits the underside of the disk — this is what drives autorotation. The disk normal tilts toward −X (upwind):

```
n_disk = (−sin δ, 0, cos δ)   in local tube frame
```

At δ=0, the disk is perpendicular to the line (n_disk = +Z, parallel to line).
At δ>0, the disk normal tilts toward −X (upwind/forward), raising the windward edge.

## 2. Element Inventory

Every element that appears in the visual schematic. Each has a name, geometry, position, and relationship to other elements.

### 2.1 Dyneema Line

| Property | Value |
|----------|-------|
| **Geometry** | Cylinder, Ø4 mm (scaled for visibility) |
| **Extent** | From below bottom tie to above top tie (≈1.2 m visual) |
| **Orientation** | Along +Z (local frame) |
| **Color** | Blue |
| **Role** | Primary tension member. Terminates at topmost rotor. |
| **Relationships** | Passes through center bore of tube, hub, bearings, moldings. Tied to tube at top and bottom positions. |

### 2.2 Central Tube

| Property | Value |
|----------|-------|
| **Geometry** | Hollow cylinder, OD=30mm, ID=16mm, length=800mm |
| **Position** | Centered on Z axis. Bottom at Z=0, top at Z=800mm. |
| **Orientation** | Along +Z |
| **Color** | Grey |
| **Role** | **Tension tie-rod.** Carries rotor lift from top bearing assembly to bottom tie. In tension, NOT compression. |
| **Relationships** | Dyneema passes through center bore. Top molding clamped near top. Bottom molding clamped below rotor. Tied to Dyneema at both ends through wall holes. |
| **Key annotation** | "Tube — tension tie-rod" (NOT compression column) |

### 2.3 Top Tie

| Property | Value |
|----------|-------|
| **Geometry** | Rope loops (Ø3mm Dyneema cord) passing through 2 opposed Ø5mm holes in tube wall at Z≈780mm, stitching to Dyneema inside bore |
| **Position** | Near top of tube (Z≈780mm) |
| **Role** | Prevents tube from sliding down Dyneema at zero/low wind. Secondary load path. |
| **Color** | Sandy brown / orange |
| **Relationships** | Through tube wall → around Dyneema splices inside bore |

### 2.4 Bottom Tie

| Property | Value |
|----------|-------|
| **Geometry** | Rope loops through 2 opposed Ø5mm holes at Z≈20mm, stitching to Dyneema |
| **Position** | Near bottom of tube (Z≈20mm) |
| **Role** | **Primary load path.** Transfers rotor lift from tube into Dyneema. |
| **Color** | Sandy brown / orange |
| **Relationships** | Through tube wall → around Dyneema splices. This is where F_line enters the Dyneema. |

### 2.5 Top Molding

| Property | Value |
|----------|-------|
| **Geometry** | Annular disc, OD=80mm, ID=30.5mm (slip fit over tube), height=25mm. **Underside machined at tilt angle δ.** |
| **Position** | Clamped to tube at Z≈720mm |
| **Orientation** | Horizontal (perpendicular to tube). Angled bearing face on underside. |
| **Color** | Brown |
| **Role** | Clamps top thrust bearing. Transfers lift from bearing to tube (tension). |
| **Relationships** | Clamped to tube via bolts. Top thrust bearing sits in angled recess on underside. |
| **Key detail** | The angled face means the bearing (and everything above it — hub, rotor, blades) is tilted by δ relative to the tube. The tilt is around the Y axis. |

### 2.6 Bottom Molding

| Property | Value |
|----------|-------|
| **Geometry** | Annular disc, OD=80mm, ID=30.5mm, height=25mm. **Topside machined at tilt angle δ.** |
| **Position** | Clamped to tube at Z≈520mm |
| **Orientation** | Horizontal. Angled bearing face on topside. |
| **Color** | Brown |
| **Role** | Supports bottom thrust bearing. Transfers weight/loads from hub to tube. |
| **Relationships** | Clamped to tube. Bottom thrust bearing sits on angled topside. |

### 2.7 Top Thrust Bearing

| Property | Value |
|----------|-------|
| **Geometry** | Annular ring, OD=70mm, ID=32mm, height=8mm with roller elements |
| **Position** | Between top molding underside and rotor hub top face. Tilted at δ around Y. Z≈700mm. |
| **Orientation** | Tilted by δ — plane is parallel to rotor disk plane |
| **Color** | Silver with gold roller balls |
| **Role** | Thrust bearing. Rotor lift pushes hub UP into this bearing → into top molding → into tube. |
| **Relationships** | Sandwiched between top molding (above) and rotor hub (below). Sees pure thrust in steady state. |

### 2.8 Bottom Thrust Bearing

| Property | Value |
|----------|-------|
| **Geometry** | Same as top bearing |
| **Position** | Between rotor hub bottom face and bottom molding topside. Tilted at δ. Z≈540mm. |
| **Orientation** | Tilted by δ |
| **Color** | Silver with gold rollers |
| **Role** | Supports hub weight. In gusts/negative lift, sees upward load. |
| **Relationships** | Sandwiched between hub (above) and bottom molding (below). |

### 2.9 Rotor Hub

| Property | Value |
|----------|-------|
| **Geometry** | Hollow cylinder, OD=100mm, ID=32mm (clears tube), height=70mm. Top and bottom faces angled at δ. |
| **Position** | Between top and bottom bearings. Z≈540–610mm. Dyneema passes through center bore. |
| **Orientation** | Aligned with tilt angle δ — the hub axis is NOT parallel to the tube. The hub's top and bottom faces are parallel to the bearing faces (angled at δ). |
| **Color** | Dark grey |
| **Role** | Houses the rotor. Autorotates around the tube/Dyneema on the thrust bearings. Drives generator. |
| **Relationships** | Sandwiched between two thrust bearings. Rotor disk and blades mount to hub. Swashplate scissor links connect hub to rotating ring. |
| **⚠ CRITICAL:** The hub rotates around the tube axis (+Z), but its faces are tilted at δ. This means the rotor disk plane is tilted at δ from perpendicular to the line. |

### 2.10 Rotor Disk

| Property | Value |
|----------|-------|
| **Geometry** | Thin annulus, R=3000mm, r_inner=55mm (clears hub OD). Thickness=8mm visual. |
| **Position** | Centered on hub at Z≈575mm. |
| **Orientation** | Disk plane tilted by δ around Y axis. Normal = (sin δ, 0, cos δ). **Leading edge (+X side) is tilted forward-down into the wind.** |
| **Color** | Translucent red/pink |
| **Role** | Swept area of rotor — the aerodynamic reference area. |
| **Relationships** | Mounted to hub. Blades extend radially from hub edge. |

### 2.11 Blades

| Property | Value |
|----------|-------|
| **Geometry** | 2 rectangular prisms (airfoil in v2), length=R−r_hub≈2945mm, chord=150mm, thickness=30mm. Extend radially from hub OD. |
| **Position** | Mounted to hub. 180° apart (2 blades). In disk plane (tilted at δ). |
| **Orientation** | In the tilted disk plane. Set at blade_pitch_deg relative to disk plane (0° in v1 — chord parallel to disk plane). |
| **Color** | Dark green/grey |
| **Role** | Aerodynamic surfaces — produce lift via autorotation. |
| **Relationships** | Mounted to hub. Centrifugal force acts radially outward. |

### 2.12 Generator

| Property | Value |
|----------|-------|
| **Geometry** | 3 small boxes (20×15×15mm) at 120° spacing, radius 45mm from tube center |
| **Position** | Mounted on tube at Z≈530mm, at the bottom bearing level |
| **Color** | Silver/Grey |
| **Role** | Driven by autorotating hub. Powers swashplate actuators. |
| **Relationships** | Mounted on tube (stationary). Small gear/belt engages hub OD (rotating). Empennage provides torque reaction so generator actually generates instead of spinning the tube. |

### 2.13 Swashplate

| Property | Value |
|----------|-------|
| **Geometry** | Two annular rings (rotating upper, stationary lower), OD=80mm, ID=32mm, total height=15mm |
| **Position** | On tube at Z≈380mm, below rotor assembly |
| **Color** | Teal (stationary), Dark cyan (rotating) |
| **Role** | Collective pitch control. Rotating ring linked to hub via scissor links; stationary ring on tube. Actuators push stationary ring to tilt swashplate. |
| **Relationships** | Scissor links connect rotating ring to hub. Actuators push stationary ring. |

### 2.14 Actuators

| Property | Value |
|----------|-------|
| **Geometry** | 3 linear servos (14×14×40mm) at 120° spacing, radius 38mm from tube center |
| **Position** | Mounted on tube at Z≈320mm, pushrods extending up to swashplate stationary ring |
| **Color** | Grey |
| **Role** | Drive swashplate for collective blade pitch control. Powered by generator. |
| **Relationships** | Pushrods connect to swashplate stationary ring. Power from generator via short wires. |

### 2.15 Empennage

| Property | Value |
|----------|-------|
| **Geometry** | Tail boom (Ø12mm × 900mm), H-stab (400mm span × 100mm chord), V-fin (250mm × 100mm, hanging below boom) |
| **Position** | Mounted at bottom of tube (Z≈120mm), extends in +X direction (downwind). Boom droops 15° below horizontal. |
| **Orientation** | Boom extends +X (downwind). V-fin hangs in −Z direction (below boom). **In clean inflow — autogyro inflow enters from below.** |
| **Color** | Dark grey |
| **Role** | **Torque reaction for generator.** Without it, generator would spin the tube+rotor assembly around the Dyneema. Also provides weathervane (yaw) alignment and pitch trim. |
| **Relationships** | Mounted to tube bottom. In clean airstream below the rotor (autogyro inflow from below, not above). |

### 2.16 Scissor Links

| Property | Value |
|----------|-------|
| **Geometry** | 2 thin rods connecting hub OD to swashplate rotating ring |
| **Position** | Extending from hub bottom edge (Z≈540mm) down to swashplate rotating ring (Z≈388mm) |
| **Color** | Light grey |
| **Role** | Transmit hub rotation to swashplate rotating ring. |
| **Relationships** | Hub → scissor link → swashplate rotating ring. |

## 3. Force Visualization Requirements

Each force arrow must be clearly identifiable by color and direction:

| Force | Color | Direction | Origin |
|-------|-------|-----------|--------|
| **F_lift** | Green | Perpendicular to wind, upward from disk | Rotor disk center |
| **F_drag** | Orange | Parallel to wind | Rotor disk center |
| **F_line** | Purple | Along Dyneema (+Z), from disk to anchor | Hub center |
| **T_above** | Purple (thin) | Along Dyneema (−Z), above top tie | Top tie point |
| **T_below** | Purple (thick) | Along Dyneema (−Z), below bottom tie | Bottom tie point |
| **F_centrifugal** | Red | Radially outward from hub | Blade root at hub OD |
| **M_gyro** | Orange (curved arrow) | Circumferential around Y axis | Hub/bearing interface |

## 4. Operating Point & Dimensioned Specifications

> All values from live Julia model at best sweep configuration:
> R=3.0m, σ=0.0318, δ=10°, φ=55°, v=8 m/s. Regenerate with `julia --project=. schematics/generate_params.jl`.

### 4.1 Aerodynamic Operating Point

| Parameter | Value | Source |
|-----------|-------|--------|
| F_lift (⊥ wind) | 997 N | `rotor_force_along_line()` |
| F_drag (∥ wind) | 831 N | `rotor_force_along_line()` |
| F_line (along Dyneema) | 1,294 N | `rotor_force_along_line()` |
| Autorotation RPM | 45 | `estimated_autorotation_rpm(λ=2.5)` |
| Tip speed | 14.1 m/s | Ω × R |
| Gyro moment | 10.6 N·m | I·Ω·ω_prec (ω_prec=0.1 rad/s) |
| Centrifugal force/blade | 70 N | m_blade·Ω²·R_cg |
| Anchor tension (4-stack) | 5,065 N | `stack_tension_profile()` |

### 4.2 Dimensioned Components

| Component | Material | Key Dimensions | Margin / Rationale |
|-----------|----------|----------------|---------------------|
| **Tube** | Carbon fibre | 25×15mm, 5mm wall, 800mm long | SF=146× in tension (600 MPa UTS) |
| **Top/Bottom ties** | 3mm Dyneema cord | Ø5mm holes through tube wall | 647 N/tie, cord breaks at ~8,000 N |
| **Bearings** | SKF 51105 thrust ball | 25×42×11mm, C_dyn=15.9kN | 16× load margin, 140× speed margin |
| **Moldings** | Al 6061-T6 | 70mm OD, 25.5mm ID, 20mm tall | 10° angled bearing face |
| **Hub** | Al 6061-T6 | 80mm OD, 27mm ID, 60mm tall | 10° top/bottom faces |
| **Generator** | Brushless outrunner | 3 units at 120°, 45mm radius | 5W at 45 RPM, τ=1.06 N·m |
| **Swashplate** | Al/brass | 80mm OD, 27mm ID, 15mm total | Rotating + stationary rings |
| **Actuators** | Micro servo (3×) | 10mm stroke, ~20N force | ~5W total, powered by generator |
| **Empennage boom** | Carbon tube | 16mm OD, 1,800mm length | Torque reaction arm |
| **H-stab** | Ply/balsa | 600mm span × 150mm chord | Weathervane + pitch trim |
| **V-fin** | Ply/balsa | 400mm height × 150mm chord | Yaw stability, hangs below boom |

### 4.3 Per-Unit Mass Budget

| Component | Mass (kg) |
|-----------|-----------|
| Carbon tube | 0.25 |
| Moldings (2×) | 0.30 |
| Bearings (2× SKF 51105) | 0.12 |
| Rotor hub | 0.60 |
| Blades (2×, estimated) | 2.00 |
| Generator (3 units) | 0.15 |
| Swashplate + actuators | 0.20 |
| Empennage | 0.45 |
| Ties + fasteners | 0.10 |
| **Total** | **~4.2 kg** |

Sweep assumed 5.0 kg/rotor — dimensioned estimate is 4.2 kg (0.8 kg margin).

### 4.4 Key Engineering Checks

- **Tube tension:** 1,294 N on 314 mm² carbon → 4.1 MPa (0.7% of UTS) ✓
- **Bearing thrust:** 997 N vs 15,900 N rating → 6.3% utilization ✓
- **Bearing speed:** 45 RPM vs 6,300 RPM limit → 0.7% utilization ✓
- **Generator torque reaction:** 1.06 N·m at 1.8m boom → 0.59 N tail force needed. V-fin produces ~0.4 N at CL=0.1, 10 m/s — adequate ✓
- **Tie hole bearing:** 647 N on 3mm Dyneema through 5mm carbon hole — non-critical ✓
- **Tip speed noise:** 14.1 m/s vs 120 m/s limit — inaudible ✓

## 5. Annotation Requirements

Every element needs a label. Labels must be:
- Oriented to be readable in the default isometric view
- Placed outside the geometry with leader lines where needed
- Sized proportionally (12pt for major elements, 10pt for details)

Required labels:
1. "Dyneema line (Ø4 mm)" — along the blue line
2. "Tube — tension tie-rod" — along the grey tube (NOT "compression")
3. "Top tie → Dyneema" — at top rope position
4. "Bottom tie → Dyneema (primary load)" — at bottom rope position
5. "Top molding (angled bearing face)" — at top molding
6. "Top thrust bearing" — at top bearing
7. "Rotor hub (autorotates)" — at hub
8. "Blade (2×)" — at blade tip
9. "Rotor disk (R=3.0 m)" — annotation arrow to disk edge
10. "Bottom thrust bearing" — at bottom bearing
11. "Bottom molding" — at bottom molding
12. "Generator (hub-driven)" — at generator
13. "Swashplate (rotating + stationary)" — at swashplate
14. "Actuator (3×, 120° apart)" — at one actuator
15. "Tail boom" — along boom
16. "H-stab" — at horizontal stabilizer
17. "V-fin" — at vertical fin
18. "T_above" / "T_below" — at tension arrows
19. "F_lift = X N" — at lift arrow
20. Force summary box: T_below = T_above + F_line − W·cos φ + line_drag

## 6. Required Views

The schematic must be exportable in these views:

1. **Isometric** (default) — shows 3D relationships, all elements visible
2. **Front (+Y view)** — looking along tilt axis. Shows disk tilt angle δ, line elevation φ, blade profile.
3. **Side (−X view)** — looking into wind. Shows disk as edge, empennage profile.
4. **Section A-A** — cut through YZ plane (through Dyneema centerline). Shows tube, bearings, hub in cross-section with internal details.

## 7. Tilt Angle Specification (CRITICAL)

This is the relationship that must be visually correct:

```
Line direction: +Z (local frame)
Disk plane normal: n_disk = (sin δ, 0, cos δ)

When δ = 10°:
  - Disk leading edge (+X side) tilts FORWARD-DOWN by 10°
  - Disk trailing edge (−X side) tilts BACKWARD-UP by 10°
  - Effective AoA = 90° − φ + δ = 90° − 55° + 10° = 45°

Wind direction: horizontal, from +X toward −X
  - At φ = 55° elevation, the wind has components:
    - Along line: v·cos(φ) downward
    - Cross-line: v·sin(φ) perpendicular to line
```

**Visual check:** In the front view (+Y), the rotor disk should appear as an ellipse with the leading edge (−X, windward) tilted UP and the trailing edge (+X, downwind) tilted DOWN — like a kite presenting its underside to the wind.

## 8. Assembly Order (top → bottom)

```
1. Dyneema line (passes through everything)
2. Top tie (rope through tube → Dyneema at Z≈780mm)
3. Top molding (clamped to tube at Z≈720mm, angled underside)
4. Top thrust bearing (sits in top molding recess, tilted δ)
5. Rotor hub (between bearings, tilted δ, autorotates)
6. Rotor disk + blades (mounted to hub, in tilted plane)
7. Bottom thrust bearing (under hub, tilted δ)
8. Bottom molding (clamped to tube at Z≈520mm, angled topside)
9. Generator (mounted on tube at bearing level)
10. Swashplate (on tube at Z≈380mm)
11. Scissor links (hub → swashplate)
12. Actuators (on tube at Z≈320mm, pushrods to swashplate)
13. Empennage (mounted at tube bottom Z≈120mm, extends +X, droops 15°)
14. Bottom tie (rope through tube → Dyneema at Z≈20mm)
```

## 9. Parameter Binding

All dimensions in the visual model come from `schematics/parameters.scad`, which is generated by `schematics/generate_params.jl` from the live Julia model. No hardcoded numbers in the visual model.

**Regeneration workflow:**
```
1. Change Julia model parameters
2. Run: julia --project=. schematics/generate_params.jl
3. Render: openscad --preview -o single_unit.png single_unit.scad
4. Verify: check tilt angle, forces, RPM against expected
```

## 10. Acceptance Criteria

The visual schematic is correct when:

- [ ] Rotor disk appears as tilted ellipsoid at angle δ relative to tube perpendicular
- [ ] Disk leading edge (+X) is forward-down; trailing edge (−X) is backward-up
- [ ] Dyneema passes through center of ALL elements (visible in section view)
- [ ] Tube is labeled as tension tie-rod, not compression
- [ ] Both top and bottom ties are visible
- [ ] Force arrows have correct colors, directions, and labels
- [ ] All 20+ elements have labels
- [ ] Empennage extends downwind (+X) and droops below horizontal
- [ ] Generator and actuators are visible with correct 120° spacing
- [ ] The force summary equation is shown
- [ ] Parameters match live Julia model output (verified by re-running generate_params.jl)
- [ ] Exportable in isometric, front, side, and section views
