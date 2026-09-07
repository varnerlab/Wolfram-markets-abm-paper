# Figs-ModelB-BalanceSheetQuench.jl -- crossed trader cash/share intervention
# figure.  Reads a completed campaign and runs no simulations.
#
# Layout (2 x 2).  Panels A-C share one x-axis: the nine (cash, share)
# multiplier cells at the plotted activation fraction, grouped by cash
# multiplier with the share multiplier on the ticks.  Each panel carries one
# series per dealer capacity.  A: transition probability against the exact
# held-boundary value (which is identical in every cell).  B: median maximum
# drawdown on a log axis, so the 0.04%-83.5% range is legible; medians of
# exactly zero are drawn at the axis floor with open markers.  C: median
# dealer rejection fraction.  D: transition probability against drawdown for
# all 27 endogenous cells, which shows the absence of a monotone relation.

include(joinpath(@__DIR__, "Include.jl"))

const MODE = "--pilot" in ARGS ? "Pilot" : "Full"
const INPUT = joinpath(_PATH_TO_DATA, "ModelB-BalanceSheetQuench-$(MODE)-Summary.csv")
isfile(INPUT) || error("missing $(INPUT); run Compute-ModelB-BalanceSheetQuench.jl")
summary = CSV.read(INPUT, DataFrame)

function _wilson(k::Int, n::Int; z::Float64 = 1.959963984540054)
    p = k / n
    denom = 1 + z^2 / n
    center = (p + z^2 / (2n)) / denom
    half = z * sqrt(p * (1 - p) / n + z^2 / (4n^2)) / denom
    return (max(0.0, center - half), min(1.0, center + half))
end

# Finance is causally disconnected from the lattice in the held-boundary arm.
# Confirm exact within-seed equality across all nine balance-sheet interventions.
held = summary[summary.boundary_mode .== "hold", :]
for df in groupby(held, [:market_maker_capacity, :target_f, :seed])
    @assert length(unique(df.transitioned)) == 1
    @assert length(unique(df.treated_onset)) == 1
    @assert length(unique(df.final_sell_mean)) == 1
end

rows = NamedTuple[]
for df in groupby(summary, [:boundary_mode, :market_maker_capacity, :target_f,
                            :cash_factor, :share_factor])
    push!(rows, (
        boundary_mode = first(df.boundary_mode),
        market_maker_capacity = first(df.market_maker_capacity),
        target_f = first(df.target_f),
        cash_factor = first(df.cash_factor),
        share_factor = first(df.share_factor),
        transition_probability = mean(df.transitioned),
        median_final_sell = median(df.final_sell_mean),
        median_drawdown = median(df.maximum_drawdown),
        median_buy_suppression = median(df.buy_suppression_fraction),
        median_sell_suppression = median(df.sell_suppression_fraction),
        median_maker_rejection = median(df.maker_rejection_fraction),
    ))
end
grouped = DataFrame(rows)
sort!(grouped, [:boundary_mode, :market_maker_capacity, :target_f,
                :cash_factor, :share_factor])
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-BalanceSheetQuench-$(MODE)-Derived.csv"), grouped)

f_plot = MODE == "Full" ? 0.18 : 0.20
f_plot in grouped.target_f || error("f=$(f_plot) is absent from $(INPUT)")
capacities = [0.1, 1.0, Inf]
cash_factors = [0.1, 1.0, 10.0]
share_factors = [0.1, 1.0, 10.0]
factor_labels = ["0.1", "1", "10"]
capacity_colors = Dict(h => cgrad(:viridis, length(capacities), categorical = true)[i]
                       for (i, h) in enumerate(capacities))
_hlabel(h) = isinf(h) ? "∞" : h == 1.0 ? "1" : string(h)

endo = grouped[(grouped.boundary_mode .== "endogenous") .&
               (grouped.target_f .== f_plot), :]
held_f = grouped[(grouped.boundary_mode .== "hold") .& (grouped.target_f .== f_plot), :]
held_p = only(unique(held_f.transition_probability))
n_seeds = length(unique(summary.seed))
held_lo, held_hi = _wilson(round(Int, held_p * n_seeds), n_seeds)

# x positions: cells ordered cash-major, share-minor; 1..3, 4..6, 7..9
cell_x(ci, si) = 3 * (ci - 1) + si
xticks_cells = (1:9, repeat(factor_labels, 3))
group_centers = [2, 5, 8]
group_labels = ["cash ×0.1", "cash ×1", "cash ×10"]

const DRAWDOWN_FLOOR = 1e-3   # percent; medians of exactly zero are drawn here

function _cell_value(df::DataFrame, h::Float64, cf::Float64, sf::Float64, metric::Symbol)
    return only(df[(df.market_maker_capacity .== h) .& (df.cash_factor .== cf) .&
                   (df.share_factor .== sf), metric])
end

