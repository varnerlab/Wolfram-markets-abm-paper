# Table1-RuleTaxonomy.jl
# Prints a LaTeX tabular for the rule taxonomy table.
# Paste the output into paper/sections/tables.tex.

include(joinpath(@__DIR__, "Include.jl"))

rules = [
    (6158,  "022110002", "Imitation / herding",  "Homogeneous model; stable wave patterns"),
    (19280, "222110002", "Majority rule",         "80\\% of agents in crash model; promotes herding"),
    (19286, "222110022", "Minority / contrarian", "20\\% of agents in crash model; destabilises grid"),
]

header = """
% ---- Table 1: Rule Taxonomy  (paste into paper) ----
\\begin{table}[h]
\\centering
\\caption{Wolfram totalistic CA rule taxonomy. Base-3 encoding reads right-to-left:
digit \$a_i\$ gives the next state when the neighbourhood sum index equals \$i\$.}
\\label{tab:rule-taxonomy}
\\begin{tabular}{ccll}
\\toprule
Rule index & Base-3 encoding & Economic interpretation & Role \\\\
\\midrule"""

println(header)
for (idx, b3, interp, role) in rules
    println("$(idx) & \$($(b3))_{3}\$ & $(interp) & $(role) \\\\")
end
println("""\\bottomrule
\\end{tabular}
\\end{table}
% ---- end Table 1 ----""")
