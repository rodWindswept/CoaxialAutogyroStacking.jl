// Coaxial Autogyro Stack — Parametric 3D Model
// OpenSCAD — renders to STL, PNG (preview mode for colors)
//
// Parameters match the Julia model:
//   AutogyroRotor(radius=1.5, hub_radius=0.1, n_blades=2, blade_chord=0.15,
//                 tilt_deg=10.0, blade_pitch_deg=0.0, mass=5.0)
//   AutogyroStack([r,r,r], fill(10.0, 4), line_diameter=0.004, line_angle_deg=50.0)

// ============================================================
// PARAMETERS — edit these to match your Julia model
// ============================================================

// Rotor geometry
ROTOR_RADIUS       = 1.5;    // m — disk radius
HUB_RADIUS         = 0.1;    // m — central hub
N_BLADES           = 2;      // number of blades
BLADE_CHORD        = 0.15;   // m — mean chord width
BLADE_THICKNESS    = 0.03;   // m — visual blade thickness

// Stack geometry
N_ROTORS           = 3;      // number of rotors in stack
SECTION_LENGTH     = 10.0;   // m — spacing between rotors
BOTTOM_EXTRA       = 3.0;    // m — line below bottom rotor to anchor
LINE_DIAMETER      = 0.004;  // m — Dyneema line
LINE_ANGLE         = 50.0;   // degrees — line elevation from horizontal

// Disk tilt (pitch relative to perpendicular-to-line)
TILT_ANGLE         = 10.0;   // degrees — forward-down into wind

// Hub / mechanical detail
HUB_HEIGHT         = 0.12;   // m — thickness of hub along line
BEARING_DIAMETER   = 0.14;   // m — thrust bearing diameter
TAIL_BOOM_LENGTH   = 0.8;    // m — empennage boom
TAIL_SPAN          = 0.4;    // m — horizontal stabilizer half-span
TAIL_CHORD         = 0.12;   // m — stabilizer chord

// Visual scaling for display
VISUAL_SCALE       = 10.0;   // scale factor: model units → display units
LINE_DIA_SCALE     = 100.0;  // visual exaggeration for 4mm line

// ============================================================
// DERIVED VALUES
// ============================================================

TOTAL_LINE_LENGTH = N_ROTORS * SECTION_LENGTH + BOTTOM_EXTRA;
VIS_LINE_DIA = max(LINE_DIAMETER * LINE_DIA_SCALE * VISUAL_SCALE, 1.0);
DEG = 3.14159265359 / 180;  // degrees to radians

// ============================================================
// MODULES
// ============================================================

// A single rotor blade
module blade(length, chord, thickness) {
    translate([0, -chord/2, -thickness/2])
        cube([length, chord, thickness]);
}

// Rotor swept disk (annulus) — thicker for visibility
module swept_disk() {
    $fn = 64;
    vs = VISUAL_SCALE;
    color([0.72, 0.13, 0.13], 0.55) {
        difference() {
            cylinder(h=0.15 * vs, r=ROTOR_RADIUS * vs, center=true);
            cylinder(h=0.20 * vs, r=HUB_RADIUS * vs, center=true);
        }
    }
}

// Hub and bearing assembly
module hub_assembly() {
    $fn = 64;
    vs = VISUAL_SCALE;

    // Main hub body
    color("DimGray", 0.85)
        cylinder(h=HUB_HEIGHT * vs, r=HUB_RADIUS * vs, center=true);

    // Thrust bearing — metallic ring
    color("Silver", 0.9) {
        difference() {
            cylinder(h=0.06 * vs, r=BEARING_DIAMETER/2 * vs, center=true);
            cylinder(h=0.08 * vs, r=HUB_RADIUS * vs, center=true);
        }
    }

    // Bearing balls (decorative)
    for (i = [0:7]) {
        angle = i * 45;
        r = (HUB_RADIUS + BEARING_DIAMETER/2) / 2 * vs;
        color("Gold", 0.8)
            translate([r * cos(angle), r * sin(angle), 0])
                sphere(r=0.03 * vs, $fn=8);
    }
}

// Blades
module blades() {
    vs = VISUAL_SCALE;
    for (i = [0 : N_BLADES-1]) {
        angle = i * 360 / N_BLADES;
        rotate([0, 0, angle]) {
            color("DarkSlateGray", 0.75)
                blade(ROTOR_RADIUS * vs - HUB_RADIUS * vs,
                      BLADE_CHORD * vs,
                      BLADE_THICKNESS * vs);
        }
    }
}

// Empennage: boom + horizontal stabilizer
module empennage() {
    $fn = 32;
    vs = VISUAL_SCALE;

    // Boom
    color("DimGray", 0.6) {
        rotate([0, 90, 0])
            cylinder(h=TAIL_BOOM_LENGTH * vs, r=0.04 * vs);
    }

