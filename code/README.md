# Simulation and analysis code

The current manuscript uses reserve clearing. Its complete executed source
snapshot is `output/rebuilt/manuscript-reserve-v1/code/`; reproduce it through
[rebuild/README.md](rebuild/README.md). Every retained condition was rerun
with full financial histories, including held technical traders.

The shared simulator supports both the corrected `clearing=:reserve`
mechanism and historical `clearing=:legacy`. Historical callers retain
their original default. The corrected manuscript wrapper explicitly selects
reserve clearing and checks conservation, resources, prices, and execution
provenance for every simulation.

## Environment and reproduction

The production run used Julia 1.12.7 with twelve simulation threads and one
garbage-collection thread. The recorded checkpoint scheduler requires Julia
1.11 or later. Julia package versions are pinned in `Project.toml` and
`Manifest.toml`; Python versions are recorded in the study's
`Runtime-Environment.json`.

```sh
julia --project=code -e 'using Pkg; Pkg.instantiate()'
bash code/run_all.sh repaired-tests
```

Use `code/rebuild/ColdClone.py` to create another empty-data copy of the
executed study, then its `Run.py` and postprocessing commands. The current
PDF can be compiled separately with `make -C paper-arxiv`. Neither the
corrected manuscript nor its simulations require the archived QQQ input.

## Layout

- `src/`: shared decision rules, financial simulator, reserve clearing, and utilities.
- `rebuild/`: clean-study preparation, execution, verification, figures, and manuscript generation.
- `repaired/`: repair checks and separate advice-transmission studies.
- `model-b/` and `revision/`: historical standing-quote experiment drivers; the adapted corrected copies live in the executed snapshot.
- `following/`: historical advice experiments, superseded by their reserve-model versions.
- `model-a/`: archived external-price prototype.
- `data/`: historical summaries and input documentation; current manuscript data live in the isolated study.
- `figs/`: generated figures, including the six installed corrected manuscript figures.

The historical `all`, `figures`, and `revision` runner modes are blocked
after the corrected manuscript is installed. They would otherwise copy
historical tables and figures over the corrected outputs. This restriction
does not remove the historical source or data.
