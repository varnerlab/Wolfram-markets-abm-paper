# Compute-RuleScreen.jl
# Screen all 3^9 = 19,683 possible 3-state totalistic CA rules in two passes.
#
# Pass 1 (fast):     64×64 grid, 500 steps, single shared random init
#   Metrics: final entropy H, entropy σ over tail, net imbalance φ, fixed-point flag
#   Output:  data/RuleScreen-Pass1.csv
#
# Pass 2 (detailed): surviving rules on 128×128, 2000 steps
#   Metrics: mean cluster size ξ (spatial correlation proxy),
#            temporal autocorrelation of φ(t),
#            crash-response Δφ after a sell shock at t=1000
#   Output:  data/RuleScreen-Pass2.csv
#
# Wolfram classes assigned:
#   0 — trivial   : near-uniform final state  (H_final < 0.3)
#   1 — stable    : mixed, fixed point         (is_fixed, low H_std)
#   2 — periodic  : oscillating / limit cycle  (moderate H_std)
#   3 — complex   : edge-of-chaos / SOC        (high H_std, mixed population)

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Lightweight helpers (avoid storing all frames like solve() does)
# ---------------------------------------------------------------------------

function _advance!(next::Matrix{Int}, current::Matrix{Int},
                   Q::Dict{Float64,Int64}, decision::Dict{Int64,Int64})
    nrows, ncols = size(current)
    copyto!(next, current)
    @inbounds for r in 2:nrows-1, c in 2:ncols-1
        μ = 0.25 * (current[r, c-1] + current[r, c+1] +
                    current[r-1, c] + current[r+1, c])
        next[r, c] = decision[Q[round(μ; digits=2)]]
    end
end

function _entropy(grid)
    N  = length(grid)
    n0 = count(==(0), grid) / N
    n1 = count(==(1), grid) / N
    n2 = count(==(2), grid) / N
    H  = 0.0
    for f in (n0, n1, n2)
        f > 0.0 && (H -= f * log(f))
    end
    return H
end

function _mean_cluster_size(grid)
    nrows, ncols = size(grid)
    visited = falses(nrows, ncols)
    total   = 0
    count_c = 0
    stack   = Tuple{Int,Int}[]
    for r0 in 1:nrows, c0 in 1:ncols
        visited[r0, c0] && continue
        s  = grid[r0, c0]
        sz = 0
        push!(stack, (r0, c0))
        visited[r0, c0] = true
        while !isempty(stack)
            r, c = pop!(stack)
            sz  += 1
            for (dr, dc) in ((-1,0),(1,0),(0,-1),(0,1))
                nr, nc = r+dr, c+dc
                if 1 ≤ nr ≤ nrows && 1 ≤ nc ≤ ncols &&
                   !visited[nr,nc] && grid[nr,nc] == s
                    visited[nr,nc] = true
                    push!(stack, (nr,nc))
                end
            end
        end
        total   += sz
        count_c += 1
    end
    return count_c > 0 ? total / count_c : 0.0
end

function _autocorr(series::Vector{Float64}, lag::Int=20)
    n  = length(series)
    n ≤ lag && return 0.0
    μ  = mean(series)
    σ² = var(series)
    σ² ≈ 0.0 && return 0.0
    return sum((series[i] - μ) * (series[i+lag] - μ) for i in 1:n-lag) /
           ((n - lag) * σ²)
end

# ---------------------------------------------------------------------------
# Pass 1 — all 19,683 rules
# ---------------------------------------------------------------------------
const NRULES = 3^9        # 19683
const NROWS1 = 64
const NCOLS1 = 64
const STEPS1 = 500
const TAIL1  = 50         # tail window for H_std and fixed-point check

@info "Pass 1: screening all $(NRULES) rules on $(NROWS1)×$(NCOLS1) for $(STEPS1) steps ..."

Random.seed!(42)
init64 = rand(0:2, NROWS1, NCOLS1)

# Pre-build Q and weights once (same for all rules)
_tmp_rule = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=0, colors=3, radius=4))
const _Q  = _tmp_rule.neighborhoodstatesmap

rule_idx  = Int[]
H_final   = Float64[]
H_std_v   = Float64[]
phi_v     = Float64[]
buy_v     = Float64[]
hold_v    = Float64[]
sell_v    = Float64[]
fixed_v   = Bool[]

p = Progress(NRULES; desc="Pass 1: ", showspeed=true)

let cur = copy(init64), nxt = similar(init64)
    for idx in 0:NRULES-1
        rm = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=idx, colors=3, radius=4))
        Q  = rm.neighborhoodstatesmap
        D  = rm.rule

        copyto!(cur, init64)

        tail_H    = zeros(TAIL1)
        tail_snap = [Matrix{Int}(undef, NROWS1, NCOLS1) for _ in 1:TAIL1]

        for step in 1:STEPS1
            _advance!(nxt, cur, Q, D)
            cur, nxt = nxt, cur

            if step > STEPS1 - TAIL1
                ti = step - (STEPS1 - TAIL1)
                tail_H[ti] = _entropy(cur)
                copyto!(tail_snap[ti], cur)
            end
        end

        N      = NROWS1 * NCOLS1
        n0     = count(==(0), cur) / N
        n1     = count(==(1), cur) / N
        n2     = count(==(2), cur) / N
        Hf     = _entropy(cur)
        Hs     = std(tail_H)
        phi    = n0 - n2
        is_fix = all(tail_snap[i] == tail_snap[end] for i in 1:TAIL1)

        push!(rule_idx, idx)
        push!(H_final,  Hf)
        push!(H_std_v,  Hs)
        push!(phi_v,    phi)
        push!(buy_v,    n0)
        push!(hold_v,   n1)
        push!(sell_v,   n2)
        push!(fixed_v,  is_fix)

        next!(p)
    end
