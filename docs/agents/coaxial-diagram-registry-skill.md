---
name: coaxial-diagram-registry
description: Track diagrams through 3 HITL rounds. One figure per chart.
---

# Coaxial Diagram Registry

Every diagram in this project is tracked through a registry (`DIAGRAM_REGISTRY.md`)
with a 3-round Human-In-The-Loop (HITL) review pipeline. No diagram is published
without completing all three rounds.

## Trigger

Use when the user asks to create, review, or iterate on any chart, figure, or
diagram for CoaxialAutogyroStacking.jl. Also triggered by "update diagrams" or
"regenerate figures."

## File structure per diagram

Each diagram lives in `diagrams/<slug>/` with these files:

```
diagrams/<slug>/
├── SPEC.md          # ~1000 word specification (see SPEC format below)
├── <slug>.py        # Python script that generates the figure (data loading + plotting)
├── <slug>.tex       # TikZ/LaTeX source (if applicable)  
├── <slug>.png       # 300dpi raster output
├── <slug>.pdf       # Vector output
└── IMPLICATIONS.md  # One paragraph on what the data shows and its significance
```

## SPEC.md format (mandatory sections)

Every SPEC.md must contain these sections in order. Target ~1000 words.

```markdown
# SPEC.md — <slug>

## Slug
`<slug>`

## Title
<Finding-oriented title, not just a description of what's plotted>

## Data Source
<Path to source file and date regenerated>
<List every column used with units and description>

## Aggregation
<How raw data is grouped/filtered/aggregated before plotting>
<Filter criteria and viability gates>

## Variables
<Table: Axis/Channel | Variable | Units | Description for every visual channel>

## Audience
<Who this diagram is for and how they'll use it>

## Message
<The one-sentence finding this diagram communicates>

## Chart type
<Scatter, bar, line, etc.>

## Visual encoding
<What each visual channel encodes and why>

## Annotation strategy
<Which points get labels, how they're chosen, where labels are placed>

## Related SPEC sections
<Cross-references to project documentation>

## Generation
<How to regenerate: command, dependencies>
```

Example SPEC.md for reference: see `diagrams/bem-pareto/SPEC.md`.

## Registry format

`DIAGRAM_REGISTRY.md` at repo root. Each diagram has one row:

```
| Slug | Title | Status | Round | Data Source | Last Check | Issues |
|------|-------|--------|-------|-------------|------------|--------|
| bem-pareto | Pareto Front: Tension vs Efficiency | R1 | 1/3 | bem_full_sweep.tsv | 2026-07-27 | label overlap |
```

Status values: `prototype`, `R1`, `R2`, `R3`, `approved`, `deprecated`

## The 3 HITL rounds

### Round 1: Data Integrity
Automated checks:
- Every plotted value matches source data (spot-check 5 random points)
- Axes are labeled with units
- Data ranges are physically plausible (no negative tensions, no RPM > 500)
- Color mapping is consistent with data values
- Superscripts/special characters render correctly

### Round 2: Visual Clarity
Automated checks:
- No label overlaps (bounding-box collision detection)
- Leader lines don't cross each other
- Leader lines MUST connect labels to their specific data points — no detached
  side panels or key tables that break the visual connection
- Labels MUST be placed in whitespace around data clusters — never on top of
  or obscuring data points
- At most 3 visual channels per plot (position, color, size)
- EVERY visual channel must have an on-chart legend: color/shape in the plot
  legend, size as a separate size legend with example markers at labeled sizes
- Font sizes ≥ 8pt at 300dpi output
- No clipped text or truncated labels — including the implications caption
  at the bottom of the figure. Every line of the caption must be fully visible
  within the image bounds. Verify by checking the last character of the
  caption renders completely.
- White/clean background (no dark themes for publication)
- Layout MUST be tightly cropped to content — portrait orientation preferred.
  Use fixed `subplots_adjust` values, NOT `bbox_inches="tight"` (which expands
  unpredictably when annotations extend beyond axes)

### Round 3: Communication
Automated checks:
- Title states the finding, not just the data
- IMPLICATIONS.md paragraph is present and substantive
- The implications paragraph MUST also appear on the chart itself as a caption
  below the plot area, integrated into the figure (not just as a separate file)
