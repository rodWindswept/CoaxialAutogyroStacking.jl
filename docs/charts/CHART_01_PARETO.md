# Chart 1: Pareto Frontier — Tension vs Mass Efficiency vs Stability

## Data Source

`bem_full_sweep.tsv` — 384 BEM configurations filtered to 312 viable rows
(non-zero anchor tension). Grouped by unique configuration (radius × stack
count × profile × elevation), figures of merit computed as means across the
4 wind speeds (6, 8, 10, 12 m/s).

## What This Chart Shows

Three linked views of the BEM parameter sweep Pareto frontier:

**Panel A (Tension vs N/kg):** Each point is one configuration. X-axis is mean
anchor tension (N) — the raw lift delivered to the kite turbine hub. Y-axis is
tension per rotor mass (N/kg) — how efficiently each kilogram of rotor hardware
converts wind into lift. Higher is better on both axes. Points are coloured by
tilt profile (uniform, graded, top_draggy, bottom_lifty) and shaped by profile.

**Panel B (Tension vs CV):** Same configurations, but Y-axis is tension
coefficient of variation across wind speeds. Lower CV = more stable through
gusts. This is the stability-efficiency trade-off — configurations that deliver
high mean tension may be less stable when wind changes.

**Panel C (Radius × Stack Count heatmap):** Maximum anchor tension for each
combination of rotor radius and stack count, collapsed across all profiles and
elevations. This shows the dominant effect: bigger rotors and more rotors
produce more tension.

**Panel D (Best configuration callout):** Text annotation showing the single
best configuration by mean anchor tension, with key numbers.

## Key Findings

1. **Tilt-profile differentiation is small (≤3.2% at N=2, +1.3% for graded at
   N=4).** The points for different profiles overlap almost completely at any
   given radius and stack count. This is not a failure of the analysis — it is
   the correct physics: with corrected polygon force equilibrium, the line
   segment angle is dominated by cumulative tension direction, not individual
   rotor tilt. The buggy solver (pre-2026-07-27) produced a false +12.7%
   top_draggy advantage that has been corrected.

2. **Radius dominates everything.** Moving from R=2.0m to R=3.0m increases
   tension by ~70% (186→314 N at N=2). This is the single most important
   design lever. R=1.5m is completely non-viable — all configurations produce
   zero net tension because the rotor cannot overcome its own weight.

3. **Stacking is nearly penalty-free.** At R=3.0m, going from N=1 to N=4
   increases tension almost 4× with only ~2% per-rotor efficiency penalty from
   line drag and cumulative weight. This is the core economic argument for
   stacked autogyros over single large rotors.

4. **Elevation angle doesn't matter (post-fix).** The 45° and 55° configurations
   produce nearly identical tensions (<0.2% difference). This is a consequence
   of the corrected polygon solver: the line finds its own equilibrium angle
   regardless of the initial elevation guess. The elevation parameter is
   effectively not a design variable in BEM — it's determined by force balance.

5. **All profiles converge at N=2.** With only one downstream rotor, the
   kinematic constraint is too strong for tilt to matter. The N=2 results show
   graded = uniform (314 N) and extreme profiles ~3.5% below. The N=4 results
   show graded pulling ahead slightly (+1.3%). This suggests that tilt-profile
   differentiation requires at least 3-4 rotors to become measurable — and even
   then it's modest.

## Design Implications

**For the rotor designer:** Prioritise radius. Every additional 0.5m of radius
buys more tension than any tilt-profile optimisation. The practical minimum is
R=2.0m (186 N at N=2, 8 m/s); the sweet spot is R=3.0m (314 N at N=2).

**For the stack architect:** Stack to N=4. The efficiency penalty is negligible
and the tension gain is linear. Beyond N=4, the analysis doesn't go, but the
trend suggests continued linear scaling until practical constraints (line
length, launch complexity) dominate.

**For the controls engineer:** Don't over-invest in per-rotor tilt optimisation.
A uniform stack produces 628 N; a carefully graded stack produces 636 N — a
+1.3% gain. The control complexity of individual rotor tilt may not be worth
the marginal improvement. Focus control effort on collective pitch for wind
speed adaptation instead.

**For the investor:** The story is radius + count, not tilt magic. A 4-rotor
stack at R=3.0m delivers 636 N at 8 m/s (~65 kg lift), scaling to 1.41 kN at
12 m/s (~144 kg). Per-rotor efficiency is 31.8 N/kg at the design point.
Compare to PCA-2 empirical disk model: same configuration delivers ~5,000 N —
the ~8× gap is a fidelity choice, not a performance defect (see Discussion).

## Limitations

- **No wake interaction.** All rotors see freestream wind. Wake coupling (v3)
  will reduce downstream rotor performance. The modest graded advantage may
  narrow further when upstream wake deficits are modelled.
- **4 wind speeds only (6, 8, 10, 12 m/s).** The CV metric captures
  variability across this range but doesn't reflect gust dynamics or
  time-varying wind fields.
- **2 elevations only (45°, 55°).** The finding that elevation doesn't matter
  is based on only two values. A finer sweep (40°, 50°, 60°) would confirm.
- **NACA 0012 only.** A symmetric airfoil was chosen for modelling simplicity.
  Cambered sections would produce different (likely higher) forces.
- **Constant chord (0.15m).** Real rotors would be tapered. The constant-chord
  assumption affects both BEM forces and Reynolds number distributions.
- **Re below PCA-2 validation range.** All BEM configurations operate at
  tip Re < 5×10⁵, below the range where the PCA-2 empirical data is considered
  trustworthy. The NACA 0012 data at these Re may not capture laminar
  separation bubble effects.
