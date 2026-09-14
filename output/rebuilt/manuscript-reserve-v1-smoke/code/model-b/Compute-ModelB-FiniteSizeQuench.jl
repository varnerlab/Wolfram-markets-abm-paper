# Compute-ModelB-FiniteSizeQuench.jl -- finite-size scaling of the matched
# Model B rule quench under unlimited and constrained trading reservoirs.
#
# This is deliberately a finite-time analysis.  It reports transition curves,
# an ensemble susceptibility, and interpolated pseudocritical crossings f_50(L)
# rather than claiming an equilibrium critical point.
#
# Run modes:
#   julia --project=code -t auto code/model-b/Compute-ModelB-FiniteSizeQuench.jl --smoke
#   julia --project=code -t auto code/model-b/Compute-ModelB-FiniteSizeQuench.jl
#   julia --project=code -t auto code/model-b/Compute-ModelB-FiniteSizeQuench.jl --full

include(joinpath(@__DIR__, "Include.jl"))

const SMOKE = "--smoke" in ARGS
const FULL = "--full" in ARGS
SMOKE && FULL && error("--smoke and --full are mutually exclusive")

const MODE = SMOKE ? "Smoke" : FULL ? "Full" : "Pilot"
const GRID_SIZES = SMOKE ? [16, 24] : FULL ? [32, 48, 64, 96, 128] : [32, 64, 96]
const T_PRE = SMOKE ? 20 : FULL ? 1000 : 500
const T_POST = SMOKE ? 40 : FULL ? 3000 : 1500
const STEPS = T_PRE + T_POST
const SEEDS = SMOKE ? collect(1:2) : FULL ? collect(1:50) : collect(1:10)
const TARGET_FS = SMOKE ? [0.20, 0.25] : FULL ?
    [0.14, 0.15, 0.16, 0.17, 0.175, 0.18, 0.185, 0.19,
     0.20, 0.21, 0.225, 0.25] :
    [0.185, 0.195, 0.20, 0.205, 0.225]
const CAPACITIES = [100.0, 1.0]
const BOUNDARY_MODES = [:endogenous, :hold]
const CONDITIONS = [(capacity = 100.0, boundary_mode = :hold),
                    (capacity = 100.0, boundary_mode = :endogenous),
                    (capacity = 1.0, boundary_mode = :endogenous)]
const FINAL_WINDOW = min(T_POST, 500)

function _config(L::Int64, f::Float64, capacity::Float64, seed::Int64)
    return build(MyModelBConfiguration, (
        number_of_rows = L,
        number_of_cols = L,
        steps = STEPS,
        seed = seed,
        λ = 0.02,
        k = 1.0,
        minority_fraction = f,
        edge_band_spread = 0.5,
        cost_basis_rule = false,
        initial_cash = 1000.0,
        initial_shares = 10,
        P0 = 100.0,
        market_maker_capacity = capacity,
    ))
end

function _first_crossing(x::Vector{Float64})
    i = findfirst(≥(0.5), @view x[(T_PRE + 2):end])
    return isnothing(i) ? 0 : i
end

function _metrics(result::MyModelBSimulationResult, L::Int64)
    final_states = @view result.sell_fraction[(end - FINAL_WINDOW + 1):end]
    post_prices = @view result.prices[(T_PRE + 1):end]
    system_cash = result.total_cash .+ result.market_maker_cash
    system_shares = result.total_shares .+ result.market_maker_inventory
    rejected = sum(@view result.market_maker_rejected_buys[(T_PRE + 1):end]) +
               sum(@view result.market_maker_rejected_sells[(T_PRE + 1):end])
    eligible = sum(@view result.executed_buys[(T_PRE + 1):end]) + sum(@view result.executed_sells[(T_PRE + 1):end]) + rejected
    onset = _first_crossing(result.sell_fraction)
    return (
        onset = onset,
        transitioned = onset > 0,
        final_sell_mean = mean(final_states),
        final_sell_second_moment = mean(abs2, final_states),
        temporal_susceptibility = (L - 2)^2 * var(final_states; corrected = false),
        maximum_drawdown = compute_max_drawdown(collect(post_prices)),
        maker_rejection_fraction = rejected / max(1, eligible),
        cash_conservation_error = maximum(abs.(system_cash .- first(system_cash))),
        share_conservation_error = maximum(abs.(system_shares .- first(system_shares))),
    )
end

