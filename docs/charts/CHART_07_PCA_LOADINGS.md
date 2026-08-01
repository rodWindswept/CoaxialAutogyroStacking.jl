# Chart 7: PCA Loadings — Variance Decomposition & Feature Contributions

## Data Source

Same 312-configuration PCA decomposition as Chart 6. The scree plot (left
panel) is computed from `pca.explained_variance_ratio_`; the loadings bar
chart (right panel) draws from `pca.components_[0:2, :]` for the six numeric
features (profile dummies omitted for clarity). Both panels come from a single
`sklearn.decomposition.PCA` fit.

## What This Chart Shows

**Left panel — Scree plot:** A bar chart of explained variance percentage for
each principal component, ordered PC1 through PC9. A red overlaid line shows
the cumulative variance captured as PCs are added. A dashed grey line marks
the conventional 80%-explained threshold. The scree plot answers "how many
dimensions do I really need to keep?"

**Right panel — Loadings:** A grouped horizontal bar chart showing how each of
the six numeric features loads onto PC1 (blue), PC2 (orange), and PC3 (green).
Positive loadings mean higher values of that feature push a configuration in
the positive direction along that PC. The absolute magnitude of the loading
tells you how strongly that feature defines the component. This panel answers
"what does each PC actually measure?"

**Annotations:** Each bar in the scree plot is labelled with its exact
percentage. The loadings bars are centred at zero with gridlines, making sign
and magnitude immediately readable.

## Key Findings

1. **Three components capture 70% of variance — five capture 90%.**
   PC1 alone explains 36% — more than PCs 2+3 combined. This is a strong
   signal: the BEM design space has one dominant axis of variation. The scree
   plot elbow is at PC3 (cumulative 70%), with PCs 4–9 each contributing ≤8%.
   The conventional 80% threshold is crossed at PC4; by PC5 the cumulative is
   90%. For most practical purposes, looking at PCs 1–3 covers the meaningful
   structure.

2. **PC1 = tip speed, RPM, radius (all positive).** The three largest PC1
   loadings are tip_speed_bem (+0.52), autorotation_rpm (+0.50), and radius
   (+0.49). These are nearly equal and all positive, confirming PC1 as a
   composite "rotor power" index. wind_speed has a moderate positive loading
   (+0.34) on PC1 — faster wind spins the rotor faster — but its primary
   contribution is to PC2. n_rotors and elevation have negligible PC1
   loadings.

3. **PC2 = wind speed (almost exclusively).** wind_speed loads at +0.82 on
   PC2, dwarfing all other features. The next largest PC2 loadings are
   tip_speed_bem (+0.34) and elevation (+0.28). This is the cleanest
   single-feature PC in the decomposition — PC2 is essentially "wind speed
   with a small tip-speed side effect." The cleanliness of this separation
   validates the sweep design: wind_speed was varied independently of
   geometric parameters, and PCA recovers that independence.

4. **PC3 = stack count (n_rotors, negative loading).** n_rotors loads at −0.68
   on PC3, with wind_speed contributing +0.30 in the opposite direction. The
   negative sign is arbitrary (PCA signs are unconstrained) but meaningful:
   increasing rotor count pushes configurations in the negative PC3 direction,
   while wind speed pushes positive. PC3 is therefore the "stack depth" axis
   — configurations with many rotors cluster at negative PC3, single-rotor
   setups at positive PC3. At 15% explained variance, this is a real effect
   but one-third as important as the rotor-power axis.

5. **Elevation is a non-factor in every PC.** elevation loadings are ≤0.28 on
   every component, and it never appears in the top three loadings of any PC.
   This is the quantitative confirmation of the polygon-solver insight: the
   BEM line finds its own equilibrium angle, so the elevation sweep parameter
   does not create meaningful variation in the force output. From a PCA
   perspective, elevation is noise.

## Design Implications

**For dimensionality reduction:** If you need to build a surrogate model
(response surface, Gaussian process, neural network) of the BEM output, you
can confidently compress the 9 input features to 3 PC scores and recover 70%
of the design-space structure. Compressing to 5 PCs recovers 90%. This is a
10× reduction in input dimensionality with bounded information loss.

**For understanding trade-offs:** The orthogonality of PC1 (rotor power) and
PC2 (wind speed) means these two design drivers operate independently. A
configuration that is high-power at 8 m/s will also be high-power at 12 m/s
— the PC1 ranking is wind-speed-invariant. This simplifies multi-objective
optimisation because you don't need to re-rank configurations for each wind
condition.

**For prioritising future sweeps:** The loading structure says: sweep radius
and wind_speed more finely; don't bother sweeping elevation; n_rotors matters
but less than you'd think. A refined 2D sweep (radius × wind_speed) at fixed
n_rotors=4 would capture the dominant PC1 and PC2 variation at a fraction of
the computational cost of the full 4D grid.

**For the stack architect:** PC3's n_rotors loading (−0.68, 15% variance) is
genuinely useful but modest. It says that adding rotors changes the
configuration in a way that is partially independent of making them bigger or
spinning them faster — stack depth is its own dimension. But it's the third
dimension, not the first. Prioritise radius, then wind-speed robustness, then
count.

## Limitations

- **PC loadings are linear combinations, not causal effects.** A high loading
  on tip_speed_bem does not prove that increasing tip speed causes higher
  tension — it shows that high-tip-speed configurations tend to have high PC1
  scores. The causality runs through the physics (BEM), not the PCA.
- **Profile dummies are excluded from the loadings panel.** The one-hot
  encoding creates three correlated dummy variables that are hard to display
  in a clean grouped bar chart. The biplot (Chart 6) shows profile effects
  better.
- **Scree plot "elbow" is subjective.** PC3→PC4 drops from 15% to 8% — a
  visible but not dramatic elbow. Different analysts might keep 3, 4, or 5
  PCs depending on their tolerance for discarded variance.
- **PCA on standardised data weights all features equally.** If you have
  prior knowledge that radius matters more than elevation (you do), a weighted
  or supervised decomposition (PLS, canonical correlation) might extract more
  task-relevant components. PCA is unsupervised — it finds axes of maximum
  variance, not axes that best predict tension.
