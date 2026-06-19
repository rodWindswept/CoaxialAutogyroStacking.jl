#!/usr/bin/env julia --project=.
# notebooks/sweep_plots.jl
# Standalone plot generator — run with:
#   julia --project=. notebooks/sweep_plots.jl
#
# Generates PNG figures from the parameter sweep results.
# Interactive exploration: uncomment the `display(fig)` lines or use
# `julia --project=. -i notebooks/sweep_plots.jl` for a REPL session.

using CoaxialAutogyroStacking
using DataFrames
using CairoMakie
using Statistics
using Printf

# ── Run sweep ──────────────────────────────────────────────────────────────────

println("Running parameter sweep...")
df_raw = parameter_sweep()
fom = compute_figures_of_merit(df_raw)
println("Done: $(nrow(df_raw)) evaluations → $(nrow(fom)) configurations.\n")

# ── Figure 1: Pareto Front — Tension vs Mass Efficiency ─────────────────────

pf = pareto_front(fom, :mean_anchor_tension, :tension_per_kg)

fig1 = Figure(size=(900, 650))
ax1 = Axis(fig1[1, 1],
    xlabel="Mean Anchor Tension (N)",
    ylabel="Tension per Rotor Mass (N/kg)",
    title="Pareto Front — Tension vs Mass Efficiency")

scatter!(ax1, fom.mean_anchor_tension, fom.tension_per_kg,
    color=:gray60, markersize=5, alpha=0.25, label="All configurations")
scatter!(ax1, pf.mean_anchor_tension, pf.tension_per_kg,
    color=:red, markersize=9, label="Pareto optimal")

# Annotate extremes
biggest = sort(fom, :mean_anchor_tension, rev=true)[1, :]
most_efficient = sort(fom, :tension_per_kg, rev=true)[1, :]
text!(ax1, @sprintf("R=%.1f m, N=%d\n%.0f N", biggest.radius, biggest.n_rotors, biggest.mean_anchor_tension),
    position=(biggest.mean_anchor_tension + 300, biggest.tension_per_kg),
    fontsize=9, color=:blue)
text!(ax1, @sprintf("R=%.1f m, N=%d\n%.0f N/kg", most_efficient.radius, most_efficient.n_rotors, most_efficient.tension_per_kg),
    position=(most_efficient.mean_anchor_tension - 600, most_efficient.tension_per_kg + 5),
    fontsize=9, color=:darkgreen)
axislegend(ax1, position=:rb)
save("sweep_pareto_tension_mass.png", fig1)
println("Saved sweep_pareto_tension_mass.png")

# ── Figure 2: Pareto Front — Tension vs Gust Stability ─────────────────────

pf_cv = pareto_front(fom, :mean_anchor_tension, :tension_cv, sense=(:max, :min))

fig2 = Figure(size=(900, 650))
ax2 = Axis(fig2[1, 1],
    xlabel="Mean Anchor Tension (N)",
    ylabel="Tension CV (lower = more stable)",
    title="Pareto Front — Tension vs Gust Stability")

scatter!(ax2, fom.mean_anchor_tension, fom.tension_cv,
    color=:gray60, markersize=5, alpha=0.25, label="All configurations")
scatter!(ax2, pf_cv.mean_anchor_tension, pf_cv.tension_cv,
    color=:red, markersize=9, label="Pareto optimal")
axislegend(ax2, position=:rt)
save("sweep_pareto_tension_cv.png", fig2)
println("Saved sweep_pareto_tension_cv.png")

# ── Figure 3: Profile Comparison ────────────────────────────────────────────

profile_means = combine(groupby(fom, :profile), :tension_per_kg => mean => :mean_tpk)
profile_cvs  = combine(groupby(fom, :profile), :tension_cv => mean => :mean_cv)

fig3 = Figure(size=(900, 400))
ax3a = Axis(fig3[1, 1], title="Mean N/kg by Tilt Profile", ylabel="N/kg")
barplot!(ax3a, 1:4, profile_means.mean_tpk,
    color=[:gray50, :orange, :steelblue, :darkgreen])
ax3a.xticks = (1:4, profile_means.profile)

ax3b = Axis(fig3[1, 2], title="Mean CV by Tilt Profile", ylabel="CV (lower = more stable)")
barplot!(ax3b, 1:4, profile_cvs.mean_cv,
    color=[:gray50, :orange, :steelblue, :darkgreen])
