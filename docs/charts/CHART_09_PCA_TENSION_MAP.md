# Chart 9: PCA Tension Map — Design Space Coloured by Anchor Tension

## Data Source

`bem_pca_scores.tsv` — the same 312-configuration PCA projection as Charts
6–8. Each point's colour is its `anchor_tension` value in newtons, mapped to
a red-yellow-green perceptually-uniform colour scale (matplotlib `RdYlGn`).
Low tension is red, mid-range is yellow, high tension is green.

## What This Chart Shows

The same PC1–PC2 scatter plane as the biplot (Chart 6), but with a critical
difference: instead of colouring by profile to show group membership, this
chart colours by the output variable — anchor tension. The result is a "value
map" of the design space where colour directly encodes performance.

**Colour gradient interpretation:** Green points are high-tension
configurations (600–900 N), yellow are mid-range (200–600 N), red are
low-tension or barely viable (0–200 N). The spatial pattern of colour in PC
space reveals how tension varies with the principal components — and where the
best configurations live.

**Axes labels include interpretive hints:** The x-axis reads "PC1 — Rotor
Size & Speed" and the y-axis reads "PC2 — Wind Speed," connecting the abstract
PC scores back to their physical interpretations from the loadings analysis.

A colour bar on the right provides the newton-to-colour mapping.

This chart is the payoff slide: after decomposing the design space (Chart 6),
explaining what each axis means (Chart 7), and ranking individual predictors
(Chart 8), this chart shows the result — where in the design space does the
best performance live?

## Key Findings

1. **Tension increases smoothly and monotonically with PC1.** The colour
   gradient sweeps from red on the left through yellow in the centre to green
   on the right. There are no reversals, no "sweet spots" in the middle of the
   PC1 range that outperform the extremes. The relationship is PC1 ↑ → tension
   ↑, full stop. This confirms that PC1 is not just a descriptive axis — it
   is a de facto performance axis, and maximising PC1 is equivalent to
   maximising anchor tension (within the scope of this sweep).

2. **Tension increases with PC2 at fixed PC1 — but weakly.** At any vertical
   slice through the plot, points higher on PC2 (higher wind speed) are
   slightly greener than points lower down. The gradient is visible but much
   shallower than the left-to-right PC1 gradient. This is the visual
   equivalent of the correlation ranking: PC1 (r = 0.66) dominates, PC2
   (r = 0.16) adds a modest top-up. A configuration's PC1 position determines
   its performance tier; PC2 adjusts within that tier.

3. **The "green zone" is the far right, not the top right.** The highest
   tension configurations cluster in a tight band from mid-PC2 to high-PC2
   at extreme positive PC1. These are R=3.0m rotors at wind speeds of 10–12
   m/s — the biggest, fastest configurations in the sweep. The single best
   point on this map (highest anchor tension) sits at the intersection of
   maximum PC1 and maximum PC2.

4. **No high-PC1, low-PC2 green points exist.** The far-right, bottom of the
   plot is sparse and yellow at best. This means you cannot achieve high
   tension with a large fast rotor in low wind — even a 3m radius, 4-rotor
   stack at 6 m/s cannot match a 2m, 2-rotor stack at 12 m/s. Wind speed is
   a hard constraint: PC1 can compensate but not fully substitute for PC2.

5. **The red zone is exclusively R=1.5m.** Every red and red-orange point
   sits at negative PC1. These are all R=1.5m configurations regardless of
   wind speed or stack count. The R=1.5m cluster is so low-performing that it
   does not overlap the performance range of R=2.0m or R=3.0m at any wind
   speed. A 1.5m rotor at 12 m/s (maximum PC2) produces less tension than a
   2.0m rotor at 6 m/s (minimum PC2). Radius is not just the dominant lever
   — below 2.0m, it is a hard viability gate.

6. **The yellow transition zone is narrow.** The colour transition from red
   (poor) to green (good) happens over a relatively short PC1 range
   (roughly −1 to +2). This means the design space has a sharp "takeoff"
   threshold — below some critical rotor size/speed, the stack cannot
   overcome its own weight and line drag to produce useful net tension. Above
   that threshold, tension scales rapidly. This threshold behaviour is
   characteristic of systems where parasitic losses (rotor weight, line drag)
   must be overcome before net output appears.

## Design Implications

**For setting design targets:** The tension map gives you a visual answer to
"how good do I need to be?" If you want green-level performance (600+ N),
your configuration must reach a PC1 score of roughly +1.5 or higher. Working
backwards through the PC1 loadings, that means: R ≥ 2.5m, tip speed ≥ 80 m/s
(at 12 m/s wind), n_rotors ≥ 2. The map translates "high performance" from
an abstract goal to concrete parameter ranges.

**For identifying diminishing returns:** The green zone at extreme PC1 shows
points clustered tightly — R=3.0m at 10 m/s and R=3.0m at 12 m/s are nearly
the same colour. This suggests that beyond some PC1 threshold, further
increases in rotor size or wind speed produce smaller marginal tension gains.
The sweep doesn't go far enough right to confirm an asymptote, but the
clustering hints at one.

**For communicating the value of larger rotors:** The left-to-right colour
sweep makes the radius argument visually undeniable. No table of numbers, no
regression coefficient, no p-value is as convincing as a plot where every
green point is on the right and every red point is on the left. This is the
chart to show when someone asks "why 3 metres?"

**For outlier investigation:** Any green point unusually far from the main
green cluster, or any red point in a green-dominated region, is worth
investigating. It represents a configuration that performs better or worse
than its PC coordinates predict — possibly a bug, possibly an interesting
edge case (e.g., a profile that genuinely outperforms at a specific operating
point).

## Limitations

- **PC1 and PC2 capture 55% of variance.** The remaining 45% — including PC3
  (n_rotors, 15%) — is collapsed onto the same 2D plane. Two configurations
  with the same PC1 and PC2 but different n_rotors will plot at the same
  (x,y) but may have different tensions. The colour differences within a tight
  cluster partly reflect this hidden-dimension variance.
- **The colour map is perceptually uniform but not colourblind-friendly.**
  Red-green colour maps are problematic for the ~8% of males with
  red-green colour vision deficiency. A viridis or cividis colour map would
  be more accessible but less intuitively mapped to "red = bad, green = good."
- **Tension values are means across wind speeds collapsed into PC space.**
  The raw data has 4 wind speeds per configuration, but the PCA treats each
  (config × wind_speed) row as a separate point. This means the tension colour
  at each point is the tension at that specific wind speed, not the
  configuration mean. A point's colour can change across wind speeds even if
  its geometry is the same.
- **Extrapolation beyond the sweep bounds is not supported.** The green zone
  at maximum PC1 is the edge of the sampled space, not a true asymptote. The
  map cannot tell you whether R=3.5m would be greener still, or whether
  tension would plateau. The sweep bounds are the map bounds.
