# DIAGRAM_REGISTRY.md — CoaxialAutogyroStacking.jl

> Every diagram goes through 3 HITL rounds before publication.
> See `coaxial-diagram-registry` skill for the full workflow.
> One diagram per figure — multi-panel figures must be split.

## Current Diagrams

### Approved (7)

| Slug | Title | Status | Round | Source | Last Check |
|------|-------|--------|-------|--------|------------|
| bem-pareto | No Pareto Trade-off: Tension vs Efficiency | approved | 3/3 | bem_full_sweep.tsv | 2026-07-29 |
| bem-feasibility-radius | Re Viability Heatmap | approved | 3/3 | bem_full_sweep.tsv | 2026-07-29 |
| bem-feasibility-heatmap | Tip Speed Noise Gate | approved | 3/3 | bem_full_sweep.tsv | 2026-07-29 |
| bem-tension-accum | Tension Accumulation Along Line | approved | 3/3 | bem_full_sweep.tsv | 2026-07-29 |
| bem-tension-accum-v2 | Tension w/ Wind Gradient (α=0.14) | approved | 3/3 | bem_full_sweep.tsv | 2026-07-29 |
| bem-radial-loading | Radial BEM Loading: CL 2-D vs 3-D Snel | approved | 3/3 | bem_induction | 2026-07-29 |
| bem-trpt-power | TRPT vs Yo-yo Power Generation | approved | 1/3 | bem_full_sweep.tsv | 2026-07-29 |

### Prototypes — BEM Charts (3 remaining, from notebooks/bem_charts.jl)

| Slug | Title | Source PNG | Subplot |
|------|-------|-----------|---------|
| bem-pareto-profile | Pareto: Tension vs N/kg by Profile | bem_chart_1_pareto.png | ax1a |
| bem-pareto-radius | Pareto: Tension vs N/kg by Radius | bem_chart_1_pareto.png | ax1b |
| bem-pareto-count | Pareto: Tension vs N/kg by Stack Count | bem_chart_1_pareto.png | ax1c |
| bem-pareto-elevation | Pareto: Tension vs N/kg by Elevation | bem_chart_1_pareto.png | ax1d |

### Prototypes — Viability Charts (4, from notebooks/viability_charts.jl)

| Slug | Title | Source PNG |
|------|-------|-----------|
| viability-gates | Viability Gates Summary Table | viability_gates.png |
| viability-heatmap | Viability Heatmap: Tip Speed × Reynolds | viability_heatmap.png |
| viability-reynolds | Reynolds Number Distribution | viability_reynolds.png |
| viability-tip-speed | Tip Speed Distribution | viability_tip_speed.png |

### Prototypes — PCA-2 Sweep Charts (6, from notebooks/sweep_plots.jl)

| Slug | Title | Source PNG | Subplot |
|------|-------|-----------|---------|
| sweep-pareto-mass | Pareto: Tension vs Mass Efficiency (PCA-2) | sweep_pareto_tension_mass.png | — |
| sweep-pareto-cv | Pareto: Tension vs Gust Stability (CV) | sweep_pareto_tension_cv.png | — |
| sweep-profile-nkg | Bar: N/kg by Tilt Profile | sweep_profile_comparison.png | ax3a |
| sweep-profile-cv | Bar: Gust Stability (CV) by Tilt Profile | sweep_profile_comparison.png | ax3b |
| sweep-heatmap | Heatmap: Tension by Radius × Stack Count | sweep_heatmap_radius_stack.png | — |
| sweep-tension-vs-wind | Line: Anchor Tension vs Wind Speed | sweep_tension_vs_wind.png | — |

### Prototypes — PCA Analysis (7 new, from bem_full_sweep.tsv)

Principal Component Analysis of 96 BEM configurations across 7 variables
(radius, n_rotors, tension, N/kg, RPM, tip_speed, Re). Identifies which
design levers actually drive variance — directly informs manufacturing
simplification, instrumentation, and funding priorities.

