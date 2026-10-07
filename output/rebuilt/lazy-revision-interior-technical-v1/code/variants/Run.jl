# Run.jl -- execute or resume the frozen manifest of the lazy-revision and
# interior-technical study. One group is one condition and starting market:
# a no-switch control followed by every switched fraction, written as an
# atomic checkpoint after the common-history checks pass.
include("Include.jl")

length(ARGS) == 1 || error("provide the frozen study directory")
const STUDY = abspath(ARGS[1])
const JOBS = CSV.read(joinpath(STUDY, "Manifest.csv"), DataFrame;
    types = Dict(c => String for c in (:group, :role, :experiment, :condition,
                                       :rho_label, :boundary)))
const WRITE_LOCK = ReentrantLock()
const COMPLETED = Threads.Atomic{Int}(0)
const FINAL_WINDOW = 500

array_digest(x) = bytes2hex(sha256(reinterpret(UInt8, vec(x))))

function variant_config(job)
    build(MyModelBConfiguration, (
        number_of_rows = Int(job.L), number_of_cols = Int(job.L),
        steps = Int(job.pre) + Int(job.post), seed = Int(job.seed),
        λ = 0.02, k = 1.0, minority_fraction = Float64(job.f), edge_band_spread = 0.5,
        cost_basis_rule = false, initial_cash = 1000.0, initial_shares = 10,
        P0 = 100.0, market_maker_capacity = Float64(job.h),
    ))
end

# The same per-run checks as the manuscript rebuild's simulate_repaired.
function checked_run(config, job)
    pre, steps = Int(job.pre), config.steps
    late = unique(vcat(collect(max(pre + 1, steps - 400):100:steps), steps))
    r = simulate(config; clearing = :reserve, minority_population = :interior,
        boundary_mode = Symbol(job.boundary),
        rule_activation_step = job.role == "control" ? steps + 1 : pre + 1,
        revision_probability = Float64(job.alpha),
        interior_technical_fraction = Float64(job.rho),
        snapshot_steps = vcat(pre, late), verbose = false)
    cash = r.total_cash .+ r.market_maker_cash
    shares = r.total_shares .+ r.market_maker_inventory
    cash_error = maximum(abs.(cash .- cash[1]))
    @assert cash_error < max(1e-5, abs(cash[1]) * 1e-11)
    @assert all(==(shares[1]), shares)
    @assert all(isfinite, r.prices) && all(>(0), r.prices)
    @assert minimum(r.final_books.cash) >= -1e-9 && minimum(r.final_books.shares) >= 0
    if config.market_maker_capacity > 0
        product = r.market_maker_cash .* r.market_maker_inventory
        @assert maximum(abs.(product ./ product[1] .- 1)) < 1e-9
        @assert r.prices ≈ r.market_maker_cash ./ r.market_maker_inventory
    else
        @assert all(==(config.P0), r.prices)
    end
    return (result = r, cash_error = cash_error, late = late)
end

# Sell fractions of the two checkerboard halves, over interior cells that are
# not technical traders.
function half_gap(grid, technical)
    n = (zeros(Int, 2), zeros(Int, 2))
    for r in 2:size(grid, 1)-1, c in 2:size(grid, 2)-1
        (r, c) in technical && continue
        half = iseven(r + c) ? 1 : 2
        n[1][half] += grid[r, c] == 2
        n[2][half] += 1
    end
    return abs(n[1][1] / n[2][1] - n[1][2] / n[2][2])
end

# Share of non-technical interior traders with an edge or interior technical
# neighbor: how many traders see a price-responsive decision directly.
function technical_reach(layout, L)
    technical = Set(vcat(layout.edge_coordinates, layout.interior_technical))
    interior = Set(layout.interior_technical)
    reached = counted = 0
    for r in 2:L-1, c in 2:L-1
        (r, c) in interior && continue
        counted += 1
        reached += any(in(technical), ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)))
    end
    return reached / counted
end

# Mean shares of interior technical traders in Buy and in Sell over the
# post-switch steps, reconstructed from the price and band series.
function interior_technical_shares(r, layout, pre, boundary)
    (boundary == "hold" || isempty(layout.interior_technical)) && return (0.0, 0.0)
    buys = sells = 0
    for t in (pre + 1):r.config.steps, k in layout.interior_technical_k
        s = compute_band_state(r.prices[t + 1], r.ema_price[t + 1], r.ema_volatility[t + 1], k)
        buys += s == 0
        sells += s == 2
    end
    total = (r.config.steps - pre) * length(layout.interior_technical_k)
    return (buys / total, sells / total)
end

