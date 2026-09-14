# Complete manuscript rerun under reserve execution

The author requested a complete rerun after the standing-quote execution
flaw was found. Every experiment retained in the six-figure manuscript,
including technical-trader-held conditions, will be computed again. No
previous simulation output or checkpoint supplies a manuscript value.
Existing outputs remain archived for comparisons and diagnosis.

## Model and scope

Use the tested reserve-v2 simulator and full cash/share bookkeeping in every
condition, including held controls, refinement, and long-horizon runs. Keep
the original grid initialization, rule assignments, initial cash and shares,
warm-up, observation windows, and starting-market seeds. This is a clean
reproduction under a replacement mechanism, not a fresh independent sample.
The separate advice confirmation remains a separate experiment and is not
pooled with this manuscript's rule-switch campaigns.

The replacement model has finite reserves and no independent exponential
price-impact parameter. Replace the old unlimited-dealer comparison with
100 initial reserve shares per trader, described as deep reserves, never as
unlimited execution. Keep the finite values 0, 0.1, 0.5, 1, 2, 5, and 10 where
they were included. Zero reserves retain matched trader orders at the fixed
quote. Replace the obsolete independent-lambda experiment with an explicit
depth comparison at h=40, 100, and 400. Their initial normalized log-price
slopes are 2/h = 0.05, 0.02, and 0.005; initial funding and price depth vary
together. Do not interpret this as holding reserves fixed while varying
price impact. Record these changes in Methods, captions, and the supplement.

## Retained experiments, all recomputed

- Paired rule change: four fractions, 50 starting markets, deep reserves,
  active technical traders, 64 by 64 grid, 1,000 baseline and 3,000 later steps.
- Dealer reserves: the original eleven fractions, eight reserve levels,
  both technical-trader conditions, and all 50 starting markets.
- Grid size: 32, 48, 64, 96, and 128; twelve initial fractions; active traders
  at h=1 and 100 and held traders at h=100; 50 starting markets. Recompute
  the original adaptive fraction-refinement algorithm from this new grid.
- Cash and shares: fractions 0.17, 0.175, 0.18, and 0.185; h=0.1, 1, and 100;
  both technical-trader conditions; nine resource-multiplier combinations;
  50 starting markets. Verify conservation on each side of the intentional
  resource intervention and check held decision equality again.
- All eighteen single-entry rule neighbors: three fractions, both technical-
  trader conditions, 20 starting markets, paired no-switch controls.
- Persistent rule versus one-time Sell pulse: the original three fractions,
  both technical-trader conditions, 50 starting markets, paired controls.
- Adaptive versus frozen band width: f=0.175, eight reserve levels, 50 starts,
  active technical traders, paired controls.
- Depth sensitivity: f=0.20, h=40/100/400, active traders, 50 starts, paired
  no-switch controls, replacing the removed lambda parameter's experiment.
- No-switch histories through 100,000 additional steps: the original ten
  starting markets and both technical-trader conditions at h=100.
- Held horizon and majority-threshold checks: the original L=32/64/128 grids,
  fraction grids, 50 starts, and all observation windows through 12,000
  steps. Use the full reserve simulator, not the finance-free held kernel.
- Figure trajectories: select representative markets from the newly computed
  summaries using the existing numerical selection rules and seed tie-breaks.
  Extend the five fraction examples and all 50 f=0.15 markets to 10,000 steps.
  Never select an example by visual appeal or preserve its previous seed merely
  because it was shown before. Regenerate rule diagrams from their rule tables.

No historical result is a required outcome. In particular, h=10 need not
equal deep reserves, small reserves need not protect prices, and no-switch
markets need not be assumed to avoid a majority. Report all measured results.
Accounting, common prehistories, finite prices, actual-price affordability,
and deterministic decision identities are implementation checks.

## Analysis, isolation, and verification

Retain the existing 2,000 whole-starting-market bootstrap analysis, Wilson
intervals for displayed proportions, empirical interpolation, and monotone
logistic working fits. Refinement follows the existing preset rule of adding
midpoints adjacent to the observed 5--95% transition until five interior
fractions are sampled, with a maximum of ten rounds. Unbracketed crossings
remain undefined; failure to bracket or to obtain five interior points is
reported rather than changing the protocol after inspecting the result.

Create an isolated tree under `output/rebuilt/manuscript-reserve-v1/`, copying
source and environment files only. The initial data, checkpoint, and figure
directories must be empty. A frozen source inventory and explicit manifest
record all campaign settings before production. Atomic checkpoints may resume
work created within this new run after an interruption; old checkpoints are
never imported. Every runner checks its source inventory before executing.
Preserve the prior manuscript and source before installing the rebuilt version.

Recompute all main figures and supplementary tables from the isolated outputs.
Rewrite Methods, Results, Discussion, the abstract, captions, and conclusion
against those outputs. Rebuild the PDF, check all references and layout, and
verify that every figure and reported computed value has a fresh source.
Retain the clean run, logs, manifests, hashes, analysis, and validation as the
reproducibility record. The existing archives are read only for explicit
old-versus-new comparisons and are excluded from manuscript data inputs.
