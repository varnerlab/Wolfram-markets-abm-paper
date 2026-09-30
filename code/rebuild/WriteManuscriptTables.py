"""Generate every retained table from the isolated, corrected simulation outputs."""
from pathlib import Path
import argparse
import json
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'
D=STUDY/'code/data'
S=STUDY/'paper-arxiv/sections'


def val(x,d=3):
    return 'Undefined' if not np.isfinite(x) else f'{x:.{d}f}'


def ci(r,name,d=3):
    return f'{val(r[name],d)} [{val(r[name+"_lo"],d)}, {val(r[name+"_hi"],d)}]'


def cap(x):
    assert np.isfinite(x)
    return f'{x:g}'


def scientific(x):
    if x == 0:return '0'
    mantissa,exponent=f'{x:.2e}'.split('e')
    return rf'${mantissa}\times10^{{{int(exponent)}}}$'


def table(caption,label,header,rows,layout,small=r'\small',keep=True):
    lines=[r'\begin{center}']
    if keep: lines += [r'\begin{minipage}{\linewidth}\centering']
    lines += [r'\captionsetup{type=table,hypcap=false}',r'\caption{'+caption+'}',
              r'\label{'+label+'}',small,r'\begin{tabular}{'+layout+'}',r'\toprule']
    if header: lines += [header+r' \\',r'\midrule']
    lines += [x if x==r'\midrule' else x+r' \\' for x in rows]
    lines += [r'\bottomrule',r'\end{tabular}']
    if keep: lines += [r'\end{minipage}']
    lines += [r'\end{center}','']
    return '\n'.join(lines)


UNDEFINED=' Undefined denotes a crossing outside the tested fractions; intervals use the bootstrap samples in which it was inside.'


def read(name):
    return pd.read_csv(D/name)


