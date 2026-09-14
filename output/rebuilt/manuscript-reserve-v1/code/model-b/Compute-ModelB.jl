# Compute-ModelB.jl — Stage 1 diagnostic driver (spec 2026-07-16 §6)
#
# Runs the 32×32, 200-step closed-loop diagnostic with per-agent budget
# constraints and heterogeneous edge bands, twice: cost_basis_rule on
# (default, artifacts saved) and off (summary logged only). Saves:
#   code/data/ModelB-Diagnostic.jld2   — full trajectory + books + config
#   code/figs/ModelB-Diagnostic.pdf    — 3×2 diagnostic figure
#
# This is a diagnostic, not a paper figure — nothing is copied to paper/figs.
# Stage 2 (64×64 ensemble) comes in a later session, only after the
# constrained feedback loop is demonstrably working.

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Configuration — single source of truth (all assumptions stated explicitly)
# ---------------------------------------------------------------------------
base = (
    number_of_rows        = 32,
    number_of_cols        = 32,
    steps                 = 200,
    seed                  = 42,
    initial_condition     = :balanced_perturbation,
    initial_buy_fraction  = 0.05,
    initial_sell_fraction = 0.05,
    edge_fraction         = 0.25,
    α                     = 1 / 60,
    k                     = 1.0,
    λ                     = 0.01,
    P0                    = 100.0,
    minority_fraction     = 0.20,
    rule_major_index      = 19280,
    rule_minor_index      = 19286,
    initial_cash          = 1000.0,   # 10·P0 — ~10 steps of one-sided buying
    initial_shares        = 10,
    cost_basis_rule       = true,     # disposition effect ON (default run)
    edge_band_spread      = 0.5,      # k_i ~ U(0.5, 1.5)
)
config = build(MyModelBConfiguration, base)

@info "Model B Stage 1 diagnostic: $(config.number_of_rows)×$(config.number_of_cols), " *
      "$(config.steps) steps, seed $(config.seed), cost_basis_rule = $(config.cost_basis_rule)"
result = simulate(config)

# ---------------------------------------------------------------------------
# Save the full trajectory and final books
# ---------------------------------------------------------------------------
save(joinpath(_PATH_TO_DATA, "ModelB-Diagnostic.jld2"), Dict(
    "frames"           => result.frames,
    "prices"           => result.prices,
    "log_returns"      => result.log_returns,
    "net_imbalance"    => result.net_imbalance,
    "buy_fraction"     => result.buy_fraction,
    "hold_fraction"    => result.hold_fraction,
    "sell_fraction"    => result.sell_fraction,
    "edge_buy_count"   => result.edge_buy_count,
    "edge_hold_count"  => result.edge_hold_count,
    "edge_sell_count"  => result.edge_sell_count,
    "edge_switches"    => result.edge_switches,
    "ema_price"        => result.ema_price,
    "ema_volatility"   => result.ema_volatility,
    "band_lower"       => result.band_lower,
    "band_upper"       => result.band_upper,
    "executed_buys"    => result.executed_buys,
    "executed_sells"   => result.executed_sells,
    "suppressed_buys"  => result.suppressed_buys,
    "suppressed_sells" => result.suppressed_sells,
    "total_cash"       => result.total_cash,
    "total_shares"     => result.total_shares,
    "books_cash"       => result.final_books.cash,
    "books_shares"     => result.final_books.shares,
    "books_avg_cost"   => result.final_books.avg_cost,
    "edge_coordinates" => result.edge_coordinates,
    "edge_k"           => result.edge_k,
    "config"           => Dict(String(f) => getfield(config, f)
                               for f in fieldnames(typeof(config))),
))
@info "Saved: ModelB-Diagnostic.jld2"

# ---------------------------------------------------------------------------
# 3×2 diagnostic figure (spec 2026-07-16 §6)
# ---------------------------------------------------------------------------
T      = config.steps
n_edge = length(result.edge_coordinates)

p1 = plot(0:T, result.band_lower, fillrange = result.band_upper,
          fillalpha = 0.15, lw = 0, color = :gray, label = "EMA ± kσ (nominal)")
