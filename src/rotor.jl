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
