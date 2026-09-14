# Compute-RuleScreen-v2.jl
# Screen CA rules in the context of the COUPLED Model A (with QQQ edge agents).
# The v1 screen ran rules in isolation — unrealistic because sell states are never
# injected without price-driven boundary forcing.
#
# Step 0 — Analytical pre-filter (no simulation needed):
#   herding   : rule[0]=0  AND rule[8]=2  (follow the crowd at both extremes)
#   contrarian: rule[0]=2  AND rule[8]=0  (go against the crowd at both extremes)
#   ~2187 rules in each class (3^7 free interior configs)
#
# Pass 1 — Run filtered rules with QQQ edge agents (64×64, 2000 steps)
#   Metrics: mean buy/hold/sell fractions, phi variance, entropy
#   Filter:  realistic mix — all fractions > 0.05
#   Output:  data/RuleScreen-v2-Pass1.csv
#
# Pass 2 — Top herding × top contrarian crash pairs (128×128, 3000 steps, f=0.20)
#   Metric: peak-to-trough range of phi (crash size), min buy fraction
#   Output:  data/RuleScreen-v2-Pass2.csv

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Load price data and pre-compute edge agent states
# ---------------------------------------------------------------------------
df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)

const α_EMA  = 1/60
const k_BAND = 1.0

ema  = compute_ema(prices; α=α_EMA)
evol = compute_ema_volatility(prices, ema; α=α_EMA)

edge_signal = map(1:length(prices)) do t
    prices[t] > ema[t] + k_BAND * evol[t] && return 2   # overbought → Sell
    prices[t] < ema[t] - k_BAND * evol[t] && return 0   # oversold  → Buy
    return 1                                              # Hold
end

@info "Loaded $(length(prices)) price steps; edge Buy=$(count(==(0),edge_signal)) Hold=$(count(==(1),edge_signal)) Sell=$(count(==(2),edge_signal))"

# ---------------------------------------------------------------------------
# Step 0: Analytical pre-filter
# ---------------------------------------------------------------------------
# Rule encoding: digit i of the base-3 representation gives next state
# when neighborhood config index = i.
# Config 0 → mean=0.0 (all Buy),  Config 8 → mean=2.0 (all Sell)

herding_rules    = Int[]
contrarian_rules = Int[]

for idx in 0:3^9-1
    d = digits(idx, base=3, pad=9)  # d[1]=rule[0], d[9]=rule[8]
    if d[1] == 0 && d[9] == 2
        push!(herding_rules, idx)
    elseif d[1] == 2 && d[9] == 0
        push!(contrarian_rules, idx)
    end
end

@info "Pre-filter: $(length(herding_rules)) herding, $(length(contrarian_rules)) contrarian"

# ---------------------------------------------------------------------------
# Lightweight coupled simulation (no frame storage)
# ---------------------------------------------------------------------------
function _run_coupled(rule_idx::Int, nrows::Int, ncols::Int,
                      nsteps::Int, edge_sig::Vector{Int})
    rm = build(MyTwoDimensionalTotalisticWolframRuleModel,
               (index=rule_idx, colors=3, radius=4))
    Q  = rm.neighborhoodstatesmap
    D  = rm.rule

    mid_r = div(nrows, 2)
    mid_c = div(ncols, 2)
    edge_pos = ((1, mid_c), (nrows, mid_c), (mid_r, 1))

    Random.seed!(1234)
    state = rand(0:2, nrows, ncols)
    nxt   = copy(state)

    N          = nrows * ncols
    buy_acc    = 0.0
    hold_acc   = 0.0
    sell_acc   = 0.0
    phi_ts     = zeros(nsteps)

    for step in 1:nsteps
        es = edge_sig[min(step, length(edge_sig))]
        for (r, c) in edge_pos
            state[r, c] = es
        end

        copyto!(nxt, state)
        @inbounds for r in 2:nrows-1, c in 2:ncols-1
            μ = 0.25 * (state[r,c-1] + state[r,c+1] + state[r-1,c] + state[r+1,c])
            nxt[r,c] = D[Q[round(μ; digits=2)]]
        end
        state, nxt = nxt, state

        b = count(==(0), state) / N
        h = count(==(1), state) / N
        s = count(==(2), state) / N
        buy_acc  += b;  hold_acc += h;  sell_acc += s
        phi_ts[step] = b - s
    end

    bm = buy_acc / nsteps;  hm = hold_acc / nsteps;  sm = sell_acc / nsteps
    H  = -sum(f * log(f) for f in (bm, hm, sm) if f > 0.0)
    return (buy=bm, hold=hm, sell=sm,
            phi_var  = var(phi_ts),
            H        = H,
            has_all  = bm > 0.05 && hm > 0.05 && sm > 0.05)
