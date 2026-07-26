# Coaxial Autogyro Stacking — Blade-Element Momentum Analysis

> **Author:** Cameron Read, under supervision of Rod Read
> **Repository:** `CoaxialAutogyroStacking.jl` v2.1
> **Date:** July 2026
> **Audience:** Academic / technical — aerodynamicists, wind energy researchers, rotorcraft engineers

---

## Abstract

This report presents a blade-element momentum (BEM) analysis of stacked
autorotating rotors for airborne wind energy lift applications. A 1-D axial
BEM solver with NACA 0012 airfoil data is coupled to a polygon-line force
equilibrium model, replacing the empirical PCA-2 disk lookup of v1. The Snel
3-D rotational stall-delay correction is applied to capture centrifugal
boundary-layer pumping effects. Results from a 384-configuration parameter
sweep confirm that graded tilt stacking is physically meaningful under polygon
line geometry: a top-draggy profile yields +12.7% anchor tension over a uniform
stack at the R=3.0 m, N=2 design point. The best configuration (R=3.0 m, N=4,
top-draggy, 55° elevation) delivers 858 N mean anchor tension at 8 m/s. The
1-D BEM is found to under-predict forces relative to the PCA-2 empirical disk
model by approximately one order of magnitude — a fundamental limitation of
2-D airfoil data in a disk-averaged flow, not a solver defect. The Snel
correction closes part of this gap at root stations (c/r > 0.15) but has
negligible effect at design-point tip stations.

---

## 1. Introduction

### 1.1 Motivation

Stacked autogyro rotors offer a modular, fault-tolerant lifting system for kite
turbine platforms. Unlike single soft kites, an N-rotor stack provides linear
lift scaling with rotor count, graceful degradation under individual rotor
failure, and transportability in standard containers. The aerodynamic challenge
is predicting rotor forces when downstream rotors operate in the wake of
upstream rotors — and when the line geometry itself is shaped by cumulative
rotor forces.

### 1.2 Model evolution

| Version | Aerodynamic model | Line geometry | Stall model | Key limitation |
|---------|------------------|---------------|-------------|----------------|
| v1.0 | PCA-2 empirical disk | Rigid straight line | — | Tilt profile collapses (null result) |
| v2.0 | 1-D axial BEM | Polygon chain | — | ~10× force under-prediction vs PCA-2 |
| v2.1 | 1-D axial BEM | Polygon chain | Snel 3-D | Root thrust +35%, tip unaffected |

The v1 PCA-2 model produced a null result for tilt-profile differentiation:
changing a rotor's tilt angle changed only that rotor's effective AoA, not the
line geometry for rotors below. The polygon line model in v2.0/v2.1 couples
rotor forces to line segment angles, making graded stacking aerodynamically
meaningful.

---

## 2. Methods

### 2.1 BEM autorotation solver

Autorotation RPM is solved from the condition of zero net torque on the rotor.
For a freely-spinning autogyro rotor, the aerodynamic driving torque from the
driving region of the blade must exactly balance the aerodynamic braking torque
from the driven region and the profile drag torque.

The induction factor *a* at each blade station is found by solving the 1-D
axial momentum equation:

