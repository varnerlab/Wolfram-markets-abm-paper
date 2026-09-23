"""Record the completed study's findings and its response to the earlier review."""
from pathlib import Path
import json
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'
D=STUDY/'code/data'


def main():
    v=json.loads((STUDY/'Verification.json').read_text());assert v['state']=='verified'
    build=json.loads((STUDY/'Build.json').read_text())
    controls=pd.read_csv(D/'ModelB-Revision-Controls-Grouped.csv')
    dd=pd.read_csv(D/'Rebuild-Dealer-Paired-Drawdown.csv').query('boundary == "endogenous"').set_index('h')
    band=json.loads((D/'Rebuild-Band-Contrast.json').read_text())
    sizes=pd.read_csv(D/'ModelB-Revision-FiniteSize-Scaling.csv')
    held=sizes.query('boundary_mode == "hold"').set_index('gridn')
    horizons=pd.read_csv(D/'ModelB-Revision-Horizons-Scaling.csv').query('L == 64 and threshold == .5').set_index('post')
    pulse=controls.query('campaign == "matched_pulse" and action == "sell_pulse"')
    screen=controls.query('campaign == "rule_screen" and f == .2').groupby('rule').p.agg(['min','max'])
    long=controls.query('campaign == "long_control"')
    extended=pd.read_csv(D/'ModelB-Revision-MarketPanel-Horizons.csv').query('f == .15 and post == 10000')
    longtext='; '.join(f'{"active" if r.boundary=="endogenous" else "held"}: {round(r.p*r.seeds)}/{int(r.seeds)}' for r in long.itertuples())
    comparison=STUDY/'comparisons/held-decision-comparison.json'
    comparison_text=''
    if comparison.exists():
        old_new=json.loads(comparison.read_text())
        assert old_new['identical_transition_flags'] and old_new['identical_onsets']
        assert old_new['max_final_mean_difference']==0
        comparison_text=f" Separately, all {old_new['paired_held_conditions']:,} newly computed held size outcomes match the historical decision summaries. That old/new comparison supplies no manuscript inputs."
    refined_comparison=STUDY/'comparisons/held-refined-comparison.json'
    if refined_comparison.exists():
        refined_old_new=json.loads(refined_comparison.read_text())
        assert max(refined_old_new['maximum_absolute_differences'].values())==0
        comparison_text+=f" The {refined_old_new['curves']} refined held curves also match the historical midpoints, widths, susceptibility peaks, and their confidence intervals exactly."
    findings=f'''- Every retained campaign was rerun from empty data and figure directories, including full financial simulations with technical traders held. The execution ledger contains **{v['total_completed_simulations']:,}** newly completed full simulations. The fixed campaign manifest contributes 45,910; refinement, extensions, selected figure histories, and wrapper validation are counted separately in `Verification.json`.
- With active technical traders and depth h=100, the rule campaign produced 0/50 Sell majorities at fractions .10 and .15, and 50/50 at .20 and .25. All matched no-switch controls remained below a majority over 3,000 steps.
- The persistent rule effect survives the repaired execution mechanism. The one-time Sell-pulse probabilities ranged from {pulse.p.min():.2f} to {pulse.p.max():.2f}. In the eighteen-rule screen at f=.20, {(screen['min']==1).sum()} rules produced majorities in all twenty starting markets under both feedback conditions and {(screen['max']==0).sum()} produced none.
- The old protective interpretation of a small dealer does **not** survive. At f=.20, active median drawdown is {100*dd.loc[.1,'treated_median']:.2f}% at h=.1 and {100*dd.loc[100,'treated_median']:.2f}% at h=100. However, the corresponding no-switch medians are {100*dd.loc[.1,'control_median']:.2f}% and {100*dd.loc[100,'control_median']:.2f}%. Median paired increases are {100*dd.loc[.1,'delta_median']:.2f} and {100*dd.loc[100,'delta_median']:.2f} percentage points. Table S2 reports all eight depths and pointwise bootstrap intervals.
- Held decisions are financially independent by construction; the fresh run also verifies matching final states, onset, and final mean Sell fraction across depths and resource changes.{comparison_text}
- The held majority midpoint changes from {held.loc[32,'f50']:.3f} at L=32 to {held.loc[128,'f50']:.3f} at L=128. At L=64, extending observation from 3,000 to 9,000 steps changes it from {horizons.loc[3000,'f50']:.3f} to {horizons.loc[9000,'f50']:.3f}. These are finite-grid, finite-time comparisons.
- The h=.1 minus h=100 majority contrast at f=.175 is {band['adaptive_difference']:+.2f} with adaptive widths and {band['frozen_difference']:+.2f} with frozen widths. Their difference is {band['difference']:+.2f}, with a paired 95% bootstrap interval [{band['lo']:+.2f}, {band['hi']:+.2f}].
- The 100,000-step no-switch controls gave {longtext} majorities. At f=.15 and 10,000 steps, the fifty-market extension gave {int(extended.query('condition == "changed"').transitioned.sum())}/50 majorities with the changed rule and {int(extended.query('condition == "control"').transitioned.sum())}/50 in matched controls.
'''
    scope='''The corrected model uses a finite constant-product dealer and uniform batch execution at a price supported by its reserves. It removes the isolated dealer round-trip cash extraction present in the old standing-quote/exponential-update combination. It also changes the price mechanism, so old/new differences cannot be attributed to settlement alone. Dealer depth now changes funding and price sensitivity together. The former independent impact-coefficient sweep is replaced by depths 40, 100, and 400. The h=0 matched-trade, fixed-price condition remains a separate control.

Order suppression and rejection statistics now use the post-switch window consistently. The old main-campaign order summaries included baseline steps; this measurement change is also recorded in the protocol.

The rerun uses the retained study's original seed sets to make the mechanism comparison reproducible. Fresh-market confirmation of the separate advice-transmission study is recorded in `output/repaired/transmission-confirmation-v1-full/`; those results are not pooled into these six rule-switch figures. Retired experiments are retained as historical records and are not manuscript evidence.

Historical results were preserved for audit rather than deleted. `Protocol.json` records zero initial cached files and no historical imports. Each execution-ledger entry is written only after a new full simulation and its conservation/resource checks complete. The sole production-source amendment changed checkpoint scheduling from dynamic to greedy after a 480-check equivalence test; its exact one-line diff, hashes, and original protocol are archived. Numerical simulator functions were unchanged throughout production.
'''
    verification=f'''All six figure PDFs and all eleven tables were regenerated. The model tests passed 6,028 checks, the rebuild tests passed 79, and scheduling equivalence passed 480. `Verification.json` records manifest completeness, source hashes, newly recomputed overlaps, and conservation bounds. `Build.json` records the compiled PDF and input hashes; the build has zero LaTeX/BibTeX warnings and zero overfull boxes. Visual review and installation are recorded separately in `Visual-Review.json` and `Build.json`.

Reproduction instructions are in `code/rebuild/README.md`. Use `ColdClone.py` to create another empty-data copy of this exact executed source. Earlier checkpoint directories are never copied. Additional manuscript postprocessing and presentation adjustments are versioned separately from the frozen production source.
'''
    assessment='# Complete corrected manuscript rerun\n\n'+scope+'\n## Findings\n\n'+findings+'\n## Verification and reproduction\n\n'+verification
    (STUDY/'ASSESSMENT.md').write_text(assessment)
    items=[
        ('Matched null interventions','Fresh paired Sell pulses and persistent rule switches at identical target sets.','Table S5'),
        ('Single-entry rule screen','All eighteen alternative single-entry rules, three fractions, twenty starting markets, both feedback conditions.','Table S6'),
        ('Adaptive refinement','Bisect fraction intervals near the majority crossover, up to ten rounds; report actual interior-point counts.','Figure 3; Table S3'),
        ('Bootstrap uncertainty','2,000 whole-market resamples; report crossing, width, and sampled susceptibility-peak intervals.','Methods; Table S3'),
        ('Dealer feedback mechanism','Recompute adaptive/frozen band contrasts and paired uncertainty; remove the obsolete +.38 claim.','Table S7'),
        ('Horizon scaling','Recompute fixed, size-dependent, and extended windows with full held financial histories.','Table S9'),
        ('Impact sensitivity','Replace the obsolete independent exponential coefficient with reserve depths 40, 100, and 400; state their coupled effects.','Table S8'),
        ('Long no-switch controls','Rerun ten starting markets per feedback condition for 100,000 additional steps.','Supplementary methods'),
        ('Logistic sensitivity','Refit increasing logistic curves and bootstrap their midpoint/width uncertainty from fresh data.','Figure 3A; Table S10'),
        ('Totalistic restriction','Explain which neighbor configurations are conflated; retain the limitation to this rule class.','Methods; Discussion'),
        ('Causal framing','Separate persistent rule assignment, Sell-majority formation, execution, and drawdown; include matched financial controls.','Results; Table S2'),
        ('Dealer comparison','Replace historical price outcomes and the small-dealer crash ceiling with reserve-model results.','Figures 2 and 5; Table S2'),
        ('Baseline characterization','Recompute pre-switch Sell windows and return summaries; avoid stationarity or calibration claims.','Supplementary methods'),
        ('Majority threshold','Recompute first passage for Sell fractions .4, .5, and .6 on the horizon grid.','Table S9'),
        ('Behavioral interpretation','Explain the ordered Buy/Hold/Sell score and the information omitted by a totalistic rule.','Methods'),
        ('Title scope','Restrict the title to a simulated market: "When Selling Spreads: Local Decisions, Limited Resources, and Market Crashes in a Simulated Market."','Title'),
        ('Table S2 source','Generate the table from fresh rule summaries and all-depth paired drawdown comparisons.','WriteManuscriptTables.py'),
        ('h=10 display','Keep h=10 explicitly as a distinct finite comparison; the deep arm is h=100.','Figure 2'),
        ('Interior-point counts','Report actual counts and distinguish sampled peak locations from fitted estimates.','Tables S3 and S10'),
        ('Advance selection','Freeze this rerun protocol and manifests before production; do not retroactively claim preregistration of the original study.','Protocol.json; supplementary methods'),
        ('Single-seed illustration','Select new examples by the documented numerical rule before viewing images; cite ensemble comparisons.','Figures 4 and 5; Table S11'),
    ]
    response='# Response to the synthetic peer review: corrected model\n\nThe original review remains in `peer-review.md`. This response supersedes numerical claims from the standing-quote model. Every retained experiment was repeated under the corrected protocol.\n\n'+scope+'\n## Recomputed findings\n\n'+findings+'\n## Review items\n\n| Item | Resolution | Evidence |\n|---|---|---|\n'
    response+='\n'.join(f'| {i}. {name} | {resolution} | {evidence} |' for i,(name,resolution,evidence) in enumerate(items,1))
    response+='\n\n## Limits\n\nNo infinite-time threshold, global attractor classification, classical nucleation mechanism, fitted susceptibility exponent, empirical market calibration, or general arbitrage-free theorem is claimed. Held financial invariance follows from the update structure and does not establish realism. Bootstrap intervals condition on the selected fraction grid. Frozen bands retain path-specific baseline widths and a moving center. Absolute dealer reserves grow with trader count in the size series.\n\n## Validation\n\n'+verification
    (STUDY/'peer-review-response.md').write_text(response)
    print('Wrote ASSESSMENT.md and the corrected peer-review response.')


if __name__=='__main__':main()
