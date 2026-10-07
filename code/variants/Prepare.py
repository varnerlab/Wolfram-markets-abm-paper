"""Freeze the lazy-revision and interior-technical study in a new empty directory."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "output/rebuilt/manuscript-reserve-v1"
LEDGER = REFERENCE / "code/data/Rebuild-Execution-Ledger.csv"
VERSION = "lazy-revision-interior-technical-v1"

# Fraction offsets around each condition's pilot crossover: dense near the
# center, wide tails so every condition brackets Sell-majority probability 0
# and 1. One offset set serves every condition.
OFFSETS = [-0.08, -0.06, -0.04, -0.03, -0.025, -0.02, -0.015, -0.01, -0.005, 0.0,
           0.005, 0.01, 0.015, 0.02, 0.025, 0.03, 0.04, 0.06, 0.08, 0.12, 0.18, 0.25]

HELD = ("hold", 100.0)
ACTIVE_SHALLOW = ("endogenous", 1.0)
ACTIVE_DEEP = ("endogenous", 100.0)
EDGE_COUNT_RHO = 63 / 62**2  # the 63 edge technical traders of L = 64, moved inside

# (experiment, L, alpha, rho_label, rho, boundary, h) -> pilot crossover center.
# L = 64 centers come from output/pilots/revision-interior-technical (20 markets);
# L = 32 and 128 centers from a coarse 20-market size pilot (2026-10-02).
def conditions():
    rows = []
    lazy_centers = {1.0: 0.18, 0.95: 0.255, 0.9: 0.295, 0.75: 0.36, 0.5: 0.41}
    for alpha, center in lazy_centers.items():
        for boundary, h in (HELD, ACTIVE_SHALLOW, ACTIVE_DEEP):
            rows.append(("lazy", 64, alpha, "0", 0.0, boundary, h, center))
    interior_centers = {
        ("edge-count", EDGE_COUNT_RHO): {HELD: 0.185, ACTIVE_SHALLOW: 0.22, ACTIVE_DEEP: 0.22},
        ("0.025", 0.025): {HELD: 0.19, ACTIVE_SHALLOW: 0.27, ACTIVE_DEEP: 0.27},
        ("0.05", 0.05): {HELD: 0.20, ACTIVE_SHALLOW: 0.32, ACTIVE_DEEP: 0.355},
        ("0.1", 0.10): {HELD: 0.24, ACTIVE_SHALLOW: 0.38, ACTIVE_DEEP: 0.35},
    }
    for (label, rho), centers in interior_centers.items():
        for (boundary, h), center in centers.items():
            rows.append(("interior", 64, 1.0, label, rho, boundary, h, center))
    size_centers = {
        32: {(0.9, "0", 0.0, HELD): 0.345, (1.0, "0.05", 0.05, HELD): 0.22,
             (1.0, "0.05", 0.05, ACTIVE_DEEP): 0.37},
        128: {(0.9, "0", 0.0, HELD): 0.28, (1.0, "0.05", 0.05, HELD): 0.19,
              (1.0, "0.05", 0.05, ACTIVE_DEEP): 0.34},
    }
    for L, centers in size_centers.items():
        for (alpha, label, rho, (boundary, h)), center in centers.items():
            rows.append(("size", L, alpha, label, rho, boundary, h, center))
    return rows


def fractions(center):
    return sorted({round(center + offset, 4) for offset in OFFSETS
                   if 0.0 < center + offset < 0.95})


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def condition_id(L, alpha, rho_label, boundary, h):
    return f"L{L}-a{alpha:g}-r{rho_label}-{boundary}-h{h:g}"


def manifest_rows(smoke):
    rows = []
    if smoke:
        grid = [0.15, 0.25, 0.35]
        design = [("lazy", 64, 1.0, "0", 0.0, "hold", 100.0, grid),
                  ("lazy", 64, 1.0, "0", 0.0, "endogenous", 100.0, grid),
                  ("lazy", 64, 0.9, "0", 0.0, "endogenous", 1.0, grid),
                  ("interior", 64, 1.0, "0.05", 0.05, "hold", 100.0, grid),
                  ("interior", 64, 1.0, "0.05", 0.05, "endogenous", 100.0, grid)]
        seeds, pre, post = range(1, 3), 20, 80
    else:
        design = [row[:-1] + (fractions(row[-1]),) for row in conditions()]
        seeds, pre, post = range(1, 51), 1000, 3000
    for experiment, L, alpha, label, rho, boundary, h, grid in design:
        condition = condition_id(L, alpha, label, boundary, h)
        for seed in seeds:
            group = f"{condition}-s{seed}"
            jobs = [("control", max(grid))] + [("treated", f) for f in grid]
            for role, f in jobs:
                rows.append(dict(group=group, role=role, experiment=experiment,
                                 condition=condition, alpha=alpha, rho=rho, rho_label=label,
                                 h=h, boundary=boundary, seed=seed, f=f, L=L,
                                 pre=pre, post=post))
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--smoke", action="store_true",
                        help="three fractions, two seeds, short runs: an end-to-end pipeline check")
    args = parser.parse_args()
    dest = args.destination.resolve()
    if dest.exists():
        raise SystemExit("Destination must not already exist.")
    reference = json.loads((REFERENCE / "Protocol.json").read_text())
    for name, expected in reference["frozen_computation"].items():
        assert digest(REFERENCE / name) == expected, name
    sources = list((ROOT / "code/src").glob("*.jl"))
    sources += list((ROOT / "code/variants").glob("*.jl"))
    sources += list((ROOT / "code/variants").glob("*.py"))
    sources += [ROOT / "code/variants/README.md",
                ROOT / "code/test/test_revision_interior_technical.jl",
                ROOT / "code/Project.toml", ROOT / "code/Manifest.toml"]
    for source in sources:
        target = dest / source.relative_to(ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    for name in ("logs", "results"):
        (dest / name).mkdir()
    rows = manifest_rows(args.smoke)
    with (dest / "Manifest.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    frozen = {str(p.relative_to(dest)): digest(p)
              for p in sorted(dest.rglob("*")) if p.is_file()}
    groups = {row["group"] for row in rows}
    protocol = dict(
        version=VERSION + ("-smoke" if args.smoke else ""),
        created_utc=datetime.now(timezone.utc).isoformat(),
        purpose=("Robustness of the rule-switch crossover to lazy revision (each interior "
                 "trader adopts its rule output with probability alpha per step) and to "
                 "band-rule technical traders placed in the interior at fraction rho"),
        model_changes=("revision_probability = alpha and interior_technical_fraction = rho "
                       "in simulate(); alpha = 1 and rho = 0 reproduce the archived "
                       "manuscript runs bit for bit"),
        experiments=dict(
            lazy="L = 64, rho = 0, alpha in {1, 0.95, 0.9, 0.75, 0.5}, held h = 100 and active h = 1, 100",
            interior=("L = 64, alpha = 1, rho in {63 cells (edge count), 0.025, 0.05, 0.10}, "
                      "held h = 100 and active h = 1, 100; rho = 0 is the lazy alpha = 1 condition"),
            size=("L = 32 and 128: alpha = 0.9 held h = 100; rho = 0.05 held and active h = 100; "
                  "L = 64 counterparts are in the lazy and interior experiments")),
        fraction_offsets=OFFSETS,
        fraction_centers="Pilot crossovers (20 starting markets, seeds 1-20); see conditions in Prepare.py",
        seeds="1-50, the starting markets of the manuscript campaigns" if not args.smoke else "1-2",
        pre_steps=rows[0]["pre"], post_steps=rows[0]["post"],
        groups=len(groups), full_financial_simulations=len(rows),
        pairing=("One no-switch control per condition and starting market, at the largest "
                 "fraction with the minor rule dormant; exact common-history assertions for "
                 "each switched run"),
        majority="Interior Sell fraction, excluding interior technical traders, reaches 0.5 after the switch",
        estimands=("Majority probability by fraction with Wilson 95% intervals; f25, f50, f75 by "
                   "linear interpolation at the first upward crossing; paired differences in f50 "
                   "between conditions sharing starting markets"),
        uncertainty="2,000 bootstrap resamples of whole starting markets, shared across conditions",
        resolution_check="Flag any condition with fewer than five fractions strictly between 0.05 and 0.95",
        validation=("alpha = 1, rho = 0, L = 64 runs at fractions also run in the manuscript "
                    "campaigns must reproduce the archived final-grid hashes in the ledger"),
        reference_protocol_sha256=digest(REFERENCE / "Protocol.json"),
        reference_ledger=str(LEDGER), reference_ledger_sha256=digest(LEDGER),
        initial_cached_results=0, frozen_files=frozen)
    (dest / "Protocol.json").write_text(json.dumps(protocol, indent=2) + "\n")
    print(f"Prepared {dest}: {len(rows)} simulations in {len(groups)} groups")


if __name__ == "__main__":
    main()
