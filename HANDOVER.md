# HANDOVER.md — CoaxialAutogyroStacking.jl Handover & Agent Guide

> **Target Audience:** Cameron & Cameron's AI Agent  
> **Repository:** `CoaxialAutogyroStacking.jl`  
> **Status:** All 345 unit tests green (`julia --project=. test/runtests.jl`).  
> **Primary Purpose:** Guide post-pull workflow, post-pull staleness audit, charting potential exploration, and dual-audience (academic & investor) reporting on Cameron's aerodynamic breakthroughs.

---

## 1. Immediate Post-Pull Checklist

Upon pulling `master`, Cameron's agent **must** perform the following three steps immediately:

1. **Verify Test Suite**:
   ```bash
   julia --project=. test/runtests.jl
   ```
   *Confirm that all 345+ tests pass cleanly.*

2. **Execute Post-Pull Staleness Sweep**:
   - Verify that all newly created `src/` modules are exported and documented in `AGENTS.md` and `PLAN.md`.
   - Check that any doc/notebook examples calling `AutogyroStack(...)` include the `line_density` parameter (default 970.0 kg/m³).
   - Confirm that public functions exported in `CoaxialAutogyroStacking.jl` match docstrings and `SPEC.md`.

3. **Check Quality Invariants**:
   - Tension is strictly monotonic increasing from top rotor to anchor.
   - Forces scale with $v^2$.
   - Zero wind returns mass-only tension budget.

---

## 2. Framing Cameron's Aerodynamic Achievements

When reporting on recent work (Phases 10e and 10f), frame findings according to the target audience:

```
                      ┌────────────────────────────────────────┐
                      │    CAMERON'S AERODYNAMIC RESULTS       │
                      └───────────────────┬────────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
   ACADEMIC / TECHNICAL AUDIENCE                   INVESTOR / COMMERCIAL AUDIENCE
   • Snel 3D Stall-Delay Model                     • Mass Efficiency (N/kg) & Scaling
   • Rotational Augmentation (+35% root thrust)    • Total Anchor Tension (649 N @ 8 m/s)
   • 1-D Axial BEM Physics Limits                  • Viability Envelopes (Noise/Re)
   • Radial Load Distributions C_L,3D(r/R)         • Modular Cost & Payload Reach
```

### A. Academic & Technical Publications
* **Snel 3-D Stall Delay (`src/stall_delay.jl`)**:
  * Explain the physics: Centrifugal pumping thins the boundary layer on rotating blades, delaying stall.
  * Quantitative impact: Increases local station thrust by **+35%** at high-solidity root stations ($c/r > 0.15$), with a **~3% net boost** at the $R=3\text{ m}$ design point.
  * Formulating $C_{L,3\text{D}}$: 2-D $C_L$ solves axial induction $a$ in momentum loop; 3-D $C_{L,3\text{D}}$ integrates station forces.
* **1-D Axial BEM Physics Boundary**:
  * Document the fundamental limit of 1-D axial BEM compared to empirical 3D disk data (PCA-2). BEM under-predicts forces (~10×) due to lack of disk-averaged cross-flow components and 3D tip vortex interaction. This establishes the theoretical justification for Phase 11 / v3.0 wake modeling.

### B. Investor & Commercial Stakeholders
* **Mass Efficiency & System Scaling**:
  * $N$-rotor stacks deliver **linear lift scaling** with negligible drag penalty (~2% per added rotor at $R=3\text{ m}$).
  * Top recommended configuration ($R=3\text{ m}, N=4$, `top_draggy` profile) delivers **$649\text{ N}$ continuous anchor tension** at $8\text{ m/s}$ (scaling to **$\sim 1.46\text{ kN}$ at $12\text{ m/s}$**).
* **Radius-Dependent Profile Dominance**:
  * For small rotors ($R=2\text{ m}$), `bottom_lifty` is optimal (concentrates lift near anchor).
  * For large rotors ($R=3\text{ m}$), `top_draggy` wins by **+12.7%** over uniform tilt because the top rotor shapes line geometry to optimize inflow angle for lower rotors.
* **Operational Viability Envelopes**:
  * Operating tip speeds ($23\text{--}38\text{ m/s}$) stay comfortably below the acoustic noise limit ($120\text{ m/s}$, Mach 0.3).
  * Reynolds numbers ($Re > 5\times 10^5$) validate aerodynamic stability across standard operating wind regimes ($4\text{--}12\text{ m/s}$).

### C. System-Level Value Propositions (Applications & Industry Impact)
When communicating the overall significance of this package, Cameron's agent **must** emphasize how this work unlocks practical airborne applications:

1. **Steady Lift for Airborne Wind Energy (AWE) & Kite Turbines**:
   * **The Challenge**: Single soft kites or giant rigid wings are prone to luffing, stalling, or total collapse in turbulent gusts, causing turbine drop.
   * **The Solution**: Stacked autogyros provide continuous, self-stabilizing autorotative lift that acts as a reliable "tether throttle" to hold turbine hubs stably at optimal altitude.
2. **Over-The-Horizon (OTH) Communication & Remote Sensing**:
   * Enables persistent, ultra-long-endurance tethered platforms for offshore communication relays, marine surveillance, disaster response cell towers, and atmospheric monitoring.
