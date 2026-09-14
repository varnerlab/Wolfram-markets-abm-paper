"""Prepare, analyze, verify, and plot the fixed fresh-market confirmation."""
import argparse
import csv
import hashlib
import io
import json
import platform
import tomllib
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
VERSION = "transmission-confirmation-v1"
BOOTSTRAPS = 10000
BOOTSTRAP_SEED = 2026091401
METRICS = (
    "exit_cash_difference", "followers_return_difference", "others_sell_difference",
    "after_withdrawal_others_sell_difference", "late_others_sell_difference",
    "drawdown_difference", "remaining_exit_cash_difference", "follower_cash_difference",
    "remaining_cash_difference", "dealer_cash_difference", "total_trader_cash_difference",
)
KEYS = ("a", "independent", "h", "boundary")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def csv_text(rows):
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return stream.getvalue()


def atomic_text(path, value):
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(value)
    temporary.replace(path)


def write_json(path, value):
    atomic_text(path, json.dumps(value, indent=2, allow_nan=False) + "\n")


def output_dir(smoke):
    return ROOT / "output/repaired" / (VERSION + ("-smoke" if smoke else "-full"))


def market_seeds(smoke):
    return [640001] if smoke else list(range(641001, 641051))


def environment():
    return {"python_version": platform.python_version(), "numpy_version": np.__version__,
            "bootstrap_generator": "numpy.random.PCG64", "bootstrap_seed": BOOTSTRAP_SEED}


def prepare(smoke=False):
    output = output_dir(smoke)
    output.mkdir(parents=True, exist_ok=True)
    if (output / "Protocol.toml").exists():
        check_frozen(output)
        print("Existing frozen preparation verified:", output)
        return
    prior = sorted(set((ROOT / "code/data").glob("*Summary.csv")) |
                   set((ROOT / "code/data").glob("*Manifest.csv")) |
                   set((ROOT / "output/repaired").glob("*/Summary.csv")) |
                   set((ROOT / "output/repaired").glob("*/Manifest.csv")))
    audit = []
    combined = set()
    for path in prior:
        if VERSION in str(path):
            continue
        rows = read_rows(path)
        if not rows or "seed" not in rows[0]:
            continue
        seeds = sorted({int(r["seed"]) for r in rows})
        combined.update(seeds)
        audit.append({"path": str(path.relative_to(ROOT)), "sha256": sha(path),
                      "rows": len(rows), "seeds": seeds})
    overlap = combined & set(market_seeds(smoke))
    assert not overlap, f"Starting markets already used: {overlap}"
    assert audit and set(range(631001, 631011)) <= combined
    write_json(output / "Freshness.json", {
        "recorded_utc": datetime.now(timezone.utc).isoformat(),
        "confirmation_seeds": market_seeds(smoke), "prior_unique_seeds": len(combined),
        "overlap": sorted(overlap), "prior_files": audit,
    })
    write_json(output / "Environment.json", environment())
    print(f"Freshness audit passed: {len(audit)} prior files, {len(combined)} prior seeds; {output}")


def check_frozen(output):
    protocol = tomllib.loads((output / "Protocol.toml").read_text())
    frozen = tomllib.loads((output / "Frozen-files.toml").read_text())["files"]
    for path, expected in frozen.items():
        assert sha(ROOT / path) == expected, f"Frozen source changed: {path}"
    digest = hashlib.sha256("\n".join(p + frozen[p] for p in sorted(frozen)).encode()).hexdigest()
    assert digest == protocol["source_digest"]
    for filename, field in (("Manifest.csv", "manifest_digest"),
                            ("Freshness.json", "freshness_digest"),
                            ("Environment.json", "python_environment_digest")):
        assert sha(output / filename) == protocol[field], filename
    assert json.loads((output / "Environment.json").read_text()) == environment()
    assert protocol["bootstrap_resamples"] == BOOTSTRAPS
    assert protocol["bootstrap_seed"] == BOOTSTRAP_SEED
    assert protocol["primary_interval_level"] == .975
    return protocol


def groups(rows, keys):
    result = defaultdict(list)
    for row in rows:
        result[tuple(row[k] for k in keys)].append(row)
    return result


def paired(left, right, metric):
    key = lambda row: (int(row["seed"]), int(row["replicate"]))
    lookup = {key(r): r for r in right}
    assert len(lookup) == len(right) == len(left)
    assert set(lookup) == {key(r) for r in left}
    return [{"seed": r["seed"], "replicate": r["replicate"],
             metric: float(r[metric]) - float(lookup[key(r)][metric])} for r in left]


