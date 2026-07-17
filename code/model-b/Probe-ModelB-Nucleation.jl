# Probe-ModelB-Nucleation.jl — de-risking probe for the "nucleation in Model B"
# angle. Two questions, answered on dense spatial frames:
#
#   Q1 SPATIAL or GLOBAL?  When Model B crashes, does one sell domain nucleate
#      and grow (largest connected sell-cluster fraction tracks the total sell
#      fraction), or do sell cells appear everywhere at once (largest cluster
#      << total, i.e. mean-field / global synchronization)?
#   Q2 ARRESTED?           Does the largest domain's growth plateau exactly when
#      suppressed-sell orders spike — budget exhaustion stalling the front?
#
# Three configs, identical but for the two things that matter:
#   stable   f=0.10  cash=1000  — below transition: dispersed-sell baseline
#   freeze   f=0.20  cash= 500  — above transition, TIGHT budget (expect freeze)
#   collapse f=0.20  cash=5000  — above transition, LOOSE budget (expect crash)
#
# Diagnostic only; writes two probe figures, no data artifacts.

include(joinpath(@__DIR__, "Include.jl"))

const P0    = 100.0
const GRIDN = 64
const STEPS = 1000
const SEED  = 1

function _probe_config(; f, cash)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = SEED,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = f,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end

# Connected components of sell (state 2) cells, 4-neighbour, OPEN boundaries
# (Model B has a distinct edge ring — no periodic wrap). Returns (n, max).
function _sell_clusters(grid::Matrix{Int64})
    nr, nc  = size(grid)
    visited = falses(nr, nc)
    n_clust = 0
    max_sz  = 0
    for r in 1:nr, c in 1:nc
        (grid[r, c] == 2 && !visited[r, c]) || continue
        n_clust += 1
        sz    = 0
        queue = [(r, c)]
        visited[r, c] = true
        while !isempty(queue)
            cr, cc = popfirst!(queue)
            sz += 1
            for (dr, dc) in ((-1, 0), (1, 0), (0, -1), (0, 1))
                nr2, nc2 = cr + dr, cc + dc
                (1 <= nr2 <= nr && 1 <= nc2 <= nc) || continue
                if grid[nr2, nc2] == 2 && !visited[nr2, nc2]
                    visited[nr2, nc2] = true
                    push!(queue, (nr2, nc2))
                end
            end
        end
        max_sz = max(max_sz, sz)
    end
    return n_clust, max_sz
end

# ---------------------------------------------------------------------------
# Run the three configs with per-step frames; reduce to spatial time series.
# ---------------------------------------------------------------------------
const CONFIGS = [
    (name = "stable",   f = 0.10, cash = 1000.0),
    (name = "freeze",   f = 0.20, cash =  500.0),
    (name = "collapse", f = 0.20, cash = 5000.0),
]
const N_CELLS = GRIDN * GRIDN

runs = map(CONFIGS) do cfg
    @info "Running probe config" cfg.name f = cfg.f cash = cfg.cash
    res    = simulate(_probe_config(f = cfg.f, cash = cfg.cash);
                      snapshot_steps = collect(1:STEPS), verbose = false)
    sellfr = zeros(STEPS)
    maxcl  = zeros(STEPS)
    nclust = zeros(Int, STEPS)
    for t in 1:STEPS
        g          = res.frames[t]
        n, m       = _sell_clusters(g)
        sellfr[t]  = count(==(2), g) / N_CELLS
        maxcl[t]   = m / N_CELLS
        nclust[t]  = n
    end
    peak = argmax(sellfr)
    @info "  reduced" cfg.name peak_sell = round(sellfr[peak], digits = 3) max_cluster_frac_at_peak = round(maxcl[peak], digits = 3) ratio = round(maxcl[peak] / max(sellfr[peak], 1e-9), digits = 3)
    (cfg = cfg, res = res, sellfr = sellfr, maxcl = maxcl, nclust = nclust)
end

# ---------------------------------------------------------------------------
# Figure 1 — grid montage: 3 configs (rows) x 7 fixed steps (cols)
# ---------------------------------------------------------------------------
const MONT_STEPS = [1, 100, 250, 400, 550, 700, 1000]
montage = Plots.Plot[]
for r in runs
    for (j, t) in enumerate(MONT_STEPS)
        ttl = j == 1 ? "$(r.cfg.name)\nt=$t" : "t=$t"
        push!(montage, _grid_panel(r.res.frames[t], ttl))
    end
end
fig1 = plot(montage...; layout = (length(runs), length(MONT_STEPS)),
            size = (1500, 660), plot_title = "Model B sell field (blue=Buy, gray=Hold, orange=Sell)",
            plot_titlefontsize = 11)
_save_figure(fig1, "Probe-ModelB-Nucleation-Grids.pdf")

# ---------------------------------------------------------------------------
# Figure 2 — cluster dynamics: columns = configs
#   row 1: total sell fraction (black) vs largest-cluster fraction (red)
#          -> overlap => nucleation; red << black => dispersed/global
#   row 2: number of sell clusters (left) + suppressed sells, scaled (blue)
#          -> arrest shows as growth plateau coinciding with suppression rise
# ---------------------------------------------------------------------------
panels = Plots.Plot[]
for r in runs                                        # row 1 across configs
    p = plot(1:STEPS, r.sellfr, color = :black, lw = 1.4, label = "total sell",
             title = r.cfg.name, titlefont = 10, ylims = (0, 1),
             ylabel = "fraction", guidefont = 8, tickfont = 7, legendfontsize = 6)
    plot!(p, 1:STEPS, r.maxcl, color = _SELL_COLOR, lw = 1.4, label = "largest cluster")
    push!(panels, p)
end
for r in runs                                        # row 2 across configs
    supp   = r.res.suppressed_sells
    sscale = maximum(supp) > 0 ? maximum(r.nclust) / maximum(supp) : 0.0
    p = plot(1:STEPS, r.nclust, color = "#666666", lw = 1.2, label = "n sell clusters",
             xlabel = "step", ylabel = "n clusters", guidefont = 8, tickfont = 7,
             legendfontsize = 6)
    plot!(p, 1:STEPS, supp .* sscale, color = _BUY_COLOR, lw = 1.2, ls = :dash,
          label = "suppressed sells (scaled)")
    push!(panels, p)
end
fig2 = plot(panels...; layout = (2, length(runs)), size = (1400, 620),
            left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
            plot_title = "Nucleation diagnostics: spatial (row 1) and arrest (row 2)",
            plot_titlefontsize = 11)
_save_figure(fig2, "Probe-ModelB-Nucleation-Clusters.pdf")

@info "Probe-ModelB-Nucleation.jl complete."
