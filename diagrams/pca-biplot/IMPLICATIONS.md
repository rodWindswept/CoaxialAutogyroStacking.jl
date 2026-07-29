# IMPLICATIONS.md — pca-biplot

Principal Component Analysis reveals that the 7-dimensional BEM design
space collapses to 2 dimensions explaining 89.7% of variance. PC1 (72.8%)
is a physical-scale axis dominated by tip speed, Reynolds number, and mass
efficiency. PC2 (16.9%) captures rotor count effects.

The design problem is simpler than it appears. Radius and rotor count
explain 90% of what matters. Tilt profile does not create distinct design
families in PC space — all four profiles overlap completely.

## Significance

- The design space is effectively 2-dimensional. Optimize radius and N.
- Manufacturing complexity can be reduced to a 4×4 grid of (R, N) choices.
- Tilt profile is not a structural differentiator in PC space.

## Consequence

- Focus engineering effort on radius and stack count, not tilt profile.
- Instrumentation: tension, tip speed, and N/kg are co-linear — fewer
  sensors needed.
- Investors: the design problem is tractable. Two knobs drive 90% of
  performance variance.
