# src/rotor.jl — Single autogyro rotor struct and force calculations

"""
    AutogyroRotor

A single autogyro rotor disk mounted coaxially on a kite line.

Fields:
- `radius`       : rotor disk radius (m)
- `hub_radius`   : inner / hub radius (m)
- `n_blades`     : number of blades
- `blade_chord`  : mean blade chord (m)
- `pitch_deg`    : blade collective pitch angle (degrees)
- `mass`         : rotor mass (kg)
"""
struct AutogyroRotor
    radius       :: Float64
    hub_radius   :: Float64
    n_blades     :: Int
    blade_chord  :: Float64
    pitch_deg    :: Float64
    mass         :: Float64
end

"""
    rotor_disk_area(rotor::AutogyroRotor)

Returns the swept disk area (π·R²) in m².
"""
function rotor_disk_area(rotor::AutogyroRotor)
    return π * rotor.radius^2
end

"""
    effective_alpha(rotor::AutogyroRotor, line_elevation_deg)

Effective disk angle of attack relative to the wind.

α_eff = 90° − line_elevation_deg + pitch_deg

The rotor disk is coaxial with the line. Pitching the blades independently
shifts the effective AoA along the PCA-2 CL/CD curve.
"""
function effective_alpha(rotor::AutogyroRotor, line_elevation_deg)
    return 90.0 - line_elevation_deg + rotor.pitch_deg
end

"""
    rotor_force_along_line(rotor::AutogyroRotor, rho, v_wind, line_elevation_deg)
        → (F_line, F_lift, F_drag, cl_used, cd_used)

Computes the aerodynamic forces on a single autogyro rotor disk using PCA-2
empirical coefficients.

Physics:
- α_eff = 90° − line_elevation_deg + pitch_deg
- CL, CD from PCA-2 interpolation at α_eff (clamped to [0°, 90°])
- q = ½ ρ v²  (dynamic pressure)
- A_disk = π·R²
- F_lift = q·A_disk·CL   (force perpendicular to wind)
- F_drag = q·A_disk·CD   (force parallel to wind)
- F_line = F_lift·sin(line_elevation) + F_drag·cos(line_elevation)
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
