using DiffEqBayesStan, OrdinaryDiffEq, ParameterizedFunctions,
      RecursiveArrayTools, Distributions, MCMCChains, Test

println("\n\nFour parameter case\n")

f1 = @ode_def begin
    dx = a*x - b*x*y
    dy = -c*y + d*x*y
end a b c d

u0 = [1.0,1.0]
tspan = (0.0,10.0)
p = [1.5,1.0,3.0,1.0]
prob1 = ODEProblem(f1,u0,tspan,p)
sol = solve(prob1,Tsit5())

t = collect(range(1,stop=10,length=50))
randomized = VectorOfArray([(sol(t[i]) + .01randn(2)) for i in 1:length(t)])
data = convert(Array,randomized)
priors = [truncated(Normal(1.5,0.01),0.5,2),truncated(Normal(1.0,0.01),0.5,1.5),
          truncated(Normal(3.0,0.01),0.5,4),truncated(Normal(1.0,0.01),0.5,2)]

bayesian_result = stan_inference(prob1,t,data,priors;
    num_chains=4,num_samples=1000,num_warmup=1000,
    vars =(DiffEqBayesStan.StanODEData(),InverseGamma(4,1)))

@test mean(get(bayesian_result.chains,:theta_1)[1]) ≈ 1.5 atol=1e-1
@test mean(get(bayesian_result.chains,:theta_2)[1]) ≈ 1.0 atol=1e-1
@test mean(get(bayesian_result.chains,:theta_3)[1]) ≈ 3.0 atol=1e-1
@test mean(get(bayesian_result.chains,:theta_4)[1]) ≈ 1.0 atol=1e-1