def main_tables():
    counts=json.loads((STUDY/'Campaign-counts.json').read_text())
    rows=[r'Rule switch & 64 & $100$ & active & 50 & 400',
          r'Dealer depth & 64 & $0$--$100$ & active/held & 50 & 9,600',
          r'Grid size & 32--128 & $1,100$ & active/held & 50 & 9,750',
          r'Cash and shares & 64 & $0.1,1,100$ & active/held & 50 & 10,800']
    text=r'''% Generated from the corrected rebuild only.
\section*{Tables}
\setcounter{table}{0}
\renewcommand{\thetable}{S\arabic{table}}

'''+table('Design of the four main comparisons. Active technical traders responded to the quoted price; '
          'held technical traders stayed in Hold. The grid-size comparison '
          'used active technical traders at dealer depth $h=1$ and $100$, and held technical traders at $h=100$. '
          'Counts include the no-switch controls. Where a comparison tested several fractions, one control '
          'per starting market and condition served all of them. The cash-and-shares comparison had no '
          'no-switch controls.',
          'tab:campaigns',r'Comparison & Grid sizes & Dealer $h$ & Technical traders & Starting markets & Simulations',
          rows,'llllrr',r'\small\setlength{\tabcolsep}{4pt}')
    df=read('ModelB-TableS2-PairedSwitch.csv');rows=[]
    for r in df.itertuples():
        onset=val(r.median_onset,1).replace(',','{,}')
        rows.append(f'{r.target_f:.2f} & {int(r.seeds)} & {r.control_p:.2f} & {r.treated_p:.2f} & {onset}')
    rows=[r'\multicolumn{5}{l}{\textbf{A. Rule switch at $h=100$, active technical traders}}',
          r'Fraction $f$ & Starting markets & No-switch $p$ & Switched $p$ & Median onset']+rows
    raw=read('ModelB-ReservoirQuench-Full-Summary.csv')
    paired=[];rng=np.random.default_rng(20260914);indices=rng.integers(0,50,(2000,50))
    for (mode,h),group in raw[np.isclose(raw.target_f,.2)].groupby(['boundary_mode','market_maker_capacity']):
        group=group.sort_values('seed');assert len(group)==50
        delta=(group.treated_maximum_drawdown-group.control_maximum_drawdown).to_numpy()
        lo,hi=np.quantile(np.median(delta[indices],axis=1),[.025,.975])
        paired.append(dict(boundary=mode,h=h,n=50,control_median=group.control_maximum_drawdown.median(),
            treated_median=group.treated_maximum_drawdown.median(),delta_median=np.median(delta),delta_lo=lo,delta_hi=hi))
    paired=pd.DataFrame(paired);paired.to_csv(D/'Rebuild-Dealer-Paired-Drawdown.csv',index=False)
    rows += [r'\midrule',r'\multicolumn{5}{l}{\textbf{B. Dealer depth at $f=0.20$, active technical traders}}',
             r'$h$ & Starting markets & No-switch DD & Switched DD & Paired $\Delta$DD [95\% CI]']
    for _,r in paired[paired.boundary=='endogenous'].sort_values('h').iterrows():
        rows.append(f'{cap(r.h)} & {int(r.n)} & {100*r.control_median:.2f} & {100*r.treated_median:.2f} & '
                    f'{100*r.delta_median:.2f} [{100*r.delta_lo:.2f}, {100*r.delta_hi:.2f}]')
    text+=table('Paired rule switches on a $64\\times64$ grid over 3,000 post-switch steps. '
                'In A, majority probability $p$ is the fraction of markets reaching an interior Sell fraction of at least '
                'one-half; median onset is conditional on reaching that value. Undefined means no run reached a majority. '
                'In B, DD is median maximum drawdown in percent. $\\Delta$DD is the median paired '
                'difference, in percentage points, with a pointwise 95\\% whole-market bootstrap confidence '
                'interval (CI). These contrasts separate the rule switch from baseline financial variation.',
                'tab:paired-switch','',rows,'rrrrl',r'\small\setlength{\tabcolsep}{4pt}')
    text+=r'\input{sections/finite-size-table}'+'\n\n'
    df=read('ModelB-TableS4-BalanceSheetFractions.csv');rows=[]
    for r in df.itertuples():
        assert r.held_cells==27 and r.endo_cells==27
        rows.append(f'{r.target_f:.3f} & {r.held_p:.2f} & {r.endo_min:.2f}--{r.endo_max:.2f}')
    text+=table('Probability of a Sell majority after changes in trader cash and shares over 50 starting markets '
                'and 3,000 post-switch steps. '
                'Each fraction includes 27 combinations of cash, shares, and dealer depth. '
                'With technical traders held, the probability was the same across those combinations; with '
                'technical traders active, it spanned the stated range.',
                'tab:balance-fractions',r'Fraction $f$ & Technical traders held & Technical traders active (range)',rows,'rrl')
    text+=feedback_pairs()
    text+='\n'+r'\input{sections/revision-tables}'+'\n\n'+r'\input{sections/market-panel-horizons-table}'+'\n'
    (S/'tables.tex').write_text(text)


