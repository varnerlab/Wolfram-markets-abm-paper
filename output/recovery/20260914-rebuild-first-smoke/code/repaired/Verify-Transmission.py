"""Check frozen source, complete coverage, intervention gates, and analysis."""
import csv
import hashlib
import json
import math
import runpy
import sys
import tomllib
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def verify(stage="pilot"):
    assert stage in ("smoke", "pilot")
    output = ROOT / "output/repaired" / ("transmission-v1-" + stage)
    protocol = tomllib.loads((output / "Protocol.toml").read_text())
    common = runpy.run_path(str(ROOT / "code/repaired/Verify-Outputs.py"))["source_digest"]()
    for name in ("code/following/Following-Controls-Lib.jl", "code/repaired/Compute-Following-Pilot.jl",
                 "code/repaired/Transmission-Lib.jl", "code/repaired/Compute-Transmission.jl"):
        common += name + (ROOT / name).read_text()
    assert sha(common.encode()) == protocol["source_digest"]
    assert sha((ROOT / "code/Manifest.toml").read_bytes()) == protocol["environment_digest"]
    spec = ROOT / "docs/superpowers/specs/2026-09-14-reserve-transmission-controls.md"
    assert sha(spec.read_bytes()) == protocol["specification_digest"]
    assert sha((output / "Manifest.csv").read_bytes()) == protocol["manifest_digest"]
    manifest = read_rows(output / "Manifest.csv")
    data = read_rows(output / "Summary.csv")
    expected_runs, expected_blocks, expected_markets = (52, 4, 1) if stage == "smoke" else (1040, 80, 10)
    assert len(data) == len(manifest) == expected_runs
    lookup = {row["job_id"]: row for row in data}
    assert len(lookup) == expected_runs
    assert set(lookup) == {row["job_id"] for row in manifest}
    for job in manifest:
        assert all(lookup[job["job_id"]][key] == value for key, value in job.items())
    paths = sorted((output / "checkpoints").glob("*.csv"))
    assert len(paths) == expected_blocks
    cached = [row for path in paths for row in read_rows(path)]
    assert len(cached) == expected_runs
    assert {row["job_id"]: row for row in cached} == lookup
    masks = [row for row in data if row["diagnostic"] == "mask"]
    held_masks = [row for row in masks if row["boundary"] == "hold"]
    withdrawal = [row for row in data if row["diagnostic"] == "withdrawal"]
    assert all(row["same_advice_orders"] == "true" for row in masks)
    assert all(row["held_mask_identity"] == "true" for row in held_masks)
    assert all(row["withdrawal_prefix_identity"] == "true" for row in withdrawal)
    assert all(float(row["others_sell_difference"]) == 0 and
               float(row["late_others_sell_difference"]) == 0 for row in held_masks)
    for row in data:
        assert float(row["exit_unsold_shares"]) == float(row["control_exit_unsold_shares"]) == 0
        amounts = [float(row[key]) for key in
                   ("follower_cash_difference", "remaining_cash_difference", "dealer_cash_difference")]
        assert all(map(math.isfinite, amounts))
        assert abs(sum(amounts)) < 1e-3
        assert abs(amounts[-1]) < 1e-3
        assert abs(float(row["total_trader_cash_difference"])) < 1e-3
    for name, expected in (("Grouped.csv", 528), ("Contrasts.csv", 352), ("Source-contrasts.csv", 264)):
        estimates = read_rows(output / name)
        assert len(estimates) == expected
        assert all(int(row["markets"]) == expected_markets and int(row["valid_bootstraps"]) == 2000
                   for row in estimates)
        assert all(float(row["lower"]) <= float(row["upper"]) for row in estimates)
    replays = 0
    if stage == "pilot":
        replay_rows = read_rows(output / "Pilot-replay.csv")
        assert len(replay_rows) == 320
        old = {row["job_id"]: row for row in
               read_rows(ROOT / "output/repaired/following-reserve-v2-pilot/Summary.csv")}
        for replay in replay_rows:
            new, prior = lookup[replay["job_id"]], old[replay["pilot_job_id"]]
            common_keys = new.keys() & prior.keys() - {"job_id", "stage", "diagnostic", "control_id"}
            assert all(new[key] == prior[key] for key in common_keys)
            assert len(common_keys) == int(replay["matching_columns"])
        replays = len(replay_rows)
    analysis = tomllib.loads((output / "Analysis.toml").read_text())
    source = (ROOT / "code/repaired/Analyze-Transmission.jl").read_bytes()
    source += (ROOT / "code/following/Analyze-Following.jl").read_bytes()
    assert analysis["analysis_digest"] == sha(source)
    assert analysis["summary_digest"] == sha((output / "Summary.csv").read_bytes())
    result = {"verified_utc": datetime.now(timezone.utc).isoformat(), "runs": expected_runs,
              "blocks": expected_blocks, "markets": expected_markets, "pilot_replays": replays,
              "held_mask_identities": len(held_masks), "identical_masked_advice": len(masks),
              "withdrawal_prefix_identities": len(withdrawal),
              "maximum_dealer_cash_difference": max(abs(float(row["dealer_cash_difference"])) for row in data),
              "maximum_total_trader_cash_difference": max(abs(float(row["total_trader_cash_difference"])) for row in data),
              "source_digest": protocol["source_digest"], "summary_digest": analysis["summary_digest"]}
    (output / "verification.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    verify(sys.argv[1] if len(sys.argv) > 1 else "pilot")
