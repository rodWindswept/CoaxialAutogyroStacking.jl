// Single Lifting Autogyro Unit — Mechanical Assembly
// ============================================================
// Built to spec: schematics/PRD.md §1–9
// Parameters from Julia model via schematics/generate_params.jl
//
// Wind blows toward +X (horizontal, world frame).
// Disk tilt: forward-down relative to LINE, which gives upward tilt to WIND.
//   (line at 55° + disk tilted forward-down = disk appears tilted back to wind)
//   Disk normal tilts toward −X (windward/front) in tube-local.
//   rotate([0, −δ, 0]) — negative Y rotation.
// Entire assembly tilted to LINE_ELEVATION in world space.
// Empennage extends +X (downwind), droops 15° below horizontal.
// ============================================================

include <parameters.scad>
$fn = 72;
function s(x) = x * VISUAL_SCALE;

$vpr = [70, 0, 30];
$vpt = [s(200), 0, s(300)];
$vpd = s(6000);

// ============================================================
// AXIAL POSITIONS (tube-local Z, from tube bottom = 0)
// Contact chain: molding → bearing → hub → bearing → molding
// Bearing: SKF 51105 (H=11mm), Molding: Al 6061 (H=20mm), Hub (H=60mm)
// ============================================================
ZT_TOP_TIE       = 780;   // top rope tie — above everything
ZT_TOP_MOLDING   = 720;   // bottom of top molding (20mm tall, to 740)
ZT_TOP_BEARING   = 720;   // top face of top bearing (11mm thick, to 709)
ZT_HUB_TOP       = 709;   // hub top face (contacts top bearing)
ZT_HUB_BOTTOM    = 649;   // hub bottom (60mm tall)
ZT_ROTOR_DISK    = 679;   // disk center = hub midpoint
ZT_BOTTOM_BEARING= 649;   // top face of bottom bearing (extends to 638)
ZT_BOTTOM_MOLDING= 638;   // top of bottom molding (20mm tall, to 658)
ZT_GENERATOR     = 643;   // generator at bearing level, on tube
ZT_SWASHPLATE    = 620;   // right under bottom molding
ZT_ACTUATORS     = 560;   // actuators below swashplate
ZT_EMPENNAGE     = 120;   // tail boom mount
ZT_BOTTOM_TIE    = 20;    // bottom rope tie — primary load path

// Tilt: forward-down relative to line = negative Y rotation
// Molding cut: matches bearing tilted at −δ (deeper on −X/windward side)
TILT_SIGN = -1;  // −1 = forward-down (correct for autogyro kite)

// ============================================================
// MODULES (tube-local: Z = along tube)
// ============================================================

module dyneema_line() {
    // Extends well below assembly to suggest anchor point
    color("RoyalBlue", 0.85)
        translate([0, 0, -s(500)])
            cylinder(h=s(ZT_TOP_TIE + 600), r=s(LINE_DIAMETER * 1.5), $fn=16);
}

module central_tube() {
    difference() {
        color("DimGray", 0.7)
            cylinder(h=s(TUBE_LENGTH), r=s(TUBE_OD / 2));
        translate([0, 0, -1])
            cylinder(h=s(TUBE_LENGTH + 2), r=s(TUBE_ID / 2));
        for (a = [0, 180], z = [ZT_TOP_TIE, ZT_BOTTOM_TIE]) {
            rotate([0, 0, a])
            translate([s(TUBE_OD / 2), 0, s(z)])
                rotate([0, 90, 0])
                    cylinder(h=s(TUBE_WALL + 2), r=s(TIE_HOLE_DIA / 2), center=true);
        }
    }
}

module rope_tie(z) {
    for (a = [0, 180]) {
        rotate([0, 0, a]) color("SandyBrown", 0.85) {
            translate([s(TUBE_OD / 2 + TUBE_WALL / 2), 0, s(z)])
                rotate([0, 90, 0])
                    cylinder(h=s(TUBE_OD), r=s(TIE_ROPE_DIA / 2), center=true);
            translate([s(TUBE_OD / 2 + 2), 0, s(z - 8)])
                cylinder(h=s(16), r=s(TIE_ROPE_DIA / 2));
        }
    }
}

