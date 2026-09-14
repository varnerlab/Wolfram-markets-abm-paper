# Files.jl — Data loading and simulation I/O

"""
    load_price_data(path) → DataFrame

Load OHLC price data from a CSV file.
Expected columns: Open, High, Low, Close (plus a date/time column).
"""
function load_price_data(path::String)::DataFrame
    return CSV.read(path, DataFrame)
end

"""
    save_simulation(path, result)

Persist a MySimulationResult to a JLD2 file.
"""
function save_simulation(path::String, result::MySimulationResult)
    save(path, Dict(
        "frames"        => result.frames,
        "prices"        => result.prices,
        "net_imbalance" => result.net_imbalance,
        "edge_states"   => result.edge_states,
    ))
end

"""
    load_simulation(path) → MySimulationResult

Load a previously saved MySimulationResult from a JLD2 file.
"""
function load_simulation(path::String)::MySimulationResult
    d = load(path)
    return MySimulationResult(
        d["frames"],
        d["prices"],
        d["net_imbalance"],
        d["edge_states"],
    )
end
