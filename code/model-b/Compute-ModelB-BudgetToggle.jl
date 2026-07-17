# Compute-ModelB-BudgetToggle.jl — budget-toggle intervention (arrested-
# nucleation confirmatory analysis #2; the cleanest causal test).
#
# The seed sweep showed nucleation ONSET times are broadly dispersed (Kramers
# waiting times), so fixed-time freeze-vs-collapse comparisons are underpowered
# (p ≈ 0.06 at n = 20). This experiment removes onset variance entirely with a
# within-seed counterfactual:
#
#   For each seed, run a CONTROL to find the nucleation onset t_on (first step
#   the largest sell cluster reaches ONSET_FRAC of the grid), then rerun the
#   IDENTICAL config with one change — at t = t_on every agent's cash is scaled
#   by a factor — and compare front growth over the next W steps. Dynamics are
#   deterministic given the seed, so the two runs share bit-identical history
#   up to t_on (asserted below) and any post-toggle divergence is causally
#   attributable to the budget change alone.
#
# Two directions, mirroring the probe's freeze/collapse configs (cash 500 vs
# 5000, factor 10 = their ratio):
#   injection  — tight base (cash  500), cash x10  at onset. If budgets arrest
#                the front, the front should ACCELERATE vs control.
#   withdrawal — loose base (cash 5000), cash x0.1 at onset. The front should
#                DECELERATE vs control.
#
# Note the causal chain being tested: the execution layer binds ORDERS, not
# sentiment — cash gates buys, so the grid feels budgets only through
# executed imbalance -> price -> edge bands -> boundary. The toggle probes
# exactly that chain.
#
# Writes: code/data/ModelB-Nucleation-BudgetToggle.csv (one row per direction x seed)
#         code/figs/ModelB-Nucleation-BudgetToggle.pdf
#
# Launch: julia -t 8 code/model-b/Compute-ModelB-BudgetToggle.jl
# Smoke:  TOGGLE_SMOKE=1 julia code/model-b/Compute-ModelB-BudgetToggle.jl
#         (tiny grid, forced t_on — exercises the toggle path, not the science)
#
# Threading contract (as Stage 2): results land in preallocated vectors indexed
# by work-item id; all file I/O and plotting happen OUTSIDE the threaded loop.

include(joinpath(@__DIR__, "Include.jl"))

const SMOKE = get(ENV, "TOGGLE_SMOKE", "0") == "1"
SMOKE && @warn "TOGGLE_SMOKE=1 — tiny grid, forced onset; outputs are smoke artifacts only"

const P0         = 100.0
const GRIDN      = SMOKE ? 32 : 64
const STEPS      = SMOKE ? 200 : 1500
const SEEDS      = SMOKE ? collect(1:2) : collect(1:20)
const W          = SMOKE ? 100 : 400      # post-toggle comparison window
const ONSET_FRAC = 0.05                   # largest cluster ≥ 5% of grid = front established
const N_CELLS    = GRIDN * GRIDN

const DIRECTIONS = [
    (name = "injection",  base_cash =  500.0, factor = 10.0),
    (name = "withdrawal", base_cash = 5000.0, factor =  0.1),
]

