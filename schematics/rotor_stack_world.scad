// Inline Autogyro Stack — World-Oriented 3-Rotor Assembly
// OpenSCAD — ground plane, wind direction, line elevation, disk tilt
//
// Coordinate system:
//   Ground plane: XZ (Y = 0)
//   Wind: +X direction (along ground)
//   Dyneema line: elevation angle from horizontal, in XY plane
//   Rotor disk: tilted forward-down into wind relative to perpendicular-to-line

// ============================================================
// WORLD PARAMETERS
// ============================================================
WIND_SPEED         = 8.0;    // m/s — freestream
LINE_ELEVATION     = 65.0;   // degrees — line angle above horizontal
TILT_ANGLE         = 12.0;   // degrees — disk tilt forward-down into wind
N_ROTORS           = 3;      // number of rotors in stack
ROTOR_SPACING      = 10.0;   // m — between rotors along line
BOTTOM_SECTION     = 5.0;    // m — bottom rotor to anchor

// ============================================================
// ROTOR GEOMETRY (same as Julia model)
// ============================================================
ROTOR_RADIUS       = 1.5;    // m
HUB_RADIUS         = 0.1;    // m
N_BLADES           = 2;
BLADE_CHORD        = 0.15;   // m
BLADE_THICKNESS    = 0.03;   // m
ROTOR_MASS         = 5.0;    // kg

// ============================================================
// TUBE & MECHANICAL (scaled from mm to m for consistency)
// ============================================================
TUBE_OD            = 0.025;  // m (25 mm)
TUBE_ID            = 0.020;  // m
TUBE_LENGTH        = 0.6;    // m — between bearings
LINE_DIAMETER      = 0.004;  // m (4 mm Dyneema)

MOLDING_OD         = 0.065;  // m
MOLDING_HEIGHT     = 0.030;  // m
BEARING_HEIGHT     = 0.010;  // m
HUB_OD             = 0.090;  // m
HUB_HEIGHT         = 0.080;  // m

TAIL_BOOM_LENGTH   = 0.6;    // m — downwind from tube
HSTAB_SPAN         = 0.35;   // m
VFIN_HEIGHT        = 0.20;   // m

// ============================================================
// DERIVED
// ============================================================
DEG                = 3.14159265359 / 180;
LINE_ELEV_RAD      = LINE_ELEVATION * DEG;
TILT_RAD           = TILT_ANGLE * DEG;
TOTAL_LINE_LENGTH  = BOTTOM_SECTION + N_ROTORS * ROTOR_SPACING;

// Visual scales (OpenSCAD works in mm, our model is in m)
VS = 1000.0;  // multiply m → mm for display

// ============================================================
// MODULES (all in metres, converted to mm at render time)
// ============================================================
$fn = 48;

module dyneema_line(length) {
    color("RoyalBlue", 0.8)
        cylinder(h=length*VS, r=LINE_DIAMETER*6*VS, center=false, $fn=16);
}

module central_tube() {
    color("DimGray", 0.65) {
        difference() {
            cylinder(h=TUBE_LENGTH*VS, r=TUBE_OD/2*VS, center=false);
            cylinder(h=TUBE_LENGTH*VS+1, r=TUBE_ID/2*VS, center=false);
        }
    }
}

module molding(is_top) {
    ang = TILT_ANGLE;
    color("SaddleBrown", 0.7) {
        difference() {
            cylinder(h=MOLDING_HEIGHT*VS, r=MOLDING_OD/2*VS, center=false);
            cylinder(h=MOLDING_HEIGHT*VS+1, r=TUBE_OD/2*VS+1, center=false);
        }
    }
}

module thrust_bearing() {
    color("Silver", 0.6) {
        difference() {
            cylinder(h=BEARING_HEIGHT*VS, r=MOLDING_OD/2*VS, center=false);
            cylinder(h=BEARING_HEIGHT*VS+1, r=TUBE_OD/2*VS+1, center=false);
        }
    }
}

module rotor_hub() {
    color("DarkSlateGray", 0.55) {
        difference() {
            cylinder(h=HUB_HEIGHT*VS, r=HUB_OD/2*VS, center=false);
            cylinder(h=HUB_HEIGHT*VS+1, r=TUBE_OD/2*VS+1, center=false);
        }
    }
}

module rotor_disk() {
    color("FireBrick", 0.20) {
        difference() {
            cylinder(h=0.02*VS, r=ROTOR_RADIUS*VS, center=true);
            cylinder(h=0.03*VS, r=HUB_OD/2*VS + 5, center=true);
        }
    }
}

module blades() {
    color("DarkSlateGray", 0.65) {
        for (i = [0:N_BLADES-1]) {
            angle = i * 360 / N_BLADES;
            rotate([0, 0, angle])
                translate([HUB_OD/2*VS + 5, -BLADE_CHORD/2*VS, -BLADE_THICKNESS/2*VS])
                    cube([ROTOR_RADIUS*VS - HUB_OD/2*VS - 5, BLADE_CHORD*VS, BLADE_THICKNESS*VS]);
        }
    }
}

module swashplate() {
    color("DarkCyan", 0.5) {
        difference() {
            cylinder(h=0.02*VS, r=MOLDING_OD/2*VS + 5, center=false);
            cylinder(h=0.03*VS, r=TUBE_OD/2*VS + 1, center=false);
        }
    }
}

