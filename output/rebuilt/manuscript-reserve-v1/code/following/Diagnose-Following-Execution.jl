# Isolate the settlement convention using prescribed orders in the full simulator.
include("Following-Lib.jl")

struct ExecutionProbe <: AbstractMarketObserver
    traders::Vector{Int}
    orders::Vector{Int}
end

function market_before_step!(o::ExecutionProbe, t, grid, books, price, mu, sigma, dealer)
    # Every other trader remains in Hold. Local decisions cannot create extra orders.
    fill!(grid, 1)
    grid[o.traders] .= 1 - o.orders[t]
    nothing
end

function execution_probe_cases()
    cases = NamedTuple[]
    for h in (0., 1., Inf)
        push!(cases, (; name="hold", h, impact=0.02, participants=0,
                      first_order=0, cycles=1, wait_steps=0))
    end
    crowd = round(Int, 0.4 * (64 - 2)^2)
    for h in (0., 1., Inf), impact in (0., 0.02), participants in (1, crowd),
        first_order in (1, -1)
        push!(cases, (; name=first_order==1 ? "buy_sell" : "sell_buy",
                      h, impact, participants, first_order, cycles=1, wait_steps=0))
    end
    for h in (1., Inf), first_order in (1, -1), (cycles, wait_steps) in ((1, 5), (100, 0))
        push!(cases, (; name=cycles==100 ? "repeated" : "delayed",
                      h, impact=0.02, participants=crowd, first_order, cycles, wait_steps))
    end
    cases
end

# Analytical benchmark for one-sided, fully filled orders only. Integrating
# the exponential marginal quote over the order charges the same average price
# on the outward and return legs. This is not a mixed-order clearing engine.
average_path_quote(price, x) = iszero(x) ? price : price * expm1(x) / x

function run_execution_probe(case)
    orders = Int[0]
    for _ in 1:case.cycles
        push!(orders, case.first_order)
        append!(orders, zeros(Int, case.wait_steps))
        push!(orders, -case.first_order)
    end
    push!(orders, 0)
    config = build(MyModelBConfiguration, (
        number_of_rows=64, number_of_cols=64, steps=length(orders), seed=630001,
        initial_condition=:all_hold, minority_fraction=0., edge_fraction=0.25,
        initial_cash=1000., initial_shares=10, P0=100., λ=case.impact,
        cost_basis_rule=false, market_maker_capacity=case.h,
    ))
    linear = LinearIndices((64, 64))
    interior = [linear[r,c] for c in 2:63 for r in 2:63]
    participants = interior[1:case.participants]
    observer = ExecutionProbe(participants, orders)
    result = simulate(config; observer, boundary_mode=:hold,
                      minority_population=:interior, snapshot_steps=Int[], verbose=false)
    ids = vcat(interior, [linear[r,c] for (r,c) in result.edge_coordinates])
    n = length(ids)
    others = setdiff(ids, participants)
    count_per_leg = case.h==0. ? 0 : case.participants
    expected_buys = [order==1 ? count_per_leg : 0 for order in orders]
    expected_sells = [order==-1 ? count_per_leg : 0 for order in orders]
    @assert result.executed_buys == expected_buys
    @assert result.executed_sells == expected_sells
    @assert all(iszero, result.suppressed_buys) && all(iszero, result.suppressed_sells)
    @assert all(==(config.initial_shares), result.final_books.shares[ids])
    @assert all(==(config.initial_cash), result.final_books.cash[others])
    @assert isapprox(result.prices[end], config.P0; atol=1e-9, rtol=0)
    @assert result.market_maker_inventory[end] == result.market_maker_inventory[1]

    cash = result.total_cash .+ result.market_maker_cash
    shares = result.total_shares .+ result.market_maker_inventory
    cash_error = maximum(abs.(cash .- cash[1]))
    @assert cash_error <= max(1e-7, abs(cash[1])*1e-11)
    @assert all(==(shares[1]), shares)
    cohort_cash = sum(result.final_books.cash[participants] .- config.initial_cash; init=0.)
    dealer_cash = result.market_maker_cash[end] - result.market_maker_cash[1]
    @assert isapprox(cohort_cash + dealer_cash, 0.; atol=1e-6, rtol=0)

    # A completed cycle has unchanged price and holdings, so cash profit equals
    # the change in portfolio value; it cannot be explained by endpoint marking.
    x = case.impact * count_per_leg / n
    expected_profit = case.cycles * count_per_leg * config.P0 * (
        case.first_order==1 ? expm1(x) : -expm1(-x))
    @assert isapprox(cohort_cash, expected_profit; atol=1e-6, rtol=1e-9)
    if case.impact>0 && count_per_leg>0
        @assert cohort_cash > 0 && dealer_cash < 0
    else
        @assert isapprox(cohort_cash, 0.; atol=1e-8, rtol=0)
    end

    signed_x = case.first_order * x
    opening_price = average_path_quote(config.P0, signed_x)
    closing_price = average_path_quote(config.P0 * exp(signed_x), -signed_x)
    benchmark_profit = case.cycles * count_per_leg * case.first_order * (closing_price-opening_price)
    @assert isapprox(benchmark_profit, 0.; atol=1e-6, rtol=0)
    initial_cohort_value = case.participants * (config.initial_cash + config.initial_shares*config.P0)
    row = merge(case, (
        n_traders=n, filled_per_leg=count_per_leg, final_price=result.prices[end],
        cohort_cash_profit=cohort_cash, dealer_cash_profit=dealer_cash,
        profit_per_participant=case.participants==0 ? 0. : cohort_cash/case.participants,
        cohort_return=initial_cohort_value==0 ? 0. : cohort_cash/initial_cohort_value,
        expected_cash_profit=expected_profit, maximum_cash_error=cash_error,
        average_path_open_quote=opening_price, average_path_close_quote=closing_price,
        analytical_average_path_profit=benchmark_profit,
    ))
    steps = [merge(case, (
        step=t, requested_order=orders[t], quote_before=result.prices[t],
        quote_after=result.prices[t+1], buys=result.executed_buys[t], sells=result.executed_sells[t],
        dealer_cash=result.market_maker_cash[t+1], dealer_inventory=result.market_maker_inventory[t+1],
        trader_cash=result.total_cash[t+1], trader_shares=result.total_shares[t+1],
    )) for t in eachindex(orders)]
    (; row, steps)
