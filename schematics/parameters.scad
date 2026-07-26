// ╔══════════════════════════════════════════════════════════════════╗
// ║  COAXIAL AUTOGYRO STACKING — Shared Parameters                   ║
// ║  AUTO-GENERATED from Julia model on 2026-07-26T12:43:33.116  ║
// ║  Source: schematics/generate_params.jl                            ║
// ║  Regenerate: julia --project=. schematics/generate_params.jl      ║
// ╚══════════════════════════════════════════════════════════════════╝
//
// PHYSICAL LAYOUT (tube-local coordinates, Z = up along tube):
//
//   Z=780  ── TOP TIE ── Dyneema captured by spliced eye
//   Z=740  ── TOP MOLDING ── Angled underside = disk tilt δ
//   Z=720  ── TOP BEARING ── SKF 51105 thrust ball (ID=25, OD=42, H=11 mm)
//   Z=709  ── HUB TOP ── Aluminium, rides on bearings, autorotates
//   Z=679  ── ROTOR DISK ── Centre of 2-blade rotor (R=3000 mm)
//   Z=649  ── HUB BOTTOM
//   Z=649  ── BOTTOM BEARING
//   Z=638  ── BOTTOM MOLDING
//   Z=643  ── GENERATOR ── 3× coils on tube, 5 W
//   Z=620  ── SWASHPLATE ── Collective pitch, 3 actuators
//   Z=560  ── ACTUATORS ── Linear servos (3×, 120° apart)
//   Z=120  ── EMPENNAGE ── Tail boom + H-stab + V-fin (downwind)
//   Z=20   ── BOTTOM TIE ── Primary load path to anchor
//
//   ┌─────────────────────────────────────────────────┐
//   │  Dyneema runs through centre bore of tube       │
//   │  Tube = carbon fibre 25×15 mm, 5 mm wall        │
//   │  Rotor autorotates on pair of thrust bearings    │
//   │  Wind blows toward +X (horizontal, world frame)  │
//   │  Line elevation: 55.0° from horizontal             │
//   └─────────────────────────────────────────────────┘
//
// ═══════════════════════════════════════════════════════════════════
//  1. OPERATING CONDITIONS
// ═══════════════════════════════════════════════════════════════════
//     Best configuration from Phase 8 PCA-2 sweep (R=3.0 m, N=4):
//       Anchor tension: 5071.0 N at 8.0 m/s (lifts ~517.0 kg)
//       N/kg efficiency: 254.0 N/kg
//       Tension CV (gust stability): 0.72

WIND_SPEED        = 8.0;    // m/s   — freestream wind at hub height
AIR_DENSITY       = 1.225;  // kg/m³ — ISA sea-level standard
LINE_ELEVATION    = 55.0;   // deg   — line angle above horizontal
EFFECTIVE_ALPHA   = 45.0;   // deg   — α_eff = 90° − elevation + tilt

// ═══════════════════════════════════════════════════════════════════
//  2. ROTOR GEOMETRY  (3.0 m radius, 2 blades, PCA-2 disk model)
// ═══════════════════════════════════════════════════════════════════

ROTOR_RADIUS      = 3000.0; // mm    — blade tip to hub centre
HUB_RADIUS        = 50.0;   // mm    — central bore radius
N_BLADES          = 2;      // count — two-bladed teetering rotor
BLADE_CHORD       = 150.0;  // mm    — blade width (NACA 0012 section)
BLADE_THICKNESS   = 30.0;   // mm    — visual thickness (cosmetic)
TILT_ANGLE        = 10.0;   // deg   — disk forward tilt (machined into bearing face)
BLADE_PITCH       = 0.0;    // deg   — collective pitch offset (v2+ only)
ROTOR_MASS        = 5.0;    // kg    — per rotor (blades + hub + bearings)
ROTOR_SOLIDITY    = 0.0318; // —     — σ = N_blades × chord / (π × R)

// ═══════════════════════════════════════════════════════════════════
//  3. AERODYNAMIC FORCES  (computed by rotor_force_along_line)
// ═══════════════════════════════════════════════════════════════════

CL_OPERATING      = 0.9;    // —     — lift coefficient at α_eff=45.0° (PCA-2 table)
CD_OPERATING      = 0.75;   // —     — drag coefficient at α_eff=45.0°
F_LIFT            = 997.0;  // N     — lift ⊥ wind, per rotor
F_DRAG            = 831.0;  // N     — drag ∥ wind, per rotor
F_LINE            = 1294.0; // N     — force projected along Dyneema line
ANCHOR_TENSION    = 5071.0; // N     — cumulative tension at anchor (4-rotor stack, 8.0 m/s)

// ═══════════════════════════════════════════════════════════════════
//  4. AUTOROTATION  (estimated from tip-speed ratio λ ≈ 2.5)
// ═══════════════════════════════════════════════════════════════════

ROTOR_RPM         = 45.0;   // rpm   — steady-state autorotation speed
TIP_SPEED         = 14.1;   // m/s   — Ω × R (well below 120 m/s noise limit)
OMEGA             = 4.71;   // rad/s — angular velocity
GYRO_MOMENT       = 10.6;     // N·m   — gyroscopic precession torque (I·Ω·ω_prec)
CENTRIFUGAL_FORCE = 70.0;    // N     — per-blade centrifugal load at 70% radius

// ═══════════════════════════════════════════════════════════════════
//  5. LINE  (Dyneema SK99, 4.0 mm)
// ═══════════════════════════════════════════════════════════════════

LINE_DIAMETER     = 4.0;    // mm    — Dyneema SK99 (breaking strength ~13 kN)

