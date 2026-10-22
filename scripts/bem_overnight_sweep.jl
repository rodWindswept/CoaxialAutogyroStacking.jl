#!/usr/bin/env julia
# scripts/bem_overnight_sweep.jl
# Comprehensive BEM sweep with wake interaction — overnight run.
# ~11,520 configs.  Output: scripts/results/bem_overnight_sweep.tsv

using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking
using DataFrames
using CSV
using Dates

# ── Sweep grid ──────────────────────────────────────────────────────────
radii        = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5]         # 6
stack_counts = [1, 2, 3, 4, 5]                         # 5
spacings     = [5.0, 10.0, 15.0, 20.0]                 # 4
profiles     = ["uniform", "top_draggy", "bottom_lifty", "graded"]  # 4
wind_speeds  = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0]      # 6
elevations   = [35.0, 45.0, 55.0, 65.0]                # 4

total = length(radii) * length(stack_counts) * length(spacings) *
        length(profiles) * length(wind_speeds) * length(elevations)

const RHO = 1.225
const LINE_DIA = 0.004
const ROTOR_MASS = 5.0
const HUB_RADIUS = 0.05
const N_BLADES = 2
const BLADE_CHORD = 0.15

println("BEM overnight sweep: $total configs")
println("Grid: radii=$(radii) N=$(stack_counts) spacings=$(spacings)")
println("      profiles=$(profiles) winds=$(wind_speeds) elevations=$(elevations)")
println("Start: ", now())

t_start = time()
rows = []
completed = 0

# Wrapped in a function to avoid soft-scope issues in Julia 1.12
function run_sweep()
    global completed, rows, t_start
    for R in radii, N in stack_counts, sp in spacings, prof in profiles,
        v in wind_speeds, elev in elevations

    # Build rotors with tilt profile
    tilt_fn = get(CoaxialAutogyroStacking.TILT_PROFILES, prof, CoaxialAutogyroStacking.uniform_tilt)
    tilts = tilt_fn(N)
    rotors_vec = AutogyroRotor[]
    for i in 1:N
        push!(rotors_vec, AutogyroRotor(R, HUB_RADIUS, N_BLADES, BLADE_CHORD,
                                        tilts[i], 0.0, ROTOR_MASS))
    end
    section_lens = fill(sp, N)
    stack = AutogyroStack(rotors_vec, section_lens, LINE_DIA, elev)

    try
        θ, T, F, iters = solve_polygon_angles(
            stack.rotors, stack.section_lengths, elev, RHO, v;
            stall_delay=true, max_iter=30)
        anchor_t = T[end]

        # Estimate top rotor RPM for tip-speed analysis
        v_eff = stack_effective_wind(stack.rotors, stack.section_lengths,
                                     RHO, v, elev)
        rpm = bem_autorotation_rpm(rotors_vec[1], RHO, v_eff[1])

        push!(rows, (radius=R, n_rotors=N, spacing=sp, profile=prof,
                     wind_speed=v, elevation=elev,
                     anchor_tension=anchor_t, top_rotor_rpm=rpm,
                     solver_iters=iters, converged=true))
    catch e
        push!(rows, (radius=R, n_rotors=N, spacing=sp, profile=prof,
                     wind_speed=v, elevation=elev,
                     anchor_tension=NaN, top_rotor_rpm=NaN,
                     solver_iters=0, converged=false))
    end

    completed += 1
    if completed % 500 == 0
        elapsed = time() - t_start
        rate = completed / elapsed
        remaining_min = (total - completed) / rate / 60.0
        println("[$(Dates.format(now(), "HH:MM:SS"))] $completed/$total ",
                "($(round(100*completed/total, digits=1))%) ",
                "rate=$(round(rate, digits=1))/s ETA=$(round(remaining_min, digits=0))min")
    end
end  # for loop
end  # function run_sweep

run_sweep()

elapsed = time() - t_start
df = DataFrame(rows)

outpath = joinpath(@__DIR__, "results", "bem_overnight_sweep.tsv")
mkpath(dirname(outpath))
CSV.write(outpath, df; delim='\t')

n_conv = sum(df.converged)
println("\nDone in $(round(elapsed/60, digits=1)) min — $(nrow(df)) rows ($n_conv converged)")

# Quick summary
for v in sort(unique(df.wind_speed))
    sub = df[(df.wind_speed .== v) .& (df.converged .== true), :]
    if nrow(sub) > 0
        best = sort(sub, :anchor_tension, rev=true)[1, :]
        println("v=$(v) m/s: R=$(best.radius)m N=$(best.n_rotors) $(best.profile) ",
                "elev=$(best.elevation)° T=$(round(best.anchor_tension,digits=0))N")
    end
end
println("Saved: $outpath")
