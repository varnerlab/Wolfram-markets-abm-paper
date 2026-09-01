# Compute-ModelB-BalanceSheetQuench.jl -- matched balance-sheet interventions
# at the rule quench in the explicit-reservoir Model B family.
#
# Every arm first evolves for T_PRE steps with the contrarian landscape dormant.
# At step T_PRE + 1 the same preselected contrarian rules are activated and the
# agents' cash and share inventories are independently rescaled.  Thus all nine
# cash x inventory arms share an exact pre-intervention trajectory.  Crossing
# those arms with h = Inf and finite market-maker capacities separates trader
# funding, trader sell inventory, and counterparty capacity.
#
# The :hold arm is an exact causal null for lattice outcomes: balance-sheet
# changes may alter executions and prices but cannot re-enter the CA boundary.
#
# Run modes:
#   julia --project=code -t auto code/model-b/Compute-ModelB-BalanceSheetQuench.jl --smoke
#   julia --project=code -t auto code/model-b/Compute-ModelB-BalanceSheetQuench.jl
#   julia --project=code -t auto code/model-b/Compute-ModelB-BalanceSheetQuench.jl --full

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
const TARGET_FS = SMOKE ? [0.20] : FULL ? [0.17, 0.175, 0.18, 0.185] :
                                           [0.195, 0.20, 0.205]
const CAPACITIES = SMOKE ? [Inf, 1.0] : [Inf, 1.0, 0.1]
const BOUNDARY_MODES = [:endogenous, :hold]

# Put the neutral arm first so it is available as the within-cell reference.
const CASH_FACTORS = [1.0, 0.1, 10.0]
const SHARE_FACTORS = [1.0, 0.1, 10.0]
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

function _intervention(cash_factor::Float64, share_factor::Float64)
    return function (t, books)
        t == T_PRE + 1 || return nothing
        cash_factor == 1.0 || (books.cash .*= cash_factor)
        if share_factor != 1.0
            books.shares .= round.(Int64, books.shares .* share_factor)
        end
        return nothing
    end
end

function _first_crossing(x::Vector{Float64}; threshold::Float64 = 0.5)
    i = findfirst(≥(threshold), @view x[(T_PRE + 1):end])
    return isnothing(i) ? 0 : i - 1
end

function _constant_error(x::AbstractVector)
    isempty(x) && return 0.0
    return maximum(abs.(x .- first(x)))
end

function _metrics(result::MyModelBSimulationResult)
    post_states = @view result.sell_fraction[(T_PRE + 1):end]
    post_prices = @view result.prices[(T_PRE + 1):end]
    final_states = @view result.sell_fraction[(end - FINAL_WINDOW + 1):end]

    buy_total = sum(result.executed_buys) + sum(result.suppressed_buys) +
                sum(result.market_maker_rejected_buys)
    sell_total = sum(result.executed_sells) + sum(result.suppressed_sells) +
                 sum(result.market_maker_rejected_sells)
    eligible_total = sum(result.executed_buys) + sum(result.executed_sells) +
                     sum(result.market_maker_rejected_buys) +
                     sum(result.market_maker_rejected_sells)
    rejected_total = sum(result.market_maker_rejected_buys) +
                     sum(result.market_maker_rejected_sells)

    system_cash = result.total_cash .+ result.market_maker_cash
    system_shares = result.total_shares .+ result.market_maker_inventory
    pre_range = 1:(T_PRE + 1)
    post_range = (T_PRE + 2):length(system_cash)

    return (
        onset = _first_crossing(result.sell_fraction),
        peak_sell = maximum(post_states),
        final_sell_mean = mean(final_states),
        susceptibility = (GRIDN - 2)^2 * var(final_states; corrected = false),
        price_log_change = log(last(post_prices) / first(post_prices)),
        maximum_drawdown = compute_max_drawdown(collect(post_prices)),
        buy_suppression_fraction = sum(result.suppressed_buys) / max(1, buy_total),
        sell_suppression_fraction = sum(result.suppressed_sells) / max(1, sell_total),
        maker_rejection_fraction = rejected_total / max(1, eligible_total),
        mean_abs_imbalance = mean(abs, @view result.net_imbalance[(T_PRE + 1):end]),
        pre_cash_conservation_error = _constant_error(@view system_cash[pre_range]),
        post_cash_conservation_error = _constant_error(@view system_cash[post_range]),
        pre_share_conservation_error = _constant_error(@view system_shares[pre_range]),
        post_share_conservation_error = _constant_error(@view system_shares[post_range]),
    )
