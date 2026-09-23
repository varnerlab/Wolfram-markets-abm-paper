"""Write the Results and captions from verified corrected-run summaries."""
from pathlib import Path
import json
import re
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'
D=STUDY/'code/data';S=STUDY/'paper-arxiv/sections'


def read(name):return pd.read_csv(D/name)
def pct(x,d=2):return f'{100*x:.{d}f}'
def steps(x):return f'{x:,.0f}'.replace(',','{,}')


def generate():
    r=read('ModelB-TableS2-PairedSwitch.csv').set_index('target_f')
    d=read('ModelB-ReservoirQuench-Full-Summary.csv')
    b=read('ModelB-BalanceSheetQuench-Full-Grouped.csv')
    c=read('ModelB-Revision-Controls-Grouped.csv')
    e=read('ModelB-Revision-MarketPanel-Horizons.csv')
    cases=read('Figure4-Prespecified-Selection.csv')
    def dealer(h,f=.2,mode='endogenous'):
        return d[(d.market_maker_capacity==h)&np.isclose(d.target_f,f)&(d.boundary_mode==mode)]
    def prob(h,f,mode='endogenous'):return dealer(h,f,mode).transitioned.mean()
    def dd(h):return dealer(h).treated_maximum_drawdown.median()
    def reject(h):return dealer(h).treated_maker_rejection_fraction.median()
    assert (r.control_p==0).all() and r.loc[.1,'treated_p']==0 and r.loc[.15,'treated_p']==0
    assert r.loc[.2,'treated_p']==1 and r.loc[.25,'treated_p']==1
    assert d[np.isclose(d.target_f,.2)].transitioned.all()
    pulse=c[(c.campaign=='matched_pulse')&(c.action=='sell_pulse')]
    pulse_description=('produced no majority in either technical-trader condition' if (pulse.p==0).all()
        else f'gave probabilities ranging from {pulse.p.min():.2f} to {pulse.p.max():.2f} across the two technical-trader conditions')
    screen=c[(c.campaign=='rule_screen')&np.isclose(c.f,.2)]
    screen_per=screen.groupby('rule').p.agg(['min','max'])
    all_rules=int((screen_per['min']==1).sum());none_rules=int((screen_per['max']==0).sum())
    part_rules=len(screen_per)-all_rules-none_rules
    screen_text=f'{all_rules} produced a majority in every tested starting market under both technical-trader conditions, while {none_rules} produced none'
    if part_rules:screen_text+=f'; the remaining {part_rules} had intermediate outcomes'
    assert (pulse.p==0).all() and len(screen_per)==18
    assert r.loc[.25,'median_onset']<r.loc[.2,'median_onset']
    p1=rf'''We first asked whether a lasting change in how some traders respond to
their neighbors could turn a mixed market into one dominated by sellers.
Rule~19286 differs from the baseline Rule~19280 in a single response:
a trader with three neighbors in Buy and one in Hold chooses Sell rather
than Buy (Fig.~\ref{{fig:rule-quench}}A,B). We paired each switched market
with a no-switch control that kept Rule~19280 and shared its baseline
history and first post-switch quoted price (Supplementary
Table~\ref{{tab:campaigns}}). With active technical traders and dealer
depth $h=100$, none of the 50 starting markets reached a Sell majority
when the fraction of interior traders given the new rule was $f=0.10$ or
0.15, whereas all of them did at $f=0.20$ and 0.25, and no control
reached a majority over the same period. The median onset fell from
{r.loc[.2,'median_onset']:,.1f} steps at fraction $f=0.20$ to {r.loc[.25,'median_onset']:,.1f} steps at $f=0.25$
(Supplementary Table~\ref{{tab:paired-switch}}). In the displayed pair,
groups of sellers expanded after the rule switch while the control kept
its mixture of decisions (Fig.~\ref{{fig:rule-quench}}C). A one-time
instruction did not have the same effect: setting the selected traders
to Sell once at fraction $f=0.15$, 0.20, or 0.25 {pulse_description}
(Supplementary Table~\ref{{tab:revision-pulse}}). Which response changed
also mattered. Of the eighteen alternative rules tested at fraction
$f=0.20$, each differing from Rule~19280 in a single response,
{screen_text} (Supplementary Table~\ref{{tab:revision-rules}}). Thus,
within the tested interventions, whether a Sell majority formed
depended on which response changed, how many traders received it, and
whether the change lasted rather than acting once.
'''
    p2=rf'''Because technical traders respond to the quoted price, a Sell majority
might have required price feedback. To determine whether it did, we
repeated the rule switch with every technical trader held in Hold, so
that trades still completed and the price still moved but no decision
responded to it (Fig.~\ref{{fig:reservoir}}). A majority still formed.
With technical traders held, the Sell-majority probability was
{prob(100,.175,'hold'):.2f} at fraction $f=0.175$, {prob(100,.185,'hold'):.2f} at $f=0.185$, and
{prob(100,.2,'hold'):.2f} at $f=0.20$ (Fig.~\ref{{fig:reservoir}}A). Every held market carried
its full cash, share, and price calculations, yet its onset, final mean
Sell fraction, and final interior grid were identical across dealer
depths for the same starting market and fraction, even though its price
path differed. The held update takes no input from financial variables,
so responses to neighbors were sufficient to produce a Sell majority.
Allowing technical traders to respond to price changed how often a
majority formed near the crossover from mostly mixed to mostly
Sell-majority outcomes. At dealer depth $h=100$, the active condition
gave {round(prob(100,.175)*50)} of 50 majorities at fraction $f=0.175$ and {round(prob(100,.185)*50)} at $f=0.185$,
compared with {round(prob(100,.175,'hold')*50)} and {round(prob(100,.185,'hold')*50)} when held (Fig.~\ref{{fig:reservoir}}A,B).
Both the size and the sign of the active-minus-held difference depended
on the dealer depth and fraction. Thus, price feedback could change how
often the rule switch produced a majority, but it was not needed for
selling decisions to spread.
'''
    data=[]
    for case in cases.itertuples():
        sub=e[np.isclose(e.f,case.f)&(e.seed==case.seed)&(e.condition=='changed')].set_index('post')
        data.append((case,sub.loc[3000],sub.loc[10000]))
    delayed=sum(not a.transitioned and z.transitioned for _,a,z in data)
    onset_desc=[]
    for case,a,z in data:
        outcome=f'after {steps(z.onset)} steps' if z.transitioned else 'not within 10,000 steps'
        onset_desc.append(f'$f={case.f:.3f}$, starting market {case.seed}: {outcome}')
    f15=e[np.isclose(e.f,.15)&(e.condition=='changed')].set_index('post')
    e3=f15.loc[3000];e10=f15.loc[10000]
    ctrl=e[np.isclose(e.f,.15)&(e.condition=='control')&(e.post==10000)]
    nonmajority=[x for x in data if not x[1].transitioned];majority=[x for x in data if x[1].transitioned]
    assert len(nonmajority)==2 and len(majority)==3 and delayed==1
    late=[x for x in nonmajority if x[2].transitioned][0];never=[x for x in nonmajority if not x[2].transitioned][0]
    assert late[2].maximum_drawdown>late[1].maximum_drawdown
    n10=int(e10.transitioned.sum())
    assert int(e3.transitioned.sum())==0 and int(ctrl.transitioned.sum())==0 and 2<=n10<=5
    assert e10.maximum_drawdown.max()>e3.maximum_drawdown.max()
    count={2:'Two',3:'Three',4:'Four',5:'Five'}[n10]
    p4=rf'''A 3,000-step observation period could end before a slow majority formed,
so we extended five markets with active technical traders and dealer
depth $h=100$ to 10,000 steps (Fig.~\ref{{fig:dose-panels}}). We chose them from the
3,000-step results before inspecting any images. Two had not reached a
majority by that endpoint and three had. Of the two, the market at
fraction $f={late[0].f:.3f}$ reached a majority after {steps(late[2].onset)} steps, whereas the
market at $f={never[0].f:.3f}$ had not reached one by 10,000 steps; the three
earlier majorities formed after {steps(majority[0][2].onset)}, {steps(majority[1][2].onset)}, and
{steps(majority[2][2].onset)} steps (Supplementary Table~\ref{{tab:market-panel-horizons}}). Each
displayed majority formed through the growth and merger of groups of
sellers (Fig.~\ref{{fig:dose-panels}}A,C). For the market that reached a majority late,
maximum drawdown rose from {pct(late[1].maximum_drawdown)}\% at 3,000 steps to {pct(late[2].maximum_drawdown)}\% at
10,000 steps (Supplementary Table~\ref{{tab:market-panel-horizons}}). To see whether late
majorities were rare, we extended all 50 starting markets at fraction
$f=0.150$ together with their no-switch controls. {count} switched markets
reached a majority by 10,000 steps, compared with none at 3,000 steps,
and no control reached one. Over the same extension, the median
drawdown changed from {pct(e3.maximum_drawdown.median())}\% to {pct(e10.maximum_drawdown.median())}\%, whereas the largest
drawdown rose from {pct(e3.maximum_drawdown.max())}\% to {pct(e10.maximum_drawdown.max())}\%
(Supplementary Table~\ref{{tab:market-panel-horizons}}). Thus, a market that stayed mixed
for 3,000 steps did not necessarily stay mixed, and outcomes defined at
the original endpoint describe that period rather than the long-run
state of the market.
'''
    paired=read('Rebuild-Dealer-Paired-Drawdown.csv')
    paired=paired[paired.boundary=='endogenous'].set_index('h')
    band=json.loads((D/'Rebuild-Band-Contrast.json').read_text())
    depth=c[c.campaign=='reserve_depth'].set_index('h')
    pool=d[(d.boundary_mode=='endogenous')&np.isclose(d.target_f,.2)&d.transitioned&d.market_maker_capacity.isin([.1,1,100])]
    med=pool.groupby('market_maker_capacity').treated_onset.median();scores=[]
    for seed,sub in pool.groupby('seed'):
        if len(sub)==3:scores.append((sum(abs(x.treated_onset-med.loc[x.market_maker_capacity]) for x in sub.itertuples()),seed))
    dealer_seed=int(sorted(scores)[0][1])
    assert band['lo']<0<band['hi']
    p5=rf'''A Sell majority did not by itself determine how far the price fell,
because the decline also depended on the dealer's reserves. We
therefore varied the dealer depth $h$, the dealer's initial shares per
trader, while keeping the same rule switch (Fig.~\ref{{fig:reservoir}}). At fraction
$f=0.20$, every starting market reached a majority at every tested
depth, yet with active technical traders the median maximum drawdown
was {pct(dd(.1))}\% at dealer depth $h=0.1$, {pct(dd(1))}\% at $h=1$, and {pct(dd(100))}\% at $h=100$
(Fig.~\ref{{fig:reservoir}}C). In an additional comparison, median drawdowns were
{pct(depth.loc[40,'median_drawdown'])}\% at dealer depth $h=40$ and {pct(depth.loc[400,'median_drawdown'])}\% at $h=400$
(Supplementary Table~\ref{{tab:revision-impact}}). Smaller reserves made the quoted price
more sensitive to net selling, because the reserves set both the
dealer's available funds and the price required to execute a net trade.
Much of the decline at dealer depth $h=0.1$ occurred without the rule
switch: no-switch controls there already had a median drawdown of
{pct(paired.loc[.1,'control_median'])}\%, compared with {pct(paired.loc[100,'control_median'])}\% at $h=100$. The median paired
increase after the switch was {pct(paired.loc[.1,'delta_median'])} percentage points at dealer depth
$h=0.1$ and {pct(paired.loc[100,'delta_median'])} at $h=100$ (Supplementary Table~\ref{{tab:paired-switch}}).
Small positive reserves produced these declines while rejecting few
orders, with median dealer-rejection fractions of {reject(.1):.6f} at dealer
depth $h=0.1$, {reject(1):.6f} at $h=1$, and {reject(100):.7f} at $h=100$
(Fig.~\ref{{fig:reservoir}}D). Zero reserves were a separate limit, in which only
opposing trader orders matched, the dealer's net trading was zero, and
the price stayed fixed. Near the crossover, we also tested whether the
adaptive band widths of the technical traders shaped the difference
between dealer depths. At fraction $f=0.175$, the Sell-majority
probability was {prob(.1,.175):.2f} at dealer depth $h=0.1$ and {prob(100,.175):.2f} at $h=100$, a
difference of {band['adaptive_difference']:.2f} that became {band['frozen_difference']:.2f} when the band widths were frozen
after the rule switch. The paired difference between these two
contrasts was {band['difference']:.2f} with a 95\% bootstrap interval of
[{band['lo']:.2f}, {band['hi']:.2f}], so whether band-width adaptation contributed to the
difference remained unresolved (Supplementary Table~\ref{{tab:revision-band}}). In the
displayed starting market {dealer_seed}, a majority formed at all three dealer
depths with active technical traders while the price followed distinct
paths (Fig.~\ref{{fig:dealer-panels}}). Thus, at fraction $f=0.20$ the dealer's
reserves set the severity of the decline rather than whether a majority
formed, and shallow positive reserves did not prevent severe drawdowns.
'''
    selected=b[(b.boundary_mode=='endogenous')&np.isclose(b.target_f,.18)]
    def balance(h,cash,shares):return selected[(selected.market_maker_capacity==h)&(selected.cash_factor==cash)&(selected.share_factor==shares)].iloc[0]
    held=b[(b.boundary_mode=='hold')&np.isclose(b.target_f,.18)].transition_probability.unique();assert len(held)==1
    # Both resource dimensions are reported for fixed comparisons, never chosen for an extreme effect.
    shares=[balance(100,1,q).median_drawdown for q in (.1,1,10)]
    cashlow,cashhigh=balance(1,1,1),balance(1,10,1)
    p6=rf'''The dealer's reserves are only one side of each trade, so we also
changed the traders' own cash and shares, independently, at the rule
switch (Fig.~\ref{{fig:balance-sheet}}). With technical traders held, every cash and
share combination at fraction $f=0.18$ produced the same decision
history within a starting market, and the Sell-majority probability was
{held[0]:.2f} at every dealer depth. Holdings entered the order and clearing
calculations but not the interior decision rule, so they could change
decisions only through the price response of active technical traders.
With technical traders active, the probability ranged from
{selected.transition_probability.min():.2f} to {selected.transition_probability.max():.2f} across resource combinations and dealer depths
(Fig.~\ref{{fig:balance-sheet}}A; Supplementary Table~\ref{{tab:balance-fractions}}). With unchanged
cash and dealer depth $h=100$, share multipliers of 0.1, 1, and 10 gave
median drawdowns of {pct(shares[0])}\%, {pct(shares[1])}\%, and {pct(shares[2])}\%
(Fig.~\ref{{fig:balance-sheet}}B), because more shares supplied more potential sales
while the reserve curve set the price at which net selling could clear.
By contrast, raising the cash multiplier from 1 to 10 at dealer depth
$h=1$ with unchanged shares changed the median drawdown only from
{pct(cashlow.median_drawdown)}\% to {pct(cashhigh.median_drawdown)}\% and the majority probability from
{cashlow.transition_probability:.2f} to {cashhigh.transition_probability:.2f}, in markets where the decline was already close to
complete (Fig.~\ref{{fig:balance-sheet}}A,B). The relationship between the
dealer-rejection fraction and drawdown differed across the resource
combinations (Fig.~\ref{{fig:balance-sheet}}C,D). Together, these comparisons showed
that the financial consequences of a rule switch depended on both sides
of the traders' books and on the dealer's reserves. A majority decision
to sell did not by itself determine how many shares could change hands
or how far the quoted price would fall.
'''
    text='% Generated by code/rebuild/WriteResults.py from corrected-run outputs.\n'+r'\section{Results}'+'\n\n'+p1+'\n'+p2+'\n'+r'\input{sections/finite-size-results}'+'\n\n'+p4+'\n'+p5+'\n'+p6
    (S/'results.tex').write_text(text)
    log=(STUDY/'logs/rule.log').read_text();rule_seed=int(re.search(r'exemplar_seed = (\d+)',log)[1])
    metadata={'figure1_seed':rule_seed,'figure4_seeds':[int(x.seed) for x in cases.itertuples()],
              'figure5_seed':dealer_seed,'figure4_delayed_crossings':int(delayed)}
    (D/'Rebuild-Figure-Metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
    return metadata


if __name__=='__main__':generate()
