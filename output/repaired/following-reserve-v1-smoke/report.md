# Shared advice and copying under reserve clearing

Completed 36 runs across 1 starting markets. This pilot uses new starting markets and two design replicates per market in its full form. It is exploratory. Pointwise intervals resample whole starting markets.

Every treated run has an identical no-following prehistory. Liquidation uses the same prospective follower cohort in its own no-following endpoint. All traders request sales without new buys or outside funds, under the same reserve-clearing rule. Both arms sell every remaining share; proceeds can still differ.

Columns report mean paired changes: marked follower returns, non-follower Sell decisions, market drawdown, and normalized follower cash after the matched liquidation. Exit is a simultaneous-exit stress scenario. No fees or external fundamental value are modeled.

| Mechanism | Technical traders | Reserves/trader | Adoption | Sources | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Exit cash change (pp) |
|---|---|---:|---:|---|---:|---:|---:|---:|
| advice | held | 1 | 10% | 1 | -9.808 | -2.568 | 5.199 | 43.038 |
| copy_filled | held | 1 | 10% | 1 | 24.655 | -5.709 | -9.261 | 9.348 |
| advice | held | 1 | 10% | independent | 24.994 | -5.084 | -1.540 | 62.298 |
| advice | held | 1 | 40% | 1 | -29.913 | 28.665 | 12.350 | 17.771 |
| advice | held | 1 | 40% | 16 | -8.729 | -10.085 | 5.604 | 23.406 |
| copy_filled | held | 1 | 40% | 1 | 8.635 | -9.290 | -17.763 | 0.735 |
| copy_filled | held | 1 | 40% | 16 | 98.391 | -12.074 | -0.903 | 6.294 |
| advice | held | 1 | 40% | independent | -9.057 | -10.653 | 6.502 | 23.330 |
| advice | active | 1 | 10% | 1 | -13.451 | -2.804 | 10.159 | 27.118 |
| copy_filled | active | 1 | 10% | 1 | -11.334 | -4.172 | 4.123 | -2.559 |
| advice | active | 1 | 10% | independent | 7.200 | -3.530 | -0.071 | 26.005 |
| advice | active | 1 | 40% | 1 | -42.690 | 27.074 | 23.666 | -3.106 |
| advice | active | 1 | 40% | 16 | -22.177 | -7.727 | 11.732 | 9.831 |
| copy_filled | active | 1 | 40% | 1 | 9.033 | -9.631 | -6.798 | -1.735 |
| copy_filled | active | 1 | 40% | 16 | -4.551 | -10.256 | 3.890 | 1.992 |
| advice | active | 1 | 40% | independent | -13.858 | -9.631 | 10.031 | 9.908 |
| advice | held | 100 | 10% | 1 | -1.405 | -2.568 | 1.831 | 12.237 |
| copy_filled | held | 100 | 10% | 1 | 1.920 | -5.709 | -1.690 | 3.351 |
| advice | held | 100 | 10% | independent | 0.963 | -5.084 | -0.049 | 9.270 |
| advice | held | 100 | 40% | 1 | -8.498 | 28.665 | 19.907 | 3.869 |
| advice | held | 100 | 40% | 16 | -1.717 | -10.085 | 1.600 | 5.201 |
| copy_filled | held | 100 | 40% | 1 | -0.318 | -9.290 | -1.381 | 1.214 |
| copy_filled | held | 100 | 40% | 16 | 0.925 | -12.386 | -1.028 | 1.526 |
| advice | held | 100 | 40% | independent | -1.917 | -10.653 | 1.466 | 4.910 |
| advice | active | 100 | 10% | 1 | -3.875 | 2.686 | 7.553 | 9.702 |
| copy_filled | active | 100 | 10% | 1 | -0.848 | -4.730 | 0.265 | 0.544 |
| advice | active | 100 | 10% | independent | -1.628 | -2.753 | 2.070 | 6.722 |
| advice | active | 100 | 40% | 1 | -11.549 | 30.312 | 18.492 | 2.440 |
| advice | active | 100 | 40% | 16 | -4.933 | -5.000 | 4.470 | 4.245 |
| copy_filled | active | 100 | 40% | 1 | -1.703 | -8.864 | -0.061 | 0.678 |
| copy_filled | active | 100 | 40% | 16 | -1.874 | -9.318 | 1.167 | 0.882 |
| advice | active | 100 | 40% | independent | -4.925 | -6.080 | 4.183 | 3.990 |

`Grouped.csv` and `Contrasts.csv` contain pointwise intervals and all declared outcomes. The concentration comparisons are one source minus independent advice and one copied leader minus sixteen. The repaired pilot and old confirmation samples are not pooled. Differences from old results reflect the changed market mechanism as a whole, not an isolated estimate of arbitrage contamination.
