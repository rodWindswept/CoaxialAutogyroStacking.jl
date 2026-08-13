#!/usr/bin/env julia
# scripts/sweep_slat_authority.jl
# Compare slat-on vs slat-off across wind speeds 4-14 m/s.
# Output: scripts/results/sweep_slat_authority.tsv

using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking, DataFrames, CSV, Printf

const RHO = 1.225
const R = 3.0
const N = 3
const ELEV = 45.0
const SPACING = 15.0
const TILT = 10.0
const PITCH = 0.0

winds = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
slat_states = [false, true]

rows = []
for v in winds, slat in slat_states
    rots = [AutogyroRotor(R, 0.05, 2, 0.15, TILT, PITCH, 5.0, slat) for _ in 1:N]
    stack = AutogyroStack(rots, fill(SPACING, N), 0.004, ELEV)
    try
        θ, T, F, iters = solve_polygon_angles(
            stack.rotors, stack.section_lengths, ELEV, RHO, v;
            stall_delay=true, max_iter=30)
        anchor_t = T[end]
        v_eff = stack_effective_wind(stack.rotors, stack.section_lengths, RHO, v, ELEV)
        rpm = bem_autorotation_rpm(rots[1], RHO, v_eff[1])
        push!(rows, (wind_speed=v, slat_deployed=slat, anchor_tension=anchor_t,
                     top_rpm=rpm, solver_iters=iters, converged=true))
    catch e
        push!(rows, (wind_speed=v, slat_deployed=slat, anchor_tension=NaN,
                     top_rpm=NaN, solver_iters=0, converged=false))
    end
end

df = DataFrame(rows)
outpath = joinpath(@__DIR__, "results", "sweep_slat_authority.tsv")
mkpath(dirname(outpath))
CSV.write(outpath, df; delim='\t')

println("Slat authority at R=$(R)m N=$N:")
for v in winds
    off = df[(df.wind_speed.==v).&(df.slat_deployed.==false).&(df.converged.==true),:]
    on  = df[(df.wind_speed.==v).&(df.slat_deployed.==true).&(df.converged.==true),:]
    if nrow(off)>0 && nrow(on)>0
        t_off = off[1,:anchor_tension]
        t_on  = on[1,:anchor_tension]
        boost = (t_on/t_off - 1)*100
        @printf "v=%4.1f  off=%.0fN  on=%.0fN  Δ=+%.0f%%\n" v t_off t_on boost
    end
end
println("Saved: $outpath")
