#!/usr/bin/env julia
# compute_force_breakdown.jl — extract per-rotor force components
# Run: julia --project=../.. compute_force_breakdown.jl
# Outputs: force_breakdown.csv

using CoaxialAutogyroStacking

const RHO = 1.225

radius = 3.0
n_rotors = 4
section_len = 15.0
tilt_values = graded_tilt(n_rotors)
rotors = [AutogyroRotor(radius, radius * 0.05, 2, 0.15, tilt_values[i], 0.0, 5.0)
          for i in 1:n_rotors]

open("force_breakdown.csv", "w") do io
    write(io, "wind_speed,rotor_position,distance,along_line,thrust,drag_force,weight,wind_at_rotor\n")
    for v_ref in [6.0, 8.0, 10.0, 12.0]
        θ, _, _ = solve_polygon_angles(rotors, fill(section_len, n_rotors), 45.0, RHO, v_ref)
        for i in 1:n_rotors
            d = (n_rotors - i + 1) * section_len

            F_line, T_thrust, rpm = rotor_force_bem(rotors[i], RHO, v_ref, θ[i])
            W = rotors[i].mass * 9.81
            W_cos = W * cosd(θ[i])

            # Drag from BEM: total force minus thrust component
            # rotor_force_bem returns F_line (along-line), T_thrust (disk normal)
            # The drag is the perpendicular component
            F_drag = bare_line_drag(RHO, v_ref, 0.004, section_len, θ[i])

            write(io, "$v_ref,$i,$d,$F_line,$T_thrust,$F_drag,$W,$v_ref\n")
        end
    end
end

println("force_breakdown.csv written — 16 rows (4 wind speeds × 4 rotors)")
