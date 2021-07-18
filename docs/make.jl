using Documenter, DiffEqBayesStan

makedocs(
    modules = [DiffEqBayesStan],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "DiffEqBayesStan.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/StanJulia/DiffEqBayesStan.jl.git",
)
