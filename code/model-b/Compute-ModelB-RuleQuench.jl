# Compute-ModelB-RuleQuench.jl -- paired delayed activation of the contrarian
# rule in an otherwise homogeneous endogenous market.
#
# This campaign supplies the causal experiment missing from the manuscript:
#
#   1. Start every run with the baseline Rule 19280 at every updateable cell.
#   2. Let grid states, price, deviation bands, edge states, and agent books
#      evolve together for a common pre-period.
#   3. After T_PRE complete baseline steps, activate Rule 19286 at an exact
#      fraction f of preselected interior sites, without resetting any state.
#   4. Compare against a paired control in which the same target sites remain
#      dormant through the observed horizon.
#
# The target landscape is drawn before t = 0 in both arms.  Treated and control
# histories therefore coincide bit-for-bit through the quote formed immediately
# after activation; only the subsequent grid update differs.  This is a rule
# quench, not a restart from a separately sampled above-threshold initial state.
#
# Default mode is a modest pilot.  The smoke mode exercises plumbing only;
# full mode increases the seed count and post-quench horizon after the pilot
# establishes that the pre-period is genuinely stable.
#
# Run:
#   julia --project=code code/model-b/Compute-ModelB-RuleQuench.jl
#   RULE_QUENCH_SMOKE=1 julia --project=code code/model-b/Compute-ModelB-RuleQuench.jl
#   RULE_QUENCH_FULL=1  julia --project=code code/model-b/Compute-ModelB-RuleQuench.jl
#
# Writes pilot/smoke/full-tagged summary and thinned-trajectory CSVs under
# code/data/, a diagnostic PDF under code/figs/, and one representative paired
# trajectory with sparse frames as JLD2.

include(joinpath(@__DIR__, "Include.jl"))

const SMOKE = get(ENV, "RULE_QUENCH_SMOKE", "0") == "1" || "--smoke" in ARGS
const FULL  = get(ENV, "RULE_QUENCH_FULL", "0") == "1" || "--full" in ARGS
const PLOT_ONLY = "--plot-only" in ARGS
SMOKE && FULL && error("RULE_QUENCH_SMOKE and RULE_QUENCH_FULL are mutually exclusive")

const MODE = SMOKE ? "Smoke" : FULL ? "Full" : "Pilot"
const GRIDN = SMOKE ? 16 : 64
const T_PRE = SMOKE ? 20 : FULL ? 1000 : 750
const T_POST = SMOKE ? 40 : FULL ? 3000 : 1500
const STEPS = T_PRE + T_POST
const SEEDS = SMOKE ? collect(1:2) : FULL ? collect(1:50) : collect(1:12)
const TARGET_FS = SMOKE ? [0.20] : [0.10, 0.15, 0.20, 0.25]
const TRACE_STRIDE = SMOKE ? 1 : 5
const DISPLAY_PRE = min(T_PRE, 500)

# Canonical endogenous-model settings.  The paired intervention changes only
# the active rule labels; it does not inject cash, reset books, or alter price.
const P0 = 100.0
const INITIAL_CASH = 1000.0
const INITIAL_SHARES = 10

function _quench_config(f::Float64, seed::Int64)
    return build(MyModelBConfiguration, (
        number_of_rows = GRIDN,
        number_of_cols = GRIDN,
        steps = STEPS,
        seed = seed,
        λ = 0.02,
        k = 1.0,
        minority_fraction = f,
        edge_band_spread = 0.5,
        cost_basis_rule = false,
        initial_cash = INITIAL_CASH,
        initial_shares = INITIAL_SHARES,
        P0 = P0,
    ))
end

function _first_post_quench_crossing(series::Vector{Float64}; threshold::Float64 = 0.5)
    i = findfirst(≥(threshold), @view series[(T_PRE + 1):end])
    return isnothing(i) ? 0 : i - 1
end

function _condition_metrics(result::MyModelBSimulationResult)
    pre_window = max(0, T_PRE - min(T_PRE, 250)):T_PRE
    pre_prices = @view result.prices[pre_window .+ 1]
    pre_sell = @view result.sell_fraction[pre_window .+ 1]
    post_prices = @view result.prices[(T_PRE + 1):end]
    post_sell = @view result.sell_fraction[(T_PRE + 1):end]
    p_quench = result.prices[T_PRE + 1]

    return (
        pre_price_log_change = log(last(pre_prices) / first(pre_prices)),
        pre_return_std = std(@view result.log_returns[max(1, first(pre_window) + 1):T_PRE]),
        pre_sell_mean = mean(pre_sell),
        pre_sell_max = maximum(pre_sell),
        pre_sell_range = maximum(pre_sell) - minimum(pre_sell),
        post_price_log_change = log(last(post_prices) / p_quench),
        post_max_drawdown = compute_max_drawdown(collect(post_prices)),
        post_sell_mean = mean(post_sell),
        post_sell_peak = maximum(post_sell),
        post_sell_final = last(post_sell),
        onset_after_quench = _first_post_quench_crossing(result.sell_fraction),
    )
