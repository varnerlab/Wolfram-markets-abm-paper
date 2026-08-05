# Simulation and analysis code

This directory contains the Julia environment for both models.

## Setup

Install Julia 1.9 or later, then instantiate the project:

```bash
julia --project=code -e 'using Pkg; Pkg.instantiate()'
```

Model A recomputation also requires the QQQ input described in
[`data/README.md`](data/README.md).

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
`code/run_all.log`.

The paper is built separately:

```bash
cd paper-arxiv
make
```

## Layout

- `src/`: shared CA types, factories, simulation, and file utilities.
- `model-a/`: externally forced Model A computations and figures.
- `model-b/`: feedback-closed Model B computations, interventions, tests, and
  figures.
- `data/`: external-input documentation and generated tabular outputs.
- `figs/`: generated figures.

Model B is feedback-closed, not economically closed: agents trade with an
unmodeled counterparty that can absorb orders without an explicit inventory or
cash constraint.
