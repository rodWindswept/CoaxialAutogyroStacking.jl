# Resolution: Ticket 05 — Audit diagram SPECs

## Finding

11 of 12 diagram SPECs pass the 2.0 threshold. Two fail — bem-tension-accum
and pca-clusters.

## Passing (9 SPECs)

bem-feasibility-heatmap (1.77), bem-feasibility-radius (1.23),
bem-pareto (1.69), bem-radar (1.14), bem-radial-loading (1.36),
pca-biplot (1.45), pca-correlation (1.52), pca-efficiency (1.67),
pca-manufacturing (1.35), pca-scree (1.52), pca-loadings (2.00 — marginal)

## Failing (2 SPECs)

- **bem-tension-accum: 2.80** — 965 words, 21 em dashes. Long sentences.
  Rewrite with shorter sentences. Remove em dashes.
- **pca-clusters: 3.64** — only 55 words. Score is unstable on such a
  short file. Expand to the ~1000 word target and the score will drop.

## Consistency check

All completed-diagram SPECs use the 12-section format correctly. No
contradictory variable names or data sources found across related
diagrams. The bem-feasibility pair and bem-tension pair are internally
consistent.