end

function _run_pair(f::Float64, seed::Int64)
    config = _quench_config(f, seed)
    snapshots = Int64[T_PRE - 1, T_PRE, min(STEPS, T_PRE + 100),
                      min(STEPS, T_PRE + 400), STEPS]

    treated = simulate(
        config; snapshot_steps = snapshots,
        minority_population = :interior,
        rule_activation_step = T_PRE + 1,
        verbose = false,
    )
    control = simulate(
        config; snapshot_steps = snapshots,
        minority_population = :interior,
        rule_activation_step = STEPS + 1,
        verbose = false,
    )

    # Activation occurs after X_T_PRE. The next quote is still formed from that
    # common state, and the CA update at step T_PRE+1 is the first state that
    # can differ.
    @assert treated.prices[1:(T_PRE + 2)] == control.prices[1:(T_PRE + 2)]
    @assert treated.sell_fraction[1:(T_PRE + 1)] == control.sell_fraction[1:(T_PRE + 1)]
    @assert treated.frames[T_PRE - 1] == control.frames[T_PRE - 1]
    @assert treated.frames[T_PRE] == control.frames[T_PRE]
    @assert treated.edge_coordinates == control.edge_coordinates
    @assert treated.edge_k == control.edge_k

    tm = _condition_metrics(treated)
    cm = _condition_metrics(control)
    row = (
        target_f = f,
        seed = seed,
        gridn = GRIDN,
        t_pre = T_PRE,
        t_post = T_POST,
        n_target = round(Int, f * (GRIDN - 2)^2),
        pre_price_log_change = cm.pre_price_log_change,
        pre_return_std = cm.pre_return_std,
        pre_sell_mean = cm.pre_sell_mean,
        pre_sell_max = cm.pre_sell_max,
        pre_sell_range = cm.pre_sell_range,
        control_price_log_change = cm.post_price_log_change,
        treated_price_log_change = tm.post_price_log_change,
        delta_price_log_change = tm.post_price_log_change - cm.post_price_log_change,
        control_max_drawdown = cm.post_max_drawdown,
        treated_max_drawdown = tm.post_max_drawdown,
        delta_max_drawdown = tm.post_max_drawdown - cm.post_max_drawdown,
        control_sell_mean = cm.post_sell_mean,
        treated_sell_mean = tm.post_sell_mean,
        delta_sell_mean = tm.post_sell_mean - cm.post_sell_mean,
        control_sell_peak = cm.post_sell_peak,
        treated_sell_peak = tm.post_sell_peak,
        delta_sell_peak = tm.post_sell_peak - cm.post_sell_peak,
        control_sell_final = cm.post_sell_final,
        treated_sell_final = tm.post_sell_final,
        control_onset = cm.onset_after_quench,
        treated_onset = tm.onset_after_quench,
    )

    offsets = collect((-T_PRE):TRACE_STRIDE:T_POST)
    last(offsets) == T_POST || push!(offsets, T_POST)
    traces = NamedTuple[]
    for (condition, result) in (("control", control), ("treated", treated))
        p_quench = result.prices[T_PRE + 1]
        for offset in offsets
            t = T_PRE + offset
            push!(traces, (
                target_f = f,
                seed = seed,
                condition = condition,
                step_since_quench = offset,
                price_relative = result.prices[t + 1] / p_quench,
                sell_fraction = result.sell_fraction[t + 1],
            ))
        end
    end
    return (row = row, traces = traces, treated = treated, control = control)
end

stem = "ModelB-RuleQuench-$(MODE)"
items = [(f = f, seed = seed) for f in TARGET_FS for seed in SEEDS]
if PLOT_ONLY
    summary = CSV.read(joinpath(_PATH_TO_DATA, "$(stem)-Summary.csv"), DataFrame)
    traces = CSV.read(joinpath(_PATH_TO_DATA, "$(stem)-Trajectories.csv"), DataFrame)
    results = nothing
