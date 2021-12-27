function timings_check!(df::DataFrame; N = 6, upper=0.25)

    for row in 1:nrow(df)
        if df[row, :].max > (1.0 + upper) * df[row, :].median
            println("\n\nFixing row=$row: $(df[row, :])")

            #
            dft = timings(
                [df[row, :].num_threads], [df[row, :].num_cpp_chains], 
                [df[row, :].num_chains], [df[row, :].num_samples], N)
            #
            df[row, :] = dft[1, :]
            println("Updating row=$row: $(df[row, :])")
        end
    end
end

timings_check!(df)
df

# Write df to results subdir

CSV.write(joinpath(ProjDir, "results", "arm_no_tbb.csv"), df)
#CSV.write(joinpath(ProjDir, "results", "arm_tbb.csv"), df)
#CSV.write(joinpath(ProjDir, "results", "intel_no_tbb.csv"), df)
#CSV.write(joinpath(ProjDir, "results", "intel_tbb.csv"), df)

# Sort on (:num_threads,:num_chains0 instead on (:num_threads, :num_cpp_chains)

#sort(df, [:num_threads, :num_chains])