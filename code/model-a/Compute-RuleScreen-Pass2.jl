# Compute-RuleScreen-Pass2.jl
# Loads Pass 1 results and runs detailed Pass 2 on Class 3 (complex) rules only.
# Requires: data/RuleScreen-Pass1.csv  (produced by Compute-RuleScreen.jl Pass 1)
# Produces: data/RuleScreen-Pass2.csv

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Helpers
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
        sz = 0
        push!(stack, (r0, c0))
        visited[r0, c0] = true
        s = grid[r0, c0]
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
# Load Pass 1 and filter to Class 3 only
# ---------------------------------------------------------------------------
p1 = CSV.read(joinpath(_PATH_TO_DATA, "RuleScreen-Pass1.csv"), DataFrame)
survivors = filter(r -> r.wolfram_class == 3, p1)
@info "Pass 2: $(nrow(survivors)) Class-3 rules on 128×128 for 2000 steps ..."

const NROWS2  = 128
const NCOLS2  = 128
const STEPS2  = 2000
const SHOCK_T = 1000

Random.seed!(42)
init128 = rand(0:2, NROWS2, NCOLS2)

p2_rule  = Int[];    p2_xi    = Float64[]; p2_ac    = Float64[]
p2_shock = Float64[];p2_H     = Float64[]; p2_class = Int[]
p2_buy   = Float64[];p2_hold  = Float64[]; p2_sell  = Float64[]

q = Progress(nrow(survivors); desc="Pass 2: ", showspeed=true)

let cur = copy(init128), nxt = similar(init128)
    for row in eachrow(survivors)
        idx = row.rule
        rm  = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=idx, colors=3, radius=4))
        Q   = rm.neighborhoodstatesmap
        D   = rm.rule

        copyto!(cur, init128)

        N2            = NROWS2 * NCOLS2
        phi_ts        = zeros(STEPS2)
        phi_pre_shock = 0.0

        for step in 1:STEPS2
            if step == SHOCK_T
                phi_pre_shock = (count(==(0), cur) - count(==(2), cur)) / N2
                cur[2:end-1, 2:end-1] .= 2
            end
            _advance!(nxt, cur, Q, D)
            cur, nxt = nxt, cur
            phi_ts[step] = (count(==(0), cur) - count(==(2), cur)) / N2
        end

        phi_post  = mean(phi_ts[SHOCK_T+1 : min(SHOCK_T+100, STEPS2)])
        delta_phi = phi_post - phi_pre_shock
        ξ         = _mean_cluster_size(cur)
        ac        = _autocorr(phi_ts[1:SHOCK_T-1], 20)
        Hf        = _entropy(cur)
        n0        = count(==(0), cur) / N2
        n1        = count(==(1), cur) / N2
        n2        = count(==(2), cur) / N2

        push!(p2_rule, idx);   push!(p2_xi, ξ);       push!(p2_ac, ac)
        push!(p2_shock, delta_phi); push!(p2_H, Hf);  push!(p2_class, row.wolfram_class)
        push!(p2_buy, n0);     push!(p2_hold, n1);    push!(p2_sell, n2)

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
@info "Pass 2 complete. Top 20 by spatial correlation length:"
println(first(p2[:, [:rule, :xi, :autocorr, :shock_delta, :H_final]], 20))

@info "Known rules:"
for kr in [6158, 19280, 19286]
    r = p2[p2.rule .== kr, :]
    isempty(r) && (@info "  Rule $kr: not in Class 3 (survived Pass 1 as Class $(p1[p1.rule .== kr, :wolfram_class][1]))"); continue
    @info "  Rule $kr: ξ=$(round(r.xi[1],digits=1))  ac=$(round(r.autocorr[1],digits=3))  Δφ=$(round(r.shock_delta[1],digits=3))"
end
