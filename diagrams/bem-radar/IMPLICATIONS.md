# IMPLICATIONS.md — bem-radar

## Finding

Tilt profile has a negligible effect on performance. At the best (R=3.0m,
N=4) configuration, the spread between the best profile (graded, 838 N) and
worst (top-draggy, 809 N) is only 3.5%. All four profiles overlap heavily
in the radar chart despite normalized axes exaggerating the differences.

## Significance

- Manufacturing can use uniform tilt without meaningful performance loss.
- Graded tilt adds assembly complexity (each rotor at a different angle)
  for less than 4% gain — not worth the cost.
- Tilt profile is not a design differentiator. Focus engineering effort on
  radius and stack count, which drive the dominant variance (see PCA charts).

## Consequence

- Standardize on uniform tilt for all prototype builds.
- Remove tilt profile from the primary design parameter set for optimization.
- The radar chart's normalized axes visually overstate differences — always
  check raw values in the caption or IMPLICATIONS.md.
