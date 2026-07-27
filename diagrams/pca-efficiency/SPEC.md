# SPEC.md — pca-efficiency

## Slug
`pca-efficiency`

## Title
Mass Efficiency Mapped onto Principal Component Space

## Data Source
`bem_full_sweep.tsv`. PC1/PC2 scores colored by tension_per_kg (mass efficiency).

## Message
[To be determined — where does the efficient frontier sit in reduced
dimensions? This is the funding pitch: "designs on this curve give best
bang-for-buck"]

## Chart type
Scatter — PC1 vs PC2, continuous color map by N/kg, Pareto-optimal points
highlighted.

## Generation
Julia + Makie `.jl` script.
