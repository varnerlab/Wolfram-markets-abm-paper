# Complete manuscript rebuild: recovery notes

User authorized rerunning every retained manuscript experiment, including
held decisions, with no historical cache inputs. Do not stop at the
previous proposal to reuse held results. Do not delete old archives.

The production process started at 2026-09-14 17:06:45 UTC. `Status.json`
is authoritative for completed/current phases. `logs/workflow.log` records
phase starts, `logs/<phase>.log` records errors, and
`code/data/Rebuild-Execution-Ledger.csv` records every completed full
simulation. The writer PID is in `.writer-lock/owner.json` while active.
The current script resumes only this isolated run; do not run two writers.

Frozen simulation and analysis sources are listed in `Protocol.json`.
Original `code/src/*.jl` files were copied byte-identically and called
through a reserve-only validation wrapper. Do not modify a frozen source
silently. Extra presentation/analysis changes can be versioned separately.

Root `code/rebuild/` contains new postprocessing scripts added after the
production source freeze:

1. `Run.py` runs all simulation, analysis, and original adapted figure phases.
2. `FinalizeFigures.py` expands Figure 6 probability/rejection axes to their
   full domains using `presentation-v2/`; no simulation or metric changes.
3. `Verify.py` checks full manifests, execution evidence, conservation,
   and newly recomputed held overlaps. `--partial` works during execution.
4. `WriteManuscriptTables.py` writes all eleven tables and supporting text.
   Table S2 now includes matched dealer drawdowns and paired differences.
5. `WriteResults.py` writes the six Results paragraphs (one separate finite-size
   input) and current example metadata.
6. `WriteCaptions.py` writes all six captions using current example metadata.

After production completes, run 2, 3, 4, 5, 6 in that order, then review
all numerical claims and prose, compile staged `paper-arxiv/Paper_v1.tex`,
render and inspect all pages, fix layout, and check warnings/references.
Only then install the staged manuscript and six figures into the root
paper directory, refresh output/pdf, and verify the arXiv package.
Archive final sources and hashes, update README and HOUSE_STYLE guidance,
and record the new assessment. Do not commit unless asked.

Staged Introduction, Methods, Appendix, Abstract, Discussion, and Conclusion
have been rewritten. Results and generated tables/captions are intentionally
awaiting the complete fresh outputs. The discussion may need adjustment
if supplementary outcomes differ from its current qualitative description.
The root manuscript remains the historical version for now; its complete
pre-rebuild archive is
`output/recovery/20260914-before-complete-manuscript-rebuild/manuscript-and-source.tar.gz`.

Confirmed main findings so far:
- Deep-reserve rule switch: 0/50 majorities at f=.10/.15; 50/50 at .20/.25.
  Conditional median onsets are 1070 and 311.5 post-switch steps.
- All dealer depths have 50/50 majorities at f=.20. Active median drawdown
  is .999853 at h=.1, .995192 at h=1, and .251496 at h=100.
- No-switch median drawdown is .770354 at h=.1 and .007467 at h=100.
  The manuscript must distinguish these baseline fluctuations from paired
  effects of the rule change; treated drawdown is not itself a causal effect.
- All 9,600 dealer simulations and 400 rule simulations match their manifests.
  Held dealer decisions and h=0 active/held identities agree.
- Figure 1 new exemplar seed is 14. Numerical Figure 4 selection should yield
  seeds 2,15,41,5,38. Figure 5 should yield seed 2. Do not retain the old seeds.
- The old small-dealer crash ceiling is invalid for reserve clearing.
  Positive depth couples funding with quote curvature. h=0 is a separate
  fixed-price matched-trade control. The old lambda sensitivity sweep is
  replaced by depths40/100/400 with initial slope approximately2/h.

The new bibliography entry angeris2022constant was verified against the
publisher chapter and Crossref. Crossref JSON is in `reference-checks/`.
Methods and algorithms were compiled separately for layout review in
/tmp/wolfram-rebuild-methods; no overfull boxes or BibTeX warnings.
The Figure 1 PDF was rendered and inspected successfully.