module actuators() {
    for (i = [0:2]) {
        angle = i * 120;
        r = TUBE_OD*VS + 15;
        color("DimGray", 0.6)
            translate([r*cos(angle), r*sin(angle), 0])
                cube([8, 8, 40], center=true);
    }
}

module empennage() {
    // Entire empennage hangs below the line — rotated down 15° from horizontal
    rotate([0, 15, 0]) {
        // Tail boom
        color("DimGray", 0.5)
            rotate([0, 90, 0])
                cylinder(h=TAIL_BOOM_LENGTH*VS, r=5, center=false);
        // H-stab
        color("DarkSlateGray", 0.5)
            translate([TAIL_BOOM_LENGTH*VS - 50, -HSTAB_SPAN/2*VS, -2])
                cube([60, HSTAB_SPAN*VS, 4]);
        // V-fin (hangs below boom)
        color("DarkSlateGray", 0.45)
            translate([TAIL_BOOM_LENGTH*VS - 50, -2, -VFIN_HEIGHT*VS])
                cube([50, 3, VFIN_HEIGHT*VS]);
    }
}

module webbing() {
    color("Orange", 0.75) {
        for (a = [0, 180]) {
            rotate([0, 0, a])
                translate([TUBE_OD/2*VS, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h=15, r=4, center=true);
        }
    }
}

// ============================================================
// SINGLE ROTOR ASSEMBLY (along +Z in local space)
// ============================================================
module single_rotor_assembly() {
    // Tube
    central_tube();

    // Webbing at bottom of tube
    webbing();

    // Empennage at bottom
    translate([0, 0, 80])
        empennage();

    // Actuators
    translate([0, 0, TUBE_LENGTH*VS*0.45])
        actuators();

    // Swashplate
    translate([0, 0, TUBE_LENGTH*VS*0.55])
        swashplate();

    // Bottom molding + bearing
    z_bot_mold = TUBE_LENGTH*VS*0.65;
    translate([0, 0, z_bot_mold])
        molding(is_top=false);
    translate([0, 0, z_bot_mold + MOLDING_HEIGHT*VS])
        thrust_bearing();

    // Hub
    z_hub = z_bot_mold + MOLDING_HEIGHT*VS + BEARING_HEIGHT*VS;
    translate([0, 0, z_hub])
        rotor_hub();

    // Rotor disk + blades (tilted: leading edge forward-down into wind)
    // Tilt axis = tube-local Y = world vertical
    z_disk = z_hub + HUB_HEIGHT*VS/2;
    translate([0, 0, z_disk])
        rotate([0, TILT_ANGLE, 0]) {
            rotor_disk();
            blades();
        }

    // Top bearing + molding
    z_top = z_hub + HUB_HEIGHT*VS;
    translate([0, 0, z_top])
        thrust_bearing();
    translate([0, 0, z_top + BEARING_HEIGHT*VS])
        molding(is_top=true);
}

// ============================================================
// WORLD SCENE
// ============================================================

// Ground plane — large disc at Y=0, obviously horizontal from any angle
color("ForestGreen", 0.30) {
    hw = TOTAL_LINE_LENGTH * VS * 1.2;
    translate([0, 0, -hw*0.15])
        cylinder(h=hw*0.3, r=hw*0.6, center=false, $fn=64);
}

// Anchor post
color("SaddleBrown", 0.8)
    translate([0, 0, 0])
        cylinder(h=0.3*VS, r1=0.2*VS, r2=0.1*VS, $fn=16);

// === THE STACK: line at LINE_ELEVATION from horizontal ===
// Line runs along +Z in local space, then tilted to elevation angle
// Rotate around Y axis: -(90 - elevation) tilts Z toward X

rotate([0, -(90 - LINE_ELEVATION), 0]) {

    // Dyneema line
    dyneema_line(TOTAL_LINE_LENGTH);

    // Place rotors along the line
    // Rotor 1 (top) at BOTTOM_SECTION + (N-1)*SPACING up from anchor
    for (i = [0 : N_ROTORS-1]) {
        z_pos = (BOTTOM_SECTION + (N_ROTORS - 1 - i) * ROTOR_SPACING) * VS;
        translate([0, 0, z_pos])
            single_rotor_assembly();
    }
}

// Wind arrow (world space, blows along +X)
w_y = TOTAL_LINE_LENGTH * VS * sin(LINE_ELEV_RAD) * 0.55;
color("DeepSkyBlue", 0.85)
    translate([1*VS, w_y, -2*VS])
        rotate([0, 90, 0]) {
            cylinder(h=5*VS, r=0.15*VS, $fn=16);
            translate([0, 0, 5*VS])
                cylinder(h=1.0*VS, r1=0.5*VS, r2=0, $fn=16);
        }

// ============================================================
// RENDER INSTRUCTIONS
// ============================================================
//
// Preview:
//   openscad rotor_stack_world.scad
//
// PNG:
//   openscad --preview -o rotor_stack_world.png --imgsize=1920,1080 \
//     --autocenter --viewall --projection=perspective rotor_stack_world.scad
//
// STL:
//   openscad --render -o rotor_stack_world.stl rotor_stack_world.scad
