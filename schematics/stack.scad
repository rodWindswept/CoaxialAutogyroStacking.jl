// ╔══════════════════════════════════════════════════════════════════╗
// ║  COAXIAL AUTOGYRO STACK — 4-unit assembly (world space)          ║
// ║  Parameters from Julia model via schematics/generate_params.jl    ║
// ╚══════════════════════════════════════════════════════════════════╝
//
// LAYOUT (side view, world frame):
//
//                     Wind → (blows into page / +X)
//
//     ROTOR 4 (top)   ── terminates the Dyneema line
//          │               T = 0 N (nothing pulls from above)
//          │  15 m spacing
//     ROTOR 3          ── mid-stack
//          │  15 m
//     ROTOR 2          ── mid-stack
//          │  15 m
//     ROTOR 1 (bottom) ── closest to anchor
//          │   5 m extra
//     ANCHOR           ── T = ~5,065 N (delivered to kite turbine hub)
//     ──────────────── ground
//
// Line elevation: 55° from horizontal.
// Rotors indexed top→bottom (index 1 = topmost in code, reversed here
// for visual placement — bottom rotor is first along Z from anchor).
//
// OPERATING POINT (from Phase 8 PCA-2 sweep — best config):
//   Radius: 3.0 m   |  Stack: 4 rotors   |  Spacing: 15 m
//   Wind: 8 m/s      |  Elevation: 55°    |  Profile: uniform
//   Anchor tension: ~5,065 N   |  N/kg: 271   |  CV: 0.72
//   Tip speed: 14.1 m/s  |  RPM: 45   |  Re: ~3×10⁶
//
// ================================================================

include <parameters.scad>
$fn = 48;  // lower poly count for 4× assembly (faster render)

function s(x) = x * VISUAL_SCALE;
VS = VISUAL_SCALE;

// ── Stack geometry ──

N_ROTORS      = 4;        // number of autogyro units
SPACING       = 15000;    // mm — between rotor centres (15 m, from sweep optimum)
BOTTOM_EXTRA  = 5000;     // mm — line below bottom rotor to anchor (5 m)
LINE_ELEV     = LINE_ELEVATION;  // deg — from parameters.scad (55°)

// ================================================================
// SIMPLIFIED ROTOR SYMBOL  (lighter than single_unit for stack view)
// ================================================================

module rotor_symbol() {
    // ── Central tube (carbon fibre, 25 mm OD, hollow) ──
    color("DimGray", 0.6)
        cylinder(h=s(300), r=s(TUBE_OD / 2));

    // ── Inner bore (Dyneema channel) ──
    color("DimGray", 0.3)
        cylinder(h=s(300), r=s(TUBE_ID / 2));

    // ── Rotor disk — tilted forward-down (δ = 10°) relative to line ──
    //     The tilt is machined into the bearing faces (parameters.scad §9).
    //     Disk appears tilted back to oncoming wind (effective AoA = 45°).
    translate([0, 0, s(150)])
    rotate([0, -TILT_ANGLE, 0]) {
        // Swept disk annulus — semi-transparent firebrick
        color("FireBrick", 0.2) {
            difference() {
                cylinder(h=s(6), r=s(ROTOR_RADIUS), center=true);
                cylinder(h=s(8), r=s(HUB_OD / 2 + 5), center=true);
            }
        }
        // ── Two blades (NACA 0012 section, 150 mm chord) ──
        for (i = [0:N_BLADES-1]) {
            rotate([0, 0, i * 360 / N_BLADES])
            color("DarkOliveGreen", 0.8)
                translate([s(HUB_OD / 2 + 5), -s(BLADE_CHORD / 2), -s(BLADE_THICKNESS / 2)])
                    cube([s(ROTOR_RADIUS - HUB_OD / 2 - 5), s(BLADE_CHORD), s(BLADE_THICKNESS)]);
        }
    }

    // ── Empennage stub (tail boom extends downwind, droops 15°) ──
    //     Shown half-length for stack view — full boom in single_unit.scad.
    color("DimGray", 0.5)
        translate([0, 0, s(50)])
            rotate([0, -5, 0])
                rotate([0, 90, 0])
                    cylinder(h=s(TAIL_BOOM_LENGTH * 0.5), r=s(TAIL_BOOM_DIA / 2));
}

