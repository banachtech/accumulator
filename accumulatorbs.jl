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
    gte_periods = 1
    spot_price = 100.0
    strike_price = 90
    ko_price = 105
end


Base.@kwdef mutable struct MktDataBlackScholes
    rf = 0.03
    σ = 0.20
    div = 0.0
end


function valueAccumulator()
    args = ArgsBlackScholes()
    mkt = MktDataBlackScholes()
    dates, periods = AccumulatorPricer.generate_dates(args)
    H = args.ko_price
    K = args.strike_price
    S = args.spot_price
    t = []
    T = []
    beta = 0.5826
    for i in 1:length(dates)
        for j in 1:length(dates[i].obs_dates)
            push!(t, Dates.value(dates[i].obs_dates[1] - args.effective_date)/365)
            push!(T, Dates.value(dates[i].settle_date - args.effective_date)/365)
        end
    end
    mu = mkt.rf - mkt.div - mkt.σ^2/2
    lambda = 1 + mu / mkt.σ^2

    x(t) = (log10(S/K)+ (mu +  mkt.σ^2)*t)/ mkt.σ * sqrt(t)
    x1(t) = (log10(S/H)+ (mu +  mkt.σ^2)*t)/ mkt.σ * sqrt(t)
    y(t) = (log10(H^2/S/K) + (mu+ mkt.σ^2)*t)/ mkt.σ * sqrt(t)
    y1(t) = (log10(H/S) + (mu+ mkt.σ^2)*t)/ mkt.σ * sqrt(t)

    N(x) = cdf(Normal(), x)
    value = 0
    for i in 1:length(t)
        H = args.ko_price * exp(beta * mkt.σ * sqrt((Dates.value(periods[i] - args.trade_date))/365/i))
        value = value + 
        (S*exp(-mkt.div*T[i]))* ((2- N(x(t[i])) - N(x1(t[i])) - (H/S)^(2*lambda) * N(-y(t[i])) -(H/S)^(2*lambda) * N(-y1(t[i])))) - 
        (K*exp(-mkt.rf*T[i]))*  ((2 - N(x(t[i])-mkt.σ*sqrt(t[i])) - N(x1(t[i])-mkt.σ*sqrt(t[i]))) - (H/S)^(2*lambda-2)*N(-y(t[i])+mkt.σ*sqrt(t[i])) - (H/S)^(2*lambda-2)*N(-y1(t[i])+mkt.σ*sqrt(t[i])))
    end
    return value
end
