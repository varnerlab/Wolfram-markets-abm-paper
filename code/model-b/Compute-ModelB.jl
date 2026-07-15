# Compute-ModelB.jl — Stage 1 diagnostic driver (model-B-plan.md §7, spec §5)
#
# Runs the 32×32, 200-step closed-loop diagnostic and saves:
#   code/data/ModelB-Diagnostic.jld2   — full trajectory + config
#   code/figs/ModelB-Diagnostic.pdf    — 4-panel diagnostic figure
#
# This is a diagnostic, not a paper figure — nothing is copied to paper/figs.
# Stage 2 (64×64 ensemble) and Stage 3 (256×256 sweep) come in later sessions,
# only after this feedback loop is demonstrably working.

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Configuration — single source of truth (all assumptions stated explicitly)
# ---------------------------------------------------------------------------
config = build(MyModelBConfiguration, (
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
))

@info "Model B Stage 1 diagnostic: $(config.number_of_rows)×$(config.number_of_cols), " *
      "$(config.steps) steps, seed $(config.seed)"
result = simulate(config)

# ---------------------------------------------------------------------------
# Save the full trajectory
# ---------------------------------------------------------------------------
save(joinpath(_PATH_TO_DATA, "ModelB-Diagnostic.jld2"), Dict(
    "frames"           => result.frames,
    "prices"           => result.prices,
    "log_returns"      => result.log_returns,
    "net_imbalance"    => result.net_imbalance,
    "buy_fraction"     => result.buy_fraction,
    "hold_fraction"    => result.hold_fraction,
    "sell_fraction"    => result.sell_fraction,
    "edge_states"      => result.edge_states,
    "ema_price"        => result.ema_price,
    "ema_volatility"   => result.ema_volatility,
    "band_lower"       => result.band_lower,
    "band_upper"       => result.band_upper,
    "edge_coordinates" => result.edge_coordinates,
    "config"           => Dict(String(f) => getfield(config, f)
                               for f in fieldnames(typeof(config))),
))
@info "Saved: ModelB-Diagnostic.jld2"

# ---------------------------------------------------------------------------
# 4-panel diagnostic figure: price/band, imbalance, edge state, populations
# ---------------------------------------------------------------------------
T = config.steps

p1 = plot(0:T, result.band_lower, fillrange = result.band_upper,
          fillalpha = 0.15, lw = 0, color = :gray, label = "EMA ± kσ")
plot!(p1, 0:T, result.ema_price, color = :gray, ls = :dash, label = "EMA")
plot!(p1, 0:T, result.prices, color = :black, lw = 1.5, label = "price")
plot!(p1, xlabel = "step", ylabel = "price", title = "Endogenous price")

p2 = plot(1:T, result.net_imbalance, color = _BUY_COLOR, legend = false,
          xlabel = "step", ylabel = "φ", title = "Net order imbalance")
hline!(p2, [0.0], color = :gray, ls = :dot)

p3 = plot(1:T, result.edge_states, seriestype = :steppost, color = :black,
          legend = false, xlabel = "step", ylabel = "edge state",
          yticks = ([0, 1, 2], ["Buy", "Hold", "Sell"]), ylims = (-0.2, 2.2),
          title = "Edge-agent state")

p4 = plot(0:T, result.buy_fraction, color = _BUY_COLOR, label = "Buy",
          xlabel = "step", ylabel = "fraction", title = "Interior populations")
plot!(p4, 0:T, result.hold_fraction, color = "#888888", label = "Hold")
plot!(p4, 0:T, result.sell_fraction, color = _SELL_COLOR, label = "Sell")

fig = plot(p1, p2, p3, p4, layout = (2, 2), size = (1000, 700),
           left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Diagnostic.pdf"))
@info "Saved: ModelB-Diagnostic.pdf"

# ---------------------------------------------------------------------------
# Numerical summary — success criterion (spec §5): the run must not be inert
# ---------------------------------------------------------------------------
crash           = compute_crash_statistics(result.sell_fraction)
n_edge_switches = count(diff(result.edge_states) .!= 0)

@info("Diagnostic summary",
    price_min       = minimum(result.prices),
    price_max       = maximum(result.prices),
    return_std      = std(result.log_returns),
    edge_switches   = n_edge_switches,
    final_buy       = result.buy_fraction[end],
    final_hold      = result.hold_fraction[end],
    final_sell      = result.sell_fraction[end],
    crash_frequency = crash.frequency,
    n_crashes       = crash.n_crashes,
)

std(result.log_returns) == 0.0 &&
    @warn "Run appears INERT: every log return is zero (model-B-plan.md known issue)."
n_edge_switches == 0 &&
    @warn "Edge state never changed: the feedback loop may not be closing."

@info "Compute-ModelB.jl complete."
