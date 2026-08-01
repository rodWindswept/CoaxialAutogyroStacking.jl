// ╔══════════════════════════════════════════════════════════════════╗
// ║  EXPLODED ASSEMBLY — Clean geometry, labels via HTML overlay      ║
// ╚══════════════════════════════════════════════════════════════════╝

include <parameters.scad>
$fn = 72;
function s(x) = x * VISUAL_SCALE;

$vpr = [70, 0, 0];
$vpt = [s(100), 0, s(180)];
$vpd = s(2800);

module dashed_line(z1, z2, x) {
    steps = 8;
    for (i = [0:steps-1]) {
        zs = z1 + (z2 - z1) * i / steps;
        ze = z1 + (z2 - z1) * (i + 0.5) / steps;
        color("White", 0.3)
            translate([s(x), 0, s(zs)])
                cylinder(h=s(ze - zs), r=s(1.5));
    }
}

module exploded() {
    // Dyneema line
    color("RoyalBlue", 0.6)
        cylinder(h=s(700), r=s(LINE_DIAMETER * 1.5), $fn=16);

    // Tube ghosted
    color("DimGray", 0.25)
        difference() {
            cylinder(h=s(700), r=s(TUBE_OD / 2));
            translate([0,0,-1]) cylinder(h=s(702), r=s(TUBE_ID / 2));
        }

    // Parts exploded upward in assembly order
    offsets = [120, 220, 270, 380, 430];  // hub, brg_top, mold_top, brg_bot, mold_bot
    heights = [60, 11, 20, 11, 20];
    colors_ = [["Gray",0.85], ["Silver",0.7], ["Gold",0.85], ["Silver",0.7], ["Gold",0.85]];
    ods = [HUB_OD, BEARING_OD, MOLDING_OD, BEARING_OD, MOLDING_OD];
    ids = [HUB_ID, BEARING_ID, MOLDING_ID, BEARING_ID, MOLDING_ID];

    for (i = [0:4]) {
        translate([0, 0, s(offsets[i])])
            color(colors_[i][0], colors_[i][1])
                difference() {
                    cylinder(h=s(heights[i]), r=s(ods[i] / 2));
                    translate([0,0,-1]) cylinder(h=s(heights[i]+2), r=s(ids[i] / 2 + (i==0||i==1||i==3?2:0)));
                }
        dashed_line(700, 700 + offsets[i], -60);
    }

    // Disk + blades at normal position (partial)
    rotate([0, -TILT_ANGLE, 0]) {
        color("FireBrick", 0.2)
            difference() {
                cylinder(h=s(8), r=s(ROTOR_RADIUS * 0.4), center=true);
                cylinder(h=s(10), r=s(HUB_OD / 2 + 5), center=true);
            }
        for (i = [0:N_BLADES-1]) {
            rotate([0,0,i*360/N_BLADES])
            color("DarkOliveGreen", 0.85)
                translate([s(32.5), -s(BLADE_CHORD/2), -s(BLADE_THICKNESS/2)])
                    cube([s(ROTOR_RADIUS * 0.4 - 37.5), s(BLADE_CHORD), s(BLADE_THICKNESS)]);
        }
    }
}

exploded();
