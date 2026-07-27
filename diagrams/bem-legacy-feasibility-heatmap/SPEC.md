# SPEC.md — bem-legacy-feasibility-heatmap

## Slug
`bem-legacy-feasibility-heatmap`

## Title
Tip Speed by Radius and Stack Count — Noise Gate

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27, corrected polygon solver).

The sweep covers 3 rotor radii (1.5, 2.0, 3.0 m) × 4 stack counts (1–4)
× 4 tilt profiles × multiple wind speeds. Tip speed is taken directly from
the BEM solver output (`tip_speed_bem` column).

## Variables

- **Rows (y-axis):** Stack count n_rotors (1, 2, 3, 4)
- **Columns (x-axis):** Rotor radius (1.5, 2.0, 3.0 m)
- **Color:** Mean tip speed across wind speeds.
  Red = high tip speed (approaching noise limit). Green = low (quiet).
  Colormap: RdYlGn_r (reversed: green=low, red=high).
- **Cell annotation:** PASS = all wind speeds ≤ 100 m/s (noise gate).
  FAIL = any wind speed exceeds 100 m/s.
- **Cell value:** Mean tip speed in m/s, displayed below PASS/FAIL.

## Plain-language explanation

Tip speeds above ~100 m/s create aerodynamic noise that may be unacceptable
for residential or recreational deployment. This heatmap checks whether any
(radius, stack_count) combination approaches that threshold. Each cell shows
the mean tip speed and a PASS/FAIL stamp based on whether ALL wind speeds in
that configuration stay at or below 100 m/s.

If the chart comes back all green, noise is not a constraint — the design
space is limited by something else (structural limits, tension, weight).

## Message

All 12 configurations stay well below the 100 m/s noise ceiling. Maximum
tip speed across the entire sweep is ~38 m/s. Noise is not a limiting
factor at these scales — the design space is constrained by tension and
manufacturing, not acoustics.

## Audience

- **Site planners** concerned about noise restrictions near residences.
- **Investors** asking "will these be loud?" — the answer is no.
- **Design engineers** checking whether they need to down-rate rotor
  diameter or RPM for acoustic reasons (they don't).

## Implication for manufacturing

Noise is not a constraint. Don't optimise for acoustics — optimise for
tension, mass efficiency, and manufacturability. The noise gate is fully
open across the entire parameter space.

## Figure type

Heatmap with annotated pass/fail markers. 2D grid: radius on x-axis,
stack count on y-axis, color-coded by mean tip speed.

## Visual encoding

- **Color:** RdYlGn_r (reversed: green=slow, red=fast). vmin=0, vmax=100.
- **Position:** x = radius, y = n_rotors.
- **Annotation:** "PASS" (green) or "FAIL" (dark red) per noise gate.
- **Cell value:** Tip speed in m/s below annotation.

## Dimensions

~6×5 inches. 3 radii × 4 stack counts = 12 cells.

## Generation

```bash
cd diagrams/bem-legacy-feasibility-heatmap
python3 bem-legacy-feasibility-heatmap.py
```

Requires: Python 3, matplotlib, numpy. Input: `../../bem_full_sweep.tsv`.
Output: `bem-legacy-feasibility-heatmap.png` (300dpi), PDF.

## Round 1 checks

- [ ] All 12 cells present
- [ ] Tip speed values match bem_full_sweep.tsv spot-checks
- [ ] PASS iff tip_speed ≤ 100 m/s for all wind speeds
- [ ] 0 negative tip speeds
- [ ] Axes labeled with units
- [ ] Colorbar present and labeled
- [ ] PASS/FAIL + value annotations readable
- [ ] Title states noise gate threshold
- [ ] Implications caption on chart, matches data
