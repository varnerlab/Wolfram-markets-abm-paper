# Test-EdgeFraction.jl
# Quick sanity check: verify that edge agents on boundary cells correctly
# follow QQQ and influence interior dynamics, for a few known rules.
# Edge agents = f_edge fraction of boundary cells (NOT interior — interior
# cells are overwritten by the rule; boundary cells are not touched by the
# interior loop 2:N-1 × 2:N-1 and so retain their injected state).

include(joinpath(@__DIR__, "Include.jl"))

const NROWS  = 64
const NCOLS  = 64
const NSTEPS = 500
const F_EDGE = 0.25   # fraction of boundary cells used as edge agents
const α_EMA  = 1/60
const k_BAND = 1.0

# ---------------------------------------------------------------------------
# Load QQQ edge signal (corrected: overbought→Sell, oversold→Buy)
# ---------------------------------------------------------------------------
df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)
ema    = compute_ema(prices; α=α_EMA)
evol   = compute_ema_volatility(prices, ema; α=α_EMA)

edge_signal = map(1:length(prices)) do t
    prices[t] > ema[t] + k_BAND * evol[t] && return 2   # overbought → Sell
    prices[t] < ema[t] - k_BAND * evol[t] && return 0   # oversold  → Buy
    return 1
end

# ---------------------------------------------------------------------------
# Build boundary cell list and sample edge agent positions
# ---------------------------------------------------------------------------
# All boundary cells of an NROWS×NCOLS grid (top row, bottom row,
# left col, right col — corners included once each)
boundary = Tuple{Int,Int}[]
for c in 1:NCOLS
    push!(boundary, (1, c))       # top row
    push!(boundary, (NROWS, c))   # bottom row
end
for r in 2:NROWS-1              # left and right cols (exclude corners already added)
    push!(boundary, (r, 1))
    push!(boundary, (r, NCOLS))
end

Random.seed!(1234)
n_edge   = round(Int, F_EDGE * length(boundary))
edge_pos = boundary[randperm(length(boundary))[1:n_edge]]

@info "Grid: $(NROWS)×$(NCOLS)  Boundary cells: $(length(boundary))  Edge agents: $(n_edge) ($(round(100*F_EDGE))%)"

# ---------------------------------------------------------------------------
# Run one rule and print per-step fractions (first 20 steps + every 100)
# ---------------------------------------------------------------------------
function _test_rule(rule_idx::Int)
    rm = build(MyTwoDimensionalTotalisticWolframRuleModel,
               (index=rule_idx, colors=3, radius=4))
    Q = rm.neighborhoodstatesmap
    D = rm.rule

    # Print rule table so we can verify analytically
    println("\n  Rule $rule_idx lookup table:")
    for i in 0:8
        d = digits(rule_idx, base=3, pad=9)
        println("    config $i (mean=$(i/4)) → $(d[i+1])")
    end

    Random.seed!(1234)
    state   = rand(0:2, NROWS, NCOLS)
    nxt     = copy(state)
    N_cells = NROWS * NCOLS

    println("\n  Step | Edge inj | Buy%  | Hold% | Sell%")
    println("  -----|----------|-------|-------|------")

    for step in 1:NSTEPS
        es = edge_signal[step]

        # Inject QQQ signal into boundary edge agents only
        for (r, c) in edge_pos
            state[r, c] = es
        end

        # Verify a sample of edge cells actually have the injected state
        # (boundary cells are NOT touched by the interior loop below)
        copyto!(nxt, state)
        @inbounds for r in 2:NROWS-1, c in 2:NCOLS-1
            μ = 0.25 * (state[r,c-1] + state[r,c+1] + state[r-1,c] + state[r+1,c])
            nxt[r,c] = D[Q[round(μ; digits=2)]]
        end
        state, nxt = nxt, state

        # Verify: edge cells in new state should still equal es
        # (because they are on the boundary → not updated by interior loop)
        wrong = count(pos -> state[pos[1], pos[2]] != es, edge_pos)

        b = round(100 * count(==(0), state) / N_cells, digits=1)
        h = round(100 * count(==(1), state) / N_cells, digits=1)
        s = round(100 * count(==(2), state) / N_cells, digits=1)

        if step <= 20 || step % 100 == 0
            label = es == 0 ? "Buy " : es == 2 ? "Sell" : "Hold"
            flag  = wrong > 0 ? "  ← EDGE MISMATCH ($wrong cells)" : ""
            println("  $(lpad(step,4)) | $label     | $b%  | $h%  | $s% $flag")
        end
    end
end

# Test rules: original contrarian (6158), original sell-biased (19280, 19286),
# and the screen v2 candidate (16788)
for r in [6158, 19280, 19286, 16788]
    println("\n" * "="^60)
    println("RULE $r")
    _test_rule(r)
end
