# src/optimisation.jl — Optimal pitch search for rotors and stacks

"""
    optimal_pitch(rotor::AutogyroRotor, rho, v_wind, elev_deg) → (pitch_opt, F_max)

Grid-search the blade pitch angle (from -30° to 30°) to find the pitch
that maximizes the force component along the kite line axis.

Returns (pitch_opt_deg, F_line_max_N).
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
    optimal_pitches(stack::AutogyroStack, rho, v_wind) → Vector{Float64}

Optimize pitch independently for each rotor in the stack.
Returns a vector of optimal pitch angles (degrees), one per rotor.
"""
function optimal_pitches(stack::AutogyroStack, rho, v_wind)
    return [optimal_pitch(r, rho, v_wind, stack.line_angle_deg)[1] for r in stack.rotors]
end
