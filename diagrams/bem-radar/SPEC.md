# SPEC.md — bem-radar

## Slug
`bem-radar`

## Title
Tilt Profile Radar Comparison — R=3.0m, N=4

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27, corrected polygon solver).

Aggregated by (radius, n_rotors, profile) across all wind speeds and
elevations. Best (R,N) configuration selected by mean anchor tension.
At that (R,N), the 4 tilt profiles are compared on normalized metrics.

## Variables

The 4 radar axes represent performance metrics, all normalized to [0,1]
across the 4 profiles at the best (R,N) configuration:

- **Tension:** Mean anchor tension across all wind speeds (N).
- **N/kg:** Tension per rotor mass — mass efficiency (N/kg).
- **Max T:** Maximum anchor tension at any wind speed (N).
- **Stability:** 1 / CV(tension) — inverted coefficient of variation.
  Higher = more consistent across wind speeds.

## Plain-language explanation

This radar chart answers: "Which tilt profile performs best, and by how much?"
It compares the four profiles at the best radius and stack count. Each axis
shows a performance metric normalized so 1.0 = best among profiles, 0.0 =
worst. A profile that fills the chart outward is better.

But the key finding is that all four profiles overlap heavily because the
absolute differences are tiny. Graded tilt scores best (838 N mean tension),
while uniform scores worst (809 N) — only a 3.5% spread. The radar makes
these small differences look dramatic because of normalization. The honest
interpretation: tilt profile barely matters.

## Message

Tilt profile is a fine-tuning parameter, not a primary design driver.
The performance spread across all four profiles is under 4%. Build uniform
tilt for manufacturing simplicity — the penalty is negligible. Graded tilt
edges ahead marginally but complicates the stack setup.

## Audience

- **Manufacturing engineers** deciding whether grading tilt is worth the
  assembly complexity.
- **Designers** setting tilt angles per rotor.
- **Investors** asking "does the tilt profile matter?"

## Implication for manufacturing

Uniform tilt is the pragmatic choice. Graded tilt adds complexity (different
tilt angles per rotor) for less than 4% performance gain. The radar chart
visually overstates differences due to normalization — check the raw values
in the caption to see the true scale.

## Figure type

Filled radar/spider chart. 4 axes, 4 profiles.

## Visual encoding

- **Position:** Angle around the circle = metric. Radius = normalized value.
- **Color:** 4 profile colors — blue (uniform), orange (top-draggy),
  green (bottom-lifty), red (graded).
- **Fill:** Semi-transparent fill helps distinguish overlapping polygons.

## Dimensions

~7×7 inches (square, to match polar geometry).

## Generation

```bash
cd diagrams/bem-radar
python3 bem-radar.py
```

Requires: Python 3, matplotlib, numpy. Input: `../../bem_full_sweep.tsv`.
Output: `bem-radar.png` (300dpi), PDF.

## Round 1 checks

- [ ] All 4 profiles at correct (R,N)
- [ ] Mean tension values match TSV spot-checks
- [ ] Normalization correct (0–1 across 4 profiles per metric)
- [ ] Stability = 1/CV, inverted correctly
- [ ] Axes labeled
- [ ] Legend present
- [ ] Caption on chart with absolute values
- [ ] Caption notes normalization effect (visual exaggeration)