| Slug | Title | Stakeholder | Question Answered |
|------|-------|------------|-------------------|
| pca-biplot | PCA Biplot: Configurations in PC1/PC2 Space | Design | Which (R,N,profile) combos cluster together? Are there natural design families? |
| pca-scree | PCA Scree Plot: Variance Explained by Component | Funding | Is this a 1-dimensional problem? If PC1 captures 80%+, optimize one knob. |
| pca-loadings | PCA Loadings: Variable Contributions to PC1/PC2 | Engineering | Which variables drive performance? Stop tuning things that don't matter. |
| pca-correlation | Correlation Heatmap: All Variable Pairs | Instrumentation | RPM∝tip_speed and tension∝N/kg — one sensor, not two. Measure one, compute the other. |
| pca-clusters | K-Means Clusters in PC Space by (R, N) | Manufacturing | How many distinct rotor sizes to build? Probably 2-3, not 96 configurations. |
| pca-manufacturing | Manufacturing Map: (R, N) Grid in PC Space | Tooling | Which (radius, stack_count) grid points cover the Pareto front? Minimum viable product line. |
| pca-efficiency | Mass Efficiency Mapped onto PC Space | Pitch Deck | "Every design on this curve gives best bang-for-buck." The efficient frontier in reduced dimensions. |

### New — Aero/Engineering (5, from bem_full_sweep.tsv)

| Slug | Title | Stakeholder | Question Answered |
|------|-------|------------|-------------------|
| bem-rpm-envelope | RPM Operating Envelope vs Wind Speed by Radius | Design | Where does autorotation work? |
| bem-force-breakdown | Rotor Force Components: Lift, Drag, Weight | Engineering | What % of force is useful lift? |
| bem-stack-efficiency | Stack Efficiency: Tension vs Stack Count | Design | Diminishing returns from N>4? |
| bem-radius-sensitivity | Radius Sensitivity: Tension vs Rotor Radius | Engineering | Nonlinear scaling of lift with R |
| bem-ld-sweep | L/D Ratio by Tilt Profile and Wind Speed | Aero | Optimal tilt across operating range |

### New — AWES-specific (3, from bem_full_sweep.tsv)

| Slug | Title | Stakeholder | Question Answered |
|------|-------|------------|-------------------|
| bem-operating-envelope | Operating Wind Envelope by (R,N) | Operations | Which combos fly in 4 m/s? 16 m/s? |
| bem-power-density | Power Density: TRPT per Swept Area | AWES | W/m² comparison across configs |
| bem-capacity-factor | Tension Above Threshold vs Wind Speed | Investor | How often does it deliver useful lift? |

### New — Financial/Business (3, from bem_full_sweep.tsv)

| Slug | Title | Stakeholder | Question Answered |
|------|-------|------------|-------------------|
| bem-cost-per-newton | Cost per Newton: Economics of Scale | Investor | What's the cheapest way to get 1 kN? |
| bem-trpt-per-rotor | TRPT kW per Rotor Unit | Manufacturing | Power contribution per device |
| bem-cost-tradeoff | Cost vs Tension Trade-off | Funding | Where's the budget sweet spot? |

### New — Academic (4, from bem_full_sweep.tsv)

| Slug | Title | Stakeholder | Question Answered |
|------|-------|------------|-------------------|
| bem-pca2-vs-bem | PCA-2 Disk Model vs BEM v2.1 Comparison | Academic | What did we gain from BEM? |
| bem-solver-convergence | Polygon Solver Convergence by Config | Research | Is the solver robust? |
| bem-parameter-sensitivity | Parameter Sensitivity: Input to Output | Research | Which knob matters most? |
| bem-stall-delay-impact | Snel Stall Delay: Net Effect on Thrust | Aero | Does 3-D correction matter at system level? |

## Status Legend

- `prototype` — Initial creation, not yet reviewed
- `R1` — Passed data integrity check
- `R2` — Passed visual clarity check
- `R3` — Passed communication check
- `approved` — All 3 rounds complete, publication-ready
- `deprecated` — Superseded by a newer diagram

## Notes

- **PCA ≠ PCA-2.** "PCA-2" (Pitcairn) is the 1930s autogyro rotor whose empirical
  data drives the v1 disk model. "PCA" (Principal Component Analysis) charts below
  are statistical decomposition of BEM sweep results. No relation.
- **bem-pareto** (approved) replaces `sweep-pareto-mass` — BEM data supersedes PCA-2.
  Consider deprecating `sweep-pareto-mass` and `sweep-pareto-cv` after BEM versions exist.
- **Multi-panel split:** `bem_chart_1_pareto.png` (4 subplots), `bem_chart_2_feasibility.png`
  (2 subplots), and `sweep_profile_comparison.png` (2 subplots) must be split into
  individual figures per the "one diagram per figure" rule.
- **Generation:** These originated as Makie figures in Pluto notebooks. Each should
  become a standalone `.jl` script in `diagrams/<slug>/<slug>.jl` for reproducibility.
