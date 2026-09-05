# Wolfram cellular-automaton market

This repository contains the manuscript and Julia implementation for a
three-state spatial market with paired rule quenches, agent balance sheets,
endogenous price feedback, and an explicit finite-or-unlimited dealer.

From the repository root:

```bash
bash code/run_all.sh tests
bash code/run_all.sh figures
bash code/run_all.sh all
```

`tests` is the default verification path. `figures` rebuilds the revised paper
figures from committed production CSVs. `all` reruns the production campaigns
before rebuilding figures. See [`code/data/README.md`](code/data/README.md) for
the campaign inventory and data provenance.

The peer-review follow-up is documented in [peer-review-response.md](peer-review-response.md).
Run `bash code/run_all.sh revision` to reproduce its added controls; see
[code/revision/README.md](code/revision/README.md) for the complete protocol.
