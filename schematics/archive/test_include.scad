include <parameters.scad>;
echo("ROTOR_RADIUS=", ROTOR_RADIUS);
echo("TILT_ANGLE=", TILT_ANGLE);
echo("TUBE_OD=", TUBE_OD);
echo("HUB_OD=", HUB_OD);
echo("VISUAL_SCALE=", VISUAL_SCALE);
cylinder(h=100, r=ROTOR_RADIUS * VISUAL_SCALE);
