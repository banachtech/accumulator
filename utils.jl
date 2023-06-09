
Base.@kwdef mutable struct Args
    trade_cal = :USNYSE
    trade_date = today()
    effective_date = advancebdays(trade_cal, trade_date, 1)
    num_shares = 1
    boosted_num_shares = 2
    settlement_frequency = "1w"
    num_settlements = 12
    settlement_offset = 2
    gte_periods = 1
    spot_price = 1.0
    strike_price = 0.8
    ko_price = 1.0
end

Base.@kwdef mutable struct MktData
    rf = 0.03
    σ = 0.26
    β = 1.0
    div = 0.0
end

function date_offset(s::String; num=1)
    s = lowercase(s)
    n = length(s) > 1 ? Int(s[1])-48 : 1
    n *= num
    ofst = Week(n)
    if s[end] == 'w'
        ofst = Week(n)
    elseif s[end] == 'm'
        ofst = Month(n)
    elseif s[end] == 'd'
        ofst = Day(n)
    end
    return ofst
end

function advancebperiods(cal,d,s::String;num=1)
    s = lowercase(s)
    n = length(s) > 1 ? Int(s[1])-48 : 1
    n *= num
    ofst = Week(n)
    if s[end] == 'w'
        ofst = Week(n)
    elseif s[end] == 'm'
        ofst = Month(n)
    end
    return tobday(cal,d+ofst)
end

function generate_dates(args)
    BusinessDays.initcache(args.trade_cal)
    periods = []
    valuation_dates = [args.trade_date]
    t_start = args.effective_date
    n = args.gte_periods
    for i in 1:args.num_settlements
        #t_end = advancebperiods(args.trade_cal, t_start, args.settlement_frequency)
        t_end = t_start + date_offset(args.settlement_frequency) - Day(1)
        obs = listbdays(args.trade_cal, t_start, t_end)
        t_settle = advancebdays(args.trade_cal, obs[end], args.settlement_offset)
        append!(valuation_dates, listbdays(args.trade_cal, t_start, t_settle))
        gte = n > 0 ? true : false
        push!(periods, (obs_dates=obs, settle_date=t_settle, is_gte=gte))
        n -= 1
        t_start = advancebdays(args.trade_cal, obs[end], 1)
    end
    unique!(sort!(valuation_dates))
    return periods, valuation_dates
end

function f(β, x)
    a = (1.0-x)*(1.0-x)*β
    b = a*β
    c = sqrt(b + x*x)
    return -a/(c+x) + c + (x-1.0)*(β-1.0)
end

function generate_path(valuation_dates,mkt_data)
    p = Dict{Date, Float32}()
    prev_t = valuation_dates[1]
    p[prev_t] = 1.0
    lx = 0.0
    for t in valuation_dates[2:end]
        dt = Dates.value(t - prev_t)/365
        sdt = sqrt(dt)
        x = p[prev_t]
        h = mkt_data.σ*f(mkt_data.β, x)/x
        lx = lx + (mkt_data.rf - mkt_data.div - 0.5 * h * h) * dt +  h * sdt * randn()
        p[t] = exp(lx)
        prev_t = t
    end
    return p
end

function payout(path,periods,mkt_data,args)
    pv = 0.0
    n = 0
    for x in periods
        isko = false
        settle_price = path[x.settle_date]
        vals = [path[t] for t in x.obs_dates]
        
        for v in vals
            if !isko || x.is_gte 
                n += v > args.strike_price ? args.num_shares : args.boosted_num_shares
            end
            if v > args.ko_price
                isko = true
            end
        end
        dt = Dates.value(x.settle_date - args.trade_date)/365
        disc_factor = (1.0 + mkt_data.rf)^(-dt)
        pv += n * (settle_price - args.strike_price) * disc_factor
        n = 0
        if isko && !x.is_gte
            break
        end
    end
    return pv
end

function price(args,mkt_data,numsamples)
    periods, valuation_dates = generate_dates(args)
    num_dates = sum([length(q.obs_dates) for q in periods])
    println()
    println("number of valuation dates: ", num_dates)
    println("start    end    settle    days")
    for o in periods
        println(o.obs_dates[1],"  ", o.obs_dates[end],"  ", o.settle_date, "  ", length(o.obs_dates))
    end
    println()
    notional = num_dates * args.strike_price * args.num_shares
    num_dates = sum([length(q.obs_dates) for q in periods])
    println()
    println("number of valuation dates: ", num_dates)
    println("start    end    settle    days")
    for o in periods
        println(o.obs_dates[1],"  ", o.obs_dates[end],"  ", o.settle_date, "  ", length(o.obs_dates))
    end
    println()
    notional = num_dates * args.strike_price * args.num_shares
    px = zeros(numsamples)
    Threads.@threads for i in 1:numsamples
        p = generate_path_bs(valuation_dates, mkt_data)
        px[i] = payout(p,periods,mkt_data,args)
    end
    pct_px = sum(px)/numsamples/notional
    println("notional: ", notional)
    println("notional: ", notional)
    return pct_px
end
