using DiffEqBayesStan, OrdinaryDiffEq, ParameterizedFunctions,
      RecursiveArrayTools, Distributions, StanSample, Test

println("\nDiffEqBayes based LV SampleModel test")

ProjDir = @__DIR__
tmpdir = joinpath(ProjDir, "tmp")
isdir(joinpath(ProjDir, "tmp")) && rm(tmpdir; recursive=true)

#include(joinpath(ProjDir, "stan_inference_model.jl"))

f1 = @ode_def begin
  dx = a*x - x*y
  dy = -3y + x*y
end a
u0 = [1.0,1.0]
tspan = (0.0,10.0)
p = [1.5]
prob1 = ODEProblem(f1,u0,tspan,p)
sol = solve(prob1,Tsit5())
t = collect(range(1,stop=10,length=50))
randomized = VectorOfArray([(sol(t[i]) + .01randn(2)) for i in 1:length(t)])
deb_data = convert(Array, randomized)
priors = [truncated(Normal(1.5,0.1),1.0,1.8)]

println("\nCompile Stan model\n")
@time lv_sm, data = SampleModel("LV", prob1, t, deb_data, priors;
  likelihood=Normal, tmpdir)

println("\nStart sampling\n")
@time rc = stan_sample(lv_sm; data, 
    use_cpp_chains=true,
    num_samples=1000,
    num_warmups=1000, 
    num_chains=4, 
    num_threads=8
)

println("\nStart sampling (second time)\n")
@time rc = stan_sample(lv_sm; data, 
    use_cpp_chains=true,
    num_samples=1000,
    num_warmups=1000, 
    num_chains=4, 
    num_threads=8
)

if success(rc)
  lv_df = read_summary(lv_sm)
end

lv_df[8:end, [1, 2, 3, 4, 8, 9, 10]] |> display
println()
