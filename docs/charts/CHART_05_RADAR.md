# Chart 5: Radar Comparison — Tilt Profile Trade-offs

## Data Source

Figures of merit per tilt profile at the best configuration (R=3.0m, N=4,
45° and 55° elevation combined). Four profiles: uniform, graded, top_draggy,
bottom_lifty. Metrics normalised to [0,1] for radar display.

## What This Chart Shows

A radar/spider plot comparing four tilt profiles across four normalised
performance dimensions:

- **Tension:** Mean anchor tension (N) — raw lift output
- **N/kg:** Tension per rotor mass — efficiency metric
- **Max T:** Maximum anchor tension across wind speeds — peak capability
- **Stability:** 1/CV — inverted coefficient of variation (higher = more
  stable through gusts)

Each profile is a coloured polygon; larger polygon area = better overall
performance. The normalisation means differences are relative within this
group of configurations, not absolute.

## Key Findings

1. **Graded stacking wins, barely.** The graded polygon is slightly larger
   than uniform on all four axes. The differences are small (+1.3% tension,
   +1.3% N/kg, +0.7% max T, comparable stability). Graded is consistently
   best but the margin is thin.

2. **Top_draggy and bottom_lifty are slightly worse than uniform.** Both
   extreme profiles underperform by 1.7-2.0% on tension and N/kg, with
   comparable stability. The aggressive tilt at the top (top_draggy) or
   bottom (bottom_lifty) produces more drag than the line-angle benefit can
   offset. The corrected physics (post-sin/cos swap bug fix) shows that
   moderate tilt distributed across the stack outperforms extremes.

3. **Stability is nearly identical across all profiles.** The inverted CV
   metric shows all four profiles within ~2% of each other. This means gust
   response is dominated by the rotor's natural lift-curve characteristic
   (CL vs α), not by the tilt profile. The autogyro rotor is inherently
   gust-stable regardless of how you tilt it.

4. **The radar plot reveals what the Pareto chart hides.** On the Pareto
   chart (Chart 1), all profiles overlap at any given radius and N — it's
   hard to see which is best. The radar plot normalises away the dominant
   radius×N effect and shows the residual profile differences clearly.
   The story is: graded > uniform > bottom_lifty ≈ top_draggy, but the
   differences are small.

## Design Implications

**For the rotor designer:** Use graded tilt. It costs nothing (same hardware,
   different tilt angles) and provides a small but consistent advantage. The
   graded profile distributes tilt across the stack: top rotors are flatter
   (more drag, shaping the line outward), middle rotors are moderate, bottom
   rotors are steeper (more lift, exploiting the shaped line). This is the
   theoretically optimal strategy, and the data confirm it — modestly.

**For the controls engineer:** The small differences mean tilt optimisation
   is a "nice to have," not a "must have." A uniform stack is 98.7% as good
   as a carefully graded one. If individual rotor tilt control adds cost,
   weight, or complexity, skip it. The system works fine with all rotors at
   the same tilt.

**For the investor:** The radar chart visualises the "no wrong answer" story.
   All four profiles are within a few percent of each other. This means the
   design is robust to manufacturing tolerances, field adjustments, and
   operator error. You don't need an aerodynamicist on-site to tune the stack
   — any reasonable tilt configuration works.

**For the academic paper:** The radar chart is the clearest visualisation of
   the post-bug-fix reality. The pre-fix result (+12.7% top_draggy advantage)
   would have shown a dramatically expanded top_draggy polygon — that was the
   bug. The current chart shows the truth: profile differentiation is real
   but small, and graded is the consistent (if modest) winner.

## Limitations

- **Only 4 profiles tested.** The tilt space is continuous — intermediate
  profiles (e.g., a "mild graded" with 5° steps instead of 10°) might perform
  better or worse. The current sweep only tests the four named strategies.
- **Normalisation hides absolute differences.** The radar plot shows relative
  differences within this group but doesn't convey that going from R=2.0m to
  R=3.0m changes tension by ~70% while changing profile changes it by ~2%.
  Always view this chart alongside the Pareto chart (Chart 1) for scale.
- **Only 4 metrics.** Performance dimensions like cost, manufacturability,
  transportability, and launch complexity are not captured. A profile that
  wins on aerodynamics might lose on practical grounds.
- **No wake interaction.** If downstream rotors see reduced inflow, the
  graded advantage might change. Top rotors shaping the line outward might
  also push downstream rotors into cleaner air — a potential benefit not
  captured by the freestream assumption.
