# Path to Prototype — From Digital Model to Flying Hardware

> Gap analysis: what stands between the Phase 9 mechanical design and a
> working prototype Rod can test in the field.
>
> **Detailed guides now exist for all five gaps.** This document is the
> overview; follow the links for step-by-step instructions.

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

## The five gaps

| # | Gap | Detail doc | Time | Cost |
|---|-----|-----------|------|------|
| 1 | Material sourcing | [MATERIAL_SOURCING.md](docs/MATERIAL_SOURCING.md) | 1 week | £245/rotor |
| 2 | Manufacturing | [MANUFACTURING.md](docs/MANUFACTURING.md) | 2-3 weekends | £100-200 |
| 3 | Assembly | [ASSEMBLY.md](docs/ASSEMBLY.md) | 3-4 hours/rotor | — |
| 4 | Ground testing | [GROUND_TESTING.md](docs/GROUND_TESTING.md) | 3-4 hours | £50 |
| 5 | Flight testing | [FLIGHT_TESTING.md](docs/FLIGHT_TESTING.md) | 3 sessions | travel |

---

## Gap 1: Sourcing → [`docs/MATERIAL_SOURCING.md`](docs/MATERIAL_SOURCING.md)

13-section guide with real UK suppliers, current prices, and a copy-paste
shopping list. Covers:

- Dyneema SK99 4 mm, SKF 51105 bearings, carbon/aluminium tube options
- Aluminium blanks for hub + moldings, linear actuators (3 per rotor)
- Tail materials, blade construction methods, miscellaneous rigging
- Per-rotor cost: **~£245** (first rotor shopping list: **~£272**)

---

## Gap 2: Manufacturing → [`docs/MANUFACTURING.md`](docs/MANUFACTURING.md)

Step-by-step lathe/mill/build instructions for every part:

- Hub: face, bore to 27 mm, turn OD to 80 mm (±0.1 tolerance)
- Moldings: 10° angled bearing face — 3 methods (mill tilting head,
  compound slide, shimmed chuck)
- Tube: cut to 800 mm, drill 4 tie holes at Z=20 and Z=780
- Blades: Clark Y section from birch ply, station-mark shaping,
  balance to 5 g·m
- Tail boom + surfaces, actuator mounts (3D-printed or fabricated)
- Recovery table for common machining mistakes

**Recommendation:** skip the swashplate on the first rotor — test
autorotation only with fixed-pitch blades.

---

## Gap 3: Assembly → [`docs/ASSEMBLY.md`](docs/ASSEMBLY.md)

Build sequence from parts to finished rotor:

- Dyneema threading (critical: thread BEFORE assembling)
- Bottom-up bearing stack: molding → bearing → hub → bearing → molding
- Blade mounting with Loctite, re-balance check
- Tail assembly with 15° droop wedge
- Spin test (15+ seconds from one flick = healthy bearings)
- 200 kg static load test to bed knots
- Multi-rotor stacking procedure on one continuous line

**Golden rule:** fly one rotor solo before building four.

---

## Gap 4: Ground Testing → [`docs/GROUND_TESTING.md`](docs/GROUND_TESTING.md)

Pre-flight validation on the ground:

- **Static load test**: 0→200 kg in 50 kg steps, pass/fail criteria
  for knots, tube, moldings, tie holes
- **Spin test**: induced autorotation via fan/blower, expected RPM table,
  5-minute endurance run, bearing temperature check
- Fan options: leaf blower, pedestal fan (recommended), natural wind
- Instrumentation: S-type load cell + HX711, or £15 crane scale
- **Printable test card** for clipboard in the field

---

## Gap 5: Flight Testing → [`docs/FLIGHT_TESTING.md`](docs/FLIGHT_TESTING.md)

Three-session field test plan for Croft:

- **Session 1**: single rotor — prove autorotation, 10+ min flight,
  tension within 30% of model
- **Session 2**: dual stack — progressive tension, no collision,
  wake interaction measurement
- **Session 3**: quad stack — full config, target 5 kN at 8 m/s
- Emergency procedures: line break, tangle, stake pullout, high wind
- Post-flight teardown inspection + data analysis
- **Printable flight test card** with 60-second logging table

---

## What we'd learn

| Question | How tested | Doc |
|----------|-----------|-----|
| Does autorotation start reliably? | Single-rotor flight | FLIGHT_TESTING §1 |
| Do bearings survive real loads? | Post-flight inspection | FLIGHT_TESTING §5 |
| Does the Dyneema splice hold? | Load cell data + visual | GROUND_TESTING §1 |
| Is the swashplate effective? | Pitch change → tension change | (v2 — skipped on prototype) |
| Do rotors interact? | 2-rotor then 4-rotor flights | FLIGHT_TESTING §2-3 |
| Does tension match the model? | Load cell vs parameter_sweep | FLIGHT_TESTING §3 |
| Is it transportable? | Pack/unpack between sessions | — |

---

## Total estimate

| Gap | Time | Cost |
|-----|------|------|
| Sourcing | 1 week | £245/rotor |
| Manufacturing | 2-3 weekends | £100-200 |
| Assembly | 3-4 hours | — |
| Ground testing | 3-4 hours | £50 |
| Flight testing | 3 sessions | travel to Croft |

**Total: ~6 weeks calendar, ~£400-500, 3-4 weekends of hands-on work.**

---

## Recommended first step

Build **one rotor** (hybrid — aluminium hub + 3D-printed mounts + plywood
blades) and fly it at Croft. This validates the core concept (autorotation
in tethered flight) for minimum cost and time. If it works, the remaining
3 rotors are cookie-cutter copies.

---

## Open questions before building

1. **Blade construction:** Plywood with Clark Y section is recommended
   for the prototype (see MANUFACTURING.md §6). Rod may have opinions
   from kite building.
2. **Swashplate control:** Skip for the first prototype — test
   autorotation with fixed-pitch blades. Add collective control on v2.
3. **Rod's tool access:** The hub and moldings need a lathe (min 80 mm
   swing). If Rod doesn't have one, parts can be 3D-printed for fit-check
   then machined at a local shop.
4. **Load cell:** A £15-25 crane scale between anchor and line is the
   simplest option for ground and flight testing.
