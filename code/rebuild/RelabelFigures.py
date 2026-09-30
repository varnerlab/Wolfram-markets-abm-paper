"""Relabel Figures 2, 3, and 6 with the manuscript's terms without rerunning simulations.

Starts from the verified presentation scripts in the rebuild destination
(presentation-v2/Figs-*.jl), applies the documented text changes below, and
renders into a temporary directory. Only the repository copies in
paper-arxiv/figs and code/figs are replaced; the rebuild's verified figures,
data, and scripts are read but never written.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
STUDY = ROOT / "output/rebuilt/manuscript-reserve-v1"

FRACTION = ('"Activated site fraction, f"', '"Fraction given new rule, f"')
PROBABILITY = ('"Transition probability"', '"Majority probability"')
H10 = '''# Display h=10 as an additional reserve-depth comparison.
h10_curve = sort(grouped[(grouped.boundary_mode .== "endogenous") .&
                         (grouped.market_maker_capacity .== 10.0), :], :target_f)
plot!(pA, h10_curve.target_f, h10_curve.transition_probability;
      color=:black, ls=:dash, lw=1.0, label="active, h=10")
'''

# (script name, output figure, [(old, new, expected count), ...])
CHANGES = [
    ("Reservoir", "Fig2-ReservoirQuench", [
        (*FRACTION, 2), (*PROBABILITY, 1),
        ('"Dealer capacity, h"', '"Dealer depth, h"', 1),
        ('"Dealer capacity per trader, h"', '"Dealer depth, h"', 1),
        # Legend "h=1" rather than "h=1.0", as in Figure 6 and the prose.
        ('isdeepreserve(h) ? "100" : string(h)',
         'isdeepreserve(h) ? "100" : replace(string(h), r"\\.0$" => "")', 1),
        # Panel B shows all eight depths; A keeps held and h = 0.1, 1, 100.
        (H10, "", 1),
    ]),
    ("FiniteSize", "Fig3-FiniteSizeQuench", [
        (*FRACTION, 2), (*PROBABILITY, 1),
        ('"Inverse lattice size, 1/L"', '"Inverse grid size, 1/L"', 1),
        ('"Lattice size, L"', '"Grid size, L"', 1),
    ]),
    ("BalanceSheet", "Fig6-BalanceSheetQuench", [(*PROBABILITY, 2)]),
]


def revise(name, changes, out):
    text = (STUDY / "presentation-v2" / f"Figs-{name}.jl").read_text()
    include = 'include(joinpath(@__DIR__, "..", "code", "model-b", "Include.jl"))'
    assert text.count(include) == 1
    text = text.replace(include, f'include(raw"{STUDY}/code/model-b/Include.jl")\n'
                                 f'const OUT = raw"{out}"')
    # Redirect every write into the temporary directory.
    for old, new in [("CSV.write(joinpath(_PATH_TO_DATA,", "CSV.write(joinpath(OUT,"),
                     ("joinpath(_PATH_TO_FIGS,", "joinpath(OUT,"),
                     ("joinpath(_PATH_TO_PAPER_FIGS,", 'joinpath(OUT, "copy",')]:
        text = text.replace(old, new)
    assert "_PATH_TO_FIGS" not in text and "_PATH_TO_PAPER_FIGS" not in text
    assert "CSV.write(joinpath(_PATH_TO_DATA" not in text
    for old, new, count in changes:
        assert text.count(old) == count, (name, old, text.count(old))
        text = text.replace(old, new)
    return text


def main():
    env = os.environ.copy()
    env.update(GKSwstype="100", XDG_CACHE_HOME="/tmp/wolfram-rebuild-cache")
    with tempfile.TemporaryDirectory(prefix="relabel-figures-") as temporary:
        out = Path(temporary)
        (out / "copy").mkdir()
        for name, figure, changes in CHANGES:
            script = out / f"Figs-{name}.jl"
            script.write_text(revise(name, changes, out))
            subprocess.run(["julia", f"--project={STUDY / 'code'}", "--startup-file=no",
                            "--threads=1", str(script)], cwd=out, env=env, check=True)
            for folder in ("paper-arxiv/figs", "code/figs"):
                shutil.copy2(out / f"{figure}.pdf", ROOT / folder / f"{figure}.pdf")
            print("Relabelled", figure)


if __name__ == "__main__":
    main()