- A reader unfamiliar with the code can identify what each axis, color, shape,
  and size means without reading external documentation
- The key message is visible within 3 seconds of viewing
- Cross-reference to SPEC.md section is present and correct
- **Spacing and margins:** consistent, generous padding around all elements.
  No annotation touches the plot border or figure edge. Minimum 20px clear
  space between any text element and the frame edge. The implications caption
  has visible whitespace above and below. The title has breathing room from
  the top plot border. Leader-line labels have padding from axis spines.

At the end of each round, the agent records findings in the registry and
asks the user for approval before proceeding to the next round. Comments from
each round are used to edit the .py, .tex, .png, and .pdf files.

## The implications paragraph

Every diagram must have an `IMPLICATIONS.md` file containing exactly one
paragraph that answers:

1. What does this data show? (the finding)
2. Why does it matter? (the significance)
3. What action or decision does it inform? (the consequence)

Example:
> "The Pareto front shows that graded tilt profiles improve mass efficiency
> by 1-3% over uniform stacking at R=3.0m, but the advantage vanishes below
> R=2.0m where BEM thrust is too weak to bend the chain. This means graded
> stacking is only worth the mechanical complexity at large rotor radii.
> For the v3 mechanical design, we should target R≥2.5m and include tilt
> adjustability, but for smaller demonstrator units, uniform tilt is simpler
> and nearly as efficient."

## Diagram creation workflow

1. **Prototype** — User requests a new diagram. Agent creates the registry entry
   (status: `prototype`), writes SPEC.md, generates initial .py + .png.
2. **Round 1** — Agent runs data integrity checks, records issues, asks user
   for approval. If approved, status → `R1`.
3. **Round 2** — Agent runs visual clarity checks, edits files, regenerates
   .png/.pdf, asks user. If approved, status → `R2`.
4. **Round 3** — Agent runs communication checks, finalizes IMPLICATIONS.md,
   asks user. If approved, status → `R3`, then `approved`.
5. **User review** — After R3, user can request further improvements. Each
   improvement goes through the same 3-round cycle at the modified round.

The user can request new diagram prototypes be added to the registry at any time.

## Conventions (inherited from ktd-chart-design)

- Maximum 3 visual channels per scatter plot
- Bracketed shorthand labels: `[314 N, 86 RPM, graded]`
- Continuous red→amber→green spectrum for quality metrics (not discrete bands)
- Leader lines on 4-5 hero designs only
- White/clean background for publication
- `standalone` document class for LaTeX figures
- Both PDF (vector) and PNG (300dpi) generated per figure
- One diagram per figure — no multi-panel layouts

## Compilation

```bash
cd diagrams/<slug>
python <slug>.py          # generates data, may output intermediate CSV
pdflatex -interaction=nonstopmode <slug>.tex
pdftoppm -png -r 300 <slug>.pdf <slug>
mv <slug>-1.png <slug>.png
```

## Pitfalls (from bem-pareto HITL review)

- **Side panels break visual connection.** Do not move annotations to a
  separate right-hand panel or key table — the reader cannot tell which
  label refers to which point. Use leader lines from labels to data.
- **Labels on top of data.** Never place annotation boxes directly on top
  of data clusters, even with transparency. Place labels in empty whitespace
  regions and connect with leader lines.
- **Missing size legend.** If point size encodes data (e.g. radius, N),
  there MUST be an on-chart size legend showing example markers at each
  labeled size value. The reader cannot guess what size means.
- **`bbox_inches="tight"` expands unpredictably.** When annotations extend
  beyond the axes, tight bounding box inflates the canvas leaving large
  empty margins. Use fixed `figsize` + `subplots_adjust` for precise crop.
- **Implications must be on the chart.** The IMPLICATIONS.md file alone is
  not enough — the implications paragraph must appear as a caption integrated
  into the figure itself so it travels with the image.
- **HITL gates are real.** Do not advance rounds without explicit user
  approval. The human is the gate — present findings and wait for "approve"
  before moving to the next round.

## Adding a new diagram

```bash
mkdir -p diagrams/<slug>
# Agent creates SPEC.md, <slug>.py, IMPLICATIONS.md
# Agent generates <slug>.png and <slug>.pdf
# Agent adds row to DIAGRAM_REGISTRY.md
```
