# Assembly — One Autogyro Rotor: Build Sequence

> Step-by-step assembly of a single rotor unit from manufactured parts.
> Prerequisites: all parts from MANUFACTURING.md are complete, deburred,
> and laid out. Bearings and mouldings test-fitted on tube.
> Estimated time: 3-4 hours for first rotor, 1-2 hours per subsequent.

---

## 0. PARTS LAYOUT — WHAT YOU SHOULD HAVE

Lay everything out on a clean bench. Check off each item:

```
STRUCTURAL
  □ Central tube — 800 mm, tie holes drilled at Z=20 and Z=780
  □ Dyneema line — 15 m length, one end sealed with heat
  □ Hub — 80 mm OD × 60 mm, bored to 27 mm ID
  □ Top molding — 70 mm OD × 20 mm, 25.5 mm bore, angled face on bottom
  □ Bottom molding — 70 mm OD × 20 mm, 25.5 mm bore, angled face on top

ROTATING GROUP
  □ SKF 51105 bearing (×2) — clean, light oil film
  □ Rotor blades (×2) — shaped, sealed, balanced as a pair
  □ M6 bolts + nyloc nuts (×4) — blade mounting

TAIL
  □ Tail boom — 1800 mm alu tube, flattened at mount end
  □ Tail droop wedge — 15° block (3D printed or filed alu)
  □ H-stab — 600 × 150 mm
  □ V-fin — 400 × 150 mm
  □ M3 bolts + nyloc nuts (×6) — tail surface mounting
  □ M5 bolt + nyloc nut — boom mounting

RIGGING
  □ Dyneema stitching cord — 3 mm, 6 short lengths (~300 mm each)
  □ Splicing fid — 2 mm
  □ Spectra webbing — 25 mm wide, 2 short lengths (~200 mm each)
  □ Cable ties (×10) — temporary rigging, to be replaced

CONSUMABLES
  □ Isopropyl alcohol — cleaning
  □ Lint-free cloth — bearing handling
  □ Threadlocker (Loctite 243) — all metal-to-metal bolts
  □ Sharpie — marking
  □ Digital calipers — checking
  □ Torque wrench (small, 2-10 N·m) — if available
```

---

## 1. TUBE PREP

### 1a. Dyneema threading

This is the first operation — you cannot thread the line after
components are on the tube.

