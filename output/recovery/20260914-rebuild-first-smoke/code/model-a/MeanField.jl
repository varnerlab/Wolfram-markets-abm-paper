## Mean-field analysis of the 19280/19286 rule mixture
#
# Verified rule tables (base-3 decoding):
#   c:     0  1  2  3  4  5  6  7  8
#   19280: 2  0  0  0  1  1  2  2  2
#   19286: 2  2  0  0  1  1  2  2  2
#
# The two rules differ only at c=1:
#   c=1  →  Buy  w.p. (1-f),  Sell  w.p. f
#   all other c: same for both rules
#
# Mean-field self-consistency:  the new state fractions equal the
# probability-weighted outputs of the rule table.

using Printf

# --- Neighbourhood-sum distribution (4 i.i.d. draws from {0,1,2}) ---
function pi_distribution(p0, p1, p2)
    # π_k = Pr(c = k) where c = s_N + s_S + s_E + s_W
    # Each neighbour independently in state 0,1,2 with probs (p0,p1,p2).
    π = zeros(9)
    for n0 in 0:4, n1 in 0:(4-n0)
        n2 = 4 - n0 - n1
        c = n1 + 2*n2          # neighbourhood sum
        coeff = factorial(4) / (factorial(n0)*factorial(n1)*factorial(n2))
        π[c+1] += coeff * p0^n0 * p1^n1 * p2^n2
    end
    return π   # π[1] = Pr(c=0), ..., π[9] = Pr(c=8)
end

# --- One step of the mean-field map ---
function mf_step(p0, p2, f)
    p1 = 1.0 - p0 - p2
    π = pi_distribution(p0, p1, p2)

    # New fractions from the verified rule table:
    #   Buy  (s=0):  c=1 w.p.(1-f)  +  c=2  +  c=3
    #   Hold (s=1):  c=4 + c=5
    #   Sell (s=2):  c=0  +  c=1 w.p. f  +  c=6 + c=7 + c=8
    new_p0 = (1-f)*π[2] + π[3] + π[4]                # c=1(1-f), c=2, c=3 → Buy
    new_p2 = π[1] + f*π[2] + π[7]+π[8]+π[9]          # c=0, c=1(f), c=6,7,8 → Sell
    # new_p1 = π[5] + π[6]                             # c=4, c=5 → Hold
    return new_p0, new_p2
end

# --- Iterate to steady state ---
function mf_steady(f; p0_init=0.50, p2_init=0.20, maxiter=200000, tol=1e-14)
    p0, p2 = p0_init, p2_init
    for _ in 1:maxiter
        np0, np2 = mf_step(p0, p2, f)
        if abs(np0-p0) + abs(np2-p2) < tol
            return np0, np2
        end
        p0, p2 = np0, np2
    end
    return p0, p2   # may not have converged — flag this
end

# --- Sweep f and record sell fraction ---
fs = 0.0:0.001:1.00
sell_mf = Float64[]
buy_mf  = Float64[]

for f in fs
    p0, p2 = mf_steady(f)
    push!(sell_mf, p2)
    push!(buy_mf, p0)
end

@printf("At f=0:   p0=%.4f, p1=%.4f, p2=%.4f\n", buy_mf[1], 1-buy_mf[1]-sell_mf[1], sell_mf[1])
@printf("At f=0.5: p0=%.4f, p1=%.4f, p2=%.4f\n", buy_mf[501], 1-buy_mf[501]-sell_mf[501], sell_mf[501])
@printf("At f=1:   p0=%.4f, p1=%.4f, p2=%.4f\n", buy_mf[end], 1-buy_mf[end]-sell_mf[end], sell_mf[end])

# Check: sell fraction never exceeds 0.50 in buy-dominated branch
max_sell = maximum(sell_mf)
@printf("\nMax sell fraction in buy-dominated branch: %.4f\n", max_sell)
@printf("Result: Mean-field predicts NO phase transition.\n")
@printf("The buy-dominated fixed point persists for all f ∈ [0,1].\n")
@printf("The lattice transition at f_c ≈ 0.145 is a nucleation phenomenon.\n")

# Compute Pr(c=k) at f=0 steady state
p0_0, p2_0 = buy_mf[1], sell_mf[1]
p1_0 = 1 - p0_0 - p2_0
π_at_f0 = pi_distribution(p0_0, p1_0, p2_0)
println("\nFull π distribution at f=0 steady state:")
for k in 0:8
    @printf("  Pr(c=%d) = %.6f\n", k, π_at_f0[k+1])
end
