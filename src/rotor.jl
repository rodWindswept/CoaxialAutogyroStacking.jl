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
