# Figs-ModelB-MarketPanels.jl -- selected market histories for Figs. 4 and 5.
#
# Figure 4 extends the same five cases selected from the original 3,000-step
# summaries to 10,000 steps. Figure 5 retains its original 3,000-step window.
# Selection uses numerical summaries, never visual appearance.
# Pass --fig4-only to regenerate only the extended figure.

include(joinpath(@__DIR__, "Include.jl"))
using Printf

const SUMMARY_PATH = joinpath(_PATH_TO_DATA, "ModelB-ReservoirQuench-Full-Summary.csv")
isfile(SUMMARY_PATH) || error("missing $(SUMMARY_PATH); run Compute-ModelB-ReservoirQuench.jl --full")
const SUMMARY = CSV.read(SUMMARY_PATH, DataFrame)

const GRIDN = 64
const T_PRE = 1000
const T_POST = 3000
const STEPS = T_PRE + T_POST
const SNAPSHOT_OFFSETS = Int64[0, 500, 1500, 3000]
const FIG4_POST = 10000
const FIG4_OFFSETS = Int64[0, 1500, 3000, 5000, FIG4_POST]

function _market_panel_config(f::Float64, h::Float64, seed::Int64; post::Int=T_POST)
    return build(MyModelBConfiguration, (
        number_of_rows = GRIDN,
        number_of_cols = GRIDN,
        steps = T_PRE + post,
        seed = seed,
        λ = 0.02,
        k = 1.0,
        minority_fraction = f,
        edge_band_spread = 0.5,
        cost_basis_rule = false,
        initial_cash = 1000.0,
        initial_shares = 10,
        P0 = 100.0,
        market_maker_capacity = h,
    ))
end

function _run_market_panel(f::Float64, h::Float64, seed::Int64, boundary::Symbol;
                           post::Int=T_POST, offsets::Vector{Int64}=SNAPSHOT_OFFSETS)
    config = _market_panel_config(f, h, seed; post=post)
    return simulate(config;
        snapshot_steps = T_PRE .+ offsets,
        minority_population = :interior,
        rule_activation_step = T_PRE + 1,
        boundary_mode = boundary,
        verbose = false)
end

function _observed_onset(result::MyModelBSimulationResult;
                         post::Int=length(result.sell_fraction)-T_PRE-1)
    crossing = findfirst(≥(0.5), @view result.sell_fraction[(T_PRE+1):(T_PRE+post+1)])
    return isnothing(crossing) ? 0 : crossing - 1
end

function _nearest_subgroup_row(f::Float64, transitioned::Bool)
    rows = SUMMARY[(SUMMARY.boundary_mode .== "endogenous") .&
                   isinf.(SUMMARY.market_maker_capacity) .&
                   (SUMMARY.target_f .== f) .&
                   (SUMMARY.transitioned .== transitioned), :]
    nrow(rows) > 0 || error("empty selection group for f=$(f), transitioned=$(transitioned)")
    metric = transitioned ? rows.treated_onset : rows.treated_final_sell_mean
    center = median(metric)
    return rows[argmin(abs.(metric .- center)), :]
end

function _atlas_panel(results::Vector{MyModelBSimulationResult}, row_labels::Vector{String};
                      letter::String = "A", cases_as_columns::Bool = false,
                      offsets::Vector{Int64} = SNAPSHOT_OFFSETS)
    ncases = length(results)
    ntimes = length(offsets)
    L = GRIDN
    header = cases_as_columns ? 35 : 20
    label_band = cases_as_columns ? 0 : 58
    row_gap = 4
    col_gap = 5
    nrows = cases_as_columns ? ntimes : ncases
    ncols = cases_as_columns ? ncases : ntimes
    height = header + nrows * L + (nrows - 1) * row_gap
    width = label_band + ncols * L + (ncols - 1) * col_gap
    canvas = fill(NaN, height, width)

    for (case_index, result) in enumerate(results)
        for (time_index, offset) in enumerate(offsets)
            r = cases_as_columns ? time_index : case_index
            c = cases_as_columns ? case_index : time_index
            first_row = header + (r - 1) * (L + row_gap) + 1
            last_row = first_row + L - 1
            first_col = label_band + (c - 1) * (L + col_gap) + 1
            last_col = first_col + L - 1
            canvas[first_row:last_row, first_col:last_col] .= result.frames[T_PRE + offset]
        end
    end

    panel = heatmap(canvas;
        c = _grid_cgrad(), clims = (0, 2), colorbar = false,
        axis = false, yflip = true, aspect_ratio = :equal,
        xlims = (0.5, width + 0.5), ylims = (0.5, height + 0.5),
        widen = false,
        framestyle = :none, margin = 0Plots.mm,
        background_color_inside = :white)

    if cases_as_columns
        for (c, label) in enumerate(row_labels)
            first_col = label_band + (c - 1) * (L + col_gap) + 1
            center = first_col + (L - 1) / 2
            annotate!(panel, center, header / 2,
                      text(label, :black, :center, 9, "helvetica"))
        end
        for (r, offset) in enumerate(offsets)
            first_row = header + (r - 1) * (L + row_gap) + 1
            label = offset == 0 ? "rule change" : "+$(offset) steps"
            first_col = label_band + 1
            x0, x1 = first_col + 1, first_col + 42
            y0, y1 = first_row + 1, first_row + 10
            plot!(panel, Shape([x0, x1, x1, x0], [y0, y0, y1, y1]);
                  color = :white, linecolor = :transparent, fillalpha = 0.82,
                  label = "")
            annotate!(panel, x0 + 2, (y0 + y1) / 2,
                      text(label, :black, :left, 9, "helvetica"))
        end
    else
        for (c, offset) in enumerate(offsets)
            first_col = label_band + (c - 1) * (L + col_gap) + 1
            center = first_col + (L - 1) / 2
            label = offset == 0 ? "rule change" : "+$(offset) steps"
            annotate!(panel, center, header / 2,
                      text(label, :black, :center, 12, "helvetica"))
        end
        for (r, label) in enumerate(row_labels)
            first_row = header + (r - 1) * (L + row_gap) + 1
            center = first_row + (L - 1) / 2
            annotate!(panel, label_band / 2, center,
                      text(label, :black, :center, 10, "helvetica"))
        end
    end
    annotate!(panel, 3, header / 2, text(letter, :black, :left, 14, "helvetica bold"))
    return panel
