# src/stack.jl — Multi-rotor stack and tension profile computation

"""
    AutogyroStack(rotors, section_lengths, line_diameter, line_angle_deg)

Multiple autogyro rotors stacked coaxially on a single kite line, each with
independent pitch. Immutable.

The topmost rotor (index 1) is a lifting autogyro kite — it **terminates**
the line. There is no section above it; `section_lengths` has exactly
`length(rotors)` entries for the sections between rotors and below the
bottom rotor to the anchor.

The constructor asserts `length(section_lengths) == length(rotors)`.

# Fields
- `rotors::Vector{AutogyroRotor}`: rotors ordered **top → bottom** (index 1 is
  the topmost, which terminates the line).
- `section_lengths::Vector{Float64}`: line segment lengths (m), `n_rotors`
  entries. `section_lengths[1]` is between rotor 1 and rotor 2;
  `section_lengths[end]` is below the bottom rotor down to the anchor.
- `line_diameter::Float64`: line diameter (m).
- `line_angle_deg::Float64`: base line elevation angle (degrees).

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 3), 0.004, 50.0);

julia> length(stack.section_lengths) == length(stack.rotors)
true
```
"""
struct AutogyroStack
    rotors           :: Vector{AutogyroRotor}
    section_lengths  :: Vector{Float64}
    line_diameter    :: Float64
    line_angle_deg   :: Float64

    function AutogyroStack(rotors, section_lengths, line_diameter, line_angle_deg)
        @assert length(section_lengths) == length(rotors)
        new(rotors, section_lengths, line_diameter, line_angle_deg)
    end
end

"""
    stack_tension_profile(stack::AutogyroStack, rho, v_wind) -> Vector{Float64}

Line tension at each position, accumulated from the topmost rotor (which
terminates the line) downward to the anchor.

# Arguments
- `stack::AutogyroStack`: the rotor stack.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).

# Returns
- `Vector{Float64}` with `n_rotors + 1` entries (N). `profile[1]` is at the
  topmost rotor (≈ 0 — nothing pulls from above); `profile[end]` is the
  anchor tension (maximum).  Monotonically non-decreasing downward whenever
  each rotor's net force is positive.

# Physics
At each rotor the net along-line force is `F_line − W·cosθ` (positive means the
rotor pulls the line taut, adding tension below it); bare-line section drag adds
further tension.

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 3), 0.004, 50.0);

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
    # profile[1] = at topmost rotor = 0 (nothing pulls from above)

    for k in 2:length(profile)
        # Section drag: the section between rotor k-2 and rotor k-1
        # (for k=2 this is the section below the top rotor, toward rotor 2;
        #  for k=end this is the section below the bottom rotor, to the anchor)
        section_len = stack.section_lengths[k-1]
        F_drag_section = bare_line_drag(rho, v_wind, stack.line_diameter, section_len)

        # Rotor at position k-1 contributes its net line force
        rotor = stack.rotors[k-1]
        F_line, _, _, _, _ = rotor_force_along_line(rotor, rho, v_wind, stack.line_angle_deg)
        W_cos = rotor.mass * 9.81 * cosd(stack.line_angle_deg)

        # Rope cannot push — tension cannot go negative.  When a rotor's net
        # along-line force is downward (F_line < W_cos), the segment above it
        # goes slack and tension at this position is zero.  The rotor hangs (or
        # sits on the ground) and does not add to the tension below.
        delta = F_drag_section + (F_line - W_cos)
        profile[k] = max(0.0, profile[k-1] + delta)
    end

    return profile
end
