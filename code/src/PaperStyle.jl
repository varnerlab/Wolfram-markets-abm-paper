# PaperStyle.jl
# Single source of truth for figure style. The state colors are the Okabe-Ito
# values already declared in paper-arxiv/Paper_v1.tex via \definecolor, so the
# manuscript and every data figure share one color language.
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

# Font sizes are set for the source PDF canvases, which are reduced to roughly
# 0.45 of their native width in the manuscript.  These values therefore render
# at conventional journal sizes (about 7--8 pt guides and 6 pt ticks) after
# inclusion, rather than the 4--5 pt text produced by the earlier 9/10 pt
# source settings.
const _ANNOTATION_FONTSIZE = 9
const _STRIP_LABEL_FONTSIZE = 14

const _panel_kw = (
    background_color_inside = RGB(0.94, 0.94, 0.94),
    background_color_outside = :white,
    foreground_color_grid = RGB(1.0, 1.0, 1.0),
    gridalpha = 0.8,
    gridlinewidth = 0.5,
    framestyle = :box,
    fg_legend = :transparent,
    tickfontsize = 11,
    guidefontsize = 13,
    legendfontsize = 10,
    titlefontsize = 12,
    margin = 5Plots.mm,
)

_grid_cgrad() = cgrad([_BUY_COLOR, _HOLD_COLOR, _SELL_COLOR], [0.0, 0.5, 1.0])

"""
    _panel_letter!(plt, letter)

Draw a bold panel letter at the top left of `plt`. Captions reference these as
\\textbf{(A)}; never use positional language like "top row" in a caption.

The weight comes from the font FAMILY string "helvetica bold", not from a
`:bold` symbol. Plots' `Font` has no separate weight field (see
`Plots/src/components.jl`, `function font(args...)`): a bare `:bold` symbol
falls through `font()`'s type-based dispatch, fails `parse(Colorant, "bold")`,
and is taken as a literal font *family* named "bold". The GR backend then
looks up that name in its built-in `gr_font_family` table, fails to find an
entry, and falls back to `GR.loadfont("bold.ttf")`, which does not exist on
this system — hence the `GKS: could not find font bold.ttf` warning on every
run, and silently non-bold text. "helvetica bold" IS a key in that table
(mapped to GR's built-in font 107, no TTF file involved), so it renders true
bold with no warning; confirmed by rendering both side by side.

The relative y-position branches on the axis's own flip state. `annotate!`'s
relative-position path (`(rx, ry)` a fraction of the axis range, per
`locate_annotation(sp, rel::Tuple, label)` in Plots' `components.jl`) is
anchored to the DATA range, not the screen: on a normal (unflipped) axis,
`ry = 1.06` sits 6% above the top of the rendered panel, which is what every
call site wants. On a `yflip = true` axis (row/col spatial maps, drawn with
row 1 at the visual top), the data-range maximum renders at the visual
BOTTOM, so the same `ry = 1.06` places the letter 6% below the panel instead
of above it (first hit in Fig5-Nucleus.pdf's panel B; documented for the
montage case in Fig2-Combined.jl:68-77, which sidestepped it with a
dedicated unflipped blank corner panel rather than branching here). Querying
`plt.subplots[1][:yaxis][:flip]` is a cheap, reliable way to detect this
per-plot, so the branch lives in this one shared function instead of being
special-cased at every flipped call site.
"""
function _panel_letter!(plt, letter::String)
    flipped = plt.subplots[1][:yaxis][:flip]
    ry = flipped ? -0.06 : 1.06
    annotate!(plt, (0.02, ry), text(letter, :black, :left, 14, "helvetica bold"))
    return plt
end