def market_means(rows, metric, seeds, replicates):
    by_seed = groups(rows, ("seed",))
    assert {int(k[0]) for k in by_seed} == set(seeds)
    values = []
    for seed in seeds:
        selected = [r for r in rows if int(r["seed"]) == seed]
        assert sorted(int(r["replicate"]) for r in selected) == list(range(1, replicates + 1))
        observations = np.array([float(r[metric]) for r in selected])
        assert np.isfinite(observations).all(), metric
        values.append(float(observations.mean()))
    return np.array(values)


def summarize(values, indices, level=.95):
    draws = values[indices].mean(axis=1)
    tail = (1 - level) / 2
    lower, upper = np.quantile(draws, [tail, 1 - tail])
    return {"estimate": float(values.mean()), "lower": float(lower), "upper": float(upper),
            "markets": len(values), "valid_bootstraps": len(draws), "interval_level": level}


def primary_result(live, effect, indices, smoke=False):
    endpoints = []
    for name, values in (("continuous_cash_advantage", live), ("continuous_minus_mask", effect)):
        stat = summarize(values, indices, .975)
        endpoints.append({"endpoint": name, **stat, "positive_lower_limit": stat["lower"] > 0})
    return {"status": "smoke_only" if smoke else "evaluated",
            "confirmed": None if smoke else all(e["positive_lower_limit"] for e in endpoints),
            "nominal_family_level": .95, "adjustment": "Bonferroni, two endpoints",
            "endpoints": endpoints}


def estimates(data, smoke=False):
    seeds = market_seeds(smoke)
    reps = 1 if smoke else 2
    indices = np.random.Generator(np.random.PCG64(BOOTSTRAP_SEED)).integers(
        0, len(seeds), size=(BOOTSTRAPS, len(seeds)))
    treatment = [r for r in data if r["mode"] != "none"]
    def stats(rows, metric):
        return summarize(market_means(rows, metric, seeds, reps), indices)
    grouped = []
    for key, rows in sorted(groups(treatment, KEYS + ("diagnostic",)).items()):
        for metric in METRICS:
            grouped.append({**dict(zip(KEYS + ("diagnostic",), key)), "metric": metric,
                            **stats(rows, metric)})
    contrasts = []
    for key, rows in sorted(groups(treatment, KEYS).items()):
        arms = {name: [r for r in rows if r["diagnostic"] == name]
                for name in ("live", "mask", "withdrawal")}
        for name, left, right in (("continuous_minus_mask", "live", "mask"),
                                  ("withdrawal_minus_continuous", "withdrawal", "live")):
            for metric in METRICS:
                contrasts.append({**dict(zip(KEYS, key)), "comparison": name, "metric": metric,
                                  **stats(paired(arms[left], arms[right], metric), metric)})
    sources = []
    source_keys = ("a", "h", "boundary", "diagnostic")
    for key, rows in sorted(groups(treatment, source_keys).items()):
        left = [r for r in rows if r["independent"] == "false"]
        right = [r for r in rows if r["independent"] == "true"]
        for metric in METRICS:
            sources.append({**dict(zip(source_keys, key)), "comparison": "shared_minus_independent",
                            "metric": metric, **stats(paired(left, right, metric), metric)})
    primary = [r for r in treatment if float(r["a"]) == .4 and float(r["h"]) == 100 and
               r["boundary"] == "hold" and r["independent"] == "false"]
    live = [r for r in primary if r["diagnostic"] == "live"]
    mask = [r for r in primary if r["diagnostic"] == "mask"]
    metric = "exit_cash_difference"
    live_values = market_means(live, metric, seeds, reps)
    mask_values = market_means(mask, metric, seeds, reps)
    effect = market_means(paired(live, mask, metric), metric, seeds, reps)
    per_market = [{"seed": seed, "replicates": reps, "continuous_cash_advantage": float(l),
                   "masked_cash_advantage": float(m), "continuous_minus_mask": float(e)}
                  for seed, l, m, e in zip(seeds, live_values, mask_values, effect)]
    live_draws, effect_draws = live_values[indices].mean(axis=1), effect[indices].mean(axis=1)
    draws = [{"resample": i + 1, "continuous_cash_advantage": float(l),
              "continuous_minus_mask": float(e)} for i, (l, e) in enumerate(zip(live_draws, effect_draws))]
    tables = {"Grouped.csv": grouped, "Contrasts.csv": contrasts, "Source-contrasts.csv": sources,
              "Primary-markets.csv": per_market, "Primary-bootstrap.csv": draws}
    return tables, primary_result(live_values, effect, indices, smoke)


