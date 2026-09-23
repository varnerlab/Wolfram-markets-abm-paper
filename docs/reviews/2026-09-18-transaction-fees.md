# Transaction-fee design discussion

Status: recommendation under discussion. No simulator or manuscript changes
have been applied for this extension. The existing manuscript and PDF still
describe the executed model without fees.

## Author direction and pending edits

The author accepted removal of the confusing settlement qualifier
“including orders matched between traders.” All orders use the dealer's
clearing process; opposite orders offset in the dealer's net reserve change.
The proposed opening is “All completed orders settled at the common
execution price $F_t=F_t(x_t)$.”

The author then identified the absence of a dealer margin. An explicit
statement that the dealer charged no transaction fee, with a corresponding
Discussion limitation, was accepted for application. Before those edits
were made, the author redirected the task: “I don't care if we need to run
sims over again” and asked whether adding transaction fees would be more
realistic. Hold the pending settlement/no-fee prose while this scientific
choice is discussed. Technical-trader review has not yet been presented.

## Recommendation

Add a proportional fee as an explicit model extension and retain zero fee
as a comparison. The scientific purpose is to test whether the connections
between decision propagation, trader resources, and price declines persist
when repeated trading transfers cash to the dealer. This adds dealer fee
revenue and execution costs. It does not introduce dealer optimization,
endogenous liquidity withdrawal, or traders that weigh expected gains
against fees before choosing an action.

For a fee fraction $0\leq\tau<1$ and common base execution price $F_t$,
each completed one-share buy costs $(1+\tau)F_t$ and each completed sale
receives $(1-\tau)F_t$. Charge only completed orders and require buyer cash
to cover the base price plus fee when computing eligibility. Seller fees
can be deducted from sale proceeds. The dealer earns
$\tau F_t(n_t^B+n_t^S)$, including on balanced batches. This is a proposed
cash fee on each participant's completed order, not a claim to reproduce a
particular exchange fee schedule.

Initially hold dealer fee income in a separate account excluded from the
trading reserves $W_t,Q_t$. Include that account in total cash conservation.
Then the existing reserve-product identity and quote definition continue
to apply to trading reserves; total dealer cash includes both reserves and
fees. An isolated reversed trade restores the trading reserves while
leaving fee revenue with the dealer and a cash loss for the trader.

If cash fees were instead added directly to $W_t$ without changing the
definition $P_t=W_t/Q_t$, even a balanced batch would raise the quote.
That is a fee-reinvestment mechanism with an additional price effect,
not a neutral bookkeeping choice. A separately collected fee is a defensible
first design. Separating collected fees from active liquidity also has
precedent in Uniswap v3; the present cash fee and batch mechanism are not
identical to that protocol.

Apply a fixed fee from initialization in both paths of each rule-change
pair. Compare zero fee with a prespecified range of small positive fees
using common initial conditions and seeds, with technical traders active
and held. Across fee rates, financial histories may differ during the
baseline. Within each fee condition, the switch and no-switch paths must
share their history until the intervention. Measure majority probability,
drawdown, completed volume, cash-related suppression, and dealer fee income.
Do not choose a fee because it preserves a preferred result. Rates and the
exact rerun scope remain to be specified; no empirical fee calibration has
been established. The finite closed market's depletion of trader cash over
long horizons is part of the mechanism to measure.

Held technical traders should retain exactly the same interior decision
histories across fee rates, because holdings do not enter that update.
Financial histories and price paths need not coincide. Tests must include
zero-fee equivalence, buyer affordability including fees, nonnegative books,
cash conservation including fee income, balanced orders, round trips, and
the zero-reserve fixed-price branch. Fees from that branch must not fund
dealer trading if it is to remain the same fixed-price control.

## Evidence and targeted checks

Inspected the current and frozen `code/src/ReserveClearing.jl`,
`code/rebuild/README.md`, and the project's source-preservation requirements.
The current clearing function uses the same settlement price for buyers
and sellers, changes dealer reserves by the net trade, and preserves the
reserve product. There is no fee parameter or fee-revenue account. A new
versioned study is required if this extension is implemented; retain the
executed `manuscript-reserve-v1` snapshot and its results.

Exact rational arithmetic with initial dealer cash 10,000, 100 shares,
and a fee of 0.1% per completed order checked these proposed balances:

| Completed buys/sells | Fee revenue | Quote with separate fees | Quote with fees added to trading cash |
|---|---:|---:|---:|
| 1 / 1 | 0.20000000 | 100.00000000 | 100.00200000 |
| 3 / 2 | 0.50505051 | 102.03040506 | 102.03550658 |
| 0 / 2 | 0.19607843 | 96.11687812 | 96.11880046 |

Total cash was conserved when dealer fees were included. The trading
reserve product remained unchanged with separate fees. A one-share buy
followed by its isolated reverse restored both trading reserves and
transferred 0.20202020 cash from the trader to the dealer's fee account.
These are accounting examples, not simulation outcomes or a selected fee
calibration.

Primary sources checked:

