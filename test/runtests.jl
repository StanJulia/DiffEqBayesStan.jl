using SafeTestsets
const LONGER_TESTS = false

@time @safetestset "Stan_String" begin include("test_stan_string.jl") end
@time @safetestset "Stan" begin include("test_one_parameter_stan.jl") end
@time @safetestset "Stan" begin include("test_four_parameter_stan.jl") end
