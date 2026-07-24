# src/polygon_line.jl — Polygon line geometry for stacked rotors
#
# Phase 10c: Each rotor's tilt bends the line, changing effective AoA
# for rotors below. This is what makes graded stacking meaningful.

"""
    solve_polygon_angles(rotors, anchor_angle_deg, rho, v_wind; max_iter=10, tol=0.1)

Compute segment angles for a polygon chain of N rotors on a kite line.
Returns segment angles θ (one per rotor, degrees), tension profile T
(n_rotors+1 entries, N), and F_line values per rotor.

# Physics

For each rotor i (top → bottom):
- Effective AoA: α_eff = 90° − θ[i] + tilt_i
- BEM force: F_line from [`rotor_force_bem`](@ref)
- Force equilibrium determines segment angle below:
    T_x = T_above·cos(θ) + F_line·sin(θ + δ)
    T_y = T_above·sin(θ) + F_line·cos(θ + δ) − W
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
    F = zeros(n)

    for _ in 1:max_iter
        θ_old = copy(θ)
        T_above = 0.0

        for i in 1:n
            # BEM force at current segment angle
            F_line, _, _ = rotor_force_bem(rotors[i], rho, v_wind, θ[i])
            F[i] = F_line
            W = rotors[i].mass * 9.81

            # Force vector sum: T_above (at angle θ[i]) + F_line (at angle θ[i] + δ)
            # + weight (downward)
            δ = rotors[i].tilt_deg
            T_x = T_above * cosd(θ[i]) + F_line * sind(θ[i] + δ)
            T_y = T_above * sind(θ[i]) + F_line * cosd(θ[i] + δ) - W

            T_below = sqrt(T_x^2 + T_y^2)

            # Update segment angle from force equilibrium
            θ[i] = atand(T_y, T_x)

            # Clamp to physical range
            θ[i] = clamp(θ[i], 5.0, 85.0)

            T_above = T_below
        end

        if all(abs.(θ .- θ_old) .< tol)
            break
        end
    end

    # Build tension profile
    T = zeros(n + 1)
    T[1] = 0.0
    T_above = 0.0
    for i in 1:n
        F_line, _, _ = rotor_force_bem(rotors[i], rho, v_wind, θ[i])
        # Simplified accumulation (line drag/weight omitted for now)
        W = rotors[i].mass * 9.81 * cosd(θ[i])
        T[i+1] = max(0.0, T[i] + F_line - W)
    end

    return θ, T, F
end

export solve_polygon_angles
