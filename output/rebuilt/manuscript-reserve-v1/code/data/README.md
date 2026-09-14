# Corrected manuscript data

These files belong to the isolated `manuscript-reserve-v1` study. The directory
started empty. Historical results in the repository's root `code/data/`
were not imported. `../../Status.json` records execution progress;
`../../Verification.json` records the completed audit.

`Rebuild-Execution-Ledger.csv` contains one row for each full simulation made
through the study wrapper, written after its reserve, resource, and
conservation checks. Its
order reflects task completion. Scientific summaries are sorted by condition
and starting market. `../../Manifest.csv` specifies every fixed simulation;
the local `*-Manifest.csv` files also record supplementary and adaptive jobs.

| Files | Manuscript role |
|---|---|
| `ModelB-RuleQuench-Full-*` | Paired rule-switch outcomes and Figure 1 histories. |
| `ModelB-ReservoirQuench-Full-*` | Dealer-depth ensemble, matched no-switch outcomes, and numerical selection of examples. |
| `ModelB-FiniteSizeQuench-Full-*` | Original fraction grid; every summary came from a full financial simulation. |
| `ModelB-Revision-FiniteSize-*` | Original grid plus refinement; the grouped/scaling files supply Figure 3 and Tables S3/S10. |
| `ModelB-BalanceSheetQuench-Full-*` | Cash/share interventions and Figure 6. |
| `ModelB-Revision-screen`, `-pulse`, `-band`, `-impact`, `-long` | Rule screen, Sell pulses, band controls, additional reserve depths, and long no-switch controls. |
| `ModelB-Revision-Horizons*` | Fixed and size-dependent observation windows, with three Sell criteria. |
| `ModelB-Revision-MarketPanel-Horizons*` | Extended selected histories and all fifty markets at fraction .15. |
| `Figure4-Prespecified-Selection.csv`, `Figure4-Selection.csv` | Numerical selection before long-history/image inspection, and the selection used by the plotted reruns. |
| `Rebuild-Dealer-Paired-Drawdown.csv` | Both feedback conditions at all eight depths, including paired bootstrap differences. |
| `Rebuild-Band-Contrast.json` | Paired comparison of depth contrasts under adaptive and frozen widths. |
| `Rebuild-Figure-Metadata.json` | The actual seeds used in Figures 1, 4, and 5. |

The model always uses `clearing=:reserve`. `market_maker_capacity` and `h`
denote initial dealer shares per trader. Depth 100 is finite; depth zero
is the separate fixed-price matched-trade control. The retained `impact`
column in the additional-depth campaign records the initial slope `2/h`;
it is not an independently varied exponential impact coefficient.

`endogenous` means active technical traders and `hold` means held technical
traders. Held conditions still ran the full financial model. Fractions
`f` and `target_f` are nominal; the selected site count is rounded to an
integer. A seed identifies initialization and rationing priorities within
a specified grid and condition.

Prices are marginal dealer quotes. They differ from the uniform execution
price when the dealer takes a net position. Drawdown is the largest
proportional fall from a running peak in the post-switch quote window,
including the quote at activation. Stored drawdown and price-change values
are fractions, while several manuscript tables display percentages.

Order suppression and dealer rejection use post-switch orders only.
Suppression counts desired orders lacking trader resources at the selected
execution price. Rejection counts eligible orders that do not execute;
the denominator is eligible orders, with zero reported when none are
eligible. Consequently, low rejection need not mean low suppression.

Majority onset is the first updated post-switch interior state with Sell
fraction at least one-half; zero means no crossing within the stated window.
The `onset40` and `onset60` fields use criteria .4 and .6 instead.
Final Sell means use the last 500 states. The `temporal_susceptibility` field
in the original size summary, and `susceptibility` in the resource summary,
describe within-history variation. Figure 3 instead uses
`ensemble_susceptibility`: the number of interior sites multiplied by the
variance across starting markets of their final Sell means.

Bootstrap results resample whole starting markets. Finite-size and horizon
intervals condition on the sampled fraction grid. The additional paired
drawdown intervals are descriptive and pointwise. Details and generator
sources are recorded in `../../Analysis-Notes.md` and the manuscript Methods.

Restart checkpoints support recovery within this run. They are not copied
by `ColdClone.py` and are excluded from the final source-and-results archive.
