include("Following-Controls-Lib.jl")
stage=isempty(ARGS) ? "diagnostic-smoke" : ARGS[1]
run_following_diagnostics(stage;sensitivities="--sensitivities" in ARGS)