end

function _run_cell(capacity::Float64, boundary_mode::Symbol, seed::Int64)
    rows = NamedTuple[]
    common_reference = nothing

    for f in TARGET_FS
        neutral = nothing
        for cash_factor in CASH_FACTORS, share_factor in SHARE_FACTORS
            result = simulate(
                _config(f, capacity, seed);
                snapshot_steps = [T_PRE, STEPS],
                intervention = _intervention(cash_factor, share_factor),
                minority_population = :interior,
                rule_activation_step = T_PRE + 1,
                boundary_mode = boundary_mode,
                verbose = false,
            )

            # All balance-sheet arms and target fractions share exactly the
            # same stable prehistory within a capacity/boundary/seed cell.
            reference = isnothing(neutral) ? common_reference : neutral
            if !isnothing(reference)
                @assert result.frames[T_PRE] == reference.frames[T_PRE]
                @assert result.sell_fraction[1:(T_PRE + 1)] ==
                        reference.sell_fraction[1:(T_PRE + 1)]
                @assert result.prices[1:(T_PRE + 1)] ==
                        reference.prices[1:(T_PRE + 1)]
                @assert result.edge_coordinates == reference.edge_coordinates
                @assert result.edge_k == reference.edge_k
            end

            if cash_factor == 1.0 && share_factor == 1.0
                neutral = result
                isnothing(common_reference) && (common_reference = result)
            elseif boundary_mode == :hold
                # With price feedback severed, finance cannot change the CA.
                @assert result.sell_fraction == neutral.sell_fraction
                @assert result.frames[STEPS] == neutral.frames[STEPS]
            end

            m = _metrics(result)
            push!(rows, (
                gridn = GRIDN,
                seed = seed,
                target_f = f,
                market_maker_capacity = capacity,
                boundary_mode = String(boundary_mode),
                cash_factor = cash_factor,
                share_factor = share_factor,
                t_pre = T_PRE,
                t_post = T_POST,
                transitioned = m.onset > 0,
                treated_onset = m.onset,
                peak_sell = m.peak_sell,
                final_sell_mean = m.final_sell_mean,
                susceptibility = m.susceptibility,
                price_log_change = m.price_log_change,
                maximum_drawdown = m.maximum_drawdown,
                buy_suppression_fraction = m.buy_suppression_fraction,
                sell_suppression_fraction = m.sell_suppression_fraction,
                maker_rejection_fraction = m.maker_rejection_fraction,
                mean_abs_imbalance = m.mean_abs_imbalance,
                pre_cash_conservation_error = m.pre_cash_conservation_error,
                post_cash_conservation_error = m.post_cash_conservation_error,
                pre_share_conservation_error = m.pre_share_conservation_error,
                post_share_conservation_error = m.post_share_conservation_error,
            ))
        end
    end
    return rows
end

cells = [(capacity = h, boundary_mode = b, seed = Int64(seed))
         for h in CAPACITIES for b in BOUNDARY_MODES for seed in SEEDS]
stem = "ModelB-BalanceSheetQuench-$(MODE)"
summary_path = joinpath(_PATH_TO_DATA, "$(stem)-Summary.csv")
checkpoint_dir = joinpath(_PATH_TO_DATA, "$(stem)-Checkpoints")
mkpath(checkpoint_dir)

