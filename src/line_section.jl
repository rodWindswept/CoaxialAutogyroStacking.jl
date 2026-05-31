# src/line_section.jl — Bare line drag model

"""
    bare_line_drag(rho, v_wind, diameter, length)

Drag force on a bare cylindrical line section in crossflow.

F_drag = ½·ρ·v² · (diameter·length) · CD_cylinder

Uses CD_cylinder = 1.2 for a smooth circular cylinder in subcritical
crossflow (typical for Dyneema lines at operating Reynolds numbers).
"""
function bare_line_drag(rho, v_wind, diameter, length)
    CD = 1.2
    q = 0.5 * rho * v_wind^2
    A_projected = diameter * length
    return q * A_projected * CD
end
