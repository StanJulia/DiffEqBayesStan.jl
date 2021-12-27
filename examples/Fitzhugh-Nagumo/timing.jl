using DataFrames, CSV, Plots, StatsPlots

ProjDir = @__DIR__
include(joinpath(ProjDir, "fn.jl"))

nts = [1, 2, 4, 8]
nccs = [1, 2, 4, 8]
ncjs = [1, 2, 4, 8]
nss = [10000, 5000, 2500, 1250]
N = 6

function timings(nts, nccs, ncjs, nss, N)

    df = DataFrame()
    res_t = Vector{Float64}(undef, N)

    for nt in nts
        for nc in nccs
            for nj in ncjs
                println("\n\n(num_threads=$nt, num_cpp-chains=$nc, num_chains=$nj) runs\n\n")
                for ns in nss
                    if nc * nj * ns == 10000
                        for i in 1:N
                            res_t[i] = @elapsed stan_inference(prob_ode_fitzhughnagumo,
                                t,data,priors; num_threads=nt, num_cpp_chains=nc,
                                num_chains=nj, num_samples=ns, 
                                output_format = :dataframe, diffeq_string, tmpdir);
                        end
                        append!(df, DataFrame(
                            num_threads=nt, 
                            num_cpp_chains=nc,
                            num_chains=nj, 
                            num_samples=ns, 
                            min=minimum(res_t),
                            median=median(res_t),
                            max=maximum(res_t))
                        )
                    end
                end
            end
        end
    end

    df
end

df = timings(nts, nccs, ncjs, nss, N)
df |> display

CSV.write(joinpath(ProjDir, "results", "new_results_df.csv"), df)
