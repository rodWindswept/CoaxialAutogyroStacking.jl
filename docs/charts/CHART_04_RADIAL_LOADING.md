# Chart 4: Radial BEM Loading — Snel 3-D Stall-Delay Correction

## Data Source

Per-station BEM induction solve at 20 radial stations (r/R = 0.2 to 0.98)
for the best configuration rotor (R=3.0m, N=2 blades, NACA 0012, c=0.15m,
tilt=10°, elevation=45°, v_wind=8 m/s, ω=84 RPM). CL,2D from NACA 0012
table lookup at local Re; CL,3D from Snel et al. (1993) rotational
stall-delay correction.

## What This Chart Shows

Lift coefficient (CL) as a function of normalised blade radius (r/R).
Two curves: blue = 2-D NACA 0012 airfoil data (no rotational correction),
red = 3-D Snel-corrected CL (accounts for centrifugal boundary-layer pumping).
A shaded band between the curves shows the Snel boost region. The root
region (r/R < 0.35, where c/r > 0.15) and tip region (r/R > 0.8) are
annotated.

## Key Findings

1. **Snel correction provides +35% local CL at root stations** (r/R < 0.35,
   c/r > 0.15). This is the centrifugal pumping effect: the radial pressure
   gradient in the rotating boundary layer drives flow outward, thinning the
   boundary layer and delaying flow separation. The (c/r)² dependence makes
   this strong at the root (c/r ≈ 0.3) and negligible at the tip (c/r < 0.03).

2. **The net thrust increase is only ~3% at the design point.** Root stations
   contribute a small fraction of total blade area and operate at lower dynamic
   pressure than tip stations. A +35% CL boost on 20% of the blade span at
   half the dynamic pressure translates to a ~3% net thrust increase. The Snel
   correction is physically real but aerodynamically modest at this scale.

3. **CL is not constant along the span.** The 2-D NACA 0012 produces a roughly
   flat CL distribution (~0.8-1.0) across most of the blade, dipping slightly
   at the tip. This is because the autorotation equilibrium drives the
   induction factor to values that produce consistent loading. The Snel boost
   creates a pronounced peak at r/R ≈ 0.25-0.30 before tapering off.

4. **The Prandtl tip-loss factor is not implemented.** The current BEM solver
   does not apply a tip-loss correction, so CL at r/R > 0.9 does not roll off
   to zero as it would in reality. This makes tip forces slightly optimistic.
   Tip-loss would reduce CL at the outermost 10% of the blade, subtracting
   perhaps 2-3% from total thrust.

5. **Post-stall behaviour is not captured.** The airfoil data extends to
   α=20° with flat-plate extrapolation beyond. At high wind speeds or extreme
   tilt angles, some stations may enter post-stall, where the Snel correction
   is less validated and the 2-D/3-D distinction becomes less meaningful.

## Design Implications

**For the blade designer:** Don't obsess over root aerodynamics. The Snel
boost at the root is physically interesting but contributes little to net
thrust. Focus on the outer 60% of the blade (r/R > 0.4) where dynamic pressure
is highest and most of the lift is produced. A tapered planform with wider
chord at mid-span and narrower at root and tip would concentrate blade area
where it matters most.

**For the aerodynamicist validating BEM:** The CL distribution reveals whether
the BEM solver is producing physically reasonable results. A flat CL curve
across the span suggests the induction loop is converging properly. Spikes or
oscillations would indicate numerical issues. The current results look clean.

**For the academic paper:** The Snel correction is the v2.1 differentiator —
it's the bridge between 2-D airfoil theory and 3-D rotating-blade reality.
The +35% root CL / +3% net thrust numbers are small but scientifically
important: they show that the correction is implemented correctly and
that root aerodynamics are not the dominant loss mechanism.

**For the test planner:** If you can only instrument one blade station for
flight testing, put it at r/R ≈ 0.7-0.8. That's where dynamic pressure is
high, CL is representative, and the Snel correction is negligible — giving
you a clean 2-D validation point. Root stations (r/R < 0.35) are the worst
choice: low dynamic pressure, high Snel sensitivity, structurally complex.

## Limitations

- **Constant chord assumption.** Real blades taper. Tapering changes the c/r
  ratio at every station, which changes the Snel correction magnitude. A
  tapered blade with wider root chord would get more Snel boost; a blade with
  narrower root chord would get less.
- **No twist.** The current model assumes zero blade twist. In a real autogyro
  rotor, blade twist (washout at the tip) would change the local α distribution
  and alter both CL and the Snel correction.
- **Fixed RPM assumption.** The 84 RPM value is from the BEM sweep at the
  design point. In reality, RPM varies with wind speed and tilt. The CL
  distribution would shift with RPM changes — higher RPM increases the Snel
  boost (via the TSR factor in the correction).
- **Snel correction validated for wind turbines, not autogyros.** The Snel
  model was developed for horizontal-axis wind turbines operating at higher
  TSR (5-10) than autogyros (2-3). The correction may overstate or understate
  the rotational effect at autogyro TSR. Validation against CFD or experiment
  at these specific conditions would be valuable.
- **NACA 0012 is symmetric.** Cambered sections (Clark Y, GOE 417) have
  different stall characteristics and would respond differently to rotational
  augmentation. The +35% number is specific to NACA 0012.
