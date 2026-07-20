# Compute-ModelB-Nucleation-EscapeTime.jl — the shared instrumented campaign for the two
# confirmatory analyses of the nucleation-spine spec (Part 1):
#
#   A1 (escape-time / barrier law): does Model A's Kramers form
#   lnτ = A + B/(f − f0) survive under budgets, and does cash shift the
#   barrier? f-sweep × cash {500, 1000, 5000}, censoring-aware medians,
#   profile fit + seed bootstrap CIs.
#
#   A2 (velocity vs ABSOLUTE suppression): five cash doses at f = 0.20;
#   onset-aligned OLS front velocity vs mean suppressed-buy orders/step
#   (absolute, unnormalized — fixes the per-panel-scaling flaw), Spearman +
#   permutation p.
#
# Definitions COMPOSE WITH THE BUDGET TOGGLE, not boundary-vs-bulk: clusters
# are full-grid 4-neighbour BFS on Sell; onset = largest cluster ≥ 5% of the
# grid. (Boundary-vs-bulk used interior-only labeling for birth attribution;
# here fronts and onsets must line up with the toggle's intervention results.)
#
# Writes: code/data/ModelB-Nucleation-EscapeTime.csv                (one row per run)
#         code/data/ModelB-Nucleation-EscapeTime-Fits.csv           (A1 fits + boot CIs)
#         code/data/ModelB-Nucleation-EscapeTime-Trajectories.csv   (f = 0.20 runs, wide)
#
# Launch: julia -t 8 code/model-b/Compute-ModelB-Nucleation-EscapeTime.jl
# Smoke:  ESCAPE_SMOKE=1 julia code/model-b/Compute-ModelB-Nucleation-EscapeTime.jl
#         (tiny grid/horizon — exercises the full path, outputs are smoke)
#
# Threading contract (house rule): results land in preallocated vectors
# indexed by work-item id; file I/O, fits, and RNG-based statistics all run
# on the main thread after the sweep. Deterministic end to end: a rerun must
# reproduce the CSVs byte-identically.

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

const SMOKE = get(ENV, "ESCAPE_SMOKE", "0") == "1"
SMOKE && @warn "ESCAPE_SMOKE=1 — tiny grid and horizon; outputs are smoke artifacts only"

const P0         = 100.0
const GRIDN      = SMOKE ? 32 : 64
const STEPS      = SMOKE ? 300 : 2000
const N_CELLS    = GRIDN * GRIDN
const ONSET_FRAC = 0.05
const V_LO       = SMOKE ? 10 : 50       # velocity window start (after onset)
const V_HI       = SMOKE ? 100 : 400     # velocity window end = toggle's W

const PILOT_F       = SMOKE ? [0.20, 0.30] : [0.12, 0.15, 0.18, 0.20, 0.25, 0.30]
const CASH_A1       = SMOKE ? [500.0, 5000.0] : [500.0, 1000.0, 5000.0]
const F_A2          = 0.20
const CASH_A2_EXTRA = SMOKE ? Float64[] : [250.0, 2000.0]
const SEEDS_PILOT   = SMOKE ? (1:2) : (1:20)
const SEEDS_REFINE  = 1:40

# Refinement f-values near each cash level's divergence, chosen at the plan's
# Task 6 checkpoint from the pilot (2026-07-20). Pilot onset table (n = 20
# seeds per point; rate = fraction with onset by STEPS, med = KM median t_on):
#
#   f:            0.12  0.15  0.18  0.20  0.25  0.30
#   cash  500  →  0.00  0.10  0.85  1.00  1.00  1.00   med(0.18) =  891
#   cash 1000  →  0.00  0.10  0.80  1.00  1.00  1.00   med(0.18) = 1078
#   cash 5000  →  0.00  0.10  0.80  0.95  1.00  1.00   med(0.18) =  663
#
# The cliff sits between f_a = 0.15 and f_b = 0.18 at EVERY cash level, so
# the plan's rule (4 interior points of range(f_a, f_b; length = 6)[2:5],
# i.e. {0.156, 0.162, 0.168, 0.174}) applies identically to all three, at 40
# seeds each. Full production reruns pilot + refine + a2x in one
# deterministic pass.
const REFINE = SMOKE ? NamedTuple{(:f, :cash),Tuple{Float64,Float64}}[] : [
    (f = 0.156, cash = 500.0),  (f = 0.162, cash = 500.0),
    (f = 0.168, cash = 500.0),  (f = 0.174, cash = 500.0),
    (f = 0.156, cash = 1000.0), (f = 0.162, cash = 1000.0),
    (f = 0.168, cash = 1000.0), (f = 0.174, cash = 1000.0),
    (f = 0.156, cash = 5000.0), (f = 0.162, cash = 5000.0),
    (f = 0.168, cash = 5000.0), (f = 0.174, cash = 5000.0),
]

