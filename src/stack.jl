# src/stack.jl - Multi-rotor stack and tension profile computation

"""
    AutogyroStack(rotors, section_lengths, line_diameter, line_angle_deg; line_density=970.0)

Multiple autogyro rotors stacked coaxially on a single kite line, each with
independent pitch. Immutable.

The topmost rotor (index 1) is a lifting autogyro kite. It **terminates**
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
- `line_density::Float64`: line material density (kg/m³). Defaults to 970
  (Dyneema SK75). Used for computing line self-weight in the tension profile.
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
    line_density     :: Float64
    line_angle_deg   :: Float64

    function AutogyroStack(rotors, section_lengths, line_diameter, line_angle_deg;
                           line_density=970.0)
        @assert length(section_lengths) == length(rotors)
        new(rotors, section_lengths, line_diameter, line_density, line_angle_deg)
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
  topmost rotor (approximately zero, nothing pulls from above). `profile[end]`
  is the anchor tension (maximum). Monotonically non-decreasing downward when
  each rotor's net force is positive.

# Physics
At each rotor the net along-line force is `F_line − W·cosθ` (positive means the
rotor pulls the line taut, adding tension below it); bare-line section drag and
line self-weight add further tension.

# Examples
```jldoctest
julia> r = AutogyroRotor(1.5, 0.1, 2, 0.15, 10.0, 5.0);

julia> stack = AutogyroStack([r, r, r], fill(10.0, 3), 0.004, 50.0);

julia> round.(stack_tension_profile(stack, 1.225, 8.0), digits=1)
4-element Vector{Float64}:
   0.0
 296.5
 593.0
 889.5
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
        F_drag_section = bare_line_drag(rho, v_wind, stack.line_diameter, section_len, stack.line_angle_deg)

        # Rotor at position k-1 contributes its net line force
        rotor = stack.rotors[k-1]
        F_line, _, _, _, _ = rotor_force_along_line(rotor, rho, v_wind, stack.line_angle_deg)
        W_cos = rotor.mass * 9.81 * cosd(stack.line_angle_deg)

        # Rope cannot push. Tension cannot go negative. When a rotor's net
        # along-line force points downward (F_line < W_cos), the section
        # above it goes slack. Tension at this position is zero. The rotor
        # hangs (or sits on the ground). It does not add to the tension below.
        #
        # Line self-weight (from line_mass_per_m plus line_weight_along_line)
        # always adds to tension when the section is taut. The stack must
        # lift the rotors and the Dyneema line.
        mass_per_m = line_mass_per_m(stack.line_diameter, stack.line_density)
        F_line_weight = line_weight_along_line(
            mass_per_m, section_len, 9.81, stack.line_angle_deg)

        delta = F_drag_section + (F_line - W_cos) + F_line_weight
        profile[k] = max(0.0, profile[k-1] + delta)
    end

    return profile
end

# --- Phase 10c Task 8-9: Polygon-line tension profile ---

"""
    stack_tension_profile_polygon(stack::AutogyroStack, rho, v_wind) -> Vector{Float64}

Tension profile using polygon line geometry. Unlike the v1 straight-line model,
each rotor sees its own segment angle. Force equilibrium determines the angle
([`solve_polygon_angles`](@ref)). This enables graded stacking. A top-rotor
tilt reshapes the line for rotors below.

Accumulates tension top→bottom using polygon segment angles, including
bare-line drag and line self-weight along each segment.

# Returns
- `Vector{Float64}` with `n_rotors + 1` entries (N).
"""
function stack_tension_profile_polygon(stack::AutogyroStack, rho, v_wind)
    # Solve segment angles from force equilibrium
    θ, _, _ = solve_polygon_angles(
        stack.rotors, stack.section_lengths, stack.line_angle_deg, rho, v_wind)

    n = length(stack.rotors)
    profile = zeros(Float64, n + 1)
    # profile[1] = 0 (above top rotor)

    for i in 1:n
        rotor = stack.rotors[i]
        seg_angle = θ[i]
        seg_len = stack.section_lengths[i]

        # BEM force at this segment's angle
        F_line, _, _ = rotor_force_bem(rotor, rho, v_wind, seg_angle)
        W_cos = rotor.mass * 9.81 * cosd(seg_angle)

        # Section drag and line weight along this segment
        F_drag_section = bare_line_drag(rho, v_wind, stack.line_diameter, seg_len, seg_angle)

        mass_per_m = line_mass_per_m(stack.line_diameter, stack.line_density)
        F_line_weight = line_weight_along_line(mass_per_m, seg_len, 9.81, seg_angle)

        delta = F_drag_section + (F_line - W_cos) + F_line_weight
        profile[i+1] = max(0.0, profile[i] + delta)
    end

    return profile
end

export stack_tension_profile_polygon
