# Review follow-up experiments

These are retrospective sensitivity analyses prompted by `peer-review.md`.
They do not retroactively preregister the original campaigns.

From the repository root:

```bash
julia --project=code --startup-file=no code/revision/Test-Revision.jl
julia --project=code --startup-file=no -t 12 --gcthreads=1 code/revision/Compute-Controls.jl
julia --project=code --startup-file=no -t 12 --gcthreads=1 code/revision/Compute-Refinement.jl
julia --project=code --startup-file=no -t 12 --gcthreads=1 code/revision/Compute-Horizons.jl
python3 code/revision/Analyze-Revision.py
python3 code/revision/Write-Revision-Tables.py
julia --project=code code/model-b/Tables-ModelB-Supplement.jl
julia --project=code code/model-b/Figs-ModelB-ReservoirQuench.jl
julia --project=code code/model-b/Figs-ModelB-FiniteSizeQuench.jl
make -C paper-arxiv
```

`bash code/run_all.sh revision` runs the new experiments and analysis. `figures`
rebuilds from the deposited seed-level files, including the bootstrap analysis;
it does not repeat the revision simulation campaigns. Python dependencies are
listed in `requirements.txt`; Julia uses `code/Manifest.toml`.

## Designs

- `Compute-Controls.jl screen`: all 18 single-entry neighbors, fractions
  0.15/0.20/0.25, both boundaries, 20 seeds (2,160 paired jobs).
- `pulse`: persistent Rule 19286 versus one-time Sell pulse at identical target
  sites, the same fractions and boundaries, 50 seeds (600 paired jobs).
- `band`: f=0.175, eight capacities, adaptive versus frozen pre-switch deviation,
  50 seeds (800 paired jobs). The center keeps updating. Widths are constant
  within a frozen path but can differ across seeds and capacities.
- `impact`: f=0.20, three impact coefficients and three capacities, 50 seeds
  (450 paired jobs).
- `long`: no switch for 100,000 additional steps, both boundaries, first ten
  production seeds (20 jobs). These are extensions, not independent replicates.
- Refinement: original 50 seeds and all 15 size/boundary/capacity conditions.
  Bisect every interval touching the empirical 5--95% transition response until
  at least five sampled fractions have probabilities strictly inside that range.
  Original rows are retained. No probabilities are smoothed before interpolation.
- Horizons: held boundary, 50 seeds, L=32/64/128, 0.005-spaced fraction grid.
  L=32 extends through 0.30 to bracket short-window crossings; others end at 0.25.
  Endpoint windows use 3000*(L/64)^z for z=1 and 2, alongside 3,000 steps.
  L=64 adds 9,000 steps. Every run records thresholds 0.4/0.5/0.6.

The held-lattice kernel omits finances only when a held boundary makes their
irrelevance exact. It shares the production initialization draws and tables,
and tests compare full histories and grids to `simulate`. Its archived
production overlap contains 1,800 exactly matching transition indicators and
final-window means agreeing within 1e-14.

Each paired job checks common prehistory. Financial paths check cash/share
conservation. Checkpoints are atomic CSVs; their job columns are validated on
resume. If code or the experiment changes, increment the checkpoint version;
job-column validation alone cannot detect a changed simulator implementation.
Seed-level aggregate CSVs are deposited; checkpoints are ignored.

## Statistical interpretation

The analysis uses 2,000 seed-block bootstrap replicates, keeping the same seed
sample across every fraction in a curve. Percentile intervals are conditional
on the adaptively selected grid, the chosen horizon, and the model. They do not
quantify adaptive-grid selection or interpolation bias. Susceptibility maxima
are reselected over sampled fractions in each bootstrap replicate.

The logistic fit is a monotone binomial working model, supplemented rather than
substituted for empirical interpolation. Its standard errors are bootstrap
standard deviations; dependence between fractions is preserved. The CSV records
how many bootstrap replicates bracket the requested crossings. Unbracketed
crossings are NaN rather than extrapolated. No exponent or asymptotic critical
point is fitted. The 20-seed rule screen is exploratory and has no multiple-
comparison correction.

`Write-Revision-Tables.py` produces the main finite-size results paragraph and
supplementary LaTeX directly from these files. Edit its templates rather than
hand-editing the generated snippets.


### Extended price and decision histories for Fig. 4

`Compute-MarketPanel-Horizons.jl` extends the five illustrated markets and all
50 original f=0.150 starting markets to 10,000 steps after the rule change,
with an unlimited dealer and edge traders responding to price. Each of the
54 distinct starting conditions has a matched no-switch run. The script checks
3,000-step summaries against the original reservoir data, reproduces the full
original price and Sell histories for the five examples, and checks financial
conservation. This is an extension of existing runs, not a new independent
sample. Versioned checkpoints permit resumption; change the cache version if
the protocol changes.

```sh
julia --project=code --threads=4 code/revision/Compute-MarketPanel-Horizons.jl
/opt/homebrew/bin/python3 code/revision/Plot-MarketPanel-Horizons.py
```

The resulting `ModelB-Revision-MarketPanel-Horizons*.csv` files contain full-step
summary measurements at 3,000, 5,000, and 10,000 steps and trajectories sampled
every ten steps. Onset times are measured from every simulation step, not from
the thinned trajectories. The diagnostic PDF and PNG are written under
`output/pdf/`, with a numerical report in `output/analysis/`. These diagnostics
do not overwrite the manuscript figures.

The manuscript Fig. 4 retains those same five examples and now extends to
10,000 steps. Regenerate it after the summary CSV with:

```sh
julia --project=code code/model-b/Figs-ModelB-MarketPanels.jl --fig4-only
/opt/homebrew/bin/python3 code/revision/Write-Revision-Tables.py
```

The second command also writes Supplementary Table S11 from the extended
horizon summaries. Figure 5 retains its original observation period.
