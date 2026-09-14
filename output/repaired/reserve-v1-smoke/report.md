# Original-story survival under reserve clearing

Completed 64 simulations across 2 starting markets. The reserve dealer settles at an execution price consistent with its cash-and-share invariant. All pairs passed common-prehistory and accounting checks. Whole held decision histories matched legacy replays at f=0.20 for every tested reserve level and seed.

This is a retrospective model comparison. Reserve size changes both financial resources and price depth. The old impact coefficient is absent. Differences between mechanisms cannot be attributed solely to removal of round-trip profits. Each mechanism has its own warm-up and no-switch control.

## Complete repaired results

Drawdowns are medians; majority percentages count starting markets. The paired drawdown column averages differences against each run's no-switch control. Full pointwise mean intervals and conservative boundary bounds are in `Grouped.csv`.

| Technical traders | Reserve shares/trader | Rule fraction | Sell majority (%) | Median drawdown (%) | Mean paired drawdown (pp) |
|---|---:|---:|---:|---:|---:|
| active | 0.1 | 0.000 | 0.0 | 97.919 | 0.000 |
| active | 0.1 | 0.150 | 0.0 | 98.111 | 0.192 |
| active | 0.1 | 0.175 | 0.0 | 97.318 | -0.601 |
| active | 0.1 | 0.200 | 0.0 | 98.933 | 1.014 |
| active | 1 | 0.000 | 0.0 | 71.134 | 0.000 |
| active | 1 | 0.150 | 0.0 | 71.996 | 0.861 |
| active | 1 | 0.175 | 0.0 | 72.518 | 1.383 |
| active | 1 | 0.200 | 0.0 | 73.620 | 2.486 |
| active | 10 | 0.000 | 0.0 | 20.144 | 0.000 |
| active | 10 | 0.150 | 0.0 | 26.946 | 6.802 |
| active | 10 | 0.175 | 0.0 | 23.365 | 3.221 |
| active | 10 | 0.200 | 0.0 | 31.916 | 11.772 |
| active | 100 | 0.000 | 0.0 | 1.247 | 0.000 |
| active | 100 | 0.150 | 0.0 | 1.484 | 0.237 |
| active | 100 | 0.175 | 0.0 | 3.406 | 2.158 |
| active | 100 | 0.200 | 0.0 | 1.819 | 0.571 |
| held | 0.1 | 0.000 | 0.0 | 98.497 | 0.000 |
| held | 0.1 | 0.150 | 0.0 | 98.260 | -0.237 |
| held | 0.1 | 0.175 | 0.0 | 98.000 | -0.497 |
| held | 0.1 | 0.200 | 0.0 | 98.315 | -0.181 |
| held | 1 | 0.000 | 0.0 | 76.889 | 0.000 |
| held | 1 | 0.150 | 0.0 | 82.513 | 5.624 |
| held | 1 | 0.175 | 0.0 | 77.747 | 0.858 |
| held | 1 | 0.200 | 0.0 | 79.090 | 2.201 |
| held | 10 | 0.000 | 0.0 | 16.313 | 0.000 |
| held | 10 | 0.150 | 0.0 | 24.934 | 8.620 |
| held | 10 | 0.175 | 0.0 | 18.326 | 2.012 |
| held | 10 | 0.200 | 0.0 | 17.794 | 1.480 |
| held | 100 | 0.000 | 0.0 | 0.967 | 0.000 |
| held | 100 | 0.150 | 0.0 | 1.722 | 0.756 |
| held | 100 | 0.175 | 0.0 | 0.946 | -0.020 |
| held | 100 | 0.200 | 0.0 | 0.973 | 0.006 |

The held local-rule result is independent of this financial repair. Interpret any survival of active-trader probabilities or drawdown relationships only over the displayed settings. This campaign does not repeat the full size/horizon or resource-multiplier grids. The reserve mechanism is an explicit alternative dealer model, not empirical validation of an equity exchange.
