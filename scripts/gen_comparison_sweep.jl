#!/usr/bin/env julia
# Run BEM sweep with/without Snel stall delay, capturing solver iterations.
# Outputs: bem_solver_iters.tsv, bem_snel_comparison.tsv

using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking
using DataFrames
using CSV
using Statistics

# Match the BEM sweep grid
radii = [1.5, 2.0, 3.0]
n_vals = [1, 2, 3, 4]
profiles_list = ["uniform", "top_draggy", "bottom_lifty", "graded"]
elevations = [45.0, 55.0]
winds = [6.0, 8.0, 10.0, 12.0]
spacing = 15.0

rho = 1.225
line_dia = 0.004
rotor_mass = 5.0
hub_radius = 0.05
n_blades = 2
blade_chord = 0.15

# --- Solver iteration data ---
iters_rows = []
for R in radii, N in n_vals, prof in profiles_list, elev in elevations, v in winds
    rotors = AutogyroRotor[]
    for i in 1:N
        push!(rotors, AutogyroRotor(R, hub_radius, n_blades, blade_chord,
                                    10.0, 0.0, rotor_mass))
    end
    section_lens = fill(spacing, N)
    stack = AutogyroStack(rotors, section_lens, line_dia, elev)

    try
        θ, T, F, iters = solve_polygon_angles(stack.rotors, elev, rho, v;
                                               stall_delay=true, max_iter=20)
        anchor_t = T[end]
        push!(iters_rows, (radius=R, n_rotors=N, profile=prof, elevation=elev,
                           wind_speed=v, anchor_tension=anchor_t, iterations=iters))
    catch e
        push!(iters_rows, (radius=R, n_rotors=N, profile=prof, elevation=elev,
                           wind_speed=v, anchor_tension=0.0, iterations=0))
    end
end

df_iters = DataFrame(iters_rows)
CSV.write("bem_solver_iters.tsv", df_iters; delim='\t')
println("Solver iterations: $(nrow(df_iters)) rows")

# --- Snel on/off comparison ---
snel_rows = []
for R in radii, N in n_vals, prof in profiles_list, elev in elevations, v in winds
    rotors = AutogyroRotor[]
    for i in 1:N
        push!(rotors, AutogyroRotor(R, hub_radius, n_blades, blade_chord,
                                    10.0, 0.0, rotor_mass))
    end
    section_lens = fill(spacing, N)
    stack = AutogyroStack(rotors, section_lens, line_dia, elev)

    tension_snel = 0.0
    tension_nosnel = 0.0

    # With Snel
    try
        θ, T_snel, F, _ = solve_polygon_angles(stack.rotors, elev, rho, v;
                                                 stall_delay=true, max_iter=20)
        tension_snel = T_snel[end]
    catch e
    end

    # Without Snel
    try
        θ, T_nosnel, F, _ = solve_polygon_angles(stack.rotors, elev, rho, v;
                                                   stall_delay=false, max_iter=20)
        tension_nosnel = T_nosnel[end]
    catch e
    end

    boost_pct = if tension_nosnel > 0
        (tension_snel - tension_nosnel) / tension_nosnel * 100
    else
        0.0
    end

    push!(snel_rows, (radius=R, n_rotors=N, profile=prof, elevation=elev,
                      wind_speed=v, tension_with_snel=tension_snel,
                      tension_without_snel=tension_nosnel,
                      snel_boost_pct=boost_pct))
end

df_snel = DataFrame(snel_rows)
CSV.write("bem_snel_comparison.tsv", df_snel; delim='\t')
println("Snel comparison: $(nrow(df_snel)) rows")
println("Mean Snel boost: $(round(mean(df_snel.snel_boost_pct[df_snel.tension_with_snel .> 0]), digits=1))%")
