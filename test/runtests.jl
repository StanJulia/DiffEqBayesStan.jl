using SafeTestsets
const LONGER_TESTS = false

@time @safetestset "Stan_String" begin include("test_stan_string.jl") end
@time @safetestset "Stan" begin include("test_one_parameter_stan.jl") end
@time @safetestset "Stan" begin include("test_four_parameter_stan.jl") end

@time @safetestset "SampleModel LV" begin include("test_lv_samplemodel.jl") end
@time @safetestset "SampleModel FN" begin include("test_fn_samplemodel.jl") end
