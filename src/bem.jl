# src/bem.jl — Blade-element momentum theory for autorotating rotors
#
# Phase 10b: BEM core functions.
# Task 3: bem_station — single blade-element station geometry and forces.

"""
    bem_station(r, chord, cl, cd, rho, v_wind, omega, a, dr) -> (dT, dQ)

Single blade-element station. Given the local flow conditions (induction factor `a`,
rotational speed `omega`), airfoil coefficients `cl` and `cd` at the local angle of
attack, computes the thrust `dT` (N) and torque `dQ` (N·m) contributions from an
annulus of width `dr` at radius `r`.

# Physics

    v_axial    = v_wind × (1 − a)         # induced axial velocity
    v_tan      = omega × r                 # blade tangential velocity
    v_rel      = √(v_axial² + v_tan²)      # relative velocity at blade
    φ          = atan(v_axial, v_tan)      # inflow angle
    cn         = cl·cos(φ) + cd·sin(φ)     # normal force coefficient
    ct         = cl·sin(φ) − cd·cos(φ)     # tangential force coefficient
    dT         = ½·ρ·v_rel²·chord·cn·dr    # thrust per blade
    dQ         = ½·ρ·v_rel²·chord·ct·r·dr  # torque per blade

Returns `(dT, dQ)` for a single blade. Multiply by `n_blades` to get
total station contribution.

# Arguments
- `r::Real`: radial position of the station (m).
- `chord::Real`: local blade chord (m).
- `cl::Real`: lift coefficient at the local angle of attack.
- `cd::Real`: drag coefficient at the local angle of attack.
- `rho::Real`: air density (kg/m³).
- `v_wind::Real`: freestream wind speed (m/s).
- `omega::Real`: rotor angular velocity (rad/s).
- `a::Real`: axial induction factor (0 ≤ a < 1).
- `dr::Real`: annulus width (m).

# Examples
```jldoctest
julia> dT, dQ = bem_station(2.0, 0.15, 0.5, 0.015, 1.225, 8.0, 4.71, 0.3, 0.3);

julia> dT > 0.0 && dQ > 0.0
true
```
"""
function bem_station(r, chord, cl, cd, rho, v_wind, omega, a, dr)
    v_axial = v_wind * (1.0 - a)
    v_tan = omega * r
    v_rel = sqrt(v_axial^2 + v_tan^2)
    phi = atan(v_axial, v_tan)
    
    cn = cl * cos(phi) + cd * sin(phi)
    ct = cl * sin(phi) - cd * cos(phi)
    
    q = 0.5 * rho * v_rel^2
    dT = q * chord * cn * dr
    dQ = q * chord * ct * r * dr
    
    return dT, dQ
end

export bem_station
