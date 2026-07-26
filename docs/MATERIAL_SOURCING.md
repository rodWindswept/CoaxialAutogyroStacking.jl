# Material Sourcing — One Autogyro Rotor Prototype

> Target: source all off-the-shelf components for a single rotor unit.
> Budget estimate: £120–220 per rotor (off-the-shelf only, excl. manufacturing).
> Prices checked July 2026; verify before ordering.

---

## 1. DYNEMA LINE — 4 mm SK99

**What:** Main structural line running through the tube bore. Must be
spliceable (12-strand single braid). Breaking strength ~1,600 kg for 4 mm
SK78; SK99 is ~15% stronger.

**How much:** ~15 m per rotor (800 mm through tube + 14 m between units /
to anchor). For 4 rotors: ~60 m total.

| Supplier | Product | Diameter | Price/m | Notes |
|----------|---------|----------|---------|-------|
| [Sailing Chandlery](https://www.sailingchandlery.com/collections/dyneema-rope/4mm) | Liros D-Pro Dyneema SK99 | 4 mm | ~£3.50/m | UK stock, cut to length |
| [Ino-Rope](https://shop.inorope.com/en/shop-en/rigging-work/ropes-to-splice/dyneema-sk99-braid/) | Dyneema SK99 Braid | 4 mm | ~£3-4/m | Heat-stretched, good for splicing |
| [eBay UK](https://www.ebay.co.uk) | Various SK78/SK99 | 4 mm | £2-3/m | Check seller rating, verify SK99 |

**Per rotor:** ~£45-60 for 15 m.
**4-rotor stack:** ~£120-200 for 60 m.

> **Splicing note:** SK99 needs a fid (splicing needle) ~2 mm diameter.
> Brion Toss splicing guide recommended. Practice on 1 m scrap first.

---

## 2. THRUST BEARINGS — SKF 51105 (×2 per rotor)

**What:** ID=25 mm, OD=42 mm, H=11 mm. Dynamic load 15.9 kN.
One above hub, one below hub. Hub autorotates on these.

| Supplier | Product | Price each | Notes |
|----------|---------|-----------|-------|
| [Bearings R Us](https://www.bearingsrus.co.uk/51105-skf) | SKF 51105 | £10-14 | Genuine SKF |
| [Acorn Industrial](https://www.acorn-ind.co.uk/p/skf/single-direction-thrust-ball-bearings/51105-skf/) | SKF 51105 | £10-14 | Trade supplier |
| [Bearing King](https://bearing-king.co.uk/products/51105-skf-single-direction-thrust-ball-bearing-25x42x11mm) | SKF 51105 | £10-14 | Retail-friendly |
| [123Bearing](https://www.123bearing.co.uk/bearing-housing/deep-groove-bearing/thrust/51105-skf) | SKF 51105 | £8-12 | Good for small orders |
| [Wych Bearings](https://www.wychbearings.co.uk/51105_skf_thrust_bearing.html) | SKF 51105 | £10-14 | UK stock |

**Per rotor:** £16-28 (2 bearings).
**4-rotor stack:** £64-112 (8 bearings).

> **Budget option:** Generic 51105 (non-SKF) at ~£4-6 each from eBay.
> Not recommended for flight — SKF's quality control matters at 45 RPM
> under 997 N axial load. The £8 difference per bearing isn't worth the
> risk of a seized bearing at altitude.

---

## 3. CARBON FIBRE TUBE — 25 mm OD, 15 mm ID

**What:** Central tension tie-rod. Dyneema passes through bore.
Carries compression between bearings. Must be 25 mm OD to match
bearing ID (slip fit). Wall thickness ideally 5 mm (15 mm ID).

**Problem:** 25×15 mm is an unusual size. Most off-the-shelf carbon
tubes are 25×22 (1.5 mm wall), 25×23 (1 mm wall), or 25×20 (2.5 mm
wall). Custom mandrel winding is expensive.

| Supplier | Product | OD×ID (mm) | Wall | Price/m | Notes |
|----------|---------|------------|------|---------|-------|
| [Easy Composites](https://www.easycomposites.co.uk/25mm-22mm-woven-finish-carbon-fibre-tube) | Woven finish | 25×22 | 1.5 mm | ~£18/m | High quality, UK stock |
| [Easy Composites](https://www.easycomposites.co.uk/carbon-fibre-tube) | Roll-wrapped | various | up to 3 mm | ~£15-30/m | Check for 25×20 option |
| eBay UK | Pultruded | 25×20 | 2.5 mm | ~£10-15/m | Budget option |

**Critical decision:** 25×22 (1.5 mm wall) won't match the 146× safety
factor in the model. At 25×15 with 5 mm wall, SF=146×. At 25×22 with
1.5 mm wall, SF drops to ~40× — still plenty (40 × 1,294 N = 51.8 kN
capacity). A 1.5 mm wall tube is fine for the prototype.

**Alternative:** Use aluminium tube instead for the first rotor.
25×20 mm aluminium (2.5 mm wall) is £5-8/m from any metal supplier.
Easier to drill tie holes, no splintering. Heavier (~3×) but fine for
ground and short flight tests. Worth considering for the first build.

| Option | Tube | Wall | Weight (800mm) | Cost/m |
|--------|------|------|----------------|--------|
| A | Carbon 25×22 | 1.5 mm | ~50 g | £18 |
| B | Carbon 25×20 | 2.5 mm | ~80 g | £20-30 |
| C | Aluminium 25×20 | 2.5 mm | ~150 g | £5-8 |

**Per rotor:** £5-30 (one 1 m length, cut to 800 mm).
**Recommendation:** Start with Option C (aluminium) for the first
build. Upgrade to carbon once assembly is proven.

---

## 4. ALUMINIUM ROUND STOCK — Hub + Moldings

**What:** Hub (80 mm OD × 60 mm tall), top/bottom moldings
(70 mm OD × 20 mm tall each). All 6061-T6.

### Hub blank

80 mm OD round bar, at least 70 mm long (60 mm finished + facing allowance).

| Supplier | Product | Size | Price |
|----------|---------|------|-------|
| [Aluminium Warehouse](https://www.aluminiumwarehouse.co.uk) | 6061-T6 round | 3" (76.2mm) or 80mm | ~£15-25 for 100mm |
| [Metal Supermarkets UK](https://www.metalsupermarkets.co.uk) | 6061-T6 round | 80mm dia | ~£20-30 cut to length |
| eBay UK | 6061 round bar | 80mm × 100mm | ~£12-20 |

### Molding blanks (×2 per rotor)

70 mm OD round bar, 50 mm each (20 mm finished + facing + angled cut allowance).

Use same suppliers as hub. 70 mm is more common than 80 mm.

| Supplier | Size | Price |
|----------|------|-------|
| Aluminium Warehouse | 70mm × 50mm | ~£8-12 each |
| eBay UK | 70mm × 100mm | ~£10-15 (cut in half for both moldings) |

**Per rotor:** £25-45 for hub + 2 moldings (aluminium blanks only).
**4-rotor stack:** £100-180.

---

## 5. ACTUATORS — 3× per rotor

**What:** Linear actuators for swashplate collective pitch control.
10 mm stroke, must fit within 14×14×40 mm envelope (from parameters.scad).
Force requirement: modest — swashplate loads are small (~10-20 N to
change blade pitch against aerodynamic moment at the feathering hinge).

**Options:**

| Option | Product | Stroke | Force | Size | Price each | Source |
|--------|---------|--------|-------|------|-----------|--------|
| A | Actuonix L12 micro linear servo | 10 mm | ~15 N | 21×10×? mm | £28-35 | [Actuonix](https://www.actuonix.com) / RobotShop |
| B | Hitec HS-785HB linear servo (drum winch) | ~30 mm on 25mm drum | ~5 kg·cm torque | 44×20×38 mm | £25-30 | Hobbyking / eBay |
| C | Generic micro linear actuator (12V) | 10 mm | ~50 N | 20×12×40 mm | £12-18 | Amazon UK / eBay |
| D | RC linear servo (Spektrum SPMSA4030) | 8 mm | ~10 N | 24×11×22 mm | £15-20 | Hobbyking |

**Recommendation:** Option D for the prototype — RC linear servos are
light, cheap, and easy to drive from a standard RC receiver. 8 mm stroke
is acceptable (design called for 10 mm but 8 mm covers most of the range).

**Per rotor:** £45-60 (3 actuators).
**4-rotor stack:** £180-240.

> **Control question:** How to signal all 12 actuators (3 per rotor × 4
> rotors) simultaneously? Options:
> A) Wired — slip rings at each rotor to pass serial bus down the Dyneema.
>    Complex but no batteries to charge.
> B) Wireless — RC receiver + small LiPo per rotor. Simple but need to
>    charge 4 batteries before each flight session.
> C) Passive — no swashplate control on prototype. Fixed pitch, test
>    autorotation only. Simplest, validates the core concept first.

---

## 6. TAIL BOOM — 16 mm tube

**What:** Tail boom extending 1.8 m downwind. Aluminium or carbon.
16 mm OD, wall ~1-2 mm.

| Supplier | Product | Size | Price |
|----------|---------|------|-------|
| eBay UK | Aluminium tube | 16mm × 1.5mm wall × 2m | £5-8 |
| B&Q / Wickes | Aluminium tube | 16mm × 1mm × 1m | £4-6 |
| Hobbyking | Carbon fibre tube | 16mm × 14mm × 1m | £6-10 |

**Per rotor:** £5-10 (2 m length, cut to 1.8 m).
**Recommendation:** Aluminium for prototype — easy to cut, cheap, stiff enough.

---

## 7. TAIL SURFACES — H-stab + V-fin

**What:** Horizontal stabiliser (600×150 mm) and vertical fin (400×150 mm).
Lightweight flat plates — no aerofoil section needed at this TRL.

**Options:**

| Material | Thickness | How to make | Cost |
|----------|-----------|-------------|------|
| Coroplast (corrugated plastic) | 4 mm | Scissors + tape. Ugly but flies. | £3-5 (sign board from B&Q) |
| Plywood | 3 mm birch | Jigsaw + sand edges. Paint to seal. | £5-8 (model shop) |
| Foam board | 5 mm | Craft knife. Light but fragile. | £3-5 (Hobbycraft) |
| 3D-printed | 2 mm shell | FDM print in PLA. Stiff, precise. | £2-4 (filament cost) |

**Per rotor:** £3-8.
**Recommendation:** Coroplast for first build — indestructible, free if
you have an old estate agent sign. Upgrade to plywood once geometry confirmed.

---

## 8. ROTOR BLADES — 2× per rotor

**What:** 3 m radius, 150 mm chord, NACA 0012 section. The hardest part.

**Critical:** blades must survive ~70 N centrifugal force at 45 RPM
and occasional ground strikes during launch/land. They also need to be
balanced to within ~10 g at the tip to avoid vibration.

**Options:**

| Method | Material | Weight | Durability | Cost/rotor | Effort |
|--------|----------|--------|------------|-----------|--------|
| A | Hot-wire cut foam + glass skin | EPS foam, 100g glass cloth, epoxy | ~1.5 kg each | Medium | £25-35 | 1 day |
| B | 3D-printed PLA + carbon spar | PLA, 8mm CF tube spar | ~2 kg each | Low (PLA shatters) | £15-20 | 2 days printing |
| C | Plywood shaped | 6mm birch ply, hand-plane aerofoil | ~2.5 kg each | High | £15-20 | 2-3 days |
| D | Aluminium sheet bent | 1.5mm 6061 sheet, brake-formed | ~3 kg each | Very high | £20-30 | 1 day |

**Recommendation:** Option C (plywood) for the prototype. Durable, cheap,
repairable in the field. Use a simple flat-bottom section (Clark Y) rather
than NACA 0012 — easier to shape by hand and better L/D at low Re.

**NACA 0012 vs Clark Y for prototype:**
- NACA 0012: symmetrical, same CL range in both directions. Correct choice
  for the BEM model. Hard to hand-shape.
- Clark Y: flat bottom, high camber, better at Re < 500k. Easy to shape
  with a plane and sanding block. Acceptable for a proof-of-concept flight.

**Per rotor:** £15-35 (2 blades, materials only).

---

## 9. MISCELLANEOUS

| Item | Spec | Source | Cost |
|------|------|--------|------|
| Dyneema stitching cord | 3 mm SK78, ~2 m | Sailing Chandlery | £5 |
| Spectra webbing | 25 mm, ~1 m | eBay / chandlery | £5 |
| Splicing fid (needle) | 2 mm diameter | Sailing Chandlery | £5-8 |
| Epoxy resin | 200 g kit (for blade skin if glassing) | Easy Composites | £10-15 |
| M4 bolts + nyloc nuts | For actuator mounts, tail attachments | Screwfix | £5 |
| Cable ties | Various, for temporary rigging | Any hardware store | £3 |
| Balance weights | Stick-on wheel weights (5g segments) | Halfords / eBay | £5 |

**Per rotor:** ~£30-40.

---

## 10. TOOLS ASSUMED AVAILABLE (Rod's workshop)

| Tool | For |
|------|-----|
| Lathe (min 80 mm swing) | Hub, moldings |
| Milling machine or rotary table | Angled bearing faces on moldings |
| Drill press | Tie holes in tube, actuator mounts |
| Hacksaw / pipe cutter | Cutting tube to length |
| Digital calipers | Every measurement |
| Bench vice | Holding work |
| Sanding block + 80/120/240 grit | Blade shaping |
| Soldering iron | Actuator wiring (if wired control) |
| Heat gun | Dyneema end-sealing before splicing |

If Rod doesn't have lathe access, the hub and moldings can be 3D-printed
in PLA for fit-check, then machined at a local shop (~£50-100 for
one-off turning).

---

## 11. PER-ROTOR COST SUMMARY

| # | Component | Qty | Unit cost | Total |
|---|-----------|-----|-----------|-------|
| 1 | Dyneema SK99 4mm | 15 m | £3.50/m | £52 |
| 2 | SKF 51105 bearings | 2 | £12 | £24 |
| 3 | Carbon/alu tube 25mm | 1 m | £8 (alu) | £8 |
| 4 | Al hub blank 80mm | 1 | £20 | £20 |
| 5 | Al molding blanks 70mm | 2 | £10 | £20 |
| 6 | Linear actuators | 3 | £18 | £54 |
| 7 | Tail boom 16mm alu | 2 m | £6 | £6 |
| 8 | Tail surfaces (coroplast) | 2 | £3 | £6 |
| 9 | Rotor blades (ply) | 2 | £10 | £20 |
| 10 | Miscellaneous | — | — | £35 |

**TOTAL PER ROTOR: ~£245**

**4-rotor stack: ~£735** (some volume discounts on Dyneema + bearings).

---

## 12. FIRST PURCHASE — SINGLE ROTOR SHOPPING LIST

Order these to build Rotor 1:

```
□ Dyneema SK99, 4 mm × 20 m — Sailing Chandlery — £70
□ SKF 51105 × 2 — Bearing King / 123Bearing — £24
□ Aluminium tube, 25mm OD × 2mm wall × 1 m — eBay — £8
□ Aluminium round 80mm × 100mm (hub) — Aluminium Warehouse — £20
□ Aluminium round 70mm × 100mm (moldings, cut in half) — eBay — £15
□ RC linear servos × 3 (Spektrum SPMSA4030 or similar) — Hobbyking — £54
□ Aluminium tube, 16mm × 2m (tail boom) — B&Q — £6
□ Coroplast sheet A3 (tail surfaces) — local sign shop — £5
□ Birch ply 6mm × 150mm × 3m (2 blades) — model shop — £20
□ Dyneema 3mm × 2m (stitching cord) — Sailing Chandlery — £5
□ Splicing fid 2mm — Sailing Chandlery — £6
□ Epoxy 200g kit — Easy Composites — £12
□ M4 bolts + nylocs assortment — Screwfix — £5
□ Cable ties — Screwfix — £3
□ Wheel balance weights 5g × 20 — Halfords — £4
─────────────────────────────────────────────────
  ESTIMATED TOTAL: £257 + shipping (~£15) = ~£272
```

---

## 13. KNOWN UNKNOWNS (verify before ordering)

1. **25mm carbon tube with ≥3mm wall**: Easy Composites may have a
   25×20 (2.5mm wall) roll-wrapped option. Phone them and ask.
2. **SKF vs generic bearings**: Check if Rod has a bearing supplier
   already. Windswept may have a trade account.
3. **Actuator stroke**: 8 mm vs 10 mm — verify the swashplate geometry
   in OpenSCAD to confirm 8 mm covers the required pitch range.
4. **Blade construction**: Rod may have strong opinions about blade
   materials from his kite-building experience. Ask before buying ply.
5. **Rod's lathe access**: Critical. If no lathe, the hub and moldings
   need to be outsourced or 3D-printed (Option B from Gap 2).
