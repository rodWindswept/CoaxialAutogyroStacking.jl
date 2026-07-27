# IMPLICATIONS.md — pca-biplot

Principal Component Analysis reveals that the 7-dimensional BEM design space
collapses to just 2 dimensions explaining 100% of variance — the design
problem is far simpler than it appears. PC1 (81.1%) is a physical-scale axis
dominated by tip speed, Reynolds number, and mass efficiency: larger, faster
rotors score higher regardless of profile. PC2 (18.9%) is a pure rotor-count
axis: adding rotors moves designs vertically without changing their PC1
character. All four tilt profiles overlap completely with no visible
clustering, confirming statistically what bem-pareto showed pairwise — tilt
profile is a <2% effect. For manufacturing, this means the engineering
problem reduces to two decisions: pick a rotor radius and a stack count.
The tilt profile can be fixed at uniform without meaningful performance loss,
collapsing a 96-configuration design space into a 4×4 grid of (radius, N)
combinations. For funding: the design space is one-dimensional in practice
(PC1 captures 81%), so optimization effort should focus on the single knob
that matters — rotor radius.
