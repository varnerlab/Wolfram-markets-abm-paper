using CSV, DataFrames, Statistics

p1 = CSV.read("data/RuleScreen-v3-Pass1.csv", DataFrame)
p2 = CSV.read("data/RuleScreen-v3-Pass2.csv", DataFrame)

# We want pairs where:
#   phi_mean > 0.1  (buy-dominant normal market)
#   crash_size > 0.5 (large swings into crash territory)
#   buy_min < 0.3   (crashes go deep enough that sell > buy at times)

good = filter(r ->
    r.phi_mean > 0.1 &&
    r.crash_size > 0.5 &&
    r.buy_min < 0.35,
    p2)
sort!(good, :crash_size; rev=true)

println("=== Crash pairs with positive phi_mean (buy-dominant + real crashes) ===")
println("  (phi_mean > 0.1, crash_size > 0.5, buy_min < 0.35)")
for i in 1:min(15, nrow(good))
    r = good[i,:]
    println("  $i. major=$(r.major) minor=$(r.minor)  crash=$(round(r.crash_size,digits=3))  buy_min=$(round(r.buy_min,digits=3))  phi_mean=$(round(r.phi_mean,digits=3))  phi_var=$(round(r.phi_var,digits=5))")
end

println()
println("=== Pass1 homogeneous behavior of top major rules ===")
top_majors = unique(good.major[1:min(10, nrow(good))])
for m in top_majors
    r = p1[p1.rule .== m, :]
    if !isempty(r)
        row = r[1,:]
        println("  Rule $m: buy=$(round(row.buy,digits=3)) hold=$(round(row.hold,digits=3)) sell=$(round(row.sell,digits=3))  phi_var=$(round(row.phi_var,digits=5))  has_all=$(row.has_all)")
    end
end

println()
println("=== Original course rules in Pass1 ===")
for kr in [6158, 19280, 19286]
    r = p1[p1.rule .== kr, :]
    if isempty(r)
        println("  Rule $kr: not in Pass1 (not herding/contrarian pre-filter)")
    else
        row = r[1,:]
        println("  Rule $kr ($(row.type)): buy=$(round(row.buy,digits=3)) hold=$(round(row.hold,digits=3)) sell=$(round(row.sell,digits=3))  has_all=$(row.has_all)")
    end
end

println()
println("=== Pair (16014, 32): Pass1 behavior of each rule solo ===")
for r_idx in [16014, 32]
    r = p1[p1.rule .== r_idx, :]
    if isempty(r)
        println("  Rule $r_idx: not in Pass1")
    else
        row = r[1,:]
        println("  Rule $r_idx ($(row.type)): buy=$(round(row.buy,digits=3)) hold=$(round(row.hold,digits=3)) sell=$(round(row.sell,digits=3))  phi_var=$(round(row.phi_var,digits=5))")
    end
end
