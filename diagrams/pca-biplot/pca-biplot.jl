#!/usr/bin/env julia
# pca-biplot.jl — PCA biplot of BEM configurations in PC1/PC2 space
# Run: julia --project=../.. pca-biplot.jl

using CSV, DataFrames, Statistics, MultivariateStats, CairoMakie

# ── Load & aggregate ───────────────────────────────────────────────────────
df = CSV.read("../../bem_full_sweep.tsv", DataFrame; delim='\t')
gdf = groupby(df, [:radius, :n_rotors, :profile, :elevation])
records = []
for g in gdf
    mt = mean(g.anchor_tension)
    mt <= 0 && continue
    push!(records, (
        radius         = g.radius[1],
        n_rotors       = g.n_rotors[1],
        profile        = g.profile[1],
        elevation      = g.elevation[1],
        mean_tension   = mt,
        tension_per_kg = mt / (g.n_rotors[1] * 5.0),
        mean_rpm       = mean(g.autorotation_rpm),
        mean_tip_speed = mean(g.tip_speed_bem),
        tip_reynolds   = 1.225 * mean(g.tip_speed_bem) * 0.15 / 1.81e-5,
    ))
end
n = length(records)

# ── Build data matrix & standardise ────────────────────────────────────────
cols = [:radius, :n_rotors, :mean_tension, :tension_per_kg, :mean_rpm, :mean_tip_speed, :tip_reynolds]
X = zeros(n, 7)
for j in 1:7
    col = cols[j]
    X[:, j] = [getfield(records[i], col) for i in 1:n]
end
X_std = similar(X)
for j in 1:7
    μ, σ = mean(X[:, j]), std(X[:, j])
    X_std[:, j] = (X[:, j] .- μ) ./ σ
end