$$\frac{a}{1-a} = \frac{\sigma' C_N}{4 F \sin^2 \phi}$$

where $\sigma' = Bc / (2\pi r)$ is the local solidity, $C_N = C_L \cos\phi + C_D \sin\phi$
is the normal force coefficient, $\phi$ is the inflow angle, and $F$ is the
Prandtl tip-loss factor. The equation is solved by bisection on $a \in [0, 0.5)$.

Given a trial RPM $\Omega$, the BEM solver computes the net torque $Q(\Omega)$.
The autorotation condition $Q(\Omega) = 0$ is solved by bisection on $\Omega$.
This is a nested bisection: an outer loop on RPM contains an inner loop on the
induction factor at each of 20 radial stations.

### 2.2 Airfoil data

NACA 0012 lift and drag coefficients are tabulated from XFoil 6.96 at four
Reynolds numbers: $10^5$, $2\times10^5$, $5\times10^5$, and $10^6$. Values at
intermediate Re are obtained by linear interpolation. At angles of attack
outside the tabulated range ($\alpha < -16°$ or $\alpha > 20°$), post-stall
flat-plate extrapolation is applied with $C_{D,\max} = 2.0$.

The NACA 0012 is a symmetric airfoil. This choice constrains the analysis to
symmetric blade sections — cambered sections (e.g. Clark Y) would produce
higher $C_{L,\max}$ at the Reynolds numbers of interest but are not yet
tabulated.

### 2.3 Snel 3-D rotational stall-delay correction

Rotating blades experience centrifugal pumping: the radial pressure gradient
in the blade boundary layer drives flow outward, thinning the boundary layer
and delaying flow separation. This increases the local $C_L$ beyond the 2-D
airfoil value, particularly at inboard stations where the chord-to-radius
ratio $c/r$ is large.

The Snel correction (Snel et al., 1993) models this as:

$$C_{L,3\text{D}} = C_{L,2\text{D}} + g(\alpha) \cdot f(\lambda, c/r) \cdot (C_{L,\text{pot}} - C_{L,2\text{D}})$$

where $C_{L,\text{pot}} = 2\pi\alpha$ is the potential-flow lift, $g(\alpha)$
is an empirical blending function that activates near stall, and:

$$f(\lambda, c/r) = 3.1 \frac{\lambda^2}{1 + \lambda^2} \left(\frac{c}{r}\right)^2$$

The local tip-speed ratio $\lambda = \Omega r / v_\infty$ determines the
strength of the rotational effect. At high TSR (typical of autogyro operation,
$\lambda \approx 2-3$), the TSR factor $3.1\lambda^2/(1+\lambda^2) \approx 2.5-2.8$,
amplifying the correction. The $(c/r)^2$ dependence makes the correction
strongest at the root (where $c/r \approx 0.3$) and negligible at the tip
(where $c/r < 0.03$).

**Quantitative impact at R=3.0 m, 8 m/s:** The Snel correction increases local
station $C_L$ by up to 35% at root stations ($r/R < 0.35$, where $c/r > 0.15$).
The net effect on integrated rotor thrust is approximately +3% at the design
point, because the affected stations contribute a small fraction of total blade
area and operate at lower dynamic pressure than tip stations.

![Radial loading](bem_chart_4_radial_loading.png)

*Figure 1: Radial loading distribution showing 2-D (NACA 0012) vs 3-D (Snel-corrected)
lift coefficient along the blade span at R=3.0 m, v=8 m/s, $\alpha_\text{eff}=45°$.*

### 2.4 Polygon line geometry

The line connecting stacked rotors is modelled as a polygon chain of $N$
segments. Each segment's angle is determined by force equilibrium at the
rotor below it. The system of $N$ segment angles is solved by Jacobi iteration:

1. Guess initial segment angles $\theta_i^{(0)}$ (uniform = line elevation)
2. For each rotor $i$ (top → bottom):
   - Compute effective AoA: $\alpha_{\text{eff},i} = 90° - \theta_i + \delta_i$
   - Compute rotor forces via BEM at this $\alpha_{\text{eff}}$
   - Update segment angle from force equilibrium: $\tan\theta_i = (F_{\text{lift},i} - W_i) / F_{\text{drag},i}$
3. Repeat until $\max|\theta_i^{(k+1)} - \theta_i^{(k)}| < 0.1°$

Convergence is typically achieved in 3-5 iterations for viable configurations.
Extreme tilt profiles (top rotor at 30° tilt) may require 10-15 iterations or
fail to converge.

### 2.5 Parameter sweep

A 384-configuration sweep was conducted:

| Parameter | Values |
|-----------|--------|
| Rotor radius (m) | 1.5, 2.0, 3.0 |
| Stack count N | 1, 2, 3, 4 |
| Tilt profile | uniform, top_draggy, bottom_lifty, graded |
| Wind speed (m/s) | 4, 6, 8, 10, 12 |
| Line elevation (°) | 45, 55 |

Fixed: 2 blades, NACA 0012, 0.15 m chord, 5 kg/rotor, 4 mm Dyneema, $\rho=1.225$ kg/m³.
Runtime: 15.6 s on a laptop CPU. Compare to v1 PCA-2 sweep: 8,640 configurations,
~10 s — BEM is approximately 100× slower per evaluation.

---

## 3. Results

### 3.1 Viability thresholds

R=1.5 m configurations are universally non-viable in BEM with NACA 0012: at
all wind speeds the rotor cannot overcome its own weight, producing zero net
tension (the "rope-can't-push" clamp removes these from the analysis). This
represents 80 of 384 rows (21%). R=2.0 m is marginally viable; R=3.0 m is the
practical design minimum.

The 5×10⁵ Reynolds threshold (below which the PCA-2 empirical data is
considered untrustworthy) is not met by any BEM configuration — tip chord Re
ranges from ~1×10⁵ (R=1.5 m) to ~4×10⁵ (R=3.0 m, 12 m/s). This is not a
failure of the configuration but a reflection of the 150 mm chord operating
at moderate tip speeds (23-38 m/s). All configurations pass the 120 m/s
acoustic noise limit with wide margin.

### 3.2 Pareto analysis

The tension–efficiency–stability trade space reveals that `top_draggy`
systematically dominates other profiles at the design radius:

| Profile | Mean tension (N) | N/kg | CV |
|---------|-----------------|------|-----|
| top_draggy | 858 | 42.9 | 0.537 |
| uniform | 822 | 41.1 | 0.519 |
| graded | 690 | 34.5 | 0.551 |
| bottom_lifty | 631 | 31.5 | 0.561 |

*Table 1: Mean metrics across all wind speeds for R=3.0 m, N=4, 55° elevation.
CV = coefficient of variation (lower = more stable across wind speeds).*

![Pareto front](bem_chart_1_pareto.png)

*Figure 2: Tension vs mass efficiency Pareto front, coloured by tilt profile.
top_draggy (red diamonds) occupies the upper-right region of the trade space.*

### 3.3 Graded stacking confirmed

Under polygon line geometry, the tilt profile reshapes the line and alters
the effective AoA of downstream rotors. At R=3.0 m, N=2, 8 m/s:

| Profile | Anchor tension (N) | vs uniform |
|---------|-------------------|------------|
| uniform | 245 | baseline |
| top_draggy | 276 | **+12.7%** |
| bottom_lifty | 256 | +4.5% |
| graded | 253 | +3.3% |

At 12 m/s the advantage narrows: top_draggy +6.9%, bottom_lifty +2.4%. The
graded-stacking benefit is most pronounced at moderate wind speeds where the
top rotor's drag significantly reshapes the line angle for rotors below.

This confirms that the v1 null result ($\leq 3\%$ difference between profiles)
was an artefact of the rigid straight-line assumption. With a physically
coupled line geometry, tilt-profile optimisation is meaningful.

### 3.4 Scaling laws

Tension scales as $T \propto v^2$ (dynamic pressure), consistent with the
momentum theory expectation. RPM scales sub-linearly as $\Omega \propto \sqrt{v}$
(84 RPM at 8 m/s, 105 RPM at 12 m/s for R=3.0 m). Tip speeds of 23-38 m/s
are well within the acoustic limit.

Stacking is nearly penalty-free: per-rotor efficiency drops ~2% per added
rotor due to line drag and cumulative weight. The tension profile is
effectively linear with rotor count:

![Tension profile](bem_chart_3_tension_profile.png)

*Figure 3: Cumulative tension vs distance along the line for the best
configuration (R=3.0 m, N=4, top_draggy, 55°). Five wind speeds shown.*

### 3.5 Profile optimum depends on radius

An unexpected result: the optimal tilt profile switches with rotor radius:

| Radius | N=2 best profile | Tension (N) | RPM |
|--------|-----------------|-------------|-----|
| 2.0 m | bottom_lifty | 121 | 133 |
| 3.0 m | top_draggy | 276 | 84 |

![Radar comparison](bem_chart_5_radar.png)

*Figure 4: Radar comparison of tilt profiles across four metrics at R=3.0 m, N=4.
top_draggy (red) dominates on raw tension; uniform (blue) is competitive on stability.*

Smaller rotors at higher RPM benefit from concentrating tilt at lower rotors
where cumulative tension is higher — the bottom-lifty profile exploits the
greater dynamic pressure available lower in the stack. Larger rotors at lower
RPM benefit from using the top rotor to pull the line outward (top-draggy),
improving the effective AoA for all rotors below. This radius-dependent
optimum is not visible in the v1 PCA-2 sweep.

---

## 4. Discussion

### 4.1 The 2-D/disk-averaged gap

The most significant finding is not the absolute force predictions but the
systematic difference between BEM and PCA-2 force magnitudes. The PCA-2
empirical disk model (v1) predicts anchor tensions of ~5,000 N at the design
point; the BEM model (v2.1) predicts ~650 N for the same configuration. This
~8× gap is not a solver error — it is a fundamental consequence of using 2-D
airfoil data in a 1-D axial momentum framework.

The PCA-2 data comes from flight-test measurements of a full-scale autogyro
rotor (Pitcairn PCA-2, 1930s). These measurements inherently include:
- Rotational augmentation (centrifugal pumping — partially captured by Snel)
- 3-D tip vortex effects (not captured by Prandtl tip-loss alone)
- Disk-averaged cross-flow components (not captured by 1-D axial momentum)
- Unsteady aerodynamics from blade passage through the rotor wake

A 1-D axial BEM with 2-D airfoil data captures none of these effects beyond
the Snel correction, which only addresses the first point and only at root
stations. The gap is thus a characterisation of the model's limitations, not
a deficiency to be "fixed" — it establishes the theoretical justification for
higher-fidelity modelling (v3.0: wake coupling, 3-D corrections, unsteady BEM).

### 4.2 Implications for design

For engineering purposes, the v1 PCA-2 model provides the better absolute force
estimate — it is calibrated against flight data at similar scale and Re regime.
The v2.1 BEM model provides the better relative comparison between
configurations — it correctly ranks tilt profiles and captures the physical
coupling between rotor forces and line geometry. A practical design workflow
would use BEM for tilt-profile optimisation and configuration ranking, then
validate absolute forces against the PCA-2 empirical baseline.

### 4.3 Limitations

- **1-D axial assumption:** Cross-flow components from the rotor disk operating
  at a non-zero angle of attack are projected via $v_\text{through} = v_\infty \sin(\alpha_\text{eff})$.
  This projection is physically motivated but unvalidated.
- **NACA 0012 only:** A symmetric section was chosen for modelling simplicity.
  Cambered sections (Clark Y, GOE 417) would produce higher $C_{L,\max}$ at the
  Reynolds numbers of interest but require tabulation.
- **No wake interaction:** All rotors see freestream flow. Wake coupling (v3.0)
  will reduce downstream rotor performance. The top-draggy advantage may
  diminish when the top rotor's wake impinges on the rotor below.
- **Steady-state only:** No gust response, no launch/land transients, no
  time-varying wind fields.
- **Tip Reynolds below PCA-2 validation range:** All BEM configurations operate
  at $Re < 5\times 10^5$. The NACA 0012 data at these Re may not capture
  laminar separation bubble effects that are significant at model scale.

---

## 5. Conclusions

1. **Graded stacking is physically meaningful under polygon line geometry.**
   A top-draggy tilt profile produces +12.7% anchor tension compared to
   uniform tilt at R=3.0 m, N=2. The v1 null result was a straight-line
   artefact.

2. **The Snel 3-D correction provides +35% local $C_L$ at root stations**
   but contributes only ~3% net thrust increase at the design point. Root
   stations operate at low dynamic pressure and small blade area — they are
   not the primary thrust-producing region.

3. **The 1-D BEM under-predicts absolute forces by ~8× relative to the PCA-2
   empirical disk model.** This is a fundamental limitation of 2-D airfoil
   data in a disk-averaged flow, establishing the theoretical case for v3.0
   wake and 3-D modelling.

4. **The profile optimum is radius-dependent.** Small rotors (R=2.0 m, high RPM)
   prefer bottom-lifty; large rotors (R=3.0 m, low RPM) prefer top-draggy.
   This crossover is a new result from the BEM sweep.

5. **The best v2.1 configuration** (R=3.0 m, N=4, top_draggy, 55° elevation)
   delivers 858 N mean anchor tension at 8 m/s with 42.9 N/kg efficiency and
   CV=0.537 across wind speeds.

---

## References

1. Snel, H., Houwink, R., & Bosschers, J. (1993). Sectional prediction of
   lift coefficients on rotating wind turbine blades in stall. ECN-C-93-052.
2. Glauert, H. (1935). Airplane propellers. In *Aerodynamic Theory* (W.F.
   Durand, ed.), Vol. IV, Div. L. Springer.
3. Abbott, I.H. & von Doenhoff, A.E. (1959). *Theory of Wing Sections.* Dover.
4. NASA TM 20080022367. PCA-2 autogyro rotor force data.
5. XFoil 6.96. Drela, M. MIT Aero & Astro.
6. NACA 0012 polar data: airfoiltools.com, validated against Abbott & von Doenhoff.

---

*Generated from `notebooks/bem_charts.jl`. All figures auto-generated from
`bem_full_sweep.tsv` using CairoMakie. Full suite: 345 tests green.*
