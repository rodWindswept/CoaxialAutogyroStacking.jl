#!/usr/bin/env julia
# notebooks/bem_charts.jl — BEM sweep chart exploration (Rod's HANDOVER.md §3)
#
# Generates 5 chart types from bem_full_sweep.tsv:
#   1. Pareto frontier surfaces (3D: tension × N/kg × CV)
#   2. Feasibility heatmaps with Re/noise masking
#   3. Tension accumulation profiles along the line
#   4. Radial BEM loading — Snel 3D vs 2D CL(r/R)
#   5. Radar/spider comparisons of tilt profiles
#
# Usage: julia --project=. notebooks/bem_charts.jl

using CoaxialAutogyroStacking
using CairoMakie
using DataFrames
using CSV
using Statistics
using Printf

CairoMakie.activate!(type = "png")
const OUT = "bem_chart"

# ═══════════════════════════════════════════════════════════════════════════
# LOAD + POST-PROCESS
# ═══════════════════════════════════════════════════════════════════════════

println("Loading BEM sweep data...")
df = CSV.read("bem_full_sweep.tsv", DataFrame, delim='\t')
println("  $(nrow(df)) rows, $(ncol(df)) columns")

# Filter out non-viable rows (anchor_tension == 0 means rope-can't-push clamp)
df_viable = filter(:anchor_tension => t -> t > 0, df)
n_dropped = nrow(df) - nrow(df_viable)
println("  Dropped $n_dropped non-viable rows (T=0, rope-can't-push)")
println("  $(nrow(df_viable)) viable rows remaining")

# Compute Re from tip speed (assume chord=0.15m, rho=1.225, mu=1.8e-5)
const CHORD  = 0.15
const RHO    = 1.225
const MU     = 1.8e-5
const MASS   = 5.0  # kg per rotor
const RE_MIN = 5.0e5
const TIP_LIMIT = 120.0

df_v = df_viable
df_v.reynolds   = RHO .* df_v.tip_speed_bem .* CHORD ./ MU
df_v.re_ok      = df_v.reynolds .>= RE_MIN
df_v.noise_ok   = df_v.tip_speed_bem .<= TIP_LIMIT

# Group by configuration, compute figures of merit
gdf = groupby(df_v, [:radius, :n_rotors, :profile, :elevation])
fom = combine(gdf) do sub
    (mean_tension    = mean(sub.anchor_tension),
     tension_per_kg  = mean(sub.anchor_tension) / (first(sub.n_rotors) * MASS),
     tension_cv      = std(sub.anchor_tension) / mean(sub.anchor_tension),
     max_tension     = maximum(sub.anchor_tension),
     mean_rpm        = mean(sub.autorotation_rpm),
     mean_tip_speed  = mean(sub.tip_speed_bem),
     mean_re         = mean(sub.reynolds),
     all_re_ok       = all(sub.re_ok),
     all_noise_ok    = all(sub.noise_ok),
     viable          = all(sub.re_ok) && all(sub.noise_ok))
end

println("  $(nrow(fom)) unique configurations")
println("  Viable (Re + noise): $(count(fom.viable)) / $(nrow(fom))")

# ═══════════════════════════════════════════════════════════════════════════
# COLOUR PALETTE
# ═══════════════════════════════════════════════════════════════════════════

const PROFILE_COLORS = Dict(
    "uniform"       => :steelblue3,
    "top_draggy"    => :tomato3,
    "bottom_lifty"  => :darkseagreen4,
    "graded"        => :darkorange3,
)
const PROFILE_MARKERS = Dict(
    "uniform"       => :circle,
    "top_draggy"    => :diamond,
    "bottom_lifty"  => :utriangle,
    "graded"        => :star5,
)

profile_color(p) = get(PROFILE_COLORS, p, :grey60)
profile_marker(p) = get(PROFILE_MARKERS, p, :circle)

