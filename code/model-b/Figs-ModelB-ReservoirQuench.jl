# Figs-ModelB-ReservoirQuench.jl -- final reservoir-capacity figure from the
# full matched rule-quench summary.  No simulations are run here.

include(joinpath(@__DIR__, "Include.jl"))

const MODE = "--pilot" in ARGS ? "Pilot" : "Full"
const INPUT = joinpath(_PATH_TO_DATA, "ModelB-ReservoirQuench-$(MODE)-Summary.csv")
isfile(INPUT) || error("missing $(INPUT); run Compute-ModelB-ReservoirQuench.jl --full")

summary = CSV.read(INPUT, DataFrame)
const N_INTERIOR = (first(summary.gridn) - 2)^2

function _wilson(k::Int, n::Int; z::Float64 = 1.959963984540054)
    p = k / n
    den = 1 + z^2 / n
    center = (p + z^2 / (2n)) / den
    half = z * sqrt(p * (1 - p) / n + z^2 / (4n^2)) / den
    return max(0.0, center - half), min(1.0, center + half)
end

rows = NamedTuple[]
for df in groupby(summary, [:boundary_mode, :market_maker_capacity, :target_f])
    n = nrow(df)
    k = count(df.transitioned)
    plo, phi = _wilson(k, n)
    push!(rows, (
        boundary_mode = first(df.boundary_mode),
        market_maker_capacity = first(df.market_maker_capacity),
        target_f = first(df.target_f),
        n = n,
        transition_probability = k / n,
        transition_lo = plo,
        transition_hi = phi,
        median_onset = begin
            x = df.treated_onset[df.treated_onset .> 0]
            isempty(x) ? NaN : median(x)
        end,
        mean_final_sell = mean(df.treated_final_sell_mean),
        ensemble_susceptibility = N_INTERIOR *
                                  var(df.treated_final_sell_mean; corrected = false),
        median_drawdown = median(df.treated_maximum_drawdown),
        drawdown_q25 = quantile(df.treated_maximum_drawdown, 0.25),
        drawdown_q75 = quantile(df.treated_maximum_drawdown, 0.75),
        median_rejection = median(df.treated_maker_rejection_fraction),
        rejection_q25 = quantile(df.treated_maker_rejection_fraction, 0.25),
        rejection_q75 = quantile(df.treated_maker_rejection_fraction, 0.75),
    ))
end
grouped = DataFrame(rows)
sort!(grouped, [:boundary_mode, :market_maker_capacity, :target_f])
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-ReservoirQuench-$(MODE)-Derived.csv"), grouped)

# Exact implementation checks that are also scientifically useful controls.
held = summary[summary.boundary_mode .== "hold", :]
for df in groupby(held, [:target_f, :seed])
    @assert length(unique(df.transitioned)) == 1
    @assert length(unique(df.treated_onset)) == 1
    @assert length(unique(df.treated_final_sell_mean)) == 1
end
unlimited = summary[isinf.(summary.market_maker_capacity), :]
h10 = summary[summary.market_maker_capacity .== 10.0, :]
sort!(unlimited, [:boundary_mode, :target_f, :seed])
sort!(h10, [:boundary_mode, :target_f, :seed])
@assert unlimited.transitioned == h10.transitioned
@assert unlimited.treated_onset == h10.treated_onset
@assert unlimited.treated_final_sell_mean == h10.treated_final_sell_mean
@assert unlimited.treated_maximum_drawdown == h10.treated_maximum_drawdown
h0_endogenous = summary[(summary.market_maker_capacity .== 0.0) .&
                        (summary.boundary_mode .== "endogenous"), :]
h0_hold = summary[(summary.market_maker_capacity .== 0.0) .&
                  (summary.boundary_mode .== "hold"), :]
sort!(h0_endogenous, [:target_f, :seed])
sort!(h0_hold, [:target_f, :seed])
@assert h0_endogenous.transitioned == h0_hold.transitioned
@assert h0_endogenous.treated_onset == h0_hold.treated_onset
@assert h0_endogenous.treated_final_sell_mean == h0_hold.treated_final_sell_mean
@assert all(iszero, h0_endogenous.treated_maximum_drawdown)

capacity_order = [0.0, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, Inf]
capacity_labels = ["0", "0.1", "0.5", "1", "2", "5", "10", "∞"]
heatmap_capacity_labels = ["0", "0.1", "0.5", "1", "2", "5", "10", "Inf"]
line_capacities = [0.1, 1.0, Inf]
line_colors = Dict(h => cgrad(:viridis, length(line_capacities), categorical = true)[i]
                   for (i, h) in enumerate(line_capacities))

# A: capacity-dependent transition curves against the exact held-boundary CA
# control.  Held curves coincide across h by construction and are drawn once.
pA = plot(; xlabel = "Activated site fraction, f",
          ylabel = "Transition probability", ylims = (-0.03, 1.03),
          legend = :bottomright, _panel_kw...)
