# Shared advice and copying under reserve clearing

Completed 880 runs across 10 starting markets. This pilot uses new starting markets and two design replicates per market in its full form. It is exploratory. Pointwise intervals resample whole starting markets.

Every treated run has an identical no-following prehistory. Liquidation uses the same prospective follower cohort in its own no-following endpoint. All traders request sales without new buys or outside funds, under the same reserve-clearing rule. Both arms sell every remaining share; proceeds can still differ.

Columns report mean paired changes: marked follower returns, non-follower Sell decisions, market drawdown, and normalized follower cash after the matched liquidation. Exit is a simultaneous-exit stress scenario. No fees or external fundamental value are modeled.

| Mechanism | Technical traders | Reserves/trader | Adoption | Sources | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Exit cash change (pp) |
|---|---|---:|---:|---|---:|---:|---:|---:|
| advice | held | 1 | 10% | 1 | -72.054 | 2.951 | 52.247 | -5.943 |
| advice | held | 1 | 10% | 16 | -60.537 | -3.723 | 16.660 | 3.161 |
| copy_filled | held | 1 | 10% | 1 | -63.035 | -0.983 | 37.830 | -9.450 |
| copy_filled | held | 1 | 10% | 16 | -36.443 | -4.148 | 7.286 | -2.757 |
| advice | held | 1 | 10% | independent | 3.601 | -3.985 | -4.129 | 35.527 |
| advice | held | 1 | 40% | 1 | -12.520 | 18.904 | 55.111 | -5.697 |
| advice | held | 1 | 40% | 16 | -62.084 | -10.921 | 52.033 | 2.402 |
| copy_filled | held | 1 | 40% | 1 | -21.153 | 4.009 | 35.456 | -0.332 |
| copy_filled | held | 1 | 40% | 16 | 51.914 | -18.306 | 22.831 | -0.949 |
| advice | held | 1 | 40% | independent | -30.234 | -13.014 | 9.416 | 17.754 |
| advice | active | 1 | 10% | 1 | -81.865 | 2.885 | 63.452 | -15.481 |
| advice | active | 1 | 10% | 16 | -61.155 | -3.759 | 15.797 | -3.200 |
| copy_filled | active | 1 | 10% | 1 | -60.037 | -1.323 | 48.420 | -11.459 |
| copy_filled | active | 1 | 10% | 16 | -46.842 | -4.200 | 9.591 | -7.027 |
| advice | active | 1 | 10% | independent | 9.351 | -4.009 | -5.285 | 33.680 |
| advice | active | 1 | 40% | 1 | -85.147 | 18.568 | 68.213 | -18.526 |
| advice | active | 1 | 40% | 16 | -81.392 | -11.073 | 63.475 | -15.405 |
| copy_filled | active | 1 | 40% | 1 | -5.164 | -2.380 | 42.012 | 1.367 |
| copy_filled | active | 1 | 40% | 16 | 17.618 | -18.401 | 31.570 | -3.288 |
| advice | active | 1 | 40% | independent | -14.169 | -13.107 | 14.036 | 20.917 |
| advice | held | 100 | 10% | 1 | 42.715 | 2.951 | 17.621 | 42.228 |
| advice | held | 100 | 10% | 16 | 0.009 | -3.723 | 1.936 | 7.472 |
| copy_filled | held | 100 | 10% | 1 | 3.046 | 0.703 | 9.189 | 9.311 |
| copy_filled | held | 100 | 10% | 16 | 0.725 | -4.128 | 0.180 | 0.992 |
| advice | held | 100 | 10% | independent | -0.383 | -3.985 | 0.274 | 7.032 |
| advice | held | 100 | 40% | 1 | 23.152 | 18.904 | 27.556 | 27.008 |
| advice | held | 100 | 40% | 16 | -1.950 | -10.921 | 11.699 | 6.130 |
| copy_filled | held | 100 | 40% | 1 | -4.350 | 4.074 | 9.224 | 0.585 |
| copy_filled | held | 100 | 40% | 16 | 1.392 | -18.309 | 0.281 | 0.808 |
| advice | held | 100 | 40% | independent | -3.368 | -13.014 | 4.363 | 4.886 |
| advice | active | 100 | 10% | 1 | 40.150 | 3.007 | 17.893 | 39.798 |
| advice | active | 100 | 10% | 16 | -0.635 | -3.714 | 2.129 | 6.786 |
| copy_filled | active | 100 | 10% | 1 | 0.789 | -0.357 | 8.268 | 7.689 |
| copy_filled | active | 100 | 10% | 16 | 0.529 | -4.156 | 0.221 | 0.609 |
| advice | active | 100 | 10% | independent | -0.325 | -3.981 | 0.505 | 6.968 |
| advice | active | 100 | 40% | 1 | 15.779 | 18.715 | 27.574 | 20.640 |
| advice | active | 100 | 40% | 16 | -2.832 | -10.993 | 11.908 | 5.253 |
| copy_filled | active | 100 | 40% | 1 | -2.310 | -6.509 | 5.850 | 0.720 |
| copy_filled | active | 100 | 40% | 16 | 1.298 | -18.378 | 0.357 | 0.649 |
| advice | active | 100 | 40% | independent | -3.179 | -13.063 | 4.605 | 4.951 |

`Grouped.csv` and `Contrasts.csv` contain pointwise intervals and all declared outcomes. The concentration comparisons are one source minus independent advice and one copied leader minus sixteen. The repaired pilot and old confirmation samples are not pooled. Differences from old results reflect the changed market mechanism as a whole, not an isolated estimate of arbitrage contamination.
