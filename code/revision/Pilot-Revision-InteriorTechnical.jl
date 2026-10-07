# Pilot-Revision-InteriorTechnical.jl -- pilot of two model variants raised by
# the 2026-10-02 simulated review (peer-review.md):
#
#   A. Lazy revision: each interior trader adopts its rule output with
#      probability alpha per step and otherwise keeps its intention. alpha = 1
#      is the synchronous update, whose center-excluded neighbor sum splits the
#      grid into two non-interacting checkerboard halves.
#   B. Interior technical traders: band-rule traders on a fraction rho of
#      interior cells, in addition to the edge ring, so price feedback is not
#      confined to the boundary.
#
# Twenty starting markets per condition, L = 64, 1,000 baseline steps, 3,000
# post-switch steps, reserve clearing. Each starting market and condition has
# one no-switch control shared by its fractions, as in the rebuild drivers.
# Results go to output/pilots/revision-interior-technical/ (not manuscript data).
#
# Run: julia --project=code -t auto code/revision/Pilot-Revision-InteriorTechnical.jl [--smoke | --extend]
#   --extend reruns the dense interior conditions at higher fractions, because
#   active interior technical traders moved the crossover above 0.25.

using Random, Statistics, DataFrames, CSV, ProgressMeter

const _SRC = joinpath(@__DIR__, "..", "src")
include(joinpath(_SRC, "Types.jl"))
include(joinpath(_SRC, "Factory.jl"))
include(joinpath(_SRC, "Wolfram.jl"))
include(joinpath(_SRC, "Compute.jl"))
include(joinpath(_SRC, "Simulate.jl"))

const L = 64
const PRE = 1000
const POST = 3000
const STEPS = PRE + POST
const SMOKE = "--smoke" in ARGS
const EXTEND = "--extend" in ARGS
const SEEDS = SMOKE ? (1:1) : (1:20)
const OUT = joinpath(@__DIR__, "..", "..", "output", "pilots", "revision-interior-technical")

# Fractions bracket each variant's crossover (from a standalone held-only pilot).
const LAZY_FRACTIONS = Dict(
    1.0  => [0.15, 0.175, 0.185, 0.20, 0.225],
    0.95 => [0.20, 0.225, 0.25, 0.275, 0.30],
    0.9  => [0.25, 0.275, 0.30, 0.325, 0.35],
    0.75 => [0.30, 0.35, 0.375, 0.40, 0.45],
    0.5  => [0.35, 0.40, 0.425, 0.45, 0.50],
)
const TECHNICAL_FRACTIONS = [0.15, 0.175, 0.185, 0.20, 0.225, 0.25]
const SAME_COUNT_AS_EDGE = 63 / 62^2   # 63 edge technical traders at L = 64
const EXTENDED_FRACTIONS = [0.25, 0.30, 0.35, 0.40, 0.50, 0.60]

function pilot_config(f::Float64, h::Float64, seed::Int64)
    build(MyModelBConfiguration, (
        number_of_rows = L, number_of_cols = L, steps = STEPS, seed = seed,
        λ = 0.02, k = 1.0, minority_fraction = f, edge_band_spread = 0.5,
        cost_basis_rule = false, initial_cash = 1000.0, initial_shares = 10,
        P0 = 100.0, market_maker_capacity = h,
    ))
end

# The same per-run checks as the rebuild's simulate_repaired, without its ledger.
function checked_run(config; kwargs...)
    r = simulate(config; clearing = :reserve, minority_population = :interior,
                 snapshot_steps = [PRE, STEPS], verbose = false, kwargs...)
    cash = r.total_cash .+ r.market_maker_cash
    shares = r.total_shares .+ r.market_maker_inventory
    @assert maximum(abs.(cash .- cash[1])) < max(1e-5, abs(cash[1]) * 1e-11)
    @assert all(==(shares[1]), shares)
    @assert all(isfinite, r.prices) && all(>(0), r.prices)
    @assert minimum(r.final_books.cash) >= -1e-9 && minimum(r.final_books.shares) >= 0
    if config.market_maker_capacity > 0
        product = r.market_maker_cash .* r.market_maker_inventory
        @assert maximum(abs.(product ./ product[1] .- 1)) < 1e-9
    else
        @assert all(==(config.P0), r.prices)
    end
    return r
end

# Sell fractions of the two checkerboard halves in the final grid, over
# interior cells that are not technical traders.
function half_gap(grid, technical::Set{Tuple{Int64,Int64}})
    sells = [Int[], Int[]]
    for r in 2:L-1, c in 2:L-1
        (r, c) in technical && continue
        push!(sells[iseven(r + c) ? 1 : 2], grid[r, c] == 2)
    end
    return abs(mean(sells[1]) - mean(sells[2]))
end

