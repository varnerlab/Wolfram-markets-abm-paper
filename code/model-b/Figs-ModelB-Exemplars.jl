# Figs-ModelB-Exemplars.jl — curated paper figure for the two realized regimes.
#
# Self-contained and reproducible from the committed Summary.csv: it selects
# one exemplar per column, re-simulates each in-memory (deterministic via the
# stored seed), and renders a 3x2 main-text figure. No JLD2 dependency.
#
#          crash-prone            oscillatory
#   Price  | bubble & crash |     | flat wiggle |
#   State  | Sell spike     |     | B/H/S mix   |
#   Suppr. | budget dynamics|     | low / flat  |
#
# Column exemplar choices (see the accompanying discussion):
#   * oscillatory — a FLAT representative. The Stage-2 z-space medoid rides a
#     ~46% drift; we instead pick, among runs with representative amplitude
#     (return_std in the IQR), the one that actually oscillates about a flat
#     mean price. Reads unambiguously as "oscillation", not "rising market".
#   * crash-prone — a DRAMATIC TAIL exemplar (largest max_drawdown), NOT the
#     typical run. The regime is defined behaviourally (>=1% of steps with
#     Sell fraction >= 0.5), and the MEDIAN crash-prone run barely moves in
#     price (median max_drawdown ~5%; half never dip below P0) — a sell-
#     saturated liquidity freeze. Real price collapses are the ~top-10-20%
#     tail (bubble to ~2.5x, then -40..-69%). This panel shows that tail for
#     visual impact; the caption MUST state it is atypical of the regime.

include(joinpath(@__DIR__, "Include.jl"))

const P0    = 100.0
const GRIDN = 64     # must match the Stage 2 sweep so a re-sim reproduces the run
const STEPS = 2000

df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Stage2-Summary.csv"), DataFrame)
@info "Loaded summary" rows = nrow(df)

# Same config builder as the Stage 2 driver (all non-swept knobs at defaults).
function _exemplar_config(row)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = row.seed,
        λ                 = row.lambda,
        k                 = row.k,
        minority_fraction = row.f,
        edge_band_spread  = row.spread,
        cost_basis_rule   = row.disposition,
        initial_cash      = row.cash,
        P0                = P0,
    ))
end

# ---------------------------------------------------------------------------
# 1. oscillatory exemplar — flattest representative
# ---------------------------------------------------------------------------
osc          = df[df.regime .== "oscillatory", :]
q25, q75     = quantile(osc.return_std, [0.25, 0.75])
rep          = osc[(osc.return_std .>= q25) .& (osc.return_std .<= q75), :]
mid_proxy    = abs.((rep.price_max .+ rep.price_min) ./ 2 ./ P0 .- 1)   # flat-drift proxy
shortlist    = rep[sortperm(mid_proxy)[1:min(12, nrow(rep))], :]
@info "Oscillatory shortlist" osc_runs = nrow(osc) shortlist = nrow(shortlist)

function _pick_flattest(shortlist)
    best_flat, best_row, best_res = Inf, nothing, nothing
    for row in eachrow(shortlist)
        res  = simulate(_exemplar_config(row); snapshot_steps = Int64[], verbose = false)
        flat = abs(mean(res.prices) / P0 - 1)              # |mean price / P0 - 1|
        @info "  osc candidate" run_id = row.run_id mean_flat = round(flat, digits = 4) final_drift = round(res.prices[end] / P0 - 1, digits = 4)
        if flat < best_flat
            best_flat, best_row, best_res = flat, row, res
        end
    end
    return best_row, best_res, best_flat
end
osc_row, osc_res, osc_flat = _pick_flattest(shortlist)
@info "Oscillatory exemplar chosen" run_id = osc_row.run_id mean_flat = round(osc_flat, digits = 4)

# ---------------------------------------------------------------------------
# 2. crash-prone exemplar — dramatic tail (largest peak-to-trough drawdown)
# ---------------------------------------------------------------------------
cprone    = df[df.regime .== "crash_prone", :]
crash_row = cprone[argmax(cprone.max_drawdown), :]
crash_res = simulate(_exemplar_config(crash_row); snapshot_steps = Int64[], verbose = false)
@info "Crash-prone exemplar chosen (dramatic tail — atypical)" run_id = crash_row.run_id max_drawdown = round(crash_row.max_drawdown, digits = 3) price_min = round(crash_row.price_min, digits = 1) price_max = round(crash_row.price_max, digits = 1)

