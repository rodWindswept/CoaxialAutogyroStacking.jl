# IMPLICATIONS.md — bem-tension-accum

## Finding

Tension accumulates toward the anchor in distinct steps — each rotor adds
a discrete force (~1,250 N at 8 m/s, ~5,200 N at 16 m/s) to the line.
Between rotors, bare-line drag adds smaller additional tension. The tension
above the topmost rotor drops to zero at the free end.

## Significance

The anchor sees the full stack load. At 16 m/s, the peak tension exceeds
20 kN — equivalent to supporting over 2 tonnes. The anchor line and ground
attachment must be rated for this worst-case load. Each rotor adds roughly
equal force because they all see the same freestream wind speed in the
current model.

## Caveat: wind gradient

Wind speed increases with height above ground. The current model applies
the same `v_wind` to all rotors. With real wind shear (exponent 0.14),
a rotor at 60m AGL sees ~28% faster wind than one at 15m. This would make
the upper tension steps larger than the lower ones. Future work should
apply a wind profile (e.g. power law) across the stack.

## Consequence

- Anchor hardware: rated for ≥25 kN (safety factor on 20 kN peak).
- Line selection: breaking strength must exceed max anchor tension.
- Stack design: more rotors = more lift but proportionally more tension.
  The top rotor contributes nothing to its own section's tension burden.
