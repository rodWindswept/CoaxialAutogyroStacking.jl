# src/rotor.jl — Single autogyro rotor struct and force calculations

"""
    AutogyroRotor(radius, hub_radius, n_blades, blade_chord, tilt_deg, blade_pitch_deg, mass)

A single lifting autogyro kite mounted on the kite line via a hollow hub,
thrust bearing, and tailplane frame. Immutable.

# Fields
- `radius::Float64`: rotor disk radius (m).
- `hub_radius::Float64`: inner / hub radius (m).
- `n_blades::Int`: number of blades.
- `blade_chord::Float64`: mean blade chord (m).
- `tilt_deg::Float64`: disk tilt angle (degrees) — the angle the rotor plane is
  pitched away from perpendicular to the kite line (leading edge forward-down
  into the wind, like a kite pitching). This is the primary control variable
  captured by the current PCA-2 disk model.
- `blade_pitch_deg::Float64`: rotor blade pitch angle (degrees) — collective
  pitch of individual blades on the hub. Adjustable independently of disk tilt.
  Not yet used in force calculations; the current PCA-2 lookup is 1-D (AoA
  only) and does not parameterise blade pitch.
- `mass::Float64`: rotor mass (kg).

# Examples
```jldoctest
julia> rotor = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0);

julia> rotor.tilt_deg
10.0
```
"""
struct AutogyroRotor
    radius          :: Float64
    hub_radius      :: Float64
    n_blades        :: Int
    blade_chord     :: Float64
    tilt_deg        :: Float64
    blade_pitch_deg :: Float64
    mass            :: Float64
end

"""
    rotor_disk_area(rotor::AutogyroRotor) -> Float64

Swept disk annulus area, π(R² − r_hub²), in m².

# Examples
```jldoctest
julia> rotor_disk_area(AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0))
7.037166538162688
```
"""
function rotor_disk_area(rotor::AutogyroRotor)
    return π * (rotor.radius^2 - rotor.hub_radius^2)
end

"""
    rotor_solidity(rotor::AutogyroRotor) -> Float64

Rotor solidity: ratio of total blade planform area to swept disk area.

    σ = n_blades × blade_chord / (π × radius)

Solidity is a first-order parameter for rotor aerodynamics — it determines
the blade loading distribution and the fraction of the disk that is "solid"
vs. open. The PCA-2 (σ ≈ 0.098, 3 blades, R=6.86 m, c=0.56 m) is a
high-solidity rotor; our typical lifting-autogyro rotors are lower solidity
(σ ≈ 0.03–0.05 for 2 blades at R=2–3 m with 0.15 m chord).

**Important:** The PCA-2 CL/CD data in `pca2_interp` is valid for σ ≈ 0.098.
Applying it to rotors with substantially different solidity introduces
systematic error. See Duquette & Visser (2003) for solidity effects.

# Examples
```jldoctest
julia> rotor_solidity(AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0))
0.06366197723675814
```
"""
function rotor_solidity(rotor::AutogyroRotor)
    return rotor.n_blades * rotor.blade_chord / (π * rotor.radius)
end

"""
    estimated_autorotation_rpm(rotor::AutogyroRotor, v_wind, α_eff_deg; λ=2.5) -> Float64

Estimated autorotation RPM based on a nominal tip-speed ratio.

In steady autorotation, the rotor settles at an RPM where the net aerodynamic
torque balances. The through-disk velocity is `v_wind × sin(α_eff)`, and the
tip-speed ratio λ = ΩR / v_through relates this to rotor speed:

    Ω = λ × v_wind × sin(α_eff) / R
    RPM = Ω × 60 / (2π)

The default λ = 2.5 is typical for autogyro rotors in axial/autorotating flow
(PCA-2 tip speed ~340 fps at ~130 fps axial inflow → λ ≈ 2.6). Wind turbines
operate at higher λ (6–8); autorotating rotors are slower.

**Caveat:** This is a first-order estimate. Actual RPM depends on blade
geometry, airfoil, solidity, and Reynolds number — none of which the PCA-2
disk model resolves. BEM (v2) will compute RPM from torque equilibrium.

# Arguments
- `rotor::AutogyroRotor`: the rotor.
- `v_wind`: freestream wind speed (m/s).
- `α_eff_deg`: effective disk angle of attack (degrees).
- `λ`: tip-speed ratio (default 2.5).

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0);

julia> round(estimated_autorotation_rpm(r, 8.0, 50.0), digits=1)
102.2
```
"""
function estimated_autorotation_rpm(rotor::AutogyroRotor, v_wind, α_eff_deg; λ=2.5)
    v_through = v_wind * sind(α_eff_deg)
    Ω = λ * v_through / rotor.radius
    return Ω * 60.0 / (2π)
