"""Validate frozen inputs, test, and run/resume the lazy-revision and interior-technical study."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("study", type=Path)
    parser.add_argument("--threads", type=int, default=12)
    args = parser.parse_args()
    study = args.study.resolve()
    protocol = json.loads((study / "Protocol.json").read_text())

    def check():
        for name, expected in protocol["frozen_files"].items():
            assert hashlib.sha256((study / name).read_bytes()).hexdigest() == expected, name

    check()
    lock = study / ".writer-lock"
    lock.mkdir()
    (lock / "owner.json").write_text(json.dumps(dict(pid=os.getpid())))
    env = os.environ.copy()
    env["JULIA_PKG_OFFLINE"] = "true"
    command = ["julia", "--project=" + str(study / "code"), "--startup-file=no",
               "--threads=" + str(args.threads), "--gcthreads=1"]
    status = dict(version=protocol["version"], state="testing", pid=os.getpid())

    def save():
        status["updated_utc"] = datetime.now(timezone.utc).isoformat()
        (study / "Status.json").write_text(json.dumps(status, indent=2) + "\n")

    try:
        save()
        for phase, script, argv in [
                ("testing", study / "code/test/test_revision_interior_technical.jl", []),
                ("running", study / "code/variants/Run.jl", [str(study)])]:
            check()
            status["state"] = phase
            save()
            with (study / "logs" / (phase + ".log")).open("a") as log:
                subprocess.run(command + [str(script)] + argv, cwd=study, env=env,
                               stdout=log, stderr=subprocess.STDOUT, check=True)
            check()
        status["state"] = "analyzing"
        save()
        subprocess.run([sys.executable, str(study / "code/variants/Analyze.py"), str(study)],
                       check=True)
        check()
        status["state"] = "complete"
        save()
    except BaseException as error:
        status.update(state="failed", error=str(error))
        save()
        raise
    finally:
        (lock / "owner.json").unlink()
        lock.rmdir()


if __name__ == "__main__":
    main()
