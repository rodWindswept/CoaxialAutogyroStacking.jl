# Ground Testing — One Autogyro Rotor: Test Plan

> Before you fly, validate everything on the ground. If it breaks here,
> you walk back to the workshop. If it breaks at 50 m altitude, you
> walk the field picking up pieces.
>
> Prerequisites: rotor fully assembled per ASSEMBLY.md. All bolts
> checked. Bearings spin freely. Dyneema knots bedded.
> Estimated time: 3-4 hours for the full test sequence.

---

## 0. TEST RIG — What You Need

### Anchor setup

You need a solid anchor point that can hold 2 kN without moving.
A car tow hook, a heavy fence post, or a ground stake driven 600 mm
into firm soil (not sand — it'll pull out).

```
  CEILING HOOK / GANTRY
         │
         │  Dyneema (top)
         │
    ┌────┴────┐
    │  ROTOR  │  ← suspended at working height
    └────┬────┘
         │
         │  Dyneema (bottom)
         │
    ┌────┴────┐
    │  LOAD   │  ← load cell (measures tension)
    │  CELL   │
    └────┬────┘
         │
    ─────┴─────  ANCHOR POINT (ground stake / tow hook)
```

### Equipment checklist

```
□ Load cell — 0-500 kg (5 kN), with digital readout
  Recommended: S-type load cell, 500 kg, ~£30-40 on eBay/Amazon
  Alternative: crane scale (the kind anglers use) — £15-25, less precise

□ Come-along (hand winch) OR ratchet strap — 2+ ton capacity
  For static load testing. Not used during spin test.

□ Digital tachometer — optical/laser, ~£10-15 on eBay
  For measuring rotor RPM. Point at reflective tape on blade tip.
  Alternative: bike speedometer — magnet on hub, sensor on tube.

□ Anemometer — handheld wind speed meter, ~£15-25
  For measuring the fan/blower output. Or use a weather station.

□ Fan or blower — must produce 6-10 m/s airflow across a 3 m disk
  Options (see §3 for details):
  A) Leaf blower — ~£40, 60-80 m/s at nozzle, narrow jet
  B) Industrial pedestal fan — ~£60-100, 5-8 m/s, wide spread
  C) Natural wind — free, unreliable, wait for a breezy day

□ Camera / phone — video the tests. You'll want slow-motion replay.

□ Cable ties, duct tape, zip ties — temporary rigging fixes

□ Load cell mounting hardware:
  - 2× M12 eye bolts + nuts (for load cell shackles)
  - 2× shackles (D-shackles, WLL 500 kg minimum)
  - 2× carabiners (climbing-rated, 22 kN minimum)

□ Reflective tape — for tachometer

□ Notebook + pen — write down every measurement

□ Safety: gloves (rigging), eye protection (spin test — blades can
  throw debris), hard hat (if testing overhead), first aid kit
```

---

## 1. STATIC LOAD TEST — 2 kN pull

### Purpose

Verify the Dyneema knots hold, the tube doesn't buckle, the moldings
don't shift, and there's no permanent deformation anywhere.

### Setup

1. Tie the top Dyneema to an overhead anchor (tree branch, gantry,
   ladder A-frame — anything rated for 200+ kg).
2. Attach the load cell between the bottom Dyneema and the ground
   anchor using shackles. The load cell must be INLINE — it reads
   the tension directly.
3. Attach the come-along in parallel or series with the load cell
   — you need to gradually increase tension.

```
  Overhead anchor
       │
       │
  ┌────┴────┐
  │  ROTOR  │
  └────┬────┘
       │
  ┌────┴────┐
  │  LOAD   │ ← reads tension in real time
  │  CELL   │
  └────┬────┘
       │
  ┌────┴────┐
  │  COME-  │ ← increases tension
  │  ALONG  │
  └────┬────┘
       │
  ─────┴─────  GROUND ANCHOR
```

### Procedure

4. Take up slack with the come-along until the load cell reads
   ~10 kg (100 N). This is the rotor's own weight.
5. Record: does the rotor hang vertically? Are the blades level?
   Take a photo — this is your baseline.
6. Increase tension in 50 kg (500 N) increments:
   - Pull to 50 kg. Hold 30 seconds. Check all knots, moldings,
     tube straightness. Record load cell reading.
   - Pull to 100 kg. Hold 30 seconds. Check again.
   - Pull to 150 kg. Hold 30 seconds.
   - Pull to 200 kg. Hold 60 seconds. This is the full test load.
7. At 200 kg: photograph the setup. Check:
   - Dyneema knots: any slippage? Mark the Dyneema with a Sharpie
     at each knot BEFORE the test. After the test, check if the
     mark has moved relative to the knot. Any movement = knot is
     slipping = re-tie with more bedding.
   - Tube: sight along it. Any bow or bend?
   - Moldings: any gap between molding and bearing? They should
     be compressed TIGHTER under load, not separating.
   - Tie holes: any elongation? The aluminium/carbon around the
     5 mm hole should be unchanged.
8. Hold at 200 kg for 60 seconds. Release tension SLOWLY — don't
   just pop the come-along.

### Pass/fail criteria

| Check | Pass | Fail |
|-------|------|------|
| Knots | No slippage (Sharpie marks unmoved) | Any movement |
| Tube | Straight, no bow | Visible bend or crack |
| Moldings | Seated firmly, no gap | Gap visible, shifted position |
| Tie holes | Round, no elongation | Oval shape, cracking at edges |
| Dyneema | No fraying at knots | Broken strands, abrasion |
| Bearings (post-test) | Spin freely | Grinding, tight spots |

### If anything fails

- **Knot slippage**: re-tie with more initial bedding (100 kg pull
  before assembly). Add a second stopper knot.
- **Tube bend**: tube wall too thin for the compression load. Switch
  to thicker wall (see MATERIAL_SOURCING.md §3 options).
- **Molding shift**: add cable tie retainers. For permanent fix,
  add a grub screw through the molding into the tube wall (NOT
  into the Dyneema bore — drill radial, stop before the bore).
- **Tie hole elongation**: the hole is tearing. Wrap the tube at the
  tie station with a band of glass fibre + epoxy to reinforce.

---

## 2. SPIN TEST — Induced autorotation

### Purpose

Verify the rotor autorotates, reaches predicted RPM, doesn't vibrate
excessively, and the bearings don't overheat.

### Setup

1. Suspend the rotor as in §1, but with the bottom Dyneema free
   (not anchored — the rotor needs to hang freely).
2. Position the fan/blower to blow air at the rotor disk. The airflow
   should hit the disk from BELOW (simulating the autogyro's tilted
   orientation to the wind).
3. Mount the tachometer aimed at the blade tip. Stick a 20×20 mm
   piece of reflective tape on one blade tip. Aim the laser at the
   path the tape will take.
4. Set up the camera on a tripod. Frame the entire rotor. Record
   video at 60 fps minimum (slow-motion on most phones).

```
  Overhead anchor
       │
       │
  ┌────┴────┐
  │  ROTOR  │ ← hangs freely
  └────┬────┘
       │
       │  (bottom Dyneema hangs loose)
       │
  ─────┴─────
       ▲
       │  airflow from below/forward
  ┌────┴────┐
  │   FAN   │
  └─────────┘
```

### Fan placement

The rotor hangs at 55° to horizontal (its operating angle). The fan
needs to blow air at an angle that produces an effective AoA of ~45°
at the rotor disk.

For a rotor at 55° elevation with 10° forward tilt:
- Wind should come from slightly below and in front of the rotor
- Place the fan ~2-3 m away, aimed at the lower half of the disk
- Use the anemometer to measure airflow speed at the rotor position
  BEFORE mounting the rotor (it'll disturb the reading)

### Procedure

5. Turn on the tachometer. Zero it if needed.
6. Start recording video.
7. Turn on the fan at lowest speed.
8. Observe: does the rotor start spinning? An autogyro rotor should
   self-start — the airflow pushes the blades and they begin to
   autorotate without external help.
9. If it doesn't start: give it a gentle push by hand in the
   direction of rotation (clockwise from above, typically).
10. Once spinning, increase fan speed stepwise. At each step:
    - Wait 30 seconds for RPM to stabilise
    - Record: fan setting, wind speed (anemometer), RPM
    - Note any vibration or noise
11. Run at maximum fan speed for 5 minutes continuous. This is the
    endurance test — bearings heating up, blades at maximum RPM.
12. Record RPM every 60 seconds during the endurance run.
13. After 5 minutes: turn off fan. Let rotor spin down naturally.
    Time how long it takes to stop — this tells you about bearing
    friction.
14. Immediately after stopping: touch the bearings. Warm is fine.
    Hot to the touch (>50°C) = too much friction or insufficient
    lubrication.

### Expected results (from model)

| Wind speed | Predicted RPM | Tip speed |
|------------|---------------|-----------|
| 4 m/s | ~23 | 7.2 m/s |
| 6 m/s | ~34 | 10.7 m/s |
| 8 m/s | ~45 | 14.1 m/s |
| 10 m/s | ~57 | 17.9 m/s |

Predicted relationship: RPM ≈ 5.7 × wind_speed (for R=3.0m, λ=2.5).
Your measured RPM should be within ±20% of prediction on the first
test. Don't expect exact agreement — your blades are Clark Y, not
NACA 0012, and the fan airflow is non-uniform.

### Pass/fail criteria

| Check | Pass | Fail |
|-------|------|------|
| Self-start | Spins from airflow alone | Needs manual push every time |
| RPM range | Within 50% of predicted | Orders of magnitude off |
| Vibration | Smooth rotation, no visible wobble | Visible shake, blades oscillating |
| Noise | Wind rush only, no mechanical noise | Grinding, clicking, scraping |
| Bearing temp | <40°C after 5 min run | Hot to touch (>50°C) |
| Spin-down time | >10 seconds from 45 RPM | Stops abruptly (<3 sec) |
| Blade tracking | Tips follow same plane | One blade higher than the other |

### If anything fails

- **Won't self-start**: blade pitch angle may be wrong. Try adjusting
  the blade mounting angle by 2-3°. The Clark Y needs positive incidence
  to autorotate — the flat bottom should face slightly into the airflow.
- **Low RPM**: blades too heavy, bearings too tight, or fan too weak.
  Re-check bearing spin-down time unloaded (should be 15+ seconds).
- **Vibration**: blades unbalanced. Re-balance (MANUFACTURING.md §6d).
  If already balanced, check blade tracking — one blade may be mounted
  at a different angle.
- **Bearing overheat**: too much preload. The moldings may be clamping
  the bearings axially. Add a 0.5 mm shim washer between the molding
  and bearing to reduce preload.

---

## 3. FAN/BLOWER OPTIONS — Detailed

### Option A: Leaf blower (cheapest, easiest)

A petrol or electric leaf blower produces 60-80 m/s at the nozzle.
The jet is narrow (~150 mm diameter) so you'll only excite part of
the disk. Move the blower slowly across the disk face to get an
average reading.

- Petrol: ~£40 used on eBay, noisy, infinite runtime
- Electric corded: ~£30, quieter, need mains power in the field
- Battery: ~£60, portable but limited runtime (~20 min on full power)

**Downside**: the narrow jet may not start the full 3 m rotor.
You might need to hand-start and then use the blower to sustain RPM.

### Option B: Industrial pedestal fan (best)

A 750 mm (30") pedestal fan produces ~6-8 m/s across a wide area.
This is closer to the operating condition — uniform flow across
the whole disk.

- Sealey HVSF30 or similar: ~£80-100
- Hire from HSS / Travis Perkins: ~£15/day
- Borrow from a workshop: free

**Recommended** for the spin test. Worth the money — uniform flow
gives meaningful RPM data.

### Option C: Natural wind (free, unreliable)

Wait for a forecast of 6-10 m/s steady wind (Beaufort 4 — moderate
breeze, small branches move). Set up the rotor on a ridge or open
field. The wind is naturally turbulent so RPM will fluctuate — take
the average over 60 seconds.

**Downside**: you can't control it. If the wind dies, you wait. If
it gusts to 15 m/s, your prototype gets a baptism of fire.

### Option D: Car/trailer (mobile test rig)

Mount the rotor on a trailer, anchor the bottom line to the tow
hitch, drive at 15-30 mph (7-13 m/s) on a quiet road or airfield.
The rotor autorotates in the apparent wind. This is how the Wright
brothers tested their propellers.

**Requires**: a trailer, a driver, a quiet road, and a brave assistant
holding the tachometer. Not recommended for the first test.

---

## 4. INSTRUMENTATION — Load Cell Setup

### S-type load cell wiring

Most cheap S-type load cells use a Wheatstone bridge with 5 wires:
red (excitation+), black (excitation-), green (signal+), white (signal-),
and a bare shield wire.

To read it, you need an amplifier (HX711 module, ~£3 on eBay) and an
Arduino or Raspberry Pi, or a dedicated load cell readout.

### Simple option: crane scale

A digital crane scale (the kind with a hook and a display) is plug-
and-play. Shackle it inline between the Dyneema and the anchor.
Accuracy is ±0.5 kg typically — plenty for ground testing.

- 300 kg crane scale: ~£15-25 on Amazon/eBay
- Runs on AA batteries
- Peak-hold function (captures maximum tension)

### Recording data

For the static load test, write down readings manually.
For the spin test, video the tachometer display and the rotor
simultaneously. You can extract RPM frame-by-frame from the video
if needed.

---

## 5. TEST CARD — Print This Page

Take this to the test site on a clipboard:

```
GROUND TEST CARD — Autogyro Rotor Prototype
Date: ________    Location: ________    Wind: ____ m/s

── STATIC LOAD TEST ──
Baseline (10 kg):   Knots OK? □   Tube straight? □
 50 kg (500 N):     Knots OK? □   Tube straight? □   Moldings seated? □
100 kg (1 kN):      Knots OK? □   Tube straight? □   Moldings seated? □
150 kg (1.5 kN):    Knots OK? □   Tube straight? □   Moldings seated? □
200 kg (2 kN):      Knots OK? □   Tube straight? □   Moldings seated? □
                    Tie holes OK? □   Dyneema OK? □
Post-test bearing check: Spin freely? □   Duration: ____ sec

── SPIN TEST ──
Fan type: ________    Distance from rotor: ____ m
Self-start? □ Yes  □ No (needed push)

Wind speed   RPM    Notes
________    _____   _______________________
________    _____   _______________________
________    _____   _______________________
________    _____   _______________________
________    _____   _______________________

Endurance run (5 min at max fan):
  Start RPM: _____   End RPM: _____
  Bearing temp after: _____ °C  (warm / hot / cold)
  Spin-down time: _____ sec

── POST-TEST INSPECTION ──
□ All bolts still tight
□ Dyneema OK (no fraying)
□ Blades OK (no cracks at root)
□ Bearings OK (smooth, no play)
□ Tube OK (straight, no cracks at tie holes)
□ Tail surfaces OK

── DECISION ──
□ PASS — Ready for flight test (Gap 5)
□ FAIL — Fix issues above, re-test
  Issues to fix: ________________________________
```