function metrics(run, job, layout, reach)
    r = run.result
    pre, steps, L = Int(job.pre), r.config.steps, Int(job.L)
    order_window = (pre + 1):steps
    state_window = (pre + 2):(steps + 1)
    final_states = @view r.sell_fraction[(end - min(FINAL_WINDOW, Int(job.post)) + 1):end]
    first_crossing = findfirst(>=(0.5), @view r.sell_fraction[state_window])
    technical = Set(layout.interior_technical)
    n_edge = length(r.edge_coordinates)
    n_traders = (L - 2)^2 + n_edge
    technical_buy, technical_sell = interior_technical_shares(r, layout, pre, String(job.boundary))
    desired_b = r.executed_buys .+ r.suppressed_buys .+ r.market_maker_rejected_buys
    desired_s = r.executed_sells .+ r.suppressed_sells .+ r.market_maker_rejected_sells
    (; group = String(job.group), role = String(job.role), experiment = String(job.experiment),
       condition = String(job.condition),
       alpha = Float64(job.alpha), rho = Float64(job.rho), rho_label = String(job.rho_label),
       n_interior_technical = length(layout.interior_technical), technical_reach = reach,
       h = Float64(job.h), boundary = String(job.boundary), seed = Int(job.seed),
       f = Float64(job.f), L, pre, post = Int(job.post),
       n_switched = job.role == "control" ? 0 : length(layout.minor_sites),
       majority = !isnothing(first_crossing),
       onset = isnothing(first_crossing) ? -1 : first_crossing,
       peak_sell = maximum(@view r.sell_fraction[state_window]),
       final_sell_mean = mean(final_states),
       final_sell_var = var(final_states; corrected = false),
       baseline_sell_mean = mean(@view r.sell_fraction[max(1, pre - 248):(pre + 1)]),
       max_drawdown = compute_max_drawdown(r.prices[(pre + 1):end]),
       activation_price = r.prices[pre + 1], final_price = r.prices[end],
       final_dealer_inventory_per_trader = r.market_maker_inventory[end] / n_traders,
       final_dealer_cash_per_trader = r.market_maker_cash[end] / n_traders,
       post_completed_orders = sum(r.executed_buys[order_window]) + sum(r.executed_sells[order_window]),
       post_desired_buys = sum(desired_b[order_window]),
       post_desired_sells = sum(desired_s[order_window]),
       post_suppressed_buys = sum(r.suppressed_buys[order_window]),
       post_suppressed_sells = sum(r.suppressed_sells[order_window]),
       post_dealer_rejections = sum(r.market_maker_rejected_buys[order_window]) +
                                sum(r.market_maker_rejected_sells[order_window]),
       half_gap_final = half_gap(r.frames[steps], technical),
       half_gap_late_mean = mean(half_gap(r.frames[t], technical) for t in run.late),
       interior_technical_buy_post = technical_buy,
       interior_technical_sell_post = technical_sell,
       edge_technical_buy_post = n_edge == 0 ? 0.0 : mean(r.edge_buy_count[order_window]) / n_edge,
       edge_technical_sell_post = n_edge == 0 ? 0.0 : mean(r.edge_sell_count[order_window]) / n_edge,
       max_cash_conservation_error = run.cash_error,
       initial_grid_sha256 = array_digest(r.frames[0]),
       activation_grid_sha256 = array_digest(r.frames[pre]),
       prehistory_sha256 = array_digest(vcat(r.prices[1:pre + 2], r.total_cash[1:pre + 2],
                                             r.sell_fraction[1:pre + 1])),
       final_grid_sha256 = array_digest(r.frames[steps]),
       sell_history_sha256 = array_digest(r.sell_fraction),
       price_history_sha256 = array_digest(r.prices),
       completed_utc = string(now(UTC)))
end

function run_group(jobs)
    id = String(jobs[1, :group])
    path = joinpath(STUDY, "results", id * ".csv")
    if isfile(path)
        nrow(CSV.read(path, DataFrame)) == nrow(jobs) || error("incomplete checkpoint $path")
        Threads.atomic_add!(COMPLETED, 1)
        return
    end
    jobs[1, :role] == "control" || error("group $id must start with its control")
    rows = NamedTuple[]
    control = nothing
    for job in eachrow(jobs)
        config = variant_config(job)
        layout = market_layout(config; minority_population = :interior,
                               interior_technical_fraction = Float64(job.rho))
        reach = technical_reach(layout, Int(job.L))
        run = checked_run(config, job)
        if job.role == "control"
            control = run
        else
            pre, r, c = Int(job.pre), run.result, control.result
            @assert r.prices[1:pre + 2] == c.prices[1:pre + 2]
            @assert r.total_cash[1:pre + 2] == c.total_cash[1:pre + 2]
            @assert r.sell_fraction[1:pre + 1] == c.sell_fraction[1:pre + 1]
            @assert r.frames[pre] == c.frames[pre]
            @assert r.edge_coordinates == c.edge_coordinates
            @assert r.edge_k == c.edge_k
        end
        push!(rows, metrics(run, job, layout, reach))
    end
    CSV.write(path * ".tmp", DataFrame(rows))
    mv(path * ".tmp", path)
    count = Threads.atomic_add!(COMPLETED, 1) + 1
    lock(WRITE_LOCK) do
        println(now(UTC), " completed group ", count, "/", length(unique(JOBS.group)), " ", id)
        flush(stdout)
    end
end

groups = collect(groupby(JOBS, :group; sort = false))
println(now(UTC), " starting ", length(groups), " groups, ", nrow(JOBS),
        " full simulations; threads=", Threads.nthreads())
flush(stdout)
Threads.@threads :dynamic for i in eachindex(groups)
    run_group(groups[i])
end
all_rows = vcat([CSV.read(joinpath(STUDY, "results", String(g[1, :group]) * ".csv"), DataFrame)
                 for g in groups]...)
CSV.write(joinpath(STUDY, "Run-Summary.csv"), all_rows)
println(now(UTC), " complete: ", nrow(all_rows), " simulations")
