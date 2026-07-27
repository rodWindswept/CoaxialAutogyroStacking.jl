# SPEC.md — pca-manufacturing

## Slug
`pca-manufacturing`

## Title
Manufacturing Map: (Radius, Stack Count) Grid in PC Space

## Data Source
`bem_full_sweep.tsv`. PC1/PC2 scores with (radius, n_rotors) as grid labels.

## Message
[To be determined — which grid points on the (R,N) matrix cover the Pareto
front? This is the minimum set of rotor sizes and stack configurations to
manufacture]

## Chart type
Scatter with grid overlay — PC1 vs PC2, points connected by (R,N) grid lines.

## Generation
Julia + Makie `.jl` script.
