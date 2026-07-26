# Manufacturing — One Autogyro Rotor: Build Instructions

> Step-by-step for turning raw materials into a finished rotor unit.
> Approach: **Hybrid** — aluminium load-bearing parts (hub, moldings),
> 3D-printed or hand-fabricated non-structural parts (mounts, tail).
> Estimated time: 2-3 weekends for first rotor, 1 weekend each after that.

---

## 0. BEFORE YOU START

### Tools checklist

```
□ Lathe — minimum 80 mm swing over bed, 3-jaw chuck
□ Milling machine OR rotary table on lathe — for angled faces
□ Drill press — or lathe tailstock with drill chuck
□ Digital calipers — 150 mm, 0.01 mm resolution
□ Hacksaw with 32 TPI blade (aluminium)
□ Files — flat, half-round, round
□ Countersink bit — 90°, for deburring
□ Centre drill — BS1 or similar, for starting holes
□ Dial indicator — for centring in 4-jaw chuck
□ Bench vice with soft jaws (aluminium/brass jaw inserts)
□ Taps: M3, M4 (for actuator mounts)
□ Thread-locking compound (Loctite 243, medium strength)
□ Safety: goggles, hearing protection, no loose clothing near lathe
```

### From MATERIAL_SOURCING.md, you should have:

| Part | Material | Raw size |
|------|----------|----------|
| Hub blank | 6061-T6 alu round | 80 mm dia × 70 mm long |
| Molding blanks (×2) | 6061-T6 alu round | 70 mm dia × 50 mm long each |
| Tube | Alu or carbon | 25 mm OD, 1 m long |
| Blades (×2) | Birch ply | 6 mm × 150 mm × 3050 mm |
| Tail boom | Alu tube | 16 mm OD, 2 m long |
| Tail surfaces | Coroplast or ply | 600×150 mm + 400×150 mm |

---

## 1. HUB — Aluminium, 80 mm OD × 60 mm tall

### 1a. Face and centre

1. Grip the 80 mm blank in the 3-jaw chuck, ~15 mm proud of the jaws.
2. Face the end until fully cleaned up (~1 mm cut). This is your reference face.
3. Centre-drill the faced end. Drill through at 5 mm, then step-drill to
   27 mm (hub ID — clears 25 mm tube with 1 mm radial gap).
4. Bore to final ID: 27.0 mm +0.05/-0. Outside of this tolerance → hub
   won't slip over tube or will rattle.
5. Light chamfer on the bore edge — deburr thoroughly. Bearings ride
   against the hub faces; any burr here will chew the bearing race.

### 1b. Turn OD

6. Reverse the blank in the chuck, grip on the 27 mm bore with expanding
   mandrel if available, or use a 4-jaw with dial indicator to centre
   within 0.05 mm TIR.
7. Turn OD down to 80.0 mm ±0.1. Constant diameter along the full 60 mm
   length — this is the bearing journal. Bearings are slip-fit (clearance
   0.01-0.03 mm on the shaft). **Do not cut undersize** — you can't add
   material back. Sneak up on the dimension: measure at 80.5, cut 0.2,
   measure, cut 0.1, measure.
8. Face the second end to bring hub to 60.0 mm ±0.1 total height.
9. Light chamfer both OD edges — remove sharp corners.

### 1c. Blade mounting holes

10. Transfer hub to drill press or mill. Mark 2 holes on the OD at
    180° apart, centred vertically (30 mm from each face).
11. Drill and tap M6 × 12 mm deep — these mount the blade roots.
    Use a spotting drill first to prevent wander on the curved surface.
12. If using a spar instead of direct blade mounting: drill 2× 8 mm
    holes through the hub wall (perpendicular to the bore) for a carbon
    spar that passes through the hub.

### 1d. Surface finish

13. Light polish with 400 then 800 grit wet-and-dry on the OD where
    bearings sit. Don't change the dimension — just remove tool marks.
14. Clean thoroughly with isopropyl alcohol. Aluminium swarf in a
    bearing = destroyed bearing.

