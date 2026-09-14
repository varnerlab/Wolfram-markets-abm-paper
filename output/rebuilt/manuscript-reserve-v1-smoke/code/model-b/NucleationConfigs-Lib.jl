# NucleationConfigs-Lib.jl -- shared Model B configuration builders, moved
# verbatim out of Compute-ModelB-NucleationSeeds.jl (_probe_config) and
# Compute-ModelB-BudgetToggle.jl (_toggle_config). Pure move: bodies are
# unchanged. Both functions reference GRIDN, STEPS, P0 as globals — those
# constants stay defined in each campaign script (their values legitimately
# differ between scripts, e.g. BudgetToggle's GRIDN/STEPS depend on
# TOGGLE_SMOKE) and are resolved from whichever script includes this file, so
# they are NOT redefined here and NOT added as arguments.

function _probe_config(; f, cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = f,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end

function _toggle_config(; cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = 0.20,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end