At 18:03 UTC, a scheduling-only amendment changed the one checkpoint loop
in `code/revision/Revision-Lib.jl` from :dynamic to :greedy before any
supplementary production phase started. Size and balance source files were
unchanged. Every numerical function and the simulator engine are unchanged.
A 480-check serial/dynamic/greedy comparison passed. Both library versions,
original Protocol.json, exact diff, test source, and log are archived in
`source-versions/scheduling-amendment/`. Protocol.json now records this
explicit amendment and the updated library hash. Verify.py audits the
amendment and proves it is exactly that one scheduling change.

Additional postprocessing files now include `Build.py` (staged compile,
then --install only after Visual-Review.json records the reviewed PDF hash).
The isolated helper scripts can be copied into code/rebuild after completion
under a separately hashed postprocessing inventory, because their names were
not in the original frozen inventory. Their STUDY path now works both from
the repository root and from the isolated snapshot.


Update at approximately 18:48 UTC:
- Balance (10,800) and all controls (7,460) completed; partial Verify passes.
- Refinement is active. Round 1 has 1,900 paired jobs (3,800 full sims).
- Pulse: all Sell-pulse arms 0/50; persistent arms .20/.25 50/50.
- Rule screen at .20: six alternatives 20/20 under both conditions, twelve 0.
- Band h=.1 minus h=100: adaptive -.06, frozen -.26; paired contrast .20,
  95% bootstrap CI [-.08,.50]. Results and Discussion explicitly avoid
  resolving its sign or claiming width adaptation explains the depth effect.
- Depth40/100/400 median DD=.486153/.251496/.070790; p=1 each.
- Long no-switch controls 0/10 under both conditions.
- Figure6 presentation overlay now has full probability range, logarithmic
  rejection axes (all medians positive), and logarithmic DD axes spanning
  all medians (minimum 2.659%); no zero markers. Extra top margin fixes
  clipped A/B panel letters. Latest preview inspected successfully at
  /tmp/wolfram-rebuild-qa/figure6-v2-margin.png. FinalizeFigures.py now has
  --preview-balance. Final call still required after production.
- Figure2 overlay adds top margin around its probability-difference title.
- All Methods equation labels now have references. Clarified common execution
  price versus quote. Unreferenced conservation identities are unnumbered.
- WriteResults.py now describes verified held final states/onsets/means,
  rather than claiming exhaustive grid-history recording across every depth.
- WriteManuscriptTables.py formats very small rejection medians scientifically.
- Verify.py now parses the 6028 and 79 test counts, independently recomputes
  Figure4 selection, checks all nine figure-history ledger jobs, and requires
  every production phase before final verification. These new final checks
  await their inputs. Cash discrepancy in the generated validation uses TeX
  scientific notation.
- Build.py --install now copies six PDFs into root code/figs as well as paper.
- New WriteAssessment.py will generate ASSESSMENT.md and a replacement
  peer-review-response.md from verified outputs after compilation. Review it
  against actual results, then install the response at root.
- Root run_all.sh now rejects legacy all/figures/revision modes once Build.json
  records installed=true, preventing historical outputs from overwriting the
  corrected manuscript. Bash syntax check passed. Frozen snapshot unaffected.
- Added ignore pattern for rebuilt checkpoint directories; retained summaries.
- code/rebuild/README now documents cold cloning, postprocessing, PDF review,
  and installation. Copy all new, non-frozen postprocessing files into the
  study under a separate SHA inventory at completion.
- Runtime-Environment.json records Julia/Python/library versions and threads.


Refinement completed at 18:59:43 UTC after exactly 5,000 full simulations
(1,900 pairs in round 1 and 600 in round 2). All fifteen curves have at least
five interior fractions; refined summary has 11,500 rows. Horizons is active.
At 19:14:47 UTC, horizon ledger counts were L32=2300, L64=2300, L128=242;
there are 2300 L128 simulations and an additional 1000 short L32 runs in
this campaign. The largest-grid stage is much slower; keep the runner going.

To preflight manuscript layout while long simulations run, the frozen
Analyze-Revision.py was run early on the completed finite and control data
(horizon output did not yet exist), followed by the frozen tables and Figure3
scripts. Logs: analysis-preview.log, tables-preview.log, figure3-preview.log.
The official later phases still rerun these computations. Compare their
outputs with Analysis-Preview-SHA256.json after the final generators run.
All bootstrap samples bracket finite-size crossings. Held f50 at L32=.2158333,
L64=.1776667, L128=.166; widths .0231667,.015,.0077904; peaks21.152,110.488,241.187.

