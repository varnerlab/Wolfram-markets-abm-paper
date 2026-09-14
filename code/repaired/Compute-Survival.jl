include("../following/Following-Lib.jl")

function survival_metrics(r,pre)
    sell=r.sell_fraction[pre+2:end]
    cash=r.total_cash.+r.market_maker_cash
    shares=r.total_shares.+r.market_maker_inventory
    error_cash=maximum(abs.(cash.-cash[1]))
    @assert error_cash<max(1e-5,abs(cash[1])*1e-10)
    @assert all(==(shares[1]),shares)
    product=r.market_maker_cash.*r.market_maker_inventory
    @assert maximum(abs.(product./product[1].-1))<1e-9
    @assert all(r.prices.>0)
    @assert all(r.final_books.cash.>=-1e-9) && all(r.final_books.shares.>=0)
    post=pre+1:length(r.log_returns)
    rejected=sum(r.market_maker_rejected_buys[post])+sum(r.market_maker_rejected_sells[post])
    executed=sum(r.executed_buys[post])+sum(r.executed_sells[post])
    dealer=r.final_market_maker
    n=(r.config.number_of_rows-2)^2+length(r.edge_coordinates)
    (;transitioned=any(sell.>=0.5),onset=something(findfirst(>=(0.5),sell),0),
       final_sell_mean=mean(sell[max(1,end-499):end]),
       maximum_drawdown=compute_max_drawdown(r.prices[pre+1:end]),
       rejection_fraction=following_ratio(rejected,rejected+executed),
       executed_buys=sum(r.executed_buys[post]),executed_sells=sum(r.executed_sells[post]),
       final_price=r.prices[end],adoption_price=r.prices[pre+1],
       dealer_cash_per_trader=dealer.cash/n,dealer_inventory_per_trader=dealer.inventory/n,
       dealer_equity_change_per_trader=(dealer.cash+dealer.inventory*r.prices[end]-
           dealer.initial_cash-dealer.initial_inventory*r.config.P0)/n,
       maximum_cash_error=error_cash,maximum_product_error=maximum(abs.(product./product[1].-1)))
end

function compute_survival(stage="full")
    stage in ("smoke","full") || error("stage must be smoke or full")
    pre,post,L,seeds=stage=="smoke" ? (20,80,12,1:2) : (1000,3000,64,1:50)
    jobs=[(;seed,h,boundary,L,pre,post,f) for seed in seeds, h in (0.1,1.,10.,100.),
          boundary in ("hold","endogenous"),f in (0.,0.15,0.175,0.20)]
    manifest=DataFrame(vec(jobs))
    output=joinpath(FOLLOWING_ROOT,"output","repaired","reserve-v2-"*stage)
    checkpoints=joinpath(output,"checkpoints");mkpath(checkpoints)
    io=IOBuffer();CSV.write(io,manifest);manifest_bytes=take!(io)
    digest=bytes2hex(sha256(following_source_digest()*read(@__FILE__,String)))
    metadata=Dict("version"=>"reserve-v2","source_digest"=>digest,
        "manifest_digest"=>bytes2hex(sha256(manifest_bytes)),"julia_version"=>string(VERSION),
        "environment_digest"=>bytes2hex(sha256(read(joinpath(FOLLOWING_ROOT,"code","Manifest.toml")))))
    protocol=joinpath(output,"Protocol.toml")
    if isfile(protocol)
        saved=TOML.parsefile(protocol)
        all(get(saved,k,nothing)==v for (k,v) in metadata) || error("changed campaign; use a new version")
        read(joinpath(output,"Manifest.csv"))==manifest_bytes || error("changed manifest")
    else
        metadata["created_utc"]=string(now(UTC))
        open(protocol,"w") do io;TOML.print(io,metadata);end
        write(joinpath(output,"Manifest.csv"),manifest_bytes)
    end
    blocks=unique([(j.seed,j.h,j.boundary) for j in vec(jobs)])
    results=Vector{DataFrame}(undef,length(blocks))
    done=Threads.Atomic{Int}(0)
    @info "Reserve survival campaign" stage runs=nrow(manifest) blocks=length(blocks)
    Threads.@threads :dynamic for index in eachindex(blocks)
        seed,h,boundary=blocks[index]
        path=joinpath(checkpoints,"$(seed)-$(h)-$(boundary).csv")
        if isfile(path)
            data=CSV.read(path,DataFrame)
            @assert nrow(data)==4 && all(data.seed.==seed) && all(data.h.==h)
            @assert all(data.boundary.==boundary) && Set(data.f)==Set((0.,0.15,0.175,0.20))
            results[index]=data
        else
            config(f)=following_config(;L,seed,pre,post,h,minority_fraction=f)
            args=(;minority_population=:interior,boundary_mode=Symbol(boundary),
                    snapshot_steps=[pre],verbose=false,clearing=:reserve)
            control=simulate(config(0.20);args...,rule_activation_step=pre+post+1)
            cm=survival_metrics(control,pre)
            rows=NamedTuple[]
            for f in (0.,0.15,0.175,0.20)
                r=f==0 ? control : simulate(config(f);args...,rule_activation_step=pre+1)
                @assert r.frames[pre]==control.frames[pre]
                @assert r.prices[1:pre+2]==control.prices[1:pre+2]
                @assert r.total_cash[1:pre+1]==control.total_cash[1:pre+1]
                m=survival_metrics(r,pre)
                # One complete legacy replay per held condition verifies that
                # pricing cannot change the original local-rule decision history.
                held_identity=true
                if boundary=="hold" && f==0.20
                    legacy=simulate(config(f);minority_population=:interior,
                        boundary_mode=:hold,snapshot_steps=[pre],verbose=false,rule_activation_step=pre+1)
                    held_identity=legacy.sell_fraction==r.sell_fraction && legacy.frames[pre+post]==r.frames[pre+post]
                    @assert held_identity
                end
                push!(rows,merge((;seed,h,boundary,L,pre,post,f,held_identity),m,
                    (control_transitioned=cm.transitioned,control_drawdown=cm.maximum_drawdown,
                     drawdown_difference=m.maximum_drawdown-cm.maximum_drawdown,
                     transition_difference=Int(m.transitioned)-Int(cm.transitioned))))
            end
            data=DataFrame(rows)
            CSV.write(path*".tmp",data);mv(path*".tmp",path;force=true)
            results[index]=data
        end
        completed=Threads.atomic_add!(done,1)+1
        completed%10==0 && @info "Reserve blocks saved" completed total=length(blocks)
    end
    summary=reduce(vcat,results)
    @assert nrow(summary)==nrow(manifest)
    keys=[:seed,:h,:boundary,:L,:pre,:post,:f]
    @assert Set(Tuple(r) for r in eachrow(summary[:,keys]))==Set(Tuple(r) for r in eachrow(manifest[:,keys]))
    sort!(summary,[:boundary,:h,:f,:seed])
    CSV.write(joinpath(output,"Summary.csv.tmp"),summary)
    mv(joinpath(output,"Summary.csv.tmp"),joinpath(output,"Summary.csv");force=true)
    @info "Reserve survival complete" stage runs=nrow(summary) output
end

if abspath(PROGRAM_FILE)==@__FILE__
    compute_survival(isempty(ARGS) ? "full" : only(ARGS))
end
