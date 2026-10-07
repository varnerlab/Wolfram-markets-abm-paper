# Figs-Variants-MarketPanels.jl -- Supplementary Fig. S1: example markets with
# revision probability r = 0.9, the counterpart of Fig. 4 without the
# checkerboard halves of the synchronous update.
#
# Selection uses the campaign summaries only, before any image is drawn:
#   1. Fig. 4's fractions (0.15, 0.175, 0.185, 0.20 at r = 1, active technical
#      traders, dealer depth h = 100) have archived majority probabilities.
#   2. For each, the r = 0.9 fraction with the nearest majority probability is
#      chosen, ties broken by proximity to the r = 0.9 midpoint f50.
#   3. Within each fraction and outcome, the market nearest the median onset
#      (majority) or median final Sell fraction (no majority) is chosen, ties
#      broken by the lower starting-market number, as for Fig. 4. Unlike the
#      Fig. 4 script, distances are rounded to 12 digits, so the two middle
#      markets of an even-sized group, which are equidistant from the median,
#      count as tied instead of being separated by floating-point noise.
# Each rerun must reproduce its campaign onset and final-grid hash.
#
# Run: julia --project=code code/variants/Figs-Variants-MarketPanels.jl

include(joinpath(@__DIR__, "..", "model-b", "Include.jl"))
using Printf, SHA

const ROOT = joinpath(@__DIR__, "..", "..")
const STUDY = joinpath(ROOT, "output", "rebuilt", "lazy-revision-interior-technical-v1")
const ARCHIVE = joinpath(ROOT, "output", "rebuilt", "manuscript-reserve-v1", "code", "data",
                         "ModelB-ReservoirQuench-Full-Summary.csv")
const CONDITION = "L64-a0.9-r0-endogenous-h100"
const R = 0.9
const H = 100.0
const GRIDN = 64
const T_PRE = 1000
const T_POST = 3000
const STEPS = T_PRE + T_POST
const OFFSETS = Int64[0, 500, 1500, 3000]
const FIG4_SPECS = [(f = 0.150, majority = false), (f = 0.175, majority = false),
                    (f = 0.175, majority = true), (f = 0.185, majority = true),
                    (f = 0.200, majority = true)]

array_digest(x) = bytes2hex(sha256(reinterpret(UInt8, vec(x))))

# --- selection from summaries -------------------------------------------------
archive = CSV.read(ARCHIVE, DataFrame)
archive = archive[(archive.boundary_mode .== "endogenous") .& (archive.market_maker_capacity .== H), :]
target(f) = mean(archive[round.(archive.target_f; digits = 3) .== f, :transitioned])

runs = CSV.read(joinpath(STUDY, "Run-Summary.csv"), DataFrame)
treated = runs[(runs.condition .== CONDITION) .& (runs.role .== "treated"), :]
f50 = only(CSV.read(joinpath(STUDY, "Midpoints.csv"), DataFrame)[
    CSV.read(joinpath(STUDY, "Midpoints.csv"), DataFrame).condition .== CONDITION, :f50])
fractions = sort(unique(treated.f))
probability = Dict(f => mean(treated[treated.f .== f, :majority]) for f in fractions)

function matched_fraction(f4)
    p4 = target(f4)
    best = minimum(abs(probability[f] - p4) for f in fractions)
    ties = [f for f in fractions if abs(probability[f] - p4) == best]
    return ties[argmin([(abs(f - f50), f) for f in ties])]
end

function nearest_market(f, majority)
    rows = treated[(treated.f .== f) .& (treated.majority .== majority), :]
    nrow(rows) > 0 || error("empty group f=$(f) majority=$(majority)")
    metric = majority ? Float64.(rows.onset) : rows.final_sell_mean
    center = median(metric)
    # With an even count the two middle markets are equidistant from the median;
    # round so that floating-point noise cannot break that tie.
    order = sortperm(1:nrow(rows); by = i -> (round(abs(metric[i] - center); digits = 12),
                                              rows.seed[i]))
    return rows[first(order), :]
end

selection = DataFrame()
for spec in FIG4_SPECS
    f = matched_fraction(spec.f)
    row = nearest_market(f, spec.majority)
    push!(selection, (fig4_f = spec.f, fig4_probability = target(spec.f), f = f,
                      probability = probability[f], majority = spec.majority,
                      seed = Int64(row.seed), onset = Int64(row.onset),
                      final_sell_mean = row.final_sell_mean,
                      final_grid_sha256 = String(row.final_grid_sha256)))
end
CSV.write(joinpath(STUDY, "FigS1-Selection.csv"), selection)

# --- rerun and verify ---------------------------------------------------------
function run_market(f, seed)
    config = build(MyModelBConfiguration, (
        number_of_rows = GRIDN, number_of_cols = GRIDN, steps = STEPS, seed = seed,
        λ = 0.02, k = 1.0, minority_fraction = f, edge_band_spread = 0.5,
        cost_basis_rule = false, initial_cash = 1000.0, initial_shares = 10,
        P0 = 100.0, market_maker_capacity = H))
    return simulate(config; clearing = :reserve, minority_population = :interior,
                    rule_activation_step = T_PRE + 1, boundary_mode = :endogenous,
                    revision_probability = R, snapshot_steps = T_PRE .+ OFFSETS,
                    verbose = false)