WriteManuscriptTables.main_tables() and finite_tables(with_results=False)
were called for layout preview. Their staged S1--S4 and fit table are now
fresh; other sections still await the full writer. The preview PDF
/tmp/wolfram-rebuild-tables/Table-layout-preview.pdf has three pages,
no LaTeX warnings/overfull boxes, and all pages were visually inspected.
Figure3 preview /tmp/wolfram-rebuild-qa/figure3.png was inspected. FinalizeFigures
now also adds top margin to Figure3, alongside the Figure2 and Figure6 fixes.
Its final call after production remains mandatory.

New completed-state README drafts are staged in documentation/README.md and
code-README.md. Copy to root README.md and code/README.md only after successful
installation. Root HOUSE_STYLE introductory status also needs final update.
Build.py now hashes local .sty/.cls files and checks root copies match before
installation. ColdClone and Verify support Postprocessing-Sources.json (not
yet created): schema {files:{relative_source_path:sha256,...}}. Copy and hash
all new postprocessing helpers into the study after final edits; none belong
to the original frozen source inventory. The supplemental inventory should
be included in the final archive and copied into subsequent cold clones.


Latest documentation and verification updates:
- A separate old/new comparison now verifies all five refined held curves:
  f50, widths, susceptibility peaks, and their 95% intervals are exactly
  unchanged. Record: comparisons/held-refined-comparison.json. This is an
  external diagnostic, never a manuscript input. WriteAssessment reports it.
- Verify now also checks held resource onset and final Sell means across all
  27 financial combinations. Partial verification passed after that change.
- WriteManuscriptTables labels S2A "Rule switch", avoiding "adoption".
- New Archive.py requires completed computation, verified source, and a
  matching all-page visual review. It writes Artifact-Manifest.json, packages
  source/results without restart checkpoints, verifies every tar member's
  hash, and writes Completion.json with the archive SHA and simulation count.
  Include Archive.py in the postprocessing source copy/hash inventory.
- code/rebuild/README now makes ColdClone the default clean-repeat entry;
  Prepare is described as the original adaptation only. ColdClone also copies
  docs/. The original clean-rerun spec has been copied into the study's docs/
  so the archived workflow's protocol link resolves.
- Largest-grid horizon simulations were 1,064/2,300 at 19:37:17 UTC, with
  L32=2,300 and L64=2,300 completed. A final 1,000 short L32 simulations remain
  after the large block. Current large-grid rate implies roughly 30--40 more
  minutes; do not abandon the run or alter its simulator for speed.
- Production exec session remains 48052. Temporary previews completed:
  27815 (analysis), 96566 (tables), 50543 (Figure3), 27442 (table PDF).


Finalization after crash recovery, 14 September 2026:
- All computation completed at 20:14:39 UTC, with 51,056 ledger records.
- FinalizeFigures, full Verify, all three manuscript writers, and Build completed.
- All 29 PDF pages were reviewed; all changed pages were reinspected after prose fixes.
- Two independent section reviews found no numerical errors; all identified wording and evidence-reference issues were resolved and rechecked.
- The corrected manuscript and six figures are installed. The arXiv source archive compiled in isolation with identical PDF text.
- The shareable PDF is output/pdf/Wolfram-markets-revised.pdf at the repository root.
- All 29 installed PDF pages are pixel-identical to the reviewed staged pages.
- Twelve additional postprocessing files are copied and hashed separately from the 132 frozen production sources.
- ColdClone validation checked every source hash and empty initial data/figure directories; no extra simulation was started.
- Root README, code README, HOUSE_STYLE, MEMORY, and peer-review-response now describe the finished study.
- Legacy output-overwrite guards passed; the final Completion record keeps the guard active after later staged-only PDF builds.
- The six pre-existing whitespace lines in historical code/run_all.log were retained; other tracked changes pass whitespace checks.
- No active simulation or manuscript work remains. Completion.json is the authoritative final archive record. No commit was made.