capacity_token(h::Float64) = isinf(h) ? "Inf" : replace(string(h), "." => "p")
function _checkpoint_path(cell)
    return joinpath(checkpoint_dir,
                    "h$(capacity_token(cell.capacity))-$(cell.boundary_mode)-" *
                    "seed$(lpad(cell.seed, 3, '0')).csv")
end

const EXPECTED_CELL_ROWS = length(TARGET_FS) * length(CASH_FACTORS) *
                           length(SHARE_FACTORS)
function _valid_checkpoint(cell)
    path = _checkpoint_path(cell)
    isfile(path) || return false
    try
        df = CSV.read(path, DataFrame)
        return nrow(df) == EXPECTED_CELL_ROWS &&
               all(df.seed .== cell.seed) &&
               all(df.market_maker_capacity .== cell.capacity) &&
               all(df.boundary_mode .== String(cell.boundary_mode)) &&
               Set(df.target_f) == Set(TARGET_FS) &&
               Set(df.cash_factor) == Set(CASH_FACTORS) &&
               Set(df.share_factor) == Set(SHARE_FACTORS)
    catch
        return false
    end
end

pending_indices = [i for i in eachindex(cells) if !_valid_checkpoint(cells[i])]
@info("Balance-sheet rule-quench campaign",
      mode = MODE, grid = GRIDN, pre = T_PRE, post = T_POST,
      target_fs = TARGET_FS, capacities = CAPACITIES,
      cash_factors = CASH_FACTORS, share_factors = SHARE_FACTORS,
      seeds = length(SEEDS), cells = length(cells),
      resumed_cells = length(cells) - length(pending_indices),
      pending_cells = length(pending_indices),
      simulations = length(cells) * length(TARGET_FS) *
                    length(CASH_FACTORS) * length(SHARE_FACTORS),
      threads = Threads.nthreads())

done = Threads.Atomic{Int}(length(cells) - length(pending_indices))
progress_every = max(1, cld(length(cells), 10))
Threads.@threads :dynamic for j in eachindex(pending_indices)
    i = pending_indices[j]
    cell = cells[i]
    rows = _run_cell(cell.capacity, cell.boundary_mode, cell.seed)
    @assert length(rows) == EXPECTED_CELL_ROWS

    # One file per independent cell makes a completed cell restart-safe.  A
    # temporary path is renamed only after CSV.write returns, so an interrupted
    # write is never mistaken for a valid checkpoint on the next invocation.
    checkpoint_path = _checkpoint_path(cell)
    temporary_path = tempname(checkpoint_dir)
    CSV.write(temporary_path, DataFrame(rows))
    mv(temporary_path, checkpoint_path; force = true)

    completed = Threads.atomic_add!(done, 1) + 1
    (completed % progress_every == 0 || completed == length(cells)) &&
        @info("Balance-sheet progress", completed = completed, total = length(cells))
end
@assert all(_valid_checkpoint, cells)

# Reconstruct the canonical table from independently completed cells.  Its
# sorted form is identical whether the campaign ran once or resumed after an
# interruption.
summary = reduce(vcat, (CSV.read(_checkpoint_path(cell), DataFrame)
                       for cell in cells))
sort!(summary, [:boundary_mode, :market_maker_capacity, :target_f,
                :cash_factor, :share_factor, :seed])

CSV.write(summary_path, summary)

# Same-seed contrasts relative to the neutral (cash x1, shares x1) quench.
neutral_lookup = Dict{Tuple{String,Float64,Float64,Int64},NamedTuple}()
for row in eachrow(summary)
    row.cash_factor == 1.0 && row.share_factor == 1.0 || continue
    key = (row.boundary_mode, row.market_maker_capacity, row.target_f, row.seed)
    neutral_lookup[key] = NamedTuple(row)
end

