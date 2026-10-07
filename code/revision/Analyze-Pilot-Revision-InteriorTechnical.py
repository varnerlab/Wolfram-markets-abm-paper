"""Summarize the lazy-revision and interior-technical pilot.

Reads output/pilots/revision-interior-technical/Pilot-Summary.csv (and
Pilot-Summary-Extended.csv when present) written by
Pilot-Revision-InteriorTechnical.jl and writes Pilot-Grouped.csv and
Pilot-Midpoints.csv beside it.

Run: /opt/homebrew/bin/python3 code/revision/Analyze-Pilot-Revision-InteriorTechnical.py
"""

from pathlib import Path

import numpy as np
import pandas as pd

OUT = Path(__file__).resolve().parents[2] / "output" / "pilots" / "revision-interior-technical"
KEYS = ["experiment", "alpha", "rho", "boundary", "h"]


def first_crossing(fractions, probabilities, level=0.5):
    """Linear interpolation at the first upward crossing of `level`."""
    for i in range(1, len(fractions)):
        p0, p1 = probabilities[i - 1], probabilities[i]
        if p0 < level <= p1:
            return fractions[i - 1] + (level - p0) * (fractions[i] - fractions[i - 1]) / (p1 - p0)
    return np.nan


def main():
    d = pd.read_csv(OUT / "Pilot-Summary.csv")
    extended = OUT / "Pilot-Summary-Extended.csv"
    if extended.exists():
        # Shared starting markets and fraction 0.25 repeat; keep one copy.
        d = pd.concat([d, pd.read_csv(extended)]).drop_duplicates(
            subset=KEYS + ["seed", "f"], keep="first")
    d["paired_dd_increase"] = d.maximum_drawdown - d.control_maximum_drawdown
    grouped = (
        d.groupby(KEYS + ["f"])
        .agg(
            markets=("seed", "size"),
            majority_probability=("majority", "mean"),
            median_onset=("onset", lambda x: x[x > 0].median()),
            median_drawdown=("maximum_drawdown", "median"),
            median_paired_dd_increase=("paired_dd_increase", "median"),
            median_half_gap=("half_gap", "median"),
            max_half_gap=("half_gap", "max"),
            control_majorities=("control_onset", lambda x: int((x > 0).sum())),
            baseline_sell=("baseline_sell_mean", "mean"),
            technical_reach=("technical_reach", "first"),
        )
        .reset_index()
    )
    grouped.to_csv(OUT / "Pilot-Grouped.csv", index=False)

    rows = []
    for key, g in grouped.groupby(KEYS):
        g = g.sort_values("f")
        rows.append(dict(zip(KEYS, key),
                         f50=first_crossing(g.f.to_numpy(), g.majority_probability.to_numpy()),
                         technical_reach=g.technical_reach.iloc[0],
                         baseline_sell=g.baseline_sell.iloc[0],
                         control_majorities=int(g.control_majorities.sum()),
                         median_half_gap=g.median_half_gap.median()))
    midpoints = pd.DataFrame(rows)
    midpoints.to_csv(OUT / "Pilot-Midpoints.csv", index=False)

    pd.set_option("display.width", 200)
    for experiment in ("lazy", "interior"):
        print(f"\n== {experiment}: midpoints")
        print(midpoints[midpoints.experiment == experiment].to_string(index=False))
        print(f"\n== {experiment}: majority probability by fraction")
        table = grouped[grouped.experiment == experiment].pivot_table(
            index=["alpha", "rho", "boundary", "h"], columns="f", values="majority_probability")
        print(table.round(2).to_string())


if __name__ == "__main__":
    main()
