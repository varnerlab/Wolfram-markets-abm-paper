"""Generate manuscript tables directly from revision summaries (no hand edits)."""
from pathlib import Path
import re
import numpy as np
import pandas as pd
D=Path(__file__).resolve().parents[1]/'data'
S=D.parents[1]/'paper-arxiv'/'sections'

def ci(r,name,d=3):
    return f'{r[name]:.{d}f} [{r[name+"_lo"]:.{d}f}, {r[name+"_hi"]:.{d}f}]'
def cap(x): return r'$\infty$' if np.isinf(x) else f'{x:g}'
def table(caption,label,header,rows,layout,small=r'\small',keep=True):
    result = '\n'.join([r'\begin{center}',r'\captionsetup{type=table,hypcap=false}',
        r'\caption{'+caption+'}',r'\label{'+label+'}',small,
        r'\begin{tabular}{'+layout+'}',r'\toprule',header+r' \\',r'\midrule',
        *[x if x == r'\midrule' else x+r' \\' for x in rows],r'\bottomrule',r'\end{tabular}',r'\end{center}',''])
    if keep:
        result=result.replace(r'\captionsetup',r'\begin{minipage}{\linewidth}\centering'+'\n'+r'\captionsetup')
        result=result.replace(r'\end{center}',r'\end{minipage}'+'\n'+r'\end{center}')
    return result

def finite_tables():
    path=D/'ModelB-Revision-FiniteSize-Scaling.csv'
    if not path.exists(): return
    df=pd.read_csv(path)
    rows=[]; fits=[]
    previous=None
    for _,r in df.iterrows():
        condition=(r.boundary_mode,r.market_maker_capacity)
        if previous is not None and condition!=previous:
            rows.append(r'\midrule'); fits.append(r'\midrule')
        previous=condition
        lead=f'{"Held" if r.boundary_mode=="hold" else "Endog."} & {cap(r.market_maker_capacity)} & {int(r.gridn)}'
        rows.append(f'{lead} & {int(r.interior_points)} & {ci(r,"f50")} & {ci(r,"transition_width")} & {ci(r,"susceptibility_peak",1)}')
        fits.append(f'{lead} & {r.logistic_f50:.3f} ({r.logistic_f50_se:.4f}) & {r.logistic_width:.3f} ({r.logistic_width_se:.4f}) & {r.susceptibility_peak_f:.3f}')
    t=table('Effect of grid size over 50 starting markets and 3,000 steps after the rule change. '
            'Brackets give 95\\% confidence intervals (CI) from seed resampling. $n_{\\rm int}$ counts fractions '
            'with $0.05<\\hat p<0.95$. Crossings use linear interpolation. The susceptibility '
            'maximum is over the sampled grid, and its interval includes reselection of that '
            'maximum within each bootstrap replicate. Intervals condition on the refined grid.',
            'tab:finite-size-scaling',r'Boundary & $h$ & $L$ & $n_{\rm int}$ & $f_{50}$ [95\% CI] & Width [95\% CI] & Peak $\chi_L$ [95\% CI]',
            rows,'llrrlll',r'\footnotesize\setlength{\tabcolsep}{3pt}',keep=False)
    # The existing appendix supplies the center/caption wrapper for Table S3.
    t=t[t.index(r'\caption'):t.rindex(r'\end{center}')]
    (S/'finite-size-table.tex').write_text(t)
    (S/'revision-fits-table.tex').write_text(table('Comparison of logistic fits with interpolation between tested fractions. '
        'Parentheses give seed-bootstrap standard errors (SE), not binomial standard errors treating '
        'fractions as independent. The last column is the location of the empirical susceptibility '
        'maximum: it is a sampled fraction with local grid resolution, not an interpolated optimum.',
        'tab:revision-fits',r'Boundary & $h$ & $L$ & Logistic $f_{50}$ (SE) & Logistic width (SE) & $f$ at peak',
        fits,'llrlll'))
    held=df[df.boundary_mode=='hold'].sort_values('gridn')
    low,high=held.iloc[0],held.iloc[-1]
    text=rf'''The fraction of traders needing the new rule could depend on how many
traders interacted and how much time their decisions had to influence
one another. We changed the rule at five grid sizes while keeping edge
traders in Hold, and found that larger markets needed a smaller fraction
of traders to receive the new rule for a majority to form
(Fig.~\ref{{fig:finite-size}}). We tested additional fractions near the
rise in majority probability to measure its position and width. After
3,000 steps, the fraction at which half the runs reached a majority,
$f_{{50}}$, fell from {low.f50:.3f} at $L=32$ to {high.f50:.3f} at
$L=128$. The additional fraction needed to raise majority probability
from 0.25 to 0.75 decreased from {ci(low,'transition_width')} to
{ci(high,'transition_width')}, with brackets giving 95\% confidence
intervals obtained by resampling the starting markets
(Fig.~\ref{{fig:finite-size}}A,C; Supplementary Table~\ref{{tab:finite-size-scaling}}).
We also measured variation between runs by multiplying the variance of
the final mean Sell fraction by the number of interior traders. The maximum value of this measure, susceptibility, rose from
{low.susceptibility_peak:.1f} to {high.susceptibility_peak:.1f} over the
same sizes (Fig.~\ref{{fig:finite-size}}B,D). Fitting smooth curves that
required probability to increase with rule adoption placed each
midpoint within 0.004 of the estimate from interpolation between tested
fractions, although the fitted widths were narrower when edge traders
stayed in Hold (Supplementary Table~\ref{{tab:revision-fits}}). Allowing
more time also changed the result: extending the $L=64$ runs from 3,000
to 9,000 steps lowered the fraction needed for half the runs to reach a
majority from about 0.178 to 0.167. The larger of the two endpoint grids still needed a lower fraction
when we adjusted observation time with grid size or changed the Sell
fraction required to count a transition, but the estimated midpoints
kept moving in longer runs
(Supplementary Table~\ref{{tab:revision-horizons}}). The sharper rise in
majority probability on larger grids therefore described the markets
over the time observed; it did not establish a threshold that would
remain fixed as observation time increased.
'''
    (S/'finite-size-results.tex').write_text(text)


