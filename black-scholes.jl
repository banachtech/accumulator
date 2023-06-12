
using BusinessDays, Random, Dates, Distributions

include("utils.jl")

Base.@kwdef mutable struct ArgsBS
    trade_cal = :USNYSE
    trade_date = today()
    effective_date = advancebdays(trade_cal, trade_date, 1)
    num_shares = 1
    boosted_num_shares = 2
    settlement_frequency = "1d"
    num_settlements = 252
    settlement_offset = 2
    gte_periods = 1
    spot_price = 100.0
    strike_price = 90
    ko_price = 105
end

Base.@kwdef mutable struct MktDataBS
    rf = 0.03
    σ = 0.20
    β = 0.5826
    div = 0.0
end

global g,lgSK, lgSH, T, t, sigma_squared, mu, lambda, lgH2SK, σ, H,S,K
function initialiseValues(args)
    global t=[]
    global T=[]
    global  temp_dates, _ =  generate_dates(args)

    # Checked
    # converting dates to differnce in number of days
    for i in 1:length(temp_dates)
        for j in 1:length(temp_dates[i].obs_dates)
            push!(t, Dates.value(temp_dates[i].obs_dates[j] - args.trade_date)/365)
            push!(T, Dates.value(temp_dates[i].settle_date - args.trade_date)/365)
        end
    end

end


function x(t) 
    return (log(S/K) + (mu+sigma_squared)*t)/(σ*sqrt(t))
end

function x1(t) # Checked TO be correct
    return (log(S/H)+(mu+sigma_squared)*t)/(σ*sqrt(t))
end

function y(t) # Checked TO be correct
    return (log(H^2/(S*K)) + (mu+sigma_squared)*t)/(σ*sqrt(t))
end

function y1(t)# Checked TO be correct
    return (log(H/S)+(mu+sigma_squared)*t)/(σ*sqrt(t))
end

function value_accumulator2()
    value = 0
    args = ArgsBS()
    mkt_data = MktDataBS()
    initialiseValues(args)
    H = args.ko_price
    K = args.strike_price
    S = args.spot_price
    r = mkt_data.rf
    q = mkt_data.div
    σ = mkt_data.σ
    mu = r - q - σ^2/2 # Checked
    lambda = 1 + mu/σ^2 # Checked
    global H,S,K = args.ko_price, args.spot_price, args.strike_price
    
    for i in 1:length(t)
        H = args.ko_price * exp(mkt_data.β * mkt_data.σ * sqrt((Dates.value(periods[i] - args.trade_date))/i))
        NXT = cdf(Normal(), x(t[i]))
        NX1T = cdf(Normal(), x1(t[i]))
        NYT = cdf(Normal(), -y(t[i]))
        NY1T = cdf(Normal(), -y1(t[i]))
        NXT_sigma = cdf(Normal(), x(t[i]) - σ*sqrt(t[i]))
        NX1T_sigma = cdf(Normal(), x1(t[i]) - σ*sqrt(t[i]))
        NYT_sigma = cdf(Normal(), -y(t[i]) + σ*sqrt(t[i]))
        NY1T_sigma = cdf(Normal(), -y1(t[i]) + σ*sqrt(t[i]))
        value = value + ((S*exp(-q*T[i]))*(2- NXT - NX1T - (H/S)^(2*lambda) * (NYT + NY1T))) - ((K*exp(-r*T[i]))*(2 - NXT_sigma - NX1T_sigma - (H/S)^(2*lambda -2)* (NYT_sigma + NY1T_sigma) ))
    end
    return value
end