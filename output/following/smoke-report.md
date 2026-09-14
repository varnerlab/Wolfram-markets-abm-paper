# Following experiment: smoke

Complete manifest: 88 runs, including 8 shared no-following controls. There are 2 independent starting markets.

All treatment pairs have matching starting-state fingerprints. Per-run checks reconcile individual orders with aggregate execution and verify cash and share conservation.

The estimates below compare following with the same tagged traders in the paired no-following market. Returns and drawdowns are gross simulated outcomes. Intervals resample entire starting markets and are pointwise. Source agreement is imposed in the advice experiment; non-follower responses measure transmission beyond the followers.

| Mechanism | Followers | Sources | Capacity | Technical traders | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Source active (%) |
|---|---:|---:|---:|---|---:|---:|---:|---:|
| advice | 10% | 1 | 0.1 | held | -0.000 | -3.209 | 0.000 | 70.00 |
| copy_filled | 10% | 1 | 0.1 | held | -0.000 | -3.108 | 0.000 | 50.00 |
| advice | 10% | independent | 0.1 | held | -0.000 | -3.666 | 0.000 | 43.62 |
| advice | 40% | 1 | 0.1 | held | 0.018 | 15.852 | 0.360 | 70.00 |
| copy_filled | 40% | 1 | 0.1 | held | 0.010 | -3.977 | 0.378 | 18.75 |
| advice | 40% | independent | 0.1 | held | -0.000 | -6.392 | 0.000 | 47.72 |
| advice | 10% | 1 | 0.1 | active | -0.034 | 2.855 | 0.189 | 70.00 |
| copy_filled | 10% | 1 | 0.1 | active | -0.035 | -4.307 | 0.189 | 33.75 |
| advice | 10% | independent | 0.1 | active | -0.000 | -6.605 | 0.000 | 43.62 |
| advice | 40% | 1 | 0.1 | active | -0.024 | 11.392 | 0.279 | 70.00 |
| copy_filled | 40% | 1 | 0.1 | active | -0.035 | -3.352 | 0.378 | 33.75 |
| advice | 40% | independent | 0.1 | active | -0.009 | -4.801 | 0.036 | 47.72 |
| advice | 10% | 1 | Inf | held | -0.828 | -3.209 | 0.756 | 70.00 |
| copy_filled | 10% | 1 | Inf | held | 1.022 | -2.213 | 0.054 | 60.00 |
| advice | 10% | independent | Inf | held | -0.940 | -3.666 | 0.294 | 43.62 |
| advice | 40% | 1 | Inf | held | -4.057 | 15.852 | 9.685 | 70.00 |
| copy_filled | 40% | 1 | Inf | held | -5.671 | 10.852 | 8.056 | 57.50 |
| advice | 40% | independent | Inf | held | -3.775 | -6.392 | 0.054 | 47.72 |
| advice | 10% | 1 | Inf | active | 0.026 | 3.581 | 3.938 | 70.00 |
| copy_filled | 10% | 1 | Inf | active | 1.593 | -2.703 | -0.312 | 53.75 |
| advice | 10% | independent | Inf | active | 0.992 | -6.622 | -0.733 | 43.62 |
| advice | 40% | 1 | Inf | active | -2.273 | 15.511 | 8.210 | 70.00 |
| copy_filled | 40% | 1 | Inf | active | -7.651 | 18.949 | 14.807 | 43.75 |
| advice | 40% | independent | Inf | active | -2.941 | -4.830 | -0.303 | 47.72 |

Full estimates and 95% intervals: `Following-Smoke-Grouped.csv` and `Following-Smoke-Contrasts.csv`. Missing order denominators remain NaN. Zero-event probability samples use a conservative exact bound based on independent market clusters.

Pilot findings are exploratory. Confirmation uses fresh market seeds; no pilot rows are pooled into confirmation estimates.