def feedback_pairs():
    """Active versus held majority outcomes, paired by starting market, near the crossover."""
    def near(series,values):return np.isclose(series.to_numpy()[:,None],np.array(values)[None,:]).any(1)
    depths=(.1,1.,100.);sweep_f=(.175,.185,.19,.195);extra_f=(.17,.18)
    keys=['seed','target_f','market_maker_capacity','boundary_mode']
    sweep=read('ModelB-ReservoirQuench-Full-Summary.csv')
    resources=read('ModelB-BalanceSheetQuench-Full-Summary.csv')
    resources=resources[(resources.cash_factor==1)&(resources.share_factor==1)]
    # The unchanged-resource runs reproduce the dealer-depth runs wherever both exist.
    both=sweep.merge(resources,on=keys)
    assert len(both)==600 and (both.transitioned_x==both.transitioned_y).all()
    assert np.allclose(both.treated_final_sell_mean,both.final_sell_mean)
    assert np.allclose(both.treated_maximum_drawdown,both.maximum_drawdown)
    runs=pd.concat([sweep[near(sweep.target_f,sweep_f)&near(sweep.market_maker_capacity,depths)][keys+['transitioned']],
                    resources[near(resources.target_f,extra_f)][keys+['transitioned']]])
    wide=runs.assign(y=runs.transitioned.astype(float)).pivot_table(
        index=['market_maker_capacity','seed'],columns=['target_f','boundary_mode'],values='y')
    rng=np.random.default_rng(20260929);indices=rng.integers(0,50,(2000,50));records=[]
    for h in depths:
        sub=wide.loc[h];assert sub.shape==(50,12) and not sub.isna().any().any()
        fractions=sorted(sub.columns.get_level_values(0).unique())
        diff=pd.DataFrame({f:sub[(f,'endogenous')]-sub[(f,'hold')] for f in fractions})
        for f in fractions:
            x=diff[f].to_numpy();lo,hi=np.quantile(x[indices].mean(1),[.025,.975])
            records.append(dict(h=h,fractions=f'{f:.3f}',active=sub[(f,'endogenous')].mean(),held=sub[(f,'hold')].mean(),
                                only_active=int((x>0).sum()),only_held=int((x<0).sum()),difference=x.mean(),lo=lo,hi=hi))
        for label,chosen in [('0.175--0.195',sweep_f),('0.170--0.195',sweep_f+extra_f)]:
            x=diff[[f for f in fractions if np.isclose(f,chosen).any()]].to_numpy();assert x.shape==(50,len(chosen))
            lo,hi=np.quantile(x[indices].mean(axis=(1,2)),[.025,.975])
            records.append(dict(h=h,fractions=label,active=np.nan,held=np.nan,only_active=int((x>0).sum()),
                                only_held=int((x<0).sum()),difference=x.mean(),lo=lo,hi=hi))
    records=pd.DataFrame(records);records.to_csv(D/'Rebuild-Feedback-Pairs.csv',index=False)
    rows=[];previous=None
    for r in records.itertuples():
        if previous is not None and r.h!=previous:rows.append(r'\midrule')
        previous=r.h
        pooled=not np.isfinite(r.active)
        probabilities='\\multicolumn{2}{l}{Average}' if pooled else f'{r.active:.2f} & {r.held:.2f}'
        def two(x):return f'{x:.2f}'.replace('-0.00','0.00')
        rows.append(f'{cap(r.h)} & {r.fractions} & {probabilities} & {r.only_active} & {r.only_held} & '
                    f'{two(r.difference)} [{two(r.lo)}, {two(r.hi)}]')
    return table('Majority outcomes with technical traders active and held, paired by starting market, over 50 '
                 'starting markets and 3,000 post-switch steps. Fractions 0.17 and 0.18 come from the '
                 'unchanged-resource runs of the trader-resource comparison, which reproduced the dealer-depth '
                 'runs exactly where the two overlapped. Only active and Only held count markets that reached a '
                 'majority under one condition alone; held technical traders stayed in Hold from initialization, '
                 'so paired markets need not share their state at the switch. The difference is active minus '
                 'held majority probability, with a 95\\% interval (CI) from 2,000 bootstrap samples of whole '
                 'starting markets. Average rows weight the listed fractions equally and count market--fraction pairs.',
                 'tab:feedback-pairs',r'$h$ & Fraction $f$ & Active $p$ & Held $p$ & Only active & Only held & Difference [95\% CI]',
                 rows,'rlrrrrl',r'\footnotesize\setlength{\tabcolsep}{4pt}')


