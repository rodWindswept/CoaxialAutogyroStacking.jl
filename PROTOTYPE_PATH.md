# Path to Prototype — From Digital Model to Flying Hardware

> Gap analysis: what stands between the Phase 9 mechanical design and a
> working prototype Rod can test in the field.

---

## Where we are now

The digital design is complete:

- 3D models (OpenSCAD) with all components dimensioned
- Material selections (carbon fibre tube, aluminium hub/moldings, SKF bearings)
- Force calculations validated (anchor tension, bearing loads, gyro moments)
- Safety margins checked (146× on tube, 16× on bearings, 140× on bearing speed)
- Component drawings (isometric, front, side, cross-section)

What's **missing:** physical hardware. No parts have been manufactured or sourced.

---

## Gap 1: Material sourcing (~1 week, ~£200-400)

### Off-the-shelf components (buy, don't make)

| Component | Spec | Source | Est. cost |
|-----------|------|--------|-----------|
| Dyneema SK99 line | 4 mm, ~50 m length | Marlow Ropes / Liros | £30-50 |
| SKF 51105 thrust bearings | 2 per rotor × 4 rotors = 8 units | Simply Bearings / RS | £8-12 each (£64-96) |
| Carbon fibre tube | 25 mm OD, 15 mm ID, 1 m lengths | Easy Composites | £15-20 per m (£60-80) |
| Aluminium round stock | 80 mm OD (hub), 70 mm OD (moldings) | Aluminium Warehouse | £30-50 |
| Linear actuators | 3 per rotor, 10 mm stroke, ~2 kg force | Hobbyking / Amazon | £8-15 each (£96-180) |
| Spectra webbing | 25 mm, for spliced eyes | eBay / chandlery | £10-20 |
| Stitching cord | 3 mm Dyneema | As above | £10 |
| Tail boom tube | 16 mm OD aluminium or carbon | Hobbyking | £10-15 |

**Total off-the-shelf: ~£200-400**

### Parts to manufacture

| Part | Material | Process | Difficulty |
|------|----------|---------|------------|
| Hub (80×27×60 mm) | Aluminium 6061 | Lathe — bore + face | Medium |
| Top/bottom moldings (2 per rotor) | Aluminium 6061 | Lathe + angled face mill | Medium-Hard |
| Swashplate rings | Aluminium | Lathe | Medium |
| Rotor blades (2 per rotor) | Plywood / foam core / 3D print | Hand shape or CNC | Medium |
| Tail surfaces (H-stab, V-fin) | Plywood / coroplast | Hand cut | Easy |
| Actuator mounts | Aluminium / 3D print | Drill press / FDM | Easy |

---

## Gap 2: Manufacturing (~2-3 weekends)

### Option A: Machine shop (Rod has access)

Rod's workspace has a lathe and mill. The hub, moldings, and swashplate are
all turned parts — straightforward lathe work. The angled bearing faces on the
moldings need a rotary table or careful setup but are within hobbyist reach.

**Timeline:** 2-3 weekends for a complete 4-rotor set.

### Option B: 3D printing prototype

For a **non-flying fit-check prototype**, all parts can be FDM-printed in PLA.
This validates assembly, clearances, and swashplate kinematics without the
cost/time of machining aluminium. The printed parts won't survive flight loads
but confirm the design before committing to metal.

**Timeline:** 1 weekend of printing + assembly.

### Option C: Hybrid

Machine the load-bearing parts (hub, moldings) in aluminium, 3D-print the
non-structural parts (actuator mounts, tail boom clamps). This is the pragmatic
middle path.

---

## Gap 3: Assembly (~1 weekend)

Assembly sequence for one rotor:

