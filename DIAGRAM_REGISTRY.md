# DIAGRAM_REGISTRY.md — CoaxialAutogyroStacking.jl

> Every diagram goes through 3 HITL rounds before publication.
> See `coaxial-diagram-registry` skill for the full workflow.

## Current Diagrams

| Slug | Title | Status | Round | Data Source | Last Check | Issues |
|------|-------|--------|-------|-------------|------------|--------|
| bem-pareto | No Pareto Trade-off: Tension vs Efficiency | R3 | 3/3 | bem_full_sweep.tsv | 2026-07-27 | — |

## Status Legend

- `prototype` — Initial creation, not yet reviewed
- `R1` — Passed data integrity check
- `R2` — Passed visual clarity check
- `R3` — Passed communication check
- `approved` — All 3 rounds complete, publication-ready
- `deprecated` — Superseded by a newer diagram

## Suggested initial diagrams

From the corrected BEM sweep (`bem_full_sweep.tsv`, 2026-07-27):

1. `bem-pareto` — Pareto front: anchor tension vs mass efficiency, colored by profile
2. `bem-profile-comparison` — Bar chart: tension by tilt profile at R=3.0m, N=4
3. `bem-radius-scaling` — Line chart: tension vs radius for uniform profile
4. `bem-tension-profile` — Stacked area: tension accumulation along the line for top 3 configs
5. `bem-chain-geometry` — Polygon chain side-view for top_draggy vs uniform vs graded
