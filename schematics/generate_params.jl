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
// Coaxial Autogyro Stacking — Shared Parameters
// ============================================================
// AUTO-GENERATED from Julia model on $(Dates.now())
// Source: schematics/generate_params.jl
// Regenerate: julia --project=. schematics/generate_params.jl
// ============================================================

// --- Operating conditions ---
WIND_SPEED        = $(round(v_wind, digits=1));    // m/s
AIR_DENSITY       = $(rho);  // kg/m³
LINE_ELEVATION    = $(elev);   // degrees
EFFECTIVE_ALPHA   = $(round(α_eff, digits=1));   // degrees (= 90 − elev + tilt)

// --- Rotor geometry ---
ROTOR_RADIUS      = $(R * 1000); // mm ($(R) m)
HUB_RADIUS        = $(hub_r * 1000);   // mm
N_BLADES          = $n_bl;
BLADE_CHORD       = $(chord * 1000);  // mm
BLADE_THICKNESS   = 30.0;   // mm (visual only)
TILT_ANGLE        = $(tilt);   // degrees (machined bearing face)
BLADE_PITCH       = 0.0;    // degrees (not modelled in v1)
ROTOR_MASS        = $(mass);    // kg
ROTOR_SOLIDITY    = $(round(σ, digits=4)); // σ = n_blades × chord / (π × R)

// --- Aerodynamic forces (from rotor_force_along_line) ---
CL_OPERATING      = $(round(cl, digits=2));
CD_OPERATING      = $(round(cd, digits=2));
F_LIFT            = $(round(F_lift, digits=0));    // N
F_DRAG            = $(round(F_drag, digits=0));    // N
F_LINE            = $(round(F_line, digits=0));    // N — along-line
ANCHOR_TENSION    = $(round(T_anchor, digits=0));    // N — $(n_rotors)-rotor stack at $(v_wind) m/s

// --- Autorotation ---
ROTOR_RPM         = $(round(rpm, digits=1));     // estimated (λ=2.5)
TIP_SPEED         = $(round(tip_speed, digits=1));    // m/s
OMEGA             = $(round(Ω, digits=2));   // rad/s

// --- Gyroscopic precession ---
GYRO_MOMENT       = $(round(M_gyro, digits=1));     // N·m (I·Ω·ω_prec)

// --- Centrifugal blade load ---
CENTRIFUGAL_FORCE = $(round(F_cf, digits=0));    // N per blade (estimated)

// --- Line ---
LINE_DIAMETER     = $(line_d * 1000);    // mm — Dyneema SK99

// --- Tube (tension tie-rod) ---
TUBE_OD           = 30.0;   // mm
TUBE_ID           = 16.0;   // mm
TUBE_LENGTH       = 800.0;  // mm
TUBE_WALL         = 7.0;    // mm
TIE_HOLE_DIA      = 5.0;    // mm
TIE_ROPE_DIA      = 3.0;    // mm

// --- Hub ---
HUB_OD            = 100.0;  // mm
HUB_ID            = 32.0;   // mm
HUB_HEIGHT        = 70.0;   // mm — between bearing faces

// --- Bearings ---
MOLDING_OD        = 80.0;   // mm
MOLDING_ID        = 30.5;   // mm
MOLDING_HEIGHT    = 25.0;   // mm
BEARING_OD        = 70.0;   // mm
BEARING_ID        = 32.0;   // mm
BEARING_HEIGHT    = 8.0;    // mm

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
""")
end

println("Generated schematics/parameters.scad")
println("  Rotor: R=$(R)m, σ=$(round(σ, digits=4)), $(n_bl) blades")
println("  Forces: F_line=$(round(F_line, digits=0)) N, F_lift=$(round(F_lift, digits=0)) N, F_drag=$(round(F_drag, digits=0)) N")
println("  Autorotation: $(round(rpm, digits=1)) RPM, tip=$(round(tip_speed, digits=1)) m/s")
println("  Anchor tension ($(n_rotors)-rotor stack): $(round(T_anchor, digits=0)) N")
println("  Gyro moment: $(round(M_gyro, digits=1)) N·m, centrifugal: $(round(F_cf, digits=0)) N")
