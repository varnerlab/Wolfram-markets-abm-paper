include("Compute-Following-Pilot.jl")

"""The existing simultaneous-exit rule, retaining books for cash attribution."""
function reserve_exit_ledger(run)
    o,r=run.observer,run.result
    ids=o.trader_ids
    books=deepcopy(r.final_books); dealer=deepcopy(r.final_market_maker)
    initial_cash=sum(books.cash[ids])+dealer.cash
    initial_shares=sum(books.shares[ids])+dealer.inventory
    initial_product=dealer.cash*dealer.inventory
    grid=fill(1,size(books.cash)); states=fill(1,length(r.edge_coordinates))
    price=r.prices[end]; rounds=0
    for step in 1:maximum(books.shares[ids];init=0)
        for id in o.population.interior
            grid[id]=books.shares[id]>0 ? 2 : 1
        end
        for (i,(row,col)) in enumerate(r.edge_coordinates)
            states[i]=books.shares[row,col]>0 ? 2 : 1
        end
        counts=execute_reserve_orders!(books,grid,r.edge_coordinates,states,price;
            market_maker=dealer,cost_basis_rule=false,seed=o.config.seed,
            step=o.config.steps+step)
        @assert counts.executed_buys==0
        rounds=step
        counts.executed_sells==0 && break
        price=counts.next_price
    end
    cash_error=sum(books.cash[ids])+dealer.cash-initial_cash
    @assert abs(cash_error)<=max(1e-5,abs(initial_cash)*1e-11)
    @assert all(iszero,books.shares[ids])
    @assert dealer.inventory==initial_shares
    @assert isapprox(dealer.cash*dealer.inventory,initial_product;rtol=1e-10)
    (;books,dealer,price,rounds,cash_error)
end

function transmission_exit_metrics(run,control,exit,control_exit)
    o=run.observer
    ids=o.trader_ids; followers=o.population.followers
    remaining=setdiff(ids,followers)
    normalized(ledger,cohort)=isempty(cohort) ? NaN :
        mean(ledger.books.cash[cohort]./o.start_value[cohort])
    live_cash=normalized(exit,followers); base_cash=normalized(control_exit,followers)
    follower_cash=sum(exit.books.cash[followers])-sum(control_exit.books.cash[followers])
    remaining_cash=sum(exit.books.cash[remaining])-sum(control_exit.books.cash[remaining])
    dealer_cash=exit.dealer.cash-control_exit.dealer.cash
    tolerance=max(1e-5,sum(control_exit.books.cash[ids])*1e-10)
    @assert abs(follower_cash+remaining_cash+dealer_cash)<tolerance
    @assert abs(dealer_cash)<tolerance
    @assert abs(follower_cash+remaining_cash)<tolerance
    (;exit_cash_difference=live_cash-base_cash,
       wind_followers_final_cash=live_cash,control_wind_followers_final_cash=base_cash,
       remaining_exit_cash_difference=normalized(exit,remaining)-normalized(control_exit,remaining),
       follower_cash_difference=follower_cash,remaining_cash_difference=remaining_cash,
       dealer_cash_difference=dealer_cash,total_trader_cash_difference=follower_cash+remaining_cash,
       exit_unsold_shares=sum(exit.books.shares[ids]),
       control_exit_unsold_shares=sum(control_exit.books.shares[ids]),
       exit_cash_error=exit.cash_error,exit_price=exit.price)
end

function transmission_jobs(smoke=false)
    L,pre,post,seeds,reps=smoke ? (12,20,80,631001:631001,1:1) :
                                (64,1000,3000,631001:631010,1:2)
    jobs=NamedTuple[]
    stage=smoke ? "reserve-transmission-smoke-v1" : "reserve-transmission-pilot-v1"
    for seed in seeds,replicate in reps,h in (1.,100.),boundary in ("hold","endogenous")
        base=(;stage,seed,replicate,h,boundary,L,pre,post)
        push!(jobs,following_job(;base...,mode="none",a=0.,K=1,diagnostic="control"))
        for a in (0.1,0.4),independent in (false,true),diagnostic in ("live","mask","withdrawal")
            push!(jobs,following_job(;base...,mode="advice",a,independent,
                K=independent ? 0 : 1,diagnostic,
                stop_after=diagnostic=="withdrawal" ? pre : post))
        end
    end
    jobs