def controls_tables():
    df=pd.read_csv(D/'ModelB-Revision-Controls-Grouped.csv')
    screen=df[df.campaign=='rule_screen']
    rows=[]
    base=[(19280//3**c)%3 for c in range(9)]
    for rule,sub in screen.groupby('rule'):
        changes=[c for c in range(9) if (int(rule)//3**c)%3!=base[c]]
        assert len(changes)==1
        c=changes[0];out=(int(rule)//3**c)%3
        probabilities=[]
        for f in (.15,.20,.25):
            x=sub[np.isclose(sub.f,f)].set_index('boundary')
            probabilities.append(f'{x.loc["hold","p"]:.2f} / {x.loc["endogenous","p"]:.2f}')
        rows.append((c,out,f'{c} & {base[c]} $\\to$ {out} & {int(rule)} & '+' & '.join(probabilities)))
    rows=[r[2] for r in sorted(rows)]
    text=r'''\subsection{Additional controls and sensitivity analyses}
\label{app:revision-controls}

We compared a one-time decision change with a lasting change in the
rule used for later decisions. We also varied the response to price
and the observation window to identify which parts of the model
supported widespread selling. These controls were added in response to
review and retained the original initialization and 1,000-step baseline.
Unless specified otherwise, they used $L=64$, $\lambda=0.02$,
$h=\infty$, and 3,000 post-intervention steps. Each simulation with a new rule or a one-time instruction to sell was
paired with a simulation that kept the original rule. We required
exact pre-intervention agreement of their lattice and Sell histories,
and checked the price prehistory for financial arms. Comparisons that kept edge traders in Hold and measured only decisions
used a faster implementation that updated decisions without calculating
trades or prices, using the same starting markets and decision rules. Tests matched
its full Sell history and final grid to the market simulator, and
1,800 overlapping archived seed/fraction outcomes also agreed. This implementation reproduced decisions when prices could not
influence traders, but did not calculate financial outcomes.

\paragraph{A one-time decision to sell and alternative decision rules.}
We set the selected traders to Sell once while keeping their rule for
later decisions unchanged
(Supplementary Table~\ref{tab:revision-pulse}). At activation, we wrote
Sell at the rule-switch target sites before orders executed and retained
Rule~19280 everywhere. This one-time change could therefore affect the first price after the
intervention, whereas assigning a new rule preserved that price and
changed later decisions. Fractions matched the number of targeted sites; sites
already in Sell did not change state. For $f=0.15,0.20,0.25$ under both
boundaries, no pulse reached a majority in 50 seeds (0/50; Wilson
upper bound 0.071). Persistent Rule~19286 activation yielded 0/50,
50/50, and 50/50, respectively. The Wilson lower bound for 50/50
was 0.929. Directing these traders to sell once therefore did not reproduce the
majorities caused by a lasting change in their decision rule. This comparison applied to the selected traders and timing; changing
decisions once in a different way could have different outcomes.

The rule screen tested all 18 ways to change one entry of Rule~19280
(Supplementary Table~\ref{tab:revision-rules}). Each of the nine
neighbor sums had two alternative outputs. We activated each resulting
rule at the same three fractions using 20 seeds under both boundaries.
At $f=0.20$, six rules produced majority crossings in all 20 seeds
under each boundary, while the other twelve produced none. Effective
changes included entries $c=2,3,4,5$ as well as the selected $c=1$
change. Every change that replaced a Buy or Hold response with Sell at
a neighbor sum from one to five produced a majority, as did the change
from Buy to Hold at a sum of three; the same Buy-to-Hold change at a
sum of one or two, every change that moved a response away from Sell,
and every change at a sum of six or more produced none. The input being altered and its replacement output therefore
mattered even when the number of changed entries was fixed. The screen
was descriptive and used no adjustment for multiple comparisons.
An observed 0/20 had a Wilson upper bound of 0.161, and 20/20 had
a lower bound of 0.839. The screen identified other rules capable
of producing majorities over the tested window without defining
a general rule for when a majority would form.
'''
    pulse = df[df.campaign == 'matched_pulse']
    pulse_rows = []
    for (boundary, fraction), group in pulse.groupby(['boundary', 'f']):
        arms = group.set_index('action')
        transient, persistent = arms.loc['sell_pulse'], arms.loc['rule']
        pulse_rows.append(
            f'{"Held" if boundary == "hold" else "Endogenous"} & {fraction:.2f} & '
            f'{int(transient.seeds)} & {ci(transient,"p",2)} & {ci(persistent,"p",2)}')
    pulse_table = table(
        'Asking selected traders to sell once (Sell pulse) versus keeping Rule~19286 in use. '
        'Both comparisons used the same traders and 3,000 steps after the change. '
        'Entries are majority probabilities with 95\\% Wilson intervals; '
        'the dealer was unlimited under both boundary conditions.',
        'tab:revision-pulse',
        r'Boundary & $f$ & Seeds & Sell pulse & Persistent rule', pulse_rows, 'lrrll')
    text = text.replace('\nThe rule screen tested', '\n'+pulse_table+'\nThe rule screen tested')
    text+=table('All changes to one response in Rule~19280. Each probability pair is '
                'edge traders kept in Hold / responding to price over 20 starting markets; the changed rule remained in use. '
                'The output labels are Buy $=0$, Hold $=1$, Sell $=2$.',
                'tab:revision-rules',r'Sum $c$ & Output change & Rule & $f=0.15$ & $f=0.20$ & $f=0.25$',rows,'rrrrrr',r'\footnotesize')
    band=df[df.campaign=='fixed_band']
    rows=[]
    for h,sub in band.groupby('h'):
        a=sub[sub.band=='adaptive'].iloc[0];f=sub[sub.band=='frozen'].iloc[0]
        rows.append(f'{cap(h)} & {ci(a,"p",2)} & {ci(f,"p",2)} & {a.mean_edge_sell:.3f} & {f.mean_edge_sell:.3f}')
    raw=pd.read_csv(D/'ModelB-Revision-band.csv')
    values=raw.pivot(index='seed',columns=['h','band'],values='transitioned').astype(float)
    a=values[(.1,'adaptive')]-values[(np.inf,'adaptive')]
    f=values[(.1,'frozen')]-values[(np.inf,'frozen')]
    rng=np.random.default_rng(20260905); idx=rng.integers(0,50,(2000,50))
    difference=(a-f).to_numpy(); lo,hi=np.quantile(difference[idx].mean(1),[.025,.975])
    text+=rf'''
\paragraph{{Fixing the width of the price range in which edge traders chose Hold.}}
The price range within which edge traders chose Hold changed as recent
prices became more or less variable, allowing the same departure from
the reference price to produce different decisions over time
(Supplementary Table~\ref{{tab:revision-band}}). We held the width of this range fixed at its value immediately before
the rule change.
Traders retained their $k_j$ values and the moving center continued to
update. The half-width $k_j\sigma_{{1000}}$ then stayed constant within
a path, although we continued calculating recent price variation for comparison. Each run with a fixed width shared the same history as its comparison
with an adjusting width, so the fixed values could differ across
starting markets and capacities. At $f=0.175$, the difference in majority probability between $h=0.1$ and $h=\infty$ changed from {a.mean():.2f} with adaptation
to {f.mean():.2f} with frozen widths. The difference between the adjusting-width and fixed-width
comparisons was {difference.mean():.2f}, with a 95\% seed-bootstrap interval
of [{lo:.2f}, {hi:.2f}]. Removing width adaptation therefore removed
the low-capacity advantage in the point estimates. The fraction of edge traders in Sell also changed. Even with the width
fixed, increasing capacity did not consistently raise or lower majority
probability, and individual probability intervals were wide. Adjusting
the width contributed to the smaller dealer's advantage but did not
explain every effect of capacity on majority probability.
'''
    text+=table('Adjusting versus fixed widths of the Hold range at $f=0.175$ over 50 starting markets. Probability brackets '
                'are 95\\% Wilson confidence intervals (CI). Sell is the mean fraction '
                'of active edge traders in Sell, averaged over steps after the rule change and starting markets.',
                'tab:revision-band',r'$h$ & Adaptive $p$ [95\% CI] & Frozen $p$ [95\% CI] & Adaptive Sell & Frozen Sell',rows,'rllll')
    imp=df[df.campaign=='price_impact'];rows=[]
    for _,r in imp.iterrows():
        rows.append(f'{cap(r.h)} & {r.impact:.3f} & {r.p:.2f} & {100*r.median_drawdown:.2f} & {r.median_rejection:.3f}')
    text+=r'''
\paragraph{Price-impact sensitivity.}
The price-impact coefficient determined how strongly the price changed
when completed trader buys and sells differed (Supplementary Table~\ref{tab:revision-impact}).
At $f=0.20$, we varied $\lambda$ over $\{0.005,0.02,0.05\}$ and
capacity over $h\in\{0.1,1,\infty\}$. A smaller coefficient reduced
the immediate price movement from a given imbalance. When edge traders were active, the changed price also affected the
ranges they used to decide whether to buy, hold, or sell. All 50 runs reached a Sell majority in every tested combination. Median
drawdown increased with capacity at each coefficient, although its
magnitude changed by a factor of seven to ten across the coefficient
range. Dealer resources thus
limited the price decline across a decade of impact choices, while
widespread selling persisted at this activation fraction throughout
the sweep. These uncalibrated coefficients describe model sensitivity;
they do not convert the simulated drawdowns into estimates for an
empirical market. Both the number of unmatched orders the dealer could fill and the
price change assigned to those trades determined the size of the
price decline.
'''
    text+=table('Changes in how strongly trades affected price at $f=0.20$, with edge traders responding to price, '
                '50 seeds per cell. Drawdown is a percentage; rejection is the '
                'fraction of post-switch eligible orders rejected.',
                'tab:revision-impact',r'$h$ & $\lambda$ & Transition $p$ & Median drawdown (\%) & Median rejection',rows,'rrrrr')
    horizon=pd.read_csv(D/'ModelB-Revision-Horizons-Scaling.csv');rows=[]
    for (L,post),sub in horizon.groupby(['L','post']):
        x=sub.set_index('threshold')
        rows.append(f'{int(L)} & {int(post):,}'.replace(',','{,}')+' & '+' & '.join(ci(x.loc[q],'f50') for q in (.4,.5,.6)))
    text+=r'''
\paragraph{Observation time and the fraction of traders required to sell.}
A longer observation window gave the altered local dynamics more time
to reach the selected Sell fraction
(Supplementary Table~\ref{tab:revision-horizons}). Held-boundary checks
used 50 seeds on $f=0.140,0.145,\ldots,0.250$, extended to 0.300 at
$L=32$ to bracket the short-horizon response. We compared the original
3,000 steps with $T_{\rm post}=3000(L/64)^z$ for $z=1,2$ at the
endpoint sizes. These windows were 1,500 and 750 steps at $L=32$,
and 6,000 and 12,000 at $L=128$. Both scalings preserved the ordering
of endpoint midpoints. At $L=64$, increasing the horizon from 3,000
to 9,000 steps lowered the majority midpoint from about 0.178 to 0.167.
Longer endpoint runs likewise continued to move the curve. Changing
the crossing criterion to 0.4 or 0.6 retained the endpoint ordering
and downward drift with time. At $L=64$ and 3,000 steps, the three
criteria gave midpoints of approximately 0.172, 0.178, and 0.186.
The qualitative size response persisted, but the numerical midpoint
depended on both the criterion and horizon. Neither these comparisons
nor the final 500-step mean established equilibration at any size.
'''
    text+=table('Changes in observation time and the required Sell fraction, with edge traders kept in Hold, over 50 starting markets. Entries are '
                'interpolated $f_{50}$ [95\\% seed-bootstrap interval] for each crossing '
                'criterion. The horizon grids are independent of adaptive refinement, '
                'so their interpolated values can differ slightly from Supplementary Table~\\ref{tab:finite-size-scaling}.',
                'tab:revision-horizons',r'$L$ & Post-switch steps & Criterion 0.4 & Criterion 0.5 & Criterion 0.6',rows,'rrlll',r'\footnotesize',keep=True)
    baseline=pd.read_csv(D/'ModelB-Revision-pulse.csv')
    baseline=baseline[(baseline.boundary=='endogenous')&(baseline.action=='rule')&np.isclose(baseline.f,.15)]
    text+=rf'''
\paragraph{{Baseline characterization and long no-switch paths.}}
The pre-switch paths remained mixed, with similar mean Sell occupancy
in the two windows preceding activation. Across 50 endogenous
unlimited-dealer seeds, the mean interior Sell fraction was
{baseline.pre_sell_early.mean():.4f} over steps 501--750 and
{baseline.pre_sell_late.mean():.4f} over steps 751--1,000. In the
latter window, the median within-seed return standard deviation was
${baseline.pre_return_std.median():.2g}$, and the median within-seed
1st and 99th percentiles were ${baseline.pre_return_q01.median():.2g}$
and ${baseline.pre_return_q99.median():.2g}$. The mean zero-return
fraction was {baseline.pre_zero_returns.mean():.3f}. These summaries described the starting markets without showing that
their statistical properties had stopped changing or matched an
observed market. We extended the first ten production seeds
under each boundary for 100,000 additional no-switch steps. None
crossed a majority (0/10 per boundary; Wilson upper bound 0.278
for the ensemble event probability). The extension followed existing
seeds and was not an independent replication. It showed that those
paths remained below a majority over that longer interval, while
leaving global stability and the distinction between temporary patterns and patterns that would persist indefinitely
unresolved.

\paragraph{{Fit and grid uncertainty.}}
A monotone logistic curve supplied a second estimate of transition
midpoint and width alongside empirical interpolation
(Supplementary Table~\ref{{tab:revision-fits}}). Interpolation used
the first upward crossing of each target probability and allowed
local decreases in the sampled curve. The logistic fit imposed a
monotone response as a working shape model. Both analyses used 2,000
bootstrap replicates that resampled whole seeds across fractions.
Keeping each seed together preserved the dependence arising from
shared initialization, so standard errors reflected seed variation
without treating fractions as independent observations. Each
susceptibility replicate reselected the maximum over the sampled grid.
Its location remained a sampled fraction with finite local resolution.
The resulting intervals measured uncertainty conditional on the refined
grid and observation horizon. They did not account for discretization
error, adaptive-grid selection uncertainty, or changes caused by
extending the horizon. No susceptibility exponent was estimated from
these finite-size summaries.
\input{{sections/revision-fits-table}}
'''
    # Keep generated tables in the post-reference table section; SI keeps prose.
    table_pattern = r'\\begin\{center\}.*?\\end\{center\}'
    tables = re.findall(table_pattern, text, flags=re.S)
    assert len(tables) == 5
    text = re.sub(table_pattern, '', text, flags=re.S)
    fits_input = r'\input{sections/revision-fits-table}'
    text = text.replace(fits_input, '')
    (S/'revision-tables.tex').write_text('\n\n'.join(tables) + '\n\n' + fits_input + '\n')
    (S/'revision-controls.tex').write_text(re.sub(r'\n{3,}', '\n\n', text).rstrip() + '\n')

if __name__=='__main__':
    finite_tables()
    controls_tables()
