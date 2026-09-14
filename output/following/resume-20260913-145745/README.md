# Confirmation restart, 13 September 2026

Both frozen confirmation campaigns were restarted at 15:10 EDT, with twelve
Julia simulation threads and one garbage-collection thread per campaign.
The diagnostic campaign includes all planned sensitivities.

At restart, the core campaign had 63 of 300 saved blocks (7,119 of 33,900
simulations), and the diagnostic campaign had 24 of 400 saved blocks (4,320
of 72,000 simulations). Existing checkpoint files are reused by the original
runners, which verify job IDs and implementation digests before accepting them.

The detached supervisor runs core analysis and figures after core computation
succeeds. It runs diagnostic analysis after diagnostic computation succeeds
and the core summary is available, allowing the analysis to compare matching
live runs. A failing command stops subsequent commands for that campaign and
is recorded in status.json. The supervisor does not restart after a reboot;
completed simulation blocks remain resumable.

## Files

- `status.json`: updated every five seconds; campaign commands, process IDs,
  current stages, saved-block counts, and exit codes.
- `core.log`: core computation, analysis, and figure output.
- `diagnostic.log`: diagnostic computation and analysis output.
- `supervisor.log`: supervisor error output.

## Recovery snapshot

The pre-restart snapshot contains 251 verified files, including saved local
changes, the Julia environment manifest, and every existing following checkpoint.
The snapshot and temporary supervisor are in:

`/private/tmp/wolfram-following-recovery-20260913-145745/`

The archive is `saved-work.tar.gz`. This local temporary snapshot is additional
to the original project files; the new work has not been committed to Git.

## Next research steps

1. Verify full manifest coverage and successful completion of both analyses.
2. Inspect the confirmation curves, paired contrasts, mechanism controls,
   sensitivity results, and exit-test outcomes.
3. Use the confirmed findings to select the planned main figures and supporting
   tables, then integrate the results into the manuscript.