1. Cut Dyneema to 15 m length (for a single rotor test; for a
   4-rotor stack, you'll thread all rotors onto one continuous line).
2. Seal the cut end: wrap tightly with electrical tape, cut through
   the tape. This prevents the 12-strand braid from unravelling.
   Alternatively: melt the end with a heat gun and shape into a
   tapered point with gloved fingers. **Don't inhale Dyneema fumes.**
3. Check the tube bore is clear — push a rag through, then shine a
   torch. No burrs, no swarf, no carbon splinters.
4. Thread the sealed end through the tube from bottom (Z=0) to top
   (Z=800). If it snags: don't force it. Back out, check for burrs,
   re-taper the end.

> **Why 15 m for one rotor?** You need: 800 mm through the tube +
> enough line above and below to tie off to a test rig. For the full
> 4-rotor stack, you thread one continuous 60 m line through all
> four tubes. Don't cut per-rotor lengths if you plan to stack them.

### 1b. Bottom tie (primary load path)

5. At Z=20 (the lower pair of holes), pass a 300 mm length of 3 mm
   Dyneema stitching cord through both holes (front to back).
6. Wrap around the outside of the tube, pass back through the holes
   in the opposite direction. You now have a loop encircling the
   tube wall at Z=20.
7. This loop captures the main Dyneema line. Tie a double fisherman's
   knot to secure it. Pull HARD — this knot takes the full anchor
   tension. If it slips, everything below this rotor falls.
8. Optional stronger method: splice an eye into the main Dyneema
   line at exactly Z=20, pass the stitching cord through the eye
   and the tie holes. The eye takes the load directly; the stitching
   cord just keeps the eye aligned with the holes.
9. Once tied, pull 50 kg on the Dyneema (body weight — stand on a
   loop) to bed the knots. Re-tighten.

### 1c. Top tie

10. Repeat steps 5-9 at Z=780 (upper pair of holes).
11. The top tie captures the Dyneema above this rotor — it carries
    the weight of all rotors above this one. On the topmost rotor,
    the top tie carries no load (line terminates here).
    On the bottom rotor, the top tie carries 3 rotors' worth of
    tension.
12. Bed the knots as above.

---

## 2. BOTTOM BEARING STACK — Build from the bottom up

Assembly order, bottom to top (tube vertical, bottom at bench level):

```
   Z=780  ── Top tie (already done)

   Z=720  ── Top molding ── angled face DOWN
   Z=720  ── Top bearing  ── sits ON molding's angled face
   Z=709  ── Hub top      ── contacts bearing
   Z=679  ── Rotor disk   ── centre
   Z=649  ── Hub bottom   ── contacts bearing
   Z=649  ── Bottom bearing ── sits ON bottom molding's angled face
   Z=638  ── Bottom molding ── angled face UP

   Z=20   ── Bottom tie (already done)
```

### 2a. Bottom molding

1. Slide the bottom molding onto the tube from the top. Let it drop
   to Z≈638.
2. The angled face points UP. The deeper side (thinner edge of the
   molding) faces FORWARD — toward +X, the windward side.
3. Push it down firmly against the bottom tie loop. It should sit
   snug — the tie loop acts as a stop.

### 2b. Bottom bearing

4. Clean the bearing with isopropyl alcohol on a lint-free cloth.
   Remove all packing grease — it's a corrosion inhibitor, not a
   lubricant. You want a very light film of oil, almost dry.
5. Identify the bearing faces: SKF 51105 has two identical flat
   washers and a ball cage between them. Either washer can face up.
6. Slide the bearing onto the tube. It sits directly on the bottom
   molding's angled face. The washer should seat flat against the
   angled surface — if it rocks, the molding angle is wrong.
7. Check: bearing spins freely by hand. No grinding, no tight spots.

### 2c. Hub

8. Slide the hub onto the tube. It should drop smoothly over the
   25 mm OD — if it binds, check for burrs in the bore.
9. Lower it until the bottom face contacts the bearing washer.
   The hub should spin freely on the bearing. Test: give it a flick —
   it should rotate several turns before stopping.
10. If it doesn't spin freely: check that the bearing is seated
    flat on the molding. A cocked bearing binds the hub.

### 2d. Top bearing

11. Clean as per step 4.
12. Slide onto the tube, resting on the top face of the hub.
13. Rotate the hub — both bearings should spin smoothly together.

### 2e. Top molding

14. Slide the top molding onto the tube. Angled face points DOWN
    (toward the bearing below). Deeper side faces FORWARD (+X).
15. Lower it until the angled face contacts the top bearing washer.
16. Push down firmly. The stack should be compressed: bottom molding
    → bearing → hub → bearing → top molding. No gaps, no wobble.

### 2f. Secure the stack

17. The moldings are retained by friction and the Dyneema ties above
    and below. For the prototype, friction is enough — the operating
    loads push the stack together (tension in the Dyneema compresses
    the bearings between the moldings).
18. For peace of mind: wrap a cable tie around the tube just above
    the top molding. This prevents it from sliding up if the line
    goes slack during handling. Remove for flight — it'll abrade
    the Dyneema under load.

### 2g. Spin test

19. Hold the tube vertically. Give the hub a hard flick. It should
    spin for at least 5-10 seconds before stopping.
20. If it stops quickly: bearings are packed with grease (re-clean),
    hub is binding on the tube (check bore clearance), or moldings
    are misaligned (check angle orientation).
21. Listen: a healthy bearing stack is nearly silent. Grinding =
    contamination. Squeaking = dry bearing (add ONE drop of light
    machine oil — sewing machine oil is ideal).

---

## 3. BLADE MOUNTING

### 3a. Orientation

The blades mount at 180° to each other. The rotor disk plane is set
by the bearing angles (10° forward tilt). The blades should be
mounted so the flat bottom faces DOWN (toward the anchor) and the
curved top faces UP (toward the incoming airflow).

For an autogyro: airflow comes from BELOW the disk (the rotor is
tilted back relative to the wind). The blades should produce lift
UPWARD along the tube axis.

### 3b. Bolt on

1. Align blade 1 with the hub's mounting holes. Insert M6 bolts
   from the blade side, nuts on the hub side.
2. Add a drop of Loctite 243 to each bolt thread.
3. Tighten to 4-5 N·m (firm but not crushing the plywood). The
   bolt head should slightly indent the plywood surface — that's
   enough. Overtightening crushes the wood fibres and weakens the
   joint.
4. Repeat for blade 2, 180° opposite.
5. Check: both blades at the same angle relative to the tube.
   Sight along the blade from tip to hub — should be parallel to
   the hub face.

### 3c. Re-check balance

6. With both blades mounted, re-check balance. The hub should
   rest at any angle on a horizontal shaft.
7. Add wheel weights to the light blade's tip if needed. The
   blades were balanced as a pair during manufacturing, but bolt
   and washer weight differences can throw it off.

---

## 4. TAIL ASSEMBLY

### 4a. Boom mount

1. Position the 15° droop wedge against the tube at Z≈120.
   Wedge orientation: thick side DOWN — this angles the boom
   downward from horizontal.
2. Clamp the wedge to the tube with a cable tie (temporary) or
   a proper tube clamp (permanent).
3. Insert the flattened end of the tail boom into the wedge clamp.
4. Drill through the clamp + boom + wedge. Insert M5 bolt, add
   nyloc nut. Tighten until the boom doesn't rotate by hand.

### 4b. H-stab

5. Position the H-stab centred on the boom, 50 mm from the tip.
6. Drill 2× 3 mm holes through the stab and boom.
7. Bolt with M3 bolts + nyloc nuts. The stab should be horizontal
   in level flight (perpendicular to the tube axis, parallel to
   the horizon when the line is at 55°).
8. If the stab isn't level: shim one side with a washer.

### 4c. V-fin

9. Mount the V-fin centred on the boom, forward of the H-stab
   (closer to the tube, ~200 mm from the tube end).
10. Hang BELOW the boom. Drill 2× 3 mm holes. Bolt.
11. Check: V-fin is perpendicular to H-stab. It should catch
    crosswinds and weathervane the unit to face the wind.

---

## 5. FINAL CHECKS

### 5a. Full rotation test

1. Suspend the rotor by the top Dyneema (tie it to a ceiling hook,
   a tree branch, or a ladder).
2. The rotor should hang vertically — tube aligned with gravity.
3. Give the blades a hard push. The entire hub + blade assembly
   should autorotate freely. Listen for:
   - Scraping: blade tip hitting the tube or tail. Adjust tail
     boom angle.
   - Clicking: something loose. Check all bolts.
   - Wobbling: blades unbalanced. Re-check balance.
4. It should spin for 15+ seconds from one hard push.

### 5b. Load test (ground)

5. Tie the bottom Dyneema to a fixed anchor point (fence post,
   car tow hook, ground stake).
6. Pull on the top Dyneema with a come-along or ratchet strap
   to ~200 kg (2 kN). This is ~40% of design tension — enough
   to bed the knots without risking anything.
7. Check: no permanent deformation, knots haven't slipped, tube
   isn't buckling, moldings haven't shifted.
8. Release tension. Check bearings still spin freely — load
   shouldn't have affected them (thrust bearings are designed
   for this).