def format_interval(row):
    return f"{100 * float(row['estimate']):+.3f} [{100 * float(row['lower']):+.3f}, {100 * float(row['upper']):+.3f}]"


def report(data, tables, decision, smoke):
    title = "Smoke workflow: no confirmation claim" if smoke else "Fresh-market confirmation of local advice influence"
    verdict = "This small workflow check is excluded from confirmation." if smoke else (
        "Both predeclared endpoints passed: the joint claim was confirmed on fresh starting markets."
        if decision["confirmed"] else "The joint claim was not confirmed: at least one predeclared endpoint failed.")
    lines = [f"# {title}", "", verdict, "",
             f"Completed {len(data):,} runs across {len(market_seeds(smoke))} starting markets. "
             "Pilot observations were not pooled with confirmation. All results use the unchanged repaired engine.", "",
             "The primary setting is 40% adoption of one shared source, reserves of 100 shares per trader, "
             "and technical traders held. Cash is measured after all traders liquidate, relative to the same "
             "prospective cohort in its no-following market, normalized by value at adoption.", "",
             "| Required endpoint | Mean change (pp; adjusted interval) | Positive lower limit |",
             "|---|---:|---|", *[f"| {r['endpoint']} | {format_interval(r)} | {r['positive_lower_limit']} |"
                                     for r in decision["endpoints"]], "",
             "The two required endpoints use 97.5% percentile intervals with a Bonferroni adjustment for "
             "nominal 95% family coverage. Both lower limits must exceed zero. Bootstrap coverage is approximate. "
             "The analysis averages design replicates within each starting market, then resamples whole markets "
             "10,000 times. The following secondary intervals are pointwise 95% intervals.", "",
             "| Technical traders | Reserves/trader | Advice intervention | Follower cash difference (pp; 95% interval) |",
             "|---|---:|---|---:|"]
    for r in tables["Grouped.csv"]:
        if float(r["a"]) == .4 and r["independent"] == "false" and r["metric"] == "exit_cash_difference":
            lines.append(f"| {'held' if r['boundary'] == 'hold' else 'active'} | {float(r['h']):g} | "
                         f"{r['diagnostic']} | {format_interval(r)} |")
    lines += ["", "Masking retains follower submitted advice orders while changing what their neighbors read. "
              "Held non-followers reproduce their no-following decision histories exactly; active technical "
              "traders retain the route through prices. Withdrawal also changes follower orders and therefore "
              "does not isolate local influence by itself.", "",
              f"The largest absolute dealer cash difference was {max(abs(float(r['dealer_cash_difference'])) for r in data):.6g} "
              "currency units. The corresponding aggregate trader cash difference was "
              f"{max(abs(float(r['total_trader_cash_difference'])) for r in data):.6g}. "
              "With all trader shares liquidated, the dealer's reserve invariant fixes equal final dealer cash. "
              "Follower cash gains redistribute cash among traders.", "",
              "Complete secondary estimates are in [Grouped.csv](Grouped.csv), [Contrasts.csv](Contrasts.csv), "
              "and [Source-contrasts.csv](Source-contrasts.csv). The [market-level primary values](Primary-markets.csv) "
              "and [bootstrap draws](Primary-bootstrap.csv) reproduce the fixed decision. "
              "See the [protocol](../../../docs/superpowers/specs/2026-09-14-reserve-transmission-confirmation.md).", "",
              "The confirmation tests new starting markets within this model and its specified settings. "
              "It does not establish useful information about an external asset value, real investment performance, "
              "copying effects, transaction-cost robustness, alternative execution mechanisms, or size/horizon sensitivity."]
    return "\n".join(lines) + "\n"


def analyze(smoke=False):
    output = output_dir(smoke)
    protocol = check_frozen(output)
    data = read_rows(output / "Summary.csv")
    assert len(data) == protocol["runs"]
    tables, decision = estimates(data, smoke)
    for name, rows in tables.items():
        atomic_text(output / name, csv_text(rows))
    write_json(output / "Primary.json", decision)
    atomic_text(output / "report.md", report(data, tables, decision, smoke))
    artifacts = list(tables) + ["Primary.json", "report.md"]
    write_json(output / "Analysis.json", {"created_utc": datetime.now(timezone.utc).isoformat(),
        "source_digest": protocol["source_digest"], "summary_digest": sha(output / "Summary.csv"),
        "artifacts": {p: sha(output / p) for p in artifacts}})
    print(json.dumps(decision, indent=2))


