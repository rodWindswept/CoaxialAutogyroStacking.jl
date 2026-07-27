# SPEC.md — pca-clusters

## Slug
`pca-clusters`

## Title
K-Means Clusters in PC Space by Rotor Radius and Stack Count

## Data Source
`bem_full_sweep.tsv`. K-means clustering (k=3–5) on PC1/PC2 scores.

## Message
[To be determined — expected: 2-3 natural clusters corresponding to
R=1.5/2.0/3.0m, confirming that radius is the primary design differentiator]

## Chart type
Scatter — PC1 vs PC2 with cluster ellipses, labeled by (R, N).

## Generation
Julia + Makie `.jl` script. Requires Clustering.jl.
