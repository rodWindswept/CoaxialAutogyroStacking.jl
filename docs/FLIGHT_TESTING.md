# Flight Testing — Autogyro Rotor: Field Test Plan

> You've sourced, built, assembled, and ground-tested. Now fly it.
> Three sessions: solo rotor → 2-rotor stack → 4-rotor stack.
> Location: Croft (or any open field with steady wind and soft ground).
> Estimated time: 3 half-day sessions, spaced a week apart for fixes.

---

## 0. BEFORE YOU LEAVE HOME

### Weather requirements

| Parameter | Minimum | Ideal | Maximum |
|-----------|---------|-------|---------|
| Wind speed (steady) | 4 m/s | 6-8 m/s | 10 m/s |
| Gust spread | — | <3 m/s variation | 5 m/s |
| Wind direction | — | Steady (not shifting ±30°) | — |
| Precipitation | — | None | Light drizzle acceptable |
| Visibility | 500 m | Clear | — |
| Ground condition | Dry | Short grass | Not waterlogged |

**Check forecast:** Use Windy.com or the Met Office aviation forecast.
Look for a steady 6-8 m/s westerly (Croft's prevailing wind). Avoid
days with gust ratios >1.5 (gust speed / steady speed).

### Field kit checklist

```
ROTOR + RIGGING
  □ Assembled rotor(s) — fully checked per GROUND_TESTING.md
  □ Dyneema line — length depends on session (see each session)
  □ Ground stake — 600 mm steel angle iron or screw anchor
  □ Carabiners (×3) — climbing-rated, 22 kN
  □ Shackles (×2) — D-shackles, WLL 500 kg

INSTRUMENTS
  □ Load cell + readout — OR crane scale — inline between anchor and line
  □ Anemometer — handheld, for spot wind readings
  □ Camera (×2 if possible) — one wide shot of whole rig, one close on rotor
  □ Phone with slow-motion video (240 fps if available)
  □ GPS / phone — log location, time, altitude
  □ Notebook + pen (waterproof) + this test card

SAFETY
  □ First aid kit
  □ Gloves — rigging gloves (not loose fabric — Dyneema burns)
  □ Eye protection — blades can throw debris
  □ Hard hat — if rotor is overhead
  □ Knife — sharp, accessible. Cut the line if things go wrong.
  □ Mobile phone — fully charged, emergency contacts saved
  □ Fire extinguisher — if using petrol generator/blower nearby

TOOLS + SPARES
  □ Multi-tool / Leatherman
  □ Cable ties (assorted) + duct tape
  □ Spare M6 bolts + nyloc nuts (×4)
  □ Spare wheel balance weights
  □ Spare Dyneema 3 mm (5 m) — for emergency re-tie
  □ Sharpie
  □ Digital calipers (in case of post-flight inspection)

COMFORT
  □ Water (2+ litres per person)
  □ Snacks / lunch
  □ Sunscreen / hat / warm layer (Croft wind chill is real)
  □ Folding chair
  □ Bin bag — pack out all rubbish
```

---

## 1. SESSION 1 — Single Rotor

**Goal:** Prove one rotor autorotates in real wind, produces measurable
tension, and flies stably for 10+ minutes.

### Setup

```
                    ┌───┐
                    │ R │  Single rotor
                    └─┬─┘
                      │
                      │  Dyneema (~15 m)
                      │
                 ┌────┴────┐
                 │  LOAD   │  Load cell
                 │  CELL   │
                 └────┬────┘
                      │
                 ─────┴─────  Ground stake
                 GROUND
```

1. Drive the ground stake into firm soil at a 15° angle away from
   the expected pull direction. It should be 500+ mm deep.
2. Attach the load cell to the stake with a shackle.
3. Attach the Dyneema to the load cell with a carabiner.
4. Walk the rotor downwind. Let out ~10 m of line initially.
5. The rotor will lie on the ground. Orient it so the blades are
   horizontal (parallel to the ground) and the disk faces the wind.

### Launch procedure

6. **Wind check**: measure with anemometer at head height. If <4 m/s
   or >10 m/s: abort. Wait or come back another day.
7. **Camera on**: start both cameras recording.
8. **Launch**: lift the rotor by the tail boom and point the disk
   into the wind. The rotor should tilt back and the blades should
   start spinning.
9. **If blades don't spin**: the disk angle is wrong. Tilt the
   rotor further back (more nose-up relative to wind). Try a hand
   spin to get it started.
10. **Once spinning**: walk backward, letting out line slowly. Keep
    tension on the line — don't let it go slack. The rotor will climb
    as line tension increases.
11. **Target altitude**: ~10-15 m above ground. Enough to be clear
    of ground turbulence but low enough to see what's happening.

### Data collection (fly for 10 minutes minimum)

Record every 60 seconds:

| Time | Wind (m/s) | Tension (kg) | RPM | Altitude (est.) | Notes |
|------|-----------|-------------|-----|-----------------|-------|
| 0:00 | | | | | Launch |
| 1:00 | | | | | |
| 2:00 | | | | | |
| ... | | | | | |

RPM is hard to measure in flight without telemetry. Options:
- Bike speedometer with magnet on hub (wired sensor taped to tube)
- Optical tachometer aimed from the ground (needs clear line of sight
  to the reflective tape on one blade tip)
- Estimate from video: count blade passes per second in slow-motion
  (2 blades = 2 passes per revolution). 45 RPM = 1.5 blade passes/sec.

### Observations to record

- **Does it self-start?** Every launch, or only with help?
- **Blade tracking**: are both blade tips following the same plane?
  Look for one blade higher than the other — camera from the side.
- **Vibration**: visible shake? Noise level? Does it change with RPM?
- **Weathervane**: does the empennage keep the rotor facing the wind?
  Or does it oscillate / spin?
- **Line angle**: estimate the Dyneema angle from horizontal. Does it
  match the expected 55°? Steeper = less lift than predicted.
- **Stability**: does the rotor sit steady or wander? Gust response —
  does it bob or stay planted?
- **Any unusual noise**: click = something loose. Scrape = blade
  contacting tube or tail. Whistle = blade aerodynamic issue.

### Landing

12. Walk forward, reeling in line hand-over-hand (wear gloves —
    Dyneema under tension is a cheese wire).
13. As the rotor descends, it will lose RPM. Keep tension on — a
    slack line can wrap around a blade.
14. When the rotor is 2 m above ground: have your assistant grab the
    tail boom. Don't grab a blade — it's still spinning.
15. Stop the rotor by hand (gloved) on the hub — not the blade tip.

### Post-flight inspection (immediately)

```
□ All bolts still tight? (Check every one with a spanner)
□ Bearings spin freely? (Flick test — should be same as pre-flight)
□ Bearing temperature? (Warm = fine, hot = problem)
□ Blades undamaged? (Check root for cracks, tips for impact damage)
□ Dyneema OK? (Run through hands — feel for abrasion, broken strands)
□ Knots secure? (Sharpie marks still aligned?)
□ Tie holes OK? (Still round?)
□ Tail surfaces OK? (No cracks, bolts tight)
□ Tube straight? (Sight along it)
```

### Success criteria — Session 1

| Must have | Nice to have |
|-----------|-------------|
| Rotor self-starts in ≥6 m/s wind | Self-starts in 4 m/s |
| Flies stably for 10+ minutes | 30+ minutes continuous |
| Measurable tension (>20 kg on load cell) | Tension within 30% of model prediction |
| No mechanical failures | No adjustments needed mid-flight |
| Empennage weathervanes correctly | — |
| Landed under control | Caught by hand without ground contact |

**If success criteria met**: proceed to Session 2 next week.
**If not**: fix issues, re-test Session 1. Do not stack a second
rotor until the first one flies reliably.

---

## 2. SESSION 2 — Two-Rotor Stack

**Goal:** Verify progressive tension accumulation. Prove two rotors
don't collide, tangle, or interfere aerodynamically.

### Setup

```
                    ┌───┐
                    │R1 │  Top rotor (terminates line)
                    └─┬─┘
                      │  15 m spacing
                    ┌─┴─┐
                    │R2 │  Bottom rotor
                    └─┬─┘
                      │  10 m to anchor
                 ┌────┴────┐
                 │  LOAD   │
                 │  CELL   │
                 └────┬────┘
                 GROUND
```

1. Both rotors on one continuous Dyneema line, 15 m apart.
   (If following ASSEMBLY.md, you should have built them this way.)
2. Lay out the stack on the ground downwind of the anchor: R2 closest
   to anchor, R1 15 m beyond.
3. Check both rotors spin freely. Check all knots, bolts, tail surfaces
   on both units.

### Launch (harder with two)

4. Launch R1 (top rotor) first. It's the furthest downwind. Get it
   airborne and spinning.
5. Walk backward, letting out line. As R1 climbs, R2 will lift off
   the ground. The line between them should tension.
6. Guide R2's disk into the wind. It should start spinning as it
   leaves the ground.
7. Target altitude: R1 at ~25 m, R2 at ~10 m. The stack should form
   a roughly straight line at the elevation angle.

### What can go wrong (that couldn't with one)

- **Line twist**: two rotors weathervaning independently can twist
  the Dyneema between them. If the line twists, the rotors may face
  different directions. Watch for this. A swivel at each tie point
  prevents it — add one if needed.
- **Mid-line collision**: in a gust or lull, the line between rotors
  can slack momentarily and the rotors can drift together. They
  shouldn't collide (15 m spacing is generous) but watch for it.
- **Wake interaction**: R1's wake may reduce the wind seen by R2.
  You'll see this as R2 spinning slower than R1 at the same wind
  speed. Expected — the model assumes no wake in v1/v2. Measure the
  RPM difference.
- **Tension step**: the load cell should show a clear increase when
  R1 is added vs R2 alone. Compare to Session 1 data.

### Data collection

Same 60-second logging as Session 1, but add:

| Time | Wind | Tension | RPM-R1 | RPM-R2 | Notes |
|------|------|---------|--------|--------|-------|

### Success criteria — Session 2

| Must have | Nice to have |
|-----------|-------------|
| Both rotors self-start | Within 30 seconds of each other |
| No mid-line collision | — |
| Tension >1.5× single rotor | Tension ≈2× single rotor |
| Both empennages weathervane | Perfect alignment |
| Fly for 15+ minutes | 30+ minutes |
| Landed under control | Individual rotor landing |

---

## 3. SESSION 3 — Four-Rotor Stack

**Goal:** Full configuration. Prove the stack delivers ~5 kN at 8 m/s
and flies stably as a complete system.

### Setup

```
                    ┌───┐
                    │R1 │  Top
                    └─┬─┘  15 m
                    ┌─┴─┐
                    │R2 │
                    └─┬─┘  15 m
                    ┌─┴─┐
                    │R3 │
                    └─┬─┘  15 m
                    ┌─┴─┐
                    │R4 │  Bottom
                    └─┬─┘  10 m
                 ┌────┴────┐
                 │  LOAD   │
                 │  CELL   │
                 └────┬────┘
                 GROUND
```

### Launch (this takes practice)

Launch sequence: R1 → R2 → R3 → R4, from top to bottom.

1. With 60 m of line and 4 rotors laid out on the ground, launch
   is a two-person job. One person manages the line, the other
   guides each rotor into the wind as it lifts off.
2. Start with R1 (furthest downwind). Get it up and stable.
3. Walk back. As the line tensions, R2 will lift. Guide its disk.
4. Repeat for R3, then R4.
5. The stack should form a near-straight line. If the wind is steady,
   all 4 rotors should align like beads on a string.

### Key measurements

| What | How | Expected |
|------|-----|----------|
| Total anchor tension | Load cell at ground | ~500 kg at 8 m/s (model: 5,065 N ≈ 516 kg) |
| Tension linearity | Compare to 1-rotor and 2-rotor sessions | Should be roughly N × single-rotor tension |
| Stack angle | Estimate from ground — protractor app on phone | ~55° from horizontal |
| Rotor spacing | Visual check | ~15 m between each, no bunching |
| Gust response | Watch during gusts — does the stack stay organised? | Should weathervane as a unit |

### Data collection

| Time | Wind | Tension | R1 RPM | R2 RPM | R3 RPM | R4 RPM | Stack angle | Notes |
|------|------|---------|--------|--------|--------|--------|-------------|-------|

Measuring 4 RPMs simultaneously is hard without telemetry. Prioritise:
- R4 (bottom — highest tension, most interesting structurally)
- R1 (top — free-stream wind, baseline RPM)

If you can only measure one, measure R1.

### The money shot

At 8 m/s steady wind, record:
- **Anchor tension** (the number you designed for — 5,065 N)
- **Video** of the full stack from the side (shows line angle, rotor
  alignment, spacing)
- **Close-up video** of one rotor disk (shows RPM, blade tracking,
  any vibration)

This is the footage that proves the concept works.

### Success criteria — Session 3

| Must have | Nice to have |
|-----------|-------------|
| All 4 rotors fly without collision | Perfect spacing maintained |
| Anchor tension ≥300 kg at 8 m/s | ≥500 kg (matching model prediction) |
| Stack stable for 15+ minutes | 30+ minutes in varying wind |
| No mechanical failures on any rotor | — |
| Landed under control | Individual landing — bring them down one by one |
| Tension scales with rotor count | Within 20% of linear scaling |

---

## 4. EMERGENCY PROCEDURES

### Line break

If the Dyneema parts:
1. **Shout "BREAK"** — everyone look up.
2. The rotor(s) will fly downwind like a kite that's lost its string.
   They're lightweight (5 kg each) and will tumble. Let them fall —
   don't chase.
3. Once on the ground, approach carefully — blades may still be
   spinning or sharp from impact damage.

### Rotor tangle (two rotors collide)

1. If the line wraps around a blade: the rotor will stop spinning
   and the stack will destabilise. Tension will drop suddenly.
2. Reel in the line steadily — don't jerk. Jerking can tighten the
   tangle.
3. Land all rotors as quickly as possible. Untangle on the ground.

### Ground stake pulls out

1. The entire stack will fly away downwind, trailing the stake.
2. If the load cell is between the stake and the line, it'll go too.
   Attach a secondary safety line from the stake to a fixed object
   (fence, vehicle) as backup.
3. If the stack gets away: let it go. Do NOT grab the line — 500 kg
   of tension will pull you off your feet or deglove your hand.

### Person tangled in line

1. **Cut the line immediately.** Knife should be in your pocket,
   not in a bag. One-handed opening.
2. Dyneema under tension cuts skin to the bone. Do not try to
   untangle a loaded line by hand.
3. First aid: apply pressure, call 999. Croft postcode: give to
   your assistant before the test.

### Wind picks up beyond 10 m/s

1. If the anemometer reads sustained >10 m/s: land immediately.
2. The rotor was designed for 8 m/s cruise, 12 m/s max. At 15 m/s
   gust, tension will be ~4× higher (v² scaling) — potentially
   20 kN, well beyond the 2 kN ground test.
3. Don't wait to see if it holds. Land.

---

## 5. POST-FLIGHT — BACK AT THE WORKSHOP

### Teardown inspection

1. Disassemble each rotor to component level.
2. Inspect under bright light:
   - Bearings: any pitting on the raceways? (Magnifying glass)
   - Tube: any cracks at tie holes? (Dye penetrant if available)
   - Hub: any scoring on the bearing journal?
   - Moldings: any cracks at the angled face?
   - Blades: any delamination? (Tap test — dull thud = delam)
   - Dyneema: any broken strands? (Bend test — kinked section = damaged)
3. Photograph any damage. Write up findings in the flight log.

### Data analysis

4. Plot tension vs wind speed for all three sessions. Does it
   follow the predicted v² curve?
5. Plot tension vs rotor count at 8 m/s. Is it linear?
6. Compare measured RPM to model prediction. Calculate the
   effective tip-speed ratio λ_eff = ΩR / v_wind.
7. Write up a one-page flight report: what worked, what didn't,
   what needs changing before the next session.

### Publish

8. Put the flight report, tension data, and best video clips in
   `docs/flight-reports/` in the repo.
9. This is the evidence that convinces people the concept works.

---

## 6. FLIGHT TEST CARD — Print This Page

```
FLIGHT TEST CARD — Autogyro Rotor
Session: □ 1 (single)  □ 2 (dual)  □ 3 (quad)

Date: ________    Location: ________    Forecast wind: ____ m/s
Crew: ____________________ , ____________________

── PRE-FLIGHT ──
□ Weather check: wind ____ m/s  (OK: 4-10 m/s)
□ All bolts checked
□ Bearings spin freely
□ Dyneema + knots visual check
□ Cameras recording
□ Load cell zeroed

── FLIGHT LOG (every 60 sec) ──
Time  Wind  Tension  RPM-1  RPM-2  RPM-3  RPM-4  Notes
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
____  ____  _______  _____  _____  _____  _____  ________________
(continue on back)

── LANDING ──
Time airborne: ____ min    Landing: □ Controlled  □ Hard  □ Crash
Post-flight bearing temp: □ Cold  □ Warm  □ Hot

── POST-FLIGHT INSPECTION ──
Rotor 1:  Bolts □  Bearings □  Blades □  Dyneema □  Tube □  Tail □
Rotor 2:  Bolts □  Bearings □  Blades □  Dyneema □  Tube □  Tail □
Rotor 3:  Bolts □  Bearings □  Blades □  Dyneema □  Tube □  Tail □
Rotor 4:  Bolts □  Bearings □  Blades □  Dyneema □  Tube □  Tail □

Any damage noted? _________________________________________

── SESSION RESULT ──
□ PASS — Proceed to next session
□ PARTIAL — Fly again same configuration after fixes:
  _________________________________________________________
□ FAIL — Major redesign needed:
  _________________________________________________________

Signed: ____________________  Date: ________
```