end

function transmission_checks(run,control,live,j)
    o,b=run.observer,control.observer
    @assert o.start_fingerprint==b.start_fingerprint
    @assert run.result.prices[1:j.pre+1]==control.result.prices[1:j.pre+1]
    invariant=run.result.market_maker_cash.*run.result.market_maker_inventory
    @assert maximum(abs.(invariant./invariant[1].-1))<1e-9
    @assert run.result.prices≈run.result.market_maker_cash./run.result.market_maker_inventory
    same_orders=true; held_identity=true; withdrawal_identity=true
    if j.diagnostic=="mask"
        follower_ids=o.population.followers
        same_orders=o.state_tape[follower_ids,:]==live.observer.state_tape[follower_ids,:]
        @assert same_orders
        if j.boundary=="hold"
            nonfollowers=setdiff(o.population.interior,follower_ids)
            held_identity=o.state_tape[nonfollowers,:]==b.state_tape[nonfollowers,:]
            @assert held_identity
        end
    elseif j.diagnostic=="withdrawal"
        last_advised=j.pre+j.stop_after
        withdrawal_identity=o.state_tape[:,1:last_advised]==live.observer.state_tape[:,1:last_advised] &&
            run.result.prices[1:last_advised+1]==live.result.prices[1:last_advised+1]
        @assert withdrawal_identity
    end
    (;same_advice_orders=same_orders,held_mask_identity=held_identity,withdrawal_prefix_identity=withdrawal_identity)
end

function transmission_late_metrics(run,control)
    o=run.observer; ids=o.population.others
    pre=o.protocol.pre; total=o.config.steps
    delta(span)=mean((@view o.state_tape[ids,span]).==2)-
                mean((@view control.observer.state_tape[ids,span]).==2)
    (;after_withdrawal_others_sell_difference=delta(2pre+1:total),
       late_others_sell_difference=delta(max(pre+1,total-499):total))
end

function transmission_block(group,directory)
    base=only(filter(j->j.mode=="none",group))
    path=joinpath(directory,base.job_id*".csv")
    if isfile(path)
        saved=CSV.read(path,DataFrame)
        @assert nrow(saved)==length(group) && Set(saved.job_id)==Set(j.job_id for j in group)
        return saved
    end
    config=following_config(L=base.L,seed=base.seed,pre=base.pre,post=base.post,h=base.h)
    boundary=Symbol(base.boundary)
    control=run_following(config,protocol_from_job(base);boundary,clearing=:reserve,record_states=true)
    control_exit=reserve_exit_ledger(control)
    rows=NamedTuple[]
    base_row=merge(following_row(NamedTuple(base),control,control,NamedTuple(base)),
        transmission_exit_metrics(control,control,control_exit,control_exit),
        transmission_late_metrics(control,control),transmission_checks(control,control,control,base))
    push!(rows,base_row)
    for a in (0.1,0.4),independent in (false,true)
        arm_jobs=filter(j->j.mode!="none" && j.a==a && j.independent==independent,group)
        live_job=only(filter(j->j.diagnostic=="live",arm_jobs))
        live=run_following(config,protocol_from_job(live_job);boundary,clearing=:reserve,record_states=true)
        for j in arm_jobs
            run=j.diagnostic=="live" ? live : run_following(config,protocol_from_job(j);
                boundary,clearing=:reserve,record_states=true,
                masked_states=j.diagnostic=="mask" ? control.observer.state_tape : nothing)
            exit=reserve_exit_ledger(run)
            row=merge(following_row(NamedTuple(j),run,control,NamedTuple(base)),
                transmission_exit_metrics(run,control,exit,control_exit),
                transmission_late_metrics(run,control),transmission_checks(run,control,live,j))
            push!(rows,row)
        end
    end
    data=DataFrame(rows)
    CSV.write(path*".tmp",data);mv(path*".tmp",path;force=true)
    data
end

function transmission_digest()
    source=following_source_digest()
    for path in ("code/following/Following-Controls-Lib.jl",
                 "code/repaired/Compute-Following-Pilot.jl",
                 "code/repaired/Transmission-Lib.jl","code/repaired/Compute-Transmission.jl")
        source*=path*read(joinpath(FOLLOWING_ROOT,path),String)
    end
    bytes2hex(sha256(source))
end
