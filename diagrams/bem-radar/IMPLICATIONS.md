# IMPLICATIONS.md — bem-radar

## Finding

Tilt profile has a moderate effect on performance. At the best (R=3.0m,
N=4) configuration, the spread between the best profile (graded, 858 N)
and worst (top-draggy, 769 N) is 10.4%. All four profiles overlap in
most radar axes. The largest differences appear in raw tension.

## Significance

- Graded tilt wins. The 10% margin is real but not dominant.
- Uniform tilt is within ~4% of graded for most metrics.
- Top-draggy is clearly worse — the spread to graded is meaningful.
- Manufacturing can use uniform tilt for simplicity with a small penalty
  or graded tilt for maximum performance.

## Consequence

- Tilt profile is a design choice with moderate impact, not a fine-tuning
  parameter as previously thought.
- Standardize on uniform tilt for prototype builds (4% penalty vs graded).
- Reserve graded tilt for performance-critical deployments.
