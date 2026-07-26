#!/usr/bin/env julia
# generate_params.jl — Export CoaxialAutogyroStacking model parameters to OpenSCAD
#
# Usage:
#   julia --project=. schematics/generate_params.jl
#
# Reads the Julia model, computes forces and RPM for the best sweep configuration,
# and writes schematics/parameters.scad with current values.
#
# This keeps the OpenSCAD geometry in sync with the physics model — change the
# Julia model, regenerate the SCAD parameters, re-render.

using CoaxialAutogyroStacking
using Dates

# Best configuration from Phase 8 sweep
R       = 3.0     # m
hub_r   = 0.05    # m
n_bl    = 2
chord   = 0.15    # m
tilt    = 10.0    # degrees
mass    = 5.0     # kg
spacing = 15.0    # m
n_rotors = 4
line_d  = 0.004   # m
elev    = 55.0    # degrees
rho     = 1.225   # kg/m³
v_wind  = 8.0     # m/s

# Build the rotor
rotor = AutogyroRotor(R, hub_r, n_bl, chord, tilt, 0.0, mass)

# Compute forces
α_eff = effective_alpha(rotor, elev)
F_line, F_lift, F_drag, cl, cd = rotor_force_along_line(rotor, rho, v_wind, elev)
A_disk = rotor_disk_area(rotor)
σ = rotor_solidity(rotor)
rpm = estimated_autorotation_rpm(rotor, v_wind, α_eff)
Ω = rpm * 2π / 60
tip_speed = Ω * R

# Build stack and compute anchor tension
rotors = [AutogyroRotor(R, hub_r, n_bl, chord, tilt, 0.0, mass) for _ in 1:n_rotors]
stack = AutogyroStack(rotors, fill(spacing, n_rotors), line_d, elev)
profile = stack_tension_profile(stack, rho, v_wind)
T_anchor = profile[end]

# Gyroscopic moment estimate
# I ≈ ½·m·R² for disk (rough), ω_precession ~ 0.1 rad/s for line angle changes
I_disk = 0.5 * mass * R^2
ω_prec = 0.1  # rad/s — typical line angle change rate in gust
M_gyro = I_disk * Ω * ω_prec

# Centrifugal force per blade (rough: blade mass ~1.5 kg at R_cg ~1.5 m)
m_blade_est = 1.5  # kg
R_cg = R * 0.7
F_cf = m_blade_est * Ω^2 * R_cg

