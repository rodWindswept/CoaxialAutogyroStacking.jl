// Inline Autogyro Rotor — Full Assembly v2
// Dual-molding sandwich bearing + swashplate + actuators + empennage
// OpenSCAD — renders to STL, PNG
//
// Design: Dyneema line passes through center bore of all components.
// Two moldings clamp the rotor hub via thrust bearings above and below.
// Swashplate, actuators, and empennage mount to tube below rotor.

// ============================================================
// PARAMETERS (realistic sizes for ~1.5m radius rotor, ~300 N lift)
// ============================================================

// --- Dyneema line ---
LINE_DIAMETER      = 4.0;    // mm — Dyneema SK99 (visual scale: 3× for visibility)

// --- Central tube (compression column) ---
TUBE_OD            = 25.0;   // mm — outer diameter
TUBE_ID            = 20.0;   // mm — inner bore (clearance for 4mm line)
TUBE_LENGTH        = 600.0;  // mm — total tube length

// --- Moldings (clamped to tube, machined at tilt angle) ---
MOLDING_OD         = 65.0;   // mm
MOLDING_ID         = 25.5;   // mm — slip fit over tube
MOLDING_HEIGHT     = 30.0;   // mm
TILT_ANGLE         = 12.0;   // degrees — disk tilt

// --- Thrust bearings ---
BEARING_OD         = 55.0;   // mm
BEARING_ID         = 28.0;   // mm — clears tube
BEARING_HEIGHT     = 10.0;   // mm

// --- Rotor hub (between bearings, autorotates) ---
HUB_OD             = 90.0;   // mm — main body
HUB_ID             = 28.0;   // mm — clears tube
HUB_HEIGHT         = 80.0;   // mm — between bearing faces

// --- Rotor disk ---
ROTOR_RADIUS       = 1500.0; // mm
N_BLADES           = 2;
BLADE_CHORD        = 150.0;  // mm
BLADE_THICKNESS    = 25.0;   // mm

// --- Swashplate ---
SWASH_OD           = 75.0;   // mm
SWASH_ID           = 28.0;   // mm
SWASH_HEIGHT       = 18.0;   // mm — total (rotating + stationary rings)

// --- Actuators (3× linear servos, 120° apart) ---
ACTUATOR_WIDTH     = 16.0;   // mm
ACTUATOR_DEPTH     = 16.0;   // mm
ACTUATOR_HEIGHT    = 45.0;   // mm
ACTUATOR_RADIUS    = 35.0;   // mm — mounting radius from tube center
ACTUATOR_STROKE    = 12.0;   // mm — pushrod travel

// --- Empennage ---
TAIL_BOOM_LENGTH   = 600.0;  // mm — from tube to H-stab
TAIL_BOOM_DIA      = 10.0;   // mm
HSTAB_SPAN         = 350.0;  // mm — total horizontal stabilizer span
HSTAB_CHORD        = 100.0;  // mm
HSTAB_THICK        = 4.0;    // mm
VFIN_HEIGHT        = 200.0;  // mm
VFIN_CHORD         = 90.0;   // mm
VFIN_THICK         = 3.0;    // mm

// --- Webbing capture ---
WEBBING_WIDTH      = 8.0;    // mm
WEBBING_SLOT_WIDTH = 9.0;    // mm — tube wall slot
Splice_DIA         = 8.0;    // mm — splice bulge in Dyneema

// --- Axial positions (from tube bottom) ---
POS_SPLICE         = 20.0;   // mm — spliced eye position
POS_EMPENNAGE      = 100.0;  // mm — tail boom attach point
POS_ACTUATORS      = 240.0;  // mm — top of actuator bodies
POS_SWASHPLATE     = 310.0;  // mm — swashplate center
POS_BOTTOM_MOLDING = 370.0;  // mm — bottom molding
POS_BOTTOM_BEARING = 395.0;  // mm — bottom bearing
POS_HUB_BOTTOM     = 405.0;  // mm — hub bottom face
POS_ROTOR_DISK     = 445.0;  // mm — rotor disk center
POS_HUB_TOP        = 485.0;  // mm — hub top face
POS_TOP_BEARING    = 485.0;  // mm — top bearing
POS_TOP_MOLDING    = 500.0;  // mm — top molding

// ============================================================
// MODULES
// ============================================================
$fn = 64;

// --- Dyneema line ---
module dyneema_line() {
    color("RoyalBlue", 0.8)
        cylinder(h=TUBE_LENGTH + 100, r=LINE_DIAMETER*1.5, center=false, $fn=16);
}

