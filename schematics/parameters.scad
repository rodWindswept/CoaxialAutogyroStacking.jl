// Coaxial Autogyro Stacking — Shared Parameters
// ============================================================
// AUTO-GENERATED from Julia model on 2026-07-03T11:27:46.030
// Source: schematics/generate_params.jl
// Regenerate: julia --project=. schematics/generate_params.jl
// ============================================================

// --- Operating conditions ---
WIND_SPEED        = 8.0;    // m/s
AIR_DENSITY       = 1.225;  // kg/m³
LINE_ELEVATION    = 55.0;   // degrees
EFFECTIVE_ALPHA   = 45.0;   // degrees (= 90 − elev + tilt)

// --- Rotor geometry ---
ROTOR_RADIUS      = 3000.0; // mm (3.0 m)
HUB_RADIUS        = 50.0;   // mm
N_BLADES          = 2;
BLADE_CHORD       = 150.0;  // mm
BLADE_THICKNESS   = 30.0;   // mm (visual only)
TILT_ANGLE        = 10.0;   // degrees (machined bearing face)
BLADE_PITCH       = 0.0;    // degrees (not modelled in v1)
ROTOR_MASS        = 5.0;    // kg
ROTOR_SOLIDITY    = 0.0318; // σ = n_blades × chord / (π × R)

// --- Aerodynamic forces (from rotor_force_along_line) ---
CL_OPERATING      = 0.9;
CD_OPERATING      = 0.75;
F_LIFT            = 997.0;    // N
F_DRAG            = 831.0;    // N
F_LINE            = 1294.0;    // N — along-line
ANCHOR_TENSION    = 5065.0;    // N — 4-rotor stack at 8.0 m/s

// --- Autorotation ---
ROTOR_RPM         = 45.0;     // estimated (λ=2.5)
TIP_SPEED         = 14.1;    // m/s
OMEGA             = 4.71;   // rad/s

// --- Gyroscopic precession ---
GYRO_MOMENT       = 10.6;     // N·m (I·Ω·ω_prec)

// --- Centrifugal blade load ---
CENTRIFUGAL_FORCE = 70.0;    // N per blade (estimated)

// --- Line ---
LINE_DIAMETER     = 4.0;    // mm — Dyneema SK99

// --- Tube (tension tie-rod, carbon fibre) ---
// 25×15mm, 5mm wall — SF=146× in tension at 1,294 N
TUBE_OD           = 25.0;   // mm
TUBE_ID           = 15.0;   // mm
TUBE_LENGTH       = 800.0;  // mm
TUBE_WALL         = 5.0;    // mm
TIE_HOLE_DIA      = 5.0;    // mm — Dyneema stitching cord (3mm)
TIE_ROPE_DIA      = 3.0;    // mm

// --- Hub (aluminium) ---
HUB_OD            = 80.0;   // mm
HUB_ID            = 27.0;   // mm — clears 25mm tube
HUB_HEIGHT        = 60.0;   // mm — between bearing faces

// --- Bearings (SKF 51105 thrust ball) ---
// ID=25mm, OD=42mm, H=11mm, C_dyn=15.9kN, limiting=6,300rpm
// Load: 997N → 16× capacity margin, 45rpm → 140× speed margin
BEARING_OD        = 42.0;   // mm — SKF 51105
BEARING_ID        = 25.0;   // mm — slip fit over tube
BEARING_HEIGHT    = 11.0;   // mm

// --- Moldings (aluminium 6061-T6) ---
MOLDING_OD        = 70.0;   // mm
MOLDING_ID        = 25.5;   // mm — slip fit over tube
MOLDING_HEIGHT    = 20.0;   // mm

// --- Generator ---
GEN_RADIUS        = 45.0;   // mm
GEN_WIDTH         = 20.0;   // mm
GEN_HEIGHT        = 15.0;   // mm
GEN_POWER         = 5.0;    // W

// --- Swashplate + actuators ---
SWASH_OD          = 80.0;   // mm
SWASH_ID          = 32.0;   // mm
SWASH_HEIGHT      = 15.0;   // mm
ACTUATOR_WIDTH    = 14.0;   // mm
ACTUATOR_DEPTH    = 14.0;   // mm
ACTUATOR_HEIGHT   = 40.0;   // mm
ACTUATOR_RADIUS   = 38.0;   // mm
ACTUATOR_STROKE   = 10.0;   // mm

// --- Empennage ---
TAIL_BOOM_LENGTH  = 1800.0;  // mm — lever arm for torque reaction
TAIL_BOOM_DIA     = 16.0;   // mm
TAIL_DROOP        = 15.0;   // degrees
HSTAB_SPAN        = 600.0;  // mm
HSTAB_CHORD       = 150.0;  // mm
VFIN_HEIGHT       = 400.0;  // mm
VFIN_CHORD        = 150.0;  // mm

// --- Display ---
VISUAL_SCALE      = 0.3;    // mm → OpenSCAD units