def verify(smoke=False):
    output = output_dir(smoke)
    protocol = check_frozen(output)
    data, manifest = read_rows(output / "Summary.csv"), read_rows(output / "Manifest.csv")
    runs, blocks = (52, 4) if smoke else (5200, 400)
    assert protocol["runs"] == len(data) == len(manifest) == runs
    lookup = {r["job_id"]: r for r in data}
    assert len(lookup) == runs and set(lookup) == {r["job_id"] for r in manifest}
    for job in manifest:
        assert all(lookup[job["job_id"]][k] == v for k, v in job.items())
    checkpoints = sorted((output / "checkpoints").glob("*.csv"))
    assert len(checkpoints) == blocks
    cached = [r for p in checkpoints for r in read_rows(p)]
    assert len(cached) == runs and {r["job_id"]: r for r in cached} == lookup
    assert {int(r["seed"]) for r in data} == set(market_seeds(smoke))
    assert len({r["seed"]: r["start_fingerprint"] for r in data}) == len(market_seeds(smoke))
    for row in data:
        control = lookup[row["control_id"]]
        assert control["mode"] == "none" and row["start_fingerprint"] == control["start_fingerprint"]
        assert all(row[k] == control[k] for k in ("seed", "replicate", "h", "boundary"))
        assert all(row[k] == "true" for k in
                   ("same_advice_orders", "held_mask_identity", "withdrawal_prefix_identity"))
        assert float(row["exit_unsold_shares"]) == float(row["control_exit_unsold_shares"]) == 0
        amounts = [float(row[k]) for k in ("follower_cash_difference", "remaining_cash_difference", "dealer_cash_difference")]
        assert np.isfinite(amounts).all() and abs(sum(amounts)) < 1e-3
        assert abs(amounts[-1]) < 1e-3 and abs(float(row["total_trader_cash_difference"])) < 1e-3
        if row["diagnostic"] == "mask" and row["boundary"] == "hold":
            assert float(row["others_sell_difference"]) == float(row["late_others_sell_difference"]) == 0
    audit = json.loads((output / "Freshness.json").read_text())
    assert audit["confirmation_seeds"] == market_seeds(smoke) and audit["overlap"] == []
    previous_fingerprints = set()
    for prior in audit["prior_files"]:
        path = ROOT / prior["path"]
        assert sha(path) == prior["sha256"], f"Prior data changed: {path}"
        assert not (set(prior["seeds"]) & set(market_seeds(smoke)))
        if "Summary" in path.name:
            previous_fingerprints.update(r["start_fingerprint"] for r in read_rows(path) if "start_fingerprint" in r)
    assert not (previous_fingerprints & {r["start_fingerprint"] for r in data})
    analysis = json.loads((output / "Analysis.json").read_text())
    assert analysis["source_digest"] == protocol["source_digest"]
    assert analysis["summary_digest"] == sha(output / "Summary.csv")
    for name, digest in analysis["artifacts"].items():
        assert sha(output / name) == digest, name
    tables, decision = estimates(data, smoke)
    for name, rows in tables.items():
        assert (output / name).read_text() == csv_text(rows), f"Estimate mismatch: {name}"
    assert decision == json.loads((output / "Primary.json").read_text())
    primary = read_rows(output / "Primary-markets.csv")
    # Reconstruct the two intervals directly from the deposited draw columns.
    draws = read_rows(output / "Primary-bootstrap.csv")
    for endpoint in decision["endpoints"]:
        name = endpoint["endpoint"]
        assert np.isclose(endpoint["estimate"], np.mean([float(r[name]) for r in primary]), atol=1e-14)
        limits = np.quantile([float(r[name]) for r in draws], [.0125, .9875])
        assert np.allclose(limits, [endpoint["lower"], endpoint["upper"]], atol=1e-14)
    result = {"verified_utc": datetime.now(timezone.utc).isoformat(), "runs": runs, "blocks": blocks,
              "markets": len(primary), "held_mask_identities": sum(r["diagnostic"] == "mask" and r["boundary"] == "hold" for r in data),
              "identical_masked_advice": sum(r["diagnostic"] == "mask" for r in data),
              "withdrawal_prefix_identities": sum(r["diagnostic"] == "withdrawal" for r in data),
              "prior_files_checked": len(audit["prior_files"]), "prior_seed_overlap": 0,
              "prior_starting_fingerprint_overlap": 0, "source_digest": protocol["source_digest"],
              "summary_digest": sha(output / "Summary.csv"), "primary_confirmed": decision["confirmed"]}
    write_json(output / "verification.json", result)
    print(json.dumps(result, indent=2))


