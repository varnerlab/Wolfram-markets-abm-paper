# Figs-ModelB-FiniteSizeQuench.jl -- final finite-size figure from the full
# matched quench campaign. No simulations are run here.

include(joinpath(@__DIR__, "..", "code", "model-b", "Include.jl"))

const SUMMARY_PATH = joinpath(_PATH_TO_DATA, "ModelB-Revision-FiniteSize-Summary.csv")
const GROUPED_PATH = joinpath(_PATH_TO_DATA, "ModelB-Revision-FiniteSize-Grouped.csv")
const SCALING_PATH = joinpath(_PATH_TO_DATA, "ModelB-Revision-FiniteSize-Scaling.csv")
all(isfile, (SUMMARY_PATH, GROUPED_PATH, SCALING_PATH)) ||
    error("missing full finite-size outputs")

summary = CSV.read(SUMMARY_PATH, DataFrame)
grouped = CSV.read(GROUPED_PATH, DataFrame)
scaling = CSV.read(SCALING_PATH, DataFrame)

# The reservoir campaign already verifies exact held-boundary invariance to h.
# The scaling campaign therefore stores that redundant lattice arm only once.

sizes = sort(unique(summary.gridn))
size_colors = Dict(L => cgrad(:viridis, length(sizes), categorical = true)[i]
                   for (i, L) in enumerate(sizes))

function _wilson(k::Int, n::Int; z::Float64 = 1.959963984540054)
    p = k / n
    den = 1 + z^2 / n
    center = (p + z^2 / (2n)) / den
    half = z * sqrt(p * (1 - p) / n + z^2 / (4n^2)) / den
    return max(0.0, center - half), min(1.0, center + half)
end

held_rows = NamedTuple[]
held_raw = summary[(summary.boundary_mode .== "hold") .&
                   isdeepreserve.(summary.market_maker_capacity), :]
for df in groupby(held_raw, [:gridn, :target_f])
    n = nrow(df)
    k = count(df.transitioned)
    lo, hi = _wilson(k, n)
    push!(held_rows, (gridn = first(df.gridn), target_f = first(df.target_f),
                      p = k / n, lo = lo, hi = hi))
end
held_curve = DataFrame(held_rows)

pA = plot(; xlabel = "Activated site fraction, f",
          ylabel = "Transition probability", ylims = (-0.03, 1.03),
          legend = :bottomright, _panel_kw...)
for L in sizes
    sub = held_curve[held_curve.gridn .== L, :]
    sort!(sub, :target_f)
    plot!(pA, sub.target_f, sub.p;
          ribbon = (sub.p .- sub.lo, sub.hi .- sub.p),
          color = size_colors[L], fillalpha = 0.055,
          marker = :circle, ms = 2.8, lw = 1.8, label = "L=$(L)")
    fit = only(eachrow(scaling[(scaling.boundary_mode .== "hold") .&
                              (scaling.gridn .== L), :]))
    fs = range(minimum(sub.target_f), maximum(sub.target_f); length=200)
    probability = 1.0 ./ (1.0 .+ exp.(-(fit.logistic_a .+ fit.logistic_b .* (fs .- 0.18) ./ 0.01)))
    plot!(pA, fs, probability; color=size_colors[L], ls=:dash, lw=1.2, label="")
end

pB = plot(; xlabel = "Activated site fraction, f",
          ylabel = "Ensemble susceptibility, χₗ",
          legend = false, _panel_kw...)
for L in sizes
    sub = grouped[(grouped.boundary_mode .== "hold") .&
                  isdeepreserve.(grouped.market_maker_capacity) .&
                  (grouped.gridn .== L), :]
    sort!(sub, :target_f)
    plot!(pB, sub.target_f, sub.ensemble_susceptibility;
          color = size_colors[L], marker = :circle, ms = 2.8,
          lw = 1.8, label = "")
end

conditions = [
    (boundary = "hold", h = 100.0, color = :black, marker = :circle,
     label = "held"),
    (boundary = "endogenous", h = 100.0, color = _SERIES_COLORS[1], marker = :square,
     label = "active, h=100"),
    (boundary = "endogenous", h = 1.0, color = _SERIES_COLORS[3], marker = :diamond,
     label = "active, h=1"),
]

pC = plot(; xlabel = "Inverse lattice size, 1/L", ylabel = "f₅₀(L)",
          legend = :best, _panel_kw...)
pD = plot(; xlabel = "Lattice size, L", ylabel = "Peak susceptibility",
          legend = :best, _panel_kw...)
for cond in conditions
    sub = scaling[(scaling.boundary_mode .== cond.boundary) .&
                  ((isdeepreserve(cond.h) .& isdeepreserve.(scaling.market_maker_capacity)) .|
                   (scaling.market_maker_capacity .== cond.h)), :]
    sort!(sub, :gridn)
    finite_crossing = isfinite.(sub.f50)
    plot!(pC, 1.0 ./ sub.gridn[finite_crossing], sub.f50[finite_crossing];
          yerror = (sub.f50[finite_crossing] .- sub.f50_lo[finite_crossing],
                    sub.f50_hi[finite_crossing] .- sub.f50[finite_crossing]),
          color = cond.color, marker = cond.marker, ms = 4, lw = 1.8,
          label = cond.label)
    positive_peak = sub.susceptibility_peak .> 0
    plot!(pD, sub.gridn[positive_peak], sub.susceptibility_peak[positive_peak];
          yerror = (sub.susceptibility_peak[positive_peak] .- sub.susceptibility_peak_lo[positive_peak],
                    sub.susceptibility_peak_hi[positive_peak] .- sub.susceptibility_peak[positive_peak]),
          color = cond.color, marker = cond.marker, ms = 4, lw = 1.8,
          label = cond.label)
end

for (i, p) in enumerate((pA, pB, pC, pD))
    _panel_letter!(p, string(Char('A' + i - 1)))
end
fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (940, 730),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm, top_margin = 5Plots.mm)
output = joinpath(_PATH_TO_FIGS, "Fig3-FiniteSizeQuench.pdf")
savefig(fig, output)
cp(output, joinpath(_PATH_TO_PAPER_FIGS, "Fig3-FiniteSizeQuench.pdf"); force = true)
@info "Saved finite-size quench figure" output
