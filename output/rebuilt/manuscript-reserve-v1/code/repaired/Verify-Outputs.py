"""Verify the completed repaired campaigns against their frozen protocols."""
import csv
import hashlib
import json
import tomllib
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "output/repaired"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def source_digest():
    names = ["Types.jl", "Factory.jl", "Wolfram.jl", "Compute.jl", "Simulate.jl",
             "Following.jl", "FollowingMetrics.jl", "ReserveClearing.jl"]
    paths = ["code/src/" + name for name in names] + ["code/following/Following-Lib.jl"]
    return digest(b"".join(path.encode() + (ROOT / path).read_bytes() for path in paths))


def verify():
    result = {"verified_utc": datetime.now(timezone.utc).isoformat(), "campaigns": {}}
    common = source_digest()
    for name, script, count, blocks, keys in [
        ("reserve-v2-full", "Compute-Survival.jl", 1600, 400,
         ["seed", "h", "boundary", "L", "pre", "post", "f"]),
        ("following-reserve-v2-pilot", "Compute-Following-Pilot.jl", 880, 80, ["job_id"]),
    ]:
        directory = OUTPUT / name
        protocol = tomllib.loads((directory / "Protocol.toml").read_text())
        code = common
        if name.startswith("following"):
            code += (ROOT / "code/following/Following-Controls-Lib.jl").read_text()
        code += (ROOT / "code/repaired" / script).read_text()
        assert protocol["source_digest"] == digest(code.encode()), name
        assert protocol["environment_digest"] == digest((ROOT / "code/Manifest.toml").read_bytes()), name
        assert protocol["manifest_digest"] == digest((directory / "Manifest.csv").read_bytes()), name
        summary = rows(directory / "Summary.csv")
        manifest = rows(directory / "Manifest.csv")
        identity = lambda row: tuple(row[key] for key in keys)
        assert len(summary) == len(manifest) == count, name
        assert len(set(map(identity, summary))) == count, name
        assert set(map(identity, summary)) == set(map(identity, manifest)), name
        checkpoints = sorted((directory / "checkpoints").glob("*.csv"))
        assert len(checkpoints) == blocks, name
        cached = [row for path in checkpoints for row in rows(path)]
        assert len(cached) == count, name
        assert {identity(row): row for row in cached} == {identity(row): row for row in summary}, name
        grouped = rows(directory / "Grouped.csv")
        expected_markets = 10 if name.startswith("following") else 50
        for row in grouped:
            # A cohort with no shares at exit has an undefined unsold fraction.
            if row["metric"] == "wind_followers_unsold_fraction":
                assert 0 <= int(row["markets"]) <= expected_markets, name
            else:
                assert int(row["markets"]) == expected_markets, name
        if name.startswith("following"):
            treated = [row for row in summary if row["mode"] != "none"]
            assert len(treated) == 800
            assert all(float(row["wind_followers_unsold_shares"]) == 0 and
                       float(row["control_wind_followers_unsold_shares"]) == 0 for row in treated)
        else:
            assert all(row["held_identity"] == "true" for row in summary)
        result["campaigns"][name] = {"runs": count, "blocks": blocks,
            "source_digest": protocol["source_digest"],
            "summary_sha256": digest((directory / "Summary.csv").read_bytes())}
    equivalents = {}
    for old, new in [("reserve-v1-full", "reserve-v2-full"),
                     ("following-reserve-v1-pilot", "following-reserve-v2-pilot")]:
        previous = sorted((OUTPUT / old / "checkpoints").glob("*.csv"))
        if previous:
            for path in previous:
                assert path.read_bytes() == (OUTPUT / new / "checkpoints" / path.name).read_bytes()
            equivalents[old + "_to_" + new] = len(previous)
    result["identical_prior_version_blocks"] = equivalents
    trips = rows(OUTPUT / "round-trips-v2/Summary.csv")
    assert len(trips) == 64
    assert all(abs(float(row["cohort_cash_gain"])) < 1e-6
               for row in trips if row["clearing"] == "reserve")
    result["round_trip_cases"] = len(trips)
    (OUTPUT / "verification.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    verify()
