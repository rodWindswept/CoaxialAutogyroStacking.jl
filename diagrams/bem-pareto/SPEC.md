# SPEC.md — bem-pareto

## Slug
`bem-pareto`

## Title
No Pareto Trade-off: Anchor Tension and Mass Efficiency Are Co-linear

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27 with corrected polygon solver,
commit `473a316`). Tab-separated values, 384 rows after viability filtering,
header row with column names.

Columns used:

| Column | Units | Description |
|--------|-------|-------------|
| `radius` | m | Rotor disk radius (1.5, 2.0, 3.0) |
| `n_rotors` | — | Number of rotors in stack (1, 2, 3, 4) |
| `profile` | — | Tilt profile name: `uniform`, `top_draggy`, `bottom_lifty`, `graded` |
| `elevation` | deg | Line elevation angle (45, 55) |
| `wind_speed` | m/s | Freestream wind speed (6, 8, 10, 12) |
| `anchor_tension` | N | Cumulative tension at the anchor (bottom of stack) |
| `autorotation_rpm` | — | Rotor rotational speed at torque equilibrium |
| `tip_speed_bem` | m/s | Blade tip speed computed from polygon segment angles |

Columns NOT used by this diagram: `spacing` (fixed at 15 m), `autorotation_rpm`,
`tip_speed_bem`.

## Aggregation

Group raw rows by unique configuration key: `(radius, n_rotors, profile,
elevation)`. For each configuration, compute:

- `mean_tension` = arithmetic mean of `anchor_tension` across all 4 wind
  speeds (6, 8, 10, 12 m/s). Averaging across wind speeds captures the
  configuration's performance envelope rather than a single operating point.
- `tension_per_kg` = `mean_tension / (n_rotors × 5.0 kg)`, where 5.0 kg is
  the fixed rotor mass per unit. This is the mass efficiency — how many
  Newtons of lift each kilogram of rotor hardware produces.

Viability gate: configurations with `mean_tension ≤ 0` are excluded. These
are R=1.5m configurations where BEM thrust cannot overcome rotor weight
(BEM viability threshold, see SPEC.md §6.6).

This produces 96 aggregated configurations from the 384 raw rows
(4 radii × 4 counts × 4 profiles × 2 elevations = 128 combinations,
minus ~32 zero-tension R=1.5m configs at the two elevations).

All 4 wind speeds are included in every mean. The sweep script runs
6, 8, 10, 12 m/s by default; the 6 m/s values are mostly zero for
R=1.5m and contribute to the viability gate.

## Variables

| Channel | Variable | Units | Description |
|---------|----------|-------|-------------|
| X (position) | Mean anchor tension | N | Average cumulative lift across 6–12 m/s wind speeds. Raw output delivered to the kite turbine attachment point. |
| Y (position) | Tension per rotor mass | N/kg | Mass efficiency — lift per kilogram of rotor hardware. Higher means more lift from the same mass budget. |
| Color | Tilt profile | — | Discrete categories: uniform (blue), top-draggy (orange), bottom-lifty (green), graded (red). Profile determines how disk tilt δ varies across the stack. |
| Shape | Tilt profile | — | Redundant with color for accessibility: circle, square, triangle, diamond. |
| Size | Rotor disk area | m² | Point area ∝ radius² (∝ πR², the rotor disk area). Larger disks produce more thrust. R=1.5m, 2.0m, 3.0m shown in size legend. |

## Audience

Primary: Rod and Cameron — design-space exploration and decision-making for
the v3 mechanical design and KTD.jl integration.

Secondary: Academic readers (AWES Forum, conference papers) and investors.
The chart communicates that tilt profile optimization is a second-order
effect compared to simply maximizing rotor radius and stack count.

## Message

Tension and mass efficiency are co-linear — the configuration that produces
the most lift also produces it most efficiently per kilogram. A single
configuration (R=3.0m, N=4, graded, 839 N, 42.0 N/kg) dominates all others
on both objectives simultaneously. There is no Pareto trade-off to navigate.

## Chart type

2-D scatter plot. One figure only — no subplots, no small multiples.
Pareto-optimal point marked with a black star.

## Visual encoding

- **Position (x, y):** carries the primary comparison — tension vs efficiency.
  These are the two objectives being optimized.
- **Color + shape:** 4 discrete categories for tilt profile. Shape is
  redundant with color (circle/square/triangle/diamond) so the chart is
  readable in grayscale or for colorblind readers.
- **Size:** point area proportional to rotor disk area (πR²). This is the
  third visual channel — the maximum allowed by the convention. Size
  legend below the x-axis shows reference markers at R=1.5, 2.0, 3.0m.
- **Star marker:** the single Pareto-optimal configuration. Since the
  Pareto front is a single point (objectives are co-linear), a star
  replaces the usual front curve.

## Annotation strategy

Five configurations are annotated with leader lines:

1. **Pareto-optimal** (R=3.0m, N=4, graded, 839 N) — the dominant design.
2. **R=3.0m, N=2** (417 N) — shows the jump from N=2 to N=4 nearly doubles
   tension at the same radius.
3. **R=2.0m, N=4** (492 N) — the highest-tension configuration at the
   intermediate radius.
4. **R=2.0m, N=2** (241 N) — mid-tier reference.
5. **R=2.0m, N=1** (112 N) — lowest viable single-rotor tension.

Labels are placed in whitespace around the data clusters and connected
with straight leader lines. No labels are placed on top of data points.
Labels show: profile name, radius, rotor count, tension, and N/kg.

The tight cluster at R=3.0m, N=4 (all four profiles within 2% of each
other) is noted in the implications caption rather than annotated
individually, avoiding leader-line congestion.

## Related SPEC sections

- SPEC.md §6.3 — Key Findings from v1 PCA-2 sweep (original Pareto analysis)
- SPEC.md §6.6 — BEM Sweep v2.0, corrected 2026-07-27 (data source)
- SPEC.md §5.2 — Known limitations of v2 BEM model

## Generation

```bash
cd diagrams/bem-pareto
python3 bem-pareto.py
```

Requires: Python 3, matplotlib, numpy. Input: `../../bem_full_sweep.tsv`.
Output: `bem-pareto.png` (300dpi), `bem-pareto.pdf` (vector).
No LaTeX compilation needed — this is a pure matplotlib figure.

The implications caption must be fully visible within the image bounds.
Verify: the last line of the caption ends with "SPEC.md §6.6." and is not
clipped at the bottom edge.

Spacing requirements: minimum 20px clear space between any text element
and the figure edge. The implications caption has visible whitespace above
and below. Title has breathing room from the top plot border. Annotation
labels have padding from axis spines. No element touches the frame edge.
