# title: Fitzhugh-Nagumo Bayesian Parameter Estimation Benchmarks
# author: Vaibhav Dixit, Chris Rackauckas

ProjDir = @__DIR__
using DiffEqBayesStan, BenchmarkTools, MCMCChains
using Tables, AxisKeys

using OrdinaryDiffEq, RecursiveArrayTools, Distributions
using ParameterizedFunctions, StanSample
using Plots
gr(fmt=:png)

### Defining the problem

# The [FitzHugh-Nagumo model](https://en.wikipedia.org/wiki/FitzHugh%E2%80%93Nagumo_model) is a simplified version of [Hodgkin-Huxley model](https://en.wikipedia.org/wiki/Hodgkin%E2%80%93Huxley_model) and is used to describe an excitable system (e.g. neuron).

fitz = @ode_def FitzhughNagumo begin
  dv = v - v^3/3 -w + l
  dw = τinv*(v +  a - b*w)
end a b τinv l

prob_ode_fitzhughnagumo = ODEProblem(fitz,[1.0,1.0],(0.0,10.0),[0.7,0.8,1/12.5,0.5])
sol = solve(prob_ode_fitzhughnagumo, Tsit5())

# Data is genereated by adding noise to the solution obtained above.

t = collect(range(1,stop=10,length=10))
sig = 0.20
data = convert(Array, VectorOfArray([(sol(t[i]) + sig*randn(2)) for i in 1:length(t)]))


### Plot of the data and the solution.

scatter(t, data[1,:])
scatter!(t, data[2,:])
plot!(sol)

### Priors for the parameters which will be passed for the Bayesian Inference

priors = [
  truncated(Normal(1.0,0.5),0,1.5),truncated(Normal(1.0,0.5),0,1.5),
  truncated(Normal(0.0,0.5),0.0,0.5),truncated(Normal(0.5,0.5),0,1)
]

### Benchmarks

#### Stan.jl backend

tmpdir = joinpath(ProjDir, "tmp")

diffeq_string = "
  vector sho(
    real t,vector internal_var___u, 
    real internal_var___p_1, real internal_var___p_2, 
    real internal_var___p_3, real internal_var___p_4) {

  vector[2] internal_var___du;

  internal_var___du[1] = internal_var___p_4 - 0.3333 * internal_var___u[1] ^ 3 + -1 * internal_var___u[2] + internal_var___u[1];
  internal_var___du[2] = internal_var___p_3 * (internal_var___p_1 + -1 * internal_var___p_2 * internal_var___u[2] + internal_var___u[1]);

  return internal_var___du;
}
"

@btime bayesian_result_stan = 
  stan_inference(prob_ode_fitzhughnagumo,t,data,priors;
    num_samples = 2500, output_format = :dataframe,
    diffeq_string, tmpdir)

bayesian_result_stan = 
  stan_inference(prob_ode_fitzhughnagumo,t,data,priors;
    num_samples = 2500, output_format = :dataframe,
    diffeq_string, tmpdir)

describe(bayesian_result_stan.chains)

