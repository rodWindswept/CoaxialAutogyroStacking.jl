# Phase 9a — Dimensioned Assembly Specification

> Generated from live Julia model 2026-07-03.
> All forces from `CoaxialAutogyroStacking.jl` at best sweep config:
> R=3.0m, σ=0.0318, tilt=10°, elev=55°, v=8 m/s.

## Operating Point

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
| Disk solidity | 0.0318 | σ = n_blades×chord/(π×R) |

## Tube — Tension Tie-Rod

| Property | Value | Rationale |
|----------|-------|-----------|
| Material | Carbon fibre (pultruded tube) | High specific stiffness, corrosion-proof |
| OD | 25 mm | Standard stock size |
| ID | 15 mm | Clearance for 4mm Dyneema + 2×3mm ties |
| Wall | 5 mm | SF=146× in pure tension (600 MPa UTS) |
| Length | 800 mm | Between top tie and bottom tie |
| Mass | ~0.25 kg | ρ≈1.6 g/cm³, V=π(12.5²−7.5²)×800=251 cm³ |
| Tie holes | 2× Ø5mm opposed | Through-wall at Z=20mm and Z=780mm |
| Tie cord | 3mm Dyneema | Breaking strength ~800 daN, load 647 N/tie |

**Load path:** Rotor lift → top bearing → top molding → tube (tension) → bottom tie → Dyneema.
Tube is NOT in compression. Top tie prevents sliding at zero wind; bottom tie carries operational load.

## Thrust Bearings — SKF 51105

| Property | Value |
|----------|-------|
| Type | Single-direction thrust ball bearing |
| ID × OD × H | 25 × 42 × 11 mm |
| Dynamic load rating | 15.9 kN |
| Limiting speed | 6,300 rpm |
| Mass | 0.06 kg each |
| Quantity per unit | 2 (top + bottom) |

**Margins:**
- Load: 15,900 / 997 = **16×** capacity margin
- Speed: 6,300 / 45 = **140×** speed margin
- Gyro moment (10.6 N·m): within bearing moment capacity — thrust ball bearings tolerate moderate off-axis loads at low speed

The bearing ID (25mm) matches the tube OD — the tube passes through the bearing bore.
Bearings seat in angled recesses in the moldings (machined at δ=10°).

## Moldings — Aluminium 6061-T6

| Property | Value |
|----------|-------|
| Material | Al 6061-T6 (yield 275 MPa) |
| OD | 70 mm |
| ID | 25.5 mm (0.5mm clearance over tube) |
| Height | 20 mm |
| Angled face | 10° (machined to match bearing tilt) |
| Clamping | 2× M4 bolts per molding |
| Mass | ~0.15 kg each (top + bottom = 0.30 kg) |

Bearing stress at clamp interface: 1,294 N / (π × 25 × 20) ≈ **0.8 MPa** — trivial.

## Rotor Hub — Aluminium

| Property | Value |
|----------|-------|
| Material | Al 6061-T6 |
| OD | 80 mm |
| ID | 27 mm (1mm clearance over tube) |
| Height | 60 mm (between bearing faces) |
| Top/bottom faces | Angled 10° (parallel to bearing faces) |
| Mass | ~0.6 kg (solid annulus, estimated) |

## Generator

| Property | Value |
|----------|-------|
| Power output | ~5 W (3 actuators × ~1.5W avg) |
| Torque at 45 RPM | 1.06 N·m |
| Type | Small brushless outrunner used as generator |
| Mounting | 3× units at 120°, radius 45mm from tube center |
| Drive | Friction or gear drive from hub OD |
| Mass | ~0.15 kg (3 units) |

**Torque reaction:** 1.06 N·m at 1.8m tail boom → 0.59 N lateral force needed at tail.
V-fin (0.4×0.15m) at 10 m/s produces ~0.4 N at CL=0.1 — adequate even at very low speeds.

## Swashplate + Actuators

| Property | Value |
|----------|-------|
| Swashplate OD | 80 mm |
| Swashplate ID | 27 mm |
| Rotating ring | Linked to hub via 2× scissor links |
| Stationary ring | Fixed to tube |
| Actuators | 3× micro servo (e.g. Hitec HS-5085MG) |
| Actuator stroke | 10 mm |
| Actuator force | ~20 N (estimated) |
| Power per actuator | ~1.5W average (5W total) |
| Mass (swash + 3 servos) | ~0.2 kg |

**Note:** Blade pitching moment requires BEM for accurate actuator sizing.
Values here are order-of-magnitude estimates based on RC helicopter servos.

## Empennage

| Property | Value |
|----------|-------|
| Tail boom | Carbon tube, 16mm OD, 1,800mm length |
| Boom mass | ~0.15 kg |
| H-stab | 600mm span × 150mm chord, 4mm ply/balsa |
| V-fin | 400mm height × 150mm chord, 3mm ply/balsa |
| Tail surfaces mass | ~0.3 kg |
| Boom tilt | −5° (slight upward toward rotor) |
| Primary role | Torque reaction for generator |
| Secondary role | Passive weathervane (yaw alignment) |

**Sizing check:** Torque reaction requires 0.59 N at tail. V-fin at 10 m/s apparent wind with CL=0.16 produces this easily. The empennage is sized for visibility and weathervane authority, not torque reaction (which is trivial).

## Per-Unit Mass Budget

| Component | Mass (kg) |
|-----------|-----------|
| Carbon tube (25×15, 800mm) | 0.25 |
| Moldings (2× Al, 70×25.5×20mm) | 0.30 |
| Bearings (2× SKF 51105) | 0.12 |
| Rotor hub (Al, 80×27×60mm) | 0.60 |
| Blades (2×, estimated) | 2.00 |
| Generator (3 units) | 0.15 |
| Swashplate + actuators | 0.20 |
| Empennage (boom + H-stab + V-fin) | 0.45 |
| Dyneema ties + fasteners | 0.10 |
| **Total per unit** | **~4.2 kg** |

The sweep assumed 5.0 kg/rotor. Our dimensioned estimate is **4.2 kg** — within budget with 0.8 kg margin for wiring, connectors, and manufacturing tolerances.

## Open Questions

- **Blade mass:** 2.0 kg is a rough estimate. Actual depends on spar construction, skin material, and whether the blades are solid or hollow. BEM (v2) will give better structural requirements.
- **Actuator force:** Needs blade pitching moment from BEM. Current estimate is from RC helicopter experience.
- **Generator efficiency:** 5W from a tiny brushless motor at 45 RPM may be optimistic. A gear stage might be needed.
- **Fixed vs adjustable disk tilt:** Current design uses fixed δ=10° machined into moldings. Adjustable tilt would require a different bearing arrangement.