ax3b.xticks = (1:4, profile_cvs.profile)
save("sweep_profile_comparison.png", fig3)
println("Saved sweep_profile_comparison.png")

# ── Figure 4: Radius × Stack Count Heatmap ──────────────────────────────────

heat_data = combine(groupby(fom, [:radius, :n_rotors]),
    :mean_anchor_tension => mean => :tension)

radii = sort(unique(heat_data.radius))
stacks = sort(unique(heat_data.n_rotors))
t_matrix = zeros(length(stacks), length(radii))
for (i, n) in enumerate(stacks)
    for (j, r) in enumerate(radii)
        row = heat_data[(heat_data.radius .== r) .& (heat_data.n_rotors .== n), :]
        t_matrix[i, j] = length(row.tension) > 0 ? row.tension[1] : NaN
    end
end

fig4 = Figure(size=(700, 500))
ax4 = Axis(fig4[1, 1],
    xlabel="Rotor Radius (m)", ylabel="Stack Count",
    title="Anchor Tension (N) — Radius × Stack Count")
hm = heatmap!(ax4, radii, stacks, t_matrix, colormap=:viridis)
Colorbar(fig4[1, 2], hm, label="Tension (N)")
save("sweep_heatmap_radius_stack.png", fig4)
println("Saved sweep_heatmap_radius_stack.png")

# ── Figure 5: Profile breakdown by wind speed ──────────────────────────────

ws_data = combine(groupby(df_raw, [:profile, :wind_speed]),
    :anchor_tension => mean => :mean_tension)

fig5 = Figure(size=(800, 500))
ax5 = Axis(fig5[1, 1],
    xlabel="Wind Speed (m/s)", ylabel="Mean Anchor Tension (N)",
    title="Tension vs Wind Speed by Profile")
for (p, c) in zip(["uniform", "top_draggy", "bottom_lifty", "graded"],
                   [:gray40, :orange, :steelblue, :darkgreen])
    sub = ws_data[ws_data.profile .== p, :]
    sort!(sub, :wind_speed)
    lines!(ax5, sub.wind_speed, sub.mean_tension, color=c, linewidth=2, label=p)
end
axislegend(ax5, position=:lt)
save("sweep_tension_vs_wind.png", fig5)
println("Saved sweep_tension_vs_wind.png")

# ── Print summary ────────────────────────────────────────────────────────────

println("\n" * "="^60)
println("SWEEP SUMMARY")
println("="^60)

println("\nTop 5 by N/kg:")
top5 = sort(fom, :tension_per_kg, rev=true)[1:5, :]
show(select(top5, :radius, :n_rotors, :spacing, :profile, :elevation,
    :mean_anchor_tension => ByRow(x -> round(x, digits=0)) => "Tension_N",
    :tension_per_kg => ByRow(x -> round(x, digits=1)) => "N_per_kg",
    :tension_cv => ByRow(x -> round(x, digits=3)) => "CV"),
    allrows=true, summary=false)

println("\nTop 5 by anchor tension:")
top5t = sort(fom, :mean_anchor_tension, rev=true)[1:5, :]
show(select(top5t, :radius, :n_rotors, :spacing, :profile, :elevation,
    :mean_anchor_tension => ByRow(x -> round(x, digits=0)) => "Tension_N",
    :tension_per_kg => ByRow(x -> round(x, digits=1)) => "N_per_kg",
    :tension_cv => ByRow(x -> round(x, digits=3)) => "CV"),
    allrows=true, summary=false)

println("\nProfile means:")
for p in ["uniform", "top_draggy", "bottom_lifty", "graded"]
    sub = fom[fom.profile .== p, :]
    m_tpk = mean(sub.tension_per_kg)
    m_cv  = mean(sub.tension_cv)
    println("  $(rpad(p, 14)) $(@sprintf("%6.1f", m_tpk)) N/kg   CV=$(round(m_cv, digits=4))")
end

println("\nPareto front: $(nrow(pf)) configs (tension vs N/kg)")
println("Pareto front: $(nrow(pf_cv)) configs (tension vs CV)")

println("\nSaved $(nrow(fom)) configurations to sweep_results.tsv")
println("Generated 5 figures in schematics/")
