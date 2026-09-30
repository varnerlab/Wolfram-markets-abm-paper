"""Build Figure 1's TikZ rule comparison without rerunning simulations.

Use --source ORIGINAL_FIGURE.pdf to refresh the preserved vector market panel
from a full corrected Julia figure. Ordinary rebuilds use the saved panel.
"""
from pathlib import Path
import argparse
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
PANEL = ROOT / "code/figs/Fig1-PairedMarkets.pdf"
SOURCE = ROOT / "paper-arxiv/figures/Fig1-RuleComparison.tex"


def compile_tex(path, directory):
    result = subprocess.run(
        ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", path.name],
        cwd=directory, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    if result.returncode:
        raise RuntimeError(result.stdout)
    return path.with_suffix(".pdf")


def render(source=None):
    # Independent exact decoding guards the diagram's intended scientific claim.
    rules = [[(r // 3**c) % 3 for c in range(9)] for r in (19280, 19286)]
    assert rules == [[2, 0, 0, 0, 1, 1, 2, 2, 2], [2, 2, 0, 0, 1, 1, 2, 2, 2]]
    assert [c for c in range(9) if rules[0][c] != rules[1][c]] == [1]
    with tempfile.TemporaryDirectory(prefix="rule-figure-") as temporary:
        work = Path(temporary)
        if source:
            shutil.copy2(source.resolve(), work / "original.pdf")
            crop = work / "paired-markets.tex"
            crop.write_text(r"""\documentclass[border=0pt]{standalone}
\usepackage{graphicx}
\begin{document}
\includegraphics[trim=115bp 20bp 55bp 575bp,clip]{original.pdf}
\end{document}
""")
            cropped = compile_tex(crop, work)
            shutil.copy2(cropped, PANEL)
        if not PANEL.exists():
            raise FileNotFoundError("saved market panel missing; supply --source with the original corrected figure")
        shutil.copy2(PANEL, work / "paired-markets.pdf")
        tex = work / SOURCE.name
        shutil.copy2(SOURCE, tex)
        result = compile_tex(tex, work)
        for folder in ("code/figs", "paper-arxiv/figs"):
            shutil.copy2(result, ROOT / folder / "Fig1-RuleQuench.pdf")
    print("Rebuilt Figure 1: TikZ rule comparison and unchanged paired market snapshots.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="full original corrected Julia figure")
    parser.add_argument("--watch", action="store_true", help="watch TikZ inputs alongside the manuscript")
    parser.add_argument("--job", default="Paper_v1", help="manuscript job for --watch")
    args = parser.parse_args()
    render(args.source)
    if not args.watch:
        return
    watched = (SOURCE, PANEL, Path(__file__))
    def signature():
        return tuple(path.stat().st_mtime_ns for path in watched)
    previous = signature()
    process = subprocess.Popen(
        ["latexmk", "-pdf", "-pvc", "-interaction=nonstopmode", "-halt-on-error", args.job + ".tex"],
        cwd=ROOT / "paper-arxiv",
    )
    try:
        while process.poll() is None:
            current = signature()
            if current != previous:
                # Launch the saved renderer so edits to this script also take effect.
                subprocess.run([sys.executable, str(Path(__file__).resolve())], check=False)
                previous = current
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        if process.poll() is None:
            process.terminate()
        process.wait()


if __name__ == "__main__":
    main()
