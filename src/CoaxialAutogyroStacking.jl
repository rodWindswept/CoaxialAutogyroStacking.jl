module CoaxialAutogyroStacking

# CoaxialAutogyroStacking.jl — Multiple independently-pitched autogyro rotors
# stacked inline on a kite line, computing forces and tension profiles.
#
# Phase 1–7: PCA-2 empirical data, rotor model, line drag, stack, optimisation
# Phase 8:   Parameter sweep + Pareto-front analysis

include("pca2_data.jl")
include("rotor.jl")
include("line_section.jl")
include("stack.jl")
include("optimisation.jl")
include("sweep.jl")

export pca2_interp
export AutogyroRotor, rotor_disk_area, effective_alpha, rotor_force_along_line
export bare_line_drag
export AutogyroStack, stack_tension_profile
export optimal_pitch, optimal_pitches, lift_force_steady
export parameter_sweep, compute_figures_of_merit, pareto_front
export uniform_tilt, top_draggy_tilt, bottom_lifty_tilt, graded_tilt

end # module CoaxialAutogyroStacking
