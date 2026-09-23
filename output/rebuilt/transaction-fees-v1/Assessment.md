# Transaction-fee sensitivity

Completed 8,400 full financial simulations.

Fees were 0, 5, 10, or 25 basis points per completed order, from initialization.
Dealer fee income was excluded from trading reserves. Each condition used 50 seeds,
a 64-by-64 grid, 1,000 baseline steps, and 3,000 steps after the rule change.

All within-condition common histories matched. With technical traders held,
Sell fractions at every step and final grids were identical across all fee rates and all three reserve depths.

Selected numerical summaries below use f=0.20. The complete CSV files cover all fractions.

| Dealer shares/trader | Technical traders | Fee (bp) | Sell majority | Median drawdown | Median cumulative fees / initial trader cash |
|---|---|---:|---:|---:|---:|
| 0.1 | active | 0 | 50/50 | 99.99% | 0.000% |
| 0.1 | held | 0 | 50/50 | 99.99% | 0.000% |
| 1 | active | 0 | 50/50 | 99.52% | 0.000% |
| 1 | held | 0 | 50/50 | 99.53% | 0.000% |
| 100 | active | 0 | 50/50 | 25.15% | 0.000% |
| 100 | held | 0 | 50/50 | 24.66% | 0.000% |
| 0.1 | active | 5 | 50/50 | 99.99% | 13.482% |
| 0.1 | held | 5 | 50/50 | 99.99% | 14.188% |
| 1 | active | 5 | 50/50 | 99.50% | 12.192% |
| 1 | held | 5 | 50/50 | 99.49% | 13.011% |
| 100 | active | 5 | 50/50 | 24.94% | 7.293% |
| 100 | held | 5 | 50/50 | 24.27% | 7.118% |
| 0.1 | active | 10 | 50/50 | 99.98% | 25.728% |
| 0.1 | held | 10 | 50/50 | 99.99% | 26.251% |
| 1 | active | 10 | 49/50 | 99.48% | 23.834% |
| 1 | held | 10 | 50/50 | 99.45% | 24.315% |
| 100 | active | 10 | 50/50 | 24.51% | 14.455% |
| 100 | held | 10 | 50/50 | 23.80% | 14.155% |
| 0.1 | active | 25 | 50/50 | 99.98% | 52.897% |
| 0.1 | held | 25 | 50/50 | 99.98% | 52.852% |
| 1 | active | 25 | 50/50 | 99.40% | 49.261% |
| 1 | held | 25 | 50/50 | 99.32% | 50.296% |
| 100 | active | 25 | 50/50 | 23.67% | 36.191% |
| 100 | held | 25 | 50/50 | 23.21% | 34.906% |

Probability intervals are Wilson 95% intervals. Continuous summaries include quartiles.
Paired differences use 2,000 seed bootstrap samples and percentile 95% intervals.
These fee rates are illustrative sensitivity parameters, not an exchange calibration.
The study does not rerun every market size, resource intervention, or following experiment.
