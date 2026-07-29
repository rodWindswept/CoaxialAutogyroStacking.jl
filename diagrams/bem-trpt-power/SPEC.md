# SPEC.md — bem-trpt-power

## Slug
`bem-trpt-power`

## Title
Power Generation Potential — TRPT vs Yo-yo — Stacked Autogyro Lift

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-29, θ_above polygon fix).
Best config: R=3.0m, N=4, graded, 45° elevation.

Power formulas:
- TRPT = anchor_tension × kite_factor / 1000 (kW)
  - v5 Octagon: factor = 44.4 (871 W/kg)
  - Canonical 5-line: factor = 28.9 (568 W/kg)
- Yo-yo peak = anchor_tension × (v_wind / 3.0) / 1000 (kW)
- Yo-yo net = yo-yo peak × 0.77 (77% duty cycle)

## Variables

- **X-axis:** Wind speed (6–12 m/s)
- **Y-axis:** Power (kW)
- **4 curves:** TRPT v5, TRPT Canonical, Yo-yo peak, Yo-yo net

## Message

The stacked autogyro strongly favors fly-gen TRPT power. TRPT delivers
16–64 kW across 6–12 m/s. Yo-yo net delivers only 0.5–4.5 kW. The gap
is 10–14× at all wind speeds. Do not use the autogyro in yo-yo mode.

## Plain-language explanation

This chart answers: "Which AWES mode should we pair with the stacked
autogyro?" The answer is fly-gen (TRPT). The autogyro produces steady
lift. TRPT converts it to shaft power through a kite turbine. Yo-yo
wastes energy reeling the line back in. At every wind speed, TRPT
produces 10–14× more usable power.

## Audience

- **AWES system designers** choosing between fly-gen and yo-yo.
- **Investors** asking about the power generation potential.
- **Kite turbine engineers** sizing generators for the expected power.

## Figure type

Multi-line chart. 4 curves on shared axes.

## Generation

```bash
cd diagrams/bem-trpt-power
python3 bem-trpt-power.py
```