# Draw one series per capacity across the nine cells, connecting only within a
# cash group so that the line never implies continuity across groups.
function _cell_series!(p, metric::Symbol; transform = identity, floor = nothing,
                       label_series::Bool = true)
    for h in capacities
        color = capacity_colors[h]
        first_group = true
        for (ci, cf) in enumerate(cash_factors)
            xs = [cell_x(ci, si) for si in 1:3]
            ys = [transform(_cell_value(endo, h, cf, sf, metric)) for sf in share_factors]
            open = floor === nothing ? falses(3) : (ys .<= 0)
            ys_draw = floor === nothing ? ys : max.(ys, floor)
            plot!(p, xs, ys_draw; color = color, lw = 1.8,
                  label = (label_series && first_group) ? "active, h=$(_hlabel(h))" : "")
            closed = .!open
            any(closed) && scatter!(p, xs[closed], ys_draw[closed]; color = color,
                                    marker = :circle, ms = 4.5, markerstrokewidth = 0,
                                    label = "")
            any(open) && scatter!(p, xs[open], ys_draw[open]; color = :white,
                                  markerstrokecolor = color, markerstrokewidth = 1.6,
                                  marker = :circle, ms = 4.5, label = "")
            first_group = false
        end
    end
    vline!(p, [3.5, 6.5]; color = :gray55, ls = :dot, lw = 1, label = "")
    return p
end

function _group_labels!(p, y)
    for (x, lab) in zip(group_centers, group_labels)
        annotate!(p, x, y, text(lab, _ANNOTATION_FONTSIZE, :center, :gray25))
    end
    return p
end

# A: transition probability per cell against the held-boundary constant
pA = plot(; xlabel = "Share multiplier", ylabel = "Transition probability",
          xticks = xticks_cells, xlims = (0.4, 9.6), ylims = (0.35, 1.06),
          legend = :bottomright, _panel_kw...)
hspan!(pA, [held_lo, held_hi]; color = :black, alpha = 0.08, label = "")
hline!(pA, [held_p]; color = :black, ls = :dash, lw = 2.2,
       label = "held (all cells)")
_cell_series!(pA, :transition_probability)
_group_labels!(pA, 1.03)

# B: median maximum drawdown, log axis, in percent
pB = plot(; xlabel = "Share multiplier", ylabel = "Median maximum drawdown (%)",
          xticks = xticks_cells, xlims = (0.4, 9.6), yscale = :log10,
          ylims = (5e-4, 300), yticks = ([1e-3, 1e-2, 1e-1, 1, 10, 100],
                                          ["0", "0.01", "0.1", "1", "10", "100"]),
          legend = false, _panel_kw...)
_cell_series!(pB, :median_drawdown; transform = x -> 100x, floor = DRAWDOWN_FLOOR,
              label_series = false)
_group_labels!(pB, 180.0)

# C: median dealer rejection fraction
pC = plot(; xlabel = "Share multiplier", ylabel = "Median dealer rejection",
          xticks = xticks_cells, xlims = (0.4, 9.6), ylims = (-0.03, 0.72),
          legend = false, _panel_kw...)
_cell_series!(pC, :median_maker_rejection; label_series = false)
_group_labels!(pC, 0.68)

# D: probability against drawdown for all 27 endogenous cells
pD = plot(; xlabel = "Median maximum drawdown (%)", ylabel = "Transition probability",
          xscale = :log10, xlims = (5e-4, 300),
          xticks = ([1e-3, 1e-2, 1e-1, 1, 10, 100], ["0", "0.01", "0.1", "1", "10", "100"]),
          ylims = (0.35, 1.06), legend = false, _panel_kw...)
hspan!(pD, [held_lo, held_hi]; color = :black, alpha = 0.08, label = "")
hline!(pD, [held_p]; color = :black, ls = :dash, lw = 2.2, label = "")
for h in capacities
    sub = endo[endo.market_maker_capacity .== h, :]
    dd = 100 .* sub.median_drawdown
    open = dd .<= 0
    dd_draw = max.(dd, DRAWDOWN_FLOOR)
    color = capacity_colors[h]
    any(.!open) && scatter!(pD, dd_draw[.!open], sub.transition_probability[.!open];
                            color = color, marker = :circle, ms = 6,
                            markerstrokewidth = 0, label = "")
    any(open) && scatter!(pD, dd_draw[open], sub.transition_probability[open];
                          color = :white, markerstrokecolor = color,
                          markerstrokewidth = 1.6, marker = :circle, ms = 6, label = "")
end

for (p, letter) in zip((pA, pB, pC, pD), ("A", "B", "C", "D"))
    _panel_letter!(p, letter)
end
fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (1100, 800),
           left_margin = 5Plots.mm, bottom_margin = 4Plots.mm,
           right_margin = 3Plots.mm, top_margin = 3Plots.mm)
output = joinpath(_PATH_TO_FIGS,
                  MODE == "Full" ? "Fig6-BalanceSheetQuench.pdf" :
                                   "Fig6-BalanceSheetQuench-PilotPreview.pdf")
savefig(fig, output)
MODE == "Full" &&
    cp(output, joinpath(_PATH_TO_PAPER_FIGS, "Fig6-BalanceSheetQuench.pdf"); force = true)
@info "Saved balance-sheet quench figure" output held_p held_lo held_hi
