# src/viability.jl - Physical viability checks for a rotor stack (Phase 8.5)

"""
    viability_report(stack::AutogyroStack, rho, v_wind;
                     reynolds_min=5.0e5, tip_speed_limit=120.0)
        -> (reynolds_ok, noise_ok, line_weight_fraction, warnings)

Single entry point for physical viability checks on a rotor stack at a given
flow state.

Applies the worst-case-across-stack rule. Hazards use the worst offender:
maximum tip speed (the loudest rotor sets the noise verdict). Validity uses
the weakest link: minimum tip Reynolds (the least trustworthy rotor
invalidates the whole prediction). On graded-tilt stacks these can be
different rotors.

# Arguments
- `stack::AutogyroStack`: the rotor stack.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `reynolds_min`: tip Reynolds floor for PCA-2 data trust (default 5×10⁵).
- `tip_speed_limit`: blade tip speed noise limit in m/s (default 120, ~Mach 0.35).

# Returns
A named tuple:
- `reynolds_ok::Bool`: minimum tip Re across the stack ≥ `reynolds_min`.
- `noise_ok::Bool`: maximum tip speed across the stack ≤ `tip_speed_limit`.
- `line_weight_fraction::Float64`: total line self-weight force along the line
  divided by total rotor lift along the line. This is the share of rotor lift
  that goes to lifting the rope. `Inf` at zero wind (zero lift).
- `warnings::Vector{String}`: one message per failed gate, with the offending
  numbers; empty when fully viable.

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.05, 4, 0.15, 10.0, 0.0, 5.0);

julia> stack = AutogyroStack([r, r, r], [3.0, 3.0, 9.0], 0.004, 50.0);

julia> rep = viability_report(stack, 1.225, 8.0);

julia> (rep.reynolds_ok, rep.noise_ok)
(false, true)
```
"""
function viability_report(stack::AutogyroStack, rho, v_wind;
                          reynolds_min=5.0e5, tip_speed_limit=120.0)
    # Worst-case-across-stack rule: the least trustworthy rotor (minimum tip
    # Reynolds) decides whether the PCA-2 prediction is valid.
    re_min = minimum(
        rotor_reynolds_number(r, rho, v_wind, effective_alpha(r, stack.line_angle_deg))
        for r in stack.rotors)

    # Worst-case-across-stack rule: the loudest rotor (maximum tip speed)
    # sets the noise verdict. On graded-tilt stacks this can differ from
    # the min-Reynolds rotor.
    v_tip_max = maximum(
        rotor_tip_speed(r, v_wind, effective_alpha(r, stack.line_angle_deg))
        for r in stack.rotors)

    # Line self-weight force along the line as a fraction of total rotor
    # lift along the line. This measures how much rotor effort goes to
    # lifting the rope. At zero wind the rotors produce nothing. The
    # fraction is Inf (line weight dominates zero lift).
    mass_per_m = line_mass_per_m(stack.line_diameter, stack.line_density)
    total_line_weight = sum(
        line_weight_along_line(mass_per_m, L, 9.81, stack.line_angle_deg)
        for L in stack.section_lengths)
    total_rotor_lift = sum(
        first(rotor_force_along_line(r, rho, v_wind, stack.line_angle_deg))
        for r in stack.rotors)
    line_weight_fraction = total_line_weight / total_rotor_lift

    warnings = String[]
    if re_min < reynolds_min
        push!(warnings, "min tip Reynolds $(round(re_min, sigdigits=3)) below " *
                        "$(round(reynolds_min, sigdigits=3)). PCA-2 data " *
                        "untrustworthy at this scale")
    end
    if v_tip_max > tip_speed_limit
        push!(warnings, "max blade tip speed $(round(v_tip_max, digits=1)) m/s " *
                        "exceeds $(tip_speed_limit) m/s noise limit")
    end

    return (reynolds_ok          = re_min >= reynolds_min,
            noise_ok             = v_tip_max <= tip_speed_limit,
            line_weight_fraction = line_weight_fraction,
            warnings             = warnings)
end