// --- Central tube ---
module central_tube() {
    color("DimGray", 0.7) {
        difference() {
            cylinder(h=TUBE_LENGTH, r=TUBE_OD/2, center=false);
            cylinder(h=TUBE_LENGTH + 1, r=TUBE_ID/2, center=false);
        }
    }
    // Webbing slots at bottom (2 opposing slots)
    color("white", 0.0) {  // invisible cutouts — shown by their absence
        for (a = [0, 180]) {
            rotate([0, 0, a])
                translate([TUBE_OD/2 - 1, -WEBBING_SLOT_WIDTH/2, POS_SPLICE - 5])
                    cube([3, WEBBING_SLOT_WIDTH, 15]);
        }
    }
}

// --- Molding (with angled bearing face) ---
module molding(is_top) {
    ang = TILT_ANGLE;
    // Main body
    color("SaddleBrown", 0.75) {
        difference() {
            cylinder(h=MOLDING_HEIGHT, r=MOLDING_OD/2, center=false);
            cylinder(h=MOLDING_HEIGHT + 1, r=MOLDING_ID/2, center=false);
            // Angled face (cut at tilt angle)
            if (is_top) {
                // Top molding: angled face on UNDERSIDE (bearing sits under it)
                translate([0, 0, MOLDING_HEIGHT - 2])
                    rotate([-ang, 0, 0])
                        translate([0, 0, -5])
                            cube([MOLDING_OD, MOLDING_OD, 10], center=true);
            } else {
                // Bottom molding: angled face on TOPSIDE (bearing sits on it)
                translate([0, 0, 2])
                    rotate([ang, 0, 0])
                        translate([0, 0, -5])
                            cube([MOLDING_OD, MOLDING_OD, 10], center=true);
            }
        }
    }
    // Clamp bolts (2 on each side)
    for (a = [0, 180]) {
        rotate([0, 0, a]) {
            color("Silver", 0.8)
                translate([MOLDING_OD/2 + 3, 0, MOLDING_HEIGHT/2])
                    rotate([0, 90, 0])
                        cylinder(h=8, r=3, center=true);
        }
    }
}

// --- Thrust bearing (roller ring) ---
module thrust_bearing() {
    color("Silver", 0.65) {
        difference() {
            cylinder(h=BEARING_HEIGHT, r=BEARING_OD/2, center=false);
            cylinder(h=BEARING_HEIGHT + 1, r=BEARING_ID/2, center=false);
        }
    }
    // Roller elements (decorative)
    for (i = [0:11]) {
        angle = i * 30;
        r = (BEARING_OD + BEARING_ID) / 4;
        color("Gold", 0.7)
            translate([r*cos(angle), r*sin(angle), BEARING_HEIGHT/2])
                sphere(r=2.5);
    }
}

// --- Rotor hub ---
module rotor_hub() {
    // Main hub body
    color("DimGray", 0.6) {
        difference() {
            cylinder(h=HUB_HEIGHT, r=HUB_OD/2, center=false);
            cylinder(h=HUB_HEIGHT + 1, r=HUB_ID/2, center=false);
            // Angled top face
            translate([0, 0, HUB_HEIGHT - 1])
                rotate([-TILT_ANGLE, 0, 0])
                    translate([0, 0, -5])
                        cube([HUB_OD + 4, HUB_OD + 4, 10], center=true);
            // Angled bottom face
            translate([0, 0, 1])
                rotate([TILT_ANGLE, 0, 0])
                    translate([0, 0, -5])
                        cube([HUB_OD + 4, HUB_OD + 4, 10], center=true);
        }
    }
}

// --- Rotor disk annulus ---
module rotor_disk() {
    color("FireBrick", 0.25) {
        difference() {
            cylinder(h=12, r=ROTOR_RADIUS, center=true);
            cylinder(h=14, r=HUB_OD/2 + 5, center=true);
        }
    }
}

// --- Blade ---
module blade() {
    color("DarkSlateGray", 0.7)
        translate([HUB_OD/2 + 5, -BLADE_CHORD/2, -BLADE_THICKNESS/2])
            cube([ROTOR_RADIUS - HUB_OD/2 - 5, BLADE_CHORD, BLADE_THICKNESS]);
}

// --- Swashplate ---
module swashplate() {
    // Rotating ring (upper)
    color("DarkCyan", 0.55) {
        difference() {
            cylinder(h=SWASH_HEIGHT/2 + 2, r=SWASH_OD/2, center=false);
            cylinder(h=SWASH_HEIGHT/2 + 3, r=SWASH_ID/2, center=false);
        }
    }
    // Stationary ring (lower)
    color("Teal", 0.7) {
        difference() {
            cylinder(h=SWASH_HEIGHT/2 + 2, r=SWASH_OD/2 + 2, center=false);
            cylinder(h=SWASH_HEIGHT/2 + 3, r=SWASH_ID/2, center=false);
        }
    }
}