# ── PCA ────────────────────────────────────────────────────────────────────
M = fit(PCA, X_std'; maxoutdim=2)
scores = MultivariateStats.transform(M, X_std')
loadings = M.proj
pc1_var = principalvars(M)[1] / tprincipalvar(M) * 100
pc2_var = principalvars(M)[2] / tprincipalvar(M) * 100

# ── Plot (portrait, tight crop) ────────────────────────────────────────────
PROFILE_COLORS = Dict(
    "uniform" => :blue, "top_draggy" => :orangered,
    "bottom_lifty" => :green, "graded" => :red,
)
PROFILE_MARKERS = Dict(
    "uniform" => :circle, "top_draggy" => :rect,
    "bottom_lifty" => :utriangle, "graded" => :diamond,
)

fig = Figure(size=(800, 1000), backgroundcolor=:white)
ax = Axis(fig[1, 1],
    title = "PCA of BEM Configurations: What Drives Performance Variance?",
    xlabel = "PC1 — Physical Scale & Performance ($(round(pc1_var,digits=1))% variance)",
    ylabel = "PC2 — Rotor Count ($(round(pc2_var,digits=1))% variance)",
    backgroundcolor = :white,
    xgridvisible = true, ygridvisible = true,
    xgridcolor = :gray90, ygridcolor = :gray90,
    titlesize = 14,
)

# Scatter configurations by profile
for prof in ["uniform", "top_draggy", "bottom_lifty", "graded"]
    idx = findall(r -> r.profile == prof, records)
    isempty(idx) && continue
    radii = [records[i].radius for i in idx]
    sizes = radii .^ 2 .* 12
    scatter!(ax,
        [scores[1, i] for i in idx],
        [scores[2, i] for i in idx],
        markersize = sizes,
        color = PROFILE_COLORS[prof],
        marker = PROFILE_MARKERS[prof],
        strokewidth = 0.5, strokecolor = :white,
        label = prof,
    )
end

# ── Loading arrows ─────────────────────────────────────────────────────────
arrow_scale = maximum(abs.(extrema(scores))) * 0.7
var_names = ["radius", "n_rotors", "mean tension", "tension per kg",
             "mean rpm", "mean tip speed", "tip Reynolds"]

# Draw the 5 collinear arrows with slight angular spread so they're visible
# as separate lines, not one merged blob
collinear_j = [1, 4, 5, 6, 7]  # radius, tension per kg, mean rpm, mean tip speed, tip Reynolds
spread_angles = [-0.03, -0.015, 0.0, 0.015, 0.03]  # radians
for (k, j) in enumerate(collinear_j)
    lx = loadings[j, 1] * arrow_scale
    ly = loadings[j, 2] * arrow_scale
    # Apply tiny angular spread so lines don't perfectly overlap
    angle = atan(ly, lx) + spread_angles[k]
    mag = sqrt(lx^2 + ly^2)
    slx = mag * cos(angle)
    sly = mag * sin(angle)
    shade = 0.3 + 0.1 * k  # slightly different grays
    arrows!(ax, [0.0], [0.0], [slx], [sly],
        tipwidth = 0.12, tiplength = 0.15,
        linewidth = 2.0, color = (shade, shade, shade, 0.7))
end

# n_rotors — distinct direction
arrows!(ax, [0.0], [0.0], [loadings[2,1] * arrow_scale], [loadings[2,2] * arrow_scale],
    tipwidth = 0.15, tiplength = 0.2,
    linewidth = 2.5, color = (:gray30, 0.7))
# mean_tension — distinct direction
arrows!(ax, [0.0], [0.0], [loadings[3,1] * arrow_scale], [loadings[3,2] * arrow_scale],
    tipwidth = 0.15, tiplength = 0.2,
    linewidth = 2.5, color = (:gray30, 0.7))

# n_rotors label
text!(ax, loadings[2,1] * arrow_scale * 1.15, loadings[2,2] * arrow_scale * 1.05,
    text = "n_rotors", fontsize = 10, color = :black, align = (:left, :center),
    strokecolor = :white, strokewidth = 3)

# mean_tension label
text!(ax, loadings[3,1] * arrow_scale * 0.85, loadings[3,2] * arrow_scale * 1.25,
    text = "mean tension", fontsize = 10, color = :black, align = (:center, :bottom),
    strokecolor = :white, strokewidth = 3)

# 5 collinear variables — combined label
collinear_label = "radius, tension per kg,\nmean rpm, mean tip speed,\ntip Reynolds"
text!(ax, loadings[1,1] * arrow_scale * 1.6, loadings[1,2] * arrow_scale * 0.6,
    text = collinear_label,
    fontsize = 9, color = :black, align = (:left, :center),
    strokecolor = :white, strokewidth = 3)
text!(ax, loadings[1,1] * arrow_scale * 1.6, loadings[1,2] * arrow_scale * 0.15,
    text = "(collinear — all driven by radius)",
    fontsize = 7.5, color = :gray40, align = (:left, :center),
    strokecolor = :white, strokewidth = 2)

# ── Size legend (bottom-left corner, clear of all data) ───────────────────
sizes_legend = [1.5^2 * 12, 2.0^2 * 12, 3.0^2 * 12]
sx_base = minimum(scores[1, :]) * 1.05
sy_base = minimum(scores[2, :]) * 1.15
for (j, (s, r)) in enumerate(zip(sizes_legend, [1.5, 2.0, 3.0]))
    scatter!(ax, [sx_base], [sy_base + j * 1.5], markersize = s,
        color = :gray60, marker = :circle, strokewidth = 0.5, strokecolor = :white)
    text!(ax, sx_base + 0.5, sy_base + j * 1.5, text = "R=$r",
        fontsize = 9, color = :gray30, align = (:left, :center),
        strokecolor = :white, strokewidth = 1)
end
text!(ax, sx_base, sy_base + 5.5,
    text = "Point area ∝\ndisk area (πR²)", fontsize = 8, color = :gray50,
    align = (:left, :center), strokecolor = :white, strokewidth = 1)

# ── Legend ──────────────────────────────────────────────────────────────────
axislegend(ax, position = :rb, framevisible = true, framecolor = :gray85,
    backgroundcolor = (:white, 0.85), fontsize = 10)

# ── Implications caption ───────────────────────────────────────────────────
# Short caption in a dedicated bottom row — guaranteed to fit
short_caption = "IMPLICATIONS: 7-D BEM design space collapses to 2-D. " *
    "PC1 (81%) = physical scale & performance. PC2 (19%) = rotor count. " *
    "All 4 tilt profiles overlap — tilt is a tuning parameter, not a design " *
    "differentiator. Manufacturing: reduce to 4x4 grid of (radius, N). " *
    "Build uniform tilt. Data: BEM v2.0, corrected polygon solver. SPEC.md §6.6."
caption_text = Label(fig[2, 1], short_caption,
    fontsize = 8.5, color = :black, font = :italic,
    halign = :left, valign = :top,
    tellwidth = true, tellheight = true,
    padding = (10, 30, 15, 30))

# ── Layout ─────────────────────────────────────────────────────────────────
colsize!(fig.layout, 1, Aspect(1, 0.75))  # portrait aspect
rowsize!(fig.layout, 1, Relative(0.80))
rowsize!(fig.layout, 2, Auto(0.20))

# ── Output ─────────────────────────────────────────────────────────────────
CairoMakie.activate!()
save("pca-biplot.png", fig, px_per_unit = 4.0)
save("pca-biplot.pdf", fig)
println("pca-biplot.png + pca-biplot.pdf generated")
println("  $(n) configurations, PC1=$(round(pc1_var,digits=1))%, PC2=$(round(pc2_var,digits=1))%")
