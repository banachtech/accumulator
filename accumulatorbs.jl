include("utils.jl")
using BusinessDays, Random, Dates, Distributions

Base.@kwdef mutable struct ArgsBlackScholes
    trade_cal = :USNYSE
    trade_date = today()
    effective_date = advancebdays(trade_cal, trade_date, 1)
    num_shares = 1
    boosted_num_shares = 2
    settlement_frequency = "1w"
    num_settlements = 52
    settlement_offset = 2
    gte_periods = 0
    spot_price = 1.00
    strike_price = 0.9
    ko_price = 1.05
end


Base.@kwdef mutable struct MktDataBlackScholes
    rf = 0.03
    σ = 0.20
    div = 0.0
end


function valueAccumulator()
    args = ArgsBlackScholes()
    mkt = MktDataBlackScholes()
    dates, periods = generate_dates(args)

    num_dates = sum([length(dt.obs_dates) for dt in dates])
    # println()
    # println("number of valuation dates: ", num_dates)
    # println("start        end        settle      days")
    # for o in dates
    #     println(o.obs_dates[1],"  ", o.obs_dates[end],"  ", o.settle_date, "  ", length(o.obs_dates))
    # end

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
    
    λ1 = 1 + 2*(r-q)/σ^2
    λ2 = 1 - 2*(r-q)/σ^2

    N(x) = cdf(Normal(), x)
    value = 0

    for i in eachindex(t)
        if(i<args.gte_periods)
            B = args.spot_price*10
        else
            B = args.ko_price * exp(beta * σ * sqrt(T[i] / m[i]))
        end
        x1 = S/K
        x2 = S/B
        b = B/S
        y = B^2/(K*S)
        dt = t[i]
        dT = T[i]

        value = value +
        (S * exp(-q * dT)) * ((2 - N(δ_plus(x1, dt)) - N(δ_plus(x2, dt)) - b^λ1 * N(-δ_plus(y, dt)) - b^λ1 * N(-δ_plus(b, dt)))) -
        (K * exp(-r * dT)) * ((2 - N(δ_minus(x1, dt)) - N(δ_minus(x2, dt)) - x2^λ2 * N(-δ_minus(y, dt))  - x2^λ2 * N(-δ_minus(b, dt))))
    end

    # num_dates = sum([length(q.obs_dates) for q in dates])
    # μ = mkt.rf - mkt.div - 0.5 * mkt.σ^2
    # λ = 1 + μ / (mkt.σ^2)

    # x(t) = (log(S/K)+ (μ +  mkt.σ^2)*t)/ (mkt.σ * sqrt(t))
    # x1(t) = (log(S/B)+ (μ +  mkt.σ^2)*t)/ (mkt.σ * sqrt(t))
    # y(t) = (log(B^2/(S*K)) + (μ+ mkt.σ^2)*t)/ (mkt.σ * sqrt(t))
    # y1(t) = (log(B/S) + (μ + mkt.σ^2)*t)/ (mkt.σ * sqrt(t))

    # N(x) = cdf(Normal(), x)
    # value = 0
    # for i in eachindex(t)
    #     if(i<args.gte_periods)
    #         B = args.spot_price*10
    #     else
    #         B = args.ko_price * exp(beta * mkt.σ * sqrt(T[i] / m[i]))
    #     end
    #     value = value + 
    #     (S * exp(-mkt.div * T[i])) * ((2 - N(x(t[i])) -                  N(x1(t[i])) -                   (B/S)^(2*λ)    * N(-y(t[i]))                   - (B/S)^(2*λ) *    N(-y1(t[i])))) - 
    #     (K * exp(-mkt.rf * T[i])) *  ((2 - N(x(t[i])-mkt.σ*sqrt(t[i]))-  N(x1(t[i])-mkt.σ*sqrt(t[i]))) - (B/S)^(2*λ-2)  * N(-y(t[i])+mkt.σ*sqrt(t[i]))  - (B/S)^(2*λ-2) *  N(-y1(t[i])+mkt.σ*sqrt(t[i])))
    # end

    notional = num_dates * args.strike_price * args.num_shares
    println()
    println("notional: ", notional)
    # println("value: ", value)
    return value / notional * 100
end

println("fair value (%): ", valueAccumulator())