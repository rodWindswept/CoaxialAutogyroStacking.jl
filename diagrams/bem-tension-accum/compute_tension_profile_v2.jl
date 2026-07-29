#!/usr/bin/env julia
# compute_tension_profile_v2.jl — tension profile with wind gradient
# Run: julia --project=../.. compute_tension_profile_v2.jl
# Outputs: tension_profile_v2.csv
#
# Wind gradient: each rotor sees v(z) = v_ref * (z/10)^alpha.
# Computes profile via stack_tension_profile_polygon at each rotor's
# local wind speed, then accumulates per-section forces.

using CoaxialAutogyroStacking

const RHO = 1.225
const ALPHA = 0.14
const Z_REF = 10.0
const SIN_45 = sind(45.0)

radius = 3.0
n_rotors = 4
section_len = 15.0
tilt_values = graded_tilt(n_rotors)
rotors = [AutogyroRotor(radius, radius * 0.05, 2, 0.15, tilt_values[i], 0.0, 5.0)
          for i in 1:n_rotors]

v_refs = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0]

open("tension_profile_v2.csv", "w") do io
    write(io, "wind_speed,distance_from_anchor,tension\n")
    for v_ref in v_refs
        # Compute per-rotor forces with local wind speeds.
        # Solve polygon angles at the reference wind speed (approximation).
        θ, _, _ = solve_polygon_angles(rotors, 45.0, RHO, v_ref)

        T_cum = 0.0
        # Free end above topmost rotor
        write(io, "$v_ref,$(n_rotors * section_len),0.0\n")
        # Iterate top to bottom (i=1 is topmost at 60m)
        for i in 1:n_rotors
            d = (n_rotors - i + 1) * section_len  # 60, 45, 30, 15
            z = d * SIN_45
            v_local = v_ref * (max(z, 0.1) / Z_REF)^ALPHA

            F_line, _, _ = rotor_force_bem(rotors[i], RHO, v_local, θ[i])
            W_cos = rotors[i].mass * 9.81 * cosd(θ[i])
            seg_drag = bare_line_drag(RHO, v_local, 0.004, section_len, θ[i])
            mass_per_m = line_mass_per_m(0.004, 970.0)
            seg_weight = line_weight_along_line(mass_per_m, section_len, 9.81, θ[i])

            delta = seg_drag + (F_line - W_cos) + seg_weight
            T_cum += max(0.0, delta)
            # Write tension at the point BELOW this rotor
            d_below = d - section_len  # 45, 30, 15, 0
            write(io, "$v_ref,$d_below,$T_cum\n")
        end
        # Bare-line section below bottom rotor (15m to anchor)
        seg_drag = bare_line_drag(RHO, v_ref * (7.5 * SIN_45 / Z_REF)^ALPHA, 0.004, section_len, 45.0)
        mass_per_m = line_mass_per_m(0.004, 970.0)
        seg_weight = line_weight_along_line(mass_per_m, section_len, 9.81, 45.0)
        T_cum += seg_drag + seg_weight
        write(io, "$v_ref,0.0,$T_cum\n")
    end
end

println("tension_profile_v2.csv written — $(length(v_refs)) wind speeds with gradient")