**Check**: Hub slides over 25 mm tube with ~0.5 mm radial clearance.
Bearings slide onto hub OD with light finger pressure (slip fit).
Hub spins freely by hand with no tight spots.

---

## 2. MOLDINGS — Aluminium, 70 mm OD × 20 mm tall (×2 identical)

### 2a. Face and bore

1. Grip 70 mm blank, face one end.
2. Centre drill, drill through 5 mm, step to 25.5 mm (molding ID —
   0.5 mm radial clearance over 25 mm tube).
3. Bore to 25.50 mm +0.05/-0. Same tolerance discipline as the hub.

### 2b. Turn OD

4. Reverse using expanding mandrel or 4-jaw + indicator.
5. Turn OD to 70.0 mm ±0.1.
6. Face to 20.0 mm ±0.1 height.

### 2c. Angled bearing face (the hard part)

The underside of the top molding and the topside of the bottom molding
are machined at the disk tilt angle **δ = 10°**. This sets the rotor
disk plane relative to the tube axis.

**Method A — Milling machine with tilting head:**
7. Clamp molding in mill vice with the bearing face upward.
8. Tilt head 10°.
9. Fly-cut the face until it cleans up across the full diameter.
   The face should now be angled — deeper on one side by:
   tan(10°) × 70 mm = 12.3 mm difference across the face.
10. Verify with a protractor or sine bar.

**Method B — Lathe with compound slide:**
7. Grip molding in 4-jaw chuck.
8. Set compound slide to 10°.
9. Face with the compound — this cuts a conical face rather than
    flat-angled, but within tolerance for the prototype.

**Method C — Lathe with packing:**
7. Shim one jaw of the 3-jaw chuck with a 10° wedge (or appropriate
    shim thickness for the diameter). This tilts the workpiece.
8. Face normally — the cut will be angled relative to the part axis.
9. **Caution**: this is a bodge. Works for one prototype but not
    repeatable. The angled face doesn't need to be precision-ground —
    the bearing's spherical balls accommodate small angular
    misalignment.

**Which molding gets which angle:**
- **Top molding**: angle on the BOTTOM face (bearing sits below).
  The deeper side faces FORWARD (windward / -X direction).
- **Bottom molding**: angle on the TOP face (bearing sits above).
  The deeper side faces FORWARD (windward / -X direction).
- Both cut in the same orientation — when installed, the rotor disk
  tilts forward-down into the wind.

### 2d. Finish

11. Deburr all edges. The angled face is a bearing seat — polish to
    400 grit, no tool marks.

**Check**: Molding slides over 25 mm tube. Angled face reads ~10°
against a square. Both moldings have the same angle orientation.

---

## 3. TUBE — Cut, drill, deburr

### 3a. Cut to length

1. Measure 800 mm from one end. Mark with a fine Sharpie (not a scribe —
   scratches on carbon fibre are stress risers).
2. Cut with a 32 TPI hacksaw (alu tube) or a diamond-grit rod saw
   (carbon tube). Use a mitre box for square cut.
3. Deburr inside and outside with a half-round file. Carbon fibre dust
   is nasty — wear a mask, vacuum as you go.

### 3b. Tie holes (×4 holes — 2 top, 2 bottom)

4. Mark positions (from tube bottom = 0):
   - Z = 20 mm: bottom tie hole pair
   - Z = 780 mm: top tie hole pair
5. At each Z: drill one hole from front (+X side), one from back (-X).
   Both on the same horizontal plane. 5.0 mm diameter.
6. Use a centre punch to prevent drill wander. On carbon: use a very
   sharp drill, low pressure, high speed — let the tool cut.
7. Countersink lightly — remove any burr that could chafe the Dyneema.

**Check**: 3 mm Dyneema stitching cord passes through both holes at
each station. Inside of tube is smooth — run a finger through, feel
for burrs.

---

## 4. SWASHPLATE — Aluminium rings

### 4a. Stationary ring (bottom)

1. From 80 mm OD alu round (or leftover from hub blank): part off
   a 7 mm thick disc.
