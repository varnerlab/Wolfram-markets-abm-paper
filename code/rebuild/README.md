# Complete corrected manuscript rebuild

This workflow reruns every retained manuscript experiment with finite
constant-product reserve clearing, including all held-decision conditions.
It starts with empty data and figure directories. Earlier results remain
available for provenance but cannot enter this pipeline.

The protocol is
[2026-09-14-clean-manuscript-rerun.md](../../docs/superpowers/specs/2026-09-14-clean-manuscript-rerun.md).
The fixed manifest contains 45,910 full financial simulations. Adaptive
fraction refinement, selected trajectory extensions, figure histories, and
validation runs are recorded separately.

To repeat the exact executed study in a new directory, start from the
repository root (or from an extracted study snapshot):

```sh
python3 code/rebuild/ColdClone.py /path/to/new-study
cd /path/to/new-study
python3 code/rebuild/Run.py
python3 code/rebuild/FinalizeFigures.py
python3 code/rebuild/Verify.py
python3 code/rebuild/WriteManuscriptTables.py
python3 code/rebuild/WriteResults.py
python3 code/rebuild/WriteCaptions.py
python3 code/rebuild/Build.py
```

The original destination is `output/rebuilt/manuscript-reserve-v1/`. Once prepared,
`Run.py` can resume that same run using only its own completed phases and
checkpoints. It checks frozen source hashes before and after every phase,
and a writer lock prevents concurrent runners. `Status.json`, `logs/`,
`Manifest.csv`, and `code/data/Rebuild-Execution-Ledger.csv` record progress.
`Verify.py --partial` checks completed phases while computation continues.

The original simulator files are copied without modification. An explicit
wrapper selects `clearing=:reserve`, validates resources and conservation,
and records each completed full simulation. A finance-free held-decision
kernel is used only as a validation oracle. It supplies no production data.

The historical unlimited dealer is replaced by finite depth `h=100`.
The old independent exponential-impact sweep has no counterpart in this
mechanism, so its retained sensitivity question uses depths 40, 100, and
400, with initial slopes approximately `2/h`. All financial summaries use
post-switch orders. These specification and measurement changes are
recorded in the protocol.

The staged manuscript lives inside the isolated destination. Equations,
interpretation, captions, and Results must be checked against its outputs,
then the complete PDF must be built and visually reviewed before updating
the manuscript at the repository root. The scripts that reproduce the
historical standing-quote model remain under `code/model-b/` and
`code/revision/`; they are not the corrected rebuild entry points.

The destination must not exist. `ColdClone.py` copies source and protocol
files, never data, figures, checkpoints, or phase-completion records.
`Prepare.py` records the initial adaptation of historical drivers; do not
apply it again to already adapted source.
The recorded scheduling amendment changes task assignment only; both source
versions and its equivalence checks are retained in `source-versions/`.

After rendering and inspecting every page of the staged PDF, record its
SHA-256 and `all_pages_reviewed: true` in `Visual-Review.json`. Then run
`python3 code/rebuild/Build.py --install` from the repository root to install
that reviewed version, rebuild the root PDF, and verify the arXiv package.
`WriteAssessment.py` generates the outcome summary and updated review response
after verification and compilation. `Archive.py` packages reviewed source
and results, verifies every archived file against its hash, and writes
`Completion.json`; restart checkpoints are omitted. These steps do not
submit or publish the manuscript.
