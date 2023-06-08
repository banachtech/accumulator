# Leveraged Accumulator Pricer

An monte-carlo pricer in Julia to price leveraged accumulator structured product[^1]. Stock price model is Hyperbolic local volatility model of Jäckel[^2].

Disclaimer: 
This work in progress and is not meant to provide a tradable price.

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
$ julia accumulator.jl --strike 0.9 --barrier 1.05 --freq "1w" --periods 26
-0.04303109340515951
```

## References
[^1]: Lam, K., Philip, L. H., & Xin, L. (2009, March). [Accumulator pricing](https://hub.hku.hk/bitstream/10722/132834/2/Content.pdf). In 2009 IEEE Symposium on Computational Intelligence for Financial Engineering (pp. 72-79). IEEE. 
[^2]: Jäckel, P. (2006). [Hyperbolic local volatility](http://www.jaeckel.org/HyperbolicLocalVolatility.pdf). Preprint.
