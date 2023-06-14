using BusinessDays, Random, Dates

include("cli.jl") # parsing command-line inputs
include("utils.jl") # helper function for pricing accumulator

function main()
    args = parse_cli()
    decu = Args(;ko_price=args["barrier"],
            strike_price=args["strike"],
            num_shares=args["shares"],
            boosted_num_shares=args["leverage"] * args["shares"],
            settlement_frequency=args["freq"],
            num_settlements=args["periods"],
            settlement_offset=args["offset"],
            gte_periods=args["gte"],
            spot_price=args["spotref"]
            )
    mkt_data = MktData(;rf=args["rf"],
            σ=args["sigma"],
            β=args["beta"],    
            div=args["div"]
            )
    decu_price = decumulator_price(decu,mkt_data,args["iters"])
    println("fair value (%): ", decu_price*100)
    println()
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
