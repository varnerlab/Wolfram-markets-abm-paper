# Simulation and analysis code

This directory contains the Julia environment for the endogenous
cellular-automaton market and the archived external-price prototype.

## Setup

Install Julia 1.9 or later, then instantiate the project:

```bash
julia --project=code -e 'using Pkg; Pkg.instantiate()'
```

The revised manuscript does not require the QQQ input. It is retained only for
the archived Model A prototype described in [`data/README.md`](data/README.md).

## Commands

From the repository root:

```bash
bash code/run_all.sh tests
bash code/run_all.sh figures
bash code/run_all.sh all
```

`tests` is the safe default. `figures` rebuilds the paper figures from existing
derived data. `all` first runs tests, then the expensive simulations, then the
figure scripts. The runner stops at the first failure and writes
`code/run_all.log`. It defaults to 12 simulation threads and one garbage-
collection thread; set `MARKET_ABM_THREADS` or `MARKET_ABM_GC_THREADS` to
override those conservative production defaults.

The paper is built separately:

```bash
cd paper-arxiv
make
```

## Layout

- `src/`: shared CA types, factories, simulation, and file utilities.
- `model-a/`: archived externally forced classroom prototype.
- `model-b/`: principal feedback-closed model, explicit-dealer experiments,
  interventions, tests, and figures.
- `data/`: external-input documentation and generated tabular outputs.
- `figs/`: generated figures.

Model B includes an explicit dealer ledger. The `h = Inf` limit permits dealer
borrowing and shorting and reproduces the historical fill-all convention;
finite `h` imposes cash and inventory bounds, and whole-system cash and shares
are conserved outside deliberate balance-sheet interventions.