1. Cut carbon fibre tube to 800 mm
2. Drill tie holes at Z=20 and Z=780
3. Thread Dyneema through tube bore
4. Slide on bottom molding, bottom bearing
5. Mount hub (slip fit over tube, rides on bottom bearing)
6. Mount top bearing, top molding
7. Attach rotor blades to hub
8. Install swashplate, actuators, scissor links
9. Mount tail boom, H-stab, V-fin
10. Splice Dyneema eyes at top and bottom ties
11. Repeat for rotors 2, 3, 4
12. String all 4 rotors on the main Dyneema line with 15 m spacings

**Critical step:** the Dyneema splicing. A spliced eye in SK99 is ~90% of
line strength when done correctly. Practice on scrap first.

---

## Gap 4: Ground testing (~1 day)

Before flying, validate on the ground:

### Static load test
- Anchor the stack, pull to 1.5× design tension (~7.5 kN) with a come-along
- Verify: no permanent deformation, Dyneema splices hold, bearings spin freely

### Spin test (single rotor)
- Mount one rotor on a rig with a fan/blower providing ~8 m/s airflow
- Verify: rotor autorotates, reaches ~45 RPM, bearings don't seize
- Check: swashplate changes pitch, empennage aligns to flow

### RPM measurement
- Attach a cheap bike speedometer magnet to the hub
- Verify RPM matches model prediction (~45 at 8 m/s)

---

## Gap 5: Flight testing (~2-3 sessions at Croft)

### Session 1: Single rotor

Fly **one rotor only** to validate:
- Autorotation starts reliably in real wind
- Empennage weathervanes correctly
- Swashplate responds (if remote-controlled)
- Line tension measured with a load cell at anchor

Success criteria: stable flight for 10+ minutes, tension matches model within 30%.

### Session 2: Two-rotor stack

Add a second rotor at 15 m spacing:
- Verify progressive tension accumulation
- Check for rotor-rotor interaction (do they collide? do wakes interfere?)
- Measure anchor tension, compare to model prediction

### Session 3: Four-rotor stack

Full configuration:
- All 4 rotors, 15 m spacing, 55° elevation
- Target: 5 kN anchor tension at 8 m/s wind
- Video documentation for design review

---

## What we'd learn

| Question | How tested |
|----------|-----------|
| Does autorotation start reliably? | Single-rotor flight |
| Do bearings survive real loads? | Post-flight inspection |
| Does the Dyneema splice hold? | Load cell data + visual |
| Is the swashplate effective? | Pitch change → tension change |
| Do rotors interact/aeroelastically couple? | 2-rotor then 4-rotor flights |
| Does tension match the model? | Load cell vs parameter_sweep prediction |
| Is it transportable? | Pack/unpack between sessions |

---

## Total estimate

| Phase | Time | Cost |
|-------|------|------|
| Sourcing | 1 week | £200-400 |
| Manufacturing (Option C, hybrid) | 2-3 weekends | £100-200 (consumables) |
| Assembly | 1 weekend | — |
| Ground testing | 1 day | £50 (load cell, come-along) |
| Flight testing | 2-3 sessions | travel to Croft |

**Total: ~6 weeks calendar, ~£350-650, 3-4 weekends of hands-on work.**

---

## Recommended first step

Build **one rotor** (Option C — aluminium hub + 3D-printed mounts) and fly it
at Croft. This validates the core concept (autorotation in tethered flight)
for minimum cost and time. If it works, the remaining 3 rotors are
cookie-cutter copies.

---

## Open questions before building

1. **Blade construction:** Plywood with glass skin? 3D-printed with carbon
   spars? Foam core hot-wire cut? Needs to survive centrifugal loads (~70 N
   per blade at radius) and occasional ground strikes.
2. **Swashplate control:** Wired or wireless? If wired, need slip rings at
   each rotor to pass power/signal down the Dyneema. If wireless (RC servo +
   battery per rotor), need battery endurance for flight duration.
3. **Load cell:** Where to mount it? Between anchor and ground point is
   simplest. Sampling rate: 10 Hz should capture gust response.
4. **Rod's availability:** Does Rod have access to a lathe/mill? If not,
   manufacture moves to a local machine shop or goes 3D-printed.
