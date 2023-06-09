# Leveraged Accumulator Pricer

An monte-carlo pricer in Julia to price leveraged accumulator structured product[^1]. Stock price model is Hyperbolic local volatility model of Jäckel[^2].

Disclaimer: 
This is work in progress and is not meant to provide a tradable price.

## Usage
```bash
$ julia accumulator.jl -h
usage: accumulator.jl [-n SHARES] [-l LEVERAGE] [-f FREQ] [-p PERIODS]
                      [-o OFFSET] [-g GTE] [-s SPOTREF] [-k STRIKE]
                      [-b BARRIER] [-r RF] [-q DIV] [-σ SIGMA]
                      [-β BETA] [-i ITERS] [-h]

optional arguments:
  -n, --shares SHARES   daily number of shares (type: Int64, default:
                        1)
  -l, --leverage LEVERAGE
                        leverage (type: Int64, default: 2)
  -f, --freq FREQ       settlement frequency e.g. 1w, 2w, 1m (default:
                        "1w")
  -p, --periods PERIODS
                        number of periods (type: Int64, default: 52)
  -o, --offset OFFSET   settlement offset in business days (type:
                        Int64, default: 2)
  -g, --gte GTE         number of guarantee periods (type: Int64,
                        default: 1)
  -s, --spotref SPOTREF
                        reference spot price (type: Float64, default:
                        1.0)
  -k, --strike STRIKE   strike price (type: Float64, default: 0.9)
  -b, --barrier BARRIER
                        ko barrier price (type: Float64, default:
                        1.05)
  -r, --rf RF           risk-free rate (type: Float64, default: 0.0)
  -q, --div DIV         dividend yield (type: Float64, default: 0.0)
  -σ, --sigma SIGMA     hyp local sigma (type: Float64, default: 0.4)
  -β, --beta BETA       hyp local beta (type: Float64, default: 0.1)
  -i, --iters ITERS     number of mc iterations (type: Int64, default:
                        10000)
  -h, --help            show this help message and exit
  ```

For example, to price a 6 month, weekly settled, 2x leveraged accumulator with strike 90% and ko 105% with default market data and model parameters, use

```bash
$ julia accumulator.jl -f "1m" -p 12 -o 0 -g 0 -r 0.03 --sigma 0.2 -q 0.0 -i 100000 -i 100000

number of valuation dates: 259
start        end        settle      days
2023-06-12  2023-07-11  2023-07-11  20
2023-07-12  2023-08-11  2023-08-11  23
2023-08-14  2023-09-13  2023-09-13  22
2023-09-14  2023-10-13  2023-10-13  22
2023-10-16  2023-11-15  2023-11-15  23
2023-11-16  2023-12-15  2023-12-15  21
2023-12-18  2024-01-17  2024-01-17  20
2024-01-18  2024-02-16  2024-02-16  22
2024-02-20  2024-03-19  2024-03-19  21
2024-03-20  2024-04-19  2024-04-19  22
2024-04-22  2024-05-21  2024-05-21  22
2024-05-22  2024-06-21  2024-06-21  21

notional: 233.1
fair value (%): -0.8230122185772926
```

## References
[^1]: Lam, K., Philip, L. H., & Xin, L. (2009, March). [Accumulator pricing](https://hub.hku.hk/bitstream/10722/132834/2/Content.pdf). In 2009 IEEE Symposium on Computational Intelligence for Financial Engineering (pp. 72-79). IEEE. 
[^2]: Jäckel, P. (2006). [Hyperbolic local volatility](http://www.jaeckel.org/HyperbolicLocalVolatility.pdf). Preprint.