- [Uniswap v2 white paper](https://app.uniswap.org/whitepaper.pdf),
  Introduction and price-oracle definition: constant-product pricing,
  fees paid to liquidity providers, and the reserve ratio as price excluding
  fees. This supports treating pricing and fee collection as distinct
  ingredients, not importing its complete market design.
- [Uniswap v3 white paper](https://app.uniswap.org/whitepaper-v3.pdf),
  Section 3.2.1: collected fees are held separately rather than automatically
  reinvested as active liquidity. This supports the accounting choice only;
  it is not evidence for a particular fee rate in this synthetic market.

## Extension accepted and implemented, 18 September

The author accepted the proportional-fee recommendation with “Agree.
Update. Next.” Implemented a separate dealer revenue account and full
buyer/seller settlement at the fee-inclusive amounts. The original fee-free
engine is retained and is called directly when the fee is zero. Added an
optional reserve-settlement function to the current simulator; no existing
configuration or result fields were changed. The executed original study
was preserved.

The initial sensitivity design was fixed before simulation: fees of 0,
5, 10, and 25 basis points per completed order; dealer reserves per trader
of 0.1, 1, and 100; technical traders held or active; seeds 1–50; fractions
0.10, 0.15, 0.175, 0.185, 0.20, and 0.25. Each parameter combination shares
one fresh no-switch control across six changed-rule runs. The 8,400 full
financial simulations use 64-by-64 grids, 1,000 baseline steps, and 3,000
post-switch steps. Fees apply from initialization. Rates are sensitivity
parameters and are not represented as empirically calibrated charges.

The new study is `output/rebuilt/transaction-fees-v1/`. Its source,
environment, reference engine, and manifest were frozen before the run.
`code/fees/Prepare.py`, `Run.py`, `Run.jl`, and `Analyze.py` provide the
reproducible workflow. The separate manuscript writer is recorded with
postprocessing hashes. The new comparison supplements the original
experiments; it does not silently replace results from other sizes,
resource interventions, following conditions, or long windows.

Tests passed: 2,263 fee assertions, including exact zero-fee agreement with
the frozen executed engine, and 6,028 existing reserve-clearing assertions.
The fee tests cover randomized exhaustive quantity selection, unfilled
orders, separate revenue, fee-inclusive affordability, isolated round
trips, balanced batches, zero reserves, common prehistory, and independence
of held interior decisions from fees. Every production run checks cash
conservation including fees, share conservation, reserve product, quote,
nonnegative final books, and revenue against completed volume. Every
changed-rule run is checked against its control before a group checkpoint
is written.

Independent read-only reviewer `rule_construction_check` found no
implementation or pairing defect. The reviewer identified an omitted
share-transfer instruction in the written zero-reserve pseudocode. Corrected
that branch to invoke the full cash, share, and cost-basis updates, followed
by the fee-account update. The simulator already executed these transfers
correctly. Final numerical and PDF checks are recorded below.


## Completed evidence and final verification, 18 September

All 8,400 simulations completed, representing 1,200 control/treatment
comparison groups. Manifest completeness, frozen source hashes, paired
prehistory, and per-run accounting checks passed. The largest absolute
cash-conservation discrepancy was 8.419156074523926e-7. All zero-fee
revenues were zero. With technical traders held, Sell fractions at every
step and final grids were identical across fees and reserve depths. This
wording names the stored evidence; complete interior frames were not
archived at every step.

The results do not support a uniformly stabilizing effect of fees. With
active technical traders, h=100, and f=0.20, increasing the fee from zero
to 25 basis points changed median maximum drawdown from 25.15% to 23.67%.
The median paired change was -1.34 percentage points, with a 95% bootstrap
interval of [-1.60,-1.16]. At h=1 and f=0.175, the same comparison changed
median drawdown from 76.52% to 92.81%; the median paired change was +9.04
percentage points [3.46,16.98]. These are medians of paired differences,
not differences of the reported medians. At h=100 and f=0.175, majority
probability changed from 0.50 to 0.40, with paired difference -0.10
[-0.28,0.08], so its direction was unresolved.

Independent reviewer `rule_construction_check` recomputed all condition
summaries and all 288 paired-effect rows, including their intervals, from
the complete records. All 27 rows of Table S12 match the checked summaries.
The review prompted a second table panel to support the selected paired
Results comparisons, precise held-history wording, and a caption qualifier
limiting the f=0.20 description to Panel A. All corrections were rechecked
on the saved source; no substantive findings remain.

The numerical study and original frozen analysis were preserved. The
reporting-only script `code/fees/Analyze-reporting.py` and the manuscript
writer are recorded in `Postprocessing-Sources.json` within the fee study.
The run-summary SHA-256 remains
`cfe160cd54831b0b4075dc0ad118160925a528f86c7a81514a4f4ddd2f26bfef`.
Methods, Results, Table S12, and fee validation are generated by
`code/fees/WritePaper.py`; settlement equations, pseudocode, conservation,
and the targeted Discussion limitation were updated consistently.

Normal and isolated source-archive builds passed, with identical extracted
PDF text and clean final LaTeX/BibTeX logs. The PDF has 31 pages. All pages
were rendered and visually inspected, including the corrected table and
all reflowed passages; the standalone fee-sensitivity figure was also
inspected. Refreshed the output PDF and the 29-file source archive. The
final PDF SHA-256 is
`1e9a82ce251c523b17ca01c08e5d3e69794c613d737c3f71640c33e390898212`.

The next interactive unit is the opening of “Technical traders and price
feedback,” proposed in `2026-09-18-methods-technical-traders.md` and not
applied. The fee additions have passed technical review; their prose remains
available for the author's voice review. Full Discussion and remaining
section reviews are still pending. No commit was made.
