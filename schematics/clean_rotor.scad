// ╔══════════════════════════════════════════════════════════════════╗
// ║  CLEAN RENDER — Single rotor, named colours (2021.01 safe)       ║
// ╚══════════════════════════════════════════════════════════════════╝

include <parameters.scad>
$fn = 72;
function s(x) = x * VISUAL_SCALE;

// Camera — 3/4 hero view centred on rotor disk
$vpr = [65, 0, 25];
$vpt = [0, 0, s(679)];
$vpd = s(9000);

module rotor_core() {
    // Dyneema line
    color("RoyalBlue", 0.9)
        cylinder(h=s(1200), r=s(LINE_DIAMETER * 1.5), $fn=16);

    // Central tube
    color("DimGray", 0.85)
        difference() {
            cylinder(h=s(800), r=s(TUBE_OD / 2));
            translate([0,0,-1]) cylinder(h=s(802), r=s(TUBE_ID / 2));
        }

    // Moldings
    color("Gold", 0.85)
        for (z = [638, 720])
            translate([0,0,s(z)])
                difference() {
                    cylinder(h=s(20), r=s(MOLDING_OD / 2));
                    translate([0,0,-1]) cylinder(h=s(22), r=s(MOLDING_ID / 2));
                }

    // Bearings
    color("Silver", 0.6)
        for (z = [649, 709])
            translate([0,0,s(z)])
                difference() {
                    cylinder(h=s(11), r=s(BEARING_OD / 2));
                    cylinder(h=s(13), r=s(BEARING_ID / 2 + 4));
                }

    // Hub
    color("Gray", 0.8)
        translate([0,0,s(649)])
            difference() {
                cylinder(h=s(60), r=s(HUB_OD / 2));
                translate([0,0,-1]) cylinder(h=s(62), r=s(HUB_ID / 2));
            }

    // Rotor disk — red, semi-transparent
    color("FireBrick", 0.2)
        translate([0,0,s(679)])
        rotate([0, -TILT_ANGLE, 0])
            difference() {
                cylinder(h=s(8), r=s(ROTOR_RADIUS), center=true);
                cylinder(h=s(10), r=s(HUB_OD / 2 + 5), center=true);
            }

    // Blades
    color("DarkOliveGreen", 0.9)
        translate([0,0,s(679)])
        rotate([0, -TILT_ANGLE, 0])
            for (i = [0:N_BLADES-1]) {
                rotate([0,0,i*360/N_BLADES])
                    translate([s(32.5), -s(BLADE_CHORD/2), -s(BLADE_THICKNESS/2)])
                        cube([s(ROTOR_RADIUS - 37.5), s(BLADE_CHORD), s(BLADE_THICKNESS)]);
            }

    // Wind arrow
    color("LightSkyBlue", 0.85) {
        translate([s(-ROTOR_RADIUS-100), s(180), s(700)])
        rotate([0,-90,0])
            cylinder(h=s(ROTOR_RADIUS*2.5), r=s(16));
        translate([s(ROTOR_RADIUS*1.1), s(180), s(700)])
        rotate([0,-90,0])
            cylinder(h=s(120), r1=s(48), r2=0);
    }
}

rotate([0, 90-LINE_ELEVATION, 0]) rotor_core();