# ═══════════════════════════════════════════════════════════════════════════
# CHART 1: PARETO FRONTIER — Tension × N/kg × CV (coloured by profile)
# ═══════════════════════════════════════════════════════════════════════════

println("\n[1/5] Pareto frontier — tension vs N/kg...")

fig1 = Figure(size = (1100, 750))

# ── 1a: Tension vs N/kg, coloured by profile ──
ax1a = Axis(fig1[1, 1],
    xlabel = "Mean anchor tension (N)",
    ylabel = "Tension per rotor mass (N/kg)",
    title  = "BEM Sweep — Tension vs Mass Efficiency")

for prof in unique(fom.profile)
    mask = fom.profile .== prof
    scatter!(ax1a, fom.mean_tension[mask], fom.tension_per_kg[mask];
        color     = profile_color(prof),
        marker    = profile_marker(prof),
        markersize = 10,
        alpha     = 0.7,
        label     = prof)
end
axislegend(ax1a, position = :rb, framecolor = :transparent)

# ── 1b: Tension vs CV (gust stability), coloured by profile ──
ax1b = Axis(fig1[1, 2],
    xlabel = "Mean anchor tension (N)",
    ylabel = "Tension CV (lower = more stable)",
    title  = "BEM Sweep — Tension vs Gust Stability")

for prof in unique(fom.profile)
    mask = fom.profile .== prof
    scatter!(ax1b, fom.mean_tension[mask], fom.tension_cv[mask];
        color     = profile_color(prof),
        marker    = profile_marker(prof),
        markersize = 10,
        alpha     = 0.7)
end

# ── 1c: Pareto surface — radius × N on axes, tension as colour ──
ax1c = Axis(fig1[2, 1],
    xlabel = "Rotor radius (m)",
    ylabel = "Stack count",
    title  = "Max tension by radius × stack count")

radii  = sort(unique(fom.radius))
counts = sort(unique(fom.n_rotors))
heat1c = zeros(length(radii), length(counts))
for (ri, r) in enumerate(radii)
    for (ci, n) in enumerate(counts)
        mask = (fom.radius .== r) .&& (fom.n_rotors .== n)
        if any(mask)
            heat1c[ri, ci] = maximum(fom.max_tension[mask])
        end
    end
end
hm1c = heatmap!(ax1c, radii, counts, heat1c;
    colormap = :plasma, colorrange = (0, maximum(heat1c)))
Colorbar(fig1[2, 2], hm1c; label = "Max anchor tension (N)")
ax1c.yreversed = true

# ── 1d: Best config annotation ──
best = sort(fom, :mean_tension, rev=true)[1, :]
ax1d = Axis(fig1[2, 3],
    title  = "Best BEM configuration",
    xticklabelsvisible = false, yticklabelsvisible = false,
    xticksvisible = false, yticksvisible = false)
text!(ax1d, 0.5, 0.85,
    text = "R = $(best.radius) m\nN = $(best.n_rotors)\nProfile: $(best.profile)\nElev: $(best.elevation)°",
    align = (:center, :center), fontsize = 16)
text!(ax1d, 0.5, 0.45,
    text = "$(round(best.mean_tension, digits=0)) N\n$(round(best.tension_per_kg, digits=1)) N/kg\nCV = $(round(best.tension_cv, digits=3))",
    align = (:center, :center), fontsize = 14, color = :darkred)
xlims!(ax1d, 0, 1); ylims!(ax1d, 0, 1)

