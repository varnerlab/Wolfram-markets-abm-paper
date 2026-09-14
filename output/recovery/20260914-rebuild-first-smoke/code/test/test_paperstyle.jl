include(joinpath(@__DIR__, "..", "src", "PaperStyle.jl"))

@assert _BUY_COLOR  == "#0072B2" "Buy color must match \\definecolor{buyblue}"
@assert _HOLD_COLOR == "#AAAAAA" "Hold color must match \\definecolor{holdgray}"
@assert _SELL_COLOR == "#D55E00" "Sell color must match \\definecolor{sellorange}"
@assert _EDGE_COLOR == "#009E73" "Edge color must match \\definecolor{edgegreen}"
@assert length(_SERIES_COLORS) >= 4 "need at least four non-state series colors"
@assert !(_BUY_COLOR in _SERIES_COLORS) "series colors must not collide with state colors"
@assert haskey(pairs(_panel_kw), :framestyle) "_panel_kw must set framestyle"
@assert _panel_kw.framestyle == :box
println("PaperStyle OK")
