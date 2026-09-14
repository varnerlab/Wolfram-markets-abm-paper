# Following experiment: confirmation

Complete manifest: 33900 runs, including 300 shared no-following controls. There are 50 independent starting markets.

All treatment pairs have matching starting-state fingerprints. Per-run checks reconcile individual orders with aggregate execution and verify cash and share conservation.

The estimates below compare following with the same tagged traders in the paired no-following market. Returns and drawdowns are gross simulated outcomes. Intervals resample entire starting markets and are pointwise. Source agreement is imposed in the advice experiment; non-follower responses measure transmission beyond the followers.

| Mechanism | Followers | Sources | Capacity | Technical traders | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Source active (%) |
|---|---:|---:|---:|---|---:|---:|---:|---:|
| advice | 5% | 1 | 0.1 | held | 0.002 | -0.418 | 0.027 | 49.80 |
| copy_filled | 5% | 1 | 0.1 | held | 0.000 | -1.378 | 0.000 | 39.17 |
| advice | 5% | 16 | 0.1 | held | 0.000 | -1.938 | 0.000 | 49.98 |
| copy_filled | 5% | 16 | 0.1 | held | 0.000 | -2.062 | 0.000 | 41.33 |
| advice | 5% | independent | 0.1 | held | 0.000 | -1.998 | 0.000 | 50.01 |
| advice | 10% | 1 | 0.1 | held | -0.441 | 3.120 | 0.399 | 49.80 |
| copy_filled | 10% | 1 | 0.1 | held | 0.054 | -1.150 | 0.253 | 27.36 |
| advice | 10% | 16 | 0.1 | held | 0.000 | -3.729 | 0.000 | 49.98 |
| copy_filled | 10% | 16 | 0.1 | held | 0.000 | -4.270 | 0.000 | 36.46 |
| advice | 10% | independent | 0.1 | held | 0.000 | -3.963 | 0.000 | 50.00 |
| advice | 20% | 1 | 0.1 | held | -0.502 | 11.323 | 0.399 | 49.80 |
| copy_filled | 20% | 1 | 0.1 | held | 0.552 | 6.682 | 0.334 | 8.71 |
| advice | 20% | 16 | 0.1 | held | 0.000 | -6.912 | 0.007 | 49.98 |
| copy_filled | 20% | 16 | 0.1 | held | 0.000 | -9.300 | 0.000 | 23.68 |
| advice | 20% | independent | 0.1 | held | 0.000 | -7.667 | 0.000 | 50.00 |
| advice | 40% | 1 | 0.1 | held | 0.540 | 19.131 | 0.399 | 49.80 |
| copy_filled | 40% | 1 | 0.1 | held | 0.827 | 3.730 | 0.335 | 14.88 |
| advice | 40% | 16 | 0.1 | held | 0.084 | -10.969 | 0.399 | 49.98 |
| copy_filled | 40% | 16 | 0.1 | held | -0.000 | -19.447 | 0.001 | 0.40 |
| advice | 40% | independent | 0.1 | held | 0.000 | -13.020 | 0.000 | 50.00 |
| advice | 5% | 1 | 0.1 | active | 0.002 | -0.381 | 0.037 | 49.80 |
| copy_filled | 5% | 1 | 0.1 | active | 0.000 | -1.345 | 0.000 | 39.53 |
| advice | 5% | 16 | 0.1 | active | 0.000 | -1.936 | 0.000 | 49.98 |
| copy_filled | 5% | 16 | 0.1 | active | 0.000 | -2.073 | 0.000 | 41.58 |
| advice | 5% | independent | 0.1 | active | 0.000 | -2.005 | 0.000 | 50.01 |
| advice | 10% | 1 | 0.1 | active | -0.482 | 3.151 | 0.399 | 49.80 |
| copy_filled | 10% | 1 | 0.1 | active | 0.041 | -1.020 | 0.247 | 28.99 |
| advice | 10% | 16 | 0.1 | active | 0.000 | -3.713 | 0.000 | 49.98 |
| copy_filled | 10% | 16 | 0.1 | active | 0.000 | -4.271 | 0.000 | 36.90 |
| advice | 10% | independent | 0.1 | active | 0.000 | -3.958 | 0.000 | 50.00 |
| advice | 20% | 1 | 0.1 | active | -0.652 | 11.304 | 0.399 | 49.80 |
| copy_filled | 20% | 1 | 0.1 | active | 0.542 | 5.907 | 0.338 | 8.75 |
| advice | 20% | 16 | 0.1 | active | -0.000 | -6.891 | 0.011 | 49.98 |
| copy_filled | 20% | 16 | 0.1 | active | 0.000 | -9.260 | 0.000 | 24.54 |
| advice | 20% | independent | 0.1 | active | 0.000 | -7.656 | 0.000 | 50.00 |
| advice | 40% | 1 | 0.1 | active | 0.404 | 18.845 | 0.399 | 49.80 |
| copy_filled | 40% | 1 | 0.1 | active | 0.812 | 2.468 | 0.327 | 14.40 |
| advice | 40% | 16 | 0.1 | active | 0.061 | -11.022 | 0.399 | 49.98 |
| copy_filled | 40% | 16 | 0.1 | active | 0.000 | -19.547 | 0.003 | 0.49 |
| advice | 40% | independent | 0.1 | active | 0.000 | -12.964 | 0.000 | 50.00 |
| advice | 5% | 1 | 1.0 | held | 0.031 | -0.418 | 0.190 | 49.80 |
| copy_filled | 5% | 1 | 1.0 | held | 0.000 | -1.348 | 0.000 | 40.67 |
| advice | 5% | 16 | 1.0 | held | 0.000 | -1.938 | 0.000 | 49.98 |
| copy_filled | 5% | 16 | 1.0 | held | 0.000 | -2.041 | 0.000 | 42.43 |
| advice | 5% | independent | 1.0 | held | 0.000 | -1.998 | 0.000 | 50.01 |
| advice | 10% | 1 | 1.0 | held | 5.739 | 3.120 | 3.907 | 49.80 |
| copy_filled | 10% | 1 | 1.0 | held | 0.270 | -0.724 | 1.231 | 27.36 |
| advice | 10% | 16 | 1.0 | held | 0.000 | -3.729 | 0.000 | 49.98 |
| copy_filled | 10% | 16 | 1.0 | held | 0.000 | -4.201 | 0.000 | 38.00 |
| advice | 10% | independent | 1.0 | held | 0.000 | -3.963 | 0.000 | 50.00 |
| advice | 20% | 1 | 1.0 | held | 7.627 | 11.323 | 3.914 | 49.80 |
| copy_filled | 20% | 1 | 1.0 | held | 0.940 | 8.347 | 2.977 | 7.55 |
| advice | 20% | 16 | 1.0 | held | 0.000 | -6.912 | 0.040 | 49.98 |
| copy_filled | 20% | 16 | 1.0 | held | 0.000 | -9.056 | 0.000 | 26.66 |
| advice | 20% | independent | 1.0 | held | 0.000 | -7.667 | 0.000 | 50.00 |
| advice | 40% | 1 | 1.0 | held | 10.226 | 19.131 | 3.909 | 49.80 |
| copy_filled | 40% | 1 | 1.0 | held | 4.843 | 7.116 | 2.768 | 15.26 |
| advice | 40% | 16 | 1.0 | held | 0.646 | -10.969 | 3.087 | 49.98 |
| copy_filled | 40% | 16 | 1.0 | held | 0.001 | -19.454 | 0.004 | 0.59 |
| advice | 40% | independent | 1.0 | held | 0.000 | -13.020 | 0.000 | 50.00 |
| advice | 5% | 1 | 1.0 | active | 0.033 | -0.401 | 0.186 | 49.80 |
| copy_filled | 5% | 1 | 1.0 | active | 0.000 | -1.339 | 0.000 | 40.03 |
| advice | 5% | 16 | 1.0 | active | 0.000 | -1.930 | 0.000 | 49.98 |
| copy_filled | 5% | 16 | 1.0 | active | 0.000 | -2.042 | 0.000 | 42.67 |
| advice | 5% | independent | 1.0 | active | 0.000 | -1.991 | 0.000 | 50.01 |
| advice | 10% | 1 | 1.0 | active | 5.385 | 3.191 | 3.898 | 49.80 |
| copy_filled | 10% | 1 | 1.0 | active | 0.209 | -0.557 | 1.007 | 29.09 |
| advice | 10% | 16 | 1.0 | active | 0.000 | -3.713 | 0.000 | 49.98 |
| copy_filled | 10% | 16 | 1.0 | active | 0.000 | -4.201 | 0.000 | 38.26 |
| advice | 10% | independent | 1.0 | active | 0.000 | -3.959 | 0.000 | 50.00 |
| advice | 20% | 1 | 1.0 | active | 6.455 | 11.404 | 3.914 | 49.80 |
| copy_filled | 20% | 1 | 1.0 | active | 1.034 | 9.002 | 3.145 | 8.52 |
| advice | 20% | 16 | 1.0 | active | -0.000 | -6.897 | 0.033 | 49.98 |
| copy_filled | 20% | 16 | 1.0 | active | 0.000 | -9.036 | 0.000 | 27.20 |
| advice | 20% | independent | 1.0 | active | 0.000 | -7.653 | 0.000 | 50.00 |
| advice | 40% | 1 | 1.0 | active | 9.084 | 18.877 | 3.910 | 49.80 |
| copy_filled | 40% | 1 | 1.0 | active | 4.293 | 8.367 | 2.808 | 14.05 |
| advice | 40% | 16 | 1.0 | active | 0.497 | -11.009 | 2.868 | 49.98 |
| copy_filled | 40% | 16 | 1.0 | active | 0.001 | -19.455 | 0.007 | 1.06 |
| advice | 40% | independent | 1.0 | active | 0.000 | -12.961 | 0.000 | 50.00 |
| advice | 5% | 1 | Inf | held | 16.463 | -0.418 | 7.171 | 49.80 |
| copy_filled | 5% | 1 | Inf | held | 5.733 | -1.394 | 2.755 | 44.81 |
| advice | 5% | 16 | Inf | held | 0.113 | -1.938 | 0.574 | 49.98 |
| copy_filled | 5% | 16 | Inf | held | 0.553 | -1.977 | 0.025 | 45.82 |
| advice | 5% | independent | Inf | held | -0.169 | -1.998 | 0.069 | 50.01 |
| advice | 10% | 1 | Inf | held | 49.976 | 3.120 | 17.741 | 49.80 |
| copy_filled | 10% | 1 | Inf | held | 7.084 | 0.072 | 8.496 | 29.12 |
| advice | 10% | 16 | Inf | held | 0.378 | -3.729 | 1.850 | 49.98 |
| copy_filled | 10% | 16 | Inf | held | 1.057 | -4.067 | 0.210 | 41.93 |
| advice | 10% | independent | Inf | held | -0.416 | -3.963 | 0.314 | 50.00 |
| advice | 20% | 1 | Inf | held | 65.053 | 11.323 | 25.423 | 49.80 |
| copy_filled | 20% | 1 | Inf | held | -2.506 | 6.895 | 11.817 | 7.42 |
| advice | 20% | 16 | Inf | held | 0.515 | -6.912 | 4.852 | 49.98 |
| copy_filled | 20% | 16 | Inf | held | 1.680 | -8.697 | 0.496 | 32.17 |
| advice | 20% | independent | Inf | held | -1.124 | -7.667 | 1.259 | 50.00 |
| advice | 40% | 1 | Inf | held | 50.422 | 19.131 | 30.227 | 49.80 |
| copy_filled | 40% | 1 | Inf | held | -1.529 | 4.686 | 11.609 | 9.77 |
| advice | 40% | 16 | Inf | held | -0.224 | -10.969 | 11.187 | 49.98 |
| copy_filled | 40% | 16 | Inf | held | 1.574 | -18.165 | 0.205 | 11.42 |
| advice | 40% | independent | Inf | held | -3.188 | -13.020 | 4.161 | 50.00 |
| advice | 5% | 1 | Inf | active | 13.535 | -0.410 | 7.251 | 49.80 |
| copy_filled | 5% | 1 | Inf | active | 4.308 | -1.409 | 2.799 | 44.83 |
| advice | 5% | 16 | Inf | active | -0.296 | -1.949 | 0.521 | 49.98 |
| copy_filled | 5% | 16 | Inf | active | 0.396 | -1.997 | -0.019 | 46.11 |
| advice | 5% | independent | Inf | active | -0.156 | -1.999 | 0.066 | 50.01 |
| advice | 10% | 1 | Inf | active | 47.172 | 3.126 | 17.689 | 49.80 |
| copy_filled | 10% | 1 | Inf | active | 6.218 | 0.228 | 8.490 | 27.94 |
| advice | 10% | 16 | Inf | active | -0.255 | -3.742 | 1.847 | 49.98 |
| copy_filled | 10% | 16 | Inf | active | 0.856 | -4.102 | 0.182 | 42.13 |
| advice | 10% | independent | Inf | active | -0.357 | -3.974 | 0.414 | 50.00 |
| advice | 20% | 1 | Inf | active | 60.393 | 11.349 | 24.881 | 49.80 |
| copy_filled | 20% | 1 | Inf | active | -2.373 | 8.833 | 12.925 | 5.70 |
| advice | 20% | 16 | Inf | active | -0.211 | -6.949 | 4.874 | 49.98 |
| copy_filled | 20% | 16 | Inf | active | 1.471 | -8.752 | 0.449 | 32.30 |
| advice | 20% | independent | Inf | active | -1.025 | -7.693 | 1.365 | 50.00 |
| advice | 40% | 1 | Inf | active | 42.594 | 18.923 | 28.900 | 49.80 |
| copy_filled | 40% | 1 | Inf | active | -1.832 | 3.574 | 12.242 | 8.87 |
| advice | 40% | 16 | Inf | active | -1.077 | -11.058 | 11.180 | 49.98 |
| copy_filled | 40% | 16 | Inf | active | 1.553 | -18.203 | 0.354 | 11.88 |
| advice | 40% | independent | Inf | active | -3.046 | -13.086 | 4.254 | 50.00 |

Full estimates and 95% intervals: `Following-Confirmation-Grouped.csv` and `Following-Confirmation-Contrasts.csv`. Missing order denominators remain NaN. Zero-event probability samples use a conservative exact bound based on independent market clusters.

Pilot findings are exploratory. Confirmation uses fresh market seeds; no pilot rows are pooled into confirmation estimates.