end

# ---------------------------------------------------------------------------
# Pass 1A — herding rules
# ---------------------------------------------------------------------------
const NROWS1  = 64
const NCOLS1  = 64
const NSTEPS1 = 2000

@info "Pass 1A: $(length(herding_rules)) herding rules on $(NROWS1)×$(NCOLS1) for $(NSTEPS1) steps ..."

p1h_rule=Int[]; p1h_buy=Float64[]; p1h_hold=Float64[]; p1h_sell=Float64[]
p1h_pvar=Float64[]; p1h_H=Float64[]; p1h_all=Bool[]

prog = Progress(length(herding_rules); desc="Herding:    ", showspeed=true)
for idx in herding_rules
    r = _run_coupled(idx, NROWS1, NCOLS1, NSTEPS1, edge_signal)
    push!(p1h_rule, idx); push!(p1h_buy, r.buy);  push!(p1h_hold, r.hold)
    push!(p1h_sell, r.sell); push!(p1h_pvar, r.phi_var)
    push!(p1h_H, r.H); push!(p1h_all, r.has_all)
    next!(prog)
end

herding_df = DataFrame(rule=p1h_rule, type="herding", buy=p1h_buy, hold=p1h_hold,
                       sell=p1h_sell, phi_var=p1h_pvar, H=p1h_H, has_all=p1h_all)

# ---------------------------------------------------------------------------
# Pass 1B — contrarian rules
# ---------------------------------------------------------------------------
@info "Pass 1B: $(length(contrarian_rules)) contrarian rules ..."

p1c_rule=Int[]; p1c_buy=Float64[]; p1c_hold=Float64[]; p1c_sell=Float64[]
p1c_pvar=Float64[]; p1c_H=Float64[]; p1c_all=Bool[]

prog = Progress(length(contrarian_rules); desc="Contrarian: ", showspeed=true)
for idx in contrarian_rules
    r = _run_coupled(idx, NROWS1, NCOLS1, NSTEPS1, edge_signal)
    push!(p1c_rule, idx); push!(p1c_buy, r.buy);  push!(p1c_hold, r.hold)
    push!(p1c_sell, r.sell); push!(p1c_pvar, r.phi_var)
    push!(p1c_H, r.H); push!(p1c_all, r.has_all)
    next!(prog)
end

contrarian_df = DataFrame(rule=p1c_rule, type="contrarian", buy=p1c_buy, hold=p1c_hold,
                          sell=p1c_sell, phi_var=p1c_pvar, H=p1c_H, has_all=p1c_all)

pass1 = vcat(herding_df, contrarian_df)
CSV.write(joinpath(_PATH_TO_DATA, "RuleScreen-v2-Pass1.csv"), pass1)

# Report known rules
@info "Pass 1 — known rules:"
for kr in [6158, 19280, 19286]
    r = pass1[pass1.rule .== kr, :]
    if isempty(r)
        @info "  Rule $kr: not in herding/contrarian pre-filter"
    else
        @info "  Rule $kr ($(r.type[1])): buy=$(round(r.buy[1],digits=3)) hold=$(round(r.hold[1],digits=3)) sell=$(round(r.sell[1],digits=3))  phi_var=$(round(r.phi_var[1],digits=5))  has_all=$(r.has_all[1])"
    end
end

herding_surv    = sort(filter(r -> r.has_all && r.type == "herding",    pass1), :phi_var; rev=true)
contrarian_surv = sort(filter(r -> r.has_all && r.type == "contrarian", pass1), :phi_var; rev=true)
@info "Pass 1 survivors: $(nrow(herding_surv)) herding, $(nrow(contrarian_surv)) contrarian"

# ---------------------------------------------------------------------------
# Pass 2 — crash pair screen
# ---------------------------------------------------------------------------
const TOP_N   = 50
const NROWS2  = 128
const NCOLS2  = 128
const NSTEPS2 = 3000
const F_MIN   = 0.20

