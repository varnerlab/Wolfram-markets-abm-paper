# Discussion cold-read audit

Review only. No manuscript edits, rebuild, or simulations. The current Discussion has six paragraphs and 1,586 guard-counted prose words; both remain unchanged. The existing PDF was inspected on pages 10–12 and showed no layout defects in this section. This is a completed audit with unresolved prose findings, not a clean cold-read verdict on revised text.

## Fresh-reader counts

| Round | Reader context | Severity 3 | Severity 2 | Severity 1 |
|---|---|---:|---:|---:|
| 1 | Abstract, Introduction, Methods, Results | 0 | 4 | 1 |
| 1 | Abstract and Introduction; skipped Methods/Results | 0 | 3 | 0 |

Eight raw reader flags describe seven distinct concerns. The full reader's P1.S8 and skim reader's SKIM-1 overlap on rules versus intentions spreading, at two locations. The band definition, unnamed outcome, and retained baseline differences are distinct flags grouped below because one in-place repair can address them. The additional literature-citation finding below is an editor finding, not included in reader counts. Each context used a separate fresh agent; raw reports are preserved.

## Findings and concrete repair directions

1. **Rules do not spread; selling intentions do (lines 24–27, 51–53).** Full P1.S8 (INCONSISTENT, severity 2) and SKIM-1 (REFERENT, severity 2). “Assigned rules and their spread” contradicts the sentence's own statement that rules are not transmitted. “Spread of changed responses” repeats the ambiguity. In-place clarity repair: use “assigned rule changes and the spread of selling intentions” in P1 and “spread of selling through neighboring decisions” in P2. Methods states that only selected traders receive Rule 19286 and all others retain Rule 19280. No added mechanism or new simulation is needed.

2. **Do not exclude selling from the price mechanism (lines 6–10).** Full P1.S3 (INCONSISTENT, severity 2). “Rather than on the Sell majority itself” can imply that selling does not contribute to the decline. The result establishes that majority status alone is insufficient, not that selling and prices are causally disconnected. In-place scope repair: “the size of the resulting price decline also depended on trader resources and the dealer's reserve curve.” Keep the distinction between intentions, feasible trades, and price response. Evidence: Results dealer/resource comparisons and Methods execution/quote equations.

3. **Name the condition in the visual examples (lines 29–34).** Full P2.S4 (REFERENT, severity 2). The paragraph moves directly from held technical traders to “the displayed markets,” although Figure 4 uses active technical traders. This can make the images appear to show the held experiment. In-place referent repair: “In the displayed markets with active technical traders, ...” Preserve the separate evidentiary roles: held results establish no need for price feedback; active examples illustrate growth and merger. Verified against Figure 4's caption and the Methods example-selection paragraph.

4. **Make the band-control interpretation understandable within Discussion (lines 88–94).** SKIM-2 (UNDEFINED, severity 2), SKIM-3 (REFERENT, severity 2), and full P4.S7 (REFERENT, severity 1). A reader who skips Methods lacks the meaning of band width; “one possible contributor,” “paired contrast,” and “depth difference” do not name the outcome. The retained baseline differences also lack a referent. In-place clarity repair: explain width as the distance of Buy/Sell thresholds from the moving reference price, say that freezing it tested differences in Sell-majority probability across dealer depths, and identify the retained differences as widths at the end of the baseline across depths and starting markets. Replace the existing opaque wording rather than add a Methods paragraph. Exact threshold equations, parameter values, numerical contrast estimates, and bootstrap procedure are OPTIONAL DETAIL here. Evidence: Methods technical-trader definition and revision-controls.tex's band-control paragraph; the reference price continues to update while the departure scale is frozen. The unresolved scientific result remains unresolved.

5. **Distinguish individual incentive from collective outcome (lines 114–119).** Full P5.S5 (REREAD, severity 2). A dominant strategy that “lowered wealth ... for all” appears contradictory without the comparison groups. In-place clarity repair: “Adding technical rules benefited an individual trader, but adoption by all traders lowered wealth and raised volatility relative to a market using only fundamental rules.” This is a proposed replacement for the first claim, retaining its citation; the separate claim about revision-rate equilibrium remains separate. Verified against the cited Joshi–Parker–Bedau working paper, whose abstract and payoff table distinguish unilateral advantage from the all-adopt versus all-fundamental comparison. Additional model mechanics are OPTIONAL DETAIL. Primary source: https://sfi-edu.s3.amazonaws.com/sfi-edu/production/uploads/sfi-com/dev/uploads/filer/4d/a0/4da03e0d-f3ad-4e63-a884-cdb1029659cc/98-12-115.pdf

6. **The literature contrast does not fit every attached citation (lines 97–100).** Editor finding, substantive evidence/wording issue. The sentence characterizes its cited models as assigning a separate impact coefficient to completed-order imbalance. Farmer, Patelli, and Zovko (2005) instead model random order placement and cancellation in a continuous double auction; their impact response depends on stored limit-order density. Its model description and Market Impact section do not support using it as an example of the stated assigned-coefficient mechanism. Narrow the comparison to an accurately described model, or use the citations in a broader sentence about how different execution mechanisms connect order flow to prices. Do not discard an otherwise relevant paper merely to retain the current contrast. This targeted check does not establish whether the entire Kyle/Bouchaud citation group supports a different replacement claim; that attribution remains unverified. Primary source: https://oms-inet.files.svdcdn.com/production/files/PredicitivePower.pdf?dm=1553075489 (model description pp. 2254–2255; impact pp. 2257–2258); accessible author preprint: https://arxiv.org/html/cond-mat/0309233

## Section-purpose and structure decisions

All six existing paragraph purposes are appropriate: study interpretation; spatial spread and finite-observation limits; dealer mechanism; financial feedback; comparison with other models; limitations. No finding requires splitting, merging, moving claims between paragraphs, adding a heading, or expanding the section. The literature paragraph is long but its length alone is not a defect; the repair is the comparison within it. The frozen-band qualification belongs in the feedback paragraph, with its outcome named. No reader requested removal of an entire paragraph. No scientific ambiguity was silently resolved.

Proposed substitutions are suggestions only, not a reviewed replacement section. If applied, the final saved text needs a new fresh-reader round, original-snapshot structure/length and invariant checks, and a normal build with visual inspection. The original 1,586-word baseline remains the default ceiling for any later authorized revision.

## Verification and limits

- Baseline hash and direct byte comparison confirm discussion.tex is unchanged.
- Structure guard: 6 → 6 paragraphs; 1,586 → 1,586 words; pass.
- Invariant checker: unchanged. Local voice checker raised no flags; this did not override reader findings.
- Existing PDF pages 10–12 visually inspected; no rebuild performed because the task is an audit.
- Local evidence checked: fixed rule assignments, pulse setup, active/held distinction, Figure 4 condition, reserve execution, and frozen-band interpretation.
- External primary sources checked only for the two specific literature statements above. This was not a complete bibliography verification or technical audit.
- All proposed prose repairs remain unapplied, and no claim scope or citation was changed in the manuscript.
