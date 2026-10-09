# Response to the simulated review: inventory and public intentions

The 7 October discussion asked whether traders with no remaining shares
sustain the paper's selling cascades. The author clarified the main model's
interpretation: neighbors read publicly communicated trading intentions,
without observing the sender's holdings or verifying execution. This permits
influence without a transaction. The model does not give traders a separate
choice of what to announce and does not represent strategic misreporting.

We added a hypothetical inventory-information comparison rather than treating
inventory visibility as a description of actual markets. A zero-share sender's
Sell is read as Hold; its stored intention and the trading mechanism remain
unchanged. Four branches share the same pre-intervention history: original
or inventory-conditioned observations, each with and without the rule switch.
The frozen protocol and prescribed fraction extension produced 4,400 complete
financial trajectories over 50 new starting markets. The primary contrast
compares the rule-switch effects across the two observation modes.

At fraction 0.20, dealer depth 100, and with technical traders held, original
observations produced a majority in 50/50 switched markets, versus 0/50 with
inventory-conditioned observations. The primary change in the switch effect
on the late raw Sell fraction was -52.28 percentage points, with a 95% interval
of [-54.46, -49.86]. The mean paired drawdown increase over the no-switch
control fell from 23.16 to 2.02 percentage points. The extended sweep found
majorities in 44/50 inventory-conditioned markets at fraction 0.75, with a late
mean Sell fraction of 31.52%. The result identifies dependence on the
observation rule and does not establish that disclosure eliminates cascades.

The revision is in the abstract, Introduction, Methods, a brief Results statement,
Discussion, Conclusion, Appendix A.8, Table S17, and Fig. S2. The Results statement
reports the reduction in mean maximum drawdown from 24.36% to 3.23% at the
primary setting and refers to Fig. S2C and Table S17; detailed findings are
in Appendix A.8. Source data and
the executed protocol are in `output/rebuilt/inventory-visibility-v1/`;
generators are in `code/visibility/`. Independent technical review verified the
implementation, all 4,400 run summaries, all 160 paired contrasts and their
bootstrap intervals, and all 16 saved histories. Its scope correction was
applied: original held-market checkerboard independence does not extend to
inventory-conditioned observations, which add a financial route through
holdings into subsequent inputs.