function _escape_config(; f, cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = f,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end

"""One run: simulate, reduce dense frames to the maxcl series, extract stats."""
function _run_one(f::Float64, cash::Float64, seed::Int, stage::String)
    res   = simulate(_escape_config(f = f, cash = cash, seed = seed);
                     snapshot_steps = collect(1:STEPS), verbose = false)
    maxcl = maxcl_series(res.frames, STEPS)
    t_on  = onset_step(maxcl, N_CELLS, ONSET_FRAC)
    a2ok  = t_on > 0 && t_on + V_HI <= STEPS
    v     = a2ok ? window_velocity(maxcl, N_CELLS, t_on; lo = V_LO, hi = V_HI) : NaN
    supp  = a2ok ? mean(@view res.suppressed_buys[(t_on + V_LO):(t_on + V_HI)]) : NaN
    row = (stage = stage, f = f, cash = cash, seed = seed,
           t_on = t_on, censored = t_on == 0,
           v_front = v, suppb_w = supp,
           price_end = res.prices[end], maxcl_end = maxcl[end] / N_CELLS)
    return (row = row, traj = f == F_A2 ? maxcl : Int[])
end

# ---------------------------------------------------------------------------
# Work items: pilot grid × A1 cash, the A2 dose extension, then refinement
# ---------------------------------------------------------------------------
items = NamedTuple{(:f, :cash, :seed, :stage),Tuple{Float64,Float64,Int,String}}[]
for f in PILOT_F, cash in CASH_A1, seed in SEEDS_PILOT
    push!(items, (f = f, cash = cash, seed = seed, stage = "pilot"))
end
for cash in CASH_A2_EXTRA, seed in SEEDS_PILOT
    push!(items, (f = F_A2, cash = cash, seed = seed, stage = "a2x"))
end
for r in REFINE, seed in SEEDS_REFINE
    push!(items, (f = r.f, cash = r.cash, seed = seed, stage = "refine"))
end

@info "Escape-time campaign" n_runs = length(items) grid = GRIDN steps = STEPS n_refine = length(REFINE) threads = Threads.nthreads()

results = Vector{Union{Nothing,NamedTuple}}(nothing, length(items))
Threads.@threads :dynamic for i in eachindex(items)
    it = items[i]
    results[i] = _run_one(it.f, it.cash, it.seed, it.stage)
end
@assert all(!isnothing, results)

df = DataFrame()
for r in results
    push!(df, r.row)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), df)
@info "Saved: ModelB-Nucleation-EscapeTime.csv" rows = nrow(df)

# Trajectories (f = 0.20 only) — Phase 2 exemplar insurance, wide integer counts
tidx = [i for i in eachindex(items) if !isempty(results[i].traj)]
meta = DataFrame(f = [items[i].f for i in tidx], cash = [items[i].cash for i in tidx],
                 seed = [items[i].seed for i in tidx], gridn = fill(GRIDN, length(tidx)))
tmat = reduce(vcat, [permutedims(results[i].traj) for i in tidx])
tdf  = hcat(meta, DataFrame(tmat, ["t$(t)" for t in 1:STEPS]))
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime-Trajectories.csv"), tdf)
@info "Saved: ModelB-Nucleation-EscapeTime-Trajectories.csv" rows = nrow(tdf)

