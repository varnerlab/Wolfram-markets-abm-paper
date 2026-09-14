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
    screen_text=f'{all_rules} produced a majority in every tested starting market under both feedback conditions, while {none_rules} produced none'
    if part_rules:screen_text+=f'; the remaining {part_rules} had intermediate outcomes'
    p1=rf'''To explore how a persistent change in investor decisions could destabilize
a market, we changed one response in selected traders' rules and found
that a Sell majority formed when enough traders received the new rule
(Fig.~\ref{{fig:rule-quench}}; Supplementary Tables~\ref{{tab:campaigns}}
and~\ref{{tab:paired-switch}}).
Rule~19286 changed the response to three neighbors in Buy and one in Hold
from Buy to Sell, preserving every other response
(Fig.~\ref{{fig:rule-quench}}A,B). Each treated market shared its baseline
history and first post-switch quote with a comparison market that retained
Rule~19280. With active technical traders and dealer depth $h=100$, none
of the 50 starting markets reached a majority at $f=0.10$ or 0.15, whereas
all reached one at $f=0.20$ and 0.25. No matched control reached a majority
over the same period. The median onset among the two larger fractions
changed from {r.loc[.2,'median_onset']:,.1f} to {r.loc[.25,'median_onset']:,.1f}
steps (Supplementary Table~\ref{{tab:paired-switch}}). In the selected
pair, groups of sellers expanded after the rule change while the
comparison market retained mixed decisions (Fig.~\ref{{fig:rule-quench}}C).
The lasting rule change also differed from a temporary instruction:
setting the selected traders to Sell once at $f=0.15$, 0.20, or 0.25
{pulse_description} (Supplementary Table~\ref{{tab:revision-pulse}}).
Among the eighteen single-response rule changes tested at $f=0.20$,
{screen_text} (Supplementary Table~\ref{{tab:revision-rules}}).
Within these tested interventions, majority formation differed with the
changed response, the fraction of traders receiving it, and whether the
intervention changed a rule or only the current decision.
'''
    p2=rf'''To determine whether price feedback was required for widespread selling,
we repeated the rule switch while keeping technical traders in Hold and
found that a majority still formed (Fig.~\ref{{fig:reservoir}}).
With these traders held, majority probability was {prob(100,.175,'hold'):.2f}
at $f=0.175$, {prob(100,.185,'hold'):.2f} at $f=0.185$, and
{prob(100,.2,'hold'):.2f} at $f=0.20$ (Fig.~\ref{{fig:reservoir}}A).
Every held market was simulated again with its full cash, share, and price
history. Across dealer depths, onset, final mean Sell fraction, and final
interior states were identical for the same starting market and target
fraction, although the associated financial paths differed. This agreed
with the held update, which had no input from financial variables. Neighbor responses
were therefore sufficient to produce a Sell majority. Allowing
technical traders to respond to price changed majority frequency near
the crossover between mostly mixed and mostly Sell-majority outcomes.
At $h=100$, the active condition gave {round(prob(100,.175)*50)} of 50
majorities at $f=0.175$ and {round(prob(100,.185)*50)} at $f=0.185$,
compared with {round(prob(100,.175,'hold')*50)} and
{round(prob(100,.185,'hold')*50)} when held (Fig.~\ref{{fig:reservoir}}A,B).
Both the size and direction of the active-minus-held difference depended
on the tested depth and fraction. A price response could thus modify
how often the rule change produced a majority, but it was not necessary
for selling decisions to spread. These comparisons separated the local
decision mechanism from feedback through completed trades.
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
    p4=rf'''To examine how the spatial patterns developed beyond the initial