// ═══════════════════════════════════════════════════════════════════
//  6. TUBE  (carbon fibre tension tie-rod, 25×15 mm, 5 mm wall)
// ═══════════════════════════════════════════════════════════════════
//     Safety factor: 146× in tension at 1294.0 N (compressive column).
//     Dyneema passes through centre bore. Tube carries compression
//     between top and bottom bearings — doesn't rotate.

TUBE_OD           = 25.0;   // mm    — outer diameter
TUBE_ID           = 15.0;   // mm    — inner diameter (Dyneema channel)
TUBE_LENGTH       = 800.0;  // mm    — from bottom tie to top tie
TUBE_WALL         = 5.0;    // mm    — (OD − ID) / 2
TIE_HOLE_DIA      = 5.0;    // mm    — hole for Dyneema stitching cord (3 mm)
TIE_ROPE_DIA      = 3.0;    // mm    — stitching cord diameter

// ═══════════════════════════════════════════════════════════════════
//  7. HUB  (aluminium, holds rotor disk, rides on bearings)
// ═══════════════════════════════════════════════════════════════════

HUB_OD            = 80.0;   // mm    — outer diameter
HUB_ID            = 27.0;   // mm    — inner diameter (clears 25 mm tube with gap)
HUB_HEIGHT        = 60.0;   // mm    — between bearing faces (top to bottom)

// ═══════════════════════════════════════════════════════════════════
//  8. BEARINGS  (SKF 51105 thrust ball — one above, one below hub)
// ═══════════════════════════════════════════════════════════════════
//     ID=25, OD=42, H=11 mm. Dynamic load rating: 15.9 kN.
//     At 997.0 N lift: 16× capacity margin.
//     At 45.0 rpm: 140× speed margin (limiting speed = 6,300 rpm).

BEARING_OD        = 42.0;   // mm    — SKF 51105 outer diameter
BEARING_ID        = 25.0;   // mm    — slip fit over 25 mm tube
BEARING_HEIGHT    = 11.0;   // mm    — axial thickness

// ═══════════════════════════════════════════════════════════════════
//  9. MOLDINGS  (aluminium 6061-T6 — clamp bearings to tube)
// ═══════════════════════════════════════════════════════════════════
//     Underside of top molding and topside of bottom molding are
//     machined at disk tilt angle δ (10.0°). This sets the rotor disk
//     plane relative to the tube/Dyneema axis.

MOLDING_OD        = 70.0;   // mm    — outer diameter
MOLDING_ID        = 25.5;   // mm    — slip fit over tube (0.5 mm clearance)
MOLDING_HEIGHT    = 20.0;   // mm    — axial thickness

// ═══════════════════════════════════════════════════════════════════
// 10. GENERATOR  (3× coils on tube, harvests autorotation power)
// ═══════════════════════════════════════════════════════════════════

GEN_RADIUS        = 45.0;   // mm    — coil radial position from tube centre
GEN_WIDTH         = 20.0;   // mm    — coil width
GEN_HEIGHT        = 15.0;   // mm    — coil height
GEN_POWER         = 5.0;    // W     — estimated output

// ═══════════════════════════════════════════════════════════════════
// 11. SWASHPLATE + ACTUATORS  (collective pitch control)
// ═══════════════════════════════════════════════════════════════════
//     3 actuators at 120° spacing. Swashplate translates vertically
//     to change blade collective pitch. Stroke: 10 mm covers full
//     pitch range for the PCA-2 operating envelope.

SWASH_OD          = 80.0;   // mm    — swashplate outer diameter
SWASH_ID          = 32.0;   // mm    — clears tube + generator
SWASH_HEIGHT      = 15.0;   // mm    — axial thickness
ACTUATOR_WIDTH    = 14.0;   // mm    — linear servo body width
ACTUATOR_DEPTH    = 14.0;   // mm    — linear servo body depth
ACTUATOR_HEIGHT   = 40.0;   // mm    — linear servo body height
ACTUATOR_RADIUS   = 38.0;   // mm    — mounting radius from tube centre
ACTUATOR_STROKE   = 10.0;   // mm    — full travel range

// ═══════════════════════════════════════════════════════════════════
// 12. EMPENNAGE  (tail boom + H-stab + V-fin, downwind, below line)
// ═══════════════════════════════════════════════════════════════════
//     Primary role: torque reaction for generator (not pitch trim —
//     that's handled by swashplate). H-stab provides pitch damping;
//     V-fin provides passive weathervane yaw alignment.
//     Boom droops ~15° below horizontal to stay in clean inflow.

TAIL_BOOM_LENGTH  = 1800.0; // mm    — lever arm from tube to tail
TAIL_BOOM_DIA     = 16.0;   // mm    — boom tube diameter
TAIL_DROOP        = 15.0;   // deg   — downward angle from horizontal
HSTAB_SPAN        = 600.0;  // mm    — horizontal stabiliser span
HSTAB_CHORD       = 150.0;  // mm    — horizontal stabiliser chord
VFIN_HEIGHT       = 400.0;  // mm    — vertical fin height (below boom)
VFIN_CHORD        = 150.0;  // mm    — vertical fin chord

// ═══════════════════════════════════════════════════════════════════
// 13. DISPLAY SCALING
// ═══════════════════════════════════════════════════════════════════
//     All dimensions in mm. OpenSCAD renders at 1 unit = 1 mm.
//     VISUAL_SCALE = 0.3 compresses the model for on-screen viewing
//     while keeping dimensions legible.

VISUAL_SCALE      = 0.3;    // mm → OpenSCAD units (cosmetic only)
