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

Swept disk area, π·R², in m².

# Examples
```jldoctest
julia> rotor_disk_area(AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0))
7.0685834705770345
```
"""
function rotor_disk_area(rotor::AutogyroRotor)
    return π * rotor.radius^2
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
327.2
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
