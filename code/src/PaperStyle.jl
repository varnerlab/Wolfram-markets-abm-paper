# PaperStyle.jl
# Single source of truth for figure style. The state colors are the Okabe-Ito
# values already declared in paper-arxiv/Paper_v1.tex via \definecolor, so the
# TikZ schematic (Figure 1) and every data figure share one color language.
# Changing a value here changes it in the paper only if the \definecolor block
# is changed to match.

using Colors
using Plots

const _BUY_COLOR  = "#0072B2"   # \definecolor{buyblue}
const _HOLD_COLOR = "#AAAAAA"   # \definecolor{holdgray}
const _SELL_COLOR = "#D55E00"   # \definecolor{sellorange}
const _EDGE_COLOR = "#009E73"   # \definecolor{edgegreen}

# Non-state series: cash levels, configurations, doses, arms. Rest of Okabe-Ito.
const _SERIES_COLORS = ["#E69F00", "#56B4E9", "#CC79A7", "#F0E442", "#000000"]

const _panel_kw = (
    background_color_inside = RGB(0.94, 0.94, 0.94),
    background_color_outside = :white,
    foreground_color_grid = RGB(1.0, 1.0, 1.0),
    gridalpha = 0.8,
    gridlinewidth = 0.5,
    framestyle = :box,
    fg_legend = :transparent,
    tickfontsize = 9,
    guidefontsize = 10,
    legendfontsize = 8,
    titlefontsize = 11,
    margin = 5Plots.mm,
)

_grid_cgrad() = cgrad([_BUY_COLOR, _HOLD_COLOR, _SELL_COLOR], [0.0, 0.5, 1.0])

"""
    _panel_letter!(plt, letter)

Draw a bold panel letter at the top left of `plt`. Captions reference these as
\\textbf{(A)}; never use positional language like "top row" in a caption.
"""
function _panel_letter!(plt, letter::String)
    annotate!(plt, (0.02, 1.06), text(letter, :black, :left, 12, :bold))
    return plt
end
