"""Standalone control figure from the verified pilot estimates."""
import csv
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "output/repaired/transmission-v1-pilot"
with (OUTPUT / "Grouped.csv").open(newline="") as stream:
    rows = list(csv.DictReader(stream))
style = (ROOT / "code/src/PaperStyle.jl").read_text()
palette = re.findall(r'#[0-9A-Fa-f]{6}', re.search(r'const _SERIES_COLORS = (.+)', style).group(1))
colors = {"hold": palette[4], "endogenous": palette[2]}
plt.rcParams.update({"font.size": 11, "axes.spines.top": False, "axes.spines.right": False,
                     "svg.fonttype": "none", "axes.titleweight": "bold"})
fig, axes = plt.subplots(1, 2, figsize=(12.4, 5.8))
fig.subplots_adjust(left=.075, right=.985, bottom=.25, top=.72, wspace=.28)
arms = ("live", "mask", "withdrawal")
for ax, metric, title in zip(axes,
        ("exit_cash_difference", "late_others_sell_difference"),
        ("A   Follower cash after liquidation", "B   Non-follower selling in final 500 steps")):
    for boundary, offset, marker in (("hold", -.075, "o"), ("endogenous", .075, "s")):
        values, lower, upper = [], [], []
        for arm in arms:
            selected = [r for r in rows if r["h"] == "100.0" and r["a"] == "0.4" and
                        r["independent"] == "false" and r["boundary"] == boundary and
                        r["diagnostic"] == arm and r["metric"] == metric]
            assert len(selected) == 1
            r = selected[0]
            values.append(100 * float(r["estimate"]))
            lower.append(100 * (float(r["estimate"]) - float(r["lower"])))
            upper.append(100 * (float(r["upper"]) - float(r["estimate"])))
        ax.errorbar([i + offset for i in range(3)], values, yerr=[lower, upper],
                    fmt=marker, color=colors[boundary], capsize=4, markersize=6,
                    label="Technical traders " + ("held" if boundary == "hold" else "active"))
    ax.axhline(0, color="#999999", linewidth=.8, zorder=0)
    ax.set_title(title, loc="left", fontsize=12, pad=16)
    ax.set_xticks(range(3), ("Continuous\nadvice", "Local influence\nmasked", "Advice\nwithdrawn"))
    ax.set_xlim(-.45, 2.45)
    ax.set_ylim(-8, 38)
    ax.set_ylabel("Difference from no following (percentage points)", fontsize=10)
    ax.grid(axis="y", color="#ededed", linewidth=.7)
    ax.set_axisbelow(True)
fig.suptitle("Shared advice: the local influence control", x=.075, y=.975,
             ha="left", fontsize=17, fontweight="bold")
fig.text(.075, .91, "40% adoption · one shared source · deep reserves (100 shares per trader) · 10 starting markets",
         fontsize=11, color="#555555")
handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper left", bbox_to_anchor=(.065, .88),
           frameon=False, ncols=2, fontsize=10)
fig.text(.075, .10, "Points are paired mean differences; bars are pointwise 95% whole-market bootstrap intervals.",
         fontsize=10, color="#555555")
fig.text(.075, .055, "Advice is withdrawn after 1,000 of 3,000 intervention steps. Active technical traders retain price feedback.",
         fontsize=10, color="#555555")
fig.savefig(OUTPUT / "transmission-controls.png", dpi=180)
fig.savefig(OUTPUT / "transmission-controls.svg")
plt.close(fig)
print(OUTPUT / "transmission-controls.png")
