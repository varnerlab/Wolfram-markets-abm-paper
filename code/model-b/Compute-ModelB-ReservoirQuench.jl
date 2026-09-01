# Compute-ModelB-ReservoirQuench.jl -- rule-quench phase diagram for the
# endogenous CA market coupled to an explicit trading reservoir.
#
# The campaign treats the historical execution convention as the h = Inf
# limit of one model family. Finite h is the market maker's symmetric initial
# net capacity per trading agent. The matched `:hold` boundary uses the same
# sampled edge sites, books, denominator, initial grid, and quenched target
# landscape, but prevents price from re-entering the lattice.
#
# Run modes:
#   julia --project=code -t auto code/model-b/Compute-ModelB-ReservoirQuench.jl
#   julia --project=code -t auto code/model-b/Compute-ModelB-ReservoirQuench.jl --smoke
#   julia --project=code -t auto code/model-b/Compute-ModelB-ReservoirQuench.jl --full
#
# The summary is intentionally compact. Detailed spatial instrumentation is
# added only after this screen locates the finite-reservoir regimes.

include(joinpath(@__DIR__, "Include.jl"))

const SMOKE = "--smoke" in ARGS
const FULL = "--full" in ARGS
SMOKE && FULL && error("--smoke and --full are mutually exclusive")

const MODE = SMOKE ? "Smoke" : FULL ? "Full" : "Pilot"
const GRIDN = SMOKE ? 16 : 64
const T_PRE = SMOKE ? 20 : FULL ? 1000 : 500
const T_POST = SMOKE ? 40 : FULL ? 3000 : 1500
const STEPS = T_PRE + T_POST
const SEEDS = SMOKE ? collect(1:2) : FULL ? collect(1:50) : collect(1:10)
const TARGET_FS = SMOKE ? [0.15, 0.25] : FULL ?
    [0.10, 0.15, 0.175, 0.185, 0.19, 0.195, 0.20, 0.205, 0.21, 0.225, 0.25] :
    [0.10, 0.15, 0.175, 0.20, 0.225, 0.25]
const CAPACITIES = SMOKE ? [Inf, 0.0] : [Inf, 10.0, 5.0, 2.0, 1.0, 0.5, 0.1, 0.0]
const BOUNDARY_MODES = [:endogenous, :hold]
const FINAL_WINDOW = min(T_POST, 500)

const P0 = 100.0
const INITIAL_CASH = 1000.0
const INITIAL_SHARES = 10

function _config(f::Float64, capacity::Float64, seed::Int64)
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
        market_maker_capacity = capacity,
    ))
end

function _first_crossing(x::Vector{Float64}; threshold::Float64 = 0.5)
    i = findfirst(≥(threshold), @view x[(T_PRE + 1):end])
    return isnothing(i) ? 0 : i - 1
end

function _post_metrics(result::MyModelBSimulationResult)
    post_states = @view result.sell_fraction[(T_PRE + 1):end]
    post_prices = @view result.prices[(T_PRE + 1):end]
    final_states = @view result.sell_fraction[(end - FINAL_WINDOW + 1):end]
    total_eligible = sum(result.executed_buys) + sum(result.executed_sells) +
                     sum(result.market_maker_rejected_buys) +
                     sum(result.market_maker_rejected_sells)
    total_rejected = sum(result.market_maker_rejected_buys) +
                     sum(result.market_maker_rejected_sells)
    first_reject = findfirst(>(0), result.market_maker_rejected_buys .+
                                  result.market_maker_rejected_sells)
    n_traders = (GRIDN - 2)^2 + length(result.edge_coordinates)
    maker = result.final_market_maker

    return (
        onset = _first_crossing(result.sell_fraction),
        peak_sell = maximum(post_states),
        final_sell_mean = mean(final_states),
        final_sell_var = var(final_states; corrected = false),
        susceptibility = (GRIDN - 2)^2 * var(final_states; corrected = false),
        price_log_change = log(last(post_prices) / first(post_prices)),
        maximum_drawdown = compute_max_drawdown(collect(post_prices)),
        maker_rejection_fraction = total_rejected / max(1, total_eligible),
        first_maker_rejection = isnothing(first_reject) ? 0 : first_reject,
        maker_net_inventory_per_trader =
            (maker.inventory - maker.initial_inventory) / n_traders,
        maker_cash_per_trader = maker.cash / n_traders,
        maker_inventory_per_trader = maker.inventory / n_traders,
        system_cash_error = maximum(abs.(
            result.total_cash .+ result.market_maker_cash .-
            (result.total_cash[1] + result.market_maker_cash[1])
        )),
        system_share_error = maximum(abs.(
            result.total_shares .+ result.market_maker_inventory .-
            (result.total_shares[1] + result.market_maker_inventory[1])
        )),
    )
