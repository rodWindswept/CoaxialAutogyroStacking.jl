#!/usr/bin/env julia
# viability_charts.jl — Generate pretty viability gate charts (Phase 8.5)
#
# Usage: julia --project=. notebooks/viability_charts.jl
#
# Generates 4 charts showing physical viability of swept configurations:
#   1. viability_gates.png       — pass/fail bar chart (Re, noise, weight)
#   2. viability_tip_speed.png   — tip speed vs radius, noise limit
#   3. viability_reynolds.png    — tip Reynolds vs radius, trust threshold
#   4. viability_line_weight.png — line weight fraction distribution

using CoaxialAutogyroStacking
using CairoMakie
using DataFrames
using Statistics

CairoMakie.activate!(type = "png")

# ── Run sweep ──────────────────────────────────────────────────────────────

println("Running parameter sweep (8,640 evaluations)...")
df = parameter_sweep()   # default sweep grid matches Phase 8 spec
println("  $(nrow(df)) evaluations")

# ── Viability thresholds ───────────────────────────────────────────────────

const RE_MIN  = 5.0e5   # PCA-2 data trustworthy above this
const TIP_MAX = 120.0   # m/s — Mach 0.35 noise limit
const LINE_WT = 0.10    # max 10% of lift spent lifting the rope

# ── Compute per-config viability ───────────────────────────────────────────

df_groups = groupby(df, [:radius, :n_rotors, :spacing, :profile, :elevation])
viability = combine(df_groups) do sub
    max_tip  = maximum(sub.tip_speed)
    min_re   = minimum(sub.tip_reynolds)
    # Line weight fraction: mass_per_m * total_line_length * g * cos(elev)
    # divided by mean total_lift across wind speeds
    ld       = 0.004  # 4 mm Dyneema
    dens     = 970.0
    mpm      = line_mass_per_m(ld, dens)
    n_r      = first(sub.n_rotors)
    spacing  = first(sub.spacing)
    tot_len  = spacing * (n_r + 1)  # n_r segments + below bottom to anchor
    elev     = deg2rad(first(sub.elevation))
    lw_force = mpm * tot_len * 9.81 * cos(elev)
    mean_lift = mean(sub.total_lift)
    lw_frac = mean_lift > 0 ? lw_force / mean_lift : Inf

    (tip_speed     = max_tip,
     tip_reynolds  = min_re,
     line_wt_frac  = lw_frac,
     re_ok         = min_re >= RE_MIN,
     noise_ok      = max_tip <= TIP_MAX,
     weight_ok     = lw_frac <= LINE_WT,
     mean_tension  = mean(sub.anchor_tension),
     n_configs     = nrow(sub))
end

total = nrow(viability)
pass_re     = count(viability.re_ok)
pass_noise  = count(viability.noise_ok)
pass_weight = count(viability.weight_ok)
pass_all    = count(viability.re_ok .&& viability.noise_ok .&& viability.weight_ok)
fail_re     = total - pass_re
fail_noise  = total - pass_noise
fail_weight = total - pass_weight
fail_all    = total - pass_all

println("  Configurations: $total")
println("  Re gate:     $pass_re pass / $fail_re fail  ($(round(pass_re/total*100, digits=1))%)")
println("  Noise gate:  $pass_noise pass / $fail_noise fail  ($(round(pass_noise/total*100, digits=1))%)")
println("  Weight gate: $pass_weight pass / $fail_weight fail  ($(round(pass_weight/total*100, digits=1))%)")
println("  ALL gates:   $pass_all pass / $fail_all fail  ($(round(pass_all/total*100, digits=1))%)")

# ── Style constants ────────────────────────────────────────────────────────

const BLUE    = :steelblue3
const RED     = :indianred3
const GREEN   = :darkseagreen4
const ORANGE  = :darkorange3
const GREY    = :grey70
const WARN    = :gold3
const PASS    = :seagreen
const FAIL    = :tomato3

theme_viability = Theme(
    fontsize       = 14,
    backgroundcolor = :white,
    resolution     = (1000, 700),
)

# ═══════════════════════════════════════════════════════════════════════════
# CHART 1: PASS/FAIL GATE SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

println("Generating viability_gates.png...")

fig1 = Figure(; size = (1000, 650))
ax1 = Axis(fig1[1, 1],
    title  = "Phase 8.5 — Viability Gate Summary",
    subtitle = "$total swept configurations | $(round(pass_all/total*100, digits=1))% pass all three gates",
    ylabel = "Number of configurations",
    xticks = (1:4, ["Reynolds\n(Re ≥ $(Int(RE_MIN/1e3))k)", "Noise\n(tip < $(Int(TIP_MAX)) m/s)", "Line Weight\n(< $(Int(LINE_WT*100))% of lift)", "ALL GATES"]),
    ygridvisible = false,
)

colors_each = [PASS, PASS, PASS, PASS]
b1 = barplot!(ax1, 1:4, [pass_re, pass_noise, pass_weight, pass_all];
    color = PASS, label = "Pass", strokewidth = 1, strokecolor = :white)
b2 = barplot!(ax1, 1:4, [fail_re, fail_noise, fail_weight, fail_all];
    color = FAIL, label = "Fail", strokewidth = 1, strokecolor = :white,
    stack = [pass_re, pass_noise, pass_weight, pass_all])

# Annotate percentages
for (i, (p, f)) in enumerate(zip([pass_re, pass_noise, pass_weight, pass_all],
                                  [fail_re, fail_noise, fail_weight, fail_all]))
    text!(ax1, i, p/2, text = "$(round(p/total*100, digits=1))%",
        align = (:center, :center), color = :white, fontsize = 16, font = :bold)
    text!(ax1, i, p + f/2, text = "$(round(f/total*100, digits=1))%",
        align = (:center, :center), color = :white, fontsize = 14)
