# src/polygon_line.jl - Polygon line geometry for stacked rotors
#
# Phase 10c: Each rotor's tilt bends the line. This changes effective AoA
# for rotors below. Graded stacking depends on this coupling.

"""
    solve_polygon_angles(rotors, anchor_angle_deg, rho, v_wind; max_iter=10, tol=0.1)

Compute segment angles for a polygon chain of N rotors on a kite line.
Returns segment angles θ (one per rotor, degrees), tension profile T
(n_rotors+1 entries, N), and F_line values per rotor.

# Physics

For each rotor i (top → bottom):
- Effective AoA: α_eff = 90° − θ[i] + tilt_i  (disk-normal angle)
- BEM thrust T acts along the disk normal at angle α_eff
- Force equilibrium determines segment angle below:
    T_x = T_above·cos(θ) + T·cos(α_eff)
    T_y = T_above·sin(θ) + T·sin(α_eff) − W
    θ_new = atan(T_y, T_x)

Jacobi iteration until all θ converge within `tol` degrees.

# Arguments
- `rotors::Vector{AutogyroRotor}`: rotors ordered top → bottom.
- `anchor_angle_deg`: elevation of bottom segment (degrees).
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `max_iter`: maximum iterations (default 10).
- `tol`: convergence tolerance in degrees (default 0.1).

# Returns
- `θ::Vector{Float64}`: segment angles, one per rotor (degrees).
- `T::Vector{Float64}`: tension profile, n_rotors+1 entries (N).
- `F::Vector{Float64}`: along-line force per rotor (N).
"""
function solve_polygon_angles(rotors, anchor_angle_deg, rho, v_wind; max_iter=10, tol=0.1)
    n = length(rotors)
    θ = fill(anchor_angle_deg, n)  # initial guess: straight line
    F_line = zeros(n)

    for _ in 1:max_iter
        θ_old = copy(θ)
        T_above = 0.0

        for i in 1:n
            # BEM force at current segment angle. Uses disk-normal thrust T.
            _, T_thrust, _ = rotor_force_bem(rotors[i], rho, v_wind, θ[i])
            W = rotors[i].mass * 9.81

            # Thrust acts at disk-normal angle: α_eff = 90° − θ + δ
            α_eff = effective_alpha(rotors[i], θ[i])

            # Force equilibrium: T_above at θ[i] + T_thrust at α_eff + weight down
            T_x = T_above * cosd(θ[i]) + T_thrust * cosd(α_eff)
            T_y = T_above * sind(θ[i]) + T_thrust * sind(α_eff) - W

            T_below = sqrt(T_x^2 + T_y^2)

            # Under-relaxation damping (ω = 0.5) suppresses Jacobi oscillation
            # from the thrust-angle feedback loop.
            θ_new = atand(T_y, T_x)
            θ[i] = θ[i] + 0.5 * (θ_new - θ[i])

            # Clamp to physical range
            θ[i] = clamp(θ[i], 5.0, 85.0)

            # Along-line force for caller use
            F_line[i] = T_thrust * cosd(rotors[i].tilt_deg)

            T_above = T_below
        end

        if all(abs.(θ .- θ_old) .< tol)
            break
        end
    end

    # Build tension profile using converged polygon segment angles
    T = zeros(n + 1)
    T[1] = 0.0
    for i in 1:n
        _, T_thrust, _ = rotor_force_bem(rotors[i], rho, v_wind, θ[i])
        F_line_i = T_thrust * cosd(rotors[i].tilt_deg)
        W = rotors[i].mass * 9.81 * cosd(θ[i])
        T[i+1] = max(0.0, T[i] + F_line_i - W)
    end

    return θ, T, F_line
end

export solve_polygon_angles
