# Compute.jl — Price, signal, and grid computations

# ---------------------------------------------------------------------------
# Price series helpers
# ---------------------------------------------------------------------------

"""
    compute_typical_price(df) → Vector{Float64}

Typical price = (High + Low + Close) / 3.
Expects DataFrame columns :High, :Low, :Close.
"""
function compute_typical_price(df::DataFrame)::Vector{Float64}
    # Accept both capitalised (:High) and lowercase (:high) column names
    H = hasproperty(df, :High)  ? df[!, :High]  : df[!, :high]
    L = hasproperty(df, :Low)   ? df[!, :Low]   : df[!, :low]
    C = hasproperty(df, :Close) ? df[!, :Close] : df[!, :close]
    return (H .+ L .+ C) ./ 3.0
end

"""
    compute_ema(x; α) → Vector{Float64}

Exponential moving average: μₜ = μₜ₋₁ + α·(xₜ - μₜ₋₁)
Initialized at x[1].
"""
function compute_ema(x::Vector{Float64}; α::Float64)::Vector{Float64}
    μ    = similar(x)
    μ[1] = x[1]
    for t in 2:length(x)
        μ[t] = μ[t-1] + α * (x[t] - μ[t-1])
    end
    return μ
end

"""
    compute_ema_volatility(x, μ; α) → Vector{Float64}

EMA of absolute deviations: σₜ = σₜ₋₁ + α·(|xₜ - μₜ| - σₜ₋₁)
Initialized at 0.
"""
function compute_ema_volatility(x::Vector{Float64}, μ::Vector{Float64}; α::Float64)::Vector{Float64}
    σ    = similar(x)
    σ[1] = 0.0
    for t in 2:length(x)
        σ[t] = σ[t-1] + α * (abs(x[t] - μ[t]) - σ[t-1])
    end
    return σ
end

"""
    compute_band_state(P, μ, σ, k) → Int64

Classify price relative to band:
    0 (Buy)  if P < μ - k·σ
    1 (Hold) if μ - k·σ ≤ P ≤ μ + k·σ
    2 (Sell) if P > μ + k·σ
"""
function compute_band_state(P::Float64, μ::Float64, σ::Float64, k::Float64)::Int64
    lb = μ - k * σ
    ub = μ + k * σ
    return P < lb ? 0 : (P > ub ? 2 : 1)
end

# ---------------------------------------------------------------------------
# Grid computations
# ---------------------------------------------------------------------------

"""
    compute_net_imbalance(grid, edge_coords) → Float64

Net order imbalance fraction over interior agents (edge agents excluded):
    φ = (N_buy - N_sell) / N_interior
"""
function compute_net_imbalance(
    grid::Array{Int64,2},
    edge_coords::Set{Tuple{Int64,Int64}},
)::Float64
    N_buy = 0; N_sell = 0; N_total = 0
    nrows, ncols = size(grid)
    for r in 1:nrows, c in 1:ncols
        (r, c) ∈ edge_coords && continue
        s       = grid[r, c]
        N_buy   += (s == 0)
        N_sell  += (s == 2)
        N_total += 1
    end
    return N_total > 0 ? (N_buy - N_sell) / N_total : 0.0
end

# ---------------------------------------------------------------------------
# Price model (Model B)
# ---------------------------------------------------------------------------

"""
    compute_price_update(P_prev, φ, λ) → Float64

Exponential price impact update: Pₜ = Pₜ₋₁ · exp(λ · φₜ)
"""
function compute_price_update(P_prev::Float64, φ::Float64, λ::Float64)::Float64
    return P_prev * exp(λ * φ)
end

# ---------------------------------------------------------------------------
# Return series and stylized-fact statistics
# ---------------------------------------------------------------------------

"""
    compute_log_returns(prices) → Vector{Float64}

Log returns: rₜ = ln(Pₜ / Pₜ₋₁)
"""
function compute_log_returns(prices::Vector{Float64})::Vector{Float64}
    return diff(log.(prices))
end

"""
    compute_crash_sizes(frames, threshold) → Vector{Int64}

Identify crash events as contiguous time windows where the fraction of
Sell agents exceeds `threshold`, and return the duration (in steps) of
each such window. Used for power-law / SOC analysis.
"""
function compute_crash_sizes(
    frames::Dict{Int64, Array{Int64,2}};
    threshold::Float64 = 0.5,
)::Vector{Int64}
    steps     = sort(collect(keys(frames)))
    N         = prod(size(frames[steps[1]]))
    in_crash  = false
    duration  = 0
    sizes     = Int64[]

    for t in steps
        f_sell = count(==(2), frames[t]) / N
        if f_sell >= threshold
            in_crash = true
            duration += 1
        else
            if in_crash
                push!(sizes, duration)
                duration = 0
            end
            in_crash = false
        end
    end
    in_crash && push!(sizes, duration)   # close any open crash window
    return sizes
end
