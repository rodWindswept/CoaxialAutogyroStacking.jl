// ╔══════════════════════════════════════════════════════════════════╗
// ║  HUB CLOSE-UP — Bearings, moldings, tube (no disk, no blades)    ║
// ╚══════════════════════════════════════════════════════════════════╝

include <parameters.scad>
$fn = 72;
function s(x) = x * VISUAL_SCALE;

// Tight camera on the hub stack (Z = 620 to 750)
$vpr = [70, 0, 0];
$vpt = [0, 0, s(685)];
$vpd = s(800);

module hub_stack() {
    // Dyneema line
    color("RoyalBlue", 0.9)
        cylinder(h=s(250), r=s(LINE_DIAMETER * 2), $fn=16);

    // Tube
    color("DimGray", 0.85)
        difference() {
            cylinder(h=s(250), r=s(TUBE_OD / 2));
            translate([0,0,-1]) cylinder(h=s(252), r=s(TUBE_ID / 2));
        }

    // Bottom molding — Z=638
    color("Gold", 0.9)
        translate([0,0,s(18)])
            difference() {
                cylinder(h=s(20), r=s(MOLDING_OD / 2));
                translate([0,0,-1]) cylinder(h=s(22), r=s(MOLDING_ID / 2));
            }

    // Bottom bearing — Z=649
    color("Silver", 0.7)
        translate([0,0,s(29)])
            difference() {
                cylinder(h=s(11), r=s(BEARING_OD / 2));
                cylinder(h=s(13), r=s(BEARING_ID / 2 + 2));
            }

    // Hub — Z=649 to 709
    color("Gray", 0.85)
        translate([0,0,s(29)])
            difference() {
                cylinder(h=s(60), r=s(HUB_OD / 2));
                translate([0,0,-1]) cylinder(h=s(62), r=s(HUB_ID / 2));
            }

    // Top bearing — Z=709
    color("Silver", 0.7)
        translate([0,0,s(89)])
            difference() {
                cylinder(h=s(11), r=s(BEARING_OD / 2));
                cylinder(h=s(13), r=s(BEARING_ID / 2 + 2));
            }

    // Top molding — Z=720
    color("Gold", 0.9)
        translate([0,0,s(100)])
            difference() {
                cylinder(h=s(20), r=s(MOLDING_OD / 2));
                translate([0,0,-1]) cylinder(h=s(22), r=s(MOLDING_ID / 2));
            }
}

// Recentre: bottom molding at Z=0
translate([0, 0, s(620)])
    hub_stack();