def figure(smoke=False):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    output = output_dir(smoke)
    assert (output / "verification.json").exists()
    pilot = ROOT / "output/repaired/transmission-v1-pilot"
    rows = read_rows(output / "Grouped.csv")
    old = read_rows(pilot / "Grouped.csv")
    contrasts = read_rows(output / "Contrasts.csv")
    plt.rcParams.update({"font.size": 11, "axes.spines.top": False, "axes.spines.right": False,
                         "svg.fonttype": "none"})
    fig, axes = plt.subplots(1, 2, figsize=(12.6, 6.1))
    fig.subplots_adjust(left=.075, right=.98, bottom=.26, top=.76, wspace=.32)
    colors = {"hold": "#4477AA", "endogenous": "#228833"}
    def selected(table, **filters):
        return next(r for r in table if all(r[k] == v for k, v in filters.items()))
    common = {"a": "0.4", "h": "100.0", "independent": "false", "metric": "exit_cash_difference"}
    for table, offset, color, label in ((old, -.07, "#999999", "Pilot: 10 markets"),
            (rows, .07, colors["hold"], "Smoke: 1 market" if smoke else "Confirmation: 50 markets")):
        for i, arm in enumerate(("live", "mask", "withdrawal")):
            r = selected(table, **common, boundary="hold", diagnostic=arm)
            x, lo, hi = (100 * float(r[k]) for k in ("estimate", "lower", "upper"))
            axes[0].errorbar(i + offset, x, yerr=[[x-lo], [hi-x]], fmt="o", color=color,
                             capsize=4, label=label if i == 0 else None)
    axes[0].set_xticks(range(3), ("Continuous\nadvice", "Local influence\nmasked", "Advice\nwithdrawn"))
    axes[0].set_title("A   Follower cash: pilot and confirmation", loc="left", fontsize=12, pad=14)
    axes[0].set_ylabel("Difference from no following (percentage points)")
    axes[0].legend(frameon=False, fontsize=10)
    for boundary, offset in (("hold", -.07), ("endogenous", .07)):
        for i, h in enumerate(("1.0", "100.0")):
            filters = {**common, "h": h, "boundary": boundary, "comparison": "continuous_minus_mask"}
            r = selected(contrasts, **filters)
            x, lo, hi = (100 * float(r[k]) for k in ("estimate", "lower", "upper"))
            axes[1].errorbar(i + offset, x, yerr=[[x-lo], [hi-x]], fmt="o", color=colors[boundary],
                capsize=4, label="Technical traders " + ("held" if boundary == "hold" else "active") if i == 0 else None)
    axes[1].set_xticks((0, 1), ("Shallow reserves\n1 share per trader", "Deep reserves\n100 shares per trader"))
    axes[1].set_xlim(-.4, 1.4)
    axes[1].set_title("B   Cash effect of allowing local influence", loc="left", fontsize=12, pad=14)
    axes[1].set_ylabel("Continuous minus masked advice (percentage points)")
    axes[1].legend(frameon=False, fontsize=10)
    for ax in axes:
        ax.axhline(0, color="#999999", linewidth=.8)
        ax.grid(axis="y", color="#eeeeee")
        ax.set_axisbelow(True)
    fig.suptitle("Local advice influence on fresh starting markets", x=.075, y=.965,
                 ha="left", fontsize=17, fontweight="bold")
    fig.text(.075, .895, "40% adoption · one shared source · unchanged reserve execution · matched liquidation", fontsize=11)
    fig.text(.075, .105, "Bars show pointwise 95% whole-market bootstrap intervals. Samples are not pooled.", fontsize=10)
    fig.text(.075, .06, "The confirmation decision uses two separate adjusted 97.5% intervals reported in Primary.json.", fontsize=10)
    for extension in ("png", "svg"):
        fig.savefig(output / ("confirmation-controls." + extension), dpi=180)
    plt.close(fig)
    print(output / "confirmation-controls.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "analyze", "verify", "figure"))
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()
    globals()[args.action](args.smoke)
