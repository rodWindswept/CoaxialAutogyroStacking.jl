# Interactive Dashboards & Notebooks — CoaxialAutogyroStacking.jl

Two primary interactive environments for exploring stacked autogyro configurations, equilibrium flight mechanics, and parameter sweep results.

---

## 1. Native Desktop Dashboard (`scripts/dashboard.jl`)

Standalone GLMakie desktop application with real-time parameter controls, 2D line geometry side view, tension accumulation plots, and performance HUD.

```bash
julia --project=. scripts/dashboard.jl
```

**Features:**
- **Control Inputs:** Wind speed, rotor count, radius, global tilt/pitch, per-rotor tilt offsets, line diameter, section length.
- **Equilibrium Flight Mechanics:** Computes resultant equilibrium line elevation $\theta_{\text{eq}} \approx \arctan((F_{\text{lift}} - W)/F_{\text{drag}})$ driven by system $L/D$.
- **Scenario Presets:** Launch, Cruise, Landing, Storm Gust, and Auto-Optimize.

---

## 2. Pluto Interactive Dashboard (`notebooks/dashboard.jl`)

Browser-based Pluto notebook for web interactive exploration of stack physics and line geometry.

```bash
julia --project=. -e 'using Pluto; Pluto.run("notebooks/dashboard.jl")'
```

---

## 3. Parameter Sweep & Pareto Viewer (`notebooks/sweep_plots.jl`)

Plotting and analysis notebook for visualizing multi-objective trade-offs (Tension vs Mass Efficiency $N/\text{kg}$, Tension vs Gust Stability $CV$, and viability envelopes).

```bash
julia --project=. -e 'using Pluto; Pluto.run("notebooks/sweep_plots.jl")'
```

---

## Archive Directory (`notebooks/archive/`)

Prior iteration backups and scratch notebooks are preserved in [`notebooks/archive/`](file:///home/rodbot/Documents/GitHub/CoaxialAutogyroStacking.jl/notebooks/archive/). Primary development uses `dashboard.jl` and `sweep_plots.jl`.
