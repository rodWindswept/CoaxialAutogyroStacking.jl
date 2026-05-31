module CoaxialAutogyroStacking

# CoaxialAutogyroStacking.jl — Multiple independently-pitched autogyro rotors
# stacked inline on a kite line, computing forces and tension profiles.
#
# Phase 1: PCA-2 empirical data + project skeleton

include("pca2_data.jl")
include("rotor.jl")
include("line_section.jl")
include("stack.jl")

export pca2_interp
export AutogyroRotor, rotor_disk_area, effective_alpha, rotor_force_along_line
export bare_line_drag
export AutogyroStack, stack_tension_profile

end # module CoaxialAutogyroStacking
