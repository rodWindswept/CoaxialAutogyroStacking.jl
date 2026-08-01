# Makani Chart Design Patterns — Research Summary

Extracted from The Energy Kite Report (Part I, 417 pages, 183+ figures).

## Visual Style

- **White/clean background** — publication-ready, no dark themes
- **Consistent sans-serif typography** — professional, technical look
- **Detailed captions** — every figure has a multi-sentence caption explaining what to see
- **Sub-figure labeling** — (a), (b), (c) for multi-part figures, but one message per figure

## Chart Types (most common)

### 1. Trade Space / Pareto Fronts
- Contour plots of one metric vs two design variables
- Color gradient shows the objective (e.g., power, mass, LCOE)
- Pareto frontiers overlaid as boundary lines
- Example: Power vs (y,z) position contoured at various wind speeds

### 2. Comparative Overlays
- Multiple designs on same axes
- Distinct colors: orange (new design) vs gray (baseline)
- Clear legend with line style differentiation
- Example: Oktoberkite vs M600 comparison

### 3. Power Curves with Annotations
- Wind speed on x-axis, power on y-axis
- Multiple curves for different configurations
- Annotated regions showing operational limits
- Example: "Power curves comparing normal wind vs high turbulence"

### 4. Sensitivity / Tornado Charts
- Bar charts showing how parameters affect output
- Ordered by impact magnitude
- Example: "Sensitivity of power coefficients to tower height"

### 5. Force Balance Diagrams
- Vector diagrams with labeled forces
- Geometric relationships shown visually
- Analytical equations paired with diagrams

### 6. Contour + Optimization Overlay
- 2D contour plots of performance metrics
- Optimal path or boundary overlaid
- Color scales with clear legends

## Annotation Patterns

- **Operational envelopes** — shaded regions showing feasible operation
- **"Better ← → Worse" arrows** on axes
- **Direct labeling** of interesting points (not just legend-based)
- **Reference lines** — dashed lines showing thresholds or targets
- **Before/after comparison** — old vs new design side by side

## Color Usage

- **Limited palette** — 2-4 colors per chart
- **Orange for new/proposed designs** (consistent across report)
- **Gray for baselines/references**
- **Blue → Red diverging** for signed metrics
- **Sequential colormaps** for contour plots (light → dark)

## Layout Philosophy

- **One finding per figure** — don't try to show everything
- **Figure tells story without reading text** — self-contained
- **Caption starts with the finding** — "Comparison of X shows Y is better at Z"
- **High data-ink ratio** — minimal chart junk

## Key Lessons for CoaxialAutogyroStacking Charts

1. Start each chart caption with what the reader should notice
2. Use comparative overlays (uniform vs graded vs top_draggy on same axes)
3. Annotate operational regions (feasible, optimal, edge cases)
4. Use color for meaning, not decoration
5. One chart, one message — split complex stories into multiple figures
6. White background, clean sans-serif, high contrast
