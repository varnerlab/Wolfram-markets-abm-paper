"""Plot the ten-thousand-step extension without changing manuscript figures."""
from pathlib import Path
import os
import re
import tempfile
os.environ.setdefault('MPLCONFIGDIR', str(Path(tempfile.gettempdir()) / 'markets-matplotlib'))
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter, StrMethodFormatter
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
STEM = 'ModelB-Revision-MarketPanel-Horizons'
summary = pd.read_csv(ROOT / 'code/data' / f'{STEM}.csv')
traces = pd.read_csv(ROOT / 'code/data' / f'{STEM}-Trajectories.csv')
OUT = ROOT / 'output/pdf'
OUT.mkdir(exist_ok=True, parents=True)
style = (ROOT / 'code/src/PaperStyle.jl').read_text()
state = dict(re.findall(r'const _(BUY|HOLD|SELL)_COLOR\s*=\s*"(#[A-Fa-f0-9]+)"', style))
cases = [(0.150,8), (0.175,5), (0.175,22), (0.185,46), (0.200,21)]
colors = ['#56B4E9', '#000000', '#E69F00', '#CC79A7', state['SELL']]
fig, axes = plt.subplots(2,2,figsize=(11,8.4), layout='constrained')
for ax in axes.flat:
    ax.set_facecolor('#f0f0f0')
    ax.grid(color='white', linewidth=.8)
    ax.set_axisbelow(True)
    ax.axvline(3000,color='#555555',ls=':',lw=1.3)
    ax.set_xlim(0,10000)
    ax.xaxis.set_major_formatter(StrMethodFormatter('{x:,.0f}'))
    ax.set_xlabel('Steps after the decision rule changed')

for (f,seed),color in zip(cases,colors):
    t=traces[(traces.f==f)&(traces.seed==seed)&(traces.condition=='changed')]
    label=f'f = {f:.3f}, seed {seed}'
    axes[0,0].plot(t.post_step,t.price_relative,color=color,lw=1.6,label=label)
    axes[0,1].plot(t.post_step,t.sell_fraction,color=color,lw=1.6)
control=traces[(traces.f==.15)&(traces.seed==8)&(traces.condition=='control')]
axes[0,0].plot(control.post_step,control.price_relative,color='#555555',ls='--',lw=1.1,label='Original rule, seed 8')
axes[0,1].axhline(.5,color='#555555',ls='--',lw=1)
axes[0,0].set_ylabel('Price / price when the rule changed')
axes[0,1].set_ylabel('Fraction of interior traders deciding to sell')
axes[0,1].set_ylim(0,1)
axes[0,1].yaxis.set_major_formatter(PercentFormatter(1))
axes[0,0].legend(fontsize=8,loc='lower left',framealpha=.9,ncol=2)

low=traces[traces.f==.15]
for _,g in low[low.condition=='changed'].groupby('seed'):
    axes[1,0].plot(g.post_step,g.price_relative,color=state['SELL'],alpha=.13,lw=.7)
for condition,color,label in [('changed',state['SELL'],'New rule at 15%'),('control',state['BUY'],'Original rule')]:
    t=low[low.condition==condition].groupby('post_step').price_relative.quantile([.25,.5,.75]).unstack()
    axes[1,0].fill_between(t.index,t[.25],t[.75],color=color,alpha=.2)
    axes[1,0].plot(t.index,t[.5],color=color,lw=2,label=label)
    end=summary[(summary.f==.15)&(summary.post==10000)&(summary.condition==condition)]
    assert len(end)==50
    times=np.arange(10001)
    cumulative=np.array([((end.onset>0)&(end.onset<=t)).mean() for t in times])
    axes[1,1].plot(times,cumulative,color=color,lw=2,label=label)
axes[1,0].set_ylabel('Price / price when the rule changed')
axes[1,0].legend(fontsize=9,loc='lower left')
axes[1,1].set_ylabel('Fraction of runs reaching a Sell majority')
axes[1,1].yaxis.set_major_formatter(PercentFormatter(1))
axes[1,1].set_ylim(-.003,.06)
axes[1,1].set_yticks([0,.02,.04,.06])
axes[1,1].legend(fontsize=9,loc='upper left')
for ax,letter,title in zip(axes.flat,'ABCD',[
    'Prices in the five Fig. 4 examples','Decisions in the five Fig. 4 examples',
    'Prices across all 50 starting markets at f = 0.150',
    'Late Sell majorities at f = 0.150']):
    ax.set_title(f'{letter}  {title}',loc='left',fontsize=10,fontweight='bold')
