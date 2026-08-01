# Chart 8: Feature Correlations — What Drives Anchor Tension?

## Data Source

`bem_pca_scores.tsv` — the 312-configuration dataset with PCA scores appended.
Pearson correlation coefficients (r) are computed between each candidate
predictor and the target variable `anchor_tension` using `scipy.stats.pearsonr`.
All correlations use the full 312-row dataset with no subsampling or binning.

## What This Chart Shows

A horizontal bar chart ranking nine features by their Pearson correlation with
anchor tension. Bars extend rightward for positive correlations, leftward for
negative (none in this dataset). Three colour bands segment the correlations:
red for strong predictors (r > 0.5), orange for moderate (0.2 < r < 0.5),
blue for weak (r ≤ 0.2). Each bar is labelled with its exact r value to three
decimal places.

**Ranked features (top to bottom):**
1. tip_speed_bem — the strongest single predictor
2. PC1 score — the composite "power" axis
3. autorotation_rpm — rotor speed
4. radius — rotor size
5. wind_speed — environmental forcing
6. PC2 score — the "wind" axis
7. n_rotors — stack depth
8. PC3 score — the "stack count" axis
9. elevation — line angle guess

This chart answers the most direct design question: "if I can only change one
thing, what should I change to get more anchor tension?"

## Key Findings

1. **tip_speed_bem is the best single predictor of anchor tension (r = +0.688).**
   This is the headline number. Tip speed — the product of rotor radius and
   angular velocity — explains 47% of the variance in anchor tension (r² =
   0.473). This makes mechanical sense: BEM forces scale with relative
   velocity squared at each blade section, and tip speed is the peak relative
   velocity the rotor experiences. A rotor with high tip speed has high
   dynamic pressure over its entire span, producing more lift and therefore
   more anchor tension.

2. **PC1 is almost as good as tip_speed alone (r = +0.662).** The principal
   component that combines tip speed, RPM, and radius into a single score
   correlates with tension nearly as strongly as tip speed by itself. This
   validates PC1 as a useful summary statistic — it loses only 4% of the
   correlation strength while reducing three correlated variables to one
   number. For a dashboard or optimisation loop, PC1 is the right scalar
   objective.

3. **The first three features form a tight cluster (r = 0.66–0.69).**
   tip_speed_bem, PC1, and autorotation_rpm are all highly correlated with
   tension and with each other. You cannot treat them as independent levers —
   increasing radius increases tip speed, which increases RPM at autorotation
   equilibrium. The physics links them, so the correlation chart correctly
   shows them as a block.

4. **Wind speed matters but less than rotor size (r = +0.405).** wind_speed
   is the fifth-ranked predictor, behind radius. Doubling wind speed (6→12
   m/s) increases tension by roughly 4× (dynamic pressure scaling), but the
   correlation is weaker than radius because wind speed varies over a smaller
   relative range in the sweep (2:1 for wind vs 2:1 for radius, but radius
   has a squared area effect). If the sweep had included 4–16 m/s instead of
   6–12 m/s, wind speed would rank higher.

5. **n_rotors is a surprisingly weak predictor (r = +0.246).** Adding more
   rotors does increase total anchor tension — the physics demands it — but
   the correlation is modest because n_rotors varies from 1 to 4 (a 4:1
   range) while tension varies over a 400:1 range (2 N to 800+ N). The
   narrow range of n_rotors compared to the wide range of tension outcomes
   dilutes the correlation. Stack count matters, but within the 1–4 range, it
   is not the dominant lever.

6. **Elevation is effectively uncorrelated with tension (r = +0.015).** This
   is not "elevation has a small effect" — it's "elevation has no detectable
   linear relationship with tension." The polygon solver determines line
   angle from force equilibrium, making the initial elevation guess nearly
   irrelevant. If this number were substantially non-zero, it would indicate a
   bug in the solver. r ≈ 0 is the expected and correct result.

7. **PC2 and PC3 have weak correlations with tension (r = +0.158, +0.036).**
   PC2 (wind speed axis) should correlate with tension but its loading is
   diluted by the orthogonalisation — PC1 already captured the part of wind
   speed that correlates with tension, leaving PC2 with the residual. PC3
   (stack count axis) is nearly uncorrelated for the same reason: n_rotors'
   tension-correlated variance went into PC1.

## Design Implications

**For the rotor designer:** Tip speed is your single most important metric.
Every design decision — radius, chord, airfoil, target RPM — should be
evaluated by its effect on achievable tip speed at autorotation equilibrium.
A design that increases tip speed by 10% will increase anchor tension by
roughly 7% (r = 0.69, interpreting causally with caution).

**For the optimisation engineer:** Use PC1 as a scalar objective. It captures
tip speed, RPM, and radius in one number with only a 4% correlation penalty
vs using tip speed alone. Multi-objective optimisers can treat PC1 as the
"performance" axis and PC2 (wind insensitivity) as the "robustness" axis,
with a clean orthogonality guarantee from the PCA.

**For communicating to Rod/investors:** "Tip speed is the single best
predictor of how much tension a rotor stack will produce. Profile choice and
elevation angle don't matter — the physics is dominated by how fast the blade
tips move through the air." This is a one-sentence summary backed by r = 0.69.

**For what NOT to optimise:** Don't spend engineering effort on tilt-profile
differentiation. Don't treat elevation as a design variable. Don't expect
large gains from increasing stack count beyond 4 without also increasing
radius. The correlation chart is a prioritisation tool — the top 3 features
deserve 90% of the attention.

## Limitations

- **Pearson's r measures linear correlation only.** If the true relationship
  between tip speed and tension is nonlinear (e.g., a quadratic or sigmoid),
  Pearson's r will understate the association. A Spearman rank correlation or
  mutual information score would capture nonlinear dependence but is not shown
  here.
- **Correlation ≠ causation, especially with derived variables.** tip_speed_bem
  is computed from radius × RPM — it is not an independent lever you can
  adjust in isolation. You cannot double tip speed without changing radius,
  RPM, or both. The correlation tells you tip speed is a good proxy for
  tension, not that you can directly control tip speed.
- **The sweep design determines the correlation structure.** wind_speed varies
  over 6–12 m/s (2:1), while radius varies over 1.5–3.0 m (2:1 in length,
  4:1 in area). The sweep ranges influence which features appear most
  predictive. Extending the sweep to lower wind speeds (4 m/s) or larger
  radii (3.5 m) would change the ranking.
- **n_rotors correlation is suppressed by range restriction.** With only
  four integer values (1, 2, 3, 4), the correlation ceiling is artificially
  low. A sweep with n_rotors = 1, 2, 4, 8, 16 would likely show a much
  stronger correlation.
