# SPEC.md — pca-scree

## Slug
`pca-scree`

## Title
PCA Scree Plot: Variance Explained by Principal Component

## Data Source
`bem_full_sweep.tsv`. PCA on 96 configurations × 7 variables.

## Message
[To be determined — if PC1 captures 80%+ variance, the design space is
effectively one-dimensional]

## Chart type
Bar chart — % variance explained per component + cumulative line.

## Generation
Julia + Makie `.jl` script.
