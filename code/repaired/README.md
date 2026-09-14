# Repaired execution and market-model comparison

The completed comparison and remaining scientific limits are summarized in
[What survives the execution repair](../../output/repaired/ASSESSMENT.md).
The latest [fresh-market confirmation](../../output/repaired/transmission-confirmation-v1-full/ASSESSMENT.md)
passed both predeclared criteria across 50 new starting markets and 5,200 runs.

The original standing-quote settlement convention permits profitable round
trips. The current research entry points use `clearing=:reserve`: a finite,
constant-product cash-and-share dealer with uniform batch execution prices.
The design, assumptions, proof of the closed-path accounting property, and
limits are in the [repair protocol](../../docs/superpowers/specs/2026-09-14-reserve-clearing-repair.md).

Run from the repository root:

```sh
julia --project=code --startup-file=no code/repaired/Test-ReserveClearing.jl
julia --project=code --startup-file=no code/repaired/Test-Repaired-Following.jl
julia --project=code --startup-file=no code/repaired/Compare-RoundTrips.jl
julia --project=code --startup-file=no --threads=12 --gcthreads=1 code/repaired/Compute-Survival.jl full
julia --project=code --startup-file=no code/repaired/Analyze-Survival.jl full
julia --project=code --startup-file=no --threads=12 --gcthreads=1 code/repaired/Compute-Following-Pilot.jl
julia --project=code --startup-file=no code/repaired/Analyze-Following-Pilot.jl
python3 code/repaired/Verify-Outputs.py
```

`bash code/run_all.sh repaired` runs this sequence. Use `repaired-tests` for
checks alone. Each compute script accepts `smoke` for a small workflow check.
The full original-story comparison contains 1,600 runs, including 400 shared
no-switch controls, across the original 50 market seeds. It checks fractions
0.15/0.175/0.20, reserves 0.1/1/10/100 shares per trader, and held/active
technical traders. The following pilot contains 880 runs (800 treated and
80 controls), with ten new starting markets and two design replicates. It
checks 10%/40% adoption, one/sixteen sources plus independent advice, reserves
1/100, both technical-trader conditions, and matched simultaneous liquidation.
It does not replace the previous confirmation campaign with a new confirmation.

The next mechanism comparison uses the same repaired engine and pilot starting
markets. It compares continuous advice, masking its direct local influence,
and withdrawing it after 1,000 steps. Both shared and independent advice are
included, along with cash attribution after every trader liquidates. The
[transmission protocol](../../docs/superpowers/specs/2026-09-14-reserve-transmission-controls.md)
specifies 1,040 runs and the primary comparison. Run it with:

```sh
bash code/run_all.sh repaired-transmission
```

For individual steps, run `Test-Transmission.jl`, `Compute-Transmission.jl`,
and `Analyze-Transmission.jl` with the Julia command above, followed by
`python3 code/repaired/Verify-Transmission.py`. Compute, analysis, and
verification accept `smoke`. Results are in `output/repaired/transmission-v1-pilot`.
The completed [assessment](../../output/repaired/transmission-v1-pilot/ASSESSMENT.md)
links the full results and a standalone figure. Rebuild that figure with
`python3 code/repaired/Figs-Transmission.py` from the repository root.

The fresh-market confirmation repeats the complete transmission design on
50 new starting markets, with two design replicates each: 5,200 runs including
400 no-following controls. Its
[protocol](../../docs/superpowers/specs/2026-09-14-reserve-transmission-confirmation.md)
fixes two required endpoints in the primary deep-reserve, 40%-adoption,
shared-advice setting with technical traders held. Both follower exit-cash
advantage and the continuous-minus-masked cash contrast must have positive
lower limits in their adjusted 97.5% bootstrap intervals. Secondary comparisons
use pointwise 95% intervals. Pilot rows are never pooled with confirmation.

```sh
bash code/repaired/Run-Transmission-Confirmation.sh
```

This command runs analysis and checkpoint tests, the small smoke workflow,
and the full confirmation with verification and figures. It defaults to 12
simulation threads and one garbage-collection thread, using the same environment
overrides as `run_all.sh`. The output directory is
`output/repaired/transmission-confirmation-v1-full`; the smoke sample has a
separate directory and never receives a confirmation label. The saved manifest,
source, analysis, environment, and freshness audit must match on resume.
An existing `.writer-lock` rejects a second writer. If execution was killed,
check that its recorded process is no longer running before removing that
lock and resuming. Individual preparation, analysis, verification, and figure
commands are exposed by `Transmission-Confirmation.py --help`; the Julia
compute entry point is `Compute-Transmission-Confirmation.jl`.

Outputs are under `output/repaired/`, each with an immutable source/environment
protocol, a complete manifest, atomic block checkpoints, summaries, and reports.
Only one writer may run each campaign. Resume reuses checkpoints only if the
source and manifest digests match. Changed code requires a new campaign version.
The current outputs are `reserve-v2-full`, `following-reserve-v2-pilot`, and
`round-trips-v2`. Version 2 removes captured-variable allocations in the
auction search without changing its arithmetic. Its 400 original-story
checkpoints and the 14 completed version 1 following checkpoints match exactly.
Version 1 source is archived in
`output/recovery/20260914-reserve-v1-executed-source/source.tar.gz`.

`simulate` and `run_following` retain `clearing=:legacy` as their default for
reproduction of archived experiments. New research must explicitly request
`:reserve` and finite nonnegative `market_maker_capacity`. This parameter now
sets initial reserve shares per trader; it does not impose a maximum inventory
of twice the initial reserve. The old lambda price-impact coefficient does
not apply. Large finite reserves are the deep-liquidity comparison; infinite
reserves are rejected. Pass `clearing=:reserve` to `paired_following` and
`following_wind_down` as well so control and exit paths use the same mechanism.

The reserve model changes both settlement and the economic representation of
liquidity. Comparisons with the archived model therefore test conclusions
across mechanisms; they do not estimate how much of an old effect was caused
solely by the round-trip flaw. Financial conclusions in the existing manuscript
remain pending review. Exact independence of held local decisions from finance
is checked separately.

Pre-repair source is archived in
`output/recovery/20260914-before-market-repair/source-and-protocols.tar.gz`,
with file hashes in `SHA256.json`. It includes the source for the completed
following campaigns. The original campaign CSVs and checkpoints are retained.
