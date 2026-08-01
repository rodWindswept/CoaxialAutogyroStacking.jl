# Chart 6: PCA Biplot — Design Parameters in PC1–PC2 Space

## Data Source

`bem_full_sweep.tsv` — 312 viable BEM configurations (anchor tension > 0),
projected into principal component space. Six numeric features (radius,
n_rotors, wind_speed, elevation, autorotation_rpm, tip_speed_bem) plus one
categorical feature (profile, one-hot encoded to 3 dummy variables) were
standardised before decomposition. The PCA was fitted with scikit-learn's
`sklearn.decomposition.PCA`; loadings arrows are the first two rows of
`pca.components_` scaled for visibility.

## What This Chart Shows

**Scatter points:** Each point is one BEM configuration, plotted by its PC1
and PC2 scores. Points are colour-coded by tilt profile (uniform, graded,
top_draggy, bottom_lifty) and shaped by marker to assist print and greyscale
readers. Clustering or overlap of profile colours is the main signal — if all
four colours intermingle, profile is not a major source of design-space
variance.

**Loading vectors:** Grey arrows radiating from the origin show how each
original feature projects onto the PC1–PC2 plane. Arrow length = magnitude of
that feature's contribution to the first two PCs. Arrow direction = which way
increasing that feature moves a configuration. Nearly horizontal arrows
(tip_speed_bem, autorotation_rpm, radius) load heavily on PC1; nearly vertical
arrows (wind_speed) load on PC2. The three profile dummy arrows are labelled
separately — their short lengths confirm profile is a weak differentiator.

**Annotated extremes:** The 3 configurations with highest and lowest PC1/PC2
scores are labelled with their radius, stack count, and wind speed. These
annotations ground the abstract PC axes in physical meaning: the rightmost
points are large-radius, high-RPM, high-wind configurations; the leftmost are
R=1.5m rotors that barely generate net tension.

**Axes:** PC1 (horizontal) captures 36% of total design-space variance — the
single largest axis of difference among configurations. PC2 (vertical) captures
19%. Together the biplot plane shows 55% of all structured variation.

## Key Findings

1. **PC1 is the "power" axis — radius, RPM, and tip speed dominate.** The
   tip_speed_bem loading arrow is the longest in the plot, aligned nearly flat
   along PC1. This singles out rotor tip speed as the most important single
   variable for distinguishing configurations. Radius and autorotation_rpm
   point in the same direction (all three are positively correlated),
   confirming that PC1 is essentially a composite "rotor size × speed" index.
   A configuration far to the right on PC1 has a big rotor spinning fast; a
   configuration far to the left has a small rotor at low tip speed.

2. **PC2 is the "wind" axis — independent of rotor geometry.** wind_speed
   loads almost purely on PC2 with negligible PC1 contribution. This means
   wind speed variation is orthogonal to rotor geometry choices — you get the
   same PC2 spread at every radius and stack size. This orthogonality is
   useful: it says that increasing wind speed moves configurations purely
   vertically, so you can read wind effects without confounding from rotor
   design.

3. **Profile is not a driver of design-space structure.** The three profile
   dummy arrows (top_draggy, graded, bottom_lifty — uniform is the
   reference category) are the shortest vectors in the biplot, barely visible.
   The four profile colours are thoroughly intermingled — there are no
   profile-only clusters. This is the geometric confirmation of the earlier
   finding that tilt profile produces ≤3.2% tension difference. PCA does not
   see profile as a meaningful source of variance because the numbers confirm
   it isn't one.

4. **Elevation loads weakly on PC2 alongside wind speed.** The elevation arrow
   is short and roughly parallel to wind_speed. This makes physical sense:
   elevation entered the BEM sweep as a parameter, but the polygon solver
   determines the line angle from force equilibrium, not from the elevation
   guess. The small remaining loading is a numerical artefact of how the
   solver initialises, not a real design sensitivity.

5. **R=1.5m is its own cluster on the left.** The annotated extremes on
   negative PC1 are all R=1.5m configurations. These are barely viable — they
   produce 2–34 N of anchor tension compared to hundreds of newtons at R=3.0m.
   They form a distinct low-power cluster well separated from the main body of
   the data. If the inference is "small rotors can't do the job," the biplot
   makes that visually obvious.

## Design Implications

**For dimensional analysis:** PC1 condenses three correlated variables
(radius, RPM, tip speed) into one number. This means you can rank
configurations on a single "power score" without needing to trade off radius
against RPM case by case. If a future optimisation loop needs a scalar
objective function, PC1 score is a ready-made composite that weights the
correct variables.

**For sensitivity studies:** The near-orthogonality of wind_speed (PC2) to
geometry (PC1) means wind sensitivity can be studied independently of rotor
design. A configuration's PC2 variance across wind speeds tells you its gust
response without confounding from its PC1 position.

**For experiment design:** If you need to down-select configurations for
higher-fidelity simulation (e.g., CFD or wake-coupled BEM), sampling evenly
across the PC1–PC2 plane gives you maximum coverage of the design space with
minimum runs. Pick configurations from the four quadrants of the biplot rather
than a regular grid of radius × wind_speed.

**For communicating to non-specialists:** The biplot reduces 9 dimensions to 2
while preserving 55% of the structure. It is the single best overview slide
for explaining what matters (rotor size/speed) and what doesn't (profile) in
the BEM parameter sweep.

## Limitations

- **55% is not 100%.** 45% of the structured variance lives in PCs 3–9. The
  biplot should not be the only analysis — PC3 (n_rotors, 15% variance) is
  practically important for stack design and is invisible on this plot.
- **Loading arrows are scaled for visibility, not quantitative comparison.**
  The arrow lengths are proportional to true loadings but multiplied by a
  visibility factor. Read the loadings chart (Chart 7) for exact numbers.
- **Profile dummy variables are not independent.** The three profile dummies
  sum to a constant (one-hot encoding), which introduces a linear dependency.
  PCA handles this gracefully (zero-variance directions get zero eigenvalue)
  but the profile loading arrows are not as interpretable as the numeric
  feature arrows.
- **PCA assumes linear relationships.** If the relationship between tip speed
  and tension is nonlinear (e.g., quadratic drag scaling at high Re), PCA
  will approximate it with a linear axis and lose some structure. A t-SNE or
  UMAP projection might reveal nonlinear clusters that PCA flattens.
- **312 rows is modest for PCA.** The decomposition is numerically stable
  (9 features << 312 samples) but the loadings have sampling uncertainty.
  Re-running the sweep with finer wind-speed and radius resolution would
  tighten the confidence on the arrow directions.
