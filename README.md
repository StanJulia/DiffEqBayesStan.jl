# DiffEqBayesStan.jl

[![Build Status](https://github.com/StanJulia/DiffEqBayesStan.jl/workflows/CI/badge.svg)](https://github.com/StanJulia/DiffEqBayesStan.jl/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/StanJulia/DiffEqBayesStan.jl/badge.svg?branch=master)](https://coveralls.io/github/StanJulia/DiffEqBayesStan.jl?branch=master)
[![codecov.io](http://codecov.io/github/StanJulia/DiffEqBayesStan.jl/coverage.svg?branch=master)](http://codecov.io/github/StanJulia/DiffEqBayesStan.jl?branch=master)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](http://diffeqbayes.sciml.ai/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](http://diffeqbayes.sciml.ai/dev/)

This repository is a set of extension functionality for estimating the parameters of differential equations using Stan-based Bayesian methods as available in [StanSample.jl](https://github.com/StanJulia/StanSample.jl) to perform a Bayesian estimation of a differential equation problem specified via the [DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl) interface.

This repository is a direct simplification of [DiffEqBayes.jl](). While DiffEqBayes provides and shows how to run the same problem on multiple mcmc implementations available in Julia, this packages only supports Stan.

To begin you first need to add this repository using the following command:

```julia
Pkg.add("DiffEqBayesStan")
using DiffEqBayesStan
```

## Tutorials and Documentation

For information on using the package,
[see the stable documentation](https://diffeqbayes.sciml.ai/stable/). Use the
[in-development documentation](https://diffeqbayes.sciml.ai/dev/) for the version of
the documentation, which contains the unreleased features.

## Example

 ```julia
 using ParameterizedFunctions, OrdinaryDiffEq, RecursiveArrayTools, Distributions
 f1 = @ode_def LotkaVolterra begin
  dx = a*x - x*y
  dy = -3*y + x*y
 end a

 p = [1.5]
 u0 = [1.0,1.0]
 tspan = (0.0,10.0)
 prob1 = ODEProblem(f1,u0,tspan,p)

 σ = 0.01                         # noise, fixed for now
 t = collect(1.:10.)   # observation times
 sol = solve(prob1,Tsit5())
 priors = [Normal(1.5, 1)]
 randomized = VectorOfArray([(sol(t[i]) + σ * randn(2)) for i in 1:length(t)])
 data = convert(Array,randomized)
 
 using StanSample #required for using the Stan backend
 bayesian_result_stan = stan_inference(prob1,t,data,priors)

```
### Using save_idxs to declare observables

You don't always have data for all of the variables of the model. In case of certain latent variables
you can utilise the `save_idxs` kwarg to declare the oberved variables and run the inference using any 
of the backends as shown below.

```julia
 sol = solve(prob1,Tsit5(),save_idxs=[1])
 randomized = VectorOfArray([(sol(t[i]) + σ * randn(1)) for i in 1:length(t)])
 data = convert(Array,randomized)

 using CmdStan #required for using the Stan backend
 bayesian_result_stan = stan_inference(prob1,t,data,priors,save_idxs=[1])

 bayesian_result_turing = turing_inference(prob1,Tsit5(),t,data,priors,save_idxs=[1])
 
 using DynamicHMC #required for DynamicHMC backend
 bayesian_result_hmc = dynamichmc_inference(prob1,Tsit5(),t,data,priors,save_idxs = [1])

 bayesian_result_abc = abc_inference(prob1,Tsit5(),t,data,priors,save_idxs=[1])
 ```