// Molding: angled face matches bearing at δ (deeper on windward/−X side)
module molding(is_top) {
    difference() {
        color("SaddleBrown", 0.75)
            cylinder(h=s(MOLDING_HEIGHT), r=s(MOLDING_OD / 2));
        translate([0, 0, -1])
            cylinder(h=s(MOLDING_HEIGHT + 2), r=s(MOLDING_ID / 2));
        // Cut angled face to match bearing tilt
        if (is_top) {
            translate([0, 0, s(MOLDING_HEIGHT)])
                rotate([0, TILT_SIGN * TILT_ANGLE, 0])
                    translate([0, 0, -s(MOLDING_OD)])
                        cube([s(MOLDING_OD * 2), s(MOLDING_OD * 2), s(MOLDING_OD * 2)], center=true);
        } else {
            rotate([0, TILT_SIGN * TILT_ANGLE, 0])
                translate([0, 0, s(MOLDING_OD)])
                    cube([s(MOLDING_OD * 2), s(MOLDING_OD * 2), s(MOLDING_OD * 2)], center=true);
        }
    }
    for (a = [0, 180]) {
        rotate([0, 0, a]) color("Silver", 0.8)
            translate([s(MOLDING_OD / 2 + 3), 0, s(MOLDING_HEIGHT / 2)])
                rotate([0, 90, 0]) cylinder(h=s(8), r=s(2.5), center=true);
    }
}

// Bearing, hub, disk, blades — all tilted around Y by TILT_SIGN*δ
// CRITICAL: rotate at origin (0,0,0), then translate to position.
// This keeps the element centered on the tube/Dyneema axis.

module bearing_ring() {
    // Hollow ring with visible clearance over tube (display ID > actual for visibility)
    color("Silver", 0.5) difference() {  // semi-transparent to show tube inside
        cylinder(h=s(BEARING_HEIGHT), r=s(BEARING_OD / 2));
        cylinder(h=s(BEARING_HEIGHT + 1), r=s(BEARING_ID / 2 + 4));  // visible gap
    }
    for (i = [0:15]) {
        a = i * 22.5; r = s((BEARING_OD + BEARING_ID) / 4);
        color("Gold", 0.75)
            translate([r * cos(a), r * sin(a), s(BEARING_HEIGHT / 2)])
                sphere(r=s(2.5));
    }
}

module rotor_hub_body() {
    color("DimGray", 0.6) difference() {
        cylinder(h=s(HUB_HEIGHT), r=s(HUB_OD / 2));
        translate([0, 0, -1]) cylinder(h=s(HUB_HEIGHT + 2), r=s(HUB_ID / 2));
    }
}

module rotor_disk_annulus() {
    color("FireBrick", 0.15) difference() {  // more transparent
        cylinder(h=s(6), r=s(ROTOR_RADIUS), center=true);
        cylinder(h=s(8), r=s(HUB_OD / 2 + 5), center=true);
    }
}

module blade_geom(i) {
    ang = i * 360 / N_BLADES;
    rotate([0, 0, ang])
    color("DarkOliveGreen", 0.85)  // opaque blades stand out
        translate([s(HUB_OD / 2 + 5), -s(BLADE_CHORD / 2), -s(BLADE_THICKNESS / 2)])
            cube([s(ROTOR_RADIUS - HUB_OD / 2 - 5), s(BLADE_CHORD), s(BLADE_THICKNESS)]);
}

module generator() {
    for (i = [0:2]) rotate([0, 0, i * 120])
        translate([s(GEN_RADIUS), 0, 0])
        color("DarkGray", 0.7)
            cube([s(GEN_WIDTH), s(GEN_HEIGHT), s(GEN_HEIGHT)], center=true);
}

module swashplate() {
    color("Teal", 0.7) difference() {
        cylinder(h=s(SWASH_HEIGHT / 2), r=s(SWASH_OD / 2 + 2));
        cylinder(h=s(SWASH_HEIGHT / 2 + 1), r=s(SWASH_ID / 2));
    }
    translate([0, 0, s(SWASH_HEIGHT / 2)])
    color("DarkCyan", 0.55) difference() {
        cylinder(h=s(SWASH_HEIGHT / 2), r=s(SWASH_OD / 2));
        cylinder(h=s(SWASH_HEIGHT / 2 + 1), r=s(SWASH_ID / 2));
    }
}

module actuators() {
    for (i = [0:2]) rotate([0, 0, i * 120])
        translate([s(ACTUATOR_RADIUS), 0, 0]) {
            color("DimGray", 0.65)
                cube([s(ACTUATOR_WIDTH), s(ACTUATOR_DEPTH), s(ACTUATOR_HEIGHT)], center=true);
            color("Silver", 0.8)
                translate([0, 0, s(ACTUATOR_HEIGHT / 2)])
                    cylinder(h=s(ZT_SWASHPLATE - ZT_ACTUATORS + SWASH_HEIGHT/2), r=s(2));
        }
}
// Empennage — extends +X (downwind). Slight upward tilt to sit closer to disk.
// Primary role: torque reaction for generator. Control authority from swashplate.
module empennage() {
    rotate([0, -5, 0]) {  // slight upward tilt — tail plane closer to rotor
        color("DimGray", 0.55) rotate([0, 90, 0])
            cylinder(h=s(TAIL_BOOM_LENGTH), r=s(TAIL_BOOM_DIA / 2));
        color("DarkSlateGray", 0.55)
            translate([s(TAIL_BOOM_LENGTH - HSTAB_CHORD), -s(HSTAB_SPAN / 2), -s(2)])
                cube([s(HSTAB_CHORD), s(HSTAB_SPAN), s(4)]);
        color("DarkSlateGray", 0.5)
            translate([s(TAIL_BOOM_LENGTH - VFIN_CHORD), -s(1), -s(VFIN_HEIGHT)])
                cube([s(VFIN_CHORD), s(2), s(VFIN_HEIGHT)]);
    }
}

