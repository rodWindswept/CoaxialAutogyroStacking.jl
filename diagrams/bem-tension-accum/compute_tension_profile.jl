#!/usr/bin/env julia
# compute_tension_profile.jl
# Run: julia --project=../.. compute_tension_profile.jl
# Outputs: tension_profile.csv

using CSV, DataFrames, CoaxialAutogyroStacking

RHO = 1.225
best_radius = 3.0
best_n = 4
elevation = 45.0
section_lengths = fill(15.0, best_n)

# Build rotors with graded tilt
tilt_values = graded_tilt(best_n)
rotors = [AutogyroRotor(best_radius, best_radius * 0.05, 2, 0.15, tilt_values[i], 0.0, 5.0)
          for i in 1:best_n]

stack = AutogyroStack(rotors, section_lengths, 0.004, elevation; line_density=970.0)

wind_speeds = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0]
total_len = best_n * 15.0

open("tension_profile.csv", "w") do io
    write(io, "wind_speed,distance_from_anchor,tension\n")
    for v in wind_speeds
        profile = stack_tension_profile_polygon(stack, RHO, v)
        # profile[1]=0 at top, profile[end]=anchor max
        # Convert to distance from anchor (0=anchor, total_len=top)
        for i in 1:length(profile)
            d = total_len - (i - 1) * 15.0
            write(io, "$v,$d,$(profile[i])\n")
        end
    end
end

println("tension_profile.csv written — $(length(wind_speeds)) wind speeds")
