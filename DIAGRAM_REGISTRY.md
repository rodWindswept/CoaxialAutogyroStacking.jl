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
| bem-trpt-power | TRPT vs Yo-yo Power Generation | approved | 3/3 | bem_full_sweep.tsv | 2026-07-29 |

### R1 — Data Integrity Passed (11 new, 2026-07-31)

| Slug | Title | Stakeholder | Source |
|------|-------|------------|--------|
| bem-ld-sweep | L/D Ratio by Tilt Profile and Wind Speed | Aero | bem_full_sweep.tsv |
| bem-operating-envelope | Operating Wind Envelope by (R,N) | Operations | bem_full_sweep.tsv |
| bem-capacity-factor | Tension Above Threshold vs Wind Speed | Investor | bem_full_sweep.tsv |
| bem-parameter-sensitivity | Parameter Sensitivity: Which Knob Matters Most? | Research | bem_full_sweep.tsv |
| bem-power-density | TRPT per Swept Area | AWES | bem_full_sweep.tsv |
| bem-cost-per-newton | Cost per Newton: Economics of Scale | Investor | bem_full_sweep.tsv |
| bem-cost-tradeoff | Cost vs Tension Trade-off | Funding | bem_full_sweep.tsv |
| bem-trpt-per-rotor | TRPT kW per Rotor Unit | Manufacturing | bem_full_sweep.tsv |
| bem-pca2-vs-bem | PCA-2 Disk Model vs BEM v2.1 Comparison | Academic | bem_full_sweep.tsv + pca2 |
| bem-solver-convergence | Polygon Solver Convergence by Configuration | Research | bem_solver_iters.tsv |
| bem-stall-delay-impact | Snel Stall Delay: Net Effect on System Thrust | Aero | bem_snel_comparison.tsv |

### R1 — Prototype Conversion (14 new, 2026-07-31)

| Slug | Title | Converted From |
|------|-------|---------------|
| bem-pareto-profile | Pareto: Tension vs N/kg by Profile | bem_chart_1_pareto.png (ax1a) |
| bem-pareto-radius | Pareto: Tension vs N/kg by Radius | bem_chart_1_pareto.png (ax1b) |
| bem-pareto-count | Pareto: Tension vs N/kg by Stack Count | bem_chart_1_pareto.png (ax1c) |
| bem-pareto-elevation | Pareto: Tension vs N/kg by Elevation | bem_chart_1_pareto.png (ax1d) |
| viability-gates | Viability Gates Summary Table | viability_gates.png |
| viability-heatmap | Viability Heatmap: Tip Speed × Reynolds | viability_heatmap.png |
| viability-reynolds | Reynolds Number Distribution | viability_reynolds.png |
| viability-tip-speed | Tip Speed Distribution | viability_tip_speed.png |
| sweep-pareto-mass | Pareto: Tension vs Mass Efficiency (PCA-2) | sweep_pareto_tension_mass.png |
| sweep-pareto-cv | Pareto: Tension vs Gust Stability (PCA-2) | sweep_pareto_tension_cv.png |
| sweep-profile-nkg | Bar: N/kg by Tilt Profile (PCA-2) | sweep_profile_comparison.png (ax3a) |
| sweep-profile-cv | Bar: Gust Stability by Tilt Profile (PCA-2) | sweep_profile_comparison.png (ax3b) |
| sweep-heatmap | Heatmap: Tension by Radius × Stack Count (PCA-2) | sweep_heatmap_radius_stack.png |
| sweep-tension-vs-wind | Line: Anchor Tension vs Wind Speed (PCA-2) | sweep_tension_vs_wind.png |

### R1 — PCA Analysis (7, from bem_full_sweep.tsv, 2026-07-31)

Principal Component Analysis of 96 BEM configurations across 7 variables
(radius, n_rotors, tension, N/kg, RPM, tip_speed, Re). Identifies which
design levers actually drive variance — directly informs manufacturing
simplification, instrumentation, and funding priorities.

Key results: PC1=72.8%, PC2=16.8%, PC3=9.1% — a 2-component model captures 89.6% of variance.

| Slug | Title | Stakeholder | Question Answered |
|------|-------|------------|-------------------|
| pca-biplot | PCA Biplot: Configurations in PC1/PC2 Space | Design | Which (R,N,profile) combos cluster together? Three natural families emerge. |
| pca-scree | PCA Scree Plot: Variance Explained by Component | Funding | PC1 captures 72.8% — radius is the dominant design dimension. |
| pca-loadings | PCA Loadings: Variable Contributions to PC1/PC2 | Engineering | Radius and tension dominate PC1; N/kg dominates PC2. Stop tuning what doesn't matter. |
| pca-correlation | Correlation Heatmap: All Variable Pairs | Instrumentation | RPM∝tip_speed and tension∝N/kg — one sensor, not two. |
| pca-clusters | K-Means Clusters in PC Space (k=3) | Manufacturing | Three natural families — build 2-3 rotor sizes, not 96 configurations. |
| pca-manufacturing | Manufacturing Map: (R, N) Grid in PC Space | Tooling | R=3.0m N≥3 covers the Pareto front. Minimum viable product line: 1 size, 2 stack counts. |
| pca-efficiency | Mass Efficiency Mapped onto PC Space | Pitch Deck | One configuration on the efficient frontier. Build that one. |

### R1 — Standalone Scripts (5, already have PNGs + scripts, 2026-07-31)

| Slug | Title | Stakeholder | Source |
|------|-------|------------|--------|
| bem-radar | BEM Radar: Multi-variable Design Comparison | Design | bem_full_sweep.tsv |
| bem-force-breakdown | Rotor Force Components: Lift, Drag, Weight | Aero | bem_full_sweep.tsv |
| bem-radius-sensitivity | Radius Sensitivity: Tension vs Rotor Radius | Design | bem_full_sweep.tsv |
| bem-rpm-envelope | RPM Operating Envelope vs Wind Speed by Radius | Operations | bem_full_sweep.tsv |
| bem-stack-efficiency | Stack Efficiency: Tension vs Stack Count | Manufacturing | bem_full_sweep.tsv |

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
- **Prototype conversion complete** (2026-07-31): All 14 multi-panel notebook exports
  split into standalone `diagrams/<slug>/<slug>.py` scripts with individual PNG/PDF output.
  Source: bem_chart_1_pareto.png, viability_charts.jl, sweep_plots.jl.
