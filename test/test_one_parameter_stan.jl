using DiffEqBayesStan, OrdinaryDiffEq, ParameterizedFunctions,
      RecursiveArrayTools, Distributions, MCMCChains, Test


println("One parameter case")

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

bayesian_result = stan_inference(prob1,t,data,priors;num_samples=300,
                                 num_warmup=500,likelihood=Normal)

@test mean(get(bayesian_result.chains,:theta_1)[1]) ≈ 1.5 atol=3e-1

# Test no-recompile
bayesian_result2 = stan_inference(prob1,t,data,priors,bayesian_result.model;
                                  num_samples=300,num_warmup=500,likelihood=Normal)

@test mean(get(bayesian_result2.chains,:theta_1)[1]) ≈ 1.5 atol=3e-1

priors = [truncated(Normal(1.,0.01),0.5,2.0),truncated(Normal(1.,0.01),0.5,2.0),truncated(Normal(1.5,0.01),1.0,2.0)]
bayesian_result = stan_inference(prob1,t,data,priors;num_samples=300,
                                 num_warmup=500,likelihood=Normal,sample_u0=true)

@test mean(get(bayesian_result.chains,:theta_1)[1]) ≈ 1. atol=3e-1
@test mean(get(bayesian_result.chains,:theta_2)[1]) ≈ 1. atol=3e-1
@test mean(get(bayesian_result.chains,:theta_3)[1]) ≈ 1.5 atol=3e-1

sol = solve(prob1,Tsit5(),save_idxs=[1])
randomized = VectorOfArray([(sol(t[i]) + .01 * randn(1)) for i in 1:length(t)])
data = convert(Array,randomized)
priors = [truncated(Normal(1.5,0.1),0.5,2)]
bayesian_result = stan_inference(prob1,t,data,priors;num_samples=300,
                                 num_warmup=500,likelihood=Normal,save_idxs=[1])

@test mean(get(bayesian_result.chains,:theta_1)[1]) ≈ 1.5 atol=3e-1


priors = [truncated(Normal(1.,0.01),0.5,2),truncated(Normal(1.5,0.01),0.5,2)]
bayesian_result = stan_inference(prob1,t,data,priors;num_samples=300,
                                 num_warmup=500,likelihood=Normal,
                                 save_idxs=[1],sample_u0=true)

@test mean(get(bayesian_result.chains,:theta_1)[1]) ≈ 1. atol=3e-1
@test mean(get(bayesian_result.chains,:theta_2)[1]) ≈ 1.5 atol=3e-1
