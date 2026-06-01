# src/optimisation.jl — Optimal pitch search for rotors and stacks

"""
    optimal_pitch(rotor::AutogyroRotor, rho, v_wind, elev_deg) -> (pitch_opt, F_max)

Grid-search the blade pitch (−30° to 30° in 0.5° steps) for the pitch that
maximises the along-line force component at a fixed line elevation.

# Arguments
- `rotor::AutogyroRotor`: template rotor; only its geometry/mass are reused, the
  pitch is swept.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `elev_deg`: line elevation above horizontal (degrees).

# Returns
- `(pitch_opt_deg, F_line_max_N)::Tuple{Float64,Float64}`.

# Examples
```julia
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 0.0, 5.0);

julia> pitch, F = optimal_pitch(r, 1.225, 8.0, 50.0);

julia> pitch     # peaks where α_eff hits the PCA-2 L/D sweet spot (~50°)
10.0
```
"""
function optimal_pitch(rotor::AutogyroRotor, rho, v_wind, elev_deg)
    best_pitch = 0.0
    best_F = -Inf
    for pitch in -30.0:0.5:30.0
        test_rotor = AutogyroRotor(
            rotor.radius, rotor.hub_radius, rotor.n_blades,
            rotor.blade_chord, pitch, rotor.mass)
        F_line, _, _, _, _ = rotor_force_along_line(test_rotor, rho, v_wind, elev_deg)
        if F_line > best_F
            best_F = F_line
            best_pitch = pitch
        end
    end
    return best_pitch, best_F
end

"""
    optimal_pitches(stack::AutogyroStack, rho, v_wind) -> Vector{Float64}

Optimise pitch independently for each rotor in the stack, at the stack's base
line elevation. Because v1 has no wake interaction, each rotor sees freestream
and is optimised in isolation via [`optimal_pitch`](@ref).

# Arguments
- `stack::AutogyroStack`: the rotor stack.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).

# Returns
- `Vector{Float64}`: optimal pitch (degrees), one per rotor, top → bottom.

# Examples
```julia
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 0.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 4), 0.004, 50.0);

julia> optimal_pitches(stack, 1.225, 8.0)
3-element Vector{Float64}:
 10.0
 10.0
 10.0
```
"""
function optimal_pitches(stack::AutogyroStack, rho, v_wind)
    return [optimal_pitch(r, rho, v_wind, stack.line_angle_deg)[1] for r in stack.rotors]
end

"""
    lift_force_steady(stack::AutogyroStack, rho, v_wind) -> (F_hub, T_anchor, elevation)

Integration-compatible API mirroring the `lift_force_steady` dispatch pattern in
`KiteTurbineDynamics.jl`. Returns the net hub force, anchor tension, and line
elevation for a steady-state stack configuration.

# Arguments
- `stack::AutogyroStack`: the rotor stack.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).

# Returns
- `(F_hub, T_anchor, elevation)`:
  - `F_hub`: total line force at the hub (sum of all rotor F_line values).
  - `T_anchor`: anchor tension (last entry of `stack_tension_profile`).
  - `elevation`: line elevation angle (degrees), from `stack.line_angle_deg`.

# Examples
```julia
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0);

julia> stack = AutogyroStack([r, r], fill(10.0, 3), 0.004, 50.0);

julia> F_hub, T_anchor, elev = lift_force_steady(stack, 1.225, 8.0);

julia> round(F_hub, digits=1)
654.5

julia> round(T_anchor, digits=1)
595.2

julia> elev
50.0
```
"""
function lift_force_steady(stack::AutogyroStack, rho, v_wind)
    profile = stack_tension_profile(stack, rho, v_wind)

    total_F_line = 0.0
    for rotor in stack.rotors
        F_line, _, _, _, _ = rotor_force_along_line(rotor, rho, v_wind, stack.line_angle_deg)
        total_F_line += F_line
    end

    return total_F_line, profile[end], stack.line_angle_deg
end