def finite_tables(*,with_results=True):
    df=read('ModelB-Revision-FiniteSize-Scaling.csv');rows=[];fits=[];previous=None
    for _,r in df.iterrows():
        condition=(r.boundary_mode,r.market_maker_capacity)
        if previous is not None and condition!=previous:rows.append(r'\midrule');fits.append(r'\midrule')
        previous=condition
        lead=f'{"Held" if r.boundary_mode=="hold" else "Active"} & {cap(r.market_maker_capacity)} & {int(r.gridn)}'
        rows.append(f'{lead} & {int(r.interior_points)} & {ci(r,"f50")} & {ci(r,"transition_width")} & {ci(r,"susceptibility_peak",1)}')
        fits.append(f'{lead} & {val(r.logistic_f50)} ({val(r.logistic_f50_se,4)}) & '
                    f'{val(r.logistic_width)} ({val(r.logistic_width_se,4)}) & {val(r.susceptibility_peak_f)}')
    (S/'finite-size-table.tex').write_text(table(
        'Grid-size comparisons over 50 starting markets and 3,000 post-switch steps. Brackets give 95\\% '
        'confidence intervals (CI) from 2,000 whole-market bootstrap samples. $n_{\\rm int}$ counts tested fractions '
        'with majority probability strictly between 0.05 and 0.95. The fractions $f_{25}$, $f_{50}$, and $f_{75}$ '
        'are the first upward crossings of majority probability 0.25, 0.5, and 0.75, found by linear '
        'interpolation between tested fractions, and the width is $f_{75}-f_{25}$. The susceptibility maximum '
        'is taken over the tested fractions and is selected again in each bootstrap sample.'
        +(UNDEFINED if any('Undefined' in r for r in rows) else ''),
        'tab:finite-size-scaling',r'Technical traders & $h$ & $L$ & $n_{\rm int}$ & $f_{50}$ [95\% CI] & Width [95\% CI] & Peak $\chi_L$ [95\% CI]',
        rows,'llrrlll',r'\footnotesize\setlength{\tabcolsep}{3pt}'))
    (S/'revision-fits-table.tex').write_text(table(
        'Logistic fits and susceptibility maxima over 50 starting markets and 3,000 post-switch steps. '
        'Parentheses give whole-market bootstrap standard errors (SE). '
        'The fitted curve imposes increasing probability; interpolated crossings do not. '
        'The final column gives the tested fraction with the largest susceptibility, so its precision is '
        'limited by the spacing of nearby tested fractions.',
        'tab:revision-fits',r'Technical traders & $h$ & $L$ & Logistic $f_{50}$ (SE) & Logistic width (SE) & $f$ at peak',
        fits,'llrlll'))
    if not with_results:return
    held=df[df.boundary_mode=='hold'].sort_values('gridn');low,high=held.iloc[0],held.iloc[-1]
    hor=read('ModelB-Revision-Horizons-Scaling.csv')
    h64=hor[(hor.L==64)&np.isclose(hor.threshold,.5)].set_index('post')
    delta=(df.logistic_f50-df.f50).abs().max()
    assert low.gridn==32 and high.gridn==128 and high.f50<low.f50 and high.susceptibility_peak>low.susceptibility_peak
    text=rf'''We next asked how the spread of selling depended on the number of
interacting traders. With technical traders held, we compared markets
whose grids had $L=32$ to $L=128$ rows and columns and refined the
tested fractions near the rise in majority probability at each size,
keeping the same starting markets (Fig.~\ref{{fig:finite-size}}). Larger grids gave a
sharper response. The fraction at which half the markets reached a
majority within 3,000 steps, $f_{{50}}$, fell from {low.f50:.3f} at grid size
$L=32$ to {high.f50:.3f} at $L=128$, and the width between majority probabilities
of 0.25 and 0.75 narrowed from {ci(low,'transition_width')} to {ci(high,'transition_width')}, with
brackets giving 95\% intervals from resampling whole starting markets
(Fig.~\ref{{fig:finite-size}}A,C; Supplementary Table~\ref{{tab:finite-size-scaling}}). The
susceptibility, which measures how much the final mean Sell fraction
varied between starting markets, rose from a sampled maximum of
{low.susceptibility_peak:.1f} at grid size $L=32$ to {high.susceptibility_peak:.1f} at $L=128$
(Fig.~\ref{{fig:finite-size}}B,D). The midpoints changed little when a logistic curve
replaced interpolation: across all size and technical-trader
conditions, the two estimates differed by at most {delta:.4f}
(Supplementary Tables~\ref{{tab:finite-size-scaling}} and~\ref{{tab:revision-fits}}). Observation time
still mattered. At grid size $L=64$, extending the held markets from
3,000 to 9,000 steps moved the midpoint from {h64.loc[3000,'f50']:.3f} to {h64.loc[9000,'f50']:.3f}, and
alternative Sell thresholds and size-dependent horizons gave further
comparisons (Supplementary Table~\ref{{tab:revision-horizons}}). Thus, the size
comparison described a crossover within a finite observation period
rather than a fixed threshold that would hold for indefinitely long runs.
'''
    (S/'finite-size-results.tex').write_text(text)


