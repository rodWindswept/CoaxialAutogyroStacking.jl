# src/stack.jl — Multi-rotor stack and tension profile computation

"""
    AutogyroStack(rotors, section_lengths, line_diameter, line_angle_deg)

Multiple autogyro rotors stacked coaxially on a single kite line, each with
independent pitch. Immutable.

The constructor asserts `length(section_lengths) == length(rotors) + 1`.

# Fields
- `rotors::Vector{AutogyroRotor}`: rotors ordered **top → bottom** (index 1 is
  the topmost, nearest the free end).
- `section_lengths::Vector{Float64}`: line segment lengths (m), `n_rotors + 1`
  entries. `section_lengths[1]` is above the topmost rotor (free end);
  `section_lengths[end]` is below the bottom rotor (down to the anchor).
- `line_diameter::Float64`: line diameter (m).
- `line_angle_deg::Float64`: base line elevation angle (degrees).

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 4), 0.004, 50.0);

julia> length(stack.section_lengths) == length(stack.rotors) + 1
true
```
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
    stack_tension_profile(stack::AutogyroStack, rho, v_wind) -> Vector{Float64}

Line tension at each position, accumulated from the free end (top) downward to
the anchor.

# Arguments
- `stack::AutogyroStack`: the rotor stack.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).

# Returns
- `Vector{Float64}` with `n_rotors + 1` entries (N). `profile[1]` is above the
  topmost rotor (free end, ≈ 0); `profile[end]` is the anchor tension (maximum).
  Monotonically non-decreasing downward whenever each rotor's net force is
  positive.

# Physics
At each rotor the net along-line force is `F_line − W·cosθ` (positive means the
rotor pulls the line taut, adding tension below it); bare-line section drag adds
further tension.

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 4), 0.004, 50.0);

julia> round.(stack_tension_profile(stack, 1.225, 8.0), digits=1)
4-element Vector{Float64}:
   0.0
 297.6
 595.2
 892.7
```
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