contrast_rows = NamedTuple[]
for row in eachrow(summary)
    key = (row.boundary_mode, row.market_maker_capacity, row.target_f, row.seed)
    ref = neutral_lookup[key]
    push!(contrast_rows, (
        boundary_mode = row.boundary_mode,
        market_maker_capacity = row.market_maker_capacity,
        target_f = row.target_f,
        cash_factor = row.cash_factor,
        share_factor = row.share_factor,
        seed = row.seed,
        transition_change = Int(row.transitioned) - Int(ref.transitioned),
        onset_change = (row.treated_onset > 0 && ref.treated_onset > 0) ?
                       row.treated_onset - ref.treated_onset : NaN,
        final_sell_change = row.final_sell_mean - ref.final_sell_mean,
        drawdown_change = row.maximum_drawdown - ref.maximum_drawdown,
        buy_suppression_change = row.buy_suppression_fraction -
                                 ref.buy_suppression_fraction,
        sell_suppression_change = row.sell_suppression_fraction -
                                  ref.sell_suppression_fraction,
        maker_rejection_change = row.maker_rejection_fraction -
                                 ref.maker_rejection_fraction,
    ))
end
contrasts = DataFrame(contrast_rows)
contrast_path = joinpath(_PATH_TO_DATA, "$(stem)-Contrasts.csv")
CSV.write(contrast_path, contrasts)

grouped = combine(
    groupby(summary, [:boundary_mode, :market_maker_capacity, :target_f,
                      :cash_factor, :share_factor]),
    :transitioned => mean => :transition_probability,
    :treated_onset => (x -> begin
        y = x[x .> 0]
        isempty(y) ? NaN : median(y)
    end) => :median_onset,
    :final_sell_mean => median => :median_final_sell,
    :susceptibility => median => :median_susceptibility,
    :maximum_drawdown => median => :median_drawdown,
    :buy_suppression_fraction => median => :median_buy_suppression,
    :sell_suppression_fraction => median => :median_sell_suppression,
    :maker_rejection_fraction => median => :median_maker_rejection,
)
grouped_path = joinpath(_PATH_TO_DATA, "$(stem)-Grouped.csv")
CSV.write(grouped_path, grouped)

@assert maximum(summary.pre_cash_conservation_error) < 1.0e-5
@assert maximum(summary.post_cash_conservation_error) < 1.0e-5
@assert maximum(summary.pre_share_conservation_error) == 0
@assert maximum(summary.post_share_conservation_error) == 0

# Diagnostic: endogenous transition-probability heatmaps at the center f.
f_plot = TARGET_FS[cld(length(TARGET_FS), 2)]
panels = Plots.Plot[]
for h in CAPACITIES
    sub = grouped[(grouped.boundary_mode .== "endogenous") .&
                  (grouped.market_maker_capacity .== h) .&
                  (grouped.target_f .== f_plot), :]
    z = [only(sub[(sub.share_factor .== sf) .&
                  (sub.cash_factor .== cf), :transition_probability])
         for sf in SHARE_FACTORS, cf in CASH_FACTORS]
    h_label = isinf(h) ? "∞" : string(h)
    p = heatmap(CASH_FACTORS, SHARE_FACTORS, z;
                xlabel = "Cash multiplier", ylabel = "Share multiplier",
                title = "h=$(h_label), f=$(f_plot)",
                clims = (0, 1), color = :viridis, colorbar = true,
                xscale = :log10, yscale = :log10, _panel_kw...)
    push!(panels, p)
end
for (i, p) in enumerate(panels)
    _panel_letter!(p, string(Char('A' + i - 1)))
end
fig = plot(panels...; layout = (1, length(panels)),
           size = (370 * length(panels), 350),
           left_margin = 5Plots.mm, bottom_margin = 4Plots.mm)
figure_path = joinpath(_PATH_TO_FIGS, "Fig-$(stem).pdf")
savefig(fig, figure_path)

@info("Balance-sheet rule-quench complete",
      summary = summary_path, grouped = grouped_path,
      contrasts = contrast_path, figure = figure_path,
      rows = nrow(summary))
