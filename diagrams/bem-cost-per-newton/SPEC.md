# SPEC.md — bem-cost-per-newton

## Slug
`bem-cost-per-newton`

## Title
Cost per Newton: Economics of Scale for Stacked Autogyro Rotors

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-31, BEM v2.1 polygon fix).
384 rows, tab-separated, 9 columns.

Columns used:
- `radius` (m): rotor radius
- `n_rotors` (unitless): number of rotors in the stack
- `profile`: tilt profile — only `graded` is used
- `elevation` (°): line elevation angle
- `wind_speed` (m/s): freestream wind
- `anchor_tension` (N): total line tension at anchor

## Aggregation
Filter: `profile == "graded"` and `anchor_tension > 0`.
Group by (radius, n_rotors). Compute mean anchor tension across all wind
speeds (6, 8, 10, 12 m/s) and elevations (45°, 55°, 65°).
Rows with zero tension are excluded — they represent non-viable
configurations where the BEM solver produced no thrust.

## Variables
| Axis/Channel | Variable | Units | Description |
|-------------|----------|-------|-------------|
| X-axis | Rotor radius | m | 2.0 and 3.0 m |
| Y-axis | Cost per newton | $/N | Estimated manufacturing cost ÷ mean tension |
| Color | Stack count N | — | 1=green, 2=blue, 3=orange, 4=red |
| Shape | Stack count N | — | circle, square, diamond, triangle |

Each point on the chart is one (radius, N) configuration. Lines connect
points with the same stack count N across radii. The chart only shows
R=2.0 m and R=3.0 m. R=1.5 m configurations are not plotted because
most of them produce zero tension and have no meaningful cost/N value.

## Cost Model
Simple manufacturing cost estimate for a complete stack:

- Base cost per rotor: $200 (hub, bearings, tailplane)
- Material cost per rotor: $300 × (R/1.5)² (blades, Dyneema — scales with
  disk area since blade length and line diameter grow with radius)
- Line cost: $50 per metre per section, × 10 m default spacing
- Assembly overhead: $500 (ground station, one-time)

Total cost = N × (200 + 300×(R/1.5)²) + N × 500 + 500

This is a rough magnitude estimate. Real manufacturing costs depend on
volume, labour rates, and material sourcing. The model assumes identical
rotors across the stack. Mixed-radius stacks are not modelled.

## Audience
Investor and funding — uses cost/N as a figure of merit to compare
configuration value. Also useful for manufacturing planning.

## Message
Cost per newton improves with both radius and stack count. The best
configuration is R=3.0 m, N=4 at $9.44/N. Single rotors are the least
cost-efficient at every radius.

### Plain-language explanation
This chart asks: for every dollar spent building the rotor stack, how
much pulling force do you get? Lower is better. Each marker is a
different rotor design — more rotors (N) and bigger blades (R) cost more
to build, but they also pull harder. The chart shows that adding rotors
almost always makes the cost-per-unit-of-force go down, because the
fixed overhead (ground station, assembly) gets spread across more
rotors. Bigger blades help too — a 3-metre blade gives more force per
dollar than a 2-metre blade. The cheapest option is four 3-metre rotors
at about $9.44 per newton. A single 2-metre rotor costs about $11.57
per newton — 23% more expensive for the same pulling force.

## Chart type
Connected scatter plot (lines connect same-N points across radii).

## Visual encoding
- X position: rotor radius
- Y position: cost per newton
- Color and shape together encode stack count N
- Dashed lines link same-N points to show the trend with radius

## Annotation strategy
The single best point (R=3.0 m, N=4, $9.44/N) is annotated with a label
box. No other annotations — the legend and axes are self-explanatory.

## Related SPEC sections
- SPEC.md §6.6: BEM sweep findings, graded profile optimisation
- SPEC.md §5.1: v1 limitations and viability thresholds

## Generation
```bash
cd diagrams/bem-cost-per-newton
python3 bem-cost-per-newton.py
```
Requires: Python 3, numpy, matplotlib. No Julia runtime needed.
Reads `../../bem_full_sweep.tsv` relative to the diagram directory.

## Status
R1 — data integrity verified (2026-07-31). Spec updated with verified
conclusions. Caption corrected to match actual data.
