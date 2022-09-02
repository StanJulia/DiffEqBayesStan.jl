using DiffEqBayesStan, OrdinaryDiffEq, ParameterizedFunctions,
      RecursiveArrayTools, Distributions, MCMCChains, Test


println("One parameter case")

ProjDir = @__DIR__
tmpdir = joinpath(ProjDir, "tmp")
#isdir(joinpath(ProjDir, "tmp")) && rm(tmpdir; recursive=true)


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
data = convert(Array,randomized)
priors = [truncated(Normal(1.5,0.1),1.0,1.8)]

br1 = stan_inference(prob1,t,data,priors;
  likelihood=Normal,
  tmpdir)

@test mean(get(br1.chains,:theta_1)[1]) ≈ 1.5 atol=3e-1

br2 = stan_inference(prob1,t,data,priors;
  #num_threads=8,
  use_cpp_chains=false,
  #num_chains=4,
  likelihood=Normal,
  tmpdir)

@test mean(get(br2.chains,:theta_1)[1]) ≈ 1.5 atol=3e-1
