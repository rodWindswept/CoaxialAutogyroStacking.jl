#!/usr/bin/env julia
# Generate PCA-2 sweep data matching the BEM sweep grid for comparison
using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking
using DataFrames
using CSV

# Match the BEM sweep grid
radii = [1.5, 2.0, 3.0]
n_vals = [1, 2, 3, 4]
profiles = ["uniform", "top_draggy", "bottom_lifty", "graded"]
elevations = [45.0, 55.0]
winds = [6.0, 8.0, 10.0, 12.0]

df = parameter_sweep(
    radii=radii,
    stack_counts=n_vals,
    profiles=profiles,
    elevations=elevations,
    wind_speeds=winds,
    spacings=[15.0],
)

CSV.write("bem_full_sweep_pca2.tsv", df; delim='\t')
println("PCA-2 sweep generated: $(nrow(df)) rows")
println("Columns: $(names(df))")
