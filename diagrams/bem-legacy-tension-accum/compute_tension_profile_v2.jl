#!/usr/bin/env julia
# compute_tension_profile_v2.jl — tension profile with wind gradient
# Run: julia --project=../.. compute_tension_profile_v2.jl
# Outputs: tension_profile_v2.csv
#
# Applies wind shear power law: v(z) = v_ref * (z/10)^alpha
# where z = height above ground, alpha = 0.14 (open terrain)
# Reference wind speed v_ref is at 10m AGL.

using CoaxialAutogyroStacking

const RHO = 1.225
const ALPHA = 0.14        # wind shear exponent
const Z_REF = 10.0         # reference height (m)
const ELEVATION_DEG = 45.0
const ELEVATION_RAD = deg2rad(ELEVATION_DEG)
const SIN_ELEV = sin(ELEVATION_RAD)

radius = 3.0
n_rotors = 4
section_len = 15.0
tilt_values = graded_tilt(n_rotors)

# Build rotors
rotors = [AutogyroRotor(radius, radius * 0.05, 2, 0.15, tilt_values[i], 0.0, 5.0)
          for i in 1:n_rotors]

v_refs = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0]

open("tension_profile_v2.csv", "w") do io
    write(io, "wind_speed,distance_from_anchor,tension,wind_at_rotor\n")
    for v_ref in v_refs
        # Compute along-line force per rotor at its height
        rotor_forces = zeros(n_rotors)
        for i in 1:n_rotors
            # Distance from anchor to this rotor
            d_from_anchor = i * section_len
            # Height above ground
            z = d_from_anchor * SIN_ELEV
            # Wind speed at this height
            v_local = v_ref * (max(z, 0.1) / Z_REF)^ALPHA
            rotor_forces[i] = rotor_force_along_line(rotors[i], RHO, v_local, ELEVATION_DEG)[1]
        end

        # Accumulate tension from top down
        tension = 0.0
        for i in n_rotors:-1:1
            d = i * section_len  # distance from anchor to this rotor
            # Line drag in section above this rotor
            # (rho, v_wind, diameter, length, line_angle_deg)
            z = d * SIN_ELEV
            v_local = v_ref * (max(z, 0.1) / Z_REF)^ALPHA
            section_drag = bare_line_drag(RHO, v_local, 0.004, section_len,
                                          ELEVATION_DEG)
            tension += section_drag
            write(io, "$v_ref,$d,$tension,$(rotor_forces[i])\n")
            # Add rotor force below this rotor
            tension += max(rotor_forces[i], 0.0)
        end
        # Anchor point
        write(io, "$v_ref,0.0,$tension,0.0\n")
    end
end

println("tension_profile_v2.csv written — $(length(v_refs)) wind speeds with gradient")