observation window, we extended five numerically selected markets and
found that longer observation changed some outcomes
(Fig.~\ref{{fig:dose-panels}}). Selection used the newly computed
3,000-step results and preceded inspection of images. Two selected
markets had not reached a majority at that endpoint, while three had.
At 10,000 steps, {delayed} of the initially nonmajority examples had
crossed one-half. The first-majority outcomes, in displayed order, were
{'; '.join(onset_desc)} (Supplementary Table~\ref{{tab:market-panel-horizons}}).
The spatial histories connected these crossings to the growth and
merger of groups of sellers, while the price histories measured their
financial consequences (Fig.~\ref{{fig:dose-panels}}A--C). In the selected
$f=0.175$ market that had not crossed by 3,000 steps, maximum drawdown
changed from {pct(data[1][1].maximum_drawdown)}\% to
{pct(data[1][2].maximum_drawdown)}\% at the longer endpoint
(Supplementary Table~\ref{{tab:market-panel-horizons}}).
We also extended all 50 starting markets at $f=0.150$, retaining
matched no-switch comparisons. The number of majorities among changed-rule
markets was {int(e3.transitioned.sum())} at 3,000 steps and
{int(e10.transitioned.sum())} at 10,000 steps,
while {int(ctrl.transitioned.sum())} controls reached a majority by
10,000 steps. Median drawdown changed from
{pct(e3.maximum_drawdown.median())}\% to {pct(e10.maximum_drawdown.median())}\%,
and the largest observed drawdown changed from
{pct(e3.maximum_drawdown.max())}\% to {pct(e10.maximum_drawdown.max())}\%
(Supplementary Table~\ref{{tab:market-panel-horizons}}).
The longer trajectories therefore qualified outcomes defined by the
original endpoint; persistence of mixed decisions over that shorter
window did not establish persistence over longer times.
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
    p5=rf'''We varied dealer depth while retaining the same decision-rule intervention
and found that shallower positive reserves accompanied larger price
declines, while majority probability did not vary monotonically with
depth (Fig.~\ref{{fig:reservoir}}). At $f=0.20$, every starting market
reached a majority at every tested depth. With active technical traders,
median maximum drawdown was {pct(dd(.1))}\% at $h=0.1$,
{pct(dd(1))}\% at $h=1$, and {pct(dd(100))}\% at $h=100$
(Fig.~\ref{{fig:reservoir}}C). The corresponding median rejection
fractions were {reject(.1):.6f}, {reject(1):.6f}, and
{reject(100):.7f}, so small positive reserves supported large declines
while rejecting few orders backed by trader resources
(Fig.~\ref{{fig:reservoir}}D). Zero depth supplied a separate limit:
only opposing trader orders matched, net dealer trading was zero, and
price stayed fixed. No-switch markets at $h=0.1$ already had median
drawdown {pct(paired.loc[.1,'control_median'])}\%, compared with
{pct(paired.loc[100,'control_median'])}\% at $h=100$. The median paired
increase after the rule switch was {pct(paired.loc[.1,'delta_median'])}
percentage points at $h=0.1$ and {pct(paired.loc[100,'delta_median'])}
at $h=100$ (Supplementary Table~\ref{{tab:paired-switch}}).
Positive reserve depth changed both available
funding and the price required to execute a net trade. In the additional
comparison at $h=40$ and $h=400$, median drawdowns were
{pct(depth.loc[40,'median_drawdown'])}\% and
{pct(depth.loc[400,'median_drawdown'])}\%, respectively
(Supplementary Table~\ref{{tab:revision-impact}}).
Near the majority crossover, depth also changed feedback through the
technical traders. At $f=0.175$, majority probabilities were
{prob(.1,.175):.2f} at $h=0.1$ and {prob(100,.175):.2f} at $h=100$.
Their difference changed from {band['adaptive_difference']:.2f} with
adaptive band widths to {band['frozen_difference']:.2f} with frozen widths
(Supplementary Table~\ref{{tab:revision-band}}). The paired difference
between those contrasts was {band['difference']:.2f}, with a 95\%
bootstrap interval [{band['lo']:.2f}, {band['hi']:.2f}], so its sign was
not resolved (Supplementary Table~\ref{{tab:revision-band}}). The selected comparison
from starting market {dealer_seed} also reached a majority at all three
displayed depths while following distinct price paths
(Fig.~\ref{{fig:dealer-panels}}). The reserve mechanism thus separated
majority formation from the severity of the decline, but shallow positive
reserves did not prevent severe drawdowns.
'''
    selected=b[(b.boundary_mode=='endogenous')&np.isclose(b.target_f,.18)]
    def balance(h,cash,shares):return selected[(selected.market_maker_capacity==h)&(selected.cash_factor==cash)&(selected.share_factor==shares)].iloc[0]
    held=b[(b.boundary_mode=='hold')&np.isclose(b.target_f,.18)].transition_probability.unique();assert len(held)==1
    # Both resource dimensions are reported for fixed comparisons, never chosen for an extreme effect.
    shares=[balance(100,1,q).median_drawdown for q in (.1,1,10)]
    cashlow,cashhigh=balance(1,1,1),balance(1,10,1)
    p6=rf'''To distinguish trader resources from dealer reserves, we changed cash
and share holdings independently at the rule switch and found that
financial resources changed interior decisions only through active
price feedback (Fig.~\ref{{fig:balance-sheet}}). At $f=0.18$, all
cash and share combinations with technical traders held produced the
same decision history within a starting market, giving majority
probability {held[0]:.2f} across dealer depths. With technical traders
active, probabilities ranged from {selected.transition_probability.min():.2f}
to {selected.transition_probability.max():.2f}
(Fig.~\ref{{fig:balance-sheet}}A; Supplementary Table~\ref{{tab:balance-fractions}}).
Holdings entered the order and clearing calculations but did not enter
the interior lookup table. Their effect on subsequent decisions therefore
required the intervening price response. With unchanged cash and $h=100$,
share multipliers 0.1, 1, and 10 gave median drawdowns of
{pct(shares[0])}\%, {pct(shares[1])}\%, and {pct(shares[2])}\%,
respectively (Fig.~\ref{{fig:balance-sheet}}B). More shares supplied
more potential sales, while the reserve curve determined the price
at which net selling could clear. Increasing the cash multiplier from 1
to 10 at $h=1$ with unchanged shares changed median drawdown from {pct(cashlow.median_drawdown)}\%
to {pct(cashhigh.median_drawdown)}\%, and majority probability from
{cashlow.transition_probability:.2f} to {cashhigh.transition_probability:.2f}
(Fig.~\ref{{fig:balance-sheet}}A,B). Rejection recorded the fraction
of orders backed by trader resources that still failed to execute,
and its relationship to drawdown differed across the resource
combinations (Fig.~\ref{{fig:balance-sheet}}C,D). The financial
consequences of a rule change therefore depended on both sides of
traders' books and the dealer's reserves. A majority decision to sell
alone did not specify how many shares could change hands or how far
the marginal quote would fall.
'''
    text='% Generated by code/rebuild/WriteResults.py from corrected-run outputs.\n'+r'\section{Results}'+'\n\n'+p1+'\n'+p2+'\n'+r'\input{sections/finite-size-results}'+'\n\n'+p4+'\n'+p5+'\n'+p6
    (S/'results.tex').write_text(text)
    log=(STUDY/'logs/rule.log').read_text();rule_seed=int(re.search(r'exemplar_seed = (\d+)',log)[1])
    metadata={'figure1_seed':rule_seed,'figure4_seeds':[int(x.seed) for x in cases.itertuples()],
              'figure5_seed':dealer_seed,'figure4_delayed_crossings':int(delayed)}
    (D/'Rebuild-Figure-Metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
    return metadata


if __name__=='__main__':generate()
