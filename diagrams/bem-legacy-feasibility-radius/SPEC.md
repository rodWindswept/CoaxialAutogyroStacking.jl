# SPEC.md — bem-legacy-feasibility-radius

## Slug
`bem-legacy-feasibility-radius`

## Title
Tip Reynolds Number by Radius and Stack Count — Viability Gate

## Data Source
`bem_full_sweep.tsv` (regenerated 2026-07-27, corrected polygon solver).

The sweep covers 3 rotor radii (1.5, 2.0, 3.0 m) × 4 stack counts (1, 2, 3, 4)
× 4 tilt profiles (uniform, top-draggy, bottom-lifty, graded) = 48 physical
configurations, each run at multiple wind speeds. Tip Reynolds number is
computed per wind speed as Re = ρ · v_tip · chord / μ, then the worst-case
(minimum Re across wind speeds) is checked against the 5×10⁴ threshold.

## Variables

- **Rows (y-axis):** Stack count n_rotors (1, 2, 3, 4)
- **Columns (x-axis):** Rotor radius (1.5, 2.0, 3.0 m)
- **Color:** Mean tip Reynolds number across wind speeds.
  Red = low Re (laminar, poor performance). Green = high Re (turbulent, good).
- **Cell annotation:** PASS = all wind speeds exceed Re > 5×10⁴.
  FAIL = at least one wind speed falls below the threshold.

## Plain-language explanation

This heatmap answers a simple manufacturing question: which (radius, stack_count)
combinations actually work? Below a tip Reynolds number of about 5×10⁴, the
airflow over the blade transitions from turbulent to laminar. Laminar flow
separates earlier — lift collapses, drag spikes, and the rotor stops
autorotating properly. Each cell shows the mean Re and gets a PASS or FAIL
stamp based on whether ALL wind speeds in that configuration clear the 5×10⁴
barrier.

Think of it as a compatibility chart. If your target radius and stack count
falls in a red FAIL cell, that combination is physically non-viable — the
blade never reaches the flow regime where airfoil data is valid. You need
either a larger radius (more tip speed) or more rotors (more line tension
driving autorotation faster).

## Message

Larger rotors at higher stack counts push tip Reynolds above 5×10⁴. The
smallest configurations (R=1.5m, N=1-2) fail the viability gate — they
cannot sustain turbulent flow across all wind speeds. The minimum viable
product starts at R=2.0m with N≥2 or R=1.5m with N≥3.

## Audience

- **Manufacturing engineers** selecting viable (radius, N) combinations for
  prototype builds. They need to know which configurations are worth building.
- **Investors / funding reviewers** asking "can we make a small version?"
  The answer is in this chart: small single-rotor configurations are a
  non-starter.
- **Aerodynamics reviewers** checking that the BEM model is only applied
  within its valid flow regime.

## Implication for manufacturing

Small-diameter, single-rotor configurations are physically non-viable under
autorotation. Any proposed "compact" or "backpack-sized" version must
demonstrate Re > 5×10⁴ at its design wind speed. For prototyping, focus on
R=2.0m and above, or stack at least 3 rotors if constrained to R=1.5m.

## Figure type

Heatmap with annotated pass/fail markers. 2D grid: radius on x-axis (3 values),
stack count on y-axis (4 values), color-coded by mean tip Reynolds number.
12 cells total.

## Visual encoding

- **Color:** Red = low Re (failing), Green = high Re (passing).
  Colormap: RdYlGn (red-yellow-green sequential).
- **Position:** x = radius, y = n_rotors — the two manufacturing parameters.
- **Annotation:** "PASS" (green text) or "FAIL" (dark red text) overlaid
  on each cell at center.

## Annotations

Each of the 12 cells annotated with PASS or FAIL per the viability gate
Re > 5×10⁴ (all wind speeds must pass). Colorbar on the right shows the
Re range. Title states the viability threshold explicitly.

## Dimensions

~6×5 inches. Compact heatmap — 3 radii × 4 stack counts = 12 cells with
adequate cell spacing.

## Generation

```bash
cd diagrams/bem-legacy-feasibility-radius
python3 bem-legacy-feasibility-radius.py
```

Requires: Python 3, matplotlib, numpy. Input: `../../bem_full_sweep.tsv`.
Output: `bem-legacy-feasibility-radius.png` (300dpi), PDF.

## Round 1 checks

- [ ] All 12 cells present (3 radii × 4 n_rotors)
- [ ] Re values consistent with bem_full_sweep.tsv spot-checks
- [ ] PASS iff Re > 5×10⁴ for ALL wind speeds in that cell
- [ ] FAIL if any wind speed falls below threshold
- [ ] 0 negative tensions (viability gate baseline)
- [ ] Tip speed plausibly ≤ 120 m/s
- [ ] Axes labeled with units ("Rotor Radius (m)", "Stack Count (n_rotors)")
- [ ] Colorbar present and labeled
- [ ] Title states the finding and threshold
- [ ] PASS/FAIL annotations readable on all cells
- [ ] Implications caption on chart
