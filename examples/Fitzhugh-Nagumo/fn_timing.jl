using DataFrames

ProjDir = @__DIR__
include(joinpath(ProjDir, "fn.jl"))

nts = [1, 4, 8]
ncs = [1, 4, 8]
nss = [10000, 2500, 1250]

function timings(nts, ncs, nss)

    df = DataFrame()
    res_t = Vector{Float64}(undef, 4)

    for nt in nts
        for nc in ncs
            for ns in nss
                if nc * ns == 10000
                    for i in 1:4
                        res_t[i] = @elapsed stan_inference(prob_ode_fitzhughnagumo,
                            t,data,priors;
                            num_threads=nt, num_chains=nc, num_samples=ns, 
                            output_format = :dataframe, diffeq_string, tmpdir);
                    end
                    append!(df, DataFrame(
                        SNT=Meta.parse(ENV["STAN_NUM_THREADS"]), 
                        threads=nt, 
                        chains=nc, 
                        samples=nc * 
                        ns, 
                        time_1=res_t[1],
                        time_2=res_t[2],
                        time_3=res_t[3],
                        time_4=res_t[4],
                        mean=mean(res_t))
                    )
                end
            end
        end
    end

    df
end

df = timings(nts, ncs, nss)
df |> display