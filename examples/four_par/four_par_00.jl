using StanSample, DiffEqBayesStan, MCMCChains
using OrdinaryDiffEq
using ParameterizedFunctions
using RecursiveArrayTools
using Distributions
using StatsPlots

ProjDir = @__DIR__

println("Four parameter case")

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
randomized = VectorOfArray([(sol(t[i]) + .3randn(2)) for i in 1:length(t)])
data_array = convert(Array, randomized)

priors = [truncated(Normal(1.5,0.1),0.5,2),truncated(Normal(1.0,0.1),0.5,1.5),
          truncated(Normal(3.0,0.1),0.5,4),truncated(Normal(1.0,0.1),0.5,2)]

bayesian_result = stan_inference(prob1, t, data_array, priors;
  nchains=[4], num_samples=1000, num_warmup=1000,
  vars =(DiffEqBayesStan.StanODEData(), InverseGamma(4,1)),
  output_format=:dataframe)

if success(bayesian_result.return_code)
  df = bayesian_result.chains
  
  println("\ntheta means:\n",
    [mean(df.theta_1), mean(df.theta_2), mean(df.theta_3), mean(df.theta_4)])
  println("\ntheta vars:\n",
    [var(df.theta_1), var(df.theta_2), var(df.theta_3), var(df.theta_4)])
  println()

  dfs = read_samples(bayesian_result.model; output_format=:dataframes)
  for j in 1:4
    for i in 1:4
      if i == 1
        plot(dfs[i][:, "theta_$j"], lab="chain[$j]")
      else
        plot!(dfs[i][:, "theta_$j"], lab="chain[$j]")
      end
    end
    savefig(joinpath(ProjDir, "tmp", "theta_$j.png"))
  end

  sdf = read_summary(bayesian_result.model)
  sdf |> display
  println("\n")

end

