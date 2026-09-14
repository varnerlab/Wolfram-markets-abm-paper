# Original-story survival under reserve clearing

Completed 1600 simulations across 50 starting markets. The reserve dealer settles at an execution price consistent with its cash-and-share invariant. All pairs passed common-prehistory and accounting checks. Whole held decision histories matched legacy replays at f=0.20 for every tested reserve level and seed.

This is a retrospective model comparison. Reserve size changes both financial resources and price depth. The old impact coefficient is absent. Differences between mechanisms cannot be attributed solely to removal of round-trip profits. Each mechanism has its own warm-up and no-switch control.

## Complete repaired results

Drawdowns are medians; majority percentages count starting markets. The paired drawdown column averages differences against each run's no-switch control. Full pointwise mean intervals and conservative boundary bounds are in `Grouped.csv`.

| Technical traders | Reserve shares/trader | Rule fraction | Sell majority (%) | Median drawdown (%) | Mean paired drawdown (pp) |
|---|---:|---:|---:|---:|---:|
| active | 0.1 | 0.000 | 0.0 | 77.035 | 0.000 |
| active | 0.1 | 0.150 | 0.0 | 77.164 | 0.689 |
| active | 0.1 | 0.175 | 44.0 | 92.853 | 13.490 |
| active | 0.1 | 0.200 | 100.0 | 99.985 | 22.947 |
| active | 1 | 0.000 | 0.0 | 32.917 | 0.000 |
| active | 1 | 0.150 | 0.0 | 52.865 | 21.225 |
| active | 1 | 0.175 | 36.0 | 76.517 | 45.944 |
| active | 1 | 0.200 | 100.0 | 99.519 | 66.384 |
| active | 10 | 0.000 | 0.0 | 8.310 | 0.000 |
| active | 10 | 0.150 | 0.0 | 30.466 | 23.558 |
| active | 10 | 0.175 | 40.0 | 60.108 | 51.930 |
| active | 10 | 0.200 | 100.0 | 85.677 | 76.862 |
| active | 100 | 0.000 | 0.0 | 0.747 | 0.000 |
| active | 100 | 0.150 | 0.0 | 5.041 | 4.683 |
| active | 100 | 0.175 | 50.0 | 15.870 | 14.888 |
| active | 100 | 0.200 | 100.0 | 25.150 | 24.340 |
| held | 0.1 | 0.000 | 0.0 | 68.848 | 0.000 |
| held | 0.1 | 0.150 | 0.0 | 75.385 | 7.214 |
| held | 0.1 | 0.175 | 34.0 | 92.110 | 21.475 |
| held | 0.1 | 0.200 | 100.0 | 99.987 | 31.142 |
| held | 1 | 0.000 | 0.0 | 44.519 | 0.000 |
| held | 1 | 0.150 | 0.0 | 59.871 | 16.594 |
| held | 1 | 0.175 | 34.0 | 84.949 | 39.034 |
| held | 1 | 0.200 | 100.0 | 99.528 | 54.840 |
| held | 10 | 0.000 | 0.0 | 12.141 | 0.000 |
| held | 10 | 0.150 | 0.0 | 31.984 | 20.432 |
| held | 10 | 0.175 | 34.0 | 56.785 | 45.969 |
| held | 10 | 0.200 | 100.0 | 84.986 | 72.221 |
| held | 100 | 0.000 | 0.0 | 1.218 | 0.000 |
| held | 100 | 0.150 | 0.0 | 5.400 | 4.400 |
| held | 100 | 0.175 | 34.0 | 12.181 | 12.150 |
| held | 100 | 0.200 | 100.0 | 24.660 | 23.256 |

## Overlap with the archived model

These rows match initial dealer cash and shares. They do not match price depth. Both columns summarize the original 50 starting-market identities.

| Technical traders | Reserve shares/trader | Rule fraction | Old majority (%) | Repaired majority (%) | Old median drawdown (%) | Repaired median drawdown (%) |
|---|---:|---:|---:|---:|---:|---:|
| active | 0.1 | 0.150 | 0.0 | 0.0 | 0.000 | 77.164 |
| active | 0.1 | 0.175 | 66.0 | 44.0 | 0.399 | 92.853 |
| active | 0.1 | 0.200 | 100.0 | 100.0 | 0.399 | 99.985 |
| active | 1 | 0.150 | 0.0 | 0.0 | 0.000 | 52.865 |
| active | 1 | 0.175 | 48.0 | 36.0 | 3.921 | 76.517 |
| active | 1 | 0.200 | 100.0 | 100.0 | 3.921 | 99.519 |
| active | 10 | 0.150 | 0.0 | 0.0 | 4.881 | 30.466 |
| active | 10 | 0.175 | 28.0 | 40.0 | 13.368 | 60.108 |
| active | 10 | 0.200 | 100.0 | 100.0 | 25.260 | 85.677 |
| held | 0.1 | 0.150 | 0.0 | 0.0 | 0.000 | 75.385 |
| held | 0.1 | 0.175 | 34.0 | 34.0 | 0.092 | 92.110 |
| held | 0.1 | 0.200 | 100.0 | 100.0 | 0.399 | 99.987 |
| held | 1 | 0.150 | 0.0 | 0.0 | 0.000 | 59.871 |
| held | 1 | 0.175 | 34.0 | 34.0 | 1.211 | 84.949 |
| held | 1 | 0.200 | 100.0 | 100.0 | 3.921 | 99.528 |
| held | 10 | 0.150 | 0.0 | 0.0 | 5.130 | 31.984 |
| held | 10 | 0.175 | 34.0 | 34.0 | 11.790 | 56.785 |
| held | 10 | 0.200 | 100.0 | 100.0 | 24.720 | 84.986 |

The held local-rule result is independent of this financial repair. Interpret any survival of active-trader probabilities or drawdown relationships only over the displayed settings. This campaign does not repeat the full size/horizon or resource-multiplier grids. The reserve mechanism is an explicit alternative dealer model, not empirical validation of an equity exchange.
