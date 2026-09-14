using CSV, DataFrames, Statistics

p2 = CSV.read("data/RuleScreen-v3-Pass2.csv", DataFrame)

idx = findfirst(i -> p2.major[i]==15174 && p2.minor[i]==2465, 1:nrow(p2))
if isnothing(idx)
    println("Pair (15174,2465) NOT FOUND in Pass2")
else
    row = p2[idx,:]
    println("Pair (15174,2465): rank=$idx of $(nrow(p2))")
    println("  crash_size=$(round(row.crash_size,digits=4))  buy_min=$(round(row.buy_min,digits=4))  phi_mean=$(round(row.phi_mean,digits=4))")
end

println()
println("Top 10 pairs by crash_size:")
for i in 1:10
    row = p2[i,:]
    println("  $i. major=$(row.major) minor=$(row.minor)  crash=$(round(row.crash_size,digits=3))  buy_min=$(round(row.buy_min,digits=3))  phi_mean=$(round(row.phi_mean,digits=3))")
end

println()
println("crash_size: max=$(round(maximum(p2.crash_size),digits=3))  mean=$(round(mean(p2.crash_size),digits=3))  min=$(round(minimum(p2.crash_size),digits=3))")
