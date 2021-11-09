"""
$(DocStringExtensions.README)
"""
module DiffEqBayesStan

    using DocStringExtensions
    using DiffEqBase, Distributions, MacroTools
    using RecursiveArrayTools, ModelingToolkit
    using Parameters, Distributions, Optim, Requires
    using Distances, DocStringExtensions, Random
    using StanSample

    STANDARD_PROB_GENERATOR(prob,p) = remake(prob;u0=eltype(p).(prob.u0),p=p)
    STANDARD_PROB_GENERATOR(prob::EnsembleProblem,p) = EnsembleProblem(remake(prob.prob;u0=eltype(p).(prob.prob.u0),p=p))

    include("stan_string.jl")
    include("stan_inference.jl")

    export stan_inference
    
end # module
