# Handoff — CoaxialAutogyroStacking Dashboard

Session: 2026-06-12 — grill-with-docs → dashboard implementation
Model: deepseek-v4-pro

## What was done

**Dashboard operational.** Fought Bonito 4.x serving API issues and ultimately switched to GLMakie (native OpenGL window). Dashboard loads and responds to all sliders: wind, elevation, rotor count, radius, pitch, line diameter, section length, per-rotor pitch offsets, turbulence toggle, kite spec toggle, scenario buttons (Launch/Cruise/Land/Optimize/Reset).

**Physics fix.** The side view and tension barplot were drawing sections in reverse spatial order — anchor-end was showing free-end tension (~0 N) and vice versa. Fixed by iterating sections in `(n+1):-1:2` order (anchor→free end). Also removed the phantom free-end section above the topmost rotor — line now terminates at the top rotor.

**Power comparison.** Added TRPT continuous vs yo-yo cycling power estimates driven from anchor tension:
- TRPT: `F_anchor × spec_factor / 1000` (v5 octagon: 44.4 W/N, canonical: 28.9 W/N)
- Yo-yo peak: `F_anchor × (v_wind/3) / 1000` (Loyd 1980 optimum)
- Yo-yo net: peak × 0.77 (Kitepower Falcon 100kW commercial data: 80/20 duty cycle, 15% recovery tension)
- Kite spec toggle switches between v5 octagon (871 W/kg) and canonical 5-line (568 W/kg) from KTD.jl data

**Makie native widgets** (SliderGrid, Toggle, Button) used instead of Bonito widgets — compat with GLMakie.

**HUD** compacted to ~12 lines showing wind, elevation, per-rotor CL/CD/force, anchor tension, L/D, power comparison, tension range.

## What remains

**Priority A — Dashboard improvements (conference-ready):**

1. **UI layout polish** — sliders still crowd the HUD a bit, bottom may clip on smaller screens. Needs proper padding and possibly a scrollable controls panel.
2. **Mechanical assembly schematic** — draw the tube, thrust bearing, hollow hub, empennage framework per rotor in the side view. This is the credibility piece. Currently shows abstract ellipses.
3. **Energy mission framing** — add a visible title/intro: "Coaxial Autogyro Stacking — Lifting Clean Energy Machines into the Atmosphere"
4. **Kite spec default** — grilling Q10 still open: which turbine spec as default? v5 octagon or canonical 5-line?

**Priority B — Static figures:**

Generate publication-quality PNG/SVG exports of key results: CL/CD curves, tension profiles for 1/2/3 rotor configurations, parameter sweeps.

**Priority C — Docs site:**

Deploy Documenter.jl to GitHub Pages with embedded plots. `docs/make.jl` exists but needs `deploydocs` uncommented and a repo URL.

## Grill-with-docs decisions logged

1. Priority order: A (dashboard polish) → B (static figures) → C (docs site)
2. Dashboard leads with energy mission — title/intro panel
3. Schematic-level mechanical assembly visible (tube, bearing, hub, empennage) — not abstract disks
4. All mechanical elements get equal visual weight
5. Narrative: WHY first, then stacking, individual control, credibility
6. Power readout: anchor tension → supported TRPT kW + yo-yo kW comparison
7. Kitepower Falcon data: v_reel = v_wind/3, 15% recovery tension, 80/20 duty, 77% net/peak
8. KTD.jl reference specs: v5 octagon 871 W/kg, canonical 5-line 568 W/kg
9. Yo-yo parameters from literature (Loyd 1980 + Kitepower commercial data)
10. Kite spec toggle: user-switchable between v5 and canonical

## Files changed

- `scripts/dashboard.jl` — complete rewrite using GLMakie + Makie native widgets
- Original dashboard backed up in git history

## Run command

```bash
cd ~/Documents/GitHub/CoaxialAutogyroStacking.jl
julia --project=. scripts/dashboard.jl
```
