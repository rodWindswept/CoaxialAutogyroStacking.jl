#!/usr/bin/env julia
# scripts/sweep_slat_full.jl
# Full-grid slat sweep — matches bem_overnight_sweep grid with slat on/off.
# 11,520 configs × 2 slat states = 23,040 configs.
# Output: scripts/results/sweep_slat_full.tsv

using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking, DataFrames, CSV, Printf, Dates

const RHO = 1.225
const LINE_DIA = 0.004
const ROTOR_MASS = 5.0
const HUB_RADIUS = 0.05
const N_BLADES = 2
const BLADE_CHORD = 0.15

radii        = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
stack_counts = [1, 2, 3, 4, 5]
spacings     = [5.0, 10.0, 15.0, 20.0]
profiles     = ["uniform", "top_draggy", "bottom_lifty", "graded"]
wind_speeds  = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
elevations   = [35.0, 45.0, 55.0, 65.0]

total = length(radii) * length(stack_counts) * length(spacings) *
        length(profiles) * length(wind_speeds) * length(elevations) * 2
println("Full slat sweep: $total configs")
println("Start: ", now())

t_start = time()
rows = []
completed = 0

function run_sweep()
    global completed, rows, t_start
    for R in radii, N in stack_counts, sp in spacings, prof in profiles,
        v in wind_speeds, elev in elevations, slat in [false, true]

        tilt_fn = get(CoaxialAutogyroStacking.TILT_PROFILES, prof, CoaxialAutogyroStacking.uniform_tilt)
        tilts = tilt_fn(N)
        rots = [AutogyroRotor(R, HUB_RADIUS, N_BLADES, BLADE_CHORD, tilts[i], 0.0, ROTOR_MASS, slat) for i in 1:N]
        section_lens = fill(sp, N)
        stack = AutogyroStack(rots, section_lens, LINE_DIA, elev)

        try
            θ, T, F, iters = solve_polygon_angles(
                stack.rotors, stack.section_lengths, elev, RHO, v;
                stall_delay=true, max_iter=30)
            anchor_t = T[end]
            v_eff = stack_effective_wind(stack.rotors, stack.section_lengths, RHO, v, elev)
            rpm = bem_autorotation_rpm(rots[1], RHO, v_eff[1])
            push!(rows, (radius=R, n_rotors=N, spacing=sp, profile=prof,
                         wind_speed=v, elevation=elev, slat_deployed=slat,
                         anchor_tension=anchor_t, top_rpm=rpm,
                         solver_iters=iters, converged=true))
        catch e
            push!(rows, (radius=R, n_rotors=N, spacing=sp, profile=prof,
                         wind_speed=v, elevation=elev, slat_deployed=slat,
                         anchor_tension=NaN, top_rpm=NaN,
                         solver_iters=0, converged=false))
        end

        completed += 1
        if completed % 1000 == 0
            elapsed = time() - t_start
            rate = completed / elapsed
            remaining = (total - completed) / rate / 60.0
            println("[$(Dates.format(now(),"HH:MM"))] $completed/$total ($(round(100*completed/total))%) rate=$(round(rate))/s ETA=$(round(remaining))min")
        end
    end
end

run_sweep()
elapsed = time() - t_start
df = DataFrame(rows)
outpath = joinpath(@__DIR__, "results", "sweep_slat_full.tsv")
mkpath(dirname(outpath))
CSV.write(outpath, df; delim='\t')

println("\nDone in $(round(elapsed/60))min — $(nrow(df)) rows")

# Slat boost summary by wind speed (R>=2.0m only, viable rotors)
d = df[(df.converged.==true).&(df.radius.>=2.0),:]
for v in wind_speeds
    off = d[(d.wind_speed.==v).&(d.slat_deployed.==false),:anchor_tension]
    on  = d[(d.wind_speed.==v).&(d.slat_deployed.==true),:anchor_tension]
    if length(off) > 0 && length(on) > 0
        boost = (mean(on) / mean(off) - 1) * 100
        @printf "v=%4.1f  mean boost: %+.0f%%  (off=%.0fN → on=%.0fN)\n" v boost mean(off) mean(on)
    end
end
println("Saved: $outpath")
