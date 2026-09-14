## Compute-FiniteSizeScaling.jl
#
# System-size scaling of the sell-state escape from the mixed attractor.
#
# The mixed attractor is metastable and all-Sell is absorbing, so escape is a
# nucleation-and-growth process rather than an equilibrium transition; the
# apparent threshold is where the escape time crosses the observation horizon,
# which is why it moves with both the horizon and the lattice. The nucleation
# and growth stages scale oppositely in the linear size L, so this campaign
# separates them (see FiniteSize-Lib.jl for the primitives):
#
#   t_nuc   largest sell cluster first reaches n_crit cells
#   t_half  sell fraction first exceeds 0.50
#   t_conv  sell fraction first exceeds 0.90 (the convention used by
#           Compute-NucleationFit.jl, so the L = 64 column is comparable)
#
# Predictions under independent local nucleation at rate I per site per step:
#
#   single-nucleus regime   t_nuc ~ 1/(I L^2),  t_conv - t_nuc ~ L / v
#   many-nucleus (KJMA)     t_conv -> (I v^2)^(-1/3), independent of L, with
#                           relative dispersion in t_conv falling as N^(-1/2)
#
# n_clusters_at_half separates the regimes directly: 1 in the former, many in
# the latter. Periodic boundaries throughout; no price data is involved.
#
# Two passes run from the same code path:
#
#   SURVEY  wide f and L grid; measures conversion probability, saturation and
#           dispersion collapse.               -> ModelA-FiniteSizeScaling.csv
#   RATE    low f only, with a finer labeling cadence and a smaller nucleation
#           criterion, so the nucleation-rate exponent is biased neither by
#           incubation time nor by the cadence floor.
#                                              -> ModelA-NucleationRate.csv
#
# A derived per-cell table is also written so that manuscript numbers cite a
# committed artifact rather than a rerun.
#                                              -> ModelA-FiniteSizeSummary.csv
#
# Run from code/: julia --project=. -t auto model-a/Compute-FiniteSizeScaling.jl

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using CSV, DataFrames, Printf, Statistics, Random, Base.Threads
include(joinpath(@__DIR__, "FiniteSize-Lib.jl"))

# ─── Campaign parameters ──────────────────────────────────────────────────
const N_SEEDS = 20
const T_MAX   = 100_000
const BURN_IN = FINITE_SIZE_BURN_IN

# Survey pass: wide grid. A 100-cell criterion sits well above the 30-60 cell
# sell fluctuations of the subcritical mixed state.
const SURVEY_LS    = [32, 64, 128, 256, 512]
const SURVEY_FS    = [0.13, 0.14, 0.145, 0.15, 0.155, 0.16, 0.17, 0.18, 0.20]
const SURVEY_NCRIT = 100
const SURVEY_CHECK = 25

# Avrami pass: measures the nucleation-and-growth rate constant from the
# transformation curve, which reads only the sell fraction and so is immune to
# the extreme-value contamination that makes any fixed cluster-size criterion
# unusable as a nucleation detector at large L (see FiniteSize-Lib.jl).
# Restricted to f where every seed converts, so no curve is truncated.
const AVRAMI_LS     = [64, 128, 256, 512]
const AVRAMI_FS     = [0.16, 0.17, 0.18, 0.20]
const AVRAMI_SAMPLE = 10        # trajectory sampling cadence, in steps
const AVRAMI_TMAX   = 40_000

function run_pass(name, ls, fs; n_crit, check)
    println("\n" * "=" ^ 84)
    println("  $name pass — L = $(ls), f = $(fs)")
    println("  $(N_SEEDS) seeds, T_MAX = $(T_MAX), n_crit = $(n_crit), " *
            "check every $(check) steps, threads = $(nthreads())")
    println("=" ^ 84)

    rows = NamedTuple[]
    for L in ls, f in fs
        cell = Vector{Any}(undef, N_SEEDS)
        t_wall = @elapsed @threads for s in 1:N_SEEDS
            cell[s] = run_cell(L, f, s; n_crit=n_crit, check=check,
                               t_max=T_MAX, burn_in=BURN_IN)
        end
        append!(rows, cell)

        nuc  = [r.t_nuc  for r in cell if r.nuc_observed]
        conv = [r.t_conv for r in cell if r.conv_observed]
        nclu = [r.n_clusters_at_half for r in cell if r.half_observed]
        @printf("  L=%4d f=%.3f │ nuc %2d/%2d med %8s │ conv %2d/%2d med %8s │ nuclei %5s │ %6.1f s\n",
                L, f, length(nuc), N_SEEDS,
                isempty(nuc) ? "-" : string(round(Int, median(nuc))),
                length(conv), N_SEEDS,
                isempty(conv) ? "-" : string(round(Int, median(conv))),
                isempty(nclu) ? "-" : string(round(median(nclu), digits=1)),
                t_wall)
        flush(stdout)
    end
    return DataFrame(rows)
end

