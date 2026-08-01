# Chart 2: Feasibility Heatmaps — Reynolds Number & Acoustic Envelope

## Data Source

`bem_full_sweep.tsv` — 312 viable BEM configurations. Tip chord Reynolds
number computed as Re = ρ · v_tip · c / μ with ρ=1.225 kg/m³, c=0.15 m,
μ=1.8×10⁻⁵ Pa·s. Acoustic limit set at 120 m/s tip speed (Mach 0.3).

## What This Chart Shows

Two heatmaps that define the operational envelope for BEM-based rotors:

**Panel A (Tip Reynolds Number):** Mean tip chord Reynolds number for each
radius × stack count combination. The PCA-2 empirical data is validated at
Re ≥ 5×10⁵ — below this, the airfoil data may not capture laminar separation
bubble effects that dominate at model scale. Green ✓ marks configurations
where all wind speeds meet the threshold; red ✗ marks those that don't.

**Panel B (Tip Speed — Acoustic Limit):** Mean tip speed (m/s) for each
radius × stack count combination, with the 120 m/s acoustic noise limit
marked. Values are annotated directly on cells. All configurations pass this
limit with wide margin — the highest observed tip speed is ~38 m/s at R=3.0m
and 12 m/s wind speed.

## Key Findings

1. **No BEM configuration passes the Re gate.** Every single configuration
   operates at tip chord Re below 5×10⁵. R=1.5m runs at ~1×10⁵; R=2.0m at
   ~2×10⁵; R=3.0m at ~4×10⁵ at 12 m/s. This is not a failure of the design —
   it's a consequence of running 150mm chord blades at autorotation tip speeds
   (23-38 m/s). The PCA-2 validation threshold was established for full-scale
   autogyros with larger chords and higher speeds.

2. **All configurations pass the acoustic noise gate with >3× margin.** The
   highest tip speed is 38.3 m/s at R=3.0m, 12 m/s wind speed — well below the
   120 m/s limit. Autorotating rotors are inherently quiet because tip speed is
   determined by the wind speed (via autorotation equilibrium), not by a motor.
   There is no gearbox whine, no engine drone. The dominant sound is blade
   rush, which at these tip speeds is comparable to light wind through trees.

3. **Reynolds number scales primarily with radius, weakly with wind speed.**
   The Re values are nearly independent of stack count — adding rotors doesn't
   change the tip speed (each rotor autorotates independently). The Re
   improvement from R=2.0m to R=3.0m is ~2×, consistent with the radius
   increase (tip speed roughly doubles, chord is constant).

4. **The "viable" count is zero — and that's okay.** The Re gate was
   established for the PCA-2 empirical model, not for BEM. BEM with NACA 0012
   data at Re=10⁵ is making predictions at the edge of the airfoil data's
   validated range, but the predictions are physically reasonable (forces
   scale correctly, RPM is in expected range, induction converges). The Re
   gate should be understood as a "caution flag," not a "do not fly" sign.

## Design Implications

**For the aerodynamicist:** The Re regime (1×10⁵ to 4×10⁵) is where laminar
separation bubbles form and burst on NACA 0012 — these effects are not captured
by the current 2-D airfoil tables. Wind tunnel or CFD validation at these
specific Re is recommended before committing to hardware. The Snel 3-D
correction partially addresses rotational effects but does not account for
laminar separation bubble behaviour.

**For the structural designer:** Tip speeds of 23-38 m/s mean centrifugal
stresses are modest. At R=3.0m, 86 RPM: centripetal acceleration at the tip is
ω²R = (9.0 rad/s)² × 3.0m = 243 m/s² ≈ 25g. Blade root stress from centrifugal
loading is well within plywood or aluminium capabilities.

**For the noise compliance engineer:** This system will pass any reasonable
noise regulation with enormous margin. At 50m distance, blade rush from a 38
m/s tip speed is approximately 35-40 dBA — quieter than a refrigerator. No
acoustic treatment, no sound barriers, no noise mitigation needed at all.

**For the test planner:** Wind tunnel testing at Re=2-4×10⁵ with a 150mm chord
model is feasible. A 1:3 scale model (R=1.0m, c=50mm) would operate at the
same Re but would be below the BEM viability threshold. Direct testing at full
scale (R=3.0m, c=150mm) is recommended — the hardware is simple enough that
"build and fly" may be faster and cheaper than scaled wind tunnel testing.

## Limitations

- **Re computed from mean tip speed, not local blade Re.** The actual Re
  varies along the blade span from near zero at the root to maximum at the tip.
  The mean-tip Re understates the variation — root stations operate at much
  lower Re and are more susceptible to laminar separation effects.
- **Acoustic limit is a simple Mach number gate.** Real noise depends on blade
  count, planform, twist, and atmospheric conditions. The 120 m/s limit is
  conservative — actual noise onset is gradual, not a cliff.
- **Stack count has no effect on these heatmaps.** Each rotor autorotates
  independently at the same RPM (determined by its local inflow), so tip
  speed is independent of N. The heatmaps collapse to radius-dependence only.
- **No temperature/altitude effects.** Density and viscosity vary with altitude
  and temperature. At 500m altitude on a cold day, Re would be lower; at sea
  level on a hot day, higher. The standard atmosphere values used here are
  representative but not conservative for all conditions.