function _run_cell(L::Int64, capacity::Float64, boundary_mode::Symbol, seed::Int64)
    control = simulate_repaired(
        _config(L, maximum(TARGET_FS), capacity, seed);
        snapshot_steps = [T_PRE, STEPS],
        minority_population = :interior,
        rule_activation_step = STEPS + 1,
        boundary_mode = boundary_mode,
        verbose = false,
    )
    control_metrics = _metrics(control, L)
    rows = NamedTuple[]

    for f in TARGET_FS
        treated = simulate_repaired(
            _config(L, f, capacity, seed);
            snapshot_steps = [T_PRE, STEPS],
            minority_population = :interior,
            rule_activation_step = T_PRE + 1,
            boundary_mode = boundary_mode,
            verbose = false,
        )
        @assert treated.frames[T_PRE] == control.frames[T_PRE]
        @assert treated.sell_fraction[1:(T_PRE + 1)] ==
                control.sell_fraction[1:(T_PRE + 1)]
        @assert treated.prices[1:(T_PRE + 2)] == control.prices[1:(T_PRE + 2)]
        @assert treated.edge_coordinates == control.edge_coordinates
        @assert treated.edge_k == control.edge_k

        m = _metrics(treated, L)
        push!(rows, (
            gridn = L,
            seed = seed,
            target_f = f,
            market_maker_capacity = capacity,
            boundary_mode = String(boundary_mode),
            t_pre = T_PRE,
            t_post = T_POST,
            control_transitioned = control_metrics.transitioned,
            control_onset = control_metrics.onset,
            transitioned = m.transitioned,
            treated_onset = m.onset,
            final_sell_mean = m.final_sell_mean,
            final_sell_second_moment = m.final_sell_second_moment,
            temporal_susceptibility = m.temporal_susceptibility,
            maximum_drawdown = m.maximum_drawdown,
            maker_rejection_fraction = m.maker_rejection_fraction,
            cash_conservation_error = m.cash_conservation_error,
            share_conservation_error = m.share_conservation_error,
        ))
    end
    return rows
end

cells = [(L = Int64(L), capacity = condition.capacity,
          boundary_mode = condition.boundary_mode, seed = Int64(seed))
         for L in GRID_SIZES for condition in CONDITIONS for seed in SEEDS]
stem = "ModelB-FiniteSizeQuench-$(MODE)"
summary_path = joinpath(_PATH_TO_DATA, "$(stem)-Summary.csv")
checkpoint_dir = joinpath(_PATH_TO_DATA, "$(stem)-Checkpoints")
mkpath(checkpoint_dir)

capacity_token(h::Float64) = isdeepreserve(h) ? "100.0" : replace(string(h), "." => "p")
function _checkpoint_path(cell)
    return joinpath(checkpoint_dir,
                    "L$(cell.L)-h$(capacity_token(cell.capacity))-" *
                    "$(cell.boundary_mode)-seed$(lpad(cell.seed, 3, '0')).csv")
end

const EXPECTED_CELL_ROWS = length(TARGET_FS)
function _valid_checkpoint(cell)
    path = _checkpoint_path(cell)
    isfile(path) || return false
    try
        df = CSV.read(path, DataFrame)
        return nrow(df) == EXPECTED_CELL_ROWS &&
               all(df.gridn .== cell.L) &&
               all(df.seed .== cell.seed) &&
               all(df.market_maker_capacity .== cell.capacity) &&
               all(df.boundary_mode .== String(cell.boundary_mode)) &&
               Set(df.target_f) == Set(TARGET_FS)
    catch
        return false
    end
end

# Only checkpoints created within this frozen clean run may resume.
pending_indices = [i for i in eachindex(cells) if !_valid_checkpoint(cells[i])]
@info("Finite-size rule-quench campaign",
      mode = MODE, sizes = GRID_SIZES, pre = T_PRE, post = T_POST,
      target_fs = TARGET_FS, conditions = CONDITIONS,
      seeds = length(SEEDS), cells = length(cells),
      resumed_cells = length(cells) - length(pending_indices),
      pending_cells = length(pending_indices),
      simulations = length(cells) * (length(TARGET_FS) + 1),
      threads = Threads.nthreads())

done = Threads.Atomic{Int}(length(cells) - length(pending_indices))
progress_every = max(1, cld(length(cells), 10))
Threads.@threads :dynamic for j in eachindex(pending_indices)
    i = pending_indices[j]
    cell = cells[i]
    rows = _run_cell(cell.L, cell.capacity, cell.boundary_mode, cell.seed)
    @assert length(rows) == EXPECTED_CELL_ROWS
    checkpoint_path = _checkpoint_path(cell)
    temporary_path = tempname(checkpoint_dir)
    CSV.write(temporary_path, DataFrame(rows))
    mv(temporary_path, checkpoint_path; force = true)

    completed = Threads.atomic_add!(done, 1) + 1
    (completed % progress_every == 0 || completed == length(cells)) &&
        @info("Finite-size progress", completed = completed, total = length(cells))
end
@assert all(_valid_checkpoint, cells)

summary = reduce(vcat, (CSV.read(_checkpoint_path(cell), DataFrame)
                       for cell in cells))
sort!(summary, [:boundary_mode, :market_maker_capacity, :gridn, :target_f, :seed])

CSV.write(summary_path, summary)

function _ensemble_stats(df::SubDataFrame)
    m = df.final_sell_mean
    N = (first(df.gridn) - 2)^2
    mean_m = mean(m)
    second_m = mean(abs2, m)
    variance_m = second_m - mean_m^2
    return (
        transition_probability = mean(df.transitioned),
        control_transition_probability = mean(df.control_transitioned),
        mean_final_sell = mean_m,
        ensemble_susceptibility = N * max(0.0, variance_m),
        median_temporal_susceptibility = median(df.temporal_susceptibility),
        median_drawdown = median(df.maximum_drawdown),
        median_maker_rejection = median(df.maker_rejection_fraction),
    )