end

results = MyModelBSimulationResult[]
for row in eachrow(selection)
    result = run_market(row.f, row.seed)
    crossing = findfirst(≥(0.5), @view result.sell_fraction[(T_PRE + 2):end])
    @assert (isnothing(crossing) ? -1 : crossing) == row.onset
    @assert array_digest(result.frames[STEPS]) == row.final_grid_sha256
    push!(results, result)
end

# --- panels (layout of Fig. 4, from code/model-b/Figs-ModelB-MarketPanels.jl) --
function atlas_panel(results, labels)
    L, header, row_gap, col_gap = GRIDN, 35, 4, 5
    nrows, ncols = length(OFFSETS), length(results)
    height = header + nrows * L + (nrows - 1) * row_gap
    width = ncols * L + (ncols - 1) * col_gap
    canvas = fill(NaN, height, width)
    for (c, result) in enumerate(results), (r, offset) in enumerate(OFFSETS)
        first_row = header + (r - 1) * (L + row_gap) + 1
        first_col = (c - 1) * (L + col_gap) + 1
        canvas[first_row:first_row + L - 1, first_col:first_col + L - 1] .= result.frames[T_PRE + offset]
    end
    panel = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), colorbar = false,
        axis = false, yflip = true, aspect_ratio = :equal,
        xlims = (0.5, width + 0.5), ylims = (0.5, height + 0.5), widen = false,
        framestyle = :none, margin = 0Plots.mm, background_color_inside = :white)
    for (c, label) in enumerate(labels)
        center = (c - 1) * (L + col_gap) + 1 + (L - 1) / 2
        annotate!(panel, center, header / 2, text(label, :black, :center, 9, "helvetica"))
    end
    for (r, offset) in enumerate(OFFSETS)
        first_row = header + (r - 1) * (L + row_gap) + 1
        label = offset == 0 ? "rule switch" : "+$(offset) steps"
        x0, x1, y0, y1 = 2, 43, first_row + 1, first_row + 10
        plot!(panel, Shape([x0, x1, x1, x0], [y0, y0, y1, y1]);
              color = :white, linecolor = :transparent, fillalpha = 0.82, label = "")
        annotate!(panel, x0 + 2, (y0 + y1) / 2, text(label, :black, :left, 9, "helvetica"))
    end
    annotate!(panel, 3, header / 2, text("A", :black, :left, 14, "helvetica bold"))
    return panel
end

function trajectory_panels(results, labels, colors)
    times = collect(-500:T_POST)
    indices = (T_PRE - 500:T_PRE + T_POST) .+ 1
    pB = plot(; xlabel = "Steps after rule switch", ylabel = "Price / price at rule switch",
              legend = :bottomleft, _panel_kw...)
    pC = plot(; xlabel = "Steps after rule switch", ylabel = "Sell fraction",
              ylims = (0, 1), legend = false, _panel_kw...)
    for (result, label, color) in zip(results, labels, colors)
        plot!(pB, times, result.prices[indices] ./ result.prices[T_PRE + 1];
              color = color, lw = 1.9, label = label)
        plot!(pC, times, result.sell_fraction[indices]; color = color, lw = 1.9, label = "")
    end
    for offset in OFFSETS, panel in (pB, pC)
        vline!(panel, [offset]; color = :black, alpha = 0.25, ls = :dot, lw = 0.8, label = "")
    end
    hline!(pC, [0.5]; color = :black, ls = :dash, lw = 0.9, label = "")
    _panel_letter!(pB, "B")
    _panel_letter!(pC, "C")
    return pB, pC
end

column_labels = String[]
trace_labels = String[]
for row in eachrow(selection)
    outcome = row.onset < 0 ? "no majority" : "majority +$(row.onset)"
    push!(column_labels, "f = $(@sprintf("%.3f", row.f))\n$(outcome)\nmarket $(row.seed)")
    push!(trace_labels, "f=$(@sprintf("%.3f", row.f)), market $(row.seed)")
end
colors = [_SERIES_COLORS[2], _SERIES_COLORS[5], _SERIES_COLORS[1], _SERIES_COLORS[3], _SELL_COLOR]
atlas = atlas_panel(results, column_labels)
price, sell = trajectory_panels(results, trace_labels, colors)
figure = plot(atlas, price, sell; layout = @layout([a{0.70h}; b c]), size = (1000, 1250),
              left_margin = 9Plots.mm, right_margin = 3Plots.mm, bottom_margin = 4Plots.mm)
_save_figure(figure, "FigS1-RevisionMarketPanels.pdf")
@info "Supplementary Fig. S1" fractions = selection.f seeds = selection.seed