function _toggle_config(; cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = 0.20,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end

# Connected components of sell (state 2) cells, 4-neighbour, OPEN boundaries
# (same reduction as Probe-ModelB-Nucleation.jl). Returns (n, max).
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

_maxcl_trajectory(res) = [_sell_clusters(res.frames[t])[2] / N_CELLS for t in 1:STEPS]

"""Run one (direction, seed): control -> onset -> toggled rerun -> paired row."""
function _run_pair(dir::NamedTuple, seed::Int)
    ctrl = simulate(_toggle_config(cash = dir.base_cash, seed = seed);
                    snapshot_steps = collect(1:STEPS), verbose = false)
    maxcl_c = _maxcl_trajectory(ctrl)

    t_on = SMOKE ? 50 : something(findfirst(≥(ONSET_FRAC), maxcl_c), 0)
    if t_on == 0 || t_on > STEPS - W
        return (row = (direction = dir.name, base_cash = dir.base_cash,
                       factor = dir.factor, seed = seed, included = false,
                       onset = t_on, v_ctrl = NaN, v_toggle = NaN, dv = NaN,
                       front_ctrl_W = NaN, front_toggle_W = NaN,
                       price_ctrl_W = NaN, price_toggle_W = NaN,
                       suppb_ctrl_W = NaN, suppb_toggle_W = NaN),
                maxcl_c = maxcl_c, maxcl_t = Float64[], t_on = t_on)
    end

    hook = (t, books) -> (t == t_on && (books.cash .*= dir.factor); nothing)
    tog  = simulate(_toggle_config(cash = dir.base_cash, seed = seed);
                    snapshot_steps = collect(1:STEPS), verbose = false,
                    intervention = hook)
    maxcl_t = _maxcl_trajectory(tog)

    # Internal validity: identical history up to the toggle (hook fires at the
    # top of step t_on, so prices[1:t_on] — through the end of step t_on-1 —
    # and the frame at t_on-1 must match bit-for-bit).
    @assert ctrl.prices[1:t_on] == tog.prices[1:t_on] "pre-toggle price divergence (dir=$(dir.name) seed=$seed)"
    @assert ctrl.frames[t_on - 1] == tog.frames[t_on - 1] "pre-toggle frame divergence (dir=$(dir.name) seed=$seed)"

    v_c = (maxcl_c[t_on + W] - maxcl_c[t_on]) / W
    v_t = (maxcl_t[t_on + W] - maxcl_t[t_on]) / W
    row = (direction = dir.name, base_cash = dir.base_cash, factor = dir.factor,
           seed = seed, included = true, onset = t_on,
           v_ctrl = v_c, v_toggle = v_t, dv = v_t - v_c,
           front_ctrl_W   = maxcl_c[t_on + W],
           front_toggle_W = maxcl_t[t_on + W],
           price_ctrl_W   = ctrl.prices[t_on + W + 1],
           price_toggle_W = tog.prices[t_on + W + 1],
           suppb_ctrl_W   = mean(@view ctrl.suppressed_buys[t_on:(t_on + W)]),
           suppb_toggle_W = mean(@view tog.suppressed_buys[t_on:(t_on + W)]))
    return (row = row, maxcl_c = maxcl_c, maxcl_t = maxcl_t, t_on = t_on)
end

# ---------------------------------------------------------------------------
# Sweep: 2 directions x seeds, control + toggled run per item
# ---------------------------------------------------------------------------
items = [(dir = dir, seed = seed) for dir in DIRECTIONS for seed in SEEDS]
@info "Budget-toggle intervention" n_pairs = length(items) grid = GRIDN steps = STEPS window = W threads = Threads.nthreads()

results = Vector{Union{Nothing,NamedTuple}}(nothing, length(items))
Threads.@threads :dynamic for i in eachindex(items)
    results[i] = _run_pair(items[i].dir, items[i].seed)
end
@assert all(!isnothing, results)

df = DataFrame()
for r in results
    push!(df, r.row)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle.csv"), df)
@info "Saved: ModelB-Nucleation-BudgetToggle.csv"

# Paired sign-flip permutation test on dv per direction (H0: toggle does nothing)
function _signflip_p(dv::Vector{Float64}; n_draws::Int = 20_000)
    isempty(dv) && return NaN
    rng  = Xoshiro(7)
    dobs = abs(mean(dv))
    hits = 0
    for _ in 1:n_draws
        hits += abs(mean(dv .* rand(rng, (-1.0, 1.0), length(dv)))) >= dobs
    end
    return hits / n_draws
end

for dir in DIRECTIONS
    sub = df[(df.direction .== dir.name) .& df.included, :]
    n_ex = count((df.direction .== dir.name) .& .!df.included)
    dv   = collect(skipmissing(sub.dv))
    @info "Summary: $(dir.name)" n = nrow(sub) excluded = n_ex median_onset = median(sub.onset) median_v_ctrl_e4 = round(median(sub.v_ctrl) * 1e4, digits = 2) median_v_toggle_e4 = round(median(sub.v_toggle) * 1e4, digits = 2) median_dv_e4 = round(median(dv) * 1e4, digits = 2) sign_pos = count(>(0), dv) signflip_p = _signflip_p(dv)
end

# ---------------------------------------------------------------------------
# Figure: row per direction — onset-aligned paired trajectories + paired dv
# ---------------------------------------------------------------------------
const _TOG_COLOR = Dict("injection" => _BUY_COLOR, "withdrawal" => _SELL_COLOR)
const PRE = SMOKE ? 40 : 200

panels = Plots.Plot[]
for dir in DIRECTIONS
    p = plot(title = "$(dir.name): cash x$(dir.factor) at onset", titlefont = 10,
             xlabel = "steps since onset", ylabel = "largest cluster / grid",
             guidefont = 8, tickfont = 7, legend = :topleft, legendfontsize = 6)
    seen_lbl = false
    for (i, it) in enumerate(items)
        (it.dir.name == dir.name && results[i].row.included) || continue
        r  = results[i]
        xs = (-min(PRE, r.t_on - 1)):W
        plot!(p, xs, r.maxcl_c[r.t_on .+ xs], color = "#888888", alpha = 0.45,
              lw = 1.0, label = seen_lbl ? "" : "control")
        plot!(p, xs, r.maxcl_t[r.t_on .+ xs], color = _TOG_COLOR[dir.name],
              alpha = 0.45, lw = 1.0, label = seen_lbl ? "" : "toggled")
        seen_lbl = true
    end
    vline!(p, [0], color = :black, ls = :dash, lw = 0.8, label = "")
    push!(panels, p)

    sub = df[(df.direction .== dir.name) .& df.included, :]
    q = plot(ylabel = "front velocity x 1e4 (per step)", guidefont = 8,
             tickfont = 7, legend = false, xticks = ([1, 2], ["control", "toggled"]),
             xlims = (0.6, 2.4), title = "paired velocities", titlefont = 10)
    for r in eachrow(sub)
        plot!(q, [1, 2], [r.v_ctrl, r.v_toggle] .* 1e4,
              color = _TOG_COLOR[dir.name], alpha = 0.5, lw = 1.0, marker = :circle,
              markersize = 3, markerstrokewidth = 0)
    end
    push!(panels, q)
end

fig = plot(panels...; layout = (length(DIRECTIONS), 2), size = (1250, 720),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
           plot_title = "Budget-toggle intervention (paired, onset-aligned; W=$(W))",
           plot_titlefontsize = 11)
savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-BudgetToggle.pdf"))
@info "Saved: ModelB-Nucleation-BudgetToggle.pdf"

@info "Compute-ModelB-BudgetToggle.jl complete."
