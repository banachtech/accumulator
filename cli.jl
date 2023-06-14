using ArgParse

function parse_cli()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--shares", "-n"
            help = "daily number of shares"
            arg_type = Int
            default = 1
        "--leverage", "-l"
            help = "leverage"
            arg_type = Int
            default = 2
        "--freq", "-f"
            help = "settlement frequency e.g. 1w, 2w, 1m"
            arg_type = String
            default = "1w"
        "--periods", "-p"
            help = "number of periods"
            arg_type = Int
            default = 52
        "--offset", "-o"
            help = "settlement offset in business days"
            arg_type = Int
            default = 2
        "--gte", "-g"
            help = "number of guarantee periods"
            arg_type = Int
            default = 1
        "--spotref", "-s"
            help = "reference spot price"
            arg_type = Float64
            default = 1.0
        "--strike", "-k"
            help = "strike price"
            arg_type = Float64
            default = 1.05
        "--barrier", "-b"
            help = "ko barrier price"
            arg_type = Float64
            default = 0.95
        "--rf", "-r"
            help = "risk-free rate"
            arg_type = Float64
            default = 0.0409
        "--div", "-q"
            help = "dividend yield"
            arg_type = Float64
            default = 0.0
        "--sigma", "-σ"
            help = "hyp local sigma"
            arg_type = Float64
            default = 0.730934623
        "--beta", "-β"
            help = "hyp local beta"
            arg_type = Float64
            default = 0.603063223
        "--iters", "-i"
            help = "number of mc iterations"
            arg_type = Int
            default = 10000
    end
    parsed_args = parse_args(s)
    return parsed_args
end
