#!/usr/bin/env julia
# scripts/sweep_pitch_authority.jl
# Quantify gust authority from variable blade pitch.
# Sweeps blade_pitch_deg from -5 to +20 at fixed wind speeds.
# Output: scripts/results/sweep_pitch_authority.tsv

using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking, DataFrames, CSV, Printf, Dates

const RHO = 1.225
const R = 3.0
const N = 3
const ELEV = 45.0
const SPACING = 15.0
const TILT = 10.0

pitches = [-5.0, -2.5, 0.0, 2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0]
winds = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0]

total = length(pitches) * length(winds)
println("Pitch sweep: $total configs (pitches=$pitches, winds=$winds)")

rows = []
for v in winds, p in pitches
    rots = [AutogyroRotor(R, 0.05, 2, 0.15, TILT, p, 5.0) for _ in 1:N]
    stack = AutogyroStack(rots, fill(SPACING, N), 0.004, ELEV)
    try
        θ, T, F, iters = solve_polygon_angles(
            stack.rotors, stack.section_lengths, ELEV, RHO, v;
            stall_delay=true, max_iter=30)
        anchor_t = T[end]
        v_eff = stack_effective_wind(stack.rotors, stack.section_lengths, RHO, v, ELEV)
        rpm = bem_autorotation_rpm(rots[1], RHO, v_eff[1])
        push!(rows, (wind_speed=v, blade_pitch=p, anchor_tension=anchor_t,
                     top_rpm=rpm, solver_iters=iters, converged=true))
    catch e
        push!(rows, (wind_speed=v, blade_pitch=p, anchor_tension=NaN,
                     top_rpm=NaN, solver_iters=0, converged=false))
    end
end

df = DataFrame(rows)
outpath = joinpath(@__DIR__, "results", "sweep_pitch_authority.tsv")
mkpath(dirname(outpath))
CSV.write(outpath, df; delim='\t')

# Summary: authority range at each wind speed
println("\nPitch authority (tension range across pitch sweep):")
for v in winds
    sub = df[(df.wind_speed.==v).&(df.converged.==true),:]
    if nrow(sub) > 0
        t_min = minimum(sub.anchor_tension)
        t_max = maximum(sub.anchor_tension)
        p_min = sub[argmin(sub.anchor_tension),:blade_pitch]
        p_max = sub[argmax(sub.anchor_tension),:blade_pitch]
        ratio = t_min > 0 ? t_max/t_min : Inf
        @printf "v=%4.1f m/s: %.0fN (@p=%.0f°) → %.0fN (@p=%.0f°)  range=%.1fx\n" v t_min p_min t_max p_max ratio
    end
end
println("Saved: $outpath")
