# Lazy revision and interior technical traders

This study tests two model variants raised by the 2026-10-02 simulated review
(`peer-review.md`):

- **Lazy revision.** With `revision_probability = alpha`, each interior trader
  adopts its rule output with probability alpha at each step and otherwise
  keeps its intention. The original model (alpha = 1) updates every trader at
  once from a neighbor sum that excludes the trader's own state, which splits
  the grid into two checkerboard halves that never interact when technical
  traders are held. Any alpha < 1 couples them.
- **Interior technical traders.** With `interior_technical_fraction = rho`,
  band-rule technical traders also occupy a fraction rho of interior cells, so
  price information is not confined to the edge (where it reaches about 1.5%
  of interior traders at L = 64). Interior technical cells are chosen by a
  counter-based ranking that does not depend on the switched fraction, switch
  targets skip them, they are excluded from the Sell fraction, and when held
  they stay in Hold.

Both options default to the original model, and the defaults reproduce the
archived manuscript runs bit for bit (`code/test/test_revision_interior_technical.jl`).

## Design

Fifty starting markets (seeds 1-50, the manuscript's), 1,000 baseline and
3,000 post-switch steps, reserve clearing, Rule 19280 to 19286.

| Experiment | L | alpha | rho | Technical traders |
|---|---|---|---|---|
| lazy | 64 | 1, 0.95, 0.9, 0.75, 0.5 | 0 | held h = 100; active h = 1, 100 |
| interior | 64 | 1 | 63 cells (the edge count), 0.025, 0.05, 0.10 | held h = 100; active h = 1, 100 |
| size | 32, 128 | 0.9 / 1 | 0 / 0.05 | alpha 0.9 held; rho 0.05 held and active h = 100 |

Each condition tests 22 fractions: a fixed set of offsets (dense within 0.03
of the center, wide tails to +0.25) around the crossover found in 20-market
pilots (`code/revision/Pilot-Revision-InteriorTechnical.jl`). One no-switch
control per condition and starting market, with the minor rule dormant at the
largest fraction, is shared by that group's switched runs, and every switched
run is checked for an identical history up to the switch.

The analysis checks completeness, common histories, conservation, and that
alpha = 1, rho = 0 runs reproduce the archived final grids wherever the
manuscript campaigns ran the same condition. It reports majority probabilities
with Wilson intervals; f25, f50, and f75 by linear interpolation at the first
upward crossing; and planned f50 contrasts (active minus held; each alpha
against 1; each rho against 0; L = 32 and 128 against 64), with 2,000
bootstrap resamples of whole starting markets shared across conditions so
contrasts are paired. Conditions with fewer than five fractions strictly
between 0.05 and 0.95 are flagged rather than refined.

## Running

From the repository root:

```sh
julia --project=code --startup-file=no code/test/test_revision_interior_technical.jl
python3 code/variants/Prepare.py output/rebuilt/lazy-revision-interior-technical-v1
python3 code/variants/Run.py output/rebuilt/lazy-revision-interior-technical-v1 --threads 24
```

`Prepare.py --smoke` writes a tiny study (two seeds, three fractions, 100
steps, five conditions) for an end-to-end check of the pipeline. Prepare requires a new
destination, verifies the manuscript rebuild's frozen computation, copies the
source, tests, and environment, and records hashes. Run verifies them before
and after each phase, runs the tests, resumes complete group checkpoints, and
then runs `Analyze.py`. Changing computation or design requires a new version.

`WritePaper.py` is post-processing, written after the study was frozen: it
checks the study's hashes and validation, then generates
`paper-arxiv/sections/variants-table.tex` (Tables S15 and S16) and
`variants-validation.tex` (the appendix subsection), and `variants-figure.tex`
(Supplementary Fig. S1). Run `Figs-Variants-MarketPanels.jl` first: it selects
the five example markets for Fig. S1 from the campaign summaries by the rule
in its header, checks each rerun against its archived onset and final-grid
hash, writes `FigS1-Selection.csv` into the study, and saves
`FigS1-RevisionMarketPanels.pdf` to `paper-arxiv/figs/` and `code/figs/`:

```sh
julia --project=code code/variants/Figs-Variants-MarketPanels.jl
/opt/homebrew/bin/python3 code/variants/WritePaper.py \
    output/rebuilt/lazy-revision-interior-technical-v1 --paper paper-arxiv
```