fig.suptitle('Following the same markets for 10,000 steps',fontsize=14,fontweight='bold')
fig.supxlabel('Dotted line: original 3,000-step endpoint. C: individual changed-rule runs, medians, and middle 50% bands.\n'
              '64 × 64 grid; unlimited dealer; edge traders respond to price; 1,000 initial steps before the rule change.',fontsize=9)
fig.savefig(OUT / 'Fig4-Extended-Horizon.pdf')
fig.savefig(OUT / 'Fig4-Extended-Horizon.png',dpi=160)

report=['# Extension of the Fig. 4 markets to 10,000 steps','',
'The five displayed starting markets were extended using the original decision rules, resources, '
'and price response. All 50 original starting markets at f = 0.150 were also extended. '
'Every changed-rule run had a matched run that retained Rule 19280. These are extensions '
'of existing simulations, not independent replications. The original 3,000-step statistics '
'were checked against the archived results for all 54 pairs. The complete price and Sell-fraction '
'histories through step 3,000 were also reproduced exactly for the five illustrated changed-rule runs.', '',
'All times below are steps **after** the rule change, following 1,000 initial steps. '
'A price change is relative to the price when the rule changed. Maximum drawdown is the largest '
'fall from a preceding peak in the stated period. A Sell majority means at least half of interior '
'states were Sell at least once; it is not a definition of a price crash.', '',
'| Fraction | Seed | Price change at 3,000 | Price change at 10,000 | Maximum drawdown through 10,000 | First Sell majority |',
'|---|---:|---:|---:|---:|---:|']
for f,seed in cases:
    g=summary[(summary.f==f)&(summary.seed==seed)&(summary.condition=='changed')].set_index('post')
    a,b=g.loc[3000],g.loc[10000]
    onset=f'{int(b.onset):,}' if b.onset else 'None by 10,000'
    report.append(f'| {f:.3f} | {seed} | {a.price_change:.2%} | {b.price_change:.2%} | {b.maximum_drawdown:.2%} | {onset} |')
report += ['', 'For the displayed f = 0.150 market (seed 8), the price did not continue declining: '
'it rose 0.50% between steps 3,000 and 10,000. The mean Sell fraction over the final '
'500 steps was 26.96%, compared with 26.82% at the original endpoint. Its maximum '
'drawdown increased only from 5.33% to 5.41%. This supports persistence over these '
'10,000 steps, not stability for arbitrary time.', '',
'Across the 50 f = 0.150 starting markets, no run reached a Sell majority by 3,000 '
'or 5,000 steps. Two did by 10,000: seed 7 at step 6,144 and seed 46 at step 8,417. '
'Their prices ended 24.48% and 22.52% below their values when the rule changed. '
'All 50 matched original-rule runs remained below a Sell majority. The median '
'price change across the changed-rule runs was -3.30% at 3,000 and -3.39% at 10,000. '
'Median maximum drawdown rose from 4.88% to 5.48%; the worst rose from 9.32% to 24.53%.', '',
'The Fig. 4 f = 0.175 example without a majority at 3,000 (seed 5) developed one at '
'step 4,117 and ended 25.53% below its price when the rule changed. The other three '
'examples already had majorities at 3,000 and continued toward mean Sell fractions '
'near 90% by 10,000. Thus, a run without a majority at the original endpoint cannot '
'be labeled indefinitely stable.', '',
'Previous horizon checks used edge traders kept in Hold and omitted finances. '
'They also found 2/50 majorities at f = 0.150 by 9,000 steps, but do not answer '
'the price-stability question for the active-price markets in Fig. 4.', '',
'The manuscript Fig. 4 uses these extended histories with the same five originally selected markets.', '',
'## Reproduction', '', '```sh',
'julia --project=code --threads=4 code/revision/Compute-MarketPanel-Horizons.jl',
'/opt/homebrew/bin/python3 code/revision/Plot-MarketPanel-Horizons.py', '```', '',
'Summary and trajectories: `code/data/ModelB-Revision-MarketPanel-Horizons*.csv`.']
report_dir=ROOT/'output/analysis'
report_dir.mkdir(exist_ok=True,parents=True)
(report_dir/'Fig4-Extended-Horizon.md').write_text('\n'.join(report)+'\n')
print(OUT / 'Fig4-Extended-Horizon.pdf')
