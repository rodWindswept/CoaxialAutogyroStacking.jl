using Test
using CoaxialAutogyroStacking

@testset "CoaxialAutogyroStacking" begin
    include("test_pca2_data.jl")
    include("test_rotor.jl")
end