2. Face both sides to 7.5 mm flat and parallel.
3. Bore ID to 32.0 mm (clears 25 mm tube + generator coils).
4. Turn OD to 80.0 mm.

### 4b. Rotating ring (top)

Same as stationary ring but 7.5 mm finished thickness.
The two rings stack to 15 mm total (SWASH_HEIGHT in parameters.scad).

### 4c. Assembly

5. The stationary ring is fixed to the tube (below the bottom molding).
6. The rotating ring sits on top, separated by a thin PTFE or brass
   washer to reduce friction.
7. Three radial arms extend from the rotating ring at 120° spacing
   — these connect to the actuator pushrods.

> **Simplify for prototype:** For the first rotor, skip the swashplate
> entirely. Mount the bottom molding directly, bolt the actuators to
> the tube, and set the blade pitch to a fixed angle. This tests
> autorotation without the complexity of collective control.

---

## 5. ACTUATOR MOUNTS — 3D-printed or fabricated

If using actuators (even fixed-angle on prototype, you need somewhere
to mount them):

### 5a. 3D-printed version (recommended)

1. Design a simple L-bracket in OpenSCAD or Fusion: one face clamps
   to the tube (25 mm radius), the other face has mounting holes for
   the actuator body.
2. Print in PLA, 4 perimeters, 30% infill. Takes ~1 hour per bracket.
3. Test-fit on a scrap of 25 mm tube before committing.

### 5b. Fabricated version (no 3D printer)

1. Cut 4 pieces of 2 mm aluminium sheet: 30×40 mm.
2. Bend each into an L-shape in a bench vice.
3. Drill two 4 mm holes for M4 bolts through the tube face.
4. Drill two 2.5 mm holes for M3 bolts to mount the actuator body.
5. File edges smooth.

### 5c. Mounting position

Three actuators at 120° spacing, mounted just below the bottom molding
(Z ≈ 560-620 mm range — see parameters.scad layout diagram).
They push/pull on the swashplate (or directly on blade pitch horns
if no swashplate).

---

## 6. ROTOR BLADES — 2× plywood, Clark Y section

### 6a. Blank preparation

1. From 6 mm birch ply, cut two blanks: 3050 × 150 mm.
   (3000 mm radius + 50 mm for hub attachment).
2. Mark the chord line and the 30% chord point along the full span.
3. Mark station lines every 300 mm — these are your template checkpoints.

### 6b. Aerofoil shaping (Clark Y)

The Clark Y has a flat bottom from 30% chord to the trailing edge,
and a curved upper surface with max thickness ~11.7% at 30% chord.

4. Clamp the plywood blank flat on the bench, bottom face up.
5. From 30% chord to the trailing edge: leave untouched. This is
   the flat bottom.
6. From 30% chord to the leading edge: mark the thickness profile.
   At the leading edge, thickness should reduce to a ~3 mm radius nose.
7. Using a sharp block plane, shave the upper surface in long passes.
   Work diagonally across the grain, then with the grain.
8. Check thickness at each station with calipers. Aim for ±0.5 mm.
9. Once close, switch to 80 grit sandpaper on a long sanding block.
   Long passes only — short strokes create hollows.
10. Progress through 120, 240 grit. Round the leading edge to ~3 mm
    radius. Leave the trailing edge sharp (~1 mm).
11. Seal with thinned epoxy (50% epoxy, 50% isopropyl alcohol) —
    prevents moisture warping. One coat, wipe off excess.

### 6c. Hub attachment

12. At the root of each blade, drill 2× 6 mm holes matching the hub's
    blade mounting holes.
13. Bolt through with M6 stainless bolts + nyloc nuts. Add a large
    washer (25 mm OD) on the plywood side to spread the load.
14. Alternative: epoxy a 30 mm length of 8 mm carbon tube into a hole
    drilled into the blade root. This spar passes through the hub.
    Cleaner aerodynamically, harder to make.

### 6d. Balance

15. Weigh both blades on a digital scale. They must match within 5 g.
16. If one is heavier: sand material from the heavy blade's tip (not
    the root — tip weight has the largest moment arm). Check weight
    after each pass.
