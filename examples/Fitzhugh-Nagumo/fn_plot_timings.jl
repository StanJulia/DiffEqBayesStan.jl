using DataFrames, CSV, Plots, StatsPlots

ProjDir = @__DIR__

nts = [1, 2, 4, 8]
nccs = [2, 4]
ncjs = [1, 2, 4]
nss = [5000, 2500, 1250]
N = 6

df = CSV.read(joinpath(ProjDir, "arm_results.csv"), DataFrame)

df |> display

plot(; xlim=(0, 9), ylim=(0, 60),
    xlab="num_chains", ylab="elapsed time [s]")
for nc in nccs
    for nj in ncjs
        dft = df[df.num_chains .== nj .&& df.num_cpp_chains .== nc, :]
        marksym = dft.num_threads == 2 ? :circle : :cross
        scatter!(dft.num_cpp_chains .* dft.num_chains, dft.median; 
            marker=marksym, lab="chains=$(nc*nj)")
    end
end
savefig(joinpath(ProjDir, "new_results.png"))
