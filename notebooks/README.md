# Dashboards — CoaxialAutogyroStacking.jl

Two interactive dashboards for exploring stacked autogyro configurations.

## Option 1: GLMakie (native window, recommended)

Standalone app with sliders for all parameters, side view, tension barplot, HUD,
and power comparison (TRPT vs yo-yo).

```bash
# Run from the project ROOT, not from notebooks/
cd ~/Documents/GitHub/CoaxialAutogyroStacking.jl
julia --project=. scripts/dashboard.jl
```

**Controls:**
- Wind speed, elevation, rotor count, radius, pitch, line diameter, section length
- Per-rotor pitch offsets
- Turbulence toggle, kite spec toggle
- Scenario buttons: Launch, Cruise, Land, Optimize, Reset

**Requires:** GLMakie (in Project.toml)

## Option 2: Pluto notebook (browser-based)

Interactive notebook with sweep result plots and parameter exploration.

```bash
cd ~/Documents/GitHub/CoaxialAutogyroStacking.jl
julia --project=. -e 'using Pluto; Pluto.run()'
```

Then open `notebooks/dashboard.jl` in the Pluto browser window.

**Requires:** Pluto (in Project.toml)

## Option 3: Sweep results viewer

View the Phase 8 parameter sweep results (8,640 evaluations, Pareto fronts).

```bash
cd ~/Documents/GitHub/CoaxialAutogyroStacking.jl
julia --project=. -e 'using Pluto; Pluto.run()'
```

Then open `notebooks/sweep_plots.jl` in Pluto.

**Data:** `sweep_results.tsv` (1,728 post-processed configurations)

## Backup files

`dashboard backup 1.jl` and `dashboard backup 2.jl` are earlier versions
preserved for reference. Use `dashboard.jl` for current work.

## Note

The dashboard references `optimal_pitches` which was renamed to
`optimal_rotor_tilts` in v0.1.1. A compatibility fix was applied.
If the dashboard fails to load, check that the function name matches.
