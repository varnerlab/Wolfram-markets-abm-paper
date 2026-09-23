"""Check the complete frozen fee experiment and write summaries and figures."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/wolfram-fee-matplotlib")
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def wilson(k, n):
    z = 1.959963984540054
    p = k / n
    den = 1 + z*z/n
    center = (p + z*z/(2*n)) / den
    half = z * math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / den
    return center-half, center+half


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("study", type=Path)
    args = parser.parse_args()
    study = args.study.resolve()
    protocol = json.loads((study / "Protocol.json").read_text())
    for name, expected in protocol["frozen_files"].items():
        assert hashlib.sha256((study / name).read_bytes()).hexdigest() == expected, name
    manifest = pd.read_csv(study / "Manifest.csv")
    runs = pd.read_csv(study / "Run-Summary.csv")
    keys = ["group", "role", "fee_bps", "h", "boundary", "seed", "f", "L", "pre", "post"]
    assert len(runs) == protocol["full_financial_simulations"] == len(manifest)
    assert not runs.duplicated(keys).any()
    pd.testing.assert_frame_equal(
        manifest[keys].sort_values(keys).reset_index(drop=True),
        runs[keys].sort_values(keys).reset_index(drop=True), check_dtype=False)
    assert runs["majority"].isin([True, False]).all()
    assert np.isfinite(runs.select_dtypes("number")).all().all()
    assert (runs.final_fee_revenue >= 0).all()
    zero = runs[runs.fee_bps == 0]
    assert (zero.final_fee_revenue == 0).all()
    assert (runs.final_trader_cash >= -1e-8).all()
    final_cash = runs.final_trader_cash + runs.final_trading_reserve_cash + runs.final_fee_revenue
    initial_cash = runs.initial_trader_cash + runs.initial_trading_reserve_cash
    assert np.all(np.abs(final_cash-initial_cash) < np.maximum(1e-5, initial_cash*1e-11))
    for _, group in runs.groupby("group"):
        assert group.prehistory_sha256.nunique() == 1
        assert group.activation_grid_sha256.nunique() == 1
    held = runs[runs.boundary == "hold"]
    for _, group in held.groupby(["role", "seed", "f"]):
        assert group.sell_history_sha256.nunique() == 1
        assert group.final_grid_sha256.nunique() == 1
    for _, group in runs.groupby(["seed"]):
        assert group.initial_grid_sha256.nunique() == 1

    dimensions = ["fee_bps", "h", "boundary", "role", "f"]
    rows = []
    for values, group in runs.groupby(dimensions, sort=True):
        n = len(group); k = int(group.majority.sum()); lo, hi = wilson(k, n)
        row = dict(zip(dimensions, values))
        row.update(n=n, majority_count=k, majority_probability=k/n,
            majority_lo=lo, majority_hi=hi)
        for column in ["max_drawdown", "final_sell", "final_price", "post_completed_orders",
                       "final_fee_revenue", "post_fee_revenue", "final_trader_cash"]:
            q1, med, q3 = np.quantile(group[column], [0.25, 0.5, 0.75])
            row.update({column+"_median": med, column+"_q1": q1, column+"_q3": q3})
        fractions = group.final_fee_revenue/group.initial_trader_cash
        row["fee_fraction_initial_trader_cash_median"] = fractions.median()
        suppression = group.post_suppressed_buys / group.post_desired_buys.replace(0, np.nan)
        row["buy_suppression_fraction_median"] = suppression.median()
        rows.append(row)
    summary = pd.DataFrame(rows)
    summary.to_csv(study / "Condition-Summary.csv", index=False)

    rng = np.random.default_rng(20260918)
    effects = []
    treated = runs[runs.role == "treated"]
    for values, group in treated.groupby(["fee_bps", "h", "boundary", "f"], sort=True):
        fee, h, boundary, fraction = values
        group = group.sort_values("seed")
        controls = runs[(runs.role == "control") & (runs.fee_bps == fee)
            & (runs.h == h) & (runs.boundary == boundary)].sort_values("seed")
        reference = treated[(treated.fee_bps == 0) & (treated.h == h)
            & (treated.boundary == boundary) & (treated.f == fraction)].sort_values("seed")
        for label, other in [("rule_change", controls), ("fee_vs_zero", reference)]:
            assert np.array_equal(group.seed, other.seed)
            indices = rng.integers(0, len(group), (2000, len(group)))
            row = dict(comparison=label, fee_bps=fee, h=h, boundary=boundary, f=fraction, n=len(group))
            for column, function in [("majority", np.mean), ("max_drawdown", np.median),
                                     ("post_completed_orders", np.median),
                                     ("final_trader_cash", np.median), ("final_fee_revenue", np.median)]:
                delta = group[column].to_numpy(dtype=float)-other[column].to_numpy(dtype=float)
                distribution = function(delta[indices], axis=1)
                low, high = np.quantile(distribution, [0.025, 0.975])
                row.update({column+"_difference": function(delta),
                    column+"_difference_lo": low, column+"_difference_hi": high})
            effects.append(row)
    pd.DataFrame(effects).to_csv(study / "Paired-Effects.csv", index=False)

    depths = protocol["reserves_per_trader"]
    fig, axes = plt.subplots(2, len(depths), figsize=(12, 6.4), sharex=True)
    palette = {0: "#252525", 5: "#0072B2", 10: "#009E73", 25: "#D55E00"}
    for col, depth in enumerate(depths):
        for fee in protocol["fee_bps"]:
            selected = summary[(summary.role == "treated") & (summary.h == depth)
                & (summary.boundary == "endogenous") & (summary.fee_bps == fee)].sort_values("f")
            axes[0,col].plot(selected.f, selected.majority_probability, "o-", color=palette[fee], label=f"{fee} bp")
            axes[1,col].plot(selected.f, 100*selected.max_drawdown_median, "o-", color=palette[fee])
        axes[0,col].set_title(f"Dealer shares per trader: {depth:g}")
        axes[0,col].set_ylim(-0.04, 1.04)
        axes[1,col].set_ylim(-2, 102)
        axes[1,col].set_xlabel("Fraction assigned the new rule")
    axes[0,0].set_ylabel("Sell-majority probability")
    axes[1,0].set_ylabel("Median maximum drawdown (%)")
    axes[0,-1].legend(title="Fee per completed order", frameon=False, fontsize=8)
    for ax in axes.flat:
        ax.spines[["top", "right"]].set_visible(False)
        ax.grid(axis="y", alpha=0.2)
    fig.suptitle("Transaction fees with technical traders active", fontsize=12)
    fig.tight_layout()
    fig.savefig(study / "figures/Fee-Sensitivity.pdf")
    fig.savefig(study / "figures/Fee-Sensitivity.png", dpi=180)
    plt.close(fig)

    validation = dict(complete=True, simulations=len(runs), groups=runs.group.nunique(),
        manifest_matches=True, frozen_sources_match=True, pairing_verified=True,
        held_sell_fraction_histories_and_final_grids_identical=True,
        max_cash_conservation_error=float(runs.max_cash_conservation_error.max()),
        all_zero_fee_revenues_zero=True,
        summary_sha256=hashlib.sha256((study / "Run-Summary.csv").read_bytes()).hexdigest())
    (study / "Validation.json").write_text(json.dumps(validation, indent=2) + "\n")
    lines = ["# Transaction-fee sensitivity", "", f"Completed {len(runs):,} full financial simulations.", "",
        "Fees were 0, 5, 10, or 25 basis points per completed order, from initialization.",
        "Dealer fee income was excluded from trading reserves. Each condition used 50 seeds,",
        "a 64-by-64 grid, 1,000 baseline steps, and 3,000 steps after the rule change.", "",
        "All within-condition common histories matched. With technical traders held,",
        "Sell fractions at every step and final grids were identical across all fee rates and all three reserve depths.", "",
        "Selected numerical summaries below use f=0.20. The complete CSV files cover all fractions.", "",
        "| Dealer shares/trader | Technical traders | Fee (bp) | Sell majority | Median drawdown | Median cumulative fees / initial trader cash |",
        "|---|---|---:|---:|---:|---:|"]
    for row in summary[(summary.role == "treated") & (summary.f == 0.2)].itertuples():
        lines.append(f"| {row.h:g} | {'held' if row.boundary=='hold' else 'active'} | {row.fee_bps} | "
            f"{row.majority_count}/{row.n} | {100*row.max_drawdown_median:.2f}% | "
            f"{100*row.fee_fraction_initial_trader_cash_median:.3f}% |")
    lines += ["", "Probability intervals are Wilson 95% intervals. Continuous summaries include quartiles.",
        "Paired differences use 2,000 seed bootstrap samples and percentile 95% intervals.",
        "These fee rates are illustrative sensitivity parameters, not an exchange calibration.",
        "The study does not rerun every market size, resource intervention, or following experiment."]
    (study / "Assessment.md").write_text("\n".join(lines) + "\n")
    print(json.dumps(validation, indent=2))


if __name__ == "__main__":
    main()