end

p1 = DataFrame(
    rule       = rule_idx,
    H_final    = H_final,
    H_std      = H_std_v,
    phi_final  = phi_v,
    buy_frac   = buy_v,
    hold_frac  = hold_v,
    sell_frac  = sell_v,
    is_fixed   = fixed_v,
)

# Wolfram class labels
p1.wolfram_class = map(eachrow(p1)) do r
    if r.H_final < 0.30
        0   # trivial / near-uniform
    elseif r.is_fixed && r.H_std < 0.01
        1   # stable mixed fixed point
    elseif r.H_std < 0.05
        2   # periodic / oscillating
    else
        3   # complex / edge-of-chaos
    end
end

CSV.write(joinpath(_PATH_TO_DATA, "RuleScreen-Pass1.csv"), p1)

class_counts = combine(groupby(p1, :wolfram_class), nrow => :n)
sort!(class_counts, :wolfram_class)
@info "Pass 1 complete. Class breakdown:\n$(class_counts)"

# Known rules from the paper
for kr in [6158, 19280, 19286]
    r = p1[p1.rule .== kr, :]
    @info "Known rule $(kr): class=$(r.wolfram_class[1])  H=$(round(r.H_final[1], digits=3))  H_std=$(round(r.H_std[1], digits=4))  is_fixed=$(r.is_fixed[1])"
end

# ---------------------------------------------------------------------------
# Pass 2 — detailed characterization of Class 1, 2, 3 survivors
# ---------------------------------------------------------------------------
survivors = filter(r -> r.wolfram_class == 3, p1)
@info "Pass 2: $(nrow(survivors)) survivors on 128×128 for 2000 steps ..."

const NROWS2   = 128
const NCOLS2   = 128
const STEPS2   = 2000
const SHOCK_T  = 1000   # step at which sell shock is applied

Random.seed!(42)
init128 = rand(0:2, NROWS2, NCOLS2)

p2_rule    = Int[]
p2_xi      = Float64[]
p2_ac      = Float64[]
p2_shock   = Float64[]
p2_H       = Float64[]
p2_class   = Int[]
p2_buy     = Float64[]
p2_hold    = Float64[]
p2_sell    = Float64[]

q = Progress(nrow(survivors); desc="Pass 2: ", showspeed=true)

let cur2 = copy(init128), nxt2 = similar(init128)
    for row in eachrow(survivors)
        idx = row.rule
        rm  = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=idx, colors=3, radius=4))
        Q2  = rm.neighborhoodstatesmap
        D2  = rm.rule

        copyto!(cur2, init128)

        N2            = NROWS2 * NCOLS2
        phi_ts        = zeros(STEPS2)
        phi_pre_shock = 0.0

        for step in 1:STEPS2
            if step == SHOCK_T
                phi_pre_shock = (count(==(0), cur2) - count(==(2), cur2)) / N2
                cur2[2:end-1, 2:end-1] .= 2
            end

            _advance!(nxt2, cur2, Q2, D2)
            cur2, nxt2 = nxt2, cur2

            phi_ts[step] = (count(==(0), cur2) - count(==(2), cur2)) / N2
        end

        phi_post  = mean(phi_ts[SHOCK_T+1 : min(SHOCK_T+100, STEPS2)])
        delta_phi = phi_post - phi_pre_shock

        ξ  = _mean_cluster_size(cur2)
        ac = _autocorr(phi_ts[1:SHOCK_T-1], 20)
        Hf = _entropy(cur2)
        n0 = count(==(0), cur2) / N2
        n1 = count(==(1), cur2) / N2
        n2 = count(==(2), cur2) / N2

        push!(p2_rule,  idx)
        push!(p2_xi,    ξ)
        push!(p2_ac,    ac)
        push!(p2_shock, delta_phi)
        push!(p2_H,     Hf)
        push!(p2_class, row.wolfram_class)
        push!(p2_buy,   n0)
        push!(p2_hold,  n1)
        push!(p2_sell,  n2)

        next!(q)
    end
end

p2 = DataFrame(
    rule          = p2_rule,
    xi            = p2_xi,
    autocorr      = p2_ac,
    shock_delta   = p2_shock,
    H_final       = p2_H,
    wolfram_class = p2_class,
    buy_frac      = p2_buy,
    hold_frac     = p2_hold,
    sell_frac     = p2_sell,
)
sort!(p2, :xi; rev=true)

CSV.write(joinpath(_PATH_TO_DATA, "RuleScreen-Pass2.csv"), p2)
@info "Pass 2 complete. Top 20 rules by spatial correlation length:"
println(first(p2[:, [:rule, :xi, :autocorr, :shock_delta, :wolfram_class]], 20))

@info "Known rules in Pass 2:"
for kr in [6158, 19280, 19286]
    r = p2[p2.rule .== kr, :]
    isempty(r) && continue
    @info "  Rule $(kr): class=$(r.wolfram_class[1])  ξ=$(round(r.xi[1], digits=1))  ac=$(round(r.autocorr[1], digits=3))  Δφ_shock=$(round(r.shock_delta[1], digits=3))"
end
