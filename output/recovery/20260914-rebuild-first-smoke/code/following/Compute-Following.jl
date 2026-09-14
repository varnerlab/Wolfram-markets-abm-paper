include("Following-Lib.jl")
stage=isempty(ARGS) ? "smoke" : only(ARGS)
run_following_campaign(stage)
