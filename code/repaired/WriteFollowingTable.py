"""Write the manuscript's following-experiment table from the deposited confirmation and pilot outputs.

Run from the repository root:
    python3 code/repaired/WriteFollowingTable.py
"""
import argparse
import json
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
CONF = ROOT / 'output/repaired/transmission-confirmation-v1-full'
PILOT = ROOT / 'output/repaired/following-reserve-v2-pilot'


def one(frame, **keys):
    selected = frame
    for key, value in keys.items():
        selected = selected[selected[key] == value]
    assert len(selected) == 1, (keys, len(selected))
    return selected.iloc[0]


def pp(row):
    return f'{100*row.estimate:.2f} [{100*row.lower:.2f}, {100*row.upper:.2f}]'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'paper-arxiv/sections/following-table.tex')
    args = parser.parse_args()
    grouped = pd.read_csv(CONF / 'Grouped.csv')
    contrasts = pd.read_csv(CONF / 'Contrasts.csv')
    primary = {e['endpoint']: e for e in json.loads((CONF / 'Primary.json').read_text())['endpoints']}
    assert json.loads((CONF / 'Primary.json').read_text())['confirmed']
    pilot = pd.read_csv(PILOT / 'Grouped.csv')

    def conf(metric, diagnostic='live', a=0.4, independent=False, h=100.0, boundary='hold'):
        return one(grouped, a=a, independent=independent, h=h, boundary=boundary, diagnostic=diagnostic, metric=metric)

    rows = [r'\multicolumn{7}{l}{\textbf{A. Shared advice from one source to 40\% of interior traders, 50 starting markets}}',
            r'$h$ & Technical & Cash, advice & Cash, masked & Cash difference & Non-follower Sell & Drawdown',
            r'\midrule']
    for h in (100.0, 1.0):
        for boundary in ('hold', 'endogenous'):
            difference = one(contrasts, a=0.4, independent=False, h=h, boundary=boundary,
                             comparison='continuous_minus_mask', metric='exit_cash_difference')
            rows.append(f'{h:g} & {"held" if boundary == "hold" else "active"} & '
                        f'{pp(conf("exit_cash_difference", h=h, boundary=boundary))} & '
                        f'{pp(conf("exit_cash_difference", "mask", h=h, boundary=boundary))} & {pp(difference)} & '
                        f'{pp(conf("others_sell_difference", h=h, boundary=boundary))} & '
                        f'{pp(conf("drawdown_difference", h=h, boundary=boundary))}')
    rows += [r'\midrule',
             r'\multicolumn{7}{l}{\textbf{B. Stopping advice and separate advice, 40\% followers, $h=100$, technical traders held}}',
             r'\multicolumn{2}{l}{Advice} & Cash & \multicolumn{2}{l}{Non-follower Sell, final 500 steps} & Non-follower Sell & Drawdown',
             r'\midrule']
    for label, diagnostic, independent in (('One source', 'live', False), ('Stopped at 1,000 steps', 'withdrawal', False),
                                           ('Separate for each follower', 'live', True)):
        rows.append(rf'\multicolumn{{2}}{{l}}{{{label}}} & {pp(conf("exit_cash_difference", diagnostic, independent=independent))} & '
                    rf'\multicolumn{{2}}{{l}}{{{pp(conf("late_others_sell_difference", diagnostic, independent=independent))}}} & '
                    f'{pp(conf("others_sell_difference", diagnostic, independent=independent))} & '
                    f'{pp(conf("drawdown_difference", diagnostic, independent=independent))}')

    def pil(metric, mode, K, independent=False):
        return one(pilot, mode=mode, a=0.4, K=K, independent=independent, h=100.0, boundary='hold', metric=metric)

    rows += [r'\midrule',
             r'\multicolumn{7}{l}{\textbf{C. Exploratory comparison, 10 starting markets, 40\% followers, $h=100$, technical traders held}}',
             r'\multicolumn{2}{l}{Followers} & Cash & \multicolumn{2}{l}{} & Non-follower Sell & Drawdown',
             r'\midrule']
    for label, mode, K, independent in (('Advice, one source', 'advice', 1, False), ('Advice, sixteen sources', 'advice', 16, False),
                                        ('Advice, separate for each', 'advice', 0, True),
                                        ('Copying one trader', 'copy_filled', 1, False), ('Copying sixteen traders', 'copy_filled', 16, False)):
        rows.append(rf'\multicolumn{{2}}{{l}}{{{label}}} & {pp(pil("exit_cash_difference", mode, K, independent))} & '
                    r'\multicolumn{2}{l}{} & '
                    f'{pp(pil("others_sell_difference", mode, K, independent))} & '
                    f'{pp(pil("drawdown_difference", mode, K, independent))}')

    summary = pd.read_csv(CONF / 'Summary.csv')
    treated = summary[(summary['mode'] != 'none') & (summary.a == 0.4) & (~summary.independent.astype(bool)) & (summary.h == 100.0)
                      & (summary.boundary == 'hold') & (summary.diagnostic == 'live')]
    assert len(treated) == 100
    # The same non-follower traders in their paired no-following controls.
    baseline = (treated.others_mean_sell - treated.others_sell_difference).mean()
    stopped = summary[(summary['mode'] != 'none') & (summary.a == 0.4) & (~summary.independent.astype(bool)) & (summary.h == 100.0)
                      & (summary.boundary == 'hold') & (summary.diagnostic == 'withdrawal')].late_others_sell_difference
    assert len(stopped) == 100
    cash = primary['continuous_cash_advantage']
    masked = primary['continuous_minus_mask']
    caption = (
        'Following experiments on $64\\times64$ grids in which every interior trader kept Rule~19280, with 1,000 '
        'baseline steps and 3,000 steps of following. Followers were interior traders chosen at random. Cash is '
        'the mean over followers of each follower\'s final cash, after every trader sold all of its shares to '
        'the dealer, divided by its cash and shares at the quoted price when following began, minus the same '
        'mean for the same traders in the paired no-following control. Non-follower Sell is the change in the fraction of '
        'time that non-followers spent in Sell, and drawdown is the change in the maximum drawdown of the quoted '
        'price. All changes are in percentage points, with pointwise 95\\% intervals from resampling whole '
        'starting markets. In A, each starting market had two random assignments of followers and advice. In '
        'the masked condition, neighbors read each follower\'s intention from the no-following control, and the '
        'cash difference is advice minus masked. The two endpoints fixed before these markets were simulated, '
        'cash with advice and the cash difference at dealer depth $h=100$ with technical traders held, had '
        f'Bonferroni-adjusted 97.5\\% intervals of [{100*cash["lower"]:.2f}, {100*cash["upper"]:.2f}] and '
        f'[{100*masked["lower"]:.2f}, {100*masked["upper"]:.2f}]. In the no-following controls at $h=100$ with '
        f'technical traders held, the same non-followers spent {100*baseline:.1f}\\% of their time in Sell. In B, the change in '
        f'the final 500 steps after advice stopped exceeded 20 percentage points in {(stopped > 0.2).sum()} of '
        f'{len(stopped)} runs and was below 5 percentage points in {(stopped < 0.05).sum()}. In C, copying repeated a randomly chosen '
        'trader\'s completed trade from the previous step.')
    lines = ['% Generated by code/repaired/WriteFollowingTable.py from the confirmation and pilot outputs.',
             r'\clearpage', r'\begin{center}', r'\begin{minipage}{\linewidth}\centering',
             r'\captionsetup{type=table,hypcap=false}', r'\caption{' + caption + '}', r'\label{tab:following}',
             r'\scriptsize\setlength{\tabcolsep}{1.4pt}', r'\begin{tabular}{rlccccc}', r'\toprule']
    lines += [x if x == r'\midrule' else x + r' \\' for x in rows]
    lines += [r'\bottomrule', r'\end{tabular}', r'\end{minipage}', r'\end{center}', '']
    args.output.write_text('\n'.join(lines))
    print(f'Wrote {args.output}')


if __name__ == '__main__':
    main()