# ---------------------------------------------------------------------------
# A1: censored medians, onset rates, Kramers fits + bootstrap CIs (main thread)
# ---------------------------------------------------------------------------
fitrows = NamedTuple[]
for cash in CASH_A1
    sub   = df[(df.cash .== cash) .& (df.stage .!= "a2x"), :]
    fvals = sort(unique(sub.f))
    meds  = [censored_median(Int.(sub.t_on[sub.f .== f])) for f in fvals]
    onr   = [mean(sub.t_on[sub.f .== f] .> 0) for f in fvals]
    ok    = .!isnan.(meds)
    @info "A1 onset summary" cash fvals = round.(fvals, digits = 3) onset_rate = round.(onr, digits = 2) median_ton = [isnan(m) ? "NaN" : string(Int(m)) for m in meds]
    if count(ok) >= 4
        fit = kramers_profile_fit(fvals[ok], log.(meds[ok]))
        bs  = bootstrap_kramers(collect(sub.f), Int.(sub.t_on); ndraws = 2000, rng = Xoshiro(7))
        ci(v) = isempty(v) ? (NaN, NaN) : (quantile(v, 0.025), quantile(v, 0.975))
        (Alo, Ahi) = ci(bs.A); (Blo, Bhi) = ci(bs.B); (f0lo, f0hi) = ci(bs.f0)
        push!(fitrows, (cash = cash, n_points = count(ok), A = fit.A, B = fit.B,
                        f0 = fit.f0, r2 = fit.r2, A_lo = Alo, A_hi = Ahi,
                        B_lo = Blo, B_hi = Bhi, f0_lo = f0lo, f0_hi = f0hi,
                        n_boot = length(bs.f0)))
        @info "A1 Kramers fit" cash A = round(fit.A, digits = 3) B = round(fit.B, digits = 4) f0 = round(fit.f0, digits = 4) r2 = round(fit.r2, digits = 4) f0_ci = (round(f0lo, digits = 4), round(f0hi, digits = 4)) B_ci = (round(Blo, digits = 4), round(Bhi, digits = 4)) n_boot = length(bs.f0)
    else
        push!(fitrows, (cash = cash, n_points = count(ok), A = NaN, B = NaN,
                        f0 = NaN, r2 = NaN, A_lo = NaN, A_hi = NaN, B_lo = NaN,
                        B_hi = NaN, f0_lo = NaN, f0_hi = NaN, n_boot = 0))
        @warn "A1 Kramers fit SKIPPED — fewer than 4 defined medians" cash n_defined = count(ok)
    end
end
fits_df = DataFrame(fitrows)
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime-Fits.csv"), fits_df)
@info "Saved: ModelB-Nucleation-EscapeTime-Fits.csv"

# Confirmation criterion 2: tight-vs-loose CI separation on f0 and B
let t = fits_df[fits_df.cash .== minimum(CASH_A1), :],
    l = fits_df[fits_df.cash .== maximum(CASH_A1), :]
    if nrow(t) == 1 && nrow(l) == 1 && t.n_boot[1] > 0 && l.n_boot[1] > 0
        sep_f0 = t.f0_lo[1] > l.f0_hi[1] || l.f0_lo[1] > t.f0_hi[1]
        sep_B  = t.B_lo[1]  > l.B_hi[1]  || l.B_lo[1]  > t.B_hi[1]
        @info "A1 criterion 2 (tight vs loose bootstrap-CI separation)" sep_f0 sep_B
    end
end

# ---------------------------------------------------------------------------
# A2: velocity vs absolute suppression at f = 0.20 (five doses)
# ---------------------------------------------------------------------------
a2  = df[(df.f .== F_A2) .& .!isnan.(df.v_front), :]
nex = count((df.f .== F_A2) .& isnan.(df.v_front))
if nrow(a2) >= 10
    sp = spearman_perm_p(collect(Float64.(a2.suppb_w)), collect(Float64.(a2.v_front)))
    @info "A2 velocity vs suppression" n = nrow(a2) excluded = nex rho = round(sp.rho, digits = 3) perm_p = round(sp.p, digits = 4) criterion_met = (sp.rho < 0 && sp.p < 0.05)
    for cash in sort(unique(a2.cash))
        s = a2[a2.cash .== cash, :]
        @info "A2 dose" cash n = nrow(s) median_v_e4 = round(median(s.v_front) * 1e4, digits = 2) median_suppb = round(median(s.suppb_w), digits = 1)
    end
else
    @warn "A2 underpowered — too few included runs at f = 0.20" n = nrow(a2) excluded = nex
end

@info "Compute-ModelB-Nucleation-EscapeTime.jl complete."