hold_curve = grouped[(grouped.boundary_mode .== "hold") .&
                     (grouped.market_maker_capacity .== Inf), :]
sort!(hold_curve, :target_f)
plot!(pA, hold_curve.target_f, hold_curve.transition_probability;
      ribbon = (hold_curve.transition_probability .- hold_curve.transition_lo,
                hold_curve.transition_hi .- hold_curve.transition_probability),
      color = :black, fillalpha = 0.08, ls = :dash, lw = 2.2,
      marker = :circle, ms = 3, label = "held boundary")
for h in line_capacities
    sub = grouped[(grouped.boundary_mode .== "endogenous") .&
                  (grouped.market_maker_capacity .== h), :]
    sort!(sub, :target_f)
    hlabel = isinf(h) ? "∞" : string(h)
    plot!(pA, sub.target_f, sub.transition_probability;
          ribbon = (sub.transition_probability .- sub.transition_lo,
                    sub.transition_hi .- sub.transition_probability),
          color = line_colors[h], fillalpha = 0.045, lw = 1.8,
          marker = :circle, ms = 2.8, label = "endogenous, h=$(hlabel)")
end

# The finite h=10 path coincides with the unlimited path in this campaign.
# A dashed overlay makes the checked equality visible.
h10_curve = sort(grouped[(grouped.boundary_mode .== "endogenous") .&
                         (grouped.market_maker_capacity .== 10.0), :], :target_f)
plot!(pA, h10_curve.target_f, h10_curve.transition_probability;
      color=:black, ls=:dash, lw=1.0, label="endogenous, h=10")

# B: the change attributable to closing the price-boundary feedback loop.
fs = sort(unique(grouped.target_f))
delta = fill(NaN, length(capacity_order), length(fs))
for (iy, h) in enumerate(capacity_order), (ix, f) in enumerate(fs)
    pe = only(grouped[(grouped.boundary_mode .== "endogenous") .&
                      (grouped.market_maker_capacity .== h) .&
                      (grouped.target_f .== f), :transition_probability])
    ph = only(grouped[(grouped.boundary_mode .== "hold") .&
                      (grouped.market_maker_capacity .== h) .&
                      (grouped.target_f .== f), :transition_probability])
    delta[iy, ix] = pe - ph
end
lim = max(0.1, maximum(abs, delta))
pB = heatmap(fs, 1:length(capacity_order), delta;
             xlabel = "Activated site fraction, f",
             ylabel = "Dealer capacity, h",
             yticks = (1:length(capacity_order), heatmap_capacity_labels),
             ytickfontrotation = 0,
             color = cgrad([:navy, :white, :firebrick]), clims = (-lim, lim),
             colorbar_title = "Δ probability", _panel_kw...)

# C-D: financial consequences across the full capacity ladder at the center
# of the resolved transition window.
f_plot = 0.20
function _capacity_panel(metric::Symbol, q25::Symbol, q75::Symbol, ylabel::String)
    p = plot(; xlabel = "Dealer capacity per trader, h", ylabel = ylabel,
             xticks = (1:length(capacity_order), capacity_labels),
             legend = :best, _panel_kw...)
    for (boundary, color, ls, label) in
        (("endogenous", _SERIES_COLORS[1], :solid, "endogenous boundary"),
         ("hold", _SERIES_COLORS[3], :dash, "held boundary"))
        sub = grouped[(grouped.boundary_mode .== boundary) .&
                      (grouped.target_f .== f_plot) .&
                      in.(grouped.market_maker_capacity, Ref(capacity_order)), :]
        order = [findfirst(==(h), sub.market_maker_capacity) for h in capacity_order]
        sub = sub[order, :]
        y = sub[!, metric]
        lo = y .- sub[!, q25]
        hi = sub[!, q75] .- y
        plot!(p, 1:length(capacity_order), y; ribbon = (lo, hi),
              color = color, fillalpha = 0.10, ls = ls,
              marker = :circle, ms = 3, lw = 2, label = label)
    end
    return p
end
pC = _capacity_panel(:median_drawdown, :drawdown_q25, :drawdown_q75,
                     "Maximum price drawdown")
pD = _capacity_panel(:median_rejection, :rejection_q25, :rejection_q75,
                     "Dealer rejection fraction")

for (i, p) in enumerate((pA, pB, pC, pD))
    _panel_letter!(p, string(Char('A' + i - 1)))
end
fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (940, 730),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
           right_margin = 4Plots.mm)
output = joinpath(_PATH_TO_FIGS,
                  MODE == "Full" ? "Fig2-ReservoirQuench.pdf" :
                                   "Fig2-ReservoirQuench-PilotPreview.pdf")
savefig(fig, output)
MODE == "Full" &&
    cp(output, joinpath(_PATH_TO_PAPER_FIGS, "Fig2-ReservoirQuench.pdf"); force = true)
@info "Saved reservoir-quench figure" output
