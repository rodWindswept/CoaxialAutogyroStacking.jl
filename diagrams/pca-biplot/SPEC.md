# SPEC.md — pca-biplot

## Slug
`pca-biplot`

## Title
PCA Biplot: BEM Configurations Mapped to Principal Component Space

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27, commit `473a316`, corrected
polygon solver). 384 raw rows, tab-separated.

Columns used:
| Column | Units | Description |
|--------|-------|-------------|
| `radius` | m | Rotor disk radius (1.5, 2.0, 3.0) |
| `n_rotors` | — | Rotors in stack (1, 2, 3, 4) |
| `profile` | — | Tilt profile: uniform, top_draggy, bottom_lifty, graded |
| `elevation` | deg | Line elevation (45, 55) |
| `wind_speed` | m/s | Freestream wind (6, 8, 10, 12) |
| `anchor_tension` | N | Cumulative tension at anchor |
| `autorotation_rpm` | — | Rotor RPM at torque equilibrium |
| `tip_speed_bem` | m/s | Blade tip speed from polygon segment angles |

## Aggregation

Group raw rows by configuration key `(radius, n_rotors, profile, elevation)`.
For each of the 96 viable configurations (same aggregation as `bem-pareto`):

1. `mean_tension` = mean of `anchor_tension` across 6, 8, 10, 12 m/s
2. `tension_per_kg` = mean_tension / (n_rotors × 5.0 kg)
3. `mean_rpm` = mean of `autorotation_rpm` across wind speeds
4. `mean_tip_speed` = mean of `tip_speed_bem` across wind speeds
5. `tip_reynolds` = ρ × mean_tip_speed × blade_chord / μ
   where ρ = 1.225 kg/m³, chord = 0.15 m, μ = 1.81×10⁻⁵ Pa·s

Filter: exclude configurations with mean_tension ≤ 0 (R=1.5m below BEM
viability threshold).

This produces a 96×7 data matrix. All 7 variables are standardized to
zero mean and unit variance before PCA (correlation matrix, not covariance).

The 7 PCA variables:
| # | Variable | Type | Description |
|---|----------|------|-------------|
| 1 | radius | Design | Rotor radius |
| 2 | n_rotors | Design | Stack count |
| 3 | mean_tension | Performance | Raw lift output |
| 4 | tension_per_kg | Efficiency | Lift per unit rotor mass |
| 5 | mean_rpm | Operational | Rotational speed |
| 6 | mean_tip_speed | Viability | Blade tip speed (noise limit: 120 m/s) |
| 7 | tip_reynolds | Flow regime | Tip Reynolds number |

## Variables (chart channels)

| Channel | Encodes | Description |
|---------|---------|-------------|
| X (position) | PC1 | First principal component — direction of maximum variance in the 7-D design space |
| Y (position) | PC2 | Second principal component — orthogonal direction capturing next-largest variance |
| Color (hue) | Tilt profile | 4 discrete categories: uniform (blue), top_draggy (orange), bottom_lifty (green), graded (red) |
| Size (area) | Rotor radius R | Point area ∝ R² — larger disks are larger points |
| Arrows (direction + length) | Variable loadings | Each of the 7 original variables shown as an arrow from origin; direction = contribution to PC1/PC2; length = strength of contribution |

## Audience

Primary: Rod and Cameron — design-space understanding. Which variables
drive the differences between configurations? Are there natural design
families? Is the design space effectively low-dimensional?

Secondary: Manufacturing partners and investors. Shows that the 96
configurations reduce to a much simpler structure.

## Message

The 7-dimensional BEM design space collapses to just 2 principal components
explaining 100% of variance. PC1 (81.1%) is a physical-scale axis dominated
by tip speed, Reynolds number, and mass efficiency — larger, faster rotors
score higher. PC2 (18.9%) is a rotor-count axis — adding rotors to the stack
moves configurations vertically without affecting their PC1 score. Tilt
profiles (uniform, top_draggy, bottom_lifty, graded) produce no visible
clustering — confirming the bem-pareto finding that profile choice matters
less than 2%. The design space is effectively two-dimensional: pick a radius
(PC1) and a stack count (PC2), and you've determined the configuration's
performance. Everything else is detail.

### Plain-language explanation (for non-technical readers)

Imagine you measured 7 different things about 96 rotor designs: how big
they are, how many you stack, how hard they pull, how efficient they are,
how fast they spin, and so on. You'd expect 7 numbers to need 7 dimensions
to describe — like needing 7 coordinates to locate a point in space.

Principal Component Analysis asks: "Could we describe all 96 designs using
fewer dimensions without losing important information?" The answer here is
yes — just 2 dimensions capture 100% of what makes designs different from
each other.

**What PC1 means (81.1%):** This is the "how big and powerful" axis.
Designs on the right have larger radii, higher tip speeds, and pull harder.
Designs on the left are smaller and less powerful. If you only had one
number to describe a rotor design, this would be it — it captures over 80%
of everything that matters.

**What PC2 means (18.9%):** This is the "how many rotors" axis. Whether
you stack 1, 2, 3, or 4 rotors moves you up and down this axis. Adding
rotors increases total tension without fundamentally changing the design's
character — it's a scaling knob, not a redesign.

**What the overlapping colors mean:** All four tilt profiles (uniform,
top-draggy, bottom-lifty, graded) sit on top of each other — you can't tell
them apart in this view. That's the chart's most important finding for
manufacturing: don't over-invest in tilt profile complexity. It doesn't
create a meaningfully different machine.

**What this means for building hardware:** You need to decide two things:
what radius to build (PC1) and how many to stack (PC2). The tilt profile
is a tuning parameter, not a design differentiator. This collapses a
seemingly complex 7-dimensional design problem into 2 decisions.

## Chart type

PCA biplot — scatter plot of 96 configuration scores on PC1/PC2 axes,
with 7 variable loading arrows overlaid from the origin. One figure only.
This is the standard multivariate statistics visualization for PCA.

## Visual encoding

- **Position:** PC1 (x) and PC2 (y) scores carry the primary information —
  where each configuration sits in reduced space.
- **Color:** tilt profile enables visual assessment of whether profile
  differentiates configurations in PC space.
- **Size:** rotor radius gives immediate visual grouping — larger disks
  should cluster separately from smaller ones.
- **Arrows:** variable loadings as vectors from origin. Arrow direction
  shows which PC the variable contributes to; length shows contribution
  strength. Labeled at arrow tips.
- **Variance explained:** PC1 and PC2 axis labels include % variance
  explained (e.g., "PC1 (73.2%)").

## Annotation strategy

- All 7 variable arrows labeled at tips.
- No individual configuration labels unless specific hero designs are
  identified during review.
- Variance explained percentages in axis titles.
- Legend for color (profile) and size (radius) as separate elements.

## Related SPEC sections

- SPEC.md §6.6 — BEM sweep v2.0 data source
- `bem-pareto` SPEC.md — same aggregation, complementary analysis

## Generation

```bash
cd diagrams/pca-biplot
julia --project=../.. pca-biplot.jl
```

Requires: Julia 1.12, MultivariateStats.jl, CairoMakie.jl, DataFrames.jl,
CSV.jl, Statistics stdlib. Input: `../../bem_full_sweep.tsv`.
Output: `pca-biplot.png` (300dpi), `pca-biplot.pdf` (vector).
