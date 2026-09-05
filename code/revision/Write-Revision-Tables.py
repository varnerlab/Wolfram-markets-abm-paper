"""Generate manuscript tables directly from revision summaries (no hand edits)."""
from pathlib import Path
import numpy as np
import pandas as pd
D=Path(__file__).resolve().parents[1]/'data'
S=D.parents[1]/'paper-arxiv'/'sections'

def ci(r,name,d=3):
    return f'{r[name]:.{d}f} [{r[name+"_lo"]:.{d}f}, {r[name+"_hi"]:.{d}f}]'
def cap(x): return r'$\infty$' if np.isinf(x) else f'{x:g}'
def table(caption,label,header,rows,layout,small=r'\small',keep=False):
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
    t=table('Refined finite-size response over 50 seeds and 3,000 post-activation steps. '
            'Brackets give 95\\% seed-bootstrap intervals. $n_{\\rm int}$ counts fractions '
            'with $0.05<\\hat p<0.95$. Crossings use linear interpolation. The susceptibility '
            'maximum is over the sampled grid, and its interval includes reselection of that '
            'maximum within each bootstrap replicate. Intervals condition on the refined grid.',
            'tab:finite-size-scaling',r'Boundary & $h$ & $L$ & $n_{\rm int}$ & $f_{50}$ [95\% CI] & Width [95\% CI] & Peak $\chi_L$ [95\% CI]',
            rows,'llrrlll',r'\footnotesize\setlength{\tabcolsep}{3pt}')
    # The existing appendix supplies the center/caption wrapper for Table S3.
    t=t[t.index(r'\caption'):t.rindex(r'\end{center}')]
    (S/'finite-size-table.tex').write_text(t)
    (S/'revision-fits-table.tex').write_text(table('Logistic shape sensitivity on the refined grids. '
        'Parentheses are seed-bootstrap standard errors, not binomial standard errors treating '
        'fractions as independent. The last column is the location of the empirical susceptibility '
        'maximum: it is a sampled fraction with local grid resolution, not an interpolated optimum.',
        'tab:revision-fits',r'Boundary & $h$ & $L$ & Logistic $f_{50}$ (SE) & Logistic width (SE) & $f$ at peak',
        fits,'llrlll'))
    held=df[df.boundary_mode=='hold'].sort_values('gridn')
    low,high=held.iloc[0],held.iloc[-1]
    text=rf'''The transition survived changes in lattice size on the refined grids
(Fig.~\ref{{fig:finite-size}}). Every condition had at least five sampled
fractions with empirical probability strictly between 0.05 and 0.95, and none
of its matched no-switch controls transitioned within 3,000 post-switch steps.
Under the held boundary, $f_{{50}}$ moved from {ci(low,'f50')} at $L=32$
to {ci(high,'f50')} at $L=128$, where brackets denote 95\%
seed-bootstrap intervals. The corresponding widths were
{ci(low,'transition_width')} and {ci(high,'transition_width')}
(Table~\ref{{tab:finite-size-scaling}}). The peak susceptibility increased
from {ci(low,'susceptibility_peak',1)} to {ci(high,'susceptibility_peak',1)}.
Its sampled location moved from $f={low.susceptibility_peak_f:.3f}$ to
$f={high.susceptibility_peak_f:.3f}$. Logistic fits provide a separate
shape sensitivity check (Table~\ref{{tab:revision-fits}}), without assuming
that the empirical curve is exactly logistic.

The refined analysis supports a sharper finite-time response at the largest
size. Bootstrap intervals quantify seed variation conditional on the grid;
they do not remove interpolation error or establish an asymptotic critical
point. Size-scaled horizons preserve the endpoint midpoint ordering but
continue to shift the transition curves (Appendix~\ref{{sec:revision-controls}}).
The midpoint is therefore a function of both lattice size and observation
horizon, rather than a size-only stability threshold.
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
    text=r'''\subsection{Review-motivated controls and sensitivity analyses}
\label{sec:revision-controls}

These follow-up experiments retain the original initialization and 1,000-step
baseline. Unless specified otherwise, they use $L=64$, $\lambda=0.02$,
$h=\infty$, and 3,000 post-intervention steps. Every new rule or pulse arm
is paired with a dormant baseline arm, with pre-intervention lattice and
Sell histories checked exactly; financial arms additionally check the price
prehistory. Held-boundary experiments that need only lattice observables use
an allocation-free kernel with the production setup draws and rule tables.
Tests match its full Sell history and final grid to the market simulator;
1,800 overlapping archived seed/fraction outcomes also agree. This exact
reduction does not supply financial observables.

