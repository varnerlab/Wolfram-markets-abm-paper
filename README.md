# Wolfram cellular-automaton market

The 7 October update adds a hypothetical inventory-information comparison:
neighbors read Hold instead of Sell from a sender with no shares. Its
[4,400-run study](output/rebuilt/inventory-visibility-v1/Protocol.md)
keeps the original simulator unchanged and compares four matched branches.
At the primary setting (20% switched, dealer depth 100, technical traders
held), the change reduced the switch's effect on the late raw Sell fraction
by 52.28 percentage points, with a 95% interval of 49.86--54.46 points.
Majorities reappeared at higher switched fractions. The main model is now
explicitly interpreted as influence through public intentions whose holdings
and execution observers do not verify. Reproduction instructions are in
[code/visibility](code/visibility/README.md), and the updated manuscript
contains Table S17, Fig. S2, and Appendix A.8. The synchronized submission-form
abstract is [paper-arxiv/abstract.txt](paper-arxiv/abstract.txt).

An [M.Eng. project proposal](meng-project/README.md) explores whether selling
cascades depend on traders with no shares continuing to signal Sell. It includes
a LaTeX project description and a one-slide pitch in PDF and PowerPoint formats.

The manuscript uses a finite constant-product dealer with uniform batch
execution. Every retained experiment, including held-decision financial
histories, was recomputed from empty output directories after the
standing-quote model was found to permit profitable isolated round trips.

- [Corrected manuscript](paper-arxiv/Paper_v1.pdf)
- [Findings and verification](output/rebuilt/manuscript-reserve-v1/ASSESSMENT.md)
- [Executed protocol](output/rebuilt/manuscript-reserve-v1/Protocol.md)
- [Complete reproduction workflow](code/rebuild/README.md)
- [Updated peer-review response](peer-review-response.md)

The original reserve-clearing study retains six figures and eleven tables. Its fixed manifest contains
45,910 full financial simulations, with refinement, trajectory extensions,
figure histories, and validation recorded separately in
[Verification.json](output/rebuilt/manuscript-reserve-v1/Verification.json).
The exact executed code and its outputs are in
`output/rebuilt/manuscript-reserve-v1/`. Historical results remain available
for audit and supply no inputs to this rebuilt manuscript.

To start another complete run with no cached inputs, create a new directory
from the executed source snapshot:

```sh
python3 code/rebuild/ColdClone.py /path/to/new-study
python3 /path/to/new-study/code/rebuild/Run.py
```

The destination must not exist. Follow the remaining analysis, figure,
verification, and manuscript commands in [code/rebuild/README.md](code/rebuild/README.md).
The recorded environment uses Julia 1.12.7 and Python 3.14.2; exact library
versions are in the study's `Runtime-Environment.json` and Julia manifests.

To rebuild the current PDF or verify its arXiv source archive:

```sh
make -C paper-arxiv
python3 paper-arxiv/package_arxiv.py --verify
```

`bash code/run_all.sh repaired-tests` checks the reserve mechanism and its
advice extension. The historical `all`, `figures`, and `revision` modes are
blocked after corrected-manuscript installation because they would overwrite
its outputs with the old study. Historical drivers remain under
`code/model-b/` and `code/revision/`; use the executed snapshot for the current
manuscript.

Separate repair and advice experiments are documented in
[code/repaired/README.md](code/repaired/README.md). The
[initial repair assessment](output/repaired/ASSESSMENT.md),
[transmission pilot](output/repaired/transmission-v1-pilot/ASSESSMENT.md), and
[fresh-market confirmation](output/repaired/transmission-confirmation-v1-full/ASSESSMENT.md)
retain their own protocols and results. The confirmation completed 5,200
runs across fifty new starting markets and passed both predeclared primary
criteria. Those advice results are not pooled into the six rule-switch figures.