open("schematics/parameters.scad", "w") do io
    write(io, """
// ╔══════════════════════════════════════════════════════════════════╗
// ║  COAXIAL AUTOGYRO STACKING — Shared Parameters                   ║
// ║  AUTO-GENERATED from Julia model on $(Dates.now())  ║
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
//   │  Line elevation: $(elev)° from horizontal             │
//   └─────────────────────────────────────────────────┘
//
// ═══════════════════════════════════════════════════════════════════
//  1. OPERATING CONDITIONS
// ═══════════════════════════════════════════════════════════════════
//     Best configuration from Phase 8 PCA-2 sweep (R=$(R) m, N=$(n_rotors)):
//       Anchor tension: $(round(T_anchor, digits=0)) N at $(v_wind) m/s (lifts ~$(round(T_anchor/9.81, digits=0)) kg)
//       N/kg efficiency: $(round(T_anchor/(n_rotors*mass), digits=0)) N/kg
//       Tension CV (gust stability): 0.72

WIND_SPEED        = $(round(v_wind, digits=1));    // m/s   — freestream wind at hub height
AIR_DENSITY       = $(rho);  // kg/m³ — ISA sea-level standard
LINE_ELEVATION    = $(elev);   // deg   — line angle above horizontal
EFFECTIVE_ALPHA   = $(round(α_eff, digits=1));   // deg   — α_eff = 90° − elevation + tilt

// ═══════════════════════════════════════════════════════════════════
//  2. ROTOR GEOMETRY  ($(R) m radius, $(n_bl) blades, PCA-2 disk model)
// ═══════════════════════════════════════════════════════════════════

ROTOR_RADIUS      = $(R * 1000); // mm    — blade tip to hub centre
HUB_RADIUS        = $(hub_r * 1000);   // mm    — central bore radius
N_BLADES          = $n_bl;      // count — two-bladed teetering rotor
BLADE_CHORD       = $(chord * 1000);  // mm    — blade width (NACA 0012 section)
BLADE_THICKNESS   = 30.0;   // mm    — visual thickness (cosmetic)
TILT_ANGLE        = $(tilt);   // deg   — disk forward tilt (machined into bearing face)
BLADE_PITCH       = 0.0;    // deg   — collective pitch offset (v2+ only)
ROTOR_MASS        = $(mass);    // kg    — per rotor (blades + hub + bearings)
ROTOR_SOLIDITY    = $(round(σ, digits=4)); // —     — σ = N_blades × chord / (π × R)

// ═══════════════════════════════════════════════════════════════════
//  3. AERODYNAMIC FORCES  (computed by rotor_force_along_line)
// ═══════════════════════════════════════════════════════════════════

CL_OPERATING      = $(round(cl, digits=2));    // —     — lift coefficient at α_eff=$(round(α_eff, digits=1))° (PCA-2 table)
CD_OPERATING      = $(round(cd, digits=2));   // —     — drag coefficient at α_eff=$(round(α_eff, digits=1))°
F_LIFT            = $(round(F_lift, digits=0));  // N     — lift ⊥ wind, per rotor
F_DRAG            = $(round(F_drag, digits=0));  // N     — drag ∥ wind, per rotor
F_LINE            = $(round(F_line, digits=0)); // N     — force projected along Dyneema line
ANCHOR_TENSION    = $(round(T_anchor, digits=0)); // N     — cumulative tension at anchor ($(n_rotors)-rotor stack, $(v_wind) m/s)

// ═══════════════════════════════════════════════════════════════════
//  4. AUTOROTATION  (estimated from tip-speed ratio λ ≈ 2.5)
// ═══════════════════════════════════════════════════════════════════

ROTOR_RPM         = $(round(rpm, digits=1));   // rpm   — steady-state autorotation speed
TIP_SPEED         = $(round(tip_speed, digits=1));   // m/s   — Ω × R (well below 120 m/s noise limit)
OMEGA             = $(round(Ω, digits=2));   // rad/s — angular velocity
GYRO_MOMENT       = $(round(M_gyro, digits=1));     // N·m   — gyroscopic precession torque (I·Ω·ω_prec)
CENTRIFUGAL_FORCE = $(round(F_cf, digits=0));    // N     — per-blade centrifugal load at 70% radius

// ═══════════════════════════════════════════════════════════════════
//  5. LINE  (Dyneema SK99, $(line_d * 1000) mm)
// ═══════════════════════════════════════════════════════════════════

LINE_DIAMETER     = $(line_d * 1000);    // mm    — Dyneema SK99 (breaking strength ~13 kN)

// ═══════════════════════════════════════════════════════════════════
//  6. TUBE  (carbon fibre tension tie-rod, 25×15 mm, 5 mm wall)
// ═══════════════════════════════════════════════════════════════════
//     Safety factor: 146× in tension at $(round(F_line, digits=0)) N (compressive column).
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
//     At $(round(F_lift, digits=0)) N lift: 16× capacity margin.
//     At $(round(rpm, digits=1)) rpm: 140× speed margin (limiting speed = 6,300 rpm).

BEARING_OD        = 42.0;   // mm    — SKF 51105 outer diameter
BEARING_ID        = 25.0;   // mm    — slip fit over 25 mm tube
BEARING_HEIGHT    = 11.0;   // mm    — axial thickness

// ═══════════════════════════════════════════════════════════════════
//  9. MOLDINGS  (aluminium 6061-T6 — clamp bearings to tube)
// ═══════════════════════════════════════════════════════════════════
//     Underside of top molding and topside of bottom molding are
//     machined at disk tilt angle δ ($(tilt)°). This sets the rotor disk
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
""")
end

println("Generated schematics/parameters.scad")
println("  Rotor: R=$(R)m, σ=$(round(σ, digits=4)), $(n_bl) blades")
println("  Forces: F_line=$(round(F_line, digits=0)) N, F_lift=$(round(F_lift, digits=0)) N, F_drag=$(round(F_drag, digits=0)) N")
println("  Autorotation: $(round(rpm, digits=1)) RPM, tip=$(round(tip_speed, digits=1)) m/s")
println("  Anchor tension ($(n_rotors)-rotor stack): $(round(T_anchor, digits=0)) N")
println("  Gyro moment: $(round(M_gyro, digits=1)) N·m, centrifugal: $(round(F_cf, digits=0)) N")
