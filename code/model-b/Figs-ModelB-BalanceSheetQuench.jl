# Figs-ModelB-BalanceSheetQuench.jl -- crossed trader cash/share intervention
# figure.  Reads a completed campaign and runs no simulations.

include(joinpath(@__DIR__, "Include.jl"))

const MODE = "--pilot" in ARGS ? "Pilot" : "Full"
const INPUT = joinpath(_PATH_TO_DATA, "ModelB-BalanceSheetQuench-$(MODE)-Summary.csv")
isfile(INPUT) || error("missing $(INPUT); run Compute-ModelB-BalanceSheetQuench.jl")
summary = CSV.read(INPUT, DataFrame)

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
capacities = [Inf, 1.0, 0.1]
cash_factors = [0.1, 1.0, 10.0]
share_factors = [0.1, 1.0, 10.0]
factor_labels = ["0.1", "1", "10"]

function _matrix(df::DataFrame, metric::Symbol)
    return [only(df[(df.share_factor .== sf) .&
                    (df.cash_factor .== cf), metric])
            for sf in share_factors, cf in cash_factors]
end

endo = grouped[(grouped.boundary_mode .== "endogenous") .&
               (grouped.target_f .== f_plot), :]
drawdown_max = maximum(endo.median_drawdown)
panels = Plots.Plot[]
for (row_index, metric) in enumerate((:transition_probability, :median_drawdown))
    for (column_index, h) in enumerate(capacities)
        sub = endo[endo.market_maker_capacity .== h, :]
        z = _matrix(sub, metric)
        h_label = isinf(h) ? "∞" : h == 1.0 ? "1" : string(h)
        xlabel = row_index == 2 ? "Cash multiplier" : ""
        ylabel = column_index == 1 ? "Share multiplier" : ""
        colorbar_title = metric == :transition_probability ? "Probability" : "Drawdown"
        p = heatmap(1:3, 1:3, z;
                    xticks = (1:3, row_index == 2 ? factor_labels : ["", "", ""]),
                    yticks = (1:3, column_index == 1 ? factor_labels : ["", "", ""]),
                    xlabel = xlabel, ylabel = ylabel,
                    title = row_index == 1 ? "h=$(h_label)" : "",
                    color = :viridis,
                    clims = metric == :transition_probability ? (0, 1) :
                                                              (0, drawdown_max),
                    colorbar_title = colorbar_title,
                    _panel_kw...)
        push!(panels, p)
    end
end
for (i, p) in enumerate(panels)
    _panel_letter!(p, string(Char('A' + i - 1)))
end
fig = plot(panels...; layout = (2, 3), size = (1100, 650),
           left_margin = 5Plots.mm, bottom_margin = 4Plots.mm,
           right_margin = 3Plots.mm)
output = joinpath(_PATH_TO_FIGS,
                  MODE == "Full" ? "Fig6-BalanceSheetQuench.pdf" :
                                   "Fig6-BalanceSheetQuench-PilotPreview.pdf")
savefig(fig, output)
MODE == "Full" &&
    cp(output, joinpath(_PATH_TO_PAPER_FIGS, "Fig6-BalanceSheetQuench.pdf"); force = true)
@info "Saved balance-sheet quench figure" output