end

group_rows = NamedTuple[]
for df in groupby(summary, [:boundary_mode, :market_maker_capacity, :gridn, :target_f])
    # NamedTuple(grouping keys) is constructed explicitly for stable CSV order.
    s = _ensemble_stats(df)
    push!(group_rows, merge((
        boundary_mode = first(df.boundary_mode),
        market_maker_capacity = first(df.market_maker_capacity),
        gridn = first(df.gridn),
        target_f = first(df.target_f),
    ), s))
end
grouped = DataFrame(group_rows)
sort!(grouped, [:boundary_mode, :market_maker_capacity, :gridn, :target_f])
grouped_path = joinpath(_PATH_TO_DATA, "$(stem)-Grouped.csv")
CSV.write(grouped_path, grouped)

function _crossing_f(f::Vector{Float64}, p::Vector{Float64}, level::Float64)
    order = sortperm(f)
    fs, ps = f[order], p[order]
    for i in 1:(length(fs) - 1)
        ps[i] == level && return fs[i]
        if (ps[i] - level) * (ps[i + 1] - level) ≤ 0 && ps[i + 1] != ps[i]
            return fs[i] + (level - ps[i]) * (fs[i + 1] - fs[i]) /
                   (ps[i + 1] - ps[i])
        end
    end
    ps[end] == level && return fs[end]
    return NaN
end

scaling_rows = NamedTuple[]
for df in groupby(grouped, [:boundary_mode, :market_maker_capacity, :gridn])
    f = collect(df.target_f)
    p = collect(df.transition_probability)
    f25 = _crossing_f(f, p, 0.25)
    f50 = _crossing_f(f, p, 0.50)
    f75 = _crossing_f(f, p, 0.75)
    i_peak = argmax(df.ensemble_susceptibility)
    push!(scaling_rows, (
        boundary_mode = first(df.boundary_mode),
        market_maker_capacity = first(df.market_maker_capacity),
        gridn = first(df.gridn),
        f25 = f25,
        f50 = f50,
        f75 = f75,
        transition_width = (isfinite(f25) && isfinite(f75)) ? f75 - f25 : NaN,
        susceptibility_peak_f = df.target_f[i_peak],
        susceptibility_peak = df.ensemble_susceptibility[i_peak],
    ))
end
scaling = DataFrame(scaling_rows)
scaling_path = joinpath(_PATH_TO_DATA, "$(stem)-Scaling.csv")
CSV.write(scaling_path, scaling)

@assert maximum(summary.cash_conservation_error) < 1.0e-3
@assert maximum(summary.share_conservation_error) == 0

capacity_label(h) = isdeepreserve(h) ? "100" : string(h)
size_colors = Dict(L => cgrad(:viridis, length(GRID_SIZES), categorical = true)[i]
                   for (i, L) in enumerate(GRID_SIZES))
panels = Plots.Plot[]
for (boundary, h) in (("hold", 100.0), ("endogenous", 100.0), ("endogenous", 1.0))
    p = plot(; xlabel = "Activated site fraction",
             ylabel = "Transition probability", ylim = (-0.03, 1.03),
             legend = :bottomright,
             title = "$(boundary), h=$(capacity_label(h))", _panel_kw...)
    for L in GRID_SIZES
        sub = grouped[(grouped.boundary_mode .== boundary) .&
                      (grouped.market_maker_capacity .== h) .&
                      (grouped.gridn .== L), :]
        sort!(sub, :target_f)
        plot!(p, sub.target_f, sub.transition_probability;
              marker = :circle, ms = 3, lw = 1.5,
              color = size_colors[L], label = "L=$(L)")
    end
    push!(panels, p)
end
p4 = plot(; xlabel = "Inverse lattice size, 1/L", ylabel = "f₅₀(L)",
          legend = :best, _panel_kw...)
for (boundary, h, marker) in (("hold", 100.0, :circle),
                              ("endogenous", 100.0, :square),
                              ("endogenous", 1.0, :diamond))
    sub = scaling[(scaling.boundary_mode .== boundary) .&
                  (scaling.market_maker_capacity .== h) .&
                  isfinite.(scaling.f50), :]
    sort!(sub, :gridn)
    plot!(p4, 1.0 ./ sub.gridn, sub.f50; marker = marker, lw = 1.5,
          label = "$(boundary), h=$(capacity_label(h))")
end
push!(panels, p4)

for (i, p) in enumerate(panels)
    _panel_letter!(p, string(Char('A' + i - 1)))
end
fig = plot(panels...; layout = (2, 2), size = (920, 720),
           left_margin = 5Plots.mm, bottom_margin = 4Plots.mm)
figure_path = joinpath(_PATH_TO_FIGS, "Fig-$(stem).pdf")
savefig(fig, figure_path)

@info("Finite-size rule-quench complete",
      summary = summary_path, grouped = grouped_path,
      scaling = scaling_path, figure = figure_path,
      rows = nrow(summary))