else
    @info "Paired contrarian-rule quench" mode = MODE grid = GRIDN pre = T_PRE post = T_POST pairs = length(items) threads = Threads.nthreads()
    results = Vector{Union{Nothing,NamedTuple}}(nothing, length(items))
    Threads.@threads :dynamic for i in eachindex(items)
        item = items[i]
        results[i] = _run_pair(item.f, item.seed)
    end
    @assert all(!isnothing, results)
    summary = DataFrame([result.row for result in results])
    traces = DataFrame(reduce(vcat, [result.traces for result in results]))
    CSV.write(joinpath(_PATH_TO_DATA, "$(stem)-Summary.csv"), summary)
    CSV.write(joinpath(_PATH_TO_DATA, "$(stem)-Trajectories.csv"), traces)
end

# Report the two questions separately: was the pre-period stable, and did the
# rule quench move the post-period away from its paired all-major control?
for f in TARGET_FS
    sub = summary[summary.target_f .== f, :]
    @info "Rule-quench summary" target_f=f n=nrow(sub) median_pre_abs_log_change=median(abs.(sub.pre_price_log_change)) median_pre_return_std=median(sub.pre_return_std) max_pre_sell=maximum(sub.pre_sell_max) treated_onsets=count(>(0), sub.treated_onset) control_onsets=count(>(0), sub.control_onset) median_delta_sell_peak=median(sub.delta_sell_peak) median_delta_drawdown=median(sub.delta_max_drawdown)
end

# Diagnostic figure: one common dormant-control curve and one treated curve
# per target fraction. Curves are replicate medians with interquartile bands.
xs = sort(unique(traces.step_since_quench))
f_colors = Dict(f => _SERIES_COLORS[mod1(i, length(_SERIES_COLORS))]
                for (i, f) in enumerate(TARGET_FS))

function _trace_quantiles(sub::DataFrame, value::Symbol)
    grouped = combine(
        groupby(sub[:, [:step_since_quench, value]], :step_since_quench),
        value => (x -> quantile(x, 0.25)) => :q25,
        value => median => :q50,
        value => (x -> quantile(x, 0.75)) => :q75,
    )
    sort!(grouped, :step_since_quench)
    return grouped
end

control_trace = traces[(traces.target_f .== first(TARGET_FS)) .&
                       (traces.condition .== "control") .&
                       (traces.step_since_quench .>= -DISPLAY_PRE), :]
price_control = _trace_quantiles(control_trace, :price_relative)
sell_control = _trace_quantiles(control_trace, :sell_fraction)

pA = plot(; xlabel = "Steps since contrarian activation", ylabel = "Price / activation price",
          legend = :topleft, _panel_kw...)
plot!(pA, price_control.step_since_quench, price_control.q50;
      ribbon = (price_control.q50 .- price_control.q25,
                price_control.q75 .- price_control.q50),
      color = :black, fillalpha = 0.10, lw = 2.2, ls = :dash,
      label = "dormant control")

pB = plot(; xlabel = "Steps since contrarian activation", ylabel = "Sell fraction",
          ylims = (0, 1), legend = false, _panel_kw...)
plot!(pB, sell_control.step_since_quench, sell_control.q50;
      ribbon = (sell_control.q50 .- sell_control.q25,
                sell_control.q75 .- sell_control.q50),
      color = :black, fillalpha = 0.10, lw = 2.2, ls = :dash, label = "")

for f in TARGET_FS
    sub = traces[(traces.target_f .== f) .&
                 (traces.condition .== "treated") .&
                 (traces.step_since_quench .>= -DISPLAY_PRE), :]
    pq = _trace_quantiles(sub, :price_relative)
    sq = _trace_quantiles(sub, :sell_fraction)
    label = "activate $(Int(round(100f)))%"
    plot!(pA, pq.step_since_quench, pq.q50;
          ribbon = (pq.q50 .- pq.q25, pq.q75 .- pq.q50),
          color = f_colors[f], fillalpha = 0.08, lw = 2.0, label = label)
    plot!(pB, sq.step_since_quench, sq.q50;
          ribbon = (sq.q50 .- sq.q25, sq.q75 .- sq.q50),
          color = f_colors[f], fillalpha = 0.08, lw = 2.0, label = "")
end
vline!(pA, [0], color = :black, lw = 1.0, ls = :dot, label = "")
vline!(pB, [0], color = :black, lw = 1.0, ls = :dot, label = "")
hline!(pB, [0.5], color = :black, lw = 0.9, ls = :dash, label = "")
_panel_letter!(pA, "A")
_panel_letter!(pB, "B")

