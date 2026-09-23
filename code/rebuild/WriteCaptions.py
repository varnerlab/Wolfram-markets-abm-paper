"""Generate captions with the actual newly selected starting markets."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'


def figure(name,width,caption,label):
    return '\n'.join([r'\begin{center}',r'\begin{minipage}{\linewidth}',
        r'\captionsetup{type=figure,hypcap=false}',r'\centering',
        rf'\includegraphics[width={width}\linewidth]{{figs/{name}.pdf}}',
        r'\caption{'+caption+'}',r'\label{'+label+'}',r'\end{minipage}',r'\end{center}',''])


def main():
    m=json.loads((STUDY/'code/data/Rebuild-Figure-Metadata.json').read_text())
    seeds=', '.join(str(x) for x in m['figure4_seeds'][:-1])+', and '+str(m['figure4_seeds'][-1])
    captions=[('Fig1-RuleQuench','0.95',rf'''The changed response and paired market decisions.
\textbf{{(A)}}~Baseline Rule~19280. \textbf{{(B)}}~Rule~19286 after the rule switch.
Each cross contains the four neighbors used to determine the next decision,
shown below its arrow. The hollow center is the trader being updated;
its current decision does not enter the lookup table. Blue, gray, and
orange denote Buy~(0), Hold~(1), and Sell~(2). One arrangement represents
each neighbor sum; every arrangement with that sum produces the same
response. The outlined column is the only response the rule switch
changes: three Buys and one Hold produce Buy under the baseline and
Sell after the switch.
\textbf{{(C)}}~Paired $64\times64$ grids at the rule switch and after 100,
400, and 3,000 steps. The upper row retains the baseline rule; the lower
assigns the new rule to 20\% of interior traders. Both paths share a
1,000-step baseline, dealer depth $h=100$, and active technical traders. Starting
market {m['figure1_seed']} was selected from 50 by proximity to the
median paired difference in peak Sell fraction. Ensemble outcomes and
conditional onset times appear in Supplementary Table~\ref{{tab:paired-switch}}.''','fig:rule-quench'),
    ('Fig2-ReservoirQuench','0.97',r'''Rule switches across dealer depths over 3,000 post-switch steps.
\textbf{(A)}~Probability of an interior Sell majority with technical
traders held or active. Bands are 95\% Wilson intervals over 50 starting
markets. \textbf{(B)}~Active-minus-held majority probability at each
depth and fraction. \textbf{(C)}~Median maximum drawdown at
fraction $f=0.20$, with interquartile bands. \textbf{(D)}~Median fraction of
post-switch eligible orders rejected at fraction $f=0.20$, on a logarithmic
axis with interquartile bands. Dealer depth $h$ is initial dealer shares per trader and also determines
price sensitivity through the reserve curve. The dashed overlay in A at
dealer depth $h=10$ is a distinct finite-depth comparison; the deep arm is dealer depth $h=100$.
At zero dealer depth only opposing trader orders match and price stays fixed.
Panels C and D describe switched markets. No-switch control drawdowns
and paired differences appear in Supplementary Table~\ref{tab:paired-switch}.''','fig:reservoir'),
    ('Fig3-FiniteSizeQuench','0.97',r'''Market size and the formation of a Sell majority
over 50 starting markets and 3,000 post-switch steps. \textbf{(A)}~Majority probability with technical
traders held, with 95\% Wilson bands. \textbf{(B)}~Susceptibility with
technical traders held: the variance across markets of the final
500-step mean Sell fraction, multiplied by the number of interior traders.
\textbf{(C)}~Interpolated fraction $f_{50}(L)$ at which half the markets
reached a majority, against inverse grid size, with technical traders held at dealer depth $h=100$ and active at
$h=1$ and $h=100$. \textbf{(D)}~Sampled maximum susceptibility versus
grid size. Error bars in C and D are 95\% whole-market bootstrap
intervals. Solid lines connect tested values; dashed curves in A are
logistic fits. No law for indefinitely large grids was fitted.''','fig:finite-size'),
    ('Fig4-DoseMarketPanels','0.90',rf'''Longer histories of five numerically selected markets
with active technical traders and dealer depth $h=100$. Blue, gray, and orange denote
Buy, Hold, and Sell. \textbf{{(A)}}~Grid decisions at the rule switch and after
1,500, 3,000, 5,000, and 10,000 steps. Selection used the newly computed
3,000-step summaries before inspection of images. At that endpoint,
the first two markets had not reached a majority and the other three
had. Nonmajority examples were nearest their group's median final Sell
fraction; majority examples were nearest their group's median onset,
with the starting-market number breaking ties. Starting markets were {seeds}, from left
to right. The longer outcomes did not affect selection.
\textbf{{(B)}}~Quoted price divided by its value at the rule switch.
\textbf{{(C)}}~Interior Sell fraction, with one-half marked by a
horizontal line. The dark vertical dashed line marks the original
3,000-step endpoint; other guides mark the remaining snapshots.
Onsets and financial summaries appear in Supplementary
Table~\ref{{tab:market-panel-horizons}}.''','fig:dose-panels'),
    ('Fig5-DealerMarketPanels','0.92',rf'''The same starting market at different dealer depths
with fraction $f=0.20$. \textbf{{(A)}}~Grid decisions at the rule switch and after
500, 1,500, and 3,000 steps. The first three columns have active technical
traders at dealer depth $h=0.1$, $1$, and $100$; the last holds the technical traders
at $h=100$. Starting market {m['figure5_seed']} was selected among
markets reaching a majority at all three dealer depths with active technical traders by minimizing
the summed distance from their depth-specific median onsets, with the
starting-market number breaking ties. \textbf{{(B)}}~Quoted price relative to the rule switch.
\textbf{{(C)}}~Interior Sell fraction. The held condition prevents price
feedback into decisions while retaining full trading and price
calculations. The selected paths illustrate the same initialization
across conditions; ensemble probabilities and drawdowns appear in
Fig.~\ref{{fig:reservoir}}.''','fig:dealer-panels'),
    ('Fig6-BalanceSheetQuench','0.99',r'''Changing trader cash and shares at the rule switch,
with active technical traders, fraction $f=0.18$, and 50 starting markets over 3,000 post-switch steps.
In A--C, the nine resource combinations are grouped by cash multiplier,
with share multiplier on the axis and a series for each dealer depth.
\textbf{(A)}~Majority probability. The dashed line and band give the
held-condition probability and its 95\% Wilson interval, identical
across financial conditions. \textbf{(B)}~Median maximum drawdown on a
logarithmic axis.
\textbf{(C)}~Median fraction of post-switch eligible orders rejected,
on a logarithmic axis.
\textbf{(D)}~Majority probability against median drawdown for all
27 active combinations, with the held reference repeated. The drawdown
axis follows B. Probability axes cover the full possible range;
all displayed drawdowns and rejection medians are strictly positive.''','fig:balance-sheet')]
    text='% Generated captions for the corrected rebuild.\n'+r'\section*{Figures}'+'\n\n'
    text+=('\n'+r'\clearpage'+'\n\n').join(figure(*x) for x in captions)
    (STUDY/'paper-arxiv/sections/figures.tex').write_text(text)


if __name__=='__main__':main()