top_h = first(herding_surv,    min(TOP_N, nrow(herding_surv)))
top_c = first(contrarian_surv, min(TOP_N, nrow(contrarian_surv)))
n_pairs = nrow(top_h) * nrow(top_c)
@info "Pass 2: $(nrow(top_h)) × $(nrow(top_c)) = $n_pairs pairs on $(NROWS2)×$(NCOLS2) for $(NSTEPS2) steps, f=$(F_MIN) ..."

function _run_crash_pair(major_idx::Int, minor_idx::Int,
                         nrows::Int, ncols::Int, nsteps::Int,
                         edge_sig::Vector{Int}, f::Float64)
    rm_maj = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=major_idx, colors=3, radius=4))
    rm_min = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=minor_idx, colors=3, radius=4))
    Q_maj  = rm_maj.neighborhoodstatesmap;  D_maj = rm_maj.rule
    Q_min  = rm_min.neighborhoodstatesmap;  D_min = rm_min.rule

    Random.seed!(1234)
    N = nrows * ncols
    is_min = falses(nrows, ncols)
    for pos in randperm(N)[1:round(Int, f * N)]
        is_min[(pos-1)÷ncols+1, (pos-1)%ncols+1] = true
    end

    state = rand(0:2, nrows, ncols)
    nxt   = copy(state)

    mid_r = div(nrows, 2)
    mid_c = div(ncols, 2)
    edge_pos = ((1, mid_c), (nrows, mid_c), (mid_r, 1))

    phi_ts  = zeros(nsteps)
    buy_min = 1.0

    for step in 1:nsteps
        es = edge_sig[min(step, length(edge_sig))]
        for (r, c) in edge_pos
            state[r, c] = es
        end

        copyto!(nxt, state)
        @inbounds for r in 2:nrows-1, c in 2:ncols-1
            Q = is_min[r,c] ? Q_min : Q_maj
            D = is_min[r,c] ? D_min : D_maj
            μ = 0.25 * (state[r,c-1] + state[r,c+1] + state[r-1,c] + state[r+1,c])
            nxt[r,c] = D[Q[round(μ; digits=2)]]
        end
        state, nxt = nxt, state

        b = count(==(0), state) / N
        phi_ts[step] = b - count(==(2), state) / N
        buy_min = min(buy_min, b)
    end

    return (crash_size = maximum(phi_ts) - minimum(phi_ts),
            buy_min    = buy_min,
            phi_mean   = mean(phi_ts),
            phi_var    = var(phi_ts))
end

p2_major=Int[]; p2_minor=Int[]
p2_crash=Float64[]; p2_buymin=Float64[]; p2_phimean=Float64[]; p2_phivar=Float64[]

prog2 = Progress(n_pairs; desc="Pass 2 pairs: ", showspeed=true)

let
    for hr in eachrow(top_h), cr in eachrow(top_c)
        res = _run_crash_pair(hr.rule, cr.rule, NROWS2, NCOLS2, NSTEPS2, edge_signal, F_MIN)
        push!(p2_major,   hr.rule);      push!(p2_minor,   cr.rule)
        push!(p2_crash,   res.crash_size); push!(p2_buymin, res.buy_min)
        push!(p2_phimean, res.phi_mean); push!(p2_phivar,  res.phi_var)
        next!(prog2)
    end
end

pass2 = DataFrame(major=p2_major, minor=p2_minor, crash_size=p2_crash,
                  buy_min=p2_buymin, phi_mean=p2_phimean, phi_var=p2_phivar)
sort!(pass2, :crash_size; rev=true)

CSV.write(joinpath(_PATH_TO_DATA, "RuleScreen-v2-Pass2.csv"), pass2)

@info "Pass 2 complete. Top 20 pairs by crash size:"
println(first(pass2[:, [:major, :minor, :crash_size, :buy_min, :phi_var]], 20))

@info "Known pairs:"
for (maj, min) in [(6158, 19286), (19280, 19286)]
    r = pass2[(pass2.major .== maj) .& (pass2.minor .== min), :]
    if isempty(r)
        @info "  ($maj, $min): not in surviving pairs"
    else
        @info "  ($maj, $min): crash=$(round(r.crash_size[1],digits=3))  buy_min=$(round(r.buy_min[1],digits=3))"
    end
end
