"""Build an isolated reserve-model study from source, with no historical data."""
import argparse
import hashlib
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "docs/superpowers/specs/2026-09-14-clean-manuscript-rerun.md"
VERSION = "manuscript-reserve-v1"
DRIVERS = ["Compute-ModelB-RuleQuench.jl", "Compute-ModelB-ReservoirQuench.jl",
           "Compute-ModelB-FiniteSizeQuench.jl", "Compute-ModelB-BalanceSheetQuench.jl"]
FIGURES = ["Figs-ModelB-ReservoirQuench.jl", "Figs-ModelB-FiniteSizeQuench.jl",
           "Figs-ModelB-BalanceSheetQuench.jl", "Figs-ModelB-MarketPanels.jl",
           "Tables-ModelB-Supplement.jl"]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"Expected one source match, found {text.count(old)}: {old[:100]}")
    return text.replace(old, new)


def finite_comparison(text):
    # In these selected experiment scripts every Inf is the old dealer arm.
    text = re.sub(r"\bInf\b", "100.0", text)
    text = text.replace("isinf", "isdeepreserve")
    text = text.replace("∞", "100").replace("\\\\infty", "100")
    return text


def adapt_model_file(name, text):
    text = finite_comparison(text).replace("simulate(", "simulate_repaired(")
    if name == "Compute-ModelB-RuleQuench.jl":
        text = replace_once(text, "P0 = P0,\n", "P0 = P0,\n        market_maker_capacity = 100.0,\n")
    if name in DRIVERS:
        text = text.replace("series[(T_PRE + 1):end])", "series[(T_PRE + 2):end])")
        text = text.replace("x[(T_PRE + 1):end])", "x[(T_PRE + 2):end])")
        text = text.replace("return isnothing(i) ? 0 : i - 1", "return isnothing(i) ? 0 : i")
        for field in ("executed_buys", "executed_sells", "suppressed_buys", "suppressed_sells",
                      "market_maker_rejected_buys", "market_maker_rejected_sells"):
            text = text.replace(f"sum(result.{field})", f"sum(@view result.{field}[(T_PRE + 1):end])")
        # The wrapper enforces conservation with a scale-aware tolerance per run.
        text = text.replace('conservation_error) < 1.0e-5', 'conservation_error) < 1.0e-3')
        text = text.replace('system_cash_error) < 1.0e-5', 'system_cash_error) < 1.0e-3')
    if name == "Compute-ModelB-FiniteSizeQuench.jl":
        start = text.index("# A canonical summary produced")
        stop = text.index("pending_indices =", start)
        text = text[:start] + "# Only checkpoints created within this frozen clean run may resume.\n" + text[stop:]
    if name == "Figs-ModelB-ReservoirQuench.jl":
        start = text.index("unlimited = summary[")
        stop = text.index("h0_endogenous =", start)
        text = text[:start] + "# Deep reserves and h=10 are distinct reserve-model conditions.\n" + text[stop:]
        text = text.replace("# The finite h=10 path coincides with the unlimited path in this campaign.\n# A dashed overlay makes the checked equality visible.",
                            "# Display h=10 as an additional reserve-depth comparison.")
    if name == "Figs-ModelB-MarketPanels.jl":
        text = text.replace('@assert Int64.(getproperty.(dose_rows,:seed)) == [8,5,22,46,21]',
                            'CSV.write(joinpath(_PATH_TO_DATA,"Figure4-Selection.csv"),DataFrame(dose_rows))')
        text = text.replace('"infinite dealer"', '"dealer h = 100"')
        text = text.replace('@view result.sell_fraction[(T_PRE+1):(T_PRE+post+1)]',
                            '@view result.sell_fraction[(T_PRE+2):(T_PRE+post+1)]')
        text = text.replace('isnothing(crossing) ? 0 : crossing - 1', 'isnothing(crossing) ? 0 : crossing')
        text = text.replace('center = median(metric)\n    return rows[argmin(abs.(metric .- center)), :]',
                            'center = median(metric)\n    order = sortperm(1:nrow(rows);by=i->(abs(metric[i]-center),rows.seed[i]))\n    return rows[first(order), :]')
        text = text.replace('capacity_seed =', 'capacity_seed =', 1)
    return text