// ================================================================
// DYNEMA LINE  (4 mm SK99, runs through all rotors to anchor)
// ================================================================

module dyneema_line() {
    // Total length: anchor extra + all rotor spacings
    len = BOTTOM_EXTRA + N_ROTORS * SPACING;
    color("RoyalBlue", 0.8)
        cylinder(h=s(len), r=s(LINE_DIAMETER * 2), $fn=16, center=false);
        // Diameter exaggerated 2× for visibility in render
}

// ================================================================
// ANCHOR POINT  (ground attachment — delivers ~5 kN to kite turbine)
// ================================================================

module anchor_point() {
    // ── Anchor cone (widens toward ground) ──
    color("SaddleBrown", 0.8)
        translate([0, 0, -s(200)])
            cylinder(h=s(200), r1=s(100), r2=s(50), $fn=16);

    // ── Ground plane hint (green strip) ──
    color("DarkGreen", 0.3)
        translate([-s(ROTOR_RADIUS), -s(ROTOR_RADIUS * 0.5), -s(250)])
            cube([s(ROTOR_RADIUS * 2), s(ROTOR_RADIUS), s(50)]);
}

// ================================================================
// WORLD-SPACE ASSEMBLY
// ================================================================
// The entire stack is built vertically (Z axis), then rotated
// to the operating line elevation angle (55° from horizontal).

rotate([0, 90 - LINE_ELEV, 0]) {
    // ── Anchor at origin (ground level) ──
    anchor_point();

    // ── Dyneema line (full stack height) ──
    dyneema_line();

    // ── Place rotors along the line ──
    //     i=0 = bottom rotor (closest to anchor, highest Z in world frame)
    //     i=3 = top rotor (terminates line, Z=0 tension)
    for (i = [0 : N_ROTORS - 1]) {
        z_pos = (BOTTOM_EXTRA + i * SPACING);
        translate([0, 0, s(z_pos)])
            rotor_symbol();
    }
}

// ================================================================
// WIND INDICATOR  (horizontal arrow, +X direction)
// ================================================================

color("LightSkyBlue", 0.8) {
    // Arrow shaft
    translate([s(ROTOR_RADIUS * -0.5), s(ROTOR_RADIUS * 0.3), s(BOTTOM_EXTRA + SPACING * 2)])
        rotate([0, -90, 0])
            cylinder(h=s(ROTOR_RADIUS * 2), r=s(20));
    // Arrow head
    translate([s(ROTOR_RADIUS * 1.3), s(ROTOR_RADIUS * 0.3), s(BOTTOM_EXTRA + SPACING * 2)])
        rotate([0, -90, 0])
            cylinder(h=s(100), r1=s(40), r2=0);
}

// ================================================================
// LABELS  (3D text rendered at key positions)
// ================================================================

// ── Stack configuration label ──
color("RoyalBlue", 0.9)
    translate([-s(100), s(ROTOR_RADIUS * 0.2), s(BOTTOM_EXTRA + SPACING * 3.5)])
        rotate([90, 0, 0])
            linear_extrude(s(1))
                text(str(N_ROTORS, " rotors, ", SPACING/1000, " m spacing"),
                     size=s(20), halign="center");

// ── Anchor force label ──
color("SaddleBrown", 0.9)
    translate([-s(100), s(100), s(-10)])
        rotate([90, 0, 0])
            linear_extrude(s(1))
                text(str("Anchor (", round(ANCHOR_TENSION), " N)"),
                     size=s(16), halign="center");

// ── Wind speed label ──
color("LightSkyBlue", 0.9)
    translate([s(ROTOR_RADIUS * 0.5), s(ROTOR_RADIUS * 0.35), s(BOTTOM_EXTRA + SPACING * 2.2)])
        rotate([90, 0, 0])
            linear_extrude(s(1))
                text(str("Wind ", WIND_SPEED, " m/s →"),
                     size=s(16), halign="center");

// ── Rotor index labels (1 = bottom, 4 = top) ──
for (i = [0 : N_ROTORS - 1]) {
    z_pos = BOTTOM_EXTRA + i * SPACING;
    color("White", 0.7)
        translate([-s(ROTOR_RADIUS * 0.15), -s(ROTOR_RADIUS * 0.25), s(z_pos)])
            rotate([90, 0, 0])
                linear_extrude(s(1))
                    text(str("R", i+1), size=s(14), halign="center");
}