save("$(OUT)_1_pareto.png", fig1)
println("  → $(OUT)_1_pareto.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 2: FEASIBILITY HEATMAPS — Re / noise / combined
# ═══════════════════════════════════════════════════════════════════════════

println("[2/5] Feasibility heatmaps...")

fig2 = Figure(size = (1400, 500))

# ── 2a: Reynolds number heatmap ──
re_heat = zeros(length(radii), length(counts))
for (ri, r) in enumerate(radii)
    for (ci, n) in enumerate(counts)
        mask = (fom.radius .== r) .&& (fom.n_rotors .== n)
        if any(mask)
            re_heat[ri, ci] = mean(fom.mean_re[mask])
        end
    end
end

ax2a = Axis(fig2[1, 1],
    title  = "Mean tip Reynolds number",
    xlabel = "Radius (m)", ylabel = "Stack count",
    xticks = (radii, string.(radii)),
    yticks = (counts, string.(counts)))
hm2a = heatmap!(ax2a, radii, counts, re_heat;
    colormap = Reverse(:RdYlGn))
Colorbar(fig2[1, 2], hm2a; label = "Re")
ax2a.yreversed = true

# Annotate pass/fail
for (ci, n) in enumerate(counts)
    for (ri, r) in enumerate(radii)
        mask = (fom.radius .== r) .&& (fom.n_rotors .== n)
        if any(mask)
            ok = all(fom.all_re_ok[mask])
            txt = ok ? "✓" : "✗"
            text!(ax2a, r, n, text = txt,
                align = (:center, :center),
                color = ok ? :darkgreen : :darkred,
                fontsize = 18, font = :bold)
        end
    end
end

# ── 2b: Noise heatmap ──
tip_heat = zeros(length(radii), length(counts))
for (ri, r) in enumerate(radii)
    for (ci, n) in enumerate(counts)
        mask = (fom.radius .== r) .&& (fom.n_rotors .== n)
        if any(mask)
            tip_heat[ri, ci] = mean(fom.mean_tip_speed[mask])
        end
    end
end

ax2b = Axis(fig2[1, 3],
    title  = "Mean tip speed (m/s) — limit: $(Int(TIP_LIMIT)) m/s",
    xlabel = "Radius (m)", ylabel = "Stack count",
    xticks = (radii, string.(radii)),
    yticks = (counts, string.(counts)))
hm2b = heatmap!(ax2b, radii, counts, tip_heat;
    colormap = :YlOrRd, colorrange = (0, TIP_LIMIT))
Colorbar(fig2[1, 4], hm2b; label = "Tip speed (m/s)")
ax2b.yreversed = true

for (ci, n) in enumerate(counts)
    for (ri, r) in enumerate(radii)
        mask = (fom.radius .== r) .&& (fom.n_rotors .== n)
        if any(mask)
            text!(ax2b, r, n, text = "$(round(tip_heat[ri,ci], digits=0))",
                align = (:center, :center), fontsize = 11,
                color = tip_heat[ri,ci] > TIP_LIMIT * 0.7 ? :white : :black)
        end
    end
end

save("$(OUT)_2_feasibility.png", fig2)
println("  → $(OUT)_2_feasibility.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 3: TENSION ACCUMULATION PROFILES
# ═══════════════════════════════════════════════════════════════════════════

println("[3/5] Tension accumulation profiles...")

# Build the best stack and compute the profile
best_profile_tilts = CoaxialAutogyroStacking.TILT_PROFILES[best.profile](best.n_rotors)
rotors = [AutogyroRotor(best.radius, 0.05, 2, CHORD, t, 0.0, MASS)
          for t in best_profile_tilts]
stack = AutogyroStack(rotors, fill(15.0, best.n_rotors), 0.004, best.elevation)

wind_speeds = [4.0, 6.0, 8.0, 10.0, 12.0]
profiles = Dict()
for v in wind_speeds
    profiles[v] = stack_tension_profile(stack, RHO, v)
end

fig3 = Figure(size = (1000, 650))
ax3 = Axis(fig3[1, 1],
    xlabel = "Distance from anchor (m)",
    ylabel = "Cumulative tension (N)",
    title  = "Tension Accumulation — Best BEM Config (R=$(best.radius)m, N=$(best.n_rotors), $(best.profile))")

# x-axis: distance along line from anchor upward
# profile[1] = tension at topmost rotor (0), profile[end] = anchor
total_len = best.n_rotors * 15.0 + 5.0  # 15m spacing + 5m bottom extra
distances = range(total_len, 0, length = best.n_rotors + 1)

colors = cgrad(:viridis, length(wind_speeds))
for (i, v) in enumerate(wind_speeds)
    p = profiles[v]
    lines!(ax3, distances, p;
        color = colors[i], linewidth = 2.5,
        label = "$(Int(v)) m/s")
    scatter!(ax3, distances, p;
        color = colors[i], markersize = 8)
end

# Annotate rotor positions
for i in 1:best.n_rotors
    d = distances[i+1]
    vlines!(ax3, [d]; color = :grey60, linestyle = :dot, linewidth = 1)
    text!(ax3, d, -10, text = "R$(best.n_rotors-i+1)",
        align = (:center, :top), fontsize = 10, color = :grey40)
end
axislegend(ax3, position = :lt, framecolor = :transparent,
    title = "Wind speed")

save("$(OUT)_3_tension_profile.png", fig3)
println("  → $(OUT)_3_tension_profile.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 4: RADIAL BEM LOADING — Snel 3D vs 2D CL(r/R)
# ═══════════════════════════════════════════════════════════════════════════

println("[4/5] Radial BEM loading — Snel 3D vs 2D...")

# Compute radial loading for the best rotor at 8 m/s
r_best  = best.radius
n_bl    = 2
tilt    = best_profile_tilts[1]   # top rotor tilt
α_eff   = effective_alpha(AutogyroRotor(r_best, 0.05, n_bl, CHORD, tilt, 0.0, MASS),
                           best.elevation)
v_wind  = 8.0

# BEM stations along the blade
N_STATIONS = 20
stations   = range(0.2, 0.98, N_STATIONS)  # r/R from 0.2 to 0.98
cl_2d  = zeros(N_STATIONS)
cl_3d  = zeros(N_STATIONS)
a_vals = zeros(N_STATIONS)

omega  = 84.0 * 2π / 60  # rad/s — from BEM sweep at design point
v_tip  = omega * r_best

for (i, sr) in enumerate(stations)
    r_local = sr * r_best
    chord_local = CHORD  # constant chord for now

    # Solve BEM induction at this station
    a_result = try
        bem_induction(r_local, chord_local, r_best, omega, v_wind, α_eff, RHO, MU;
                       n_blades = n_bl)
    catch
        0.0
    end
    a_vals[i] = a_result

    # Local velocity and AoA
    v_axial  = v_wind * (1 - a_result)
    v_tan    = omega * r_local
    phi      = atan(v_axial, v_tan)
    alpha_local = rad2deg(phi)  # simplified — should use blade pitch + twist

    # 2-D CL from NACA 0012
    re_local = RHO * sqrt(v_axial^2 + v_tan^2) * chord_local / MU
    cl_2d[i] = naca0012_cl(deg2rad(alpha_local), re_local)
    cl_3d[i] = snel_cl_3d(cl_2d[i], alpha_local, omega * r_local / v_wind, chord_local / r_local)
end

fig4 = Figure(size = (1000, 650))
ax4 = Axis(fig4[1, 1],
    xlabel = "Normalised radius r/R",
    ylabel = "Lift coefficient CL",
    title  = "Radial Loading — Snel 3-D Correction (R=$(r_best)m, v=$(Int(v_wind)) m/s, αeff=$(round(α_eff,digits=1))°)")

lines!(ax4, stations, cl_2d;
    color = :steelblue3, linewidth = 2.5, label = "CL (2-D NACA 0012)")
lines!(ax4, stations, cl_3d;
    color = :tomato3, linewidth = 2.5, label = "CL,3D (Snel corrected)")

# Shade the Snel boost region
band!(ax4, stations, cl_2d, cl_3d;
    color = (:tomato3, 0.15))

# Mark root and tip regions
vspan!(ax4, 0.2, 0.35; color = (:gold, 0.1))
text!(ax4, 0.275, maximum(cl_3d) * 0.95,
    text = "Root region\n(+35% Snel boost)", align = (:center, :top),
    fontsize = 11, color = :darkorange3)
text!(ax4, 0.85, maximum(cl_3d) * 0.95,
    text = "Tip region\n(minimal boost)", align = (:center, :top),
    fontsize = 11, color = :grey50)

axislegend(ax4, position = :rt, framecolor = :transparent)
save("$(OUT)_4_radial_loading.png", fig4)
println("  → $(OUT)_4_radial_loading.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 5: RADAR / SPIDER — Tilt profile comparison
# ═══════════════════════════════════════════════════════════════════════════

println("[5/5] Radar comparison of tilt profiles...")

# Aggregate metrics per profile (at best radius × N)
best_r = best.radius
best_n = best.n_rotors
profile_mask = (fom.radius .== best_r) .&& (fom.n_rotors .== best_n)
pfom = fom[profile_mask, :]

# Normalise each metric to [0, 1] for radar plot
metrics = [:mean_tension, :tension_per_kg, :max_tension]
norm_vals = Dict()
for m in metrics
    vals = pfom[!, m]
    mn, mx = minimum(vals), maximum(vals)
    norm_vals[m] = mx > mn ? (vals .- mn) ./ (mx - mn) : zeros(length(vals))
end
# Invert CV so higher = better
cv_vals = pfom.tension_cv
cv_mn, cv_mx = minimum(cv_vals), maximum(cv_vals)
norm_cv = cv_mx > cv_mn ? 1.0 .- (cv_vals .- cv_mn) ./ (cv_mx - cv_mn) : zeros(length(cv_vals))

profiles_here = unique(pfom.profile)
n_metrics = 4  # tension, N/kg, max tension, 1/CV
angles = range(0, 2π, length = n_metrics + 1)[1:n_metrics]
metric_labels = ["Tension", "N/kg", "Max T", "Stability"]

fig5 = Figure(size = (900, 750))
ax5 = Axis(fig5[1, 1],
    title  = "Tilt Profile Comparison — R=$(best_r)m, N=$(best_n)",
    aspect = 1)

for (pi, prof) in enumerate(profiles_here)
    row = pfom[pfom.profile .== prof, :][1, :]
    vals = [
        norm_vals[:mean_tension][pi],
        norm_vals[:tension_per_kg][pi],
        norm_vals[:max_tension][pi],
        norm_cv[pi],
    ]
    poly_angles = [angles..., angles[1]]
    poly_vals   = [vals..., vals[1]]

    lines!(ax5, poly_angles, poly_vals;
        color = profile_color(prof), linewidth = 2.5, label = prof)
    scatter!(ax5, angles, vals;
        color = profile_color(prof), markersize = 12, marker = profile_marker(prof))
end

ax5.xticks = (angles, metric_labels)
ylims!(ax5, -0.1, 1.15)
hidedecorations!(ax5; ticks = false, ticklabels = false)
axislegend(ax5, position = :rb, framecolor = :transparent)

save("$(OUT)_5_radar.png", fig5)
println("  → $(OUT)_5_radar.png")

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

println("\nDone. 5 charts generated:")
for f in sort(filter(f -> startswith(f, OUT), readdir()))
    sz = filesize(f)
    println("  $f  ($(round(sz/1024, digits=1)) KB)")
end
println("\nBest BEM configuration:")
println("  R=$(best.radius) m, N=$(best.n_rotors), profile=$(best.profile), elev=$(best.elevation)°")
println("  Mean tension: $(round(best.mean_tension, digits=0)) N")
println("  N/kg: $(round(best.tension_per_kg, digits=1))")
println("  CV: $(round(best.tension_cv, digits=3))")
