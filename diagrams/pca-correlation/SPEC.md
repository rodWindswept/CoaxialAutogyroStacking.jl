# SPEC.md — pca-correlation

## Slug
`pca-correlation`

## Title
Correlation Heatmap: All Variable Pairs in BEM Sweep

## Data Source
`bem_full_sweep.tsv`. Pearson correlation matrix of 7 variables.

## Message
[To be determined — expected: RPM and tip_speed are perfectly correlated
(mechanically linked); tension and N/kg are highly correlated (co-linear)]

## Chart type
Heatmap — 7×7 correlation matrix with values.

## Generation
Julia + Makie `.jl` script.