def controls_tables():
    df=read('ModelB-Revision-Controls-Grouped.csv');tables=[]
    pulse=df[df.campaign=='matched_pulse'];rows=[]
    for (boundary,f),sub in pulse.groupby(['boundary','f']):
        arms=sub.set_index('action');a,b=arms.loc['sell_pulse'],arms.loc['rule']
        rows.append(f'{"Held" if boundary=="hold" else "Active"} & {f:.2f} & {int(a.seeds)} & {ci(a,"p",2)} & {ci(b,"p",2)}')
    tables.append(table('A one-time instruction to sell versus a persistent rule switch at the same selected interior traders. '
        'Both conditions used dealer depth $h=100$, 3,000 post-intervention steps, and no-switch controls. '
        'Entries are majority probabilities with 95\\% Wilson intervals.',
        'tab:revision-pulse',r'Technical traders & $f$ & Starting markets & Sell pulse & Persistent rule',rows,'lrrll'))
    base=[(19280//3**c)%3 for c in range(9)];rows=[]
    screen=df[df.campaign=='rule_screen']
    for rule,sub in screen.groupby('rule'):
        changes=[c for c in range(9) if (int(rule)//3**c)%3!=base[c]];assert len(changes)==1
        c=changes[0];out=(int(rule)//3**c)%3;prob=[]
        for f in (.15,.20,.25):
            x=sub[np.isclose(sub.f,f)].set_index('boundary')
            prob.append(f'{x.loc["hold","p"]:.2f} / {x.loc["endogenous","p"]:.2f}')
        rows.append((c,out,f'{c} & {base[c]} $\\to$ {out} & {int(rule)} & '+' & '.join(prob)))
    tables.append(table('All single-response changes to Rule~19280 with dealer depth $h=100$. Each entry gives majority '
        'probability with technical traders held / active over 20 starting markets and 3,000 post-switch steps. '
        'Outputs are Buy $=0$, Hold $=1$, and Sell $=2$. This descriptive screen used no multiplicity adjustment.',
        'tab:revision-rules',r'Sum $c$ & Output change & Rule & $f=0.15$ & $f=0.20$ & $f=0.25$',
        [r[2] for r in sorted(rows)],'rrrrrr',r'\footnotesize'))
    band=df[df.campaign=='fixed_band'];rows=[]
    for h,sub in band.groupby('h'):
        a=sub[sub.band=='adaptive'].iloc[0];b=sub[sub.band=='frozen'].iloc[0]
        rows.append(f'{cap(h)} & {ci(a,"p",2)} & {ci(b,"p",2)} & {a.mean_edge_sell:.3f} & {b.mean_edge_sell:.3f}')
    raw=read('ModelB-Revision-band.csv')
    values=raw.pivot(index='seed',columns=['h','band'],values='transitioned').astype(float)
    a=values[(.1,'adaptive')]-values[(100.,'adaptive')]
    b=values[(.1,'frozen')]-values[(100.,'frozen')]
    difference=(a-b).to_numpy();rng=np.random.default_rng(20260905)
    lo,hi=np.quantile(difference[rng.integers(0,len(difference),(2000,len(difference)))].mean(1),[.025,.975])
    bandstats=dict(adaptive_difference=a.mean(),frozen_difference=b.mean(),difference=difference.mean(),lo=lo,hi=hi)
    (D/'Rebuild-Band-Contrast.json').write_text(json.dumps(bandstats,indent=2)+'\n')
    tables.append(table('Adaptive versus frozen band widths for active technical traders at fraction $f=0.175$ over '
        '50 starting markets. Frozen widths kept $\\sigma_t$ at its value immediately before the rule switch, '
        'while the reference price $\\mu_t$ continued to update. Entries $p$ are Sell-majority probabilities with '
        '95\\% Wilson confidence intervals (CI) in brackets. Sell is the mean fraction of technical '
        'traders in Sell over post-switch steps and starting markets. '
        f'The probability at dealer depth $h=0.1$ minus that at $h=100$ was {a.mean():.2f} with adaptive widths '
        f'and {b.mean():.2f} with frozen widths. Their paired difference was {difference.mean():.2f}, '
        f'with a 95\\% interval [{lo:.2f}, {hi:.2f}] from 2,000 whole-market bootstrap samples.',
        'tab:revision-band',r'$h$ & Adaptive $p$ [95\% CI] & Frozen $p$ [95\% CI] & Adaptive Sell & Frozen Sell',rows,'rllll'))
    imp=df[df.campaign=='reserve_depth'];assert len(imp)==3;rows=[]
    for _,r in imp.sort_values('h').iterrows():
        rows.append(f'{cap(r.h)} & {r.impact:.3f} & {ci(r,"p",2)} & {100*r.median_drawdown:.2f} & {scientific(r.median_rejection)}')
    tables.append(table('Additional dealer-depth comparisons at fraction $f=0.20$ with active technical traders and '
        '50 starting markets over 3,000 post-switch steps. Because the dealer\'s cash and share reserves keep a '
        'constant product, the initial slope of the log quoted price against net purchases per trader is '
        'approximately $2/h$; the model has no separate price-impact coefficient. '
        'Depth changes funding and price sensitivity together. Drawdown is a percentage, and the dealer-rejection '
        'fraction uses post-switch eligible orders. Probability brackets are 95\\% Wilson intervals.',
        'tab:revision-impact',r'$h$ & Initial slope $2/h$ & Majority probability & Median drawdown (\%) & Rejection',rows,'rrlrr'))
    horizon=read('ModelB-Revision-Horizons-Scaling.csv');rows=[]
    for (L,post),sub in horizon.groupby(['L','post']):
        x=sub.set_index('threshold')
        rows.append(f'{int(L)} & {int(post):,}'.replace(',','{,}')+' & '+' & '.join(ci(x.loc[q],'f50') for q in (.4,.5,.6)))
    tables.append(table('Observation period and the fraction $f_{50}$ at which half the markets reached a Sell majority, '
        'with technical traders held and dealer depth $h=100$. '
        'Entries are interpolated $f_{50}$ with 95\\% whole-market bootstrap intervals over 50 starting markets. '
        'Criterion columns give the interior Sell fraction a run had to reach to count as a majority. '
        'These runs used one fixed set of tested fractions rather than the adaptively refined set, so interpolated '
        'midpoints can differ slightly '
        'from those in Supplementary Table~\\ref{tab:finite-size-scaling} for the same runs, for example 0.167 '
        'rather than 0.166 at $L=128$ and 0.219 rather than 0.216 at $L=32$.'
        +(UNDEFINED if any('Undefined' in r for r in rows) else ''),
        'tab:revision-horizons',r'$L$ & Post-switch steps & Criterion 0.4 & Criterion 0.5 & Criterion 0.6',rows,'rrlll',r'\footnotesize'))
    (S/'revision-tables.tex').write_text('\n\n'.join(tables)+'\n\n'+r'\input{sections/revision-fits-table}'+'\n')
    long=df[df.campaign=='long_control'];longsent=[]
    for r in long.itertuples():
        longsent.append(f'{"held" if r.boundary=="hold" else "active"} technical traders: '
                        f'{round(r.p*r.seeds)}/{int(r.seeds)} majorities, 95\\% Wilson interval '
                        f'[{r.p_lo:.3f}, {r.p_hi:.3f}]')
    baseline=read('ModelB-Revision-pulse.csv')
    baseline=baseline[(baseline.boundary=='endogenous')&(baseline.action=='rule')&np.isclose(baseline.f,.15)]
    assert len(baseline)==50
    baseline_fields=['pre_sell_early','pre_sell_late','pre_return_std','pre_return_q01','pre_return_q99','pre_zero_returns']
    baseline[baseline_fields+['seed']].to_csv(D/'Rebuild-Baseline-Summary.csv',index=False)
    text=rf'''\subsection{{Additional controls and sensitivity analyses}}
\label{{app:revision-controls}}

The supplementary controls used the same initialization and baseline as
the main comparisons, with grid size $L=64$, dealer depth $h=100$, and 3,000 post-intervention
steps unless otherwise specified. Every switched run was compared
with a no-switch control. Held conditions calculated full
financial histories as well as decisions. A Sell pulse wrote Sell
at the selected interior traders immediately before the first post-baseline orders,
while retaining the baseline rule for later updates. Traders already in
Sell were unchanged. A persistent intervention instead changed the
selected rule without overwriting decisions, so its first price remained
identical to the no-switch price. These paired interventions compared
the same fractions and starting markets under both technical-trader
conditions (Supplementary Table~\ref{{tab:revision-pulse}}). The rule
screen tested all eighteen ways of changing one response in the
baseline lookup table, using twenty starting markets per condition
and three fractions. Each screen entry was descriptive rather
than a separate confirmatory hypothesis test
(Supplementary Table~\ref{{tab:revision-rules}}).

The band control froze the recent-departure scale at its value immediately
before the rule switch, while each technical trader retained its multiplier
and the reference price continued to update. Adaptive and frozen runs
shared their complete pre-switch histories. The frozen widths could
therefore differ across dealer depths and starting markets. At fraction $f=0.175$,
the estimated majority-probability difference between dealer depths $h=0.1$ and
$h=100$ was {a.mean():.2f} with adaptive widths and {b.mean():.2f} with
frozen widths. Subtracting those two differences gave
{difference.mean():.2f}, with a 95\% whole-market bootstrap interval of
[{lo:.2f}, {hi:.2f}] (Supplementary Table~\ref{{tab:revision-band}}).
This comparison changed width adaptation while retaining the response
to departures from a moving reference price. It therefore tested one
part of the price feedback rather than removing technical trading.

Additional comparisons used dealer depths $h=40,100,400$ at fraction $f=0.20$ with
active technical traders (Supplementary Table~\ref{{tab:revision-impact}}).
For the constant-product dealer, differentiating log price with respect to
normalized net trader purchases at initialization gives $2N_{{\rm tr}}/H$,
approximately $2/h$. The chosen depths therefore spanned initial slopes
0.05, 0.02, and 0.005. No independent exponential impact coefficient
was varied: changing depth also changed dealer funding. These
comparisons replaced an impact-coefficient sweep belonging to the
superseded standing-quote model. They measured sensitivity within the
corrected mechanism and did not hold available reserves fixed while
changing price sensitivity. Neither the quoted price nor the length of a step was
calibrated to an observed market.

The horizon campaign used fifty starting markets at fractions
0.140, 0.145, through 0.250, extending to 0.300 for grid size $L=32$ to bracket
short-horizon responses. Held technical traders prevented financial
feedback throughout. Endpoint comparisons used the original 3,000 steps
and size-dependent observation periods $3000(L/64)^z$ for $z=1,2$, alongside longer
observations. Majority criteria of 0.4, 0.5, and 0.6 were extracted
from each history. Interpolation and bootstrap intervals were calculated
separately for every size, horizon, and criterion
(Supplementary Table~\ref{{tab:revision-horizons}}). The no-switch
extension followed ten starting markets per technical-trader condition for
100,000 additional steps. The observed outcomes were {'; '.join(longsent)}.
These extensions reused starting markets and did not constitute
independent replications. The observed frequencies of Sell majorities described
the stated interval without establishing behavior at indefinitely long
times.

We also characterized the shared pre-switch histories at dealer depth $h=100$ with
active technical traders. Across the fifty starting markets, mean
interior Sell fractions were {baseline.pre_sell_early.mean():.4f} over
steps 501--750 and {baseline.pre_sell_late.mean():.4f} over steps
751--1,000. In the latter interval, the median within-market log-return
standard deviation was {baseline.pre_return_std.median():.6f}, and
median within-market first and ninety-ninth percentiles were
{baseline.pre_return_q01.median():.6f} and
{baseline.pre_return_q99.median():.6f}. The mean fraction of exactly
zero computed log returns was {baseline.pre_zero_returns.mean():.3f}.
These summaries described the starting markets without establishing
stationarity or matching a calibrated empirical return distribution.
The no-switch controls separately measured post-switch baseline
financial variation across dealer depths
(Supplementary Table~\ref{{tab:paired-switch}}).

The refined finite-size analysis resampled entire starting markets across
fractions in 2,000 bootstrap replicates. The empirical estimate used the
first upward crossing and allowed local decreases in probability, while
the logistic fit imposed a smooth increasing response
(Supplementary Table~\ref{{tab:revision-fits}}). Each replicate reselected
the susceptibility maximum over the tested fractions. Consequently,
intervals included variation in which sampled fraction supplied that
maximum, but not interpolation bias, uncertainty from selecting the
refinement grid, or changes from observing for longer. The recorded
valid-bootstrap fraction identified samples in which the requested
crossings remained bracketed. No susceptibility exponent or
infinite-size limit was fitted.
'''
    (S/'revision-controls.tex').write_text(text)


def market_panel_table():
    df=read('ModelB-Revision-MarketPanel-Horizons.csv')
    cases=read('Figure4-Prespecified-Selection.csv')
    rows=[r'\multicolumn{7}{l}{\textbf{A. Five examples selected from new 3,000-step results}}',
          r'$f$ & Starting market & First majority & \shortstack{Drawdown\\3,000 steps} & \shortstack{Drawdown\\10,000 steps} & \shortstack{Price change\\10,000 steps} & Final Sell']
    for case in cases.itertuples():
        sub=df[np.isclose(df.f,case.f)&(df.seed==case.seed)&(df.condition=='changed')].set_index('post')
        a,b=sub.loc[3000],sub.loc[10000];onset=f'{int(b.onset):,}' if b.onset else 'None'
        rows.append(f'{case.f:.3f} & {case.seed} & {onset} & {100*a.maximum_drawdown:.2f} & '
                    f'{100*b.maximum_drawdown:.2f} & {100*b.price_change:.2f} & {b.final_sell_mean:.3f}')
    rows += [r'\midrule',r'\multicolumn{7}{l}{\textbf{B. All 50 starting markets at $f=0.150$}}',
             r'\multicolumn{2}{l}{Decision rule} & Steps & Majorities / 50 & \shortstack{Median\\drawdown} & \shortstack{Worst\\drawdown} & \shortstack{Median\\price change}']
    for condition,label in [('changed','New rule at 15\\%'),('control','Original rule')]:
        for post in (3000,5000,10000):
            sub=df[np.isclose(df.f,.15)&(df.condition==condition)&(df.post==post)];assert len(sub)==50
            rows.append(r'\multicolumn{2}{l}{'+label+'} & '+f'{post:,} & {int(sub.transitioned.sum())}/50 & '
                        f'{100*sub.maximum_drawdown.median():.2f} & {100*sub.maximum_drawdown.max():.2f} & '
                        f'{100*sub.price_change.median():.2f}')
    (S/'market-panel-horizons-table.tex').write_text(table(
        'The five example markets of Fig.~\\ref{fig:dose-panels} and all 50 starting markets at fraction $f=0.15$ with their no-switch controls, '
        'extended from 3,000 to 10,000 steps with dealer depth $h=100$ and active technical traders. Times are steps after the rule '
        'switch, following 1,000 baseline steps. Drawdowns and price changes are percentages; price '
        'changes use the quoted price at the rule switch as reference. Final Sell averages the last 500 steps '
        'of the longer observation period. None means no Sell majority by 10,000 steps. The examples were selected from the '
        '3,000-step summaries before any images were inspected. The extensions follow the same '
        'starting markets, and are not independent replications.',
        'tab:market-panel-horizons','',rows,'lrrrrrr',r'\footnotesize\setlength{\tabcolsep}{2.5pt}'))


def main():
    protocol=json.loads((STUDY/'Protocol.json').read_text())
    assert protocol['initial_cached_files']==0 and not protocol['historical_data_imported']
    main_tables();finite_tables();controls_tables();market_panel_table()
    print('Generated all eleven tables and supporting text from',D)


if __name__=='__main__':main()
