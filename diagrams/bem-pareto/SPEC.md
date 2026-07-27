# SPEC.md — bem-pareto

## Slug
`bem-pareto`

## Title
No Pareto Trade-off: Anchor Tension and Mass Efficiency Are Co-linear

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27 with corrected polygon solver)

Columns used:
- `radius` (m): rotor radius
- `n_rotors`: number of rotors in stack
- `profile`: tilt profile name (uniform, top_draggy, bottom_lifty, graded)
- `elevation` (deg): line elevation angle
- `wind_speed` (m/s): freestream wind speed
- `anchor_tension` (N): cumulative tension at anchor
- `autorotation_rpm`: rotor RPM
- `tip_speed_bem` (m/s): blade tip speed

## Aggregation
Group by unique configuration (radius + n_rotors + profile + elevation).
For each configuration:
- `mean_tension` = mean(anchor_tension) across wind speeds 6, 8, 10, 12 m/s
- `tension_per_kg` = mean_tension / (n_rotors × 5.0 kg)
- Filter: only configurations with mean_tension > 0 (viability gate)

## Variables

| Axis/Channel | Variable | Units | Description |
|-------------|----------|-------|-------------|
| X (position) | Mean anchor tension | N | Raw cumulative lift delivered at anchor |
| Y (position) | Tension per rotor mass | N/kg | Mass efficiency — lift per kg of rotor hardware |
| Color | Tilt profile | — | uniform (blue), top_draggy (orange), bottom_lifty (green), graded (red) |
| Size | Rotor radius | m | Point area ∝ radius² (disk area) |

## Audience
Technical — Cameron, Rod, and their agents. Used for design-space exploration
and communicating trade-offs to academic/investor audiences.

## Message
"Graded and uniform tilt profiles dominate the Pareto front. top_draggy has
fallen off the frontier after the polygon solver correction. Larger radii
(R=3.0m) achieve both higher absolute tension and higher mass efficiency.
Stack count N adds tension linearly without degrading per-kg efficiency."

## Chart type
2-D scatter plot with Pareto front curve. One figure only — no subplots.

## Visual conventions (from ktd-chart-design)
- White background
- Continuous color mapping by profile (discrete categories OK for 4 values)
- Leader lines + bracketed labels on 3-4 hero configurations
- Pareto front as dashed/dotted curve
- Point size proportional to rotor disk area (radius²)
- Bracketed labels: `[636 N, 31.8 N/kg, graded, R=3.0m, N=4]`

## Related SPEC sections
- SPEC.md §6.3 (Key Findings — v1 sweep)
- SPEC.md §6.6 (BEM Sweep v2.0 — corrected 2026-07-27)

## Generation
Python script `bem-pareto.py` reads `../../bem_full_sweep.tsv`, aggregates,
and outputs `bem-pareto.png` (300dpi) using matplotlib.