module scissor_links() {
    zh = s(ZT_HUB_BOTTOM);
    zs = s(ZT_SWASHPLATE + SWASH_HEIGHT);
    for (a = [0, 180]) rotate([0, 0, a])
        color("Gray", 0.5)
            translate([s(HUB_OD / 2 - 5), 0, zs])
                cylinder(h=zh - zs, r=s(2));
}

// Force arrows
module arrow(len, rb, rh, hl, col) {
    color(col, 0.85) {
        cylinder(h=len - hl, r=rb);
        translate([0, 0, len - hl]) cylinder(h=hl, r1=rb * 2, r2=0);
    }
}

module force_arrows() {
    // F_lift — green, ⊥ wind. Build in tilted frame at origin, then translate.
    translate([0, 0, s(ZT_ROTOR_DISK)])
    rotate([0, TILT_SIGN * TILT_ANGLE, 0])
        translate([0, s(ROTOR_RADIUS * 0.7), 0])
            rotate([90, 0, 0]) arrow(s(400), s(4), s(12), s(40), "Green");

    // F_drag — orange, ∥ wind (+X)
    translate([0, 0, s(ZT_ROTOR_DISK)])
    rotate([0, TILT_SIGN * TILT_ANGLE, 0])
        translate([s(ROTOR_RADIUS * 0.5), 0, 0])
            rotate([0, -90, 0]) arrow(s(400), s(4), s(12), s(40), "Orange");

    // T_above / T_below — purple, along tube (−Z)
    translate([s(TUBE_OD + 5), 0, s(ZT_TOP_TIE + 50)])
        rotate([0, 180, 0]) arrow(s(150), s(5), s(14), s(45), "Purple");
    translate([s(TUBE_OD + 5), 0, s(ZT_BOTTOM_TIE)])
        rotate([0, 180, 0]) arrow(s(100), s(6), s(16), s(50), "Purple");

    // Centrifugal — red
    for (i = [0:N_BLADES-1]) {
        translate([0, 0, s(ZT_ROTOR_DISK)])
        rotate([0, TILT_SIGN * TILT_ANGLE, 0])
        rotate([0, 0, i * 360 / N_BLADES])
            translate([s(HUB_OD / 2 + 5), 0, 0])
                rotate([0, -90, 0]) arrow(s(ROTOR_RADIUS * 0.5), s(3), s(10), s(30), "Red");
    }

    // Gyro
    translate([0, 0, s(ZT_HUB_CENTER)])
        color("Orange", 0.7)
            rotate_extrude(angle=90, $fn=32)
                translate([s(BEARING_OD / 2), 0]) circle(r=s(3));
}

module wind_indicator() {
    translate([-s(ROTOR_RADIUS + 200), s(ROTOR_RADIUS * 0.1), s(ZT_ROTOR_DISK + 250)])
        rotate([0, -90, 0]) arrow(s(ROTOR_RADIUS * 1.3), s(5), s(16), s(50), "LightSkyBlue");
}

