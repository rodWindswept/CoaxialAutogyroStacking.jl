// Coaxial Autogyro Stack — 4-unit assembly
// ============================================================
// Parameters from Julia model via schematics/generate_params.jl
// Spacing: 15 m between units (per Phase 8 sweep optimum)
// Line elevation: 55° from horizontal
// Topmost rotor (index 1) terminates the line.
// ============================================================

include <parameters.scad>
$fn = 48;  // lower poly count for 4x assembly

function s(x) = x * VISUAL_SCALE;
VS = VISUAL_SCALE;

// Stack geometry
N_ROTORS      = 4;
SPACING       = 15000;  // mm between rotor centers
BOTTOM_EXTRA  = 5000;   // mm below bottom rotor to anchor
LINE_ELEV     = LINE_ELEVATION;  // from parameters.scad

// ============================================================
// SIMPLIFIED ROTOR ASSEMBLY (for stack — lighter than single_unit)
// ============================================================

module rotor_symbol() {
    // Tube
    color("DimGray", 0.6)
        cylinder(h=s(300), r=s(TUBE_OD / 2));
    // Inner bore
    color("DimGray", 0.3)
        cylinder(h=s(300), r=s(TUBE_ID / 2));

    // Rotor disk — tilted forward-down relative to line
    translate([0, 0, s(150)])
    rotate([0, -TILT_ANGLE, 0]) {
        color("FireBrick", 0.2) {
            difference() {
                cylinder(h=s(6), r=s(ROTOR_RADIUS), center=true);
                cylinder(h=s(8), r=s(HUB_OD / 2 + 5), center=true);
            }
        }
        // Blades
        for (i = [0:N_BLADES-1]) {
            rotate([0, 0, i * 360 / N_BLADES])
            color("DarkOliveGreen", 0.8)
                translate([s(HUB_OD / 2 + 5), -s(BLADE_CHORD / 2), -s(BLADE_THICKNESS / 2)])
                    cube([s(ROTOR_RADIUS - HUB_OD / 2 - 5), s(BLADE_CHORD), s(BLADE_THICKNESS)]);
        }
    }

    // Empennage stub
    color("DimGray", 0.5)
        translate([0, 0, s(50)])
            rotate([0, -5, 0])
                rotate([0, 90, 0])
                    cylinder(h=s(TAIL_BOOM_LENGTH * 0.5), r=s(TAIL_BOOM_DIA / 2));
}

// ============================================================
// DYNEMA LINE + STACK
// ============================================================

module dyneema_line() {
    len = BOTTOM_EXTRA + N_ROTORS * SPACING;
    color("RoyalBlue", 0.8)
        cylinder(h=s(len), r=s(LINE_DIAMETER * 2), $fn=16, center=false);
}

module anchor_point() {
    color("SaddleBrown", 0.8)
        translate([0, 0, -s(200)])
            cylinder(h=s(200), r1=s(100), r2=s(50), $fn=16);
    // Ground plane hint
    color("DarkGreen", 0.3)
        translate([-s(ROTOR_RADIUS), -s(ROTOR_RADIUS * 0.5), -s(250)])
            cube([s(ROTOR_RADIUS * 2), s(ROTOR_RADIUS), s(50)]);
}

// ============================================================
// WORLD-SPACE ASSEMBLY
// ============================================================

// Line extends along +Z (vertical in local), then tilted to elevation
rotate([0, 90 - LINE_ELEV, 0]) {
    // Anchor at bottom
    anchor_point();

    // Dyneema line (extends full stack length)
    dyneema_line();

    // Place rotors along the line
    // Rotor index 0 = bottom (closest to anchor)
    // Rotor index 3 = top (terminates the line)
    for (i = [0 : N_ROTORS - 1]) {
        z_pos = (BOTTOM_EXTRA + i * SPACING);
        translate([0, 0, s(z_pos)])
            rotor_symbol();
    }
}

// Wind arrow — horizontal, toward +X
color("LightSkyBlue", 0.8) {
    translate([s(ROTOR_RADIUS * -0.5), s(ROTOR_RADIUS * 0.3), s(BOTTOM_EXTRA + SPACING * 2)])
        rotate([0, -90, 0])
            cylinder(h=s(ROTOR_RADIUS * 2), r=s(20));
    translate([s(ROTOR_RADIUS * 1.3), s(ROTOR_RADIUS * 0.3), s(BOTTOM_EXTRA + SPACING * 2)])
        rotate([0, -90, 0])
            cylinder(h=s(100), r1=s(40), r2=0);
}

// Labels
color("RoyalBlue", 0.9)
    translate([-s(100), s(ROTOR_RADIUS * 0.2), s(BOTTOM_EXTRA + SPACING * 3.5)])
        rotate([90, 0, 0])
            linear_extrude(s(1))
                text(str(N_ROTORS, " rotors, ", SPACING/1000, " m spacing"), size=s(20), halign="center");

color("SaddleBrown", 0.9)
    translate([-s(100), s(100), s(-10)])
        rotate([90, 0, 0])
            linear_extrude(s(1))
                text(str("Anchor (", round(ANCHOR_TENSION), " N)"), size=s(16), halign="center");

color("LightSkyBlue", 0.9)
    translate([s(ROTOR_RADIUS * 0.5), s(ROTOR_RADIUS * 0.35), s(BOTTOM_EXTRA + SPACING * 2.2)])
        rotate([90, 0, 0])
            linear_extrude(s(1))
                text(str("Wind ", WIND_SPEED, " m/s →"), size=s(16), halign="center");