def adapt_revision(name, text):
    if name == "Revision-Lib.jl":
        text = text.replace("h=Inf", "h=100.0")
        text = text.replace('maximum(abs.(cash .- cash[1])) < 1e-5',
                            'maximum(abs.(cash .- cash[1])) < max(1e-5,abs(cash[1])*1e-11)')
        text = replace_once(text,'    dir = joinpath(REV_DATA, "$(stem)-$(version)-Checkpoints")',
            '''    manifest=joinpath(REV_DATA,stem*"-Manifest.csv")
    buffer=IOBuffer();CSV.write(buffer,DataFrame(jobs));manifest_bytes=take!(buffer)
    isfile(manifest) ? (@assert read(manifest)==manifest_bytes) : write(manifest,manifest_bytes)
    dir = joinpath(REV_DATA, "$(stem)-$(version)-Checkpoints")''')
        text += '\ninclude(joinpath(@__DIR__,"..","src","RebuildRuntime.jl"))\n'
        return text
    if name.startswith("Compute-"):
        text = finite_comparison(text).replace("simulate(", "simulate_repaired(")
        text = text.replace("held_lattice(c", "held_rebuild(c")
    if name == "Compute-Controls.jl":
        start = text.index("        finance=(maximum_drawdown=NaN")
        stop = text.index("\n    else", start)
        text = text[:start] + "        finance=financial_metrics(r.financial_result)" + text[stop:]
        text = replace_once(text,
            'impacts=[job(campaign="price_impact",h=h,impact=impact,seed=s)\n         for h in (0.1,1.,100.0) for impact in (0.005,0.02,0.05) for s in 1:50]',
            'impacts=[job(campaign="reserve_depth",h=h,impact=2/h,seed=s)\n         for h in (40.,100.,400.) for s in 1:50]')
    if name == "Compute-Refinement.jl":
        text = text.replace('        @assert !revision_metrics(control).transitioned\n', '')
        text = text.replace(' :final_sell_mean)', ' :final_sell_mean)')
        # The ten-round limit is a design limit, not an assertion about outcomes.
        text = text.replace('    @assert count(x->0.05<x<0.95,p)>=5',
                            '    @info "Refinement interior fractions" count=count(x->0.05<x<0.95,p)')
    if name == "Compute-MarketPanel-Horizons.jl":
        start = text.index("const PANEL_CASES =")
        stop = text.index("const PANEL_STEM =", start)
        text = text[:start] + '''function select_panel_cases()
    data=CSV.read(joinpath(REV_DATA,"ModelB-ReservoirQuench-Full-Summary.csv"),DataFrame)
    cases=NamedTuple[]
    for (f,event) in ((.15,false),(.175,false),(.175,true),(.185,true),(.20,true))
        rows=data[(data.boundary_mode.=="endogenous").&(data.market_maker_capacity.==100.).&
                  (data.target_f.==f).&(data.transitioned.==event),:]
        isempty(rows) && error("the specified exemplar subgroup is empty; report it before revising the figure")
        metric=event ? rows.treated_onset : rows.treated_final_sell_mean
        center=median(metric)
        i=first(sortperm(1:nrow(rows);by=i->(abs(metric[i]-center),rows.seed[i])))
        push!(cases,(f=f,seed=Int(rows.seed[i])))
    end
    CSV.write(joinpath(REV_DATA,"Figure4-Prespecified-Selection.csv"),DataFrame(cases))
    cases
end
const PANEL_CASES = select_panel_cases()
''' + text[stop:]
        text = text.replace('if s != 8', 'if !((f=0.150,seed=s) in PANEL_CASES)')
    return text


def prepare(smoke=False):
    destination = ROOT / "output/rebuilt" / (VERSION + ("-smoke" if smoke else ""))
    if destination.exists():
        raise FileExistsError(f"Clean preparation requires a new, absent output directory: {destination}")
    destination.mkdir(parents=True)
    copied = {}
    for path in sorted((ROOT / "code").rglob("*")):
        if not path.is_file() or path.suffix not in (".jl", ".py", ".sh", ".toml", ".txt"):
            continue
        relative = path.relative_to(ROOT)
        if any(p in relative.parts for p in ("data", "figs", "__pycache__")):
            continue
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        copied[str(relative)] = sha(path)
    for relative in ("code/data", "code/figs", "paper-arxiv/figs", "logs"):
        (destination / relative).mkdir(parents=True, exist_ok=True)
    for path in (ROOT / "paper-arxiv").rglob("*"):
        if path.is_file() and (path.suffix in (".tex", ".bib", ".sty", ".cls") or path.name == "Makefile"):
            relative = path.relative_to(ROOT)
            target = destination / relative; target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
    for name in DRIVERS + FIGURES:
        path = destination / "code/model-b" / name
        path.write_text(adapt_model_file(name, path.read_text()))
    include = destination / "code/model-b/Include.jl"
    text = include.read_text()
    text = replace_once(text, 'import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()',
                        '# Use the frozen project supplied by the clean-run command.')
    text += '\ninclude(joinpath(_PATH_TO_SRC,"RebuildRuntime.jl"))\n'
    include.write_text(text)
    runtime = (ROOT / "code/rebuild/RebuildRuntime.jl").read_text()
    (destination / "code/src/RebuildRuntime.jl").write_text('isdeepreserve(x) = x == 100.0\n' + runtime)
    for name in ("Revision-Lib.jl", "Compute-Controls.jl", "Compute-Refinement.jl",
                 "Compute-Horizons.jl", "Compute-MarketPanel-Horizons.jl"):
        path = destination / "code/revision" / name
        path.write_text(adapt_revision(name, path.read_text()))
    # These files contain model-independent numerical analysis; keep them exact.
    assert sha(destination / "code/revision/Analyze-Revision.py") == sha(ROOT / "code/revision/Analyze-Revision.py")
    original_engine = {str(p.relative_to(ROOT)): sha(p) for p in (ROOT / "code/src").glob("*.jl")}
    assert all(sha(destination / p) == digest for p, digest in original_engine.items())
    assert not list((destination / "code/data").iterdir())
    assert not list((destination / "code/figs").iterdir())
    assert not list((destination / "paper-arxiv/figs").iterdir())
    frozen = {str(p.relative_to(destination)): sha(p) for p in (destination / "code").rglob("*")
              if p.is_file() and p.suffix in (".jl", ".py", ".sh", ".toml", ".txt")}
    protocol = {"version": VERSION, "smoke": smoke, "created_utc": datetime.now(timezone.utc).isoformat(),
        "specification_sha256": sha(SPEC), "initial_cached_files": 0,
        "historical_data_imported": False, "held_financial_simulations": True,
        "clearing": "reserve", "deep_reserves": 100, "source_inputs": copied,
        "original_engine": original_engine, "frozen_computation": frozen}
    (destination / "Protocol.json").write_text(json.dumps(protocol, indent=2) + "\n")
    shutil.copy2(SPEC, destination / "Protocol.md")
    print(destination)


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--smoke",action="store_true")
    args=parser.parse_args()
    prepare(args.smoke)
