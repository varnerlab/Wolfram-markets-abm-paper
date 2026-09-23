# Transaction-fee sensitivity

This extension charges a proportional cash fee on each completed order.
Buyers pay `(1+tau)*F`, sellers receive `(1-tau)*F`, and the dealer collects
`tau*F*(completed_buys+completed_sells)`. Buy eligibility includes the fee.
Fees on sells are deducted from proceeds. No fee applies to unfilled orders.
Buyer cost basis includes fees. The production comparisons allow sales at
a loss; if the optional cost-basis restriction is enabled, it compares net
sale proceeds with the acquisition cost including fees.

Dealer revenue is kept outside the cash/share reserves used for pricing.
It is included in total cash conservation but cannot fund dealer purchases.
Trading reserves still preserve their product. At zero reserves, only
opposing orders fill at the fixed base price, including when fees accrue.
Zero fee delegates to the original clearing implementation.

`code/src/Simulate.jl` has an optional reserve execution function. Its default
retains the existing model. Fee results wrap the original market result
alongside cumulative fee revenue and base execution prices; existing result
types and archived studies are unchanged.

The initial study uses 0, 5, 10, and 25 basis points per completed order,
dealer reserves of 0.1, 1, or 100 shares per trader, active/held technical
traders, and 50 seeds. Six rule fractions (0.10, 0.15, 0.175, 0.185, 0.20,
0.25) share one freshly executed control within each fee/depth/mode/seed
condition. This gives 8,400 full financial runs on 64-by-64 grids, each
with 1,000 baseline and 3,000 post-switch steps. Fees apply throughout.
These are sensitivity parameters, not an empirical fee calibration.

From the repository root:

```sh
julia --project=code --startup-file=no code/fees/Test-Fees.jl
python3 code/fees/Prepare.py output/rebuilt/transaction-fees-v1
python3 code/fees/Run.py output/rebuilt/transaction-fees-v1 --threads 12
python3 code/fees/WritePaper.py output/rebuilt/transaction-fees-v1 --paper paper-arxiv
```

Prepare requires a new destination and verifies the original executed
study's hashes before copying its reference engine. It copies source and
environment files, never prior simulation results. Run verifies the frozen
source and manifest, runs tests, resumes only complete group checkpoints,
and checks hashes again after each phase. Each group checkpoint is written
atomically after all seven full runs and common-history checks pass.
Changing computation or design requires a new study version.

In a sandbox where the usual Julia cache is read-only, point
`JULIA_DEPOT_PATH` at a writable directory followed by the existing depot.
The run uses installed packages with `JULIA_PKG_OFFLINE=true`.

The analysis verifies manifest completeness, fee accounting, within-pair
histories, and identical held Sell-fraction histories and final grids
across fee rates and reserve depths.
It writes per-condition and paired summaries, an assessment, a figure,
and a validation report. `WritePaper.py` generates separate Methods,
Results, table, and supplementary-validation inputs from the validated
study; it does not overwrite the earlier study's generated sections.
The initial version does not rerun size, endowment, following, or long-window
experiments. Fee income as a fraction of initial trader cash includes the
whole run; financial outcomes after the switch use the original manuscript
measurement windows.

The completed `transaction-fees-v1` study retains its original frozen
`code/fees/Analyze.py`. A reporting-only correction, recorded in
`Postprocessing-Sources.json`, is saved as `code/fees/Analyze-reporting.py`
inside the study. It names the recorded held-history checks precisely;
the calculations and numerical summaries are unchanged. To reproduce the
final reporting after resuming this particular study, run:

```sh
python3 output/rebuilt/transaction-fees-v1/code/fees/Analyze-reporting.py output/rebuilt/transaction-fees-v1
python3 code/fees/WritePaper.py output/rebuilt/transaction-fees-v1 --paper paper-arxiv
```
