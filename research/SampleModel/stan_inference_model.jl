using DocStringExtensions
import DiffEqBayesStan: stan_string
import StanSample: SampleModel

struct StanODEData end

function generate_priors(n,priors)
    priors_string = ""
    if priors===nothing
        for i in 1:n
          priors_string = string(priors_string,"theta_$i ~ normal(0, 1)", " ; ")
        end
    else
        for i in 1:n
          priors_string = string(priors_string,"theta_$i ~ ",stan_string(priors[i]),";")
        end
    end
    priors_string
end

function generate_theta(n,priors)
    theta = ""
    for i in 1:n
        upper_bound = ""
        lower_bound = ""
        if !isnothing(priors) && maximum(priors[i]) != Inf
            upper_bound = string("upper=",maximum(priors[i]))
        end
        if !isnothing(priors) && minimum(priors[i]) != -Inf
            lower_bound = string("lower=",minimum(priors[i]))
        end
        if lower_bound != "" && upper_bound != ""
            theta = string(theta,"real","<$lower_bound",",","$upper_bound>"," theta_$i",";")
        elseif lower_bound != ""
            theta = string(theta,"real","<$lower_bound",">"," theta_$i",";")
        elseif upper_bound != ""
            theta = string(theta,"real","<","$upper_bound>"," theta_$i",";")
        else
            theta = string(theta,"real"," theta_$i",";")
        end
    end
    return theta
end

"""

Create and compile a SampleModel based on DiffEqBayes.

$(SIGNATURES)

For more details, use extended help.

# Extended help

### Required positional arguments
```julia
* `name::AbstractString` # Name for model
* `prob::::DiffEqBase.DEProblem` # Name for the model
* `t` # Time steps
* `data` # Data for DiffEq model
```

### Optional positional arguments
```julia
* `priors=nothing`
* `SampleModel=nothing`
```

### Keyword arguments
```julia
* `likelihood=Normal`
* `vars=(StanODEData(), InverseGamma(3,3))`
* `sample_u0=false`
* `save_idxs=nothing`
* `diffeq_string=nothing`
* `alg = :rk45`
* `reltol=1e-3`
* `abstol=1e-6`
* `maxiter=Int(1e5)`
* `tmpdir=mktempdir()` # Directory where output files are stored
```

### Returns
```julia
* `(samplemodel, data)` # Tuple containing a SampleModel and date to be used in stan_sample(...)
```
"""
function SampleModel(
    name::AbstractString,
    prob::DiffEqBase.DEProblem,
    # Positional arguments
    t, data, priors=nothing, stanmodel=nothing;
    # DiffEqBayes keyword arguments
    likelihood=Normal, vars=(StanODEData(), InverseGamma(3,3)),
    sample_u0=false, save_idxs=nothing, diffeq_string=nothing,
    # Stan differential equation function keyword arguments
    alg = :rk45, reltol=1e-3, abstol=1e-6, maxiter=Int(1e5),
    tmpdir=mktempdir())

    save_idxs !== nothing && length(save_idxs) == 1 ? save_idxs = save_idxs[1] : save_idxs = save_idxs
    length_of_y = length(prob.u0)
    save_idxs = something(save_idxs, 1:length_of_y)

    length_of_params = length(vars)
    if isnothing(diffeq_string)
        sys = ModelingToolkit.modelingtoolkitize(prob)
        length_of_parameter = length(ModelingToolkit.parameters(sys)) + sample_u0 * length(save_idxs)
    else
        length_of_parameter = length(prob.p) + sample_u0 * length(save_idxs)
    end

    if stanmodel === nothing
        if alg ==:adams
            algorithm = "ode_adams_tol"
        elseif alg ==:rk45
            algorithm = "ode_rk45_tol"
        elseif alg == :bdf
            algorithm = "ode_bdf_tol"
        else
            error("The choices for alg are :adams, :rk45, or :bdf")
        end

        hyper_params = ""
        tuple_hyper_params = ""
        setup_params = ""
        thetas = ""
        theta_names = ""
        theta_string = generate_theta(length_of_parameter, priors)

        for i in 1:length_of_parameter
            thetas = string(thetas,"real theta_$i",";")
            theta_names = string(theta_names,"theta_$i",",")
        end
        for i in 1:length_of_params
            if isa(vars[i],StanODEData)
                tuple_hyper_params = string(tuple_hyper_params,"u_hat[t,$save_idxs]",",")
            else
                dist = stan_string(vars[i])
                hyper_params = string(hyper_params,"sigma$(i-1) ~ $dist;")
                tuple_hyper_params = string(tuple_hyper_params,"sigma$(i-1)",",")
                setup_params = string(setup_params,"row_vector<lower=0>[$(length(save_idxs))] sigma$(i-1);")
            end
        end

        tuple_hyper_params = tuple_hyper_params[1:length(tuple_hyper_params)-1]
        priors_string = string(generate_priors(length_of_parameter,priors))
        stan_likelihood = stan_string(likelihood)

        if sample_u0
            nu = length(save_idxs)
            dv_names_ind = findfirst("$nu", theta_names)[1]
            if nu < length(prob.u0)
                u0 = ""
                for u_ in prob.u0[nu+1:length(prob.u0)]
                    u0 = u0*string(u_)
                end
                integral_string = "u_hat = $algorithm(sho, [$(theta_names[1:dv_names_ind]),$u0]', t0, ts, $reltol, $abstol, $maxiter, $(rstrip(theta_names[dv_names_ind+2:end],',')));"
            else
                integral_string = "u_hat = $algorithm(sho, [$(theta_names[1:dv_names_ind])]', t0, ts, $reltol, $abstol, $maxiter, $(rstrip(theta_names[dv_names_ind+2:end],',')));"
            end
        else
            integral_string = "u_hat = $algorithm(sho, u0, t0, ts, $reltol, $abstol, $maxiter, $(rstrip(theta_names,',')));"
        end

        if isnothing(diffeq_string)
            diffeq_string = ModelingToolkit.build_function(
                ModelingToolkit.equations(sys),
                ModelingToolkit.states(sys),
                ModelingToolkit.parameters(sys),
                ModelingToolkit.get_iv(sys);
                expression = Val{true},
                fname = :sho,
                target = ModelingToolkit.StanTarget()
            )
        end

        parameter_estimation_model = "
            functions {
                $diffeq_string
            }
            data {
                vector[$length_of_y] u0;
                int<lower=1> T;
                real internal_var___u[T,$(length(save_idxs))];
                real t0;
                real ts[T];
            }
            parameters {
                $setup_params
                $theta_string
            }
            model{
                vector[$length_of_y] u_hat[T];
                $hyper_params
                $priors_string
                $integral_string
                for (t in 1:T){
                    internal_var___u[t,:] ~ $stan_likelihood($tuple_hyper_params);
                }
            }
        ";

        stanmodel = 
            SampleModel(name, parameter_estimation_model, tmpdir)

    end

    data = Dict(
        "u0"=>prob.u0, "T" => length(t), 
        "internal_var___u" => view(data, :, 1:length(t)), 
        "t0" => prob.tspan[1], "ts" => t)

    return (stanmodel, data)

end