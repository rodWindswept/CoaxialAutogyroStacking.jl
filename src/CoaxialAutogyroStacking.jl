module CoaxialAutogyroStacking

# CoaxialAutogyroStacking.jl — Multiple independently-pitched autogyro rotors
# stacked inline on a kite line, computing forces and tension profiles.
#
# Phase 1: PCA-2 empirical data + project skeleton

include("pca2_data.jl")
include("rotor.jl")

export pca2_interp
export AutogyroRotor, rotor_disk_area

end # module CoaxialAutogyroStacking
