# Shared advice and copy trading

This extension implements the prospective design in
[`2026-09-13-crowding-and-copy-trading.md`](../../docs/superpowers/plans/2026-09-13-crowding-and-copy-trading.md).
It adds external recommendation streams and one-step copying of completed
trades to the existing financial simulator. Synthetic advice is a mechanism
experiment, not output from a deployed AI service.

Run from the repository root with the locked `code` environment:

```sh
julia --project=code --startup-file=no --threads=4 code/following/Test-Following.jl
julia --project=code --startup-file=no code/following/Test-Following-Analysis.jl
julia --project=code --startup-file=no code/following/Test-Following-Controls.jl
julia --project=code --startup-file=no --threads=12 --gcthreads=1 code/following/Compute-Following.jl pilot
julia --project=code --startup-file=no code/following/Analyze-Following.jl pilot
julia --project=code --startup-file=no code/following/Figs-Following.jl pilot
```

`smoke`, `pilot`, and `confirmation` select distinct manifests and starting
markets. Their core budgets are 88, 3,420, and 33,900 simulations. The main
runner also exposes `following-tests`, `following-smoke`, `following-pilot`,
`following-confirmation`, and `following-figures`. Existing `figures` and `all`
do not start the new campaigns. Launch only one writer for a campaign at a time.

The diagnostic driver defaults to a small verification campaign:

```sh
julia --project=code --startup-file=no --threads=4 code/following/Compute-Following-Controls.jl diagnostic-smoke
```

Use `diagnostic-pilot` or `diagnostic-confirmation` for the declared slice at
10%/40% following, one/sixteen sources, capacities one/unlimited, and held/active
technical traders. `--sensitivities` additionally enumerates grid sizes 32/128,
the 10,000-step horizon, and impact coefficients 0.005/0.05. Each diagnostic
manifest includes the paired control and the common capacity-one source tapes
required by replay. Live-condition endpoints also receive a simultaneous-exit
stress calculation, with cash proceeds and unsold shares reported separately.

The simulator records desired orders, resource-eligible orders, and fills
separately. Followers copy a fill from a past step, never a contemporaneous
future action or the last nonzero action indefinitely. Their copied orders
must still pass their own resource and counterparty constraints. The warm-up,
cash, shares, technical-trader bands, and price are not reset at adoption.

Following decision histories are measured before clearing, after the decision
override. Legacy `sell_fraction` histories describe the ordinary local update
and must not be substituted for the new observed-decision histories. Wealth
uses the price after settlement/repricing, normalized by wealth immediately
before adoption. The observer maintains individual wealth peaks, drawdowns,
order counts, and time in Buy/Sell; cohort summaries retain mean, lower-decile,
median, and upper-decile returns. Full individual histories are not deposited
for ordinary runs. Cohort quantiles summarize distributions; they are not a
complete transaction-level dataset.

`Following-<Campaign>-Manifest.csv` lists every job before launch.
`Following-<Campaign>-Protocol.toml` records the implementation, environment,
manifest digests, and the source revision. Version-checked block checkpoints
support resume. Summary rows include a shared control identifier and starting
state fingerprint. Paired metrics use the same prospective follower/leader
cohorts in the shared control, even though the control is simulated only once.
Changed code or design requires a newly versioned campaign, not silent reuse
of old checkpoints.

Grouped estimates resample whole starting markets 2,000 times, retaining all
design replicates within each market. Intervals are pointwise. All-zero/all-one
event samples receive separate conservative bounds based on independent market
clusters. Missing denominators remain NaN and unobserved onsets remain missing.
Pilot results are exploratory and are not pooled into confirmation estimates.

Figures and reports are generated under `output/following/`. They do not
overwrite existing manuscript figures. The final paper's claims must distinguish
imposed source agreement, transmission to non-followers, completed trades, and
quoted investment outcomes.

## Execution-price diagnostic

The historical confirmation diagnostic summary is deposited as
`code/data/Following-Diagnostic-confirmation-Summary.csv.gz` because the
uncompressed CSV exceeds GitHub's ordinary per-file limit. Its adjacent
`.gz.json` record contains the archive and uncompressed SHA-256 hashes.
The archive preserves every CSV byte; the uncompressed working copy is
ignored by Git. From the repository root, restore it before using the
historical diagnostic analysis scripts:

```sh
gzip -dk code/data/Following-Diagnostic-confirmation-Summary.csv.gz
```

The corrected manuscript uses the separately archived reserve-clearing
study under `output/rebuilt/manuscript-reserve-v1/`.

Run the deterministic settlement check with:

```sh
julia --project=code --startup-file=no --threads=1 --gcthreads=1 code/following/Diagnose-Following-Execution.jl
```

The [14 September diagnostic report](../../output/following/execution-audit-20260914/report.md)
records 35 prescribed-order cases in the full simulator. Fully filled buy–sell
and sell–buy cycles earn cash under the standing-quote settlement convention;
the dealer loses the same cash, and price and share holdings return to their
starting values. Zero-impact and zero-capacity controls remove the gain.
This isolates a competing explanation for follower returns, but does not
estimate its contribution to the completed following campaigns. The report
specifies the next execution comparison. Its alternative average execution
price is an analytical benchmark for isolated orders, not an implemented
replacement clearing engine. The diagnostic writes separate summaries,
per-step ledgers, and source/environment fingerprints.