### 5c. Pre-flight inspection checklist

```
□ All bolts tight? (Check every bolt with a spanner)
□ Blades undamaged? (Look for cracks at the root)
□ Bearings spin freely? (Flick test)
□ Dyneema knots secure? (Pull hard on each)
□ Tail surfaces rigid? (Try to wiggle them — no movement)
□ No sharp edges? (Run hand over everything — nothing that
  could cut the Dyneema if the line slacks)
□ Tube straight? (Sight along it — no bend from load test)
□ Balance ok? (Rotor stays at any angle)
```

---

## 6. STACKING (for multi-rotor assembly)

If building all 4 rotors on one continuous Dyneema line:

1. Thread all 4 tubes onto the 60 m Dyneema line BEFORE assembling
   any of them. You cannot add a tube to a line that already has
   knots tied.
2. Starting from the BOTTOM (closest to anchor):
    - Tie bottom knot at Z=20 on the first rotor
    - Assemble bearing stack on the first rotor
    - Mount blades on the first rotor
    - Measure 15 m up the line from the first rotor's top tie
    - Tie bottom knot of the second rotor at that point
    - Repeat for rotors 3 and 4
3. The topmost rotor: tie off the line above the top molding.
    No line extends above the topmost rotor. The stack terminates here.
4. Anchor tension accumulates: T=0 at the topmost rotor, increasing
    through each rotor to ~5 kN at the anchor below the bottom rotor.

> **Test one rotor first.** Fly rotor 1 solo before committing to
> the full 4-rotor build. If the design has a fundamental problem
> (bearings seize, blades flutter, empennage doesn't weathervane),
> you want to discover it on one rotor, not four.

---

## 7. TIME ESTIMATE

| Step | First rotor | Subsequent |
|------|------------|------------|
| Tube prep + Dyneema | 30 min | 20 min |
| Bottom tie | 15 min | 10 min |
| Bearing stack | 30 min | 20 min |
| Blade mounting | 20 min | 15 min |
| Tail assembly | 30 min | 20 min |
| Checks + load test | 30 min | 20 min |
| **Total** | **~3 hours** | **~2 hours** |

---

## 8. WHEN IT GOES WRONG

| Problem | Cause | Fix |
|---------|-------|-----|
| Hub doesn't spin freely | Bearing cocked on angled face | Disassemble, check molding angle, reassemble |
| | Grease too thick | Re-clean bearings, use light oil only |
| | Hub bore binding on tube | Check for burrs, check clearance (should be 0.5mm radial) |
| Blades wobble during spin | Unbalanced | Add wheel weights to light blade tip |
| | Loose bolts | Tighten to 5 N·m with Loctite |
| | Warped ply (moisture) | Re-seal with thinned epoxy, re-balance |
| Dyneema slips through tie hole | Knot not bedded | Pull harder — Dyneema is slippery, knots need serious tension to set |
| | Wrong knot | Use double fisherman's. A bowline WILL slip in Dyneema |
| Moldings shift under load | Friction insufficient | Add a cable tie retainer above top molding |
| Tail weathervanes wrong direction | V-fin mounted upside down | V-fin hangs BELOW boom, not above |