    // Stabilizer
    st = TAIL_BOOM_LENGTH * vs * 0.85;
    translate([st, 0, 0]) {
        color("DarkSlateGray", 0.6)
            cube([TAIL_CHORD * vs, TAIL_SPAN * 2 * vs, 0.03 * vs], center=true);
    }

    // Vertical fin
    translate([st, 0, 0.15 * vs]) {
        color("DarkSlateGray", 0.5)
            cube([TAIL_CHORD * vs, 0.02 * vs, 0.25 * vs], center=true);
    }
}

// Full rotor assembly: disk + hub + blades + empennage
module rotor_assembly() {
    // Tilt: leading edge forward-down into the wind
    // Disk plane perpendicular to line = YZ plane
    // TILT_ANGLE rotates the top of the disk forward (around Y axis)
    rotate([0, TILT_ANGLE, 0]) {
        swept_disk();
        hub_assembly();
        blades();
        // Empennage extends downwind from below hub
        translate([0, 0, -HUB_HEIGHT * VISUAL_SCALE / 2])
            empennage();
    }
}

// ============================================================
// SCENE: World-space assembly
// ============================================================

// Tension line: runs along +Z, then tilted to LINE_ANGLE from horizontal
module tension_line() {
    color("RoyalBlue", 0.75)
        cylinder(h=TOTAL_LINE_LENGTH * VISUAL_SCALE, r=VIS_LINE_DIA/2, center=false, $fn=16);
}

// Ground plane
module ground_plane() {
    hw = TOTAL_LINE_LENGTH * VISUAL_SCALE * 0.8;  // wide enough
    color("ForestGreen", 0.4)
        translate([-hw, -0.1, -hw * 0.3])
            cube([2*hw, 0.2, hw * 0.6]);
}

// Anchor base
module anchor_base() {
    color("SaddleBrown", 0.8)
        cylinder(h=1.5 * VISUAL_SCALE, r1=0.5 * VISUAL_SCALE, r2=0.3 * VISUAL_SCALE, $fn=16);
}

// Free-end marker
module free_end() {
    color("Gray", 0.5)
        sphere(r=0.15 * VISUAL_SCALE, $fn=16);
}

// Wind arrow (horizontal, points right)
module wind_arrow() {
    vs = VISUAL_SCALE;
    color("DeepSkyBlue", 0.8) {
        // Shaft
        translate([0, 0, -1.5 * vs])
            cylinder(h=3.0 * vs, r=0.1 * vs, $fn=12);
        // Arrowhead
        translate([0, 0, 1.5 * vs])
            cylinder(h=0.6 * vs, r1=0.35 * vs, r2=0, $fn=12);
    }
}

// ============================================================
// MAIN SCENE
// ============================================================

// The line is built along +Z (vertical).
// We rotate around Y to tilt it to LINE_ANGLE from horizontal:
//   LINE_ANGLE = 50° means 50° up from horizontal
//   Vertical = 90° from horizontal → need rotation of -(90-50) = -40° around Y
//   This tilts +Z toward +X

rotate([0, -(90 - LINE_ANGLE), 0]) {

    // Ground plane at anchor level
    translate([0, 0, -2.5 * VISUAL_SCALE])
        ground_plane();

    // Anchor post
    translate([0, 0, 0])
        anchor_base();

    // Tension line
    tension_line();

    // Place rotors: bottom rotor first (closest to anchor)
    // Place rotors along the line
    // Rotor index 0 = bottom rotor (closest to anchor)
    for (i = [0 : N_ROTORS-1]) {
        z_pos = (BOTTOM_EXTRA + i * SECTION_LENGTH + SECTION_LENGTH/2) * VISUAL_SCALE;
        translate([0, 0, z_pos])
            rotor_assembly();
    }
}

// Wind arrow in world space: blows horizontally from left, positioned mid-height
arrow_y = (TOTAL_LINE_LENGTH * VISUAL_SCALE) * sin(LINE_ANGLE * DEG) * 0.55;
arrow_x = -ROTOR_RADIUS * VISUAL_SCALE * 1.8;
translate([arrow_x, 0, arrow_y])
    rotate([0, 90, 0])
        wind_arrow();

// ============================================================
// RENDER INSTRUCTIONS
// ============================================================
//
// GUI preview:
//   openscad autogyro_stack.scad
//
// PNG (preview mode preserves colors):
//   openscad --preview -o autogyro_stack.png --imgsize=1920,1080 \
//     --autocenter --viewall --colorscheme=Cornfield \
//     --projection=ortho autogyro_stack.scad
//
// STL (full geometry, monochrome):
//   openscad --render -o autogyro_stack.stl autogyro_stack.scad
