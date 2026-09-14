using JLD2, FileIO, Statistics

hom   = load("data/ModelA-Homogeneous.jld2");
crash = load("data/ModelA-Crash.jld2");
sweep = load("data/ModelA-PhaseSweep.jld2");

function summarize(d, label)
    frames = d["frames"]
    T = length(frames)
    N = 256*256
    ts = sort(collect(keys(frames)))
    buy_frac  = [count(==(0), frames[t]) / N for t in ts]
    hold_frac = [count(==(1), frames[t]) / N for t in ts]
    sell_frac = [count(==(2), frames[t]) / N for t in ts]
    println("=== $label ===")
    println("  Steps: $T")
    println("  Buy  mean=$(round(mean(buy_frac),digits=3))  max=$(round(maximum(buy_frac),digits=3))  final=$(round(buy_frac[end],digits=3))")
    println("  Hold mean=$(round(mean(hold_frac),digits=3))  max=$(round(maximum(hold_frac),digits=3))  final=$(round(hold_frac[end],digits=3))")
    println("  Sell mean=$(round(mean(sell_frac),digits=3))  max=$(round(maximum(sell_frac),digits=3))  final=$(round(sell_frac[end],digits=3))")
    ni = d["net_imbalance"]
    println("  Sell>0.5: $(count(s->s>0.5, sell_frac)) steps   Sell>0.3: $(count(s->s>0.3, sell_frac)) steps")
    println("  Net imbalance: mean=$(round(mean(ni),digits=4))  min=$(round(minimum(ni),digits=4))  max=$(round(maximum(ni),digits=4))")
end

summarize(hom,   "Homogeneous Rule 15174 f=0")
println()
summarize(crash, "Crash Rule 15174+2465 f=0.20")

println()
println("=== Phase Sweep (mean_sell / max_sell / crash_freq) ===")
f_vals = sweep["f_values"]
res    = sweep["sweep_results"]
for f in sort(f_vals)
    r  = res[f]
    ms = round(r["mean_sell_fraction"], digits=3)
    mx = round(r["max_sell_fraction"],  digits=3)
    cf = round(r["crash_frequency"],    digits=4)
    println("  f=$(lpad(round(f,digits=2),4))  mean_sell=$ms  max_sell=$mx  crash_freq=$cf")
end
