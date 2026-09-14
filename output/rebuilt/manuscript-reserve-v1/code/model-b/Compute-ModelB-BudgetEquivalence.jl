## Compute-ModelB-BudgetEquivalence.jl
#
# Does initial cash change the onset-time law?
#
# Section 7.3 reported that the bootstrap confidence intervals for the fitted
# f0 and B overlap between cash levels. Overlapping intervals are not evidence
# of equivalence: two estimates can have overlapping intervals while their
# difference is large and poorly determined. The correct object is the sampling
# distribution of the DIFFERENCE, which this script computes, together with an
# equivalence test against a margin stated in advance.
#
# Design. The three cash arms were run on identical disorder seeds at every f
# (verified below), so the bootstrap is PAIRED: each draw resamples seed
# positions once per f and applies the same resampled positions to all three
# arms, then refits ln tau = A + B/(f - f0) separately per arm and differences
# the results within the draw. Pairing removes the shared disorder variance
# from the difference and is strictly more powerful than differencing
# independently drawn fits. A draw is discarded for every arm if any arm fails
# to retain the four f-points that a three-parameter fit requires, so the
# pairing is never broken.
#
# Reported quantities, per pair of cash levels:
#
#   d_f0, d_B         differences in the fitted parameters, as in Figure 8
#   d_lntau(f_ref)    difference in the PREDICTED log median onset time at a
#                     reference f. This is the interpretable quantity: it is
#                     the log ratio of predicted onset times, so a value of
#                     ln 2 means one arm takes twice as long to nucleate.
#
# Equivalence margin. Stated in advance and applied to d_lntau: a factor of two
# in median onset time, |d_lntau| < ln 2. Two one-sided tests at alpha = 0.05
# are equivalent to asking whether the 90% interval lies entirely inside the
# margin, so that interval is what the verdict uses; the 95% interval is also
# reported as the estimate of the difference. No margin is asserted for f0 or B
# on their own, because no defensible one exists in those units — their
# intervals are reported descriptively.
#
# Run from code/: julia --project=. model-b/Compute-ModelB-BudgetEquivalence.jl
# Writes: code/data/ModelB-Nucleation-BudgetEquivalence.csv

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

using Random, Printf

const NDRAWS = 4000
const MARGIN = log(2.0)     # equivalence margin on the log onset-time ratio

df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
a1 = df[df.stage .!= "a2x", :]          # same A1 subset the barrier-law analysis uses
cashes = sort(unique(a1.cash))
fvals  = sort(unique(a1.f))

# ─── Verify the pairing assumption before relying on it ───────────────────
for f in fvals
    s = a1[a1.f .== f, :]
    seedsets = [sort(s[s.cash .== c, :seed]) for c in cashes]
    @assert length(unique(seedsets)) == 1 "seed sets differ across cash at f = $f"
end
@info "Paired design verified: identical seed sets across all cash levels at every f."

# Per (cash, f), the onset times ordered by seed, so that one resampled index
# vector addresses the same disorder realizations in every arm.
tons = Dict((c, f) => a1[(a1.cash .== c) .& (a1.f .== f), :][sortperm(a1[(a1.cash .== c) .& (a1.f .== f), :seed]), :t_on]
            for c in cashes, f in fvals)
nseed = Dict(f => length(tons[(cashes[1], f)]) for f in fvals)

# ─── Point estimates ──────────────────────────────────────────────────────
function fit_arm(get_tons)
    pf = Float64[]; pm = Float64[]
    for f in fvals
        m = censored_median(get_tons(f))
        isnan(m) || (push!(pf, f); push!(pm, log(m)))
    end
    length(pf) >= 4 || return nothing
    return (fit = kramers_profile_fit(pf, pm), fs = pf)
end

point = Dict{Float64,Any}()
for c in cashes
    r = fit_arm(f -> tons[(c, f)])
    r === nothing && error("point fit failed for cash $c")
    point[c] = r
    @printf("  cash %6.0f │ A = %6.3f │ B = %6.4f │ f0 = %6.4f │ R² = %.3f │ %d f-points\n",
            c, r.fit.A, r.fit.B, r.fit.f0, r.fit.r2, length(r.fs))
end

