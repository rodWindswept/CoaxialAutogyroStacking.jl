# src/bem.jl - Blade-element momentum theory for autorotating rotors
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
function bem_induction(rotor::AutogyroRotor, rho, v_wind, omega, n_stations=20; stall_delay=true)
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
        cl_3d = 0.0  # will hold 3-D corrected CL for force integration
        for _ in 1:100
            v_axial = v_wind * (1.0 - a)
            v_tan = omega * r_i
            phi = atan(v_axial, v_tan)

            # Local angle of attack (blade pitch + possibly twist, 0 for now)
            alpha_deg = rad2deg(phi) - rotor.blade_pitch_deg

            cl = naca0012_cl(alpha_deg, Re_local)
            cd = naca0012_cd(alpha_deg, Re_local)

            # 3-D stall-delay correction (Snel) if enabled — computed for
            # force integration only (2-D CL drives induction iteration).
            cl_3d = cl
            if stall_delay
                c_over_r = clamp(rotor.blade_chord / r_i, 0.0, 0.5)
                lambda_local = omega * r_i / max(v_wind, 0.1)
                cl_3d = snel_cl_3d(cl_3d, alpha_deg, lambda_local, c_over_r)
            end

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
        dT, dQ = bem_station(r_i, rotor.blade_chord, cl_3d, cd, rho, v_wind, omega, a, dr)

        # Accumulate (per blade → total for all blades)
        T_total += dT * rotor.n_blades
        Q_total += dQ * rotor.n_blades
    end

    return T_total, Q_total
end

export bem_induction

# ── Task 5: Autorotation RPM via torque equilibrium ────────────────────────

"""
    bem_autorotation_rpm(rotor::AutogyroRotor, rho, v_through) -> Float64

Find the autorotation RPM — the rotational speed where net aerodynamic torque
is zero — via bisection root-find on Q(ω) = 0.

`v_through` is the velocity component normal to the rotor disk (m/s).
For a rotor at elevation φ and tilt δ: v_through = v_wind × sin(90° − φ + δ).

# Algorithm
Bisection on f(ω) = bem_induction(…)[2] between ω ∈ [0.5, ω_max] where
ω_max = 120 / R (tip-speed noise limit, ~Mach 0.3). If Q has the same sign
at both bounds (no root in range), returns the bound with smaller |Q|.

# Examples
```jldoctest
julia> r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0);

julia> rpm = bem_autorotation_rpm(r, 1.225, 8.0);

julia> rpm > 10.0 && rpm < 500.0
true
```
"""
function bem_autorotation_rpm(rotor::AutogyroRotor, rho, v_through)
    # Scan ω range for sign change (Q(ω) may not be monotonic)
    n_stations = 12
    ω_min = 1.0
    ω_max = 60.0 / rotor.radius  # ~20 rad/s for R=3m, catches first crossing
    ω_step = (ω_max - ω_min) / 8.0

    Q_prev = nothing
    ω_prev = ω_min

    for ω in (ω_min + ω_step):ω_step:ω_max
        _, Q = bem_induction(rotor, rho, v_through, ω, n_stations)

        if Q_prev !== nothing && Q_prev * Q <= 0.0
            # Sign change found — bisect in [ω_prev, ω]
            ω_lo, ω_hi = ω_prev, ω
            for _ in 1:40
                ω_mid = (ω_lo + ω_hi) / 2.0
                _, Q_mid = bem_induction(rotor, rho, v_through, ω_mid, n_stations)
                if Q_mid * Q_prev > 0.0
                    ω_lo = ω_mid
                else
                    ω_hi = ω_mid
                end
                if abs(ω_hi - ω_lo) < 1e-4
                    break
                end
            end
            return (ω_lo + ω_hi) / 2.0 * 60.0 / (2π)
        end

        Q_prev = Q
        ω_prev = ω
    end

    # No sign change found — return ω with smallest |Q|
    _, Q_lo = bem_induction(rotor, rho, v_through, ω_min, n_stations)
    _, Q_hi = bem_induction(rotor, rho, v_through, ω_max, n_stations)
    best_ω = abs(Q_lo) < abs(Q_hi) ? ω_min : ω_max
    return best_ω * 60.0 / (2π)
end

export bem_autorotation_rpm

# ── Task 6: Full BEM force computation ─────────────────────────────────────

"""
    rotor_force_bem(rotor::AutogyroRotor, rho, v_wind, elev_deg) -> (F_line, T, rpm)

Full blade-element momentum force computation for a single rotor.
Replaces the PCA-2 empirical lookup with physics-based BEM.

# Algorithm
1. Effective disk AoA: α_eff = 90° − elev + tilt
2. Through-disk velocity: v_through = v_wind × sin(α_eff)
3. Autorotation RPM from torque equilibrium: [`bem_autorotation_rpm`](@ref)
4. Thrust from full BEM pass: [`bem_induction`](@ref)
5. Along-line force: F_line ≈ T × cos(tilt_deg)  (first-order projection)

# Returns
- `F_line`: force projected onto the line axis (N).
- `T`: BEM thrust normal to rotor disk (N).
- `rpm`: autorotation rotational speed.

# Examples
```jldoctest
julia> r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0);

julia> F_line, T, rpm = rotor_force_bem(r, 1.225, 8.0, 55.0);

julia> F_line > 0.0 && rpm > 0.0
true
```
"""
function rotor_force_bem(rotor::AutogyroRotor, rho, v_wind, elev_deg)
    α_eff = effective_alpha(rotor, elev_deg)
    v_through = v_wind * sind(α_eff)

    rpm = bem_autorotation_rpm(rotor, rho, v_through)
    omega = rpm * 2π / 60.0

    T, _ = bem_induction(rotor, rho, v_through, omega, 20)

    # First-order: along-line component of thrust
    F_line = T * cosd(rotor.tilt_deg)

    return F_line, T, rpm
end

export rotor_force_bem
