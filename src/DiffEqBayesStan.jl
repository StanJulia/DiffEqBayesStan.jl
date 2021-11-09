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

    """

    # debs_path

    Relative path using the StatisticalRethinking src/ directory.

    ### Example to get access to the data subdirectory
    ```julia
    debs_path("..", "data")
    ```

    Note that in the projects, e.g. StatisticalRethinkingStan.jl and StatisticalRethinkingTuring.jl, the
    DrWatson approach is a better choics, i.e: `sr_datadir(filename)`

    """
    debs_path(parts...) = normpath(joinpath(src_path, parts...))

    # DrWatson extension
    """

    # debs_datadir

    Relative path using the StatisticalRethinking src/ directory.

    ### Example to access `Howell1.csv` in StatisticalRethinking:
    ```julia
    df = CSV.read(sr_datadir("Howell1.csv"), DataFrame)
    ```
    """
    debs_datadir(parts...) = debs_path("..", "data", parts...)


    export
        stan_inference,
        debs_path,
        debs_datadir
    
end # module