# Select one f=0.20 pair nearest the median treated-control peak-Sell effect.
# This deterministic representative supplies spatial context; A and B carry
# the ensemble result.
f_exemplar = 0.20 in TARGET_FS ? 0.20 : first(TARGET_FS)
ex_sub = summary[summary.target_f .== f_exemplar, :]
med_effect = median(ex_sub.delta_sell_peak)
ex_seed = Int64(ex_sub.seed[argmin(abs.(ex_sub.delta_sell_peak .- med_effect))])
exemplar_path = joinpath(_PATH_TO_DATA, "$(stem)-Exemplar.jld2")

if PLOT_ONLY
    isfile(exemplar_path) || error("missing $(exemplar_path); run the full campaign once")
    exemplar = load(exemplar_path)
    @assert Int64(exemplar["seed"]) == ex_seed
    control_frames = exemplar["control_frames"]
    treated_frames = exemplar["treated_frames"]
else
    ex_i = findfirst(i -> items[i].f == f_exemplar && items[i].seed == ex_seed,
                     eachindex(items))
    ex_pair = results[ex_i]
    control_frames = ex_pair.control.frames
    treated_frames = ex_pair.treated.frames
end

function _paired_market_panel(control_frames, treated_frames)
    offsets = Int64[0, 100, 400, T_POST]
    L = GRIDN
    header = 16
    row_gap = 4
    col_gap = 5
    nrows = 2
    ncols = length(offsets)
    height = header + nrows * L + (nrows - 1) * row_gap
    width = ncols * L + (ncols - 1) * col_gap
    canvas = fill(NaN, height, width)

    for (r, frames) in enumerate((control_frames, treated_frames))
        first_row = header + (r - 1) * (L + row_gap) + 1
        last_row = first_row + L - 1
        for (c, offset) in enumerate(offsets)
            first_col = (c - 1) * (L + col_gap) + 1
            last_col = first_col + L - 1
            step = T_PRE + offset
            haskey(frames, step) || error("exemplar frame missing at step $(step)")
            canvas[first_row:last_row, first_col:last_col] .= frames[step]
        end
    end

    panel = heatmap(canvas;
        c = _grid_cgrad(), clims = (0, 2), colorbar = false,
        axis = false, yflip = true, aspect_ratio = :equal,
        xlims = (0.5, width + 0.5), ylims = (0.5, height + 0.5),
        widen = false, framestyle = :none, margin = 0Plots.mm,
        background_color_inside = :white)

    for (c, offset) in enumerate(offsets)
        first_col = (c - 1) * (L + col_gap) + 1
        center = first_col + (L - 1) / 2
        label = offset == 0 ? "activation" : "+$(offset) steps"
        annotate!(panel, center, header / 2,
                  text(label, :black, :center, 11, "helvetica"))
    end
    for (r, label) in enumerate(("dormant control", "activate 20%"))
        first_row = header + (r - 1) * (L + row_gap) + 1
        x0, x1 = 2, 51
        y0, y1 = first_row + 1, first_row + 10
        plot!(panel, Shape([x0, x1, x1, x0], [y0, y0, y1, y1]);
              color = :white, linecolor = :transparent, fillalpha = 0.82,
              label = "")
        annotate!(panel, x0 + 2, (y0 + y1) / 2,
                  text(label, :black, :left, 9, "helvetica"))
    end
    annotate!(panel, 3, header / 2,
              text("C", :black, :left, 14, "helvetica bold"))
    return panel
end

pC = _paired_market_panel(control_frames, treated_frames)
fig = plot(pA, pB, pC;
           layout = @layout([a b; c{0.58h}]), size = (1000, 1000),
           left_margin = 7Plots.mm, right_margin = 3Plots.mm,
           bottom_margin = 4Plots.mm)
figure_path = joinpath(_PATH_TO_FIGS, "Fig-$(stem).pdf")
savefig(fig, figure_path)
if FULL
    cp(figure_path, joinpath(_PATH_TO_FIGS, "Fig1-RuleQuench.pdf"); force = true)
    cp(figure_path, joinpath(_PATH_TO_PAPER_FIGS, "Fig1-RuleQuench.pdf"); force = true)
end

if !PLOT_ONLY
    save(exemplar_path, Dict(
        "target_f" => f_exemplar,
        "seed" => ex_seed,
        "t_pre" => T_PRE,
        "t_post" => T_POST,
        "treated_frames" => ex_pair.treated.frames,
        "control_frames" => ex_pair.control.frames,
        "treated_prices" => ex_pair.treated.prices,
        "control_prices" => ex_pair.control.prices,
        "treated_sell_fraction" => ex_pair.treated.sell_fraction,
        "control_sell_fraction" => ex_pair.control.sell_fraction,
    ))
end

@info "Rule-quench campaign complete" mode=MODE summary_rows=nrow(summary) trajectory_rows=nrow(traces) exemplar_seed=ex_seed
