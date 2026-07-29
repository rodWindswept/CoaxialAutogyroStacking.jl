#!/usr/bin/env julia
# compute_tension_profile_v2.jl — tension profile with wind gradient (BEM v2.1)
# Run: julia --project=../.. compute_tension_profile_v2.jl
# Outputs: tension_profile_v2.csv
#
# Applies wind shear power law: v(z) = v_ref * (z/10)^alpha
# Uses solve_polygon_angles + rotor_force_bem per segment.

using CoaxialAutogyroStacking

const RHO = 1.225
const ALPHA = 0.14
const Z_REF = 10.0
const ELEVATION_DEG = 45.0
const ELEVATION_RAD = deg2rad(ELEVATION_DEG)
const SIN_ELEV = sin(ELEVATION_RAD)

radius = 3.0
n_rotors = 4
section_len = 15.0
tilt_values = graded_tilt(n_rotors)
rotors = [AutogyroRotor(radius, radius * 0.05, 2, 0.15, tilt_values[i], 0.0, 5.0)
          for i in 1:n_rotors]

v_refs = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0]

open("tension_profile_v2.csv", "w") do io
    write(io, "wind_speed,distance_from_anchor,tension,wind_at_rotor\n")
    for v_ref in v_refs
        # Solve polygon angles for this reference wind speed
        θ, _, _ = solve_polygon_angles(rotors, ELEVATION_DEG, RHO, v_ref)

        T_above = 0.0
        for i in 1:n_rotors
            d = i * section_len  # distance from anchor
            z = d * SIN_ELEV
            v_local = v_ref * (max(z, 0.1) / Z_REF)^ALPHA

            # BEM force at this segment's angle
            F_line, _, _ = rotor_force_bem(rotors[i], RHO, v_local, θ[i])
            W_cos = rotors[i].mass * 9.81 * cosd(θ[i])

            # Line drag and weight
            seg_drag = bare_line_drag(RHO, v_local, 0.004, section_len, θ[i])
            mass_per_m = line_mass_per_m(0.004, 970.0)
            seg_weight = line_weight_along_line(mass_per_m, section_len, 9.81, θ[i])

            delta = seg_drag + (F_line - W_cos) + seg_weight
            tension = T_above + delta

            write(io, "$v_ref,$d,$tension,$v_local\n")
            T_above = max(0.0, tension)
        end
        # Anchor
        write(io, "$v_ref,0.0,$T_above,0.0\n")
    end
end

println("tension_profile_v2.csv written — $(length(v_refs)) wind speeds with gradient (BEM v2.1)")
