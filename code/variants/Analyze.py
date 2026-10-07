"""Validate the completed lazy-revision and interior-technical study and summarize it.

Writes Condition-Summary.csv, Midpoints.csv, Contrasts.csv, Validation.json, and
Assessment.md in the study directory.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
import pandas as pd

BOOTSTRAPS = 2000
BOOTSTRAP_SEED = 20261002
KEYS = ["group", "role", "condition", "alpha", "rho", "h", "boundary", "seed", "f", "L", "pre", "post"]


def wilson(k, n):
    z = 1.959963984540054
    p = k / n
    den = 1 + z * z / n
    center = (p + z * z / (2 * n)) / den
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return center - half, center + half


def crossing(fractions, probabilities, level):
    """Linear interpolation at the first upward crossing of `level`."""
    for i in range(1, len(fractions)):
        p0, p1 = probabilities[i - 1], probabilities[i]
        if p0 < level <= p1:
            return fractions[i - 1] + (level - p0) * (fractions[i] - fractions[i - 1]) / (p1 - p0)
    return np.nan


def midpoints(fractions, probabilities):
    f25, f50, f75 = (crossing(fractions, probabilities, q) for q in (0.25, 0.5, 0.75))
    return f25, f50, f75, f75 - f25


def normalized(frame):
    frame = frame[KEYS].copy()
    for column in ("alpha", "rho", "h", "f"):
        frame[column] = frame[column].astype(float).round(10)
    return frame.sort_values(KEYS).reset_index(drop=True)


def validate(study, protocol, manifest, runs):
    checks = {}
    assert len(runs) == len(manifest) == protocol["full_financial_simulations"]
    assert not runs.duplicated(KEYS).any()
    pd.testing.assert_frame_equal(normalized(manifest), normalized(runs), check_dtype=False)
    checks["manifest_complete"] = True
    for column in ("prehistory_sha256", "activation_grid_sha256", "initial_grid_sha256"):
        assert (runs.groupby("group")[column].nunique() == 1).all(), column
    checks["common_history_within_groups"] = True
    checks["max_cash_conservation_error"] = float(runs.max_cash_conservation_error.max())

    ledger = pd.read_csv(protocol["reference_ledger"])
    ledger = ledger[(ledger.L == 64) & (ledger.steps == 4000) & (ledger.action == "rule")
                    & (ledger.fixed_band == "nothing") & (~ledger.resource_intervention)
                    & (ledger.rule == 19286)]
    ledger = ledger.assign(f=ledger.f.round(4))
    base = runs[(runs.alpha == 1.0) & (runs.rho == 0.0) & (runs.L == 64)
                & (runs.pre == 1000) & (runs.post == 3000)]
    compared = equal = 0
    for row in base.itertuples():
        activation = row.pre + row.post + 1 if row.role == "control" else row.pre + 1
        match = ledger[(ledger.seed == row.seed) & (ledger.h == row.h)
                       & (ledger.boundary == row.boundary) & (ledger.activation_step == activation)]
        if row.role == "treated":
            match = match[match.f == round(row.f, 4)]
        hashes = set(match.final_grid_sha256)
        if not hashes:
            continue
        assert len(hashes) == 1, (row.group, row.f)
        compared += 1
        equal += row.final_grid_sha256 in hashes
    checks["archived_runs_compared"] = compared
    checks["archived_runs_reproduced"] = equal
    smoke = protocol["version"].endswith("-smoke")
    if not smoke:
        assert compared > 0 and equal == compared, (compared, equal)
    return checks


def summarize_conditions(runs):
    treated = runs[runs.role == "treated"]
    controls = runs[runs.role == "control"].set_index("group")
    rows = []
    for (condition, f), g in treated.groupby(["condition", "f"]):
        k, n = int(g.majority.sum()), len(g)
        low, high = wilson(k, n)
        control = controls.loc[g.group]
        increase = g.max_drawdown.to_numpy() - control.max_drawdown.to_numpy()
        majority = g[g.majority]
        sells = g.post_desired_sells.sum()
        rows.append(dict(
            condition=condition, experiment=g.experiment.iat[0], L=g.L.iat[0],
            alpha=g.alpha.iat[0], rho_label=g.rho_label.iat[0], boundary=g.boundary.iat[0],
            h=g.h.iat[0], f=f, markets=n, majorities=k, majority_probability=k / n,
            wilson_low=low, wilson_high=high,
            median_onset=majority.onset.median() if len(majority) else np.nan,
            median_drawdown=g.max_drawdown.median(),
            median_control_drawdown=control.max_drawdown.median(),
            median_paired_drawdown_increase=float(np.median(increase)),
            control_majorities=int(control.majority.sum()),
            median_final_dealer_inventory_per_trader=g.final_dealer_inventory_per_trader.median(),
            sell_suppression_fraction=g.post_suppressed_sells.sum() / sells if sells else np.nan,
            median_half_gap_late=g.half_gap_late_mean.median(),
            max_half_gap_late=g.half_gap_late_mean.max(),
            mean_interior_technical_buy=g.interior_technical_buy_post.mean(),
            mean_interior_technical_sell=g.interior_technical_sell_post.mean(),
            technical_reach=g.technical_reach.iat[0],
            baseline_sell=g.baseline_sell_mean.mean()))
    return pd.DataFrame(rows).sort_values(["condition", "f"]).reset_index(drop=True)


def bootstrap_midpoints(runs, seeds, resamples):
    """Point and bootstrap f25/f50/f75/width per condition, with shared resamples."""
    treated = runs[runs.role == "treated"]
    point, draws = {}, {}
    for condition, g in treated.groupby("condition"):
        table = g.pivot_table(index="f", columns="seed", values="majority", aggfunc="first")
        table = table.reindex(columns=seeds).astype(float)
        assert not table.isna().any().any(), condition
        fractions = table.index.to_numpy()
        matrix = table.to_numpy()
        probabilities = matrix.mean(axis=1)
        point[condition] = dict(
            zip(("f25", "f50", "f75", "width"), midpoints(fractions, probabilities)),
            interior_fractions=int(((probabilities > 0.05) & (probabilities < 0.95)).sum()),
            tested_fractions=len(fractions))
        resampled = matrix[:, resamples].mean(axis=2)
        draws[condition] = np.array([midpoints(fractions, resampled[:, b])
                                     for b in range(resampled.shape[1])])
    return point, draws


def interval(values):
    finite = values[np.isfinite(values)]
    if len(finite) == 0:
        return np.nan, np.nan, 0.0
    low, high = np.percentile(finite, [2.5, 97.5])
    return low, high, len(finite) / len(values)


def planned_contrasts(conditions):
    """(label, condition A, condition B): f50 of A minus f50 of B."""
    def cid(L, alpha, rho, boundary, h):
        return f"L{L}-a{alpha:g}-r{rho}-{boundary}-h{h:g}"
    pairs = []
    for alpha in (1, 0.95, 0.9, 0.75, 0.5):
        held = cid(64, alpha, "0", "hold", 100)
        for h in (1, 100):
            pairs.append((f"lazy alpha={alpha:g}: active h={h} minus held",
                          cid(64, alpha, "0", "endogenous", h), held))
        if alpha != 1:
            pairs.append((f"lazy held: alpha={alpha:g} minus alpha=1", held, cid(64, 1, "0", "hold", 100)))
    for rho in ("0", "edge-count", "0.025", "0.05", "0.1"):
        held = cid(64, 1, rho, "hold", 100)
        for h in (1, 100):
            pairs.append((f"interior rho={rho}: active h={h} minus held",
                          cid(64, 1, rho, "endogenous", h), held))
        if rho != "0":
            pairs.append((f"interior held: rho={rho} minus rho=0", held, cid(64, 1, "0", "hold", 100)))
            pairs.append((f"interior active h=100: rho={rho} minus rho=0",
                          cid(64, 1, rho, "endogenous", 100), cid(64, 1, "0", "endogenous", 100)))
    for L in (32, 64, 128):
        pairs.append((f"size L={L}: rho=0.05 active h=100 minus held",
                      cid(L, 1, "0.05", "endogenous", 100), cid(L, 1, "0.05", "hold", 100)))
        if L != 64:
            pairs.append((f"size held alpha=0.9: L={L} minus L=64",
                          cid(L, 0.9, "0", "hold", 100), cid(64, 0.9, "0", "hold", 100)))
    return [(label, a, b) for label, a, b in pairs if a in conditions and b in conditions]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("study", type=Path)
    args = parser.parse_args()
    study = args.study.resolve()
    protocol = json.loads((study / "Protocol.json").read_text())
    for name, expected in protocol["frozen_files"].items():
        assert hashlib.sha256((study / name).read_bytes()).hexdigest() == expected, name
    assert hashlib.sha256(Path(protocol["reference_ledger"]).read_bytes()).hexdigest() == \
        protocol["reference_ledger_sha256"]
    manifest = pd.read_csv(study / "Manifest.csv")
    runs = pd.read_csv(study / "Run-Summary.csv")
    checks = validate(study, protocol, manifest, runs)

    summary = summarize_conditions(runs)
    summary.to_csv(study / "Condition-Summary.csv", index=False)

    seeds = sorted(runs.seed.unique())
    resamples = np.random.default_rng(BOOTSTRAP_SEED).integers(0, len(seeds), (BOOTSTRAPS, len(seeds)))
    point, draws = bootstrap_midpoints(runs, seeds, resamples)
    info = runs.drop_duplicates("condition").set_index("condition")
    rows = []
    for condition, values in point.items():
        row = dict(condition=condition, experiment=info.experiment[condition], L=info.L[condition],
                   alpha=info.alpha[condition], rho_label=info.rho_label[condition],
                   boundary=info.boundary[condition], h=info.h[condition], **values,
                   resolved=values["interior_fractions"] >= 5)
        for j, name in enumerate(("f25", "f50", "f75", "width")):
            row[name + "_low"], row[name + "_high"], row[name + "_valid"] = interval(draws[condition][:, j])
        rows.append(row)
    midpoint_table = pd.DataFrame(rows).sort_values(["experiment", "L", "alpha", "rho_label", "boundary", "h"])
    midpoint_table.to_csv(study / "Midpoints.csv", index=False)

    contrasts = []
    for label, a, b in planned_contrasts(point):
        difference = draws[a][:, 1] - draws[b][:, 1]
        low, high, valid = interval(difference)
        contrasts.append(dict(contrast=label, condition_a=a, condition_b=b,
                              f50_a=point[a]["f50"], f50_b=point[b]["f50"],
                              difference=point[a]["f50"] - point[b]["f50"],
                              low=low, high=high, valid_fraction=valid))
    contrast_table = pd.DataFrame(contrasts, columns=[
        "contrast", "condition_a", "condition_b", "f50_a", "f50_b", "difference",
        "low", "high", "valid_fraction"])
    contrast_table.to_csv(study / "Contrasts.csv", index=False)

    checks["conditions"] = len(point)
    checks["unresolved_conditions"] = sorted(c for c, v in point.items() if v["interior_fractions"] < 5)
    checks["conditions_without_f50"] = sorted(c for c, v in point.items() if not np.isfinite(v["f50"]))
    checks["bootstrap_resamples"] = BOOTSTRAPS
    (study / "Validation.json").write_text(json.dumps(checks, indent=2) + "\n")

    def markdown(frame):
        try:
            return frame.to_markdown(index=False, floatfmt=".4f")
        except ImportError:  # tabulate is optional
            return "```\n" + frame.to_string(index=False, float_format="%.4f") + "\n```"

    lines = [f"# {protocol['version']}", "",
             f"{len(runs)} simulations in {protocol['groups']} groups. "
             f"Archived runs reproduced: {checks['archived_runs_reproduced']} of "
             f"{checks['archived_runs_compared']}. Maximum cash conservation error: "
             f"{checks['max_cash_conservation_error']:.3g}.", "",
             "Conditions with fewer than five fractions strictly between 0.05 and 0.95: "
             + (", ".join(checks["unresolved_conditions"]) or "none") + ".", "",
             "## Midpoints", "",
             markdown(midpoint_table[["condition", "f50", "f50_low", "f50_high", "width",
                                      "interior_fractions"]]), "",
             "## Planned contrasts (f50 of A minus f50 of B)", "",
             markdown(contrast_table[["contrast", "difference", "low", "high", "valid_fraction"]]), ""]
    (study / "Assessment.md").write_text("\n".join(lines))
    print("\n".join(lines))


if __name__ == "__main__":
    main()
