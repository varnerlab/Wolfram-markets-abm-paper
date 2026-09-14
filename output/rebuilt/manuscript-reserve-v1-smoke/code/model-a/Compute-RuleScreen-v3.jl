# Compute-RuleScreen-v3.jl
# Screen CA rules with QQQ-coupled edge agents on boundary cells.
#
# Key changes from v2:
#   - Edge agents = F_EDGE fraction of boundary cells (not 3 fixed interior cells)
#   - Boundary cells are naturally excluded from the rule update loop (2:N-1 × 2:N-1)
#     so they retain their injected QQQ state without needing an explicit exclude set
#   - No figure generation during screening — numbers only, CSV at end
#   - Pass 1: 64×64, 1000 steps
#   - Pass 2: 128×128, 2000 steps, top-50 herding × top-50 contrarian pairs
#
# Analytical pre-filter (same as v2):
#   herding   : rule[0]=0, rule[8]=2  (~2187 rules)
#   contrarian: rule[0]=2, rule[8]=0  (~2187 rules)

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Load QQQ edge signal
# ---------------------------------------------------------------------------
df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)

const α_EMA  = 1/60
const k_BAND = 1.0
const F_EDGE = 0.25   # fraction of boundary cells used as edge agents

ema  = compute_ema(prices; α=α_EMA)
evol = compute_ema_volatility(prices, ema; α=α_EMA)

edge_signal = map(1:length(prices)) do t
    prices[t] > ema[t] + k_BAND * evol[t] && return 2   # overbought → Sell
    prices[t] < ema[t] - k_BAND * evol[t] && return 0   # oversold  → Buy
    return 1
end

@info "Loaded $(length(prices)) price steps  Buy=$(count(==(0),edge_signal))  Hold=$(count(==(1),edge_signal))  Sell=$(count(==(2),edge_signal))"

# ---------------------------------------------------------------------------
# Build boundary edge agent positions for a given grid size
# ---------------------------------------------------------------------------
function _boundary_edge_positions(nrows::Int, ncols::Int, f::Float64; seed::Int=1234)
    boundary = Tuple{Int,Int}[]
    for c in 1:ncols
        push!(boundary, (1, c))
        push!(boundary, (nrows, c))
    end
    for r in 2:nrows-1
        push!(boundary, (r, 1))
        push!(boundary, (r, ncols))
    end
    rng    = Random.MersenneTwister(seed)
    n_edge = round(Int, f * length(boundary))
    return boundary[randperm(rng, length(boundary))[1:n_edge]]
end

# ---------------------------------------------------------------------------
# Pass 1 simulation (no frame storage, no figures)
# ---------------------------------------------------------------------------
const NROWS1  = 64
const NCOLS1  = 64
const NSTEPS1 = 1000

edge_pos1 = _boundary_edge_positions(NROWS1, NCOLS1, F_EDGE)
@info "Pass 1 grid: $(NROWS1)×$(NCOLS1)  Boundary=$(4*(NROWS1+NCOLS1-2))  Edge agents=$(length(edge_pos1)) ($(round(Int,100*F_EDGE))%)"

function _run_pass1(rule_idx::Int, edge_pos::Vector{Tuple{Int,Int}},
                    nrows::Int, ncols::Int, nsteps::Int, edge_sig::Vector{Int})
    rm = build(MyTwoDimensionalTotalisticWolframRuleModel,
               (index=rule_idx, colors=3, radius=4))
    Q = rm.neighborhoodstatesmap
    D = rm.rule

    Random.seed!(1234)
    state = rand(0:2, nrows, ncols)
    nxt   = copy(state)
    N     = nrows * ncols

    buy_acc = 0.0;  hold_acc = 0.0;  sell_acc = 0.0
    phi_ts  = zeros(nsteps)

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
        buy_acc += b;  hold_acc += h;  sell_acc += s
        phi_ts[step] = b - s
    end

    bm = buy_acc / nsteps;  hm = hold_acc / nsteps;  sm = sell_acc / nsteps
    H  = -sum(f * log(f) for f in (bm, hm, sm) if f > 0.0)

    # Also check late-time stability: std of phi in final 200 steps
    phi_late_std = std(phi_ts[end-199:end])

    return (buy      = bm,
            hold     = hm,
            sell     = sm,
            phi_var  = var(phi_ts),
            phi_late_std = phi_late_std,
            H        = H,
            has_all  = bm > 0.05 && hm > 0.05 && sm > 0.05)
end

# ---------------------------------------------------------------------------
# Analytical pre-filter
# ---------------------------------------------------------------------------
herding_rules    = Int[]
contrarian_rules = Int[]

for idx in 0:3^9-1
    d = digits(idx, base=3, pad=9)
    if d[1] == 0 && d[9] == 2
        push!(herding_rules, idx)
    elseif d[1] == 2 && d[9] == 0
        push!(contrarian_rules, idx)
    end
end

@info "Pre-filter: $(length(herding_rules)) herding, $(length(contrarian_rules)) contrarian"

# ---------------------------------------------------------------------------
# Pass 1 — run both classes
# ---------------------------------------------------------------------------
@info "Pass 1: running $(length(herding_rules) + length(contrarian_rules)) rules on $(NROWS1)×$(NCOLS1) for $(NSTEPS1) steps ..."

all_rules  = vcat([(idx, "herding")    for idx in herding_rules],
                  [(idx, "contrarian") for idx in contrarian_rules])

p1_rule=Int[]; p1_type=String[]; p1_buy=Float64[]; p1_hold=Float64[]; p1_sell=Float64[]
p1_pvar=Float64[]; p1_plstd=Float64[]; p1_H=Float64[]; p1_all=Bool[]

