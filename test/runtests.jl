using Test
using CoaxialAutogyroStacking

@testset "CoaxialAutogyroStacking" begin
    include("test_pca2_data.jl")
    include("test_airfoil_data.jl")
    include("test_bem.jl")
    include("test_polygon_line.jl")
    include("test_rotor.jl")
    include("test_line_section.jl")
    include("test_stack.jl")
    include("test_optimisation.jl")
    include("test_sweep.jl")
    include("test_viability.jl")
    include("test_stall_delay.jl")
    include("test_wake.jl")
end
