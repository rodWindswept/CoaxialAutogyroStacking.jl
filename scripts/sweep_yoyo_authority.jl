#!/usr/bin/env julia
# scripts/sweep_yoyo_authority.jl
# Yo-yo reeling authority: sweep elevation angle as proxy for line length.
# Models wind shear (1/7 power law) and vertical velocity from reeling.
# Output: scripts/results/sweep_yoyo_authority.tsv

using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking, DataFrames, CSV, Printf

const RHO = 1.225
const R = 3.0
const N = 3
const SPACING = 15.0
const TILT = 10.0
const PITCH = 0.0

# Reference: wind at 100m altitude, 1/7 power law
const H_REF = 100.0      # reference height (m)
const LINE_LEN = 200.0    # nominal line length (m)

# Sweep over elevation angles (proxy for line length)
# Low angle = long line, high altitude = stronger wind
# High angle = short line, low altitude = weaker wind
elevations = [5.0, 15.0, 25.0, 35.0, 45.0, 55.0, 65.0, 75.0, 85.0]
wind_refs  = [6.0, 8.0, 10.0, 12.0, 14.0]  # wind at H_REF

# Reeling speeds (vertical component, m/s). Positive = reeling IN (descending).
# Zero = steady-state (no reeling).
reel_speeds = [0.0, 1.0, 2.0, 3.0]

total = length(elevations) * length(wind_refs) * length(reel_speeds)
println("Yo-yo sweep: $total configs")

function wind_at_altitude(z, v_ref, h_ref=H_REF)
    """Wind speed at altitude z using 1/7 power law."""
    z = max(z, 1.0)
    return v_ref * (z / h_ref)^(1.0/7.0)
end

rows = []
for elev in elevations, v_ref in wind_refs, v_reel in reel_speeds
    # Altitude = line_length * sin(elevation)
    altitude = LINE_LEN * sind(elev)
    v_wind = wind_at_altitude(altitude, v_ref)

    # Vertical reel velocity modifies effective wind angle at rotors
    # Descent adds upward component → increases effective AoA
    # Ascent (negative v_reel) reduces effective AoA
    # Model as: effective wind vector = (v_wind * cos(elev), v_wind * sin(elev) + v_reel)
    v_eff = sqrt((v_wind * cosd(elev))^2 + (v_wind * sind(elev) + v_reel)^2)
    # Effective elevation of the wind vector
    elev_eff = atand(v_wind * sind(elev) + v_reel, v_wind * cosd(elev))

    rots = [AutogyroRotor(R, 0.05, 2, 0.15, TILT, PITCH, 5.0) for _ in 1:N]
    stack = AutogyroStack(rots, fill(SPACING, N), 0.004, elev_eff)

    try
        θ, T, F, iters = solve_polygon_angles(
            stack.rotors, stack.section_lengths, elev_eff, RHO, v_eff;
            stall_delay=true, max_iter=30)
        anchor_t = T[end]
        push!(rows, (elevation=elev, v_ref=v_ref, v_reel=v_reel,
                     altitude=round(altitude,digits=0), v_wind=round(v_wind,digits=1),
                     v_eff=round(v_eff,digits=1), elev_eff=round(elev_eff,digits=1),
                     anchor_tension=anchor_t, solver_iters=iters, converged=true))
    catch e
        push!(rows, (elevation=elev, v_ref=v_ref, v_reel=v_reel,
                     altitude=round(altitude,digits=0), v_wind=round(v_wind,digits=1),
                     v_eff=NaN, elev_eff=NaN,
                     anchor_tension=NaN, solver_iters=0, converged=false))
    end
end

df = DataFrame(rows)
outpath = joinpath(@__DIR__, "results", "sweep_yoyo_authority.tsv")
mkpath(dirname(outpath))
CSV.write(outpath, df; delim='\t')

# ── Summary ────────────────────────────────────────────────────────────
println("\nYo-yo authority — steady-state (v_reel=0): tension range from reeling")
for v_ref in wind_refs
    sub = df[(df.v_ref.==v_ref).&(df.v_reel.==0.0).&(df.converged.==true),:]
    if nrow(sub) > 1
        t_lo = minimum(sub.anchor_tension)
        t_hi = maximum(sub.anchor_tension)
        e_lo = sub[argmin(sub.anchor_tension),:elevation]
        e_hi = sub[argmax(sub.anchor_tension),:elevation]
        ratio = t_lo > 0 ? t_hi/t_lo : Inf
        @printf "v_ref=%4.1f  %.0fN (@%.0f°) → %.0fN (@%.0f°)  range=%.1fx\n" v_ref t_lo e_lo t_hi e_hi ratio
    end
end

println("\nYo-yo authority — with reeling (v_reel=2 m/s descent):")
for v_ref in wind_refs
    static = df[(df.v_ref.==v_ref).&(df.v_reel.==0.0).&(df.elevation.==45.0).&(df.converged.==true),:]
    reeling = df[(df.v_ref.==v_ref).&(df.v_reel.==2.0).&(df.elevation.==45.0).&(df.converged.==true),:]
    if nrow(static)>0 && nrow(reeling)>0
        t_s = static[1,:anchor_tension]
        t_r = reeling[1,:anchor_tension]
        @printf "v_ref=%4.1f  static=%.0fN  reeling=%.0fN  Δ=%+.0f%%\n" v_ref t_s t_r (100*(t_r/t_s-1))
    end
end

# Power estimate for winch
println("\nWinch power estimate (R=3m N=3 elev=45° v_reel=2 m/s):")
for v_ref in wind_refs
    sub = df[(df.v_ref.==v_ref).&(df.v_reel.==2.0).&(df.elevation.==45.0).&(df.converged.==true),:]
    if nrow(sub) > 0
        tension = sub[1,:anchor_tension]
        power = tension * 2.0  # P = F * v_reel
        @printf "v_ref=%4.1f  T=%.0fN  P_reel=%.0fW\n" v_ref tension power
    end
end

println("Saved: $outpath")
