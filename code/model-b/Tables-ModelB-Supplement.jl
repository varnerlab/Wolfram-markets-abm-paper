# Tables-ModelB-Supplement.jl -- supplementary outcome tables S2, S3, and S4
# from the full paired-switch, finite-size, and cash--share campaigns. These
# tabulate quantities quoted in the Results that no figure panel carries. No
# simulations are run here.

include(joinpath(@__DIR__, "Include.jl"))
using Printf

const RULE_PATH    = joinpath(_PATH_TO_DATA, "ModelB-RuleQuench-Full-Summary.csv")
const SCALING_PATH = joinpath(_PATH_TO_DATA, "ModelB-Revision-FiniteSize-Scaling.csv")
const BALANCE_PATH = joinpath(_PATH_TO_DATA, "ModelB-BalanceSheetQuench-Full-Grouped.csv")
all(isfile, (RULE_PATH, SCALING_PATH, BALANCE_PATH)) ||
    error("missing full campaign outputs")

rule = CSV.read(RULE_PATH, DataFrame)
scaling = CSV.read(SCALING_PATH, DataFrame)
balance = CSV.read(BALANCE_PATH, DataFrame)

# The rule-switch summary stores a peak Sell fraction per path and writes onset
# zero for a path that never crossed, so the majority criterion is applied to
# the peak rather than to the presence of an onset.
_crossed(peak) = peak >= 0.5

s2_rows = NamedTuple[]
for df in groupby(sort(rule, :target_f), :target_f)
    n = nrow(df)
    onsets = df.treated_onset[_crossed.(df.treated_sell_peak)]
    push!(s2_rows, (target_f = first(df.target_f),
                    seeds = n,
                    control_p = count(_crossed, df.control_sell_peak) / n,
                    treated_p = count(_crossed, df.treated_sell_peak) / n,
                    median_onset = isempty(onsets) ? NaN : median(onsets)))
end
s2 = DataFrame(s2_rows)

# The interpolated midpoints and widths come straight from the scaling file.
# The widths appear in no figure panel, so this table is their only home.
s3 = sort(select(scaling, :boundary_mode, :market_maker_capacity, :gridn,
                 :f50, :transition_width, :susceptibility_peak_f,
                 :susceptibility_peak, :interior_points, :f50_lo, :f50_hi,
                 :transition_width_lo, :transition_width_hi,
                 :susceptibility_peak_lo, :susceptibility_peak_hi),
          [:boundary_mode, :market_maker_capacity, :gridn])

s4_rows = NamedTuple[]
for df in groupby(sort(balance, :target_f), :target_f)
    held = df.transition_probability[df.boundary_mode .== "hold"]
    endo = df.transition_probability[df.boundary_mode .== "endogenous"]
    # Every held-boundary cell within a fraction must agree, because the
    # held-boundary lattice is invariant to the balance-sheet intervention.
    length(unique(held)) == 1 ||
        error("held-boundary probability varied within f=$(first(df.target_f))")
    push!(s4_rows, (target_f = first(df.target_f),
                    held_p = first(held), held_cells = length(held),
                    endo_min = minimum(endo), endo_max = maximum(endo),
                    endo_cells = length(endo)))
end
s4 = DataFrame(s4_rows)

CSV.write(joinpath(_PATH_TO_DATA, "ModelB-TableS2-PairedSwitch.csv"), s2)
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-TableS3-FiniteSize.csv"), s3)
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-TableS4-BalanceSheetFractions.csv"), s4)

_p2(x) = @sprintf("%.2f", x)
_f2(x) = @sprintf("%.2f", x)
_f3(x) = @sprintf("%.3f", x)
_f4(x) = @sprintf("%.4f", x)
_chi(x) = @sprintf("%.1f", x)
_cap(h) = isinf(h) ? "\\infty" : @sprintf("%.0f", h)
_cond(mode) = mode == "hold" ? "Held" : "Endogenous"

# LaTeX thousands separator, matching the manuscript convention.
function _onset(x)
    isnan(x) && return "---"
    r = round(x; digits = 1)
    whole = floor(Int, r)
    tail = @sprintf("%.1f", r - whole)[2:end]
    whole < 1000 && return string(whole, tail)
    return string(div(whole, 1000), "{,}", lpad(mod(whole, 1000), 3, '0'), tail)
end

println("\n% Table S2 rows")
for r in eachrow(s2)
    println("$(_f2(r.target_f)) & $(r.seeds) & $(_p2(r.control_p)) & " *
            "$(_p2(r.treated_p)) & $(_onset(r.median_onset)) \\\\")
end

println("\n% Table S3 rows")
for r in eachrow(s3)
    println("$(_cond(r.boundary_mode)) & \$$(_cap(r.market_maker_capacity))\$ & " *
            "$(r.gridn) & $(r.interior_points) & $(_f3(r.f50)) [$(_f3(r.f50_lo)), $(_f3(r.f50_hi))] & " *
            "$(_f3(r.transition_width)) [$(_f3(r.transition_width_lo)), $(_f3(r.transition_width_hi))] & " *
            "$(_chi(r.susceptibility_peak)) [$(_chi(r.susceptibility_peak_lo)), $(_chi(r.susceptibility_peak_hi))] \\\\")
end

println("\n% Table S4 rows")
for r in eachrow(s4)
    println("$(_f3(r.target_f)) & $(_p2(r.held_p)) & " *
            "$(_p2(r.endo_min))--$(_p2(r.endo_max)) \\\\")
end