end

axislegend(ax1, position = :rt, framecolor = :transparent)
save("viability_gates.png", fig1)
println("  → viability_gates.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 2: TIP SPEED vs RADIUS (with noise limit)
# ═══════════════════════════════════════════════════════════════════════════

println("Generating viability_tip_speed.png...")

fig2 = Figure(; size = (1000, 650))
ax2 = Axis(fig2[1, 1],
    title  = "Tip Speed vs Rotor Radius",
    subtitle = "Noise gate: 120 m/s (Mach 0.35). Coloured by pass/fail.",
    xlabel = "Rotor radius (m)",
    ylabel = "Max tip speed (m/s)",
)

# Split by pass/fail for colour
pass_mask = viability.noise_ok
scatter!(ax2, viability.radius[pass_mask], viability.tip_speed[pass_mask];
    color = PASS, markersize = 12, alpha = 0.7, label = "Pass (≤120 m/s)")
scatter!(ax2, viability.radius[.!pass_mask], viability.tip_speed[.!pass_mask];
    color = FAIL, markersize = 12, alpha = 0.7, label = "Fail (>120 m/s)")

# Noise limit line
hlines!(ax2, [TIP_MAX]; color = WARN, linestyle = :dash, linewidth = 2,
    label = "Noise limit (120 m/s)")

# Trend line
r_uniq = sort(unique(viability.radius))
tip_mean = [mean(viability.tip_speed[viability.radius .== r]) for r in r_uniq]
lines!(ax2, r_uniq, tip_mean; color = :black, linewidth = 2.5, label = "Mean trend")

axislegend(ax2, position = :lt, framecolor = :transparent)
ylims!(ax2, 0, max(maximum(viability.tip_speed), TIP_MAX) * 1.1)
save("viability_tip_speed.png", fig2)
println("  → viability_tip_speed.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 3: TIP REYNOLDS vs RADIUS (with trust threshold)
# ═══════════════════════════════════════════════════════════════════════════

println("Generating viability_reynolds.png...")

fig3 = Figure(; size = (1000, 650))
ax3 = Axis(fig3[1, 1],
    title  = "Tip Reynolds Number vs Rotor Radius",
    subtitle = "Trust gate: Re ≥ 5×10⁵ for PCA-2 data validity. Coloured by pass/fail.",
    xlabel = "Rotor radius (m)",
    ylabel = "Min tip Reynolds number",
    yscale = log10,
)

scatter!(ax3, viability.radius[viability.re_ok], viability.tip_reynolds[viability.re_ok];
    color = PASS, markersize = 12, alpha = 0.7, label = "Pass (Re ≥ 5×10⁵)")
scatter!(ax3, viability.radius[.!viability.re_ok], viability.tip_reynolds[.!viability.re_ok];
    color = FAIL, markersize = 12, alpha = 0.7, label = "Fail (Re < 5×10⁵)")

hlines!(ax3, [RE_MIN]; color = WARN, linestyle = :dash, linewidth = 2,
    label = "Trust threshold (Re = 5×10⁵)")

re_mean = [mean(viability.tip_reynolds[viability.radius .== r]) for r in r_uniq]
lines!(ax3, r_uniq, re_mean; color = :black, linewidth = 2.5, label = "Mean trend")

axislegend(ax3, position = :lt, framecolor = :transparent)
save("viability_reynolds.png", fig3)
println("  → viability_reynolds.png")

# ═══════════════════════════════════════════════════════════════════════════
# CHART 4: COMBINED VIABILITY — RADIUS vs STACK COUNT HEATMAP
# ═══════════════════════════════════════════════════════════════════════════

println("Generating viability_heatmap.png...")

fig4 = Figure(; size = (1000, 650))
ax4 = Axis(fig4[1, 1],
    title  = "Viability by Radius × Stack Count",
    subtitle = "Fraction of configurations passing all 3 gates (Re + noise + line weight)",
    xlabel = "Rotor radius (m)",
    ylabel = "Stack count (N)",
    xticks = (sort(unique(viability.radius)), string.(sort(unique(viability.radius)))),
    yticks = (sort(unique(viability.n_rotors)), string.(sort(unique(viability.n_rotors)))),
    yreversed = true,
)

# Build heatmap data
radii    = sort(unique(viability.radius))
counts   = sort(unique(viability.n_rotors))
heatdata = zeros(length(counts), length(radii))

for (ri, r) in enumerate(radii)
    for (ci, n) in enumerate(counts)
        mask = (viability.radius .== r) .&& (viability.n_rotors .== n)
        subset = viability[mask, :]
        if nrow(subset) > 0
            all_ok = subset.re_ok .&& subset.noise_ok .&& subset.weight_ok
            heatdata[ci, ri] = sum(all_ok) / nrow(subset)
        end
    end
end

hm = heatmap!(ax4, radii, counts, heatdata;
    colormap = Reverse(:RdYlGn), colorrange = (0, 1))

# Annotate cells with percentages
for (ci, n) in enumerate(counts)
    for (ri, r) in enumerate(radii)
        val = heatdata[ci, ri]
        text!(ax4, r, n, text = val > 0 ? "$(round(val*100))%" : "–",
            align = (:center, :center), color = val > 0.5 ? :black : :white,
            fontsize = 13, font = :bold)
    end
end

Colorbar(fig4[1, 2], hm; label = "Fraction passing all gates")
save("viability_heatmap.png", fig4)
println("  → viability_heatmap.png")

println("\nDone. 4 charts generated:")
for f in ["viability_gates.png", "viability_tip_speed.png", "viability_reynolds.png", "viability_heatmap.png"]
    sz = filesize(f)
    println("  $f  ($(round(sz/1024, digits=1)) KB)")
end
