module CoaxialAutogyroStacking

# CoaxialAutogyroStacking.jl — Multiple independently-pitched autogyro rotors
# stacked inline on a kite line, computing forces and tension profiles.
#
# Phase 1–8:   PCA-2 empirical data, rotor model, line drag, stack, optimisation, sweep
# Phase 8.5:   Viability gates (line weight, noise, Reynolds)
# Phase 9:     Mechanical design specification (OpenSCAD, PRD, dimensions)
# Phase 10:    BEM autorotation + polygon line geometry + Snel stall delay (v2.1)

include("pca2_data.jl")
include("airfoil_data.jl")
include("rotor.jl")
include("bem.jl")
include("polygon_line.jl")
include("line_section.jl")
include("stack.jl")
include("optimisation.jl")
include("sweep.jl")
include("viability.jl")
include("stall_delay.jl")

export pca2_interp
export naca0012_cl, naca0012_cd
export AutogyroRotor, rotor_disk_area, rotor_solidity, effective_alpha, rotor_force_along_line, estimated_autorotation_rpm, rotor_tip_speed, rotor_reynolds_number
export bare_line_drag, line_mass_per_m, line_weight_along_line
export AutogyroStack, stack_tension_profile
export optimal_rotor_tilt, optimal_rotor_tilts, lift_force_steady
export parameter_sweep, compute_figures_of_merit, pareto_front
export uniform_tilt, top_draggy_tilt, bottom_lifty_tilt, graded_tilt
export viability_report
export snel_cl_3d

end # module CoaxialAutogyroStacking