end

function _trajectory_panels(results::Vector{MyModelBSimulationResult},
                            labels::Vector{String}, colors::Vector{String};
                            post::Int=T_POST, offsets::Vector{Int64}=SNAPSHOT_OFFSETS)
    times = collect(-500:post)
    indices = (T_PRE-500:T_PRE+post) .+ 1
    pB = plot(; xlabel = "Steps after rule change", ylabel = "Price / price at rule change",
              legend = :bottomleft, _panel_kw...)
    pC = plot(; xlabel = "Steps after rule change", ylabel = "Sell fraction",
              ylims = (0, 1), legend = false, _panel_kw...)
    for (result, label, color) in zip(results, labels, colors)
        p0 = result.prices[T_PRE + 1]
        plot!(pB, times, result.prices[indices] ./ p0;
              color = color, lw = 1.9, label = label)
        plot!(pC, times, result.sell_fraction[indices];
              color = color, lw = 1.9, label = "")
    end
    for offset in offsets
        original_endpoint = post > T_POST && offset == T_POST
        for panel in (pB,pC)
            vline!(panel, [offset]; color=:black, alpha=original_endpoint ? 0.8 : 0.25,
                   ls=original_endpoint ? :dash : :dot, lw=original_endpoint ? 1.2 : 0.8, label="")
        end
    end
    if post > T_POST
        for panel in (pB,pC)
            plot!(panel; xticks=([0,3000,5000,10000], ["0","3,000","5,000","10,000"]))
        end
    end
    hline!(pC, [0.5]; color = :black, ls = :dash, lw = 0.9, label = "")
    _panel_letter!(pB, "B")
    _panel_letter!(pC, "C")
    return pB, pC
end

# Figure 4: retain selection from the original 3,000-step outcome groups,
# then follow those same markets longer without selecting new examples.
dose_specs = [
    (f = 0.150, transitioned = false),
    (f = 0.175, transitioned = false),
    (f = 0.175, transitioned = true),
    (f = 0.185, transitioned = true),
    (f = 0.200, transitioned = true),
]
dose_rows = [_nearest_subgroup_row(spec.f, spec.transitioned) for spec in dose_specs]
@assert Int64.(getproperty.(dose_rows,:seed)) == [8,5,22,46,21]
extended_path = joinpath(_PATH_TO_DATA,"ModelB-Revision-MarketPanel-Horizons.csv")
isfile(extended_path) || error("Run code/revision/Compute-MarketPanel-Horizons.jl first")
extended = CSV.read(extended_path,DataFrame)
dose_results = MyModelBSimulationResult[]
dose_row_labels = String[]
dose_trace_labels = String[]
for (spec, row) in zip(dose_specs, dose_rows)
    seed = Int64(row.seed)
    result = _run_market_panel(spec.f, Inf, seed, :endogenous;
                               post=FIG4_POST, offsets=FIG4_OFFSETS)
    original_onset = _observed_onset(result; post=T_POST)
    @assert (original_onset > 0) == spec.transitioned
    @assert original_onset == Int64(row.treated_onset)
    onset = _observed_onset(result)
    check = only(eachrow(extended[(extended.f .== spec.f) .& (extended.seed .== seed) .&
                                 (extended.condition .== "changed") .& (extended.post .== FIG4_POST),:]))
    @assert onset == check.onset
    @assert isapprox(result.prices[end]/result.prices[T_PRE+1]-1,check.price_change; atol=1e-14)
    @assert isapprox(mean(result.sell_fraction[end-499:end]),check.final_sell_mean; atol=1e-14)
    push!(dose_results, result)
    outcome = onset == 0 ? "no majority" : "majority +$(onset)"
    push!(dose_row_labels, "f = $(lpad(@sprintf("%.3f", spec.f), 5))\n$(outcome)\nseed $(seed)")
    push!(dose_trace_labels, "f=$(@sprintf("%.3f", spec.f)), seed $(seed)")