function run_avrami_pass()
    println("\n" * "=" ^ 84)
    println("  AVRAMI pass — L = $(AVRAMI_LS), f = $(AVRAMI_FS)")
    println("  $(N_SEEDS) seeds, T_MAX = $(AVRAMI_TMAX), sampled every $(AVRAMI_SAMPLE) steps")
    println("  X(t) = 1 - exp(-(K t)^n); 2D continuous nucleation predicts n = 3")
    println("=" ^ 84)

    fits  = NamedTuple[]
    trajs = NamedTuple[]
    for L in AVRAMI_LS, f in AVRAMI_FS
        cell = Vector{Any}(undef, N_SEEDS)
        t_wall = @elapsed @threads for s in 1:N_SEEDS
            ts, xs = run_cell_trajectory(L, f, s; t_max=AVRAMI_TMAX, burn_in=BURN_IN,
                                         sample_every=AVRAMI_SAMPLE)
            cell[s] = (ts, xs, fit_avrami(ts, xs))
        end

        for (s, (ts, xs, fit)) in enumerate(cell)
            for (t, x) in zip(ts, xs)
                push!(trajs, (L=L, f=f, seed=s, t=t, sell_fraction=x))
            end
            if fit !== nothing
                push!(fits, (L=L, f=f, seed=s, avrami_n=fit.n, avrami_K=fit.K,
                             r2=fit.r2, npts=fit.npts, baseline=fit.baseline))
            end
        end

        ok = [c[3] for c in cell if c[3] !== nothing]
        @printf("  L=%4d f=%.3f │ fitted %2d/%2d │ n = %5.2f ± %.2f │ K = %.5f │ R² %.3f │ %6.1f s\n",
                L, f, length(ok), N_SEEDS,
                isempty(ok) ? NaN : mean(o.n for o in ok),
                length(ok) > 1 ? std(o.n for o in ok) : NaN,
                isempty(ok) ? NaN : mean(o.K for o in ok),
                isempty(ok) ? NaN : mean(o.r2 for o in ok),
                t_wall)
        flush(stdout)
    end
    return DataFrame(fits), DataFrame(trajs)
end

survey = run_pass("SURVEY", SURVEY_LS, SURVEY_FS; n_crit=SURVEY_NCRIT, check=SURVEY_CHECK)
avrami_fits, avrami_trajs = run_avrami_pass()

CSV.write(joinpath(@__DIR__, "..", "data", "ModelA-FiniteSizeScaling.csv"), survey)
CSV.write(joinpath(@__DIR__, "..", "data", "ModelA-AvramiFits.csv"), avrami_fits)
CSV.write(joinpath(@__DIR__, "..", "data", "ModelA-AvramiTrajectories.csv"), avrami_trajs)

# ─── Derived per-cell summary ─────────────────────────────────────────────
# Dispersion and saturation statistics are reported only for cells in which
# every seed converted, so no censored value enters a mean or a variance.
function summarize(df, pass)
    out = DataFrame(pass=String[], L=Int[], f=Float64[],
                    n_seeds=Int[], n_nucleated=Int[], n_converted=Int[],
                    p_convert=Float64[],
                    median_t_nuc=Union{Missing,Float64}[],
                    median_t_conv=Union{Missing,Float64}[],
                    cv_t_conv=Union{Missing,Float64}[],
                    median_growth_time=Union{Missing,Float64}[],
                    median_nuclei_at_half=Union{Missing,Float64}[])
    for L in sort(unique(df.L)), f in sort(unique(df.f))
        s = df[(df.L .== L) .& (df.f .== f), :]
        nrow(s) == 0 && continue
        nuc  = s[s.nuc_observed, :]
        conv = s[s.conv_observed, :]
        both = s[s.conv_observed .& s.nuc_observed, :]
        half = s[s.half_observed, :]
        uncensored = nrow(conv) == nrow(s)
        push!(out, (pass, L, f, nrow(s), nrow(nuc), nrow(conv), nrow(conv) / nrow(s),
                    nrow(nuc)  > 0 ? median(nuc.t_nuc)   : missing,
                    nrow(conv) > 0 ? median(conv.t_conv) : missing,
                    uncensored ? std(conv.t_conv) / mean(conv.t_conv) : missing,
                    nrow(both) > 0 ? median(both.t_conv .- both.t_nuc) : missing,
                    nrow(half) > 0 ? median(half.n_clusters_at_half)   : missing))
    end
    return out
end

summary = summarize(survey, "survey")
CSV.write(joinpath(@__DIR__, "..", "data", "ModelA-FiniteSizeSummary.csv"), summary)

# ─── Is the Avrami rate constant intensive? ───────────────────────────────
# K ∝ (I v^2)^(1/3) with I the per-site nucleation rate: once many nuclei
# contribute, K should not depend on L. A residual slope in ln K vs ln L is
# the signature of a system still converting through a single domain.
println("\n" * "=" ^ 84)
println("  Avrami rate constant K against L (prediction: no dependence)")
println("=" ^ 84)
for f in AVRAMI_FS
    xs = Float64[]; ys = Float64[]
    row = @sprintf("  f = %.3f │", f)
    for L in AVRAMI_LS
        s = avrami_fits[(avrami_fits.L .== L) .& (avrami_fits.f .== f), :]
        nrow(s) >= N_SEEDS ÷ 2 || continue
        row *= @sprintf(" L=%d: K=%.5f n=%.2f │", L, mean(s.avrami_K), mean(s.avrami_n))
        push!(xs, log(L)); push!(ys, log(mean(s.avrami_K)))
    end
    if length(xs) >= 3
        b = cov(xs, ys) / var(xs)
        row *= @sprintf("  d(lnK)/d(lnL) = %+.3f", b)
    end
    println(row)
end

println("\nWrote code/data/ModelA-FiniteSizeScaling.csv     ($(nrow(survey)) rows)")
println("Wrote code/data/ModelA-AvramiFits.csv            ($(nrow(avrami_fits)) rows)")
println("Wrote code/data/ModelA-AvramiTrajectories.csv    ($(nrow(avrami_trajs)) rows)")
println("Wrote code/data/ModelA-FiniteSizeSummary.csv     ($(nrow(summary)) rows)")
