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
    spot_price = 100
    strike_price = 090
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
    m = []
    beta = 0.5826
    for i in eachindex(dates)
        for j in eachindex(dates[i].obs_dates)
            push!(m, length(dates[i].obs_dates))
            push!(t, Dates.value(dates[i].obs_dates[j] - args.trade_date)/365)
            push!(T, Dates.value(dates[i].settle_date - args.trade_date)/365)
        end
    end

    num_dates = sum([length(q.obs_dates) for q in dates])
    μ = mkt.rf - mkt.div - 0.5 * mkt.σ^2
    λ = 1 + μ / (mkt.σ^2)

    x(t) = (log(S/K)+ (μ +  mkt.σ^2)*t)/ (mkt.σ * sqrt(t))
    x1(t) = (log(S/H)+ (μ +  mkt.σ^2)*t)/ (mkt.σ * sqrt(t))
    y(t) = (log(H^2/(S*K)) + (μ+ mkt.σ^2)*t)/ (mkt.σ * sqrt(t))
    y1(t) = (log(H/S) + (μ + mkt.σ^2)*t)/ (mkt.σ * sqrt(t))

    N(x) = cdf(Normal(), x)
    value = 0
    for i in eachindex(t)
        H = args.ko_price * exp(beta * mkt.σ * sqrt(T[i] / m[i]))
        value = value + 
        (S * exp(-mkt.div * T[i])) * ((2 - N(x(t[i])) -                  N(x1(t[i])) -                   (H/S)^(2*λ)    * N(-y(t[i]))                   - (H/S)^(2*λ) *    N(-y1(t[i])))) - 
        (K * exp(-mkt.rf * T[i])) *  ((2 - N(x(t[i])-mkt.σ*sqrt(t[i]))-  N(x1(t[i])-mkt.σ*sqrt(t[i]))) - (H/S)^(2*λ-2)  * N(-y(t[i])+mkt.σ*sqrt(t[i]))  - (H/S)^(2*λ-2) *  N(-y1(t[i])+mkt.σ*sqrt(t[i])))
    end

    notional = num_dates * args.strike_price * args.num_shares
    return value / notional * 100
end

println(valueAccumulator())