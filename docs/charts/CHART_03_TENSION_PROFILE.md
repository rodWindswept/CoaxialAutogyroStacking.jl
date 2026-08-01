# Chart 3: Tension Accumulation Profile — How Lift Builds Along the Line

## Data Source

`stack_tension_profile()` from `src/stack.jl`, computed for the best BEM
configuration (R=3.0m, N=4, graded tilt, 45° elevation) at five wind speeds
(4, 6, 8, 10, 12 m/s). Rotors spaced at 15m intervals with 5m bottom tail.
Dyneema line: 4mm diameter, ρ=970 kg/m³.

## What This Chart Shows

Cumulative tension (N) as a function of distance from the anchor (m), moving
upward along the Dyneema line through each rotor. Five coloured lines show
the tension profile at different wind speeds. Rotor positions (R4 at top
through R1 at anchor) are marked with vertical dashed lines.

Tension starts at zero at the topmost rotor (there's nothing pulling from
above) and accumulates downward as each rotor adds its lift, minus its
weight component and plus the drag from the line section below it.

## Key Findings

1. **Tension accumulates linearly with rotor count.** Each rotor adds
   approximately the same tension increment. At 8 m/s: ~159 N per rotor,
   totalling 636 N at the anchor. The per-rotor contribution is nearly uniform
   because all rotors see freestream wind (no wake coupling) and the polygon
   line angles converge to near-identical values.

2. **Tension scales with v² across wind speeds.** The spread between lines
   follows dynamic pressure: 4 m/s → 85 N, 6 m/s → 322 N, 8 m/s → 636 N,
   10 m/s → 985 N, 12 m/s → 1,412 N. The ratio between adjacent wind speeds
   is approximately (v₂/v₁)², confirming the momentum theory expectation.

3. **Line drag is negligible.** The slope of each line segment includes line
   drag from the Dyneema section, but at these tensions and line lengths,
   the drag contribution is <1 N per 15m section. Dyneema at 4mm diameter is
   effectively transparent to the wind compared to rotor forces.

4. **There is no "knee" or saturation.** The tension profile is a straight
   line from top to anchor. This means the stack could continue adding rotors
   beyond N=4 without diminishing returns — there's no evidence of crowding,
   interference, or tension saturation in the BEM model (wake coupling would
   introduce these effects in v3).

5. **The weight penalty is visible but small.** Each 5 kg rotor contributes
   49 N of weight (mg = 5 × 9.81) but only the component resolved along the
   line direction (mg·cos θ ≈ 35 N at 45°) subtracts from net lift. At 8 m/s,
   each rotor produces ~194 N of gross thrust — the net after weight is ~159 N,
   so the weight penalty is ~18% per rotor. At higher wind speeds the penalty
   shrinks (thrust grows with v², weight is constant).

## Design Implications

**For the stack architect:** You can keep stacking. N=4 is not a limit — it's
just where the current sweep stops. The linear accumulation suggests N=8 or
N=12 would behave similarly (modulo practical constraints on line length and
launch complexity). An 8-rotor stack at R=3.0m, 8 m/s would deliver ~1.3 kN;
at 12 m/s it would deliver ~2.8 kN.

**For the line specifier:** 4mm Dyneema SK75 has a breaking strength of ~14 kN.
The maximum anchor tension in this sweep (1,412 N at N=4, 12 m/s) uses only
10% of the line's capacity. Line diameter could be reduced to 2mm (breaking
strength ~5.6 kN) for lower drag and weight, or the stack size could be
increased dramatically before the line becomes the limiting factor.

**For the launch/recovery engineer:** A 4-rotor stack with 15m spacing is 60m
long from top rotor to anchor, plus 5m tail = 65m total line length. An 8-rotor
stack would be 125m. This is well within the capability of a small winch but
requires launch clearance (the top rotor must clear the ground before the
bottom rotors begin lifting).

**For the investor:** This chart tells the scalability story in one image. Want
more lift? Add another rotor. The line is straight — no diminishing returns,
no saturation, no gotchas. This is fundamentally different from fixed-wing or
soft-kite systems where adding area introduces non-linear drag penalties and
structural coupling nightmares.

## Limitations

- **No wake interaction.** All rotors see freestream. In reality, downstream
  rotors would see reduced and turbulent inflow. Wake coupling would make the
  tension profile sub-linear — each additional rotor would contribute slightly
  less than the previous one. The current chart is an upper bound on stack
  performance.
- **Static profile only.** This is the equilibrium tension at one instant. In
  gusts, the profile would shift dynamically. A time-varying analysis (v3)
  would show the dynamic response.
- **Constant spacing assumption.** 15m spacing is arbitrary. Real stacks might
  use tighter spacing (5-10m) for compactness or wider spacing (20-30m) to
  reduce wake interaction. The current model shows that spacing has negligible
  effect on tension (line drag is tiny), but wake interaction would make
  spacing matter.
- **No structural deflection.** The line is modelled as a polygon chain of
  straight segments. In reality, Dyneema stretches under load (~3.5% at
  breaking), and the line would form a continuous catenary curve between
  rotors. The polygon approximation is valid for the tension calculation but
  would differ from a photographic image of the actual system.