end

function diagnose_following_execution()
    cases = execution_probe_cases()
    runs = run_execution_probe.(cases)
    rows = DataFrame([run.row for run in runs])
    output = joinpath(FOLLOWING_ROOT, "output", "following", "execution-audit-20260914")
    mkpath(output)
    CSV.write(joinpath(output, "Summary.csv"), rows)
    CSV.write(joinpath(output, "Steps.csv"), DataFrame(reduce(vcat, [run.steps for run in runs])))
    metadata = Dict(
        "created_utc"=>string(now(UTC)), "julia_version"=>string(VERSION),
        "cases"=>length(cases), "source_digest"=>following_source_digest(),
        "diagnostic_digest"=>bytes2hex(sha256(read(@__FILE__))),
        "environment_digest"=>bytes2hex(sha256(read(joinpath(FOLLOWING_ROOT,"code","Manifest.toml")))),
        "git_revision"=>readchomp(Cmd(Cmd(["git","rev-parse","HEAD"]); dir=FOLLOWING_ROOT)),
        "scope"=>"Deterministic prescribed orders; no advice, copying, local transmission, or active technical traders.",
        "benchmark"=>"Analytical average marginal quote along the exponential price path; one-sided full fills only.",
    )
    open(joinpath(output, "Protocol.toml"), "w") do io
        TOML.print(io, metadata)
    end
    open(joinpath(output, "report.md"), "w") do io
        println(io, "# Execution-price diagnostic, 14 September 2026\n")
        println(io, "The current simulator produces positive cash profits from prescribed, fully filled buy–sell and sell–buy cycles when price impact is positive. The dealer loses the same cash. No advice, copying, or transmission is required. Prices and every trader's share holdings return to their initial values.\n")
        println(io, "All $(length(cases)) deterministic cases passed checks for prescribed fills, cash/share conservation, unchanged holdings of other traders, return to the initial price and dealer inventory, and agreement with the analytical profit. These cases are implementation diagnostics, not independent market samples.\n")
        println(io, "## Selected results\n")
        println(io, "All cases use a 64 by 64 grid, initial price 100, cash 1,000 and ten shares per trader. Selected technical traders remain in Hold but count in the simulator's price-impact denominator. The synchronized group contains 40% of interior traders, rounded using the campaign convention. Values below are simulation currency units.\n")
        println(io, "| Orders | Capacity | Impact | Participants | Cycles | Cash gain per participant | Group cash gain | Dealer cash change |\n|---|---:|---:|---:|---:|---:|---:|---:|")
        for r in eachrow(rows)
            show = r.name=="hold" && r.h==1. ||
                   r.name in ("buy_sell","sell_buy") && r.h==1. && r.impact==0.02 ||
                   r.name=="buy_sell" && r.participants>1 && (r.h==0. && r.impact==0.02 || r.h==1. && r.impact==0.) ||
                   r.name=="repeated" && r.h==1. && r.first_order==1
            show || continue
            @printf(io, "| %s | %g | %g | %d | %d | %.8f | %.6f | %.6f |\n",
                    r.name,r.h,r.impact,r.participants,r.cycles,r.profit_per_participant,r.cohort_cash_profit,r.dealer_cash_profit)
        end
        println(io, "\n`Summary.csv` contains all cases, including unlimited capacity, reversed order, five intervening Hold steps, and repeated cycles. `Steps.csv` records every execution and dealer ledger.\n")
        println(io, "## Why the gain appears\n")
        println(io, raw"For a group of $M$ traders each buying one share at $P_0$, the new quote is $P_1=P_0\exp(\lambda M/N)$, where $N$ is the simulator's fixed number of traders. Selling those shares next settles at $P_1$ and returns the quote to $P_0$. The group earns $MP_0[\exp(\lambda M/N)-1]$. Selling endowed shares first and buying them back gives $MP_0[1-\exp(-\lambda M/N)]$. With idle traders between legs, the gain is unchanged. No gain occurs at zero impact, with all traders holding, or when zero capacity prevents both legs from filling.")
        println(io, "\nThe supplied analytical benchmark integrates the marginal quote along each one-sided execution path. Outward and return legs then have the same average execution price and zero cash profit before costs. The benchmark does not implement eligibility, mixed orders, or rationing for a new market model.\n")
        println(io, "## Interpretation and next experiment\n")
        println(io, "The current convention permits profitable round trips without an informative signal. This establishes a competing explanation for follower gains; it does not measure how much of the confirmation returns comes from that convention. The completed confirmation campaigns remain results for their recorded model.\n")
        println(io, "Next, specify a separate execution variant that accounts for price impact in fill prices and tests eligibility at those prices. It must handle offsetting orders and dealer constraints, conserve cash/shares, and remove the profitable isolated round trip before adding transaction costs. Then run a small paired advice/copying/no-following pilot with matched exit tests and dealer profit/loss. Freeze its design and use new confirmation markets only after the execution checks pass. Do not overwrite the existing campaign files or reuse their checkpoints under changed code.")
    end
    @info "Execution diagnostic complete" cases=length(cases) output
    rows
end

if abspath(PROGRAM_FILE)==@__FILE__
    diagnose_following_execution()
end