# Reference f values: those retaining a defined median in EVERY arm, so the
# predicted onset time is an interpolation for all three fits rather than an
# extrapolation for any of them.
# EVERY shared f is reported, not a chosen one. The difference between two
# fitted curves is strongly f-dependent: as f grows, ln tau tends to A and the
# curves converge, so an equivalence test evaluated only at high f would pass
# almost regardless of the data. Reporting the whole shared range shows where
# the arms are separable and where they are not.
common_fs = intersect([Set(point[c].fs) for c in cashes]...)
f_refs = sort(collect(common_fs))
@info "Predicted onset time compared at every shared f: $(f_refs)"

lntau(fit, f) = fit.A + fit.B / (f - fit.f0)

# ─── Paired bootstrap ─────────────────────────────────────────────────────
rng = Xoshiro(11)
pairs = [(a, b) for (i, a) in enumerate(cashes) for (j, b) in enumerate(cashes) if i < j]
quantities = vcat(["f0", "B"], ["lntau@$(f)" for f in f_refs])
draws = Dict((a, b, q) => Float64[] for (a, b) in pairs for q in quantities)

kept = 0
for _ in 1:NDRAWS
    global kept
    # One resampled index vector per f, shared by every arm — this is the pairing.
    idx = Dict(f => rand(rng, 1:nseed[f], nseed[f]) for f in fvals)
    fits = Dict{Float64,Any}()
    ok = true
    for c in cashes
        r = fit_arm(f -> tons[(c, f)][idx[f]])
        r === nothing && (ok = false; break)
        fits[c] = r.fit
    end
    ok || continue          # discard for ALL arms, never breaking the pairing
    kept += 1
    for (a, b) in pairs
        push!(draws[(a, b, "f0")], fits[a].f0 - fits[b].f0)
        push!(draws[(a, b, "B")],  fits[a].B  - fits[b].B)
        for f in f_refs
            push!(draws[(a, b, "lntau@$(f)")], lntau(fits[a], f) - lntau(fits[b], f))
        end
    end
end
@info "Bootstrap: $(kept)/$(NDRAWS) draws retained four or more f-points in every arm."

# ─── Report and write ─────────────────────────────────────────────────────
out = DataFrame(cash_a=Float64[], cash_b=Float64[], quantity=String[],
                point_estimate=Float64[], median_draw=Float64[],
                ci95_lo=Float64[], ci95_hi=Float64[],
                ci90_lo=Float64[], ci90_hi=Float64[],
                margin=Union{Missing,Float64}[],
                equivalent_at_margin=Union{Missing,Bool}[],
                excludes_zero=Bool[], n_draws=Int[])

println("\n" * "="^100)
println("  Paired between-cash differences ($(kept) draws). Equivalence margin on ln-onset-time: ±$(round(MARGIN, digits=3)) (a factor of 2)")
println("="^100)

for (a, b) in pairs
    for q in quantities
        v = draws[(a, b, q)]
        isempty(v) && continue
        pt = if q == "f0"; point[a].fit.f0 - point[b].fit.f0
             elseif q == "B"; point[a].fit.B - point[b].fit.B
             else
                 f = parse(Float64, split(q, "@")[2])
                 lntau(point[a].fit, f) - lntau(point[b].fit, f)
             end
        lo95, hi95 = quantile(v, 0.025), quantile(v, 0.975)
        lo90, hi90 = quantile(v, 0.05),  quantile(v, 0.95)
        is_lntau = startswith(q, "lntau")
        marg = is_lntau ? MARGIN : missing
        equiv = is_lntau ? (lo90 > -MARGIN && hi90 < MARGIN) : missing
        excl0 = lo95 > 0 || hi95 < 0
        push!(out, (a, b, q, pt, median(v), lo95, hi95, lo90, hi90, marg, equiv, excl0, length(v)))

        verdict = is_lntau ? (equiv ? "EQUIVALENT within ±ln2" :
                              "NOT resolved to ±ln2") : ""
        @printf("  cash %6.0f vs %6.0f │ %-14s │ point %+8.4f │ 95%% CI [%+8.4f, %+8.4f] │ %s%s\n",
                a, b, q, pt, lo95, hi95,
                excl0 ? "differs from 0" : "includes 0",
                isempty(verdict) ? "" : " │ " * verdict)
    end
end

CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetEquivalence.csv"), out)
println("\nWrote code/data/ModelB-Nucleation-BudgetEquivalence.csv ($(nrow(out)) rows)")
