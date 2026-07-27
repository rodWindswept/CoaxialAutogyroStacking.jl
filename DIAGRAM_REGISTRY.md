# DIAGRAM_REGISTRY.md — CoaxialAutogyroStacking.jl

> Every diagram goes through 3 HITL rounds before publication.
> See `coaxial-diagram-registry` skill for the full workflow.

## Current Diagrams

| Slug | Title | Status | Round | Data Source | Last Check | Issues |
|------|-------|--------|-------|-------------|------------|--------|
| bem-pareto | No Pareto Trade-off: Tension vs Efficiency | approved | 3/3 | bem_full_sweep.tsv | 2026-07-27 | — |
| bem-feasibility | Feasibility Heatmap: Radius × Wind Speed | prototype | 0/3 | bem_full_sweep.tsv | — | — |
| bem-tension-accumulation | Tension Accumulation Along Kite Line | prototype | 0/3 | bem_full_sweep.tsv | — | — |
| bem-radial-loading | Radial BEM Loading: CL 2-D vs 3-D Snel | prototype | 0/3 | bem_full_sweep.tsv | — | — |
| bem-radar | Radar Comparison: 5 Metrics by Profile | prototype | 0/3 | bem_full_sweep.tsv | — | — |
| sweep-heatmap | Heatmap: Anchor Tension by Radius × Stack Count | prototype | 0/3 | sweep_results.tsv | — | — |
| sweep-pareto-cv | Pareto: Tension vs Gust Stability (CV) | prototype | 0/3 | sweep_results.tsv | — | — |
| sweep-pareto-mass | Pareto: Tension vs Mass Efficiency (PCA-2) | prototype | 0/3 | sweep_results.tsv | — | — |
| sweep-profile-comparison | Bar Chart: Tension by Tilt Profile | prototype | 0/3 | sweep_results.tsv | — | — |
| sweep-tension-vs-wind | Line Chart: Anchor Tension vs Wind Speed | prototype | 0/3 | sweep_results.tsv | — | — |
| viability-gates | Viability Gates Overview | prototype | 0/3 | sweep_results.tsv | — | — |
| viability-heatmap | Viability Heatmap: Tip Speed × Reynolds | prototype | 0/3 | sweep_results.tsv | — | — |
| viability-reynolds | Reynolds Number Distribution | prototype | 0/3 | sweep_results.tsv | — | — |
| viability-tip-speed | Tip Speed Distribution | prototype | 0/3 | sweep_results.tsv | — | — |

## Status Legend

- `prototype` — Initial creation, not yet reviewed
- `R1` — Passed data integrity check
- `R2` — Passed visual clarity check
- `R3` — Passed communication check
- `approved` — All 3 rounds complete, publication-ready
- `deprecated` — Superseded by a newer diagram

## Notes

- **bem-pareto** replaces `sweep-pareto-mass` (BEM data supersedes PCA-2 sweep data).
  Consider deprecating `sweep-pareto-mass` after bem-pareto is published.
- **Generation approach:** These were originally Pluto notebooks. For the registry
  pipeline, each diagram should have a standalone `.jl` script (Julia + Makie)
  rather than Python, since the data pipeline and plotting library are already
  Julia-native. Pluto notebooks can serve as the interactive exploration layer;
  the `.jl` script is the reproducible build.
- **Data sources:** `bem_full_sweep.tsv` (corrected 2026-07-27) for BEM charts;
  `sweep_results.tsv` for PCA-2 sweep charts; viability data from sweep columns.