end

function _run_cell(capacity::Float64, boundary_mode::Symbol, seed::Int64)
    # A dormant target landscape is dynamically independent of target f. Use
    # the largest target to generate the one common control for this cell.
    control = simulate(
        _config(maximum(TARGET_FS), capacity, seed);
        snapshot_steps = [T_PRE, STEPS],
        minority_population = :interior,
        rule_activation_step = STEPS + 1,
        boundary_mode = boundary_mode,
        verbose = false,
    )
    cm = _post_metrics(control)
    rows = NamedTuple[]

    for f in TARGET_FS
        treated = simulate(
            _config(f, capacity, seed);
            snapshot_steps = [T_PRE, STEPS],
            minority_population = :interior,
            rule_activation_step = T_PRE + 1,
            boundary_mode = boundary_mode,
            verbose = false,
        )

        # Common-random-number contract: all histories are identical through
        # X_T_PRE; the next quote is also formed from that common state.
        @assert treated.frames[T_PRE] == control.frames[T_PRE]
        @assert treated.sell_fraction[1:(T_PRE + 1)] ==
                control.sell_fraction[1:(T_PRE + 1)]
        @assert treated.prices[1:(T_PRE + 2)] == control.prices[1:(T_PRE + 2)]
        @assert treated.edge_coordinates == control.edge_coordinates
        @assert treated.edge_k == control.edge_k

        tm = _post_metrics(treated)
        push!(rows, (
            gridn = GRIDN,
            seed = seed,
            target_f = f,
            market_maker_capacity = capacity,
            boundary_mode = String(boundary_mode),
            t_pre = T_PRE,
            t_post = T_POST,
            control_onset = cm.onset,
            treated_onset = tm.onset,
            transitioned = tm.onset > 0,
            control_peak_sell = cm.peak_sell,
            treated_peak_sell = tm.peak_sell,
            control_final_sell_mean = cm.final_sell_mean,
            treated_final_sell_mean = tm.final_sell_mean,
            control_susceptibility = cm.susceptibility,
            treated_susceptibility = tm.susceptibility,
            control_price_log_change = cm.price_log_change,
            treated_price_log_change = tm.price_log_change,
            control_maximum_drawdown = cm.maximum_drawdown,
            treated_maximum_drawdown = tm.maximum_drawdown,
            control_maker_rejection_fraction = cm.maker_rejection_fraction,
            treated_maker_rejection_fraction = tm.maker_rejection_fraction,
            treated_first_maker_rejection = tm.first_maker_rejection,
            treated_maker_net_inventory_per_trader = tm.maker_net_inventory_per_trader,
            treated_maker_cash_per_trader = tm.maker_cash_per_trader,
            treated_maker_inventory_per_trader = tm.maker_inventory_per_trader,
            system_cash_error = tm.system_cash_error,
            system_share_error = tm.system_share_error,
        ))
    end
    return rows
end

cells = [(capacity = h, boundary_mode = b, seed = Int64(seed))
         for h in CAPACITIES for b in BOUNDARY_MODES for seed in SEEDS]
@info("Reservoir rule-quench screen",
      mode = MODE, grid = GRIDN, pre = T_PRE, post = T_POST,
      capacities = CAPACITIES, target_fs = TARGET_FS, seeds = length(SEEDS),
      cells = length(cells), threads = Threads.nthreads())

