# Following experiment: pilot

Complete manifest: 3420 runs, including 60 shared no-following controls. There are 10 independent starting markets.

All treatment pairs have matching starting-state fingerprints. Per-run checks reconcile individual orders with aggregate execution and verify cash and share conservation.

The estimates below compare following with the same tagged traders in the paired no-following market. Returns and drawdowns are gross simulated outcomes. Intervals resample entire starting markets and are pointwise. Source agreement is imposed in the advice experiment; non-follower responses measure transmission beyond the followers.

| Mechanism | Followers | Sources | Capacity | Technical traders | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Source active (%) |
|---|---:|---:|---:|---|---:|---:|---:|---:|
| advice | 5% | 1 | 0.1 | held | 0.000 | -0.437 | 0.015 | 50.18 |
| copy_filled | 5% | 1 | 0.1 | held | 0.000 | -1.279 | 0.000 | 42.27 |
| advice | 5% | 16 | 0.1 | held | 0.000 | -1.960 | 0.000 | 50.08 |
| copy_filled | 5% | 16 | 0.1 | held | 0.000 | -2.083 | 0.000 | 41.68 |
| advice | 5% | independent | 0.1 | held | 0.000 | -2.027 | 0.000 | 49.93 |
| advice | 10% | 1 | 0.1 | held | -0.462 | 3.175 | 0.399 | 50.18 |
| copy_filled | 10% | 1 | 0.1 | held | -0.007 | -0.322 | 0.315 | 27.70 |
| advice | 10% | 16 | 0.1 | held | 0.000 | -3.713 | 0.000 | 50.08 |
| copy_filled | 10% | 16 | 0.1 | held | 0.000 | -4.244 | 0.000 | 37.10 |
| advice | 10% | independent | 0.1 | held | 0.000 | -3.987 | 0.000 | 50.00 |
| advice | 20% | 1 | 0.1 | held | -0.480 | 11.226 | 0.399 | 50.18 |
| copy_filled | 20% | 1 | 0.1 | held | 0.718 | 9.959 | 0.360 | 13.51 |
| advice | 20% | 16 | 0.1 | held | -0.000 | -6.931 | 0.001 | 50.08 |
| copy_filled | 20% | 16 | 0.1 | held | 0.000 | -9.145 | 0.000 | 25.55 |
| advice | 20% | independent | 0.1 | held | 0.000 | -7.689 | 0.000 | 50.00 |
| advice | 40% | 1 | 0.1 | held | 0.554 | 18.962 | 0.399 | 50.18 |
| copy_filled | 40% | 1 | 0.1 | held | 1.146 | 5.582 | 0.343 | 18.52 |
| advice | 40% | 16 | 0.1 | held | 0.085 | -10.915 | 0.399 | 50.08 |
| copy_filled | 40% | 16 | 0.1 | held | 0.000 | -19.386 | 0.001 | 0.42 |
| advice | 40% | independent | 0.1 | held | 0.000 | -13.060 | 0.000 | 50.00 |
| advice | 5% | 1 | 0.1 | active | 0.002 | -0.384 | 0.026 | 50.18 |
| copy_filled | 5% | 1 | 0.1 | active | 0.000 | -1.343 | 0.000 | 41.61 |
| advice | 5% | 16 | 0.1 | active | 0.000 | -1.983 | 0.000 | 50.08 |
| copy_filled | 5% | 16 | 0.1 | active | 0.000 | -2.134 | 0.000 | 41.79 |
| advice | 5% | independent | 0.1 | active | 0.000 | -2.056 | 0.000 | 49.93 |
| advice | 10% | 1 | 0.1 | active | -0.436 | 3.106 | 0.399 | 50.18 |
| copy_filled | 10% | 1 | 0.1 | active | 0.029 | -0.514 | 0.254 | 30.14 |
| advice | 10% | 16 | 0.1 | active | 0.000 | -3.723 | 0.000 | 50.08 |
| copy_filled | 10% | 16 | 0.1 | active | 0.000 | -4.260 | 0.000 | 37.47 |
| advice | 10% | independent | 0.1 | active | 0.000 | -3.994 | 0.000 | 50.00 |
| advice | 20% | 1 | 0.1 | active | -0.625 | 11.270 | 0.399 | 50.18 |
| copy_filled | 20% | 1 | 0.1 | active | 0.617 | 8.247 | 0.365 | 11.43 |
| advice | 20% | 16 | 0.1 | active | 0.000 | -6.924 | 0.001 | 50.08 |
| copy_filled | 20% | 16 | 0.1 | active | 0.000 | -9.154 | 0.000 | 26.25 |
| advice | 20% | independent | 0.1 | active | 0.000 | -7.710 | 0.000 | 50.00 |
| advice | 40% | 1 | 0.1 | active | 0.423 | 18.688 | 0.399 | 50.18 |
| copy_filled | 40% | 1 | 0.1 | active | 0.536 | 8.479 | 0.364 | 10.76 |
| advice | 40% | 16 | 0.1 | active | 0.061 | -10.995 | 0.398 | 50.08 |
| copy_filled | 40% | 16 | 0.1 | active | 0.000 | -19.494 | 0.002 | 0.45 |
| advice | 40% | independent | 0.1 | active | 0.000 | -13.041 | 0.000 | 50.00 |
| advice | 5% | 1 | 1.0 | held | 0.008 | -0.437 | 0.141 | 50.18 |
| copy_filled | 5% | 1 | 1.0 | held | 0.000 | -1.284 | 0.000 | 43.26 |
| advice | 5% | 16 | 1.0 | held | 0.000 | -1.960 | 0.000 | 50.08 |
| copy_filled | 5% | 16 | 1.0 | held | 0.000 | -2.072 | 0.000 | 42.49 |
| advice | 5% | independent | 1.0 | held | 0.000 | -2.027 | 0.000 | 49.93 |
| advice | 10% | 1 | 1.0 | held | 5.901 | 3.175 | 3.877 | 50.18 |
| copy_filled | 10% | 1 | 1.0 | held | 0.064 | -0.456 | 1.438 | 26.90 |
| advice | 10% | 16 | 1.0 | held | 0.000 | -3.713 | 0.000 | 50.08 |
| copy_filled | 10% | 16 | 1.0 | held | 0.000 | -4.169 | 0.000 | 38.64 |
| advice | 10% | independent | 1.0 | held | 0.000 | -3.987 | 0.000 | 50.00 |
| advice | 20% | 1 | 1.0 | held | 8.049 | 11.226 | 3.910 | 50.18 |
| copy_filled | 20% | 1 | 1.0 | held | 1.215 | 9.814 | 2.971 | 5.75 |
| advice | 20% | 16 | 1.0 | held | 0.000 | -6.931 | 0.010 | 50.08 |
| copy_filled | 20% | 16 | 1.0 | held | 0.000 | -8.904 | 0.000 | 28.59 |
| advice | 20% | independent | 1.0 | held | 0.000 | -7.689 | 0.000 | 50.00 |
| advice | 40% | 1 | 1.0 | held | 10.678 | 18.962 | 3.909 | 50.18 |
| copy_filled | 40% | 1 | 1.0 | held | 4.534 | 9.207 | 2.866 | 13.87 |
| advice | 40% | 16 | 1.0 | held | 0.648 | -10.915 | 3.020 | 50.08 |
| copy_filled | 40% | 16 | 1.0 | held | 0.000 | -19.415 | 0.002 | 0.50 |
| advice | 40% | independent | 1.0 | held | 0.000 | -13.060 | 0.000 | 50.00 |
| advice | 5% | 1 | 1.0 | active | 0.001 | -0.411 | 0.073 | 50.18 |
| copy_filled | 5% | 1 | 1.0 | active | 0.000 | -1.288 | 0.000 | 44.07 |
| advice | 5% | 16 | 1.0 | active | 0.000 | -1.975 | 0.000 | 50.08 |
| copy_filled | 5% | 16 | 1.0 | active | 0.000 | -2.078 | 0.000 | 42.93 |
| advice | 5% | independent | 1.0 | active | 0.000 | -2.044 | 0.000 | 49.93 |
| advice | 10% | 1 | 1.0 | active | 5.510 | 3.073 | 3.904 | 50.18 |
| copy_filled | 10% | 1 | 1.0 | active | 0.159 | -0.953 | 1.106 | 28.95 |
| advice | 10% | 16 | 1.0 | active | 0.000 | -3.738 | 0.000 | 50.08 |
| copy_filled | 10% | 16 | 1.0 | active | 0.000 | -4.188 | 0.000 | 39.07 |
| advice | 10% | independent | 1.0 | active | 0.000 | -3.994 | 0.000 | 50.00 |
| advice | 20% | 1 | 1.0 | active | 6.869 | 11.173 | 3.912 | 50.18 |
| copy_filled | 20% | 1 | 1.0 | active | 1.191 | 7.093 | 3.079 | 9.20 |
| advice | 20% | 16 | 1.0 | active | -0.000 | -6.926 | 0.008 | 50.08 |
| copy_filled | 20% | 16 | 1.0 | active | 0.000 | -8.882 | 0.000 | 29.24 |
| advice | 20% | independent | 1.0 | active | 0.000 | -7.688 | 0.000 | 50.00 |
| advice | 40% | 1 | 1.0 | active | 9.561 | 18.718 | 3.909 | 50.18 |
| copy_filled | 40% | 1 | 1.0 | active | 2.752 | 5.696 | 2.546 | 9.83 |
| advice | 40% | 16 | 1.0 | active | 0.505 | -10.975 | 2.885 | 50.08 |
| copy_filled | 40% | 16 | 1.0 | active | 0.000 | -19.379 | 0.011 | 1.36 |
| advice | 40% | independent | 1.0 | active | 0.000 | -13.035 | 0.000 | 50.00 |
| advice | 5% | 1 | Inf | held | 17.130 | -0.437 | 6.834 | 50.18 |
| copy_filled | 5% | 1 | Inf | held | 6.468 | -1.380 | 2.881 | 45.65 |
| advice | 5% | 16 | Inf | held | 0.269 | -1.960 | 0.556 | 50.08 |
| copy_filled | 5% | 16 | Inf | held | 0.678 | -1.993 | 0.044 | 46.33 |
| advice | 5% | independent | Inf | held | -0.014 | -2.027 | 0.028 | 49.93 |
| advice | 10% | 1 | Inf | held | 51.425 | 3.175 | 17.102 | 50.18 |
| copy_filled | 10% | 1 | Inf | held | 8.359 | -0.228 | 8.811 | 27.81 |
| advice | 10% | 16 | Inf | held | 0.624 | -3.713 | 1.791 | 50.08 |
| copy_filled | 10% | 16 | Inf | held | 1.245 | -4.033 | 0.139 | 43.02 |
| advice | 10% | independent | Inf | held | -0.271 | -3.987 | 0.308 | 50.00 |
| advice | 20% | 1 | Inf | held | 66.472 | 11.226 | 25.418 | 50.18 |
| copy_filled | 20% | 1 | Inf | held | -0.295 | 5.593 | 11.284 | 10.10 |
| advice | 20% | 16 | Inf | held | 0.844 | -6.931 | 4.632 | 50.08 |
| copy_filled | 20% | 16 | Inf | held | 1.881 | -8.502 | 0.532 | 34.57 |
| advice | 20% | independent | Inf | held | -0.976 | -7.689 | 1.285 | 50.00 |
| advice | 40% | 1 | Inf | held | 52.508 | 18.962 | 30.462 | 50.18 |
| copy_filled | 40% | 1 | Inf | held | -0.321 | 4.464 | 12.503 | 13.86 |
| advice | 40% | 16 | Inf | held | 0.235 | -10.915 | 10.884 | 50.08 |
| copy_filled | 40% | 16 | Inf | held | 1.689 | -18.088 | -0.059 | 12.41 |
| advice | 40% | independent | Inf | held | -3.084 | -13.060 | 4.150 | 50.00 |
| advice | 5% | 1 | Inf | active | 13.934 | -0.423 | 6.834 | 50.18 |
| copy_filled | 5% | 1 | Inf | active | 5.007 | -1.367 | 2.913 | 47.83 |
| advice | 5% | 16 | Inf | active | -0.222 | -1.966 | 0.508 | 50.08 |
| copy_filled | 5% | 16 | Inf | active | 0.399 | -2.014 | 0.036 | 46.47 |
| advice | 5% | independent | Inf | active | -0.153 | -2.029 | 0.053 | 49.93 |
| advice | 10% | 1 | Inf | active | 47.268 | 3.027 | 17.216 | 50.18 |
| copy_filled | 10% | 1 | Inf | active | 7.135 | -0.022 | 9.722 | 28.42 |
| advice | 10% | 16 | Inf | active | -0.285 | -3.725 | 1.785 | 50.08 |
| copy_filled | 10% | 16 | Inf | active | 0.791 | -4.057 | 0.195 | 43.08 |
| advice | 10% | independent | Inf | active | -0.378 | -3.995 | 0.429 | 50.00 |
| advice | 20% | 1 | Inf | active | 60.261 | 11.258 | 24.840 | 50.18 |
| copy_filled | 20% | 1 | Inf | active | -0.294 | 2.650 | 10.375 | 5.39 |
| advice | 20% | 16 | Inf | active | -0.128 | -6.954 | 4.714 | 50.08 |
| copy_filled | 20% | 16 | Inf | active | 1.538 | -8.543 | 0.533 | 34.84 |
| advice | 20% | independent | Inf | active | -1.021 | -7.718 | 1.380 | 50.00 |
| advice | 40% | 1 | Inf | active | 43.900 | 18.746 | 29.095 | 50.18 |
| copy_filled | 40% | 1 | Inf | active | -2.318 | 8.997 | 15.614 | 11.84 |
| advice | 40% | 16 | Inf | active | -0.841 | -11.026 | 10.918 | 50.08 |
| copy_filled | 40% | 16 | Inf | active | 1.444 | -18.163 | 0.385 | 12.13 |
| advice | 40% | independent | Inf | active | -3.046 | -13.122 | 4.316 | 50.00 |

Full estimates and 95% intervals: `Following-Pilot-Grouped.csv` and `Following-Pilot-Contrasts.csv`. Missing order denominators remain NaN. Zero-event probability samples use a conservative exact bound based on independent market clusters.

Pilot findings are exploratory. Confirmation uses fresh market seeds; no pilot rows are pooled into confirmation estimates.