\paragraph{Matched transient perturbation and rule screen.}
At activation, the pulse arm writes Sell once at exactly the sites selected
for the rule switch, before orders execute, and subsequently keeps Rule~19280
everywhere. This changes a state rather than a response table, so its first
post-intervention quote can differ immediately. Fractions match the target
site count, not the number of states actually changed: sites already in Sell
remain Sell. The persistent switch instead leaves the first quote unchanged.
For $f=0.15,0.20,0.25$, under both held and endogenous boundaries, no pulse
reached a Sell majority in 50 seeds (0/50; Wilson upper bound 0.071).
Persistent Rule~19286 activation yielded 0/50, 50/50, and 50/50,
respectively (the Wilson lower bound for 50/50 is 0.929).
These controls distinguish the persistent rule mechanism from this matched
transient perturbation; they do not rule out every possible state perturbation.

The exploratory rule screen changes each of the nine entries to both
alternative outputs, covering all 18 single-entry neighbors of Rule~19280.
It uses 20 seeds at each of the same three fractions under both boundaries
(Table~\ref{tab:revision-rules}). Outcomes vary with the changed entry and its
output; additional transition-producing variants show that $c=1$ is not the
only effective entry. With 20 seeds, an observed 0/20 has Wilson upper bound
0.161 and 20/20 has lower bound 0.839. The screen is descriptive, does not
adjust for multiple comparisons, and does not establish a universal class of
activation thresholds.
'''
    text+=table('Single-entry neighbors of Rule~19280. Each probability pair is '
                'held / endogenous boundary over 20 seeds; the intervention is persistent. '
                'The output labels are Buy $=0$, Hold $=1$, Sell $=2$.',
                'tab:revision-rules',r'Sum $c$ & Output change & Rule & $f=0.15$ & $f=0.20$ & $f=0.25$',rows,'rrrrrr')
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
\paragraph{{Frozen band and non-monotone dealer response.}}
The fixed-band control freezes the decision deviation at its value immediately
before activation, retaining each trader's $k_j$ and continuing to update the
moving center. Thus the absolute half-width $k_j\sigma_{{1000}}$ is constant
within each path, while the diagnostic deviation still evolves. Each frozen
arm retains its adaptive arm's exact prehistory. Frozen widths vary across
seeds and capacities; this is a test of post-switch adaptation, not a test
with a common absolute width imposed on every market.
At $f=0.175$, the $h=0.1$ minus $h=\infty$ transition contrast changes from
{a.mean():.2f} under adaptation to {f.mean():.2f} with frozen widths.
The paired difference of these contrasts is {difference.mean():.2f}
(95\% seed-bootstrap interval [{lo:.2f}, {hi:.2f}]). The low-capacity advantage
therefore depends on adaptive feedback in this control, but the frozen
capacity response remains non-monotone and its individual probabilities have
wide intervals. Boundary Sell occupancy also changes
(Table~\ref{{tab:revision-band}}); this supports a feedback-mediated
interpretation without isolating a unique microscopic cause.
'''
    text+=table('Band-deviation control at $f=0.175$ over 50 seeds. Probability brackets '
                'are 95\\% Wilson intervals. Boundary Sell occupancy is the mean fraction '
                'of active boundary traders in Sell over post-switch steps and seeds.',
                'tab:revision-band',r'$h$ & Adaptive $p$ [95\% CI] & Frozen $p$ [95\% CI] & Adaptive Sell & Frozen Sell',rows,'rllll')
    imp=df[df.campaign=='price_impact'];rows=[]
    for _,r in imp.iterrows():
        rows.append(f'{cap(r.h)} & {r.impact:.3f} & {r.p:.2f} & {100*r.median_drawdown:.2f} & {r.median_rejection:.3f}')
    text+=r'''
\paragraph{Price-impact sensitivity.}
At $f=0.20$, $\lambda\in\{0.005,0.02,0.05\}$ spans a decade and
$h\in\{0.1,1,\infty\}$ spans three execution regimes. All 50 seeds transition
in every cell. Median drawdown remains ordered in $h$ for each coefficient,
but varies substantially with $\lambda$ (Table~\ref{tab:revision-impact}).
This supports the reported ordering within this range, while showing that the
price magnitudes are not calibrated or invariant to the impact choice.
'''
    text+=table('Price-impact sweep at $f=0.20$ under the endogenous boundary, '
                '50 seeds per cell. Drawdown is a percentage; rejection is the '
                'fraction of post-switch eligible orders rejected.',
                'tab:revision-impact',r'$h$ & $\lambda$ & Transition $p$ & Median drawdown (\%) & Median rejection',rows,'rrrrr')
    horizon=pd.read_csv(D/'ModelB-Revision-Horizons-Scaling.csv');rows=[]
    for (L,post),sub in horizon.groupby(['L','post']):
        x=sub.set_index('threshold')
        rows.append(f'{int(L)} & {int(post):,}'.replace(',','{,}')+' & '+' & '.join(ci(x.loc[q],'f50') for q in (.4,.5,.6)))
    text+=r'''
\paragraph{Horizon scaling and transition criterion.}
Held-boundary checks use 50 seeds on $f=0.140,0.145,\ldots,0.250$, extended
to 0.300 at $L=32$ to bracket the short-horizon response. At the endpoint
sizes we compare the original 3,000 steps with
$T_{\rm post}=3000(L/64)^z$ for $z=1,2$: 1,500 and 750 steps at $L=32$,
and 6,000 and 12,000 at $L=128$. Both scalings preserve the ordering of
endpoint midpoints. At $L=64$, increasing the horizon from 3,000 to 9,000
steps moves the majority midpoint from about 0.178 to 0.167.
The longer endpoint runs likewise continue to move the curve, so these data
do not establish horizon convergence.

Changing the crossing criterion to 0.4 or 0.6 shifts the numerical midpoint
but retains the endpoint size ordering and downward drift with horizon
(Table~\ref{tab:revision-horizons}). For $L=64$ and 3,000 steps, the midpoints
are approximately 0.173, 0.178, and 0.186 for the three criteria. Robustness
therefore applies to the qualitative response, not to a threshold-independent
numerical activation fraction. The final 500-step mean is not presumed to have
equilibrated at any size.
'''
    text+=table('Held-boundary horizon and threshold sensitivity, 50 seeds. Entries are '
                'interpolated $f_{50}$ [95\\% seed-bootstrap interval] for each crossing '
                'criterion. The horizon grids are independent of adaptive refinement, '
                'so their interpolated values can differ slightly from Table~\\ref{tab:finite-size-scaling}.',
                'tab:revision-horizons',r'$L$ & Post-switch steps & Criterion 0.4 & Criterion 0.5 & Criterion 0.6',rows,'rrlll',r'\footnotesize',keep=True)
    baseline=pd.read_csv(D/'ModelB-Revision-pulse.csv')
    baseline=baseline[(baseline.boundary=='endogenous')&(baseline.action=='rule')&np.isclose(baseline.f,.15)]
    text+=rf'''
\paragraph{{Baseline characterization and long no-switch paths.}}
In the 50 endogenous unlimited-dealer seeds, the mean interior Sell fraction
was {baseline.pre_sell_early.mean():.4f} over steps 501--750 and
{baseline.pre_sell_late.mean():.4f} over steps 751--1,000. In the latter
window, the median within-seed return standard deviation was
${baseline.pre_return_std.median():.2g}$; the median within-seed 1st and 99th
percentiles were ${baseline.pre_return_q01.median():.2g}$ and
${baseline.pre_return_q99.median():.2g}$. The mean zero-return fraction was
{baseline.pre_zero_returns.mean():.3f}. These characterize the pre-switch
ensemble, not an empirical calibration or a proof of stationarity. We do not
assert that its return distribution matches the calm regime of a published
market model.

Ten no-switch seeds under each boundary were followed for 100,000 additional
steps, with no majority crossing (0/10 per boundary; Wilson upper bound
0.278 for the ensemble event probability). These are the first ten seeds of
the production ensemble and constitute an extension, not independent
replication. The finite record excludes a majority transition in these paths
over this interval; it does not establish global stability or distinguish
all possible long transients from attractors.

\paragraph{{Fit and grid uncertainty.}}
Table~\ref{{tab:revision-fits}} supplements empirical interpolation with a
monotone logistic fit. Standard errors and intervals resample whole seeds,
including the selection of the sampled susceptibility maximum. Neither method
removes discretization error, adaptive-grid selection uncertainty, or
finite-horizon dependence. No susceptibility exponent is estimated.
\input{{sections/revision-fits-table}}
'''
    (S/'revision-controls.tex').write_text(text)

if __name__=='__main__':
    finite_tables()
    controls_tables()
