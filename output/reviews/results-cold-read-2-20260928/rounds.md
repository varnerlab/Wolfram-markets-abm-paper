# Results cold read (2026-09-28, second session)

Target: results.tex + finite-size-results.tex. Context: abstract, Introduction, Methods, figure captions (captions are collected after the references, so they were supplied as context, as a reader flipping to each cited figure would see them). Chunks of 2 paragraphs, one fresh reader each.

| Round | Chunk | Paragraphs | Sev 3 | Sev 2 | Sev 1 |
|---|---|---|---:|---:|---:|
| 1 | 1 | P1-P2 | 0 | 12 | 9 |
| 1 | 2 | P3-P4 | 0 | 17 | 12 |
| 1 | 3 | P5-P6 | 0 | 21 | 11 |

## Round 1 triage (fixed in place; every fact checked against output/rebuilt/manuscript-reserve-v1/code/data or the supplementary tables)
- P1: 3,000-step window named; onset "after the switch" (1,070.0 -> 1,070); displayed pair f=0.20; pulse purpose + protocol (Sell once, keep 19280 afterwards, per revision-controls.tex); rule screen now says the 18 include 19286, 20 starting markets, 6 of 8 toward-Sell changes vs 0 of 10 toward-Buy (Table S rules); closer scoped to 19286 vs pulse.
- P2: names the dealer-depth campaign (11 fractions, 8 depths); mechanism before held numbers; "crossover" defined at first Results use; counts -> probabilities (0.50/0.34, 0.84/0.70); sign claim now backed by range -0.04..0.18 (Fig 2B data: h=5,f=0.195 and h=2,f=0.185); band-width control MOVED here from P5 with a purpose sentence (band scale at switch 75.7 at h=0.1 vs 0.07 at h=100, verified), gaps stated in words.
- P3 (finite-size-results.tex): all five sizes; starting markets reused per added fraction; active conditions announced + "within 0.01" (max diff 0.007, Table S finite-size); "sharper response" -> steeper rise in f; f50 and width split; width defined in f; "sampled maximum" -> largest over tested fractions; 0.0035 vs shift; alternative thresholds/horizons now state the result (midpoint fell with time at L=32/64/128 under criteria 0.4/0.5/0.6); closer covers size and time.
- P4: bridge from P3; selection stated with the five fraction/outcome groups; 0.150 -> 0.15; late-majority term removed; control ceiling 1.15%; 25.30% belongs to a late-majority market (seed 30, onset 5,151); closer adds the drawdown finding.
- P5: band-width detour removed (now P2); hypothesis stated in the lead; mechanism = same net sale is a larger share of a small reserve (Eq. price update); controls tied to mechanism; "Much of the decline" dropped; rejection in per-million (226, 34, 0.6; medians 2.256e-4, 3.400e-5, 6.04e-7); h=0 outcome (drawdown 0, all majorities); closer scoped to f=0.20 and to switched markets and controls.
- P6: depths h=0.1,1,100 named; mechanism before held result; range "on both sides of the held value"; "switched markets"; "reserve curve" -> dealer's reserves; negated rejection sentence rewritten, cites B,C; "majority decision" -> "Sell majority".

## Left for the author (would change a claim or its scope)
- P6 cash comparison (S6, S8): cash effect is reported at h=1 where drawdown is saturated (96.46 -> 97.10). At h=100 with shares x1, cash x10 raised median drawdown 20.18 -> 28.48% (x0.1 shares: 3.17 -> 18.42%). The closer claims dependence on cash; the h=100 numbers support it, the h=1 numbers do not.
- P5 paired increase in percentage points (22.96 vs 24.39) hides that 77% -> 99.99% is a much larger fall in log price. Consider a log-price or remaining-value statement.
- P2 depth dependence near the crossover (0.44 vs 0.50 at n=50) is within Wilson noise; wording now "was 0.06 lower", not "affected".
- P3 no mechanism for why larger grids need a smaller f; and the L=64/9,000-step midpoint (0.167) equals L=128/3,000 (0.166), so a reader may ask whether size is partly a time effect.
- P3 susceptibility growth has no interpretation (peak chi rose 11.4x while (L-2)^2 rose 17.6x).
| 2 | 1 | P1-P2 | 0 | 9 | 11 |
| 2 | 2 | P3-P4 | 0 | 11 | 15 |
| 2 | 3 | P5-P6 | 0 | 11 | 8 |

## Round 2 triage
- P1: pulse sets intentions (not trades); rule screen names the six (incl. 19286) and the twelve by direction; the two failures named (Buy->Hold at sums 1, 2).
- P2: purpose for varying depth; "held decision" -> "decision in the held condition"; price moves only at positive depths; sign claim replaced by "at most 0.18, negative by at most 0.04 in two of 88 combinations" (verified: h=2,f=0.190 -0.02; h=5,f=0.195 -0.04); band test given a direction-neutral purpose; gap sentence split.
- P3: f50 cites Fig 3C, width cites 3A (caption check); width condition + endpoints; logistic check moved next to f50; susceptibility gloss = definition (not "variation between markets", which is misleading across sizes) + "consistent with the sharper rise"; time shift compared with size shift (0.011 vs 0.012); 0.4/0.6 described as a threshold, not a "majority"; closer split.
- P4: why f=0.15 (0/50 at 3,000 steps); runs, not starting markets, are extended; control scale (1.15%) before switched drawdowns; example drawdown moved after and given its table ref; closer says larger than what.
- P5: hypothesis phrased as dealer buying; same campaign as P2; majority at f=0.20 covers both conditions; h=40/400 "on the same trend"; control mechanism = price swings (h=0.1 controls: median final log change -0.09 but drawdown 77%); paired increase adds h=1 (66.55) and the ceiling at h=0.1; "limit" -> "case"; example states its finding (starting market 2: 99.98/99.46/24.86%); closer drops "once a majority formed" for controls.
- P6: held Wilson interval [0.50, 0.76] (shown in Fig 6A); no-controls caveat; dealer reserves not rescaled; "below 0.5%" (max 0.478%); dropped unsupported "how many shares could change hands".
- Split five long sentences (median 29 -> 28; p90 45 -> 39).
| 3 | 1 | P1-P2 | 0 | 9 | 13 |
| 3 | 2 | P3-P4 | 0 | 10 | 16 |
| 3 | 3 | P5-P6 | 0 | 9 | 9 |

