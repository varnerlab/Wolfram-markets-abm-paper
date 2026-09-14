using CSV, DataFrames, Statistics
ENV["GKSwstype"]="100"
include(joinpath(@__DIR__,"..","src","PaperStyle.jl"))

function plot_following(stage)
    root=normpath(joinpath(@__DIR__,"..",".."))
    data=CSV.read(joinpath(root,"code","data","Following-"*uppercasefirst(stage)*"-Grouped.csv"),DataFrame)
    output=joinpath(root,"output","following");mkpath(output)
    outcomes=[("others_sell_difference","Non-follower Sell change (pp)"),
              ("followers_return_difference","Follower return change (pp)"),
              ("followers_drawdown_difference","Follower drawdown change (pp)"),
              ("maximum_drawdown","Price drawdown (%)"),
              ("sell_rejection","Eligible sells rejected (%)"),
              ("transitioned","Sell-majority probability (%)")]
    capacities=sort(unique(data.h))
    for mechanism in ("advice","copy_filled"), (metric,ylabel) in outcomes
        panels=Plots.Plot[]
        for boundary in ("hold","endogenous"), h in capacities
            d=data[(data.mode.==mechanism).&(data.metric.==metric).&
                   (data.boundary.==boundary).&(data.h.==h),:]
            title=(boundary=="hold" ? "Technical traders held" : "Technical traders active")*
                  "; h = "*(isinf(h) ? "unlimited" : string(h))
            p=plot(;_panel_kw...,xlabel="Following traders (%)",ylabel,title,
                   legend=:best,size=(480,350))
            occursin("difference",metric) && hline!(p,[0.];color=:gray,linestyle=:dash,label="")
            for (index,k) in enumerate((1,4,16,0))
                series=sort(d[d.K.==k,:],:a)
                isempty(series) && continue
                color=_SERIES_COLORS[index]
                x=100series.a;y=100series.estimate
                lower=max.(0.,100 .* (series.estimate.-series.lower))
                upper=max.(0.,100 .* (series.upper.-series.estimate))
                plot!(p,x,y;yerror=(lower,upper),marker=:circle,markersize=3,
                      linewidth=1.6,color,label=k==0 ? "Independent advice" : "$k source"*(k==1 ? "" : "s"))
            end
            push!(panels,p)
        end
        combined=plot(panels...;layout=(2,length(capacities)),
                      size=(470length(capacities),740),dpi=150)
        filename=stage*"-"*mechanism*"-"*metric
        savefig(combined,joinpath(output,filename*".pdf"))
        savefig(combined,joinpath(output,filename*".png"))
    end
end

plot_following(isempty(ARGS) ? "pilot" : only(ARGS))
