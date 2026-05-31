# src/stack.jl — Multi-rotor stack and tension profile computation

"""
    AutogyroStack

Multiple autogyro rotors stacked coaxially on a single kite line,
with independent pitch per rotor.

Fields:
- `rotors`           : Vector of AutogyroRotor, ordered top→bottom (1 = topmost)
- `section_lengths`  : Line segment lengths in m, n_rotors + 1 entries.
                       section_lengths[1] is above the topmost rotor (free end),
                       section_lengths[end] is below the bottom rotor (to anchor).
- `line_diameter`    : Line diameter (m)
- `line_angle_deg`   : Base line elevation angle (degrees)
"""
struct AutogyroStack
    rotors           :: Vector{AutogyroRotor}
    section_lengths  :: Vector{Float64}
    line_diameter    :: Float64
    line_angle_deg   :: Float64

    function AutogyroStack(rotors, section_lengths, line_diameter, line_angle_deg)
        @assert length(section_lengths) == length(rotors) + 1
        new(rotors, section_lengths, line_diameter, line_angle_deg)
    end
end

"""
    stack_tension_profile(stack::AutogyroStack, rho, v_wind) → Vector{Float64}

Computes the tension at each position along the line, starting from the free
end (top) and accumulating downward toward the anchor.

Returns n_rotors + 1 entries:
- profile[1]   = above topmost rotor (free end, ≈ 0)
- profile[end] = at anchor (maximum tension)

Physics: at each rotor, the net force along the line is
(F_line − W·cosθ), where positive means the rotor pulls the line upward
(adding tension below it). Line section drag also adds to tension.
"""
function stack_tension_profile(stack::AutogyroStack, rho, v_wind)
    profile = zeros(Float64, length(stack.rotors) + 1)
    # profile[1] = above topmost rotor = free end ≈ 0

    for k in 2:length(profile)
        # Section between rotor k-2 and rotor k-1 (or free-end section for k=2)
        section_len = stack.section_lengths[k]
        F_drag_section = bare_line_drag(rho, v_wind, stack.line_diameter, section_len)

        # Rotor at position k-1 contributes its net line force
        if k > 1
            rotor = stack.rotors[k-1]
            F_line, _, _, _, _ = rotor_force_along_line(rotor, rho, v_wind, stack.line_angle_deg)
            W_cos = rotor.mass * 9.81 * cosd(stack.line_angle_deg)
            profile[k] = profile[k-1] + F_drag_section + (F_line - W_cos)
        end
    end

    return profile
end
