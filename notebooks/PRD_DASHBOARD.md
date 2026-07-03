# Dashboard Geometry PRD — Coaxial Autogyro Stacking

> The side-view diagram must reflect how a kite actually flies. Current dashboard
> gets the broad strokes right but loses the physics in the visual details.

## 1. Fundamental Geometry (non-negotiable)

```
          WIND →
          ======
          
    R1 ●─────────────── ← topmost rotor, terminates the line
         ╲
          ╲  section 1  ← rotor R1 pulls this section up
           ╲
    R2 ●───────────────
            ╲
             ╲  section 2
              ╲
    R3 ●────────────────
               ╲
                ╲  section 3
                 ╲
    ⚓ ANCHOR ──────── ground
```

**Rule 1: The kite is ABOVE its line section.**  
Each rotor sits at the top end of the line segment it pulls. The segment hangs
below the rotor, not the other way round. The rotor does not sit ON the line
like a bead — it is the thing pulling the line UP.

**Rule 2: The line terminates at the topmost rotor.**  
There is no line above R1. R1 is the free end. Tension is zero at R1 and
accumulates downward through each successive rotor to the anchor.

**Rule 3: Tension increases downward.**  
Each rotor adds its along-line force (F_line) to the tension below it.
Anchor tension = sum of all rotor contributions minus weight corrections.
The side-view line should thicken and redden toward the anchor.

**Rule 4: Wind pushes the kite; the line tethers it.**  
The wind blows horizontally. The line rises at elevation φ. The rotor disk
tilts to catch the wind from below (like a kite). The along-line component
of the aerodynamic force is what pulls the line taut.

## 2. Side-View Visual Requirements

### What to show
- Ground plane (dashed line at y=0)
- Anchor point at origin (0, 0)
- Dyneema line segments between rotors, each coloured by local tension
- Rotor disks as ellipses at segment junctions, tilted to show disk angle
- R1 at the top (terminates line), Rn nearest anchor
- Wind arrow showing direction and speed
- Tension colour legend (green=low → red=high, with scale)

### What NOT to show
- Line extending above the top rotor (physics error — nothing pulls above R1)
- Rotors drawn as beads threaded ON the line (they are at the TOP of each segment, pulling upward)
- Rotor ellipses that obscure the line junction (rotor should sit at the junction, above its section)

### Correct segment-rotor relationship

```
  WRONG:  ──●──●──●──  anchor    (rotors are beads on the line)
  
  RIGHT:  ●──●──●──⚓           (each rotor pulls the section below it,
           ╲  ╲  ╲                line hangs from rotor downward)
```

In the side view, the line should appear to hang FROM each rotor, going down
to the next rotor or anchor. The rotor is the high point of each segment.

## 3. Tension Chart Requirements

Two data series on the same chart:

1. **Cumulative tension** (purple stepped line) — tension in the line at each
   rotor position, accumulating from top (R1≈0) to anchor (max). Steps downward,
   increasing at each rotor. X-axis = position from anchor (m), anchor at 0.

2. **Per-rotor contribution** (blue bars) — how much each rotor individually
   adds to the line tension (F_line − mg·cos φ). One bar per rotor.

Legend distinguishing both series. Rotor labels (R1..Rn) at bar tops.

## 4. HUD Requirements

Text panel showing:
- Wind speed, elevation, line diameter, total span
- Per-rotor: effective α, CL, CD, F_line
- Anchor tension, total L/D
- Power comparison (TRPT vs yo-yo)
- Tension range and kite spec name

## 5. Colour Convention

| Element | Colour | Meaning |
|---------|--------|---------|
| Line segments | Green→Red gradient | Tension: green=low, red=high |
| Rotor disks | Red-tinted, 25% alpha | Matches line tension colour at that position |
| Anchor | Saddle brown | Ground attachment |
| Wind arrow | Steel blue | Wind direction/speed |
| Cumulative tension | Purple | Total line tension |
| Per-rotor bars | Steel blue | Individual rotor contribution |
| Ground | Grey dashed | Reference plane |

## 6. Acceptance Criteria

- [ ] Line terminates at top rotor — nothing above R1
- [ ] Each rotor sits at the TOP of its line section
- [ ] Line thickens and reddens toward anchor
- [ ] Colour legend visible with min/max values
- [ ] Tension chart shows both cumulative and per-rotor
- [ ] Anchor at origin (0,0), ground visible
- [ ] Wind arrow horizontal, labelled with speed