17. Once weights match, balance the assembled rotor:
    - Mount both blades on the hub.
    - Place hub on a horizontal shaft (a drill bit through the bore,
      supported on two level surfaces).
    - The heavy side will drop. Add stick-on wheel weights to the
      light blade's tip until the rotor stays at any angle.

**Aim for balance within 5 g·m (5 g at 1 m radius). At 45 RPM, 5 g
unbalance at 3 m radius produces ~1.3 N centrifugal force — acceptable
for the prototype.**

---

## 7. TAIL BOOM + SURFACES

### 7a. Boom

1. Cut 16 mm alu tube to 1800 mm length.
2. Deburr both ends.
3. Flatten the last 50 mm of the boom at the mounting end (goes into
   a clamp on the tube). Crush in a vice between hardwood blocks.
4. Drill a 5 mm hole through the flattened section for an M5 bolt.

### 7b. H-stab (horizontal)

5. From coroplast or 3 mm ply: cut 600 × 150 mm rectangle.
6. If coroplast: orient flutes spanwise for stiffness. Tape the
   leading edge to prevent delamination.
7. Attach to boom tip with 2× M3 bolts through the boom. Add a
   small plywood plate on top of the stab to spread the load.

### 7c. V-fin (vertical)

8. Cut 400 × 150 mm. Mount centred on the boom, hanging BELOW.
   The V-fin provides passive weathervane alignment — it should
   be below the boom so it's in clean air, not rotor wash.
9. Two M3 bolts through the boom. The fin should be perpendicular
   to the H-stab.

### 7d. Tail droop

10. Mount the boom with a 15° downward angle from horizontal
    (TAIL_DROOP = 15° in parameters.scad). This keeps the tail
    in clean inflow below the rotor disk.
11. Use a wedge-shaped clamp block (15° wedge, 3D printed or
    hand-filed from aluminium) between the boom and the tube mount.

---

## 8. FINAL DEBURR AND CLEAN

Before assembly:

1. Every aluminium part: deburr every edge, every hole, every bore.
   Run your finger over every surface — if it catches, file it.
2. Wash all metal parts in warm soapy water, dry thoroughly.
3. Wipe bearing bores with isopropyl alcohol — no oil film.
4. Carbon tube: wipe bore with a rag on a stick. Any loose carbon
   splinters will abrade the Dyneema.
5. Plywood blades: check for splinters, especially at the trailing
   edge. Sand any rough spots.
6. Lay out all parts on a clean bench. Group by assembly step.

---

## 9. TIME ESTIMATE

| Step | First rotor (learning) | Subsequent rotors |
|------|----------------------|-------------------|
| Hub | 4-6 hours | 2-3 hours |
| Moldings (×2) | 3-4 hours | 2 hours |
| Tube | 30 min | 20 min |
| Swashplate | skip for prototype | 2-3 hours |
| Actuator mounts | 1 hour (print) | 30 min |
| Blades | 6-8 hours | 4-5 hours |
| Tail | 1-2 hours | 1 hour |
| Deburr/clean | 1 hour | 30 min |
| **Total** | **2-3 days** | **1-1.5 days** |

---

## 10. WHEN IT GOES WRONG

| Problem | Recovery |
|---------|----------|
| Hub OD turned undersize | Scrap. Bearings need slip fit — knurling is not acceptable here. Order a new blank. |
| Molding angled face wrong orientation | Remachine the opposite face. You have 50 mm of blank, only need 20 mm finished height. |
| Blade unevenly shaped | Sand more. Plywood is forgiving — you can always remove material from the heavy side. |
| Tie hole drilled off-centre | Rotate tube 90° and drill new holes. The old holes don't matter structurally at this low load. |
| Bearing won't slide on hub | 400 grit wet-and-dry with oil, spin the hub in the lathe, polish the OD until it fits. Measure constantly. |
| Carbon tube splintered during drilling | Wrap the drill area tightly in masking tape before drilling. Tape supports the fibres. If already splintered, wrap with epoxy + glass tape as a repair bandage. Replace for flight. |
