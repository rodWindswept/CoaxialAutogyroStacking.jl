# src/line_section.jl — Bare line drag model

"""
    bare_line_drag(rho, v_wind, diameter, length) -> Float64

Drag force (N) on a bare cylindrical line section in crossflow:

    F_drag = ½·ρ·v² · (diameter·length) · CD_cylinder

Uses `CD_cylinder = 1.2` for a smooth circular cylinder in subcritical crossflow
(typical for Dyneema lines at operating Reynolds numbers). The line contributes
drag but no lift, so its L/D ≈ 0 — the contrast that motivates the rotors.

# Arguments
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `diameter`: line diameter (m).
- `length`: section length (m).

# Examples
```jldoctest
julia> round(bare_line_drag(1.225, 8.0, 0.004, 10.0), digits=2)
1.88
```
"""
function bare_line_drag(rho, v_wind, diameter, length)
    CD = 1.2
    q = 0.5 * rho * v_wind^2
    A_projected = diameter * length
    return q * A_projected * CD
end
