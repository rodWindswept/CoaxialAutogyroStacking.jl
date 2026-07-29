# src/optimisation.jl - Optimal pitch search for rotors and stacks

"""
    optimal_rotor_tilt(rotor::AutogyroRotor, rho, v_wind, elev_deg) -> (tilt_opt, F_max)

Grid-search the disk tilt (−30° to 30° in 0.5° steps) for the tilt that
maximises the along-line force component at a fixed line elevation.

**Design-time, not control-time.** Disk tilt δ is the angle of the bearing
face machined into the moldings. You set it at manufacture. It stays fixed for
the life of the rotor unit. This function answers the design question: what
bearing angle should you machine for this rotor, given the expected operating
elevation and wind speed? It is NOT a per-flight control parameter. That role
belongs to blade pitch (`blade_pitch_deg`). Blade pitch adjusts via the
swashplate but the PCA-2 lookup does not model it yet (1-D on AoA only).

Check that the returned `F_max` exceeds `W·cos(elev)`. If not, the rotor
cannot overcome its own weight at this condition. No tilt will make this
rotor useful at this elevation.

This function optimises `tilt_deg` (disk angle), NOT `blade_pitch_deg`
(collective blade pitch). The two are distinct. Disk tilt pivots the entire
rotor plane. Blade pitch changes individual blade incidence. Only disk tilt
affects the current PCA-2 1-D lookup model.

# Arguments
- `rotor::AutogyroRotor`: template rotor; only its geometry/mass are reused, the
  tilt is swept.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `elev_deg`: line elevation above horizontal (degrees).

# Returns
- `(tilt_opt_deg, F_line_max_N)::Tuple{Float64,Float64}`.

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 0.0, 0.0, 5.0);

julia> tilt, F = optimal_rotor_tilt(r, 1.225, 8.0, 50.0);

julia> tilt     # peaks where α_eff hits the PCA-2 L/D sweet spot (~50°)
10.0

julia> F > r.mass * 9.81 * cosd(50.0)  # rotor overcomes its own weight
true
```
"""
function optimal_rotor_tilt(rotor::AutogyroRotor, rho, v_wind, elev_deg)
    best_tilt = 0.0
    best_F = -Inf
    for tilt in -30.0:0.5:30.0
        test_rotor = AutogyroRotor(
            rotor.radius, rotor.hub_radius, rotor.n_blades,
            rotor.blade_chord, tilt, rotor.blade_pitch_deg, rotor.mass)
        F_line, _, _, _, _ = rotor_force_along_line(test_rotor, rho, v_wind, elev_deg)
        if F_line > best_F
            best_F = F_line
            best_tilt = tilt
        end
    end
    return best_tilt, best_F
end

"""
    optimal_rotor_tilts(stack::AutogyroStack, rho, v_wind) -> Vector{Float64}

Optimise disk tilt independently for each rotor in the stack, at the stack's
base line elevation. v1 has no wake interaction. Each rotor sees freestream.
The function optimises each rotor in isolation via [`optimal_rotor_tilt`](@ref).

# Arguments
- `stack::AutogyroStack`: the rotor stack.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).

# Returns
- `Vector{Float64}`: optimal tilt (degrees), one per rotor, top → bottom.

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 0.0, 0.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 3), 0.004, 50.0);

julia> optimal_rotor_tilts(stack, 1.225, 8.0)
3-element Vector{Float64}:
 10.0
 10.0
 10.0
```
"""
function optimal_rotor_tilts(stack::AutogyroStack, rho, v_wind)
    return [optimal_rotor_tilt(r, rho, v_wind, stack.line_angle_deg)[1] for r in stack.rotors]
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
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 0.0, 5.0);

julia> stack = AutogyroStack([r, r], fill(10.0, 2), 0.004, 50.0);

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

# --- Phase 10d Task 12: BEM-aware multivariate tilt optimisation ---

"""
    optimal_rotor_tilts_bem(stack::AutogyroStack, rho, v_wind; tilt_candidates=0:5:30)

Coordinate-descent optimisation of disk tilts for all rotors. Uses polygon
line geometry and BEM aerodynamics. Unlike v1, this accounts for rotor-to-rotor
coupling. Changing a top rotor's tilt reshapes the line. This alters the
effective AoA for every rotor below.

# Algorithm
1. Start with current tilts from the stack's rotors.
2. For each rotor i (top→bottom), try all candidate tilts, pick the one
   that maximises anchor tension (via [`stack_tension_profile_polygon`](@ref)).
3. Repeat until tilts stabilise (max 10 iterations).

# Returns
- `tilts::Vector{Float64}`: optimal tilt per rotor (degrees).
- `T_anchor::Float64`: resulting anchor tension (N).
"""
function optimal_rotor_tilts_bem(stack::AutogyroStack, rho, v_wind;
                                  tilt_candidates=0:5:30)
    n = length(stack.rotors)
    tilts = [r.tilt_deg for r in stack.rotors]  # start from current

    for _ in 1:10
        improved = false

        for i in 1:n
            best_tilt = tilts[i]
            best_T = -Inf

            for t in tilt_candidates
                trial_tilts = copy(tilts)
                trial_tilts[i] = t

                trial_rotors = [AutogyroRotor(
                    stack.rotors[j].radius, stack.rotors[j].hub_radius,
                    stack.rotors[j].n_blades, stack.rotors[j].blade_chord,
                    trial_tilts[j], stack.rotors[j].blade_pitch_deg,
                    stack.rotors[j].mass) for j in 1:n]

                trial_stack = AutogyroStack(
                    trial_rotors, stack.section_lengths,
                    stack.line_diameter, stack.line_angle_deg,
                    line_density=stack.line_density)

                profile = stack_tension_profile_polygon(trial_stack, rho, v_wind)
                T_anchor = profile[end]

                if T_anchor > best_T
                    best_T = T_anchor
                    best_tilt = t
                end
            end

            if best_tilt != tilts[i]
                tilts[i] = best_tilt
                improved = true
            end
        end

        if !improved
            break
        end
    end

    # Final evaluation
    final_rotors = [AutogyroRotor(
        stack.rotors[j].radius, stack.rotors[j].hub_radius,
        stack.rotors[j].n_blades, stack.rotors[j].blade_chord,
        tilts[j], stack.rotors[j].blade_pitch_deg,
        stack.rotors[j].mass) for j in 1:n]
    final_stack = AutogyroStack(
        final_rotors, stack.section_lengths,
        stack.line_diameter, stack.line_angle_deg,
        line_density=stack.line_density)
    profile = stack_tension_profile_polygon(final_stack, rho, v_wind)

    return tilts, profile[end]
end

export optimal_rotor_tilts_bem