end

"""
    effective_alpha(rotor::AutogyroRotor, line_elevation_deg) -> Float64

Effective disk angle of attack relative to the wind, in degrees:

    α_eff = 90° − line_elevation_deg + tilt_deg

With zero disk tilt (`tilt_deg = 0`), the rotor plane is perpendicular to the
line and `α_eff = 90° − elevation`. Tilting the disk (leading edge forward-down)
increases α_eff, shifting the operating point along the PCA-2 CL/CD curve.

The returned value is *not* clamped here — clamping to [0°, 90°] happens
downstream in [`pca2_interp`](@ref).

# Arguments
- `rotor`: the rotor (supplies `tilt_deg`).
- `line_elevation_deg`: line elevation above horizontal, in degrees.

# Examples
```jldoctest
julia> effective_alpha(AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0), 50.0)
50.0
```
"""
function effective_alpha(rotor::AutogyroRotor, line_elevation_deg)
    return 90.0 - line_elevation_deg + rotor.tilt_deg
end

"""
    rotor_force_along_line(rotor, rho, v_wind, line_elevation_deg)
        -> (F_line, F_lift, F_drag, cl_used, cd_used)

Aerodynamic forces on a single lifting autogyro kite disk, using PCA-2 empirical
coefficients.

# Arguments
- `rotor::AutogyroRotor`: the rotor.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `line_elevation_deg`: line elevation above horizontal (degrees).

# Returns
A 5-tuple `(F_line, F_lift, F_drag, cl_used, cd_used)`:
- `F_line`: force projected onto the line axis (N) — the tension-relevant term.
- `F_lift`: lift, perpendicular to the wind (N).
- `F_drag`: drag, parallel to the wind (N).
- `cl_used`, `cd_used`: the PCA-2 coefficients actually used.

# Physics
    α_eff  = 90° − line_elevation_deg + tilt_deg
    q      = ½·ρ·v²
    A_disk = π·R²
    F_lift = q·A_disk·CL          # ⊥ wind
    F_drag = q·A_disk·CD          # ∥ wind
    F_line = F_lift·sind(elev) + F_drag·cosd(elev)

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0);

julia> F_line, F_lift, F_drag, cl, cd = rotor_force_along_line(r, 1.225, 8.0, 50.0);

julia> round(F_line, digits=1)   # α_eff = 50° → CL=0.82, CD=0.86
325.8
```
"""
function rotor_force_along_line(rotor::AutogyroRotor, rho, v_wind, line_elevation_deg)
    α = effective_alpha(rotor, line_elevation_deg)
    cl, cd = pca2_interp(α)
    q = 0.5 * rho * v_wind^2
    A = rotor_disk_area(rotor)
    F_lift = q * A * cl
    F_drag = q * A * cd
    F_line = F_lift * sind(line_elevation_deg) + F_drag * cosd(line_elevation_deg)
    return F_line, F_lift, F_drag, cl, cd
end

"""
    rotor_tip_speed(rotor::AutogyroRotor, v_wind, α_eff_deg) -> Float64

Blade tip speed (m/s) for a rotor in autorotation.

Converts the estimated autorotation RPM to angular velocity and multiplies by
radius:

    ω = RPM × 2π / 60
    v_tip = ω × radius

Tip speed is important for noise constraints — the KTD.jl design limit is
120 m/s to stay well below Mach 0.3, above which tip noise becomes
significant.

# Arguments
- `rotor::AutogyroRotor`: the rotor.
- `v_wind`: freestream wind speed (m/s).
- `α_eff_deg`: effective disk angle of attack (degrees).

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0);

julia> round(rotor_tip_speed(r, 8.0, 50.0), digits=1)
15.3
```
"""
function rotor_tip_speed(rotor::AutogyroRotor, v_wind, α_eff_deg)
    rpm = estimated_autorotation_rpm(rotor, v_wind, α_eff_deg)
    ω = rpm * 2π / 60.0
    return ω * rotor.radius
end