3. **Modular Logistics & Transportability**:
   * Stacking multiple small, rigid autogyro units ($R=1.5\text{--}3\text{ m}$) replaces giant single-structure wings ($100\text{ m}^2+$). Small units fit in standard transport containers and are simple to launch, service, and replace on-site.
4. **Fault Tolerance & Fail-Safe Redundancy**:
   * An $N$-rotor stack exhibits graceful degradation: if one rotor experiences mechanical failure, the remaining $N-1$ rotors maintain line tension, preventing catastrophic system loss.

### D. Control vs. Resultant Flight Mechanics (Critical System Paradigm)
When presenting system controls and flight dynamics in academic papers, investor decks, or UI dashboards:
- **Actuator Control Inputs**: Swashplate collective pitch / disk tilt angle $\delta_i$ per rotor, winch tether length $L_{\text{tether}}$, and wind speed $v_{\text{wind}}$ (environment).
- **Equilibrium Resultants**: Line elevation angle $\theta_{\text{line}}$ is **not a direct pilot control**—it is an aerodynamic resultant driven by force vector equilibrium:
  $$\theta_{\text{eq}} \approx \arctan\left(\frac{F_{\text{lift, total}} - W_{\text{total}}}{F_{\text{drag, total}}}\right)$$
- All reporting artifacts and UI dashboards must explicitly distinguish between prescribed target elevation angles and calculated system $L/D$ equilibrium elevation states.

---

## 3. Chart Exploration & Graphical Representation Standards

Before finalizing reporting figures, Cameron's agent should conduct a **Chart Exploration Phase** using `CairoMakie` / `Makie` in [`notebooks/sweep_plots.jl`](file:///home/rodbot/Documents/GitHub/CoaxialAutogyroStacking.jl/notebooks/sweep_plots.jl).

### Data Fields Available for Visualization (`bem_full_sweep.tsv`)
* **Independent Variables**: Radius $R$ (m), Stack Count $N$, Spacing (m), Tilt Profile (`uniform`, `top_draggy`, `bottom_lifty`, `graded`), Wind Speed $v$ (m/s), Elevation Angle ($^\circ$).
* **Dependent / Computed Fields**: Tip Speed $v_{\text{tip}}$ (m/s), Tip Reynolds $Re$, Anchor Tension $T$ (N), Tension per Mass $N/\text{kg}$, Tension CV, Autorotation RPM.

### 5 Charting Dimensions & Axis Variations to Explore

```
1. PARETO FRONTIER SURFACES          2. FEASIBILITY HEATMAPS
   • X: Anchor Tension (N)              • X: Rotor Radius (m)
   • Y: Tension per Mass (N/kg)         • Y: Wind Speed (m/s)
   • Z/Color: Tension CV (Stability)    • Mask: Red out tip speed > 120 m/s or Re < 5x10⁵
   • Marker Size: Stack Count N

3. TENSION ACCUMULATION PROFILES     4. RADIAL BEM LOADING (Snel Effect)
   • X: Distance along line (m)         • X: Normalized Radius r/R (0 to 1)
   • Y: Cumulative Tension (N)          • Y: Lift Coefficient C_L (2D vs 3D Snel)
   • Shading: Lift vs Drag vs Weight    • Series: Root to tip station curves

5. RADAR / SPIDER COMPARISONS
   • Axes: Raw Tension, Mass Efficiency, Gust Stability, Acoustic Margin, Line Inclination
   • Compare: uniform vs top_draggy vs bottom_lifty vs graded
```

---

## 4. Summary of Repository File Structure

```
src/
  CoaxialAutogyroStacking.jl   module entry — includes + exports
  airfoil_data.jl              NACA 0012 polar lookup tables (Re 10⁵ to 10⁶)
  bem.jl                       BEM induction solver + autorotation RPM
  line_section.jl              bare line drag
  optimisation.jl              tilt profile optimisation
  pca2_data.jl                 PCA-2 empirical table + pca2_interp
  polygon_line.jl              polygon chain line geometry equilibrium
  rotor.jl                     AutogyroRotor struct + force calculations
  stack.jl                     AutogyroStack struct + stack_tension_profile
  stall_delay.jl               Snel 3-D stall-delay correction (snel_cl_3d)
  sweep.jl                     parameter_sweep (PCA-2 and BEM)
  viability.jl                 tip speed, Reynolds & viability checks

test/                          12 test_<module>.jl files (345 green tests)
notebooks/                     dashboard.jl, sweep_plots.jl, PRD_DASHBOARD.md
schematics/                    OpenSCAD 3D models, SVG/PDF vector cross-sections
scripts/                       bem_full_sweep.jl, standalone dashboard.jl
```

---

## 5. Definition of Done for Future Tasks

1. **Strict TDD**: Write failing test in `test/test_<module>.jl` first $\rightarrow$ minimal implementation in `src/<module>.jl` $\rightarrow$ refactor.
2. **Docs & Exports**: Export public functions in `CoaxialAutogyroStacking.jl` and add docstrings with `# Examples`.
3. **Commit Prefix**: `Phase X Task Y: description`.
4. **Full Test Suite Pass**: `julia --project=. test/runtests.jl` before every commit.