# ---------------------------------------------------------------------------
# 3. Curated 3x2 figure: columns = {crash-prone, oscillatory}, rows =
#    {price, interior state fractions, suppressed orders}
#
# Shared style (Task 10): _panel_kw + _panel_letter! throughout, no in-figure
# titles (the regime name moves to a top-right annotation on every panel, so
# no panel's identity depends on its column position). State-fraction traces
# genuinely ARE Buy/Hold/Sell quantities and keep the reserved state hues
# (Hold now uses the exact reserved _HOLD_COLOR rather than the pre-restyle
# "#888888" stand-in, with a heavier linewidth for legibility against the
# panel's gray background). Price and suppressed-order series are NOT state
# quantities: price stays neutral black/gray (a deliberate grayscale, not a
# Plots default), and suppressed buys/sells take two _SERIES_COLORS entries
# rather than the reserved Buy/Sell hues.
# ---------------------------------------------------------------------------

function _price_panel(res; regime = "", legend = false)
    T = STEPS
    p = plot(; ylabel = "price", legend = legend ? :outertopright : false, _panel_kw...)
    plot!(p, 0:T, res.band_lower, fillrange = res.band_upper, fillalpha = 0.15,
          lw = 0, color = :gray, label = legend ? "EMA band" : "")
    plot!(p, 0:T, res.ema_price, color = :gray, ls = :dash, lw = 1.0,
          label = legend ? "EMA" : "")
    plot!(p, 0:T, res.prices, color = :black, lw = 1.3, label = legend ? "price" : "")
    annotate!(p, (0.98, 1.06), text(regime, 8, :black, :right))
    return p
end

function _pop_panel(res; regime = "", legend = false)
    T = STEPS
    p = plot(; ylabel = "state fraction", ylims = (0, 1),
             legend = legend ? :outertopright : false, _panel_kw...)
    plot!(p, 0:T, res.buy_fraction, color = _BUY_COLOR, lw = 1.3,
          label = legend ? "Buy" : "")
    plot!(p, 0:T, res.hold_fraction, color = _HOLD_COLOR, lw = 1.6,
          label = legend ? "Hold" : "")
    plot!(p, 0:T, res.sell_fraction, color = _SELL_COLOR, lw = 1.3,
          label = legend ? "Sell" : "")
    annotate!(p, (0.98, 1.06), text(regime, 8, :black, :right))
    return p
end

function _supp_panel(res; regime = "", legend = false)
    T = STEPS
    p = plot(; ylabel = "suppressed orders", xlabel = "step",
             legend = legend ? :outertopright : false, _panel_kw...)
    plot!(p, 1:T, res.suppressed_buys, color = _SERIES_COLORS[1], lw = 1.2,
          label = legend ? "suppressed buys" : "")
    plot!(p, 1:T, res.suppressed_sells, color = _SERIES_COLORS[2], lw = 1.2,
          label = legend ? "suppressed sells" : "")
    annotate!(p, (0.98, 1.06), text(regime, 8, :black, :right))
    return p
end

panels = [
    _price_panel(crash_res; regime = "crash-prone (tail exemplar)"),
    _price_panel(osc_res;   regime = "oscillatory", legend = true),
    _pop_panel(crash_res;   regime = "crash-prone (tail exemplar)"),
    _pop_panel(osc_res;     regime = "oscillatory", legend = true),
    _supp_panel(crash_res;  regime = "crash-prone (tail exemplar)"),
    _supp_panel(osc_res;    regime = "oscillatory", legend = true),
]
for (p, letter) in zip(panels, ["A", "B", "C", "D", "E", "F"])
    _panel_letter!(p, letter)
end

fig = plot(panels...; layout = (3, 2), size = (950, 950),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
_save_figure(fig, "FigS1-Exemplars.pdf")
@info "Figs-ModelB-Exemplars.jl complete." osc_run = osc_row.run_id crash_run = crash_row.run_id