prog = Progress(length(all_rules); desc="Pass 1: ", showspeed=true)
for (idx, typ) in all_rules
    r = _run_pass1(idx, edge_pos1, NROWS1, NCOLS1, NSTEPS1, edge_signal)
    push!(p1_rule, idx);      push!(p1_type, typ)
    push!(p1_buy,  r.buy);    push!(p1_hold, r.hold);   push!(p1_sell, r.sell)
    push!(p1_pvar, r.phi_var); push!(p1_plstd, r.phi_late_std)
    push!(p1_H,    r.H);      push!(p1_all,  r.has_all)
    next!(prog)
end

pass1 = DataFrame(rule=p1_rule, type=p1_type, buy=p1_buy, hold=p1_hold, sell=p1_sell,
                  phi_var=p1_pvar, phi_late_std=p1_plstd, H=p1_H, has_all=p1_all)
CSV.write(joinpath(_PATH_TO_DATA, "RuleScreen-v3-Pass1.csv"), pass1)
@info "Pass 1 complete. Saved RuleScreen-v3-Pass1.csv"

# Report known rules
@info "Known rules in Pass 1:"
for kr in [6158, 19280, 19286]
    r = pass1[pass1.rule .== kr, :]
    if isempty(r)
        @info "  Rule $kr: not in herding/contrarian pre-filter"
    else
        @info "  Rule $kr ($(r.type[1])): buy=$(round(r.buy[1],digits=3)) hold=$(round(r.hold[1],digits=3)) sell=$(round(r.sell[1],digits=3))  phi_var=$(round(r.phi_var[1],digits=5))  phi_late_std=$(round(r.phi_late_std[1],digits=4))  has_all=$(r.has_all[1])"
    end
end

herding_surv    = sort(filter(r -> r.has_all && r.type == "herding",    pass1), :phi_var; rev=true)
contrarian_surv = sort(filter(r -> r.has_all && r.type == "contrarian", pass1), :phi_var; rev=true)
@info "Pass 1 survivors: $(nrow(herding_surv)) herding, $(nrow(contrarian_surv)) contrarian"

# ---------------------------------------------------------------------------
# Pass 2 — crash pair screen at larger grid
# ---------------------------------------------------------------------------
const TOP_N   = 50
const NROWS2  = 128
const NCOLS2  = 128
const NSTEPS2 = 2000

edge_pos2 = _boundary_edge_positions(NROWS2, NCOLS2, F_EDGE)
@info "Pass 2 grid: $(NROWS2)×$(NCOLS2)  Edge agents=$(length(edge_pos2))"

top_h   = first(herding_surv,    min(TOP_N, nrow(herding_surv)))
top_c   = first(contrarian_surv, min(TOP_N, nrow(contrarian_surv)))
n_pairs = nrow(top_h) * nrow(top_c)
@info "Pass 2: $(nrow(top_h)) × $(nrow(top_c)) = $n_pairs pairs, $(NSTEPS2) steps ..."

function _run_pass2(major_idx::Int, minor_idx::Int,
                    edge_pos::Vector{Tuple{Int,Int}},
                    nrows::Int, ncols::Int, nsteps::Int,
                    edge_sig::Vector{Int}, f::Float64)
    rm_maj = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=major_idx, colors=3, radius=4))
    rm_min = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=minor_idx, colors=3, radius=4))
    Q_maj = rm_maj.neighborhoodstatesmap;  D_maj = rm_maj.rule
    Q_min = rm_min.neighborhoodstatesmap;  D_min = rm_min.rule

    Random.seed!(1234)
    N      = nrows * ncols
    is_min = falses(nrows, ncols)
    rng    = Random.MersenneTwister(5678)
    for pos in randperm(rng, N)[1:round(Int, f * N)]
        is_min[(pos-1)÷ncols+1, (pos-1)%ncols+1] = true
    end

    state = rand(Random.MersenneTwister(1234), 0:2, nrows, ncols)
    nxt   = copy(state)

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

prog2 = Progress(n_pairs; desc="Pass 2: ", showspeed=true)
for hr in eachrow(top_h), cr in eachrow(top_c)
    res = _run_pass2(hr.rule, cr.rule, edge_pos2, NROWS2, NCOLS2, NSTEPS2, edge_signal, 0.20)
    push!(p2_major, hr.rule);      push!(p2_minor,   cr.rule)
    push!(p2_crash, res.crash_size); push!(p2_buymin, res.buy_min)
    push!(p2_phimean, res.phi_mean); push!(p2_phivar,  res.phi_var)
    next!(prog2)
end

pass2 = DataFrame(major=p2_major, minor=p2_minor, crash_size=p2_crash,
                  buy_min=p2_buymin, phi_mean=p2_phimean, phi_var=p2_phivar)
sort!(pass2, :crash_size; rev=true)
CSV.write(joinpath(_PATH_TO_DATA, "RuleScreen-v3-Pass2.csv"), pass2)

@info "Pass 2 complete. Top 10 pairs by crash size:"
println(first(pass2[:, [:major, :minor, :crash_size, :buy_min, :phi_var]], 10))

@info "Known pair (19280, 19286):"
r = pass2[(pass2.major .== 19280) .& (pass2.minor .== 19286), :]
if isempty(r)
    @info "  Not in surviving pairs"
else
    @info "  crash=$(round(r.crash_size[1],digits=3))  buy_min=$(round(r.buy_min[1],digits=3))  phi_var=$(round(r.phi_var[1],digits=4))"
end