// Labels
module labels() {
    color("RoyalBlue", 0.9) translate([-s(TUBE_OD + 60), -s(MOLDING_OD), s(ZT_TOP_TIE + 60)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Dyneema line (Ø4 mm)", size=s(14), halign="center");
    color("DimGray", 0.9) translate([s(TUBE_OD + 50), -s(30), s(TUBE_LENGTH / 2)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Tube — tension tie-rod", size=s(13), halign="center");
    color("SandyBrown", 0.9) translate([s(TUBE_OD + 40), -s(20), s(ZT_TOP_TIE)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Top tie → Dyneema", size=s(11));
    color("SandyBrown", 0.9) translate([s(TUBE_OD + 40), -s(20), s(ZT_BOTTOM_TIE)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Bottom tie → Dyneema", size=s(11));
    color("SaddleBrown", 0.9) translate([s(MOLDING_OD/2 + 25), -s(15), s(ZT_TOP_MOLDING + MOLDING_HEIGHT/2)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Top molding", size=s(10));
    color("Silver", 0.9) translate([s(BEARING_OD/2 + 35), -s(15), s(ZT_TOP_BEARING + BEARING_HEIGHT/2)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Top bearing", size=s(10));
    color("DimGray", 0.9) translate([s(HUB_OD/2 + 25), -s(25), s(ZT_HUB_CENTER)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Rotor hub", size=s(11));
    color("DarkOliveGreen", 0.9) translate([s(HUB_OD/2 + ROTOR_RADIUS * 0.5), -s(BLADE_CHORD), s(ZT_ROTOR_DISK)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Blade (2×)", size=s(10));
    color("FireBrick", 0.9) translate([-s(ROTOR_RADIUS * 0.65), s(ROTOR_RADIUS * 0.3), s(ZT_ROTOR_DISK)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text(str("Rotor disk (R=", ROTOR_RADIUS/1000, " m)"), size=s(12), halign="center");
    color("Silver", 0.9) translate([s(BEARING_OD/2 + 35), -s(15), s(ZT_BOTTOM_BEARING)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Bottom bearing", size=s(10));
    color("SaddleBrown", 0.9) translate([s(MOLDING_OD/2 + 25), -s(15), s(ZT_BOTTOM_MOLDING + MOLDING_HEIGHT/2)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Bottom molding", size=s(10));
    color("DarkGray", 0.9) translate([s(GEN_RADIUS + 25), -s(15), s(ZT_GENERATOR)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Generator", size=s(11));
    color("Teal", 0.9) translate([s(SWASH_OD/2 + 30), -s(15), s(ZT_SWASHPLATE + SWASH_HEIGHT/2)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Swashplate", size=s(10));
    color("DimGray", 0.9) translate([s(ACTUATOR_RADIUS + 25), -s(15), s(ZT_ACTUATORS)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Actuator (3×)", size=s(10));
    color("DimGray", 0.9) translate([s(TAIL_BOOM_LENGTH * 0.5), -s(TAIL_BOOM_DIA * 2), s(ZT_EMPENNAGE)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Tail boom", size=s(10));
    color("DarkSlateGray", 0.9) translate([s(TAIL_BOOM_LENGTH - HSTAB_CHORD/2), -s(HSTAB_SPAN/2 + 25), s(ZT_EMPENNAGE)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("H-stab", size=s(10));
    color("DarkSlateGray", 0.9) translate([s(TAIL_BOOM_LENGTH - VFIN_CHORD/2), -s(20), s(ZT_EMPENNAGE - VFIN_HEIGHT/2)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("V-fin", size=s(10));
    color("LightSkyBlue", 0.9) translate([-s(ROTOR_RADIUS - 150), s(ROTOR_RADIUS * 0.2), s(ZT_ROTOR_DISK + 270)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("Wind →", size=s(14));
    color("Purple", 0.9) translate([s(TUBE_OD + 40), -s(10), s(ZT_TOP_TIE + 25)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("T above", size=s(11));
    color("Purple", 0.9) translate([s(TUBE_OD + 55), -s(30), s(ZT_BOTTOM_TIE - 20)])
        rotate([90, 0, 0]) linear_extrude(s(1)) text("T_below = T_above + F_line − W cos φ", size=s(11));
}

// ============================================================
// ASSEMBLY (tube-local)
// ============================================================
module assembly_local() {
    dyneema_line();
    central_tube();
    rope_tie(ZT_TOP_TIE);
    rope_tie(ZT_BOTTOM_TIE);

    // Non-tilted elements (on tube, aligned with Z axis)
    translate([0, 0, s(ZT_TOP_MOLDING)])    molding(is_top=true);
    translate([0, 0, s(ZT_BOTTOM_MOLDING)]) molding(is_top=false);
    translate([0, 0, s(ZT_GENERATOR)])      generator();
    translate([0, 0, s(ZT_SWASHPLATE)])     swashplate();
    scissor_links();
    translate([0, 0, s(ZT_ACTUATORS)])      actuators();
    translate([0, 0, s(ZT_EMPENNAGE)])      empennage();

    // Tilted elements: rotate at origin (stays centered), THEN translate along tube
    // This keeps every element centered on the tube/Dyneema axis.
    translate([0, 0, s(ZT_TOP_BEARING)])
        rotate([0, TILT_SIGN * TILT_ANGLE, 0])
            bearing_ring();

    translate([0, 0, s(ZT_BOTTOM_BEARING)])
        rotate([0, TILT_SIGN * TILT_ANGLE, 0])
            bearing_ring();

    translate([0, 0, s(ZT_HUB_BOTTOM)])
        rotate([0, TILT_SIGN * TILT_ANGLE, 0])
            rotor_hub_body();

    translate([0, 0, s(ZT_ROTOR_DISK)])
        rotate([0, TILT_SIGN * TILT_ANGLE, 0]) {
            rotor_disk_annulus();
            for (i = [0:N_BLADES-1]) blade_geom(i);
        }

    force_arrows();
    labels();
}

// ============================================================
// WORLD-SPACE
// ============================================================
rotate([0, 90 - LINE_ELEVATION, 0])
    assembly_local();

wind_indicator();
