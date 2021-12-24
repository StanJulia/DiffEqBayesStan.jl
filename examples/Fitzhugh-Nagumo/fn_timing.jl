using DataFrames, CSV, Plots, StatsPlots

ProjDir = @__DIR__
include(joinpath(ProjDir, "fn.jl"))

nts = [1, 2, 4, 8]
ncs = [1, 2, 4, 8]
nss = [10000, 5000, 2500, 1250]
N = 6

function timings(nts, ncs, nss, N)

    df = DataFrame()
    res_t = Vector{Float64}(undef, N)

    for nt in nts
        for nc in ncs
            println("\n\n(num_threads=$nt, num_chains=$nc) runs\n\n")
            for ns in nss
                if nc * ns == 10000
                    for i in 1:N
                        res_t[i] = @elapsed stan_inference(prob_ode_fitzhughnagumo,
                            t,data,priors;
                            num_threads=nt, num_chains=nc, num_samples=ns, 
                            output_format = :dataframe, diffeq_string, tmpdir);
                    end
                    append!(df, DataFrame(
                        num_threads=nt, 
                        num_chains=nc, 
                        num_samples=ns, 
                        min=minimum(res_t),
                        median=median(res_t),
                        max=maximum(res_t))
                    )
                end
            end
        end
    end

    df
end

df = timings(nts, ncs, nss, N)
df |> display

CSV.write(joinpath(ProjDir, "arm_results6_df.csv"), df)

plot(; xlim=(0, 9), ylim=(0, 60),
    xlab="num_chains", ylab="elapsed time [s]")
for nc in ncs
    dft = df[df.num_threads .== nc, :]
    scatter!(dft.num_chains, dft.median; lab="num_threads=$(nc)")
end

savefig(joinpath(ProjDir, "arm_results6.png"))

