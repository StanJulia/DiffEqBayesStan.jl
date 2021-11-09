using StanSample, DiffEqBayesStan, MCMCChains
using OrdinaryDiffEq
using ParameterizedFunctions
using RecursiveArrayTools
using Distributions
using StatsPlots

function SIR!(du,u,pars,t)
    β, γ = pars
    S, I, R = u

    dS = -β*S*I
    dI = β*S*I - γ*I
    dR = γ*I
    du .= [dS, dI, dR]
end

t_obs = collect(1.0:1.0:218)
prob = ODEProblem(SIR!, [0.99, 0.01, 0.0], (0.0, t_obs[end]), [0.20, 0.15])
sol = solve(prob, Tsit5(), reltol = 1e-6, abstol = 1e-6, saveat = t_obs)

begin
    y = DataFrame(sol',[:S,:I,:R])
    plot(t_obs, y."S", lab="S")
    plot!(t_obs, y."I", lab="I")
    plot!(t_obs, y."R", lab="R")
    savefig(joinpath(@__DIR__, "sir.png"))
end

init_params = [1.0, 1.0]
data = convert(Array, sol)
priors = [Normal(), Normal()]

bayesian_result = stan_inference(prob, t_obs, data, priors; output_format=:dataframe)

if success(bayesian_result.return_code)
    df = bayesian_result.chains
    df |> display
end