plot!(p1, 0:T, result.ema_price, color = :gray, ls = :dash, label = "EMA")
plot!(p1, 0:T, result.prices, color = :black, lw = 1.5, label = "price")
plot!(p1, xlabel = "step", ylabel = "price", title = "Endogenous price")

p2 = plot(1:T, result.net_imbalance, color = _BUY_COLOR, legend = false,
          xlabel = "step", ylabel = "φ (executed)", title = "Executed order imbalance")
hline!(p2, [0.0], color = :gray, ls = :dot)

p3 = plot(1:T, result.edge_buy_count ./ n_edge, color = _BUY_COLOR, label = "Buy",
          xlabel = "step", ylabel = "fraction", title = "Edge-agent populations")
plot!(p3, 1:T, result.edge_hold_count ./ n_edge, color = "#888888", label = "Hold")
plot!(p3, 1:T, result.edge_sell_count ./ n_edge, color = _SELL_COLOR, label = "Sell")

p4 = plot(0:T, result.buy_fraction, color = _BUY_COLOR, label = "Buy",
          xlabel = "step", ylabel = "fraction", title = "Interior populations")
plot!(p4, 0:T, result.hold_fraction, color = "#888888", label = "Hold")
plot!(p4, 0:T, result.sell_fraction, color = _SELL_COLOR, label = "Sell")

desired  = result.executed_buys .+ result.executed_sells .+
           result.suppressed_buys .+ result.suppressed_sells
executed = result.executed_buys .+ result.executed_sells
p5 = plot(1:T, desired, color = :gray, label = "desired",
          xlabel = "step", ylabel = "orders", title = "Order volume")
plot!(p5, 1:T, executed, color = :black, label = "executed")

p6 = plot(1:T, result.suppressed_buys, color = _BUY_COLOR, label = "suppressed buys",
          xlabel = "step", ylabel = "count", title = "Suppressed orders")
plot!(p6, 1:T, result.suppressed_sells, color = _SELL_COLOR, label = "suppressed sells")

fig = plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), size = (1000, 1050),
           left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Diagnostic.pdf"))
@info "Saved: ModelB-Diagnostic.pdf"

# ---------------------------------------------------------------------------
# Numerical summary — success criteria (spec 2026-07-16 §6)
# ---------------------------------------------------------------------------
function _summarize(tag::String, result)
    crash = compute_crash_statistics(result.sell_fraction)
    @info("Diagnostic summary ($(tag))",
        price_min          = minimum(result.prices),
        price_max          = maximum(result.prices),
        return_std         = std(result.log_returns),
        edge_switches      = result.edge_switches,
        final_buy          = result.buy_fraction[end],
        final_hold         = result.hold_fraction[end],
        final_sell         = result.sell_fraction[end],
        n_suppressed_buys  = sum(result.suppressed_buys),
        n_suppressed_sells = sum(result.suppressed_sells),
        total_cash_final   = result.total_cash[end],
        total_shares_final = result.total_shares[end],
        crash_frequency    = crash.frequency,
        n_crashes          = crash.n_crashes,
    )
    return nothing
end

_summarize("cost_basis_rule = true", result)

std(result.log_returns) == 0.0 &&
    @warn "Run appears INERT: every log return is zero."
result.edge_switches == 0 &&
    @warn "No edge agent ever changed state: the feedback loop may not be closing."
(sum(result.suppressed_buys) + sum(result.suppressed_sells)) == 0 &&
    @warn "Constraints never bind: endowment defaults may be too large to matter."

# ---------------------------------------------------------------------------
# Comparison run — disposition toggle OFF (summary only, no artifacts)
# ---------------------------------------------------------------------------
config_off = build(MyModelBConfiguration, merge(base, (cost_basis_rule = false,)))
@info "Comparison run: cost_basis_rule = false"
result_off = simulate(config_off; verbose = false)
_summarize("cost_basis_rule = false", result_off)

@info "Compute-ModelB.jl complete."
