#!/usr/bin/env julia
# Full BEM parameter sweep — standalone script
# Run: julia --project=. scripts/bem_full_sweep.jl

using CoaxialAutogyroStacking, DataFrames, DelimitedFiles, Dates

println("Starting full BEM sweep at ", now())
t_start = time()

df = parameter_sweep_bem(
    radii       = [1.5, 2.0, 3.0],
    stack_counts = [1, 2, 3, 4],
    spacings    = [15.0],
    profiles    = ["uniform", "top_draggy", "bottom_lifty", "graded"],
    wind_speeds = [6.0, 8.0, 10.0, 12.0],
    elevations  = [45.0, 55.0],
)

elapsed = time() - t_start
println("Done in ", round(elapsed, digits=1), "s — ", nrow(df), " rows")

# Save
writedlm("bem_full_sweep.tsv", Matrix(df), '\t')
header = join(names(df), "\t")
content = read("bem_full_sweep.tsv", String)
write("bem_full_sweep.tsv", header * "\n" * content)

println("Saved bem_full_sweep.tsv")

# Quick summary
for r in [1.5, 2.0, 3.0]
    sub = df[df.radius .== r .&& df.wind_speed .== 8.0, :]
    sub2 = sub[sub.n_rotors .== 2, :]
    if nrow(sub2) > 0
        best = sort(sub2, :anchor_tension, rev=true)[1, :]
        println("R=$(r)m N=2 best=$(best.profile) T=$(round(best.anchor_tension,digits=0))N RPM=$(round(best.autorotation_rpm,digits=0))")
    end
end

# Top 5 overall
top5 = sort(df[df.wind_speed .== 8.0, :], :anchor_tension, rev=true)[1:5, :]
println("\nTop 5 at 8 m/s:")
for row in eachrow(top5)
    println("  R=$(row.radius)m N=$(row.n_rotors) $(row.profile) elev=$(row.elevation)° T=$(round(row.anchor_tension,digits=0))N")
end
