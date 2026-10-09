# Visibility of inventory and selling signals

This supplemental study treats the original model's neighbor states as public
trading intentions whose execution is unverified. The counterfactual assumes
that observers know whether a sender holds any shares and read Hold instead
of Sell when it holds none. It does not assert that this information is
available in a real market or that this response to disclosure is unique.
The rule is not monotone, so attenuation is not a required result.

## Executed design

The source in `output/rebuilt/manuscript-reserve-v1/code/src` is copied without
changes. An observer supplies a separate visible-signal array to the existing
local update. At each step: orders execute from stored intentions; holdings
settle; technical traders update from price; visible signals are constructed;
interior traders update together. Zero-share Sell is replaced by Hold in
neighbor inputs only, including signals sent by technical traders. Buy is
unchanged. Hold is code 1, not removal of a neighbor. Stored edge intentions
are restored after the local update. Fees are zero and loss-making sales are
allowed. Masking begins with the first decision update after the intervention.

Each starting market has the original 1,000-step history. Four branches share
all pre-intervention states: original or inventory-conditioned observations,
each with or without the switch from Rule 19280 to Rule 19286. No-switch
controls use the largest initial fraction with its assigned minority rule
dormant, and are shared across fractions. Full financial histories are
recomputed for all runs. No finance-free held shortcut is permitted.

The main manifest has 50 fresh seeds, 730001--730050, L=64, 3,000 steps after
the intervention, initial cash 1,000 and ten shares, dealer depths 1 and 100,
and technical traders held and active. Both observation modes use switched
fractions 0.10, 0.15, 0.175, 0.18, 0.20, 0.25 and one no-switch control:
2,800 full trajectories. The pilot uses seeds 720001--720002 with the same
full duration but only fractions 0.175 and 0.20; pilot data are excluded from
the main analysis. The smoke test uses two seeds and 100 total steps.

Before seeing main outcomes, the extension rule is fixed as follows, applied
separately to each boundary/depth condition. If inventory-conditioned majority
probability at fraction 0.25 is below 0.75, run both observation modes at
fractions 0.35, 0.50, 0.75, and 1.0. If its probability at fraction 0.10 is
above 0.25, run both modes at fractions 0.025 and 0.05. Use all 50 seeds and
the original controls. This is one extension round; no additional fractions
or horizons are chosen from its outcomes. Report a missing or nonmonotone
crossover directly. No asymptotic threshold or precise interpolated midpoint
is claimed from this coarse sweep. Main and extension manifests and their
hashes are retained separately.

## Outcomes and inference

The primary setting is fraction 0.20, dealer depth 100, technical traders
held. The primary outcome is raw Sell fraction averaged over the last 500
steps. For each seed, subtract the no-switch outcome from the switched
outcome within each observation mode, then subtract the original effect from
the inventory-conditioned effect. Report the mean of this difference of
differences and a two-sided percentile 95% interval from 10,000 bootstrap
samples of whole seeds (fixed bootstrap seed 730099), preserving every branch
and shared control. The primary inference is fixed irrespective of pilot or
extension outcomes; all other intervals are descriptive pointwise intervals.
No null-significance result establishes equivalence.

Secondary outcomes use the same paired analysis: whether the raw interior
Sell fraction reaches 0.5 after an update; maximum quoted-price drawdown
including the quote immediately before intervention; completed interior
sales per interior trader. Report all four branch means alongside contrasts.
Wilson intervals accompany majority probabilities.

Diagnostics distinguish raw input signals immediately before each update,
visible input signals, and raw intentions immediately after it. The unbacked
signal fraction is the sum of zero-share interior Sell input counts divided
by all interior Sell input counts over the specified period. Report the
baseline, post-intervention, and through-first-onset periods (the full period
if no majority forms). Also record interior sale suppression, dealer
rejection, and edge sales. Suppression is a fraction of desired interior
sales; dealer rejection is a fraction of all eligible orders. Histories are
retained for the first seed's controls and fraction-0.20 branches in every
depth/boundary condition, selected without looking at outcomes. A decrease
in visible Sell alone is mechanical and cannot establish reduced contagion.

## Validation and reproduction

Test original-mode recovery, all-sellers-funded recovery, last-share sale and
reacquisition, technical-sender masking, preservation of stored intentions,
and observation timing. Check an archived full-run final grid, exact
pre-intervention holdings/grid/bands/dealer hashes and prehistories across
all branches, conservation every step, nonnegative holdings every step, the
constant product, and positive reserve-ratio prices. Run existing reserve
clearing and round-trip tests before the production study. Hash computation,
analysis, manifests, environment, and reference records before execution.
The source archive is not altered. Production summaries are generated only
after manifest completeness and pairing checks pass.

```
julia --project=code --startup-file=no code/visibility/Test.jl
python3 code/visibility/Prepare.py output/rebuilt/inventory-visibility-v1 --mode main
/opt/homebrew/bin/python3 code/visibility/Run.py output/rebuilt/inventory-visibility-v1 --threads 12
```

Preparation requires a new directory. `--mode smoke` and `--mode pilot` create
separate checks excluded from the main study. Run resumes per-trajectory
atomic checkpoints after verifying the frozen files. Analysis and manuscript
generation use the retained summaries; no cached historical trajectory is a
new observation.
