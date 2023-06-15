include("utils.jl")
using BusinessDays, Random, Dates, Distributions

Base.@kwdef mutable struct ArgsBlackScholes
    trade_cal = :USNYSE
    trade_date = today()
    effective_date = advancebdays(trade_cal, trade_date, 1)
    num_shares = 1
    boosted_num_shares = 2
    settlement_frequency = "1m"
    num_settlements = 12
    settlement_offset = 2
    gte_periods = 0
    spot_price = 1.00
    strike_price = 1.05
    ko_price = 0.9
end


Base.@kwdef mutable struct MktDataBlackScholes
    rf = 0.03
    σ = 0.2
    div = 0.0
end


function valueDecumulator()
    args = ArgsBlackScholes()
    mkt = MktDataBlackScholes()
    dates, periods = generate_dates(args)

    num_dates = sum([length(dt.obs_dates) for dt in dates])
    println()
    println("number of valuation dates: ", num_dates)
    println("start        end        settle      days")
    for o in dates
        println(o.obs_dates[1],"  ", o.obs_dates[end],"  ", o.settle_date, "  ", length(o.obs_dates))
    end

    B = args.ko_price
    K = args.strike_price
    S = args.spot_price
    t = []
    T = []
    m = []
    beta = 0.5826
    for i in eachindex(dates)
        for j in eachindex(dates[i].obs_dates)
            push!(m, length(dates[i].obs_dates))
            push!(t, Dates.value(dates[i].obs_dates[j] - args.trade_date)/365)
            push!(T, Dates.value(dates[i].settle_date - args.trade_date)/365)
        end
    end

    q = mkt.div
    r = mkt.rf
    σ = mkt.σ

    δ_plus(x, t) = (log(x) + (r - q + 0.5 * σ^2) * t) / (σ * sqrt(t))
    δ_minus(x, t) = (log(x) + (r - q - 0.5 * σ^2) * t) / (σ * sqrt(t))
    
    μ = r - q - 0.5 * σ^2
    λ1 = 2 * (1 + μ / (σ^2))
    λ2 = λ1 - 2

    N(x) = cdf(Normal(), x)
    value = 0

    for i in eachindex(t)
        if(i<args.gte_periods)
            B = 0.001
        else
            B = args.ko_price * exp(-beta * σ * sqrt(T[i] / m[i]))
        end
        x1 = S/K
        x2 = S/B
        b = B/S
        y = B^2/(K*S)
        dt = t[i]
        dT = T[i]

        value = value + 
        S * exp(-q * dT) * (-N(δ_plus(x1, dt)) - N(δ_plus(x2, dt)) - b^λ1 * (N(δ_plus(y, dt)) - N(δ_plus(b, dt)))) - 
        K * exp(-r * dT) * (-N(δ_minus(x1, dt)) - N(δ_minus(x2, dt)) - x2^λ2 * (-N(δ_minus(y, dt)) - N(δ_minus(b, dt)))) + 
        2 * B * b^(2*(r-q)/σ^2) * N(δ_plus(y, dt))
    end

    notional = num_dates * args.strike_price * args.num_shares
    println()
    println("notional: ", notional)
    return value / notional * 100
end

println("fair value (%): ", valueDecumulator())