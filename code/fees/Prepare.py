"""Freeze the transaction-fee sensitivity design in a new empty study directory."""
import argparse
import csv
import hashlib
import itertools
import json
from pathlib import Path
import shutil
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "output/rebuilt/manuscript-reserve-v1"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    dest = args.destination.resolve()
    if dest.exists():
        raise SystemExit("Destination must not already exist.")
    reference = json.loads((REFERENCE / "Protocol.json").read_text())
    for name, expected in reference["frozen_computation"].items():
        assert digest(REFERENCE / name) == expected, name
    sources = list((ROOT / "code/src").glob("*.jl"))
    sources += list((ROOT / "code/fees").glob("*.jl"))
    sources += list((ROOT / "code/fees").glob("*.py"))
    sources += [ROOT / "code/Project.toml", ROOT / "code/Manifest.toml"]
    for source in sources:
        target = dest / source.relative_to(ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    for source in (REFERENCE / "code/src").glob("*.jl"):
        target = dest / "reference/src" / source.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    for name in ("logs", "results", "figures"):
        (dest / name).mkdir()
    rows = []
    for fee_bps, h, boundary, seed in itertools.product(
        (0, 5, 10, 25), (0.1, 1.0, 100.0), ("hold", "endogenous"), range(1, 51)
    ):
        group = f"b{fee_bps}-h{h:g}-{boundary}-s{seed}"
        for role, fraction in [("control", 0.25)] + [
            ("treated", f) for f in (0.10, 0.15, 0.175, 0.185, 0.20, 0.25)
        ]:
            rows.append(dict(group=group, role=role, fee_bps=fee_bps, h=h,
                boundary=boundary, seed=seed, f=fraction, L=64, pre=1000, post=3000))
    with (dest / "Manifest.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    frozen = {str(p.relative_to(dest)): digest(p)
        for p in sorted(dest.rglob("*")) if p.is_file()}
    protocol = dict(version="transaction-fees-v1",
        created_utc=datetime.now(timezone.utc).isoformat(),
        purpose="Paired rule-change sensitivity to proportional cash fees on each completed order",
        fee_bps=[0, 5, 10, 25], reserves_per_trader=[0.1, 1.0, 100.0],
        fractions=[0.10, 0.15, 0.175, 0.185, 0.20, 0.25],
        seed_count=50, grid_size=64, pre_steps=1000, post_steps=3000,
        full_financial_simulations=len(rows),
        fee_account="Dealer cash revenue excluded from trading reserves; no reinvestment",
        fee_timing="From initialization, before and after rule activation",
        fee_calibration="Illustrative sensitivity parameters, not an empirical calibration",
        pairing="Control reused within fee/depth/boundary/seed; exact common-history assertions for each treatment",
        uncertainty="Wilson 95% intervals for probabilities; seed-paired bootstrap intervals for differences",
        scope="Main rule-change comparison with active/held technical traders and three reserve depths; original study retained",
        reference_protocol_sha256=digest(REFERENCE / "Protocol.json"),
        initial_cached_results=0, frozen_files=frozen)
    (dest / "Protocol.json").write_text(json.dumps(protocol, indent=2) + "\n")
    print(f"Prepared {dest}: {len(rows)} simulations in {len(rows)//7} groups")


if __name__ == "__main__":
    main()