function run_metrics(r, technical)
    onset = something(findfirst(≥(0.5), @view r.sell_fraction[(PRE + 2):end]), 0)
    return (
        onset = onset,
        final_sell_mean = mean(@view r.sell_fraction[(end - 499):end]),
        baseline_sell_mean = mean(@view r.sell_fraction[(PRE - 248):(PRE + 1)]),
        maximum_drawdown = compute_max_drawdown(r.prices[(PRE + 1):end]),
        half_gap = half_gap(r.frames[STEPS], technical),
    )
end

# Fraction of non-technical interior traders with at least one technical
# neighbor (edge or interior): how far price information reaches directly.
function technical_reach(layout)
    technical = Set(vcat(layout.edge_coordinates, layout.interior_technical))
    interior = Set(layout.interior_technical)
    reached = 0
    counted = 0
    for r in 2:L-1, c in 2:L-1
        (r, c) in interior && continue
        counted += 1
        reached += any(n -> n in technical, ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)))
    end
    return reached / counted
end

function run_cell(cell)
    fractions = cell.fractions
    control_config = pilot_config(maximum(fractions), cell.h, cell.seed)
    options = (boundary_mode = cell.boundary, revision_probability = cell.alpha,
               interior_technical_fraction = cell.rho)
    layout = market_layout(control_config; minority_population = :interior,
                           interior_technical_fraction = cell.rho)
    technical = Set(layout.interior_technical)
    reach = technical_reach(layout)
    control = checked_run(control_config; rule_activation_step = STEPS + 1, options...)
    cm = run_metrics(control, technical)
    rows = NamedTuple[]
    for f in fractions
        switched = checked_run(pilot_config(f, cell.h, cell.seed);
                               rule_activation_step = PRE + 1, options...)
        @assert switched.frames[PRE] == control.frames[PRE]
        @assert switched.sell_fraction[1:(PRE + 1)] == control.sell_fraction[1:(PRE + 1)]
        @assert switched.prices[1:(PRE + 2)] == control.prices[1:(PRE + 2)]
        sm = run_metrics(switched, technical)
        push!(rows, (
            experiment = cell.experiment, alpha = cell.alpha, rho = cell.rho,
            n_interior_technical = length(technical), technical_reach = reach,
            h = cell.h, boundary = String(cell.boundary), seed = cell.seed, f = f,
            n_switched = round(Int, f * (L - 2)^2),
            onset = sm.onset, majority = sm.onset > 0,
            final_sell_mean = sm.final_sell_mean, baseline_sell_mean = sm.baseline_sell_mean,
            maximum_drawdown = sm.maximum_drawdown, half_gap = sm.half_gap,
            control_onset = cm.onset, control_final_sell_mean = cm.final_sell_mean,
            control_maximum_drawdown = cm.maximum_drawdown,
        ))
    end
    return rows
end

function extended_cells()
    cells = NamedTuple[]
    for seed in SEEDS, rho in (0.05, 0.10),
        (h, boundary) in ((100.0, :hold), (1.0, :endogenous), (100.0, :endogenous))
        push!(cells, (experiment = "interior", alpha = 1.0, rho = rho, h = h,
                      boundary = boundary, seed = seed, fractions = EXTENDED_FRACTIONS))
    end
    return cells
end

function pilot_cells()
    cells = NamedTuple[]
    for seed in SEEDS
        for (alpha, fractions) in LAZY_FRACTIONS
            push!(cells, (experiment = "lazy", alpha = alpha, rho = 0.0, h = 100.0,
                          boundary = :hold, seed = seed, fractions = fractions))
        end
        for h in (1.0, 100.0)
            push!(cells, (experiment = "lazy", alpha = 0.9, rho = 0.0, h = h,
                          boundary = :endogenous, seed = seed,
                          fractions = LAZY_FRACTIONS[0.9]))
        end
        for rho in (0.0, SAME_COUNT_AS_EDGE, 0.05, 0.10),
            (h, boundary) in ((100.0, :hold), (1.0, :endogenous), (100.0, :endogenous))
            push!(cells, (experiment = "interior", alpha = 1.0, rho = rho, h = h,
                          boundary = boundary, seed = seed,
                          fractions = TECHNICAL_FRACTIONS))
        end
    end
    return cells
end

cells = EXTEND ? extended_cells() : pilot_cells()
@info("Pilot", cells = length(cells),
      simulations = sum(length(c.fractions) + 1 for c in cells),
      threads = Threads.nthreads())
results = Vector{Vector{NamedTuple}}(undef, length(cells))
progress = Progress(length(cells); desc = "Pilot: ")
Threads.@threads :dynamic for i in eachindex(cells)
    results[i] = run_cell(cells[i])
    next!(progress)
end
summary = DataFrame(reduce(vcat, results))
sort!(summary, [:experiment, :alpha, :rho, :boundary, :h, :f, :seed])
mkpath(OUT)
name = SMOKE ? "Pilot-Summary-Smoke.csv" : EXTEND ? "Pilot-Summary-Extended.csv" : "Pilot-Summary.csv"
path = joinpath(OUT, name)
CSV.write(path, summary)
@info("Wrote", path = path, rows = nrow(summary))
