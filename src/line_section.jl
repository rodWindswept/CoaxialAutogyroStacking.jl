# src/line_section.jl — Bare line drag model

"""
    bare_line_drag(rho, v_wind, diameter, length, line_angle_deg) -> Float64

Drag force (N) on a bare cylindrical line section in crossflow.

The crossflow velocity component perpendicular to the line is
`v_wind × cos(line_elevation)`, giving dynamic pressure
`½ρ(v_wind × cos φ)²`. At φ > 0°, this is always less than the full
freestream dynamic pressure — a line at 50° elevation sees only ~41% of
the naive drag estimate.

Uses `CD_cylinder = 1.2` for a smooth circular cylinder in subcritical
crossflow (typical for Dyneema lines at operating Reynolds numbers).

# Arguments
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `diameter`: line diameter (m).
- `length`: section length (m).
- `line_angle_deg`: line elevation above horizontal (degrees).

# Examples
```jldoctest
julia> round(bare_line_drag(1.225, 8.0, 0.004, 10.0, 50.0), digits=2)
0.78

julia> bare_line_drag(1.225, 8.0, 0.004, 10.0, 0.0)  # horizontal → full crossflow
1.88
```
"""
function bare_line_drag(rho, v_wind, diameter, length, line_angle_deg)
    CD = 1.2
    v_cross = v_wind * cosd(line_angle_deg)
    q = 0.5 * rho * v_cross^2
    A_projected = diameter * length
    return q * A_projected * CD
end