## Round 3 triage
- P1: rule screen names the six exactly (Sell at each sum 1-5 incl. 19286, plus Buy->Hold at sum 3) and the twelve; cites Fig 1B for the lookup table; S4/S5 split so the 0->50 jump reads cleanly.
- P2: opening now acknowledges that pulse and screen outcomes were identical held vs active; crossover defined before use with direction ("mostly raised"); difference counts 22 positive / 2 negative / 64 zero of 88 (verified); band-width side test condensed to one sentence + pointer to Table S band and Appendix (the full numbers already live in revision-controls.tex).
- P3: active midpoints within 0.007 (0.001 at L=128); susceptibility sentence gives the independence bound (chi <= 0.25 if traders ended in Sell independently) -> outcomes shared across each market; time-vs-size comparison states its implication; "Its position" -> "The position of the rise".
- P4: FIX OF A PRE-EXISTING ERROR: the 12.29% (3,000 steps) and 25.30% (10,000 steps) largest drawdowns belong to different markets (starting markets 12 and 30); text no longer implies one market rose. Example drawdown moved next to its onset (Fig 4B); "mixed" -> "without a majority"; control/switched comparison made explicit ("even the largest control ... smaller than the median switched"); new stated finding: the switch lowered prices before any majority (3,000 steps: 0/50 majorities, median switched drawdown 5.04% vs max control 1.15%; median price change -3.40% vs +0.06%).
- P5: "nonetheless" contrast made explicit; paired increase now 22.96 (h=0.1) -> 80.31 max (h=5) -> 24.39 (h=100) with the two-ended mechanism; referent fixes.
- P6: multipliers stated; f=0.18 located near the held midpoint 0.178; held Wilson [0.50, 0.76] and active 0.58-0.60 at unchanged resources; share mechanism = traders run out of shares less often (median sell suppression 0.45/0.35/0.21 at h=100); rejection bound in per million (< 5,000; max 4,784); closer names both comparisons.
| 4 | 1 | P1-P2 | 1 | 10 | 12 |
| 4 | 2 | P3-P4 | 0 | 6 | 21 |
| 4 | 3 | P5-P6 | 0 | 8 | 12 |

## Round 4 triage
- SEV-3 (P2 band-width sentence): deleted, per the author's rule that a sentence flagged as unclear twice is deleted rather than reworded (flagged in all four rounds, in both positions). The numbers remain in revision-controls.tex and the Discussion still cites Table S band.
- P1: pulse purpose = "whether a single burst of Sell intentions could do the same"; the five Sell rules stated per sum with the baseline outputs.
- P2: opening is now a bridge from P1's identical held/active outcomes; eight depths listed (0, 0.1, 0.5, 1, 2, 5, 10, 100, verified in data); crossover defined in its own sentence; h=0 zero difference explained (fixed price at mu with sigma=0 keeps technical traders in Hold; Table S band h=0 Sell fraction 0.000).
- P3: active midpoints direction + scale; width sentence split; susceptibility: bound first, then values, then "traders within each market ended in Sell together rather than independently".
- P4: control/switched drawdown sentences split; the 12.29/25.30 sentence says "in a different market"; "deepened price declines" (drawdown evidence) instead of "lowered prices".
- P5: "nonetheless" contrast; control mechanism names both-direction swings and what drawdown records.
- P6: 64x64 grid named; active range pattern (five highest all at share multiplier 0.1, verified); share mechanism = fewer Sell orders blocked for lack of shares.
| 5 | 1 | P1-P2 | 0 | 5 | 12 |
| 5 | 2 | P3-P4 | 0 | 3 | 22 |
| 5 | 3 | P5-P6 | 0 | 10 | 12 |

## Round 5 triage
- Fixed in place: lead question now matches the "reached at least once" definition; screen sentence no longer splits its verb; P2 bridge cites only the rule screen (pulse null says nothing about feedback); active-midpoint sentence simplified; 0.4/0.6 described as the Sell fraction required to count a run; f=0.15 ensemble statistics scoped to "the 50 switched markets at this fraction"; h=40/400 described as outside the eight-depth sweep; paired peak given units and its h=5 control/switched medians (14.03/94.43, Table S2); why the dealer rarely refused (constant product: can always buy more at a lower price); active 0.58-0.60 "slightly below the held value"; share 0.1 gave the smallest drawdown in every cash-by-depth row, so higher majority probability did not bring larger drawdown (Fig 6D; Spearman 0.05 across 27).
- Left for the author: cash comparison at h=1 (5th flag); abstract "limited trading resources did not generally protect" vs shares x0.1 cutting drawdown sixfold at h=100; active below held at f=0.18; sum-3 Buy->Hold mechanism; paired uncertainty for active-held; Fig 2 caption's "distinct" h=10 overlay.
| 6 | 1 | P1-P2 | 0 | 6 | 18 |
| 6 | 2 | P3-P4 | 0 | 5 | 24 |
| 6 | 3 | P5-P6 | 0 | 10 | 13 |