end
dose_colors = [_SERIES_COLORS[2], _SERIES_COLORS[5], _SERIES_COLORS[1],
               _SERIES_COLORS[3], _SELL_COLOR]
dose_atlas = _atlas_panel(dose_results, dose_row_labels;
                          cases_as_columns=true, offsets=FIG4_OFFSETS)
dose_price, dose_sell = _trajectory_panels(dose_results, dose_trace_labels, dose_colors;
                                          post=FIG4_POST, offsets=FIG4_OFFSETS)
dose_figure = plot(dose_atlas, dose_price, dose_sell;
    layout = @layout([a{0.76h}; b c]), size = (1000, 1450),
    left_margin = 9Plots.mm, right_margin = 3Plots.mm, bottom_margin = 4Plots.mm)
_save_figure(dose_figure, "Fig4-DoseMarketPanels.pdf")
"--fig4-only" in ARGS && exit()

# Figure 5: one seed chosen jointly across h=0.1, 1, and Inf. Eligible seeds
# crossed in all three endogenous arms. The selected seed minimized its summed
# absolute distance from the three capacity-specific median onsets.
capacity_values = Float64[0.1, 1.0, Inf]
capacity_pool = SUMMARY[(SUMMARY.boundary_mode .== "endogenous") .&
                        (SUMMARY.target_f .== 0.20) .&
                        SUMMARY.transitioned .&
                        [h in capacity_values for h in SUMMARY.market_maker_capacity], :]
capacity_medians = Dict(h => median(capacity_pool[capacity_pool.market_maker_capacity .== h, :treated_onset])
                        for h in capacity_values)
eligible_seeds = Int64[]
for seed in sort(unique(Int64.(capacity_pool.seed)))
    rows = capacity_pool[capacity_pool.seed .== seed, :]
    all(any(rows.market_maker_capacity .== h) for h in capacity_values) && push!(eligible_seeds, seed)
end
isempty(eligible_seeds) && error("no seed crossed at every selected dealer capacity")
distance(seed) = sum(abs(first(capacity_pool[(capacity_pool.seed .== seed) .&
                                            (capacity_pool.market_maker_capacity .== h), :treated_onset]) -
                         capacity_medians[h]) for h in capacity_values)
capacity_seed = eligible_seeds[argmin(distance.(eligible_seeds))]

capacity_results = MyModelBSimulationResult[]
capacity_row_labels = String[]
capacity_trace_labels = String[]
for h in capacity_values
    result = _run_market_panel(0.20, h, capacity_seed, :endogenous)
    onset = _observed_onset(result)
    summary_onset = first(capacity_pool[(capacity_pool.seed .== capacity_seed) .&
                                        (capacity_pool.market_maker_capacity .== h), :treated_onset])
    @assert onset == Int64(summary_onset)
    hlabel = isinf(h) ? "infinite dealer" : "dealer h = $(@sprintf("%.1f", h))"
    push!(capacity_results, result)
    push!(capacity_row_labels, "$(hlabel)\nonset +$(onset)\nseed $(capacity_seed)")
    push!(capacity_trace_labels, hlabel)
end
held_result = _run_market_panel(0.20, Inf, capacity_seed, :hold)
held_onset = _observed_onset(held_result)
push!(capacity_results, held_result)
push!(capacity_row_labels, "technical traders held\n$(held_onset == 0 ? "no crossing" : "onset +$(held_onset)")\nseed $(capacity_seed)")
push!(capacity_trace_labels, "technical traders held")

capacity_colors = [_SERIES_COLORS[2], _SERIES_COLORS[1], _SELL_COLOR, _SERIES_COLORS[5]]
capacity_atlas = _atlas_panel(capacity_results, capacity_row_labels;
                              cases_as_columns = true)
capacity_price, capacity_sell = _trajectory_panels(capacity_results, capacity_trace_labels, capacity_colors)
capacity_figure = plot(capacity_atlas, capacity_price, capacity_sell;
    layout = @layout([a{0.78h}; b c]), size = (1000, 1450),
    left_margin = 9Plots.mm, right_margin = 3Plots.mm, bottom_margin = 4Plots.mm)
_save_figure(capacity_figure, "Fig5-DealerMarketPanels.pdf")

@info "Saved market-panel atlases" dose_seeds = Int64.(getproperty.(dose_rows, :seed)) capacity_seed