// --- Single actuator ---
module actuator_body() {
    color("DimGray", 0.65)
        cube([ACTUATOR_WIDTH, ACTUATOR_DEPTH, ACTUATOR_HEIGHT], center=true);
    // Pushrod
    color("Silver", 0.8)
        translate([0, 0, ACTUATOR_HEIGHT/2 + ACTUATOR_STROKE/2])
            cylinder(h=ACTUATOR_STROKE + 10, r=2.5, center=false);
}

// --- Empennage ---
module empennage_assembly() {
    // Entire empennage hangs below the line — rotated down 15° from horizontal
    rotate([0, 15, 0]) {
        // Tail boom
        color("DimGray", 0.5)
            rotate([0, 90, 0])
                cylinder(h=TAIL_BOOM_LENGTH, r=TAIL_BOOM_DIA/2, center=false);

        // Horizontal stabilizer
        color("DarkSlateGray", 0.55)
            translate([TAIL_BOOM_LENGTH - HSTAB_CHORD, -HSTAB_SPAN/2, -HSTAB_THICK/2])
                cube([HSTAB_CHORD, HSTAB_SPAN, HSTAB_THICK]);

        // Vertical fin (hangs below boom)
        color("DarkSlateGray", 0.5)
            translate([TAIL_BOOM_LENGTH - VFIN_CHORD, -VFIN_THICK/2, -VFIN_HEIGHT])
                cube([VFIN_CHORD, VFIN_THICK, VFIN_HEIGHT]);
    }
}

// --- Webbing capture ---
module webbing_capture() {
    // Spectra webbing loops
    color("Orange", 0.8) {
        for (a = [0, 180]) {
            rotate([0, 0, a]) {
                // Horizontal leg through slot
                translate([TUBE_OD/2 - 1, 0, POS_SPLICE])
                    rotate([0, 90, 0])
                        cylinder(h=12, r=WEBBING_WIDTH/2, center=true);
                // Vertical leg down
                translate([TUBE_OD/2 + 5, 0, POS_SPLICE - 20])
                    cube([WEBBING_WIDTH, WEBBING_WIDTH, 25], center=true);
                // Horizontal leg to Dyneema
                translate([TUBE_OD/2 + 8, 0, POS_SPLICE - 22])
                    rotate([0, 90, 0])
                        cylinder(h=8, r=WEBBING_WIDTH/2, center=true);
            }
        }
    }
    // Splice bulge in Dyneema
    color("SandyBrown", 0.7)
        translate([0, 0, POS_SPLICE - 10])
            cylinder(h=25, r=Splice_DIA/2, center=false);
}

// ============================================================
// MAIN ASSEMBLY
// ============================================================

// Orientation: tube runs along Z axis (vertical in model space)
// Tilt is around Y axis (rotor disk leans in XZ plane)

// Dyneema line (through center)
dyneema_line();

// Central tube
central_tube();

// Webbing capture at bottom
webbing_capture();

// Empennage at lower section
translate([0, 0, POS_EMPENNAGE])
    empennage_assembly();

// Actuators (3× at 120°)
for (i = [0:2]) {
    angle = i * 120;
    translate([ACTUATOR_RADIUS*cos(angle), ACTUATOR_RADIUS*sin(angle), POS_ACTUATORS])
        rotate([0, 0, angle])
            actuator_body();
}

// Swashplate
translate([0, 0, POS_SWASHPLATE])
    swashplate();

// Bottom molding
translate([0, 0, POS_BOTTOM_MOLDING])
    molding(is_top=false);

// Bottom thrust bearing
translate([0, 0, POS_BOTTOM_BEARING])
    thrust_bearing();

// Rotor hub
translate([0, 0, POS_HUB_BOTTOM])
    rotor_hub();

// Rotor disk (tilted: leading edge forward-down into wind, axis = Y)
rotate([0, TILT_ANGLE, 0])
    translate([0, 0, POS_ROTOR_DISK])
        rotor_disk();

// Blades
for (i = [0:N_BLADES-1]) {
    angle = i * 360 / N_BLADES;
    rotate([0, TILT_ANGLE, 0])
        rotate([0, 0, angle])
            translate([0, 0, POS_ROTOR_DISK])
                blade();
}

// Top thrust bearing
translate([0, 0, POS_TOP_BEARING])
    thrust_bearing();

// Top molding
translate([0, 0, POS_TOP_MOLDING])
    molding(is_top=true);

// ============================================================
// RENDER INSTRUCTIONS
// ============================================================
//
// Preview:
//   openscad rotor_assembly_v2.scad
//
// PNG:
//   openscad --preview -o rotor_assembly_v2.png --imgsize=1920,1080 \
//     --autocenter --viewall --projection=ortho rotor_assembly_v2.scad
//
// STL:
//   openscad --render -o rotor_assembly_v2.stl rotor_assembly_v2.scad