cell_results = Vector{Union{Nothing,Vector{NamedTuple}}}(nothing, length(cells))
done = Threads.Atomic{Int}(0)
progress_every = max(1, cld(length(cells), 10))
Threads.@threads :dynamic for i in eachindex(cells)
    cell = cells[i]
    cell_results[i] = _run_cell(cell.capacity, cell.boundary_mode, cell.seed)
    completed = Threads.atomic_add!(done, 1) + 1
    (completed % progress_every == 0 || completed == length(cells)) &&
        @info("Reservoir progress", completed = completed, total = length(cells))
end
@assert all(!isnothing, cell_results)
summary = DataFrame(reduce(vcat, cell_results))
sort!(summary, [:boundary_mode, :market_maker_capacity, :target_f, :seed])

stem = "ModelB-ReservoirQuench-$(MODE)"
summary_path = joinpath(_PATH_TO_DATA, "$(stem)-Summary.csv")
CSV.write(summary_path, summary)

grouped = combine(
    groupby(summary, [:boundary_mode, :market_maker_capacity, :target_f]),
    :transitioned => mean => :transition_probability,
    :treated_onset => (x -> begin
        y = x[x .> 0]
        isempty(y) ? NaN : median(y)
    end) => :median_onset,
    :treated_maximum_drawdown => median => :median_drawdown,
    :treated_final_sell_mean => median => :median_final_sell,
    :treated_susceptibility => median => :median_susceptibility,
    :treated_maker_rejection_fraction => median => :median_rejection_fraction,
    :treated_maker_net_inventory_per_trader => median => :median_net_inventory,
)
grouped_path = joinpath(_PATH_TO_DATA, "$(stem)-Grouped.csv")
CSV.write(grouped_path, grouped)

@assert maximum(summary.system_cash_error) < 1.0e-5
@assert maximum(summary.system_share_error) == 0
for row in eachrow(grouped)
    @info("Reservoir cell",
          boundary = row.boundary_mode, h = row.market_maker_capacity,
          f = row.target_f, probability = row.transition_probability,
          onset = row.median_onset, drawdown = row.median_drawdown,
          rejection = row.median_rejection_fraction)
end

capacity_labels = Dict(h => isinf(h) ? "∞" : string(h) for h in CAPACITIES)
capacity_colors = Dict(h => cgrad(:viridis, length(CAPACITIES), categorical = true)[i]
                       for (i, h) in enumerate(reverse(CAPACITIES)))

panels = Plots.Plot[]
for boundary in ("endogenous", "hold")
    sub = grouped[grouped.boundary_mode .== boundary, :]
    p = plot(; xlabel = "Activated contrarian fraction",
             ylabel = "Transition probability",
             ylim = (-0.03, 1.03), legend = :bottomright,
             title = boundary == "endogenous" ? "Endogenous boundary" : "Held boundary",
             _panel_kw...)
    for h in CAPACITIES
        s = sub[sub.market_maker_capacity .== h, :]
        sort!(s, :target_f)
        plot!(p, s.target_f, s.transition_probability;
              marker = :circle, ms = 3, lw = 1.5,
              color = capacity_colors[h], label = "h=$(capacity_labels[h])")
    end
    push!(panels, p)
end

for metric in (:median_drawdown, :median_rejection_fraction)
    ylabel = metric == :median_drawdown ? "Median maximum drawdown" :
                                          "Median maker rejection fraction"
    p = plot(; xlabel = "Activated contrarian fraction", ylabel = ylabel,
             legend = false, _panel_kw...)
    sub = grouped[grouped.boundary_mode .== "endogenous", :]
    for h in CAPACITIES
        s = sub[sub.market_maker_capacity .== h, :]
        sort!(s, :target_f)
        plot!(p, s.target_f, s[!, metric]; marker = :circle, ms = 3, lw = 1.5,
              color = capacity_colors[h], label = "")
    end
    push!(panels, p)
end

for (i, p) in enumerate(panels)
    _panel_letter!(p, string(Char('A' + i - 1)))
end
fig = plot(panels...; layout = (2, 2), size = (920, 720),
           left_margin = 5Plots.mm, bottom_margin = 4Plots.mm)
figure_path = joinpath(_PATH_TO_FIGS, "Fig-$(stem).pdf")
savefig(fig, figure_path)

@info("Reservoir rule-quench complete",
      summary = summary_path, grouped = grouped_path,
      figure = figure_path, rows = nrow(summary))
