# HANDOVER — Diagram Standard (2026-07-27)

> For Cameron — new diagram quality pipeline for the project.

## What changed

Dad has established a 3-round HITL (Human-In-The-Loop) review pipeline for
all project diagrams. Every chart, figure, or diagram now goes through three
automated review rounds before publication. The pipeline is defined in the
`coaxial-diagram-registry` skill in Dad's Hermes agent.

## The standard

- **One diagram per figure.** No multi-panel layouts — each chart tells one story.
- **Each diagram gets its own directory** under `diagrams/<slug>/` with:
  - `SPEC.md` — ~1000 word specification (data source, variables, audience, message)
  - `<slug>.py` — Python script that generates the figure
  - `<slug>.tex` — TikZ/LaTeX source (if applicable)
  - `<slug>.png` — 300dpi raster output
  - `<slug>.pdf` — vector output
  - `IMPLICATIONS.md` — one paragraph on what the data shows and why it matters

## The 3 review rounds

Each diagram goes through three automated check rounds:

1. **Data Integrity** — values match source, axes have units, ranges are physical,
   colors map correctly, special characters render.
2. **Visual Clarity** — no label overlaps, max 3 visual channels, legend present,
   fonts ≥ 8pt, no clipping, white background.
3. **Communication** — title states the finding, implications paragraph present,
   readable by a non-expert, key message visible in 3 seconds.

After each round, Dad reviews and approves before the next round. Comments from
each round are used to edit the source files and regenerate outputs.

## The registry

`DIAGRAM_REGISTRY.md` in the repo root tracks every diagram through the
pipeline. Each row shows slug, title, status (prototype → R1 → R2 → R3 →
approved), data source, last check date, and open issues.

Five initial diagrams are suggested from the corrected BEM sweep:
1. `bem-pareto` — Pareto front: tension vs mass efficiency by profile
2. `bem-profile-comparison` — Bar chart: tension by tilt profile
3. `bem-radius-scaling` — Line chart: tension vs radius
4. `bem-tension-profile` — Stacked area: tension accumulation
5. `bem-chain-geometry` — Polygon chain side-view comparison

## What this means for your agent

When your agent is asked to create or update a chart, it should:
1. Check `DIAGRAM_REGISTRY.md` for the diagram's current status
2. Read `diagrams/<slug>/SPEC.md` for context
3. Follow the round checks appropriate to the current status
4. Update the registry after each round
5. Generate/regenerate `.png` and `.pdf` after edits

## Visual conventions (from ktd-chart-design)

- Max 3 visual channels per scatter plot (position, color, size)
- Bracketed labels: `[314 N, 86 RPM, graded]`
- Continuous red→amber→green for quality metrics
- Leader lines on 4-5 hero designs only
- White/clean background
- `standalone` LaTeX document class
- Both PDF (vector) and PNG (300dpi) per figure
