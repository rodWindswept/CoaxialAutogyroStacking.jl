# SPEC.md — pca-biplot

## Slug
`pca-biplot`

## Title
PCA Biplot: BEM Configurations in Principal Component Space

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27, corrected polygon solver).
96 aggregated configurations × 7 variables: radius, n_rotors, mean_tension,
tension_per_kg, autorotation_rpm, tip_speed_bem, tip_reynolds (computed as
ρ·v_tip·chord/μ). All variables standardized to zero mean, unit variance
before PCA.

## Aggregation
Same as `bem-pareto`: group by (radius, n_rotors, profile, elevation),
compute mean tension and N/kg across 4 wind speeds. Filter zero-tension
configs. Then run PCA on the 96×7 matrix.

## Variables
| Channel | Variable | Description |
|---------|----------|-------------|
| X | PC1 | First principal component — direction of maximum variance |
| Y | PC2 | Second principal component — orthogonal to PC1 |
| Color | Tilt profile | uniform, top_draggy, bottom_lifty, graded |
| Size | Rotor radius | Point area ∝ R² |
| Arrows | Variable loadings | Direction and magnitude of each original variable's contribution |

## Audience
Design — Rod and Cameron. Identifies natural design families and which
variables cluster together in performance space.

## Message
[To be determined by the data]

## Chart type
PCA biplot — scatter of configurations + arrow overlay of variable loadings.

## Related SPEC sections
- SPEC.md §6.6 — BEM sweep data source

## Generation
Julia + Makie `.jl` script. Requires MultivariateStats.jl for PCA.
