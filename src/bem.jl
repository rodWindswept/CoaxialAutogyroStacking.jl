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

# ── Task 4: BEM induction loop ─────────────────────────────────────────────

"""
    bem_induction(rotor::AutogyroRotor, rho, v_wind, omega, n_stations=20) -> (T, Q)

Full blade-element momentum computation for one rotor at given rotational speed.
Discretises the blade into `n_stations` annuli, solves the induction factor `a`
at each station via momentum theory with Glauert correction for the turbulent
wake state (a > 0.2), then integrates thrust `T` (N) and torque `Q` (N·m).

# Physics

At each radial station r_i:
1. Guess a = 0.3, iterate:
   - v_axial = v_wind × (1 − a), v_tan = ω × r
   - φ = atan(v_axial, v_tan), α = φ − θ (local AoA)
   - CL, CD from NACA 0012 at local Re
   - cn = CL·cos(φ) + CD·sin(φ)
   - σ' = n_blades × chord / (2πr)
   - Momentum: a_new from CT = σ'·cn / sin²(φ)
     • CT ≤ 0.96: a_new = 1 / (1 + 4·sin²(φ) / (σ'·cn))
     • CT > 0.96: Glauert correction (Buhl)
   - Converged when |a − a_new| < 1e-6
2. Call [`bem_station`](@ref) with converged a, accumulate dT, dQ.

Returns total thrust and torque (summed across all blades).

# Arguments
- `rotor::AutogyroRotor`: the rotor (geometry + blade pitch).
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `omega`: rotor angular velocity (rad/s).
- `n_stations`: number of radial stations (default 20).

# Examples
```jldoctest
julia> r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0);

julia> T, Q = bem_induction(r, 1.225, 8.0, 4.71, 10);

julia> T > 0.0
true
```
"""
function bem_induction(rotor::AutogyroRotor, rho, v_wind, omega, n_stations=20)
    dr = (rotor.radius - rotor.hub_radius) / n_stations
    mu = 1.81e-5  # dynamic viscosity of air

    T_total = 0.0
    Q_total = 0.0

    for i in 1:n_stations
        # Station at midpoint of annulus
        r_i = rotor.hub_radius + (i - 0.5) * dr

        # Approximate local Reynolds number (tangential speed dominates)
        Re_local = rho * (omega * r_i) * rotor.blade_chord / mu

        # Induction factor iteration
        a = 0.3
        cl, cd = 0.0, 0.0
        for _ in 1:100
            v_axial = v_wind * (1.0 - a)
            v_tan = omega * r_i
            phi = atan(v_axial, v_tan)

            # Local angle of attack (blade pitch + possibly twist, 0 for now)
            alpha_deg = rad2deg(phi) - rotor.blade_pitch_deg

            cl = naca0012_cl(alpha_deg, Re_local)
            cd = naca0012_cd(alpha_deg, Re_local)

            cn = cl * cos(phi) + cd * sin(phi)
            sigma_local = rotor.n_blades * rotor.blade_chord / (2π * r_i)

            # CT from blade element theory
            sin_phi = sin(phi)
            if sin_phi < 1e-10
                # Blade nearly edge-on to flow — negligible forces
                a_new = a
                break
            end

            CT = sigma_local * cn / sin_phi^2

            # Momentum theory with Glauert correction
            if CT <= 0.96
                a_new = 1.0 / (1.0 + 4.0 * sin_phi^2 / (sigma_local * cn))
            else
                # Buhl's modification of Glauert correction
                a_new = 0.143 + sqrt(0.0203 - 0.6427 * (0.889 - CT))
            end

            # Clamp to physical range
            a_new = clamp(a_new, 0.0, 1.0)

            if abs(a - a_new) < 1e-6
                a = a_new
                break
            end
            a = a_new
        end

        # Compute forces at this station with converged (or last) a
        dT, dQ = bem_station(r_i, rotor.blade_chord, cl, cd, rho, v_wind, omega, a, dr)

        # Accumulate (per blade → total for all blades)
        T_total += dT * rotor.n_blades
        Q_total += dQ * rotor.n_blades
    end

    return T_total, Q_total
end

export bem_induction
