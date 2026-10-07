# Prices as geometric Brownian motion -- the check behind the card.  Standard library only,
# and nothing imported that already holds an answer: the bell curve's area, the percentiles,
# the random draws and the option price are built here.  Acme: 100 dollars, drift 5% a year,
# volatility 20% a year, one year ahead.
from math import exp, log, sqrt
S0, MU, SIG, T = 100.0, 0.05, 0.20, 1.0
K, R, Q = 100.0, 0.05, 0.02                       # the shelf's market, for the cross-check
TWO_PI, PATHS, STEPS, NLAT = 6.283185307179586, 20000, 52, 400
def phi(z): return exp(-0.5 * z * z) / sqrt(TWO_PI)        # bell-curve height at z
def simpson(f, a, b, n):                          # area under f from a to b, n panels
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def ncdf(x):                                      # bell-curve area to the left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 4000)
def bisect(f, lo, hi):                            # the crossing point of a rising f
    flo = f(lo)
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        fmid = f(mid)
        if flo * fmid <= 0.0: hi = mid
        else: lo, flo = mid, fmid
    return 0.5 * (lo + hi)
def logdrift(mu, sig): return mu - 0.5 * sig * sig         # the log's own growth rate
def median_of(mu, sig, t): return S0 * exp(logdrift(mu, sig) * t)
def mean_of(mu, t): return S0 * exp(mu * t)
def quantile(sig, t, z): return S0 * exp(logdrift(MU, sig) * t + sig * sqrt(t) * z)
def below(t, level): return ncdf((log(level / S0) - logdrift(MU, SIG) * t) / (SIG * sqrt(t)))
def dens(x): return phi((log(x / S0) - m) / s) / (x * s)   # lognormal height at the price x
class Rng:                                        # a 64-bit multiply-and-add generator
    def __init__(self, seed): self.s = seed & 0xFFFFFFFFFFFFFFFF
    def uniform(self):
        self.s = (self.s * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return (self.s >> 11) * (1.0 / 9007199254740992.0)
    def normal(self):                             # Marsaglia's polar method, no trig
        while True:
            u = 2.0 * self.uniform() - 1.0
            v = 2.0 * self.uniform() - 1.0
            q = u * u + v * v
            if 0.0 < q < 1.0: return u * sqrt(-2.0 * log(q) / q)
def walk(rng, steps, keep):                       # one exact path, every keep'th price kept
    a, b = logdrift(MU, SIG) * T / steps, SIG * sqrt(T / steps)
    s, low, out = S0, S0, [S0]
    for i in range(steps):
        s *= exp(a + b * rng.normal())
        if s < low: low = s
        if (i + 1) % keep == 0: out.append(s)
    return out, low
def row(name, a): print(f"{name:<44}{a:>14.6f}")
def two(name, a, b): print(f"{name:<44}{a:>14.6f}{b:>14.6f}")
def grid(name, vals): print(f"{name:<20}" + "".join(f"{v:>7.2f}" for v in vals))
m, s = logdrift(MU, SIG) * T, SIG * sqrt(T)       # road 1: the formulas
med, mean = median_of(MU, SIG, T), mean_of(MU, T)
sd = sqrt(S0 * S0 * exp(2.0 * MU * T) * (exp(SIG * SIG * T) - 1.0))
z05, z95 = bisect(lambda z: ncdf(z) - 0.05, -12.0, 12.0), bisect(lambda z: ncdf(z) - 0.95, -12.0, 12.0)
LO, HI = 1e-9, 1000.0                             # road 2: the density, in price space
mean_i = simpson(lambda x: x * dens(x), LO, HI, 4000)
med_i = bisect(lambda x: simpson(dens, LO, x, 2000) - 0.5, LO, HI)
below_i = simpson(dens, LO, K, 2000)
x, dt = SIG * sqrt(T / NLAT), T / NLAT            # road 3: small up-or-down multiplications
p = 0.5 * (1.0 + logdrift(MU, SIG) * dt / x)
lat_mean = S0 * (p * exp(x) + (1.0 - p) * exp(-x)) ** NLAT
lat_spread = 2.0 * sqrt(NLAT * p * (1.0 - p)) * x
rng, ends, low = Rng(20260919), [], S0            # road 4: simulate the years
for _ in range(PATHS):
    path, plow = walk(rng, STEPS, STEPS)
    ends.append(path[-1]); low = min(low, plow)
mc_mean = sum(ends) / PATHS
mc_sd = sqrt(sum((e - mc_mean) ** 2 for e in ends) / (PATHS - 1))
mc_med = 0.5 * sum(sorted(ends)[PATHS // 2 - 1:PATHS // 2 + 1])
logs = [log(e / S0) for e in ends]
mc_logmean = sum(logs) / PATHS
mc_logsd = sqrt(sum((v - mc_logmean) ** 2 for v in logs) / (PATHS - 1))
mc_below = sum(1 for e in ends if e < K) / PATHS
se_mean, se_med = mc_sd / sqrt(PATHS), mc_med * s * sqrt(TWO_PI) / (2.0 * sqrt(PATHS))
fwd = S0 * exp((R - Q) * T)                       # the same law with the pricing drift
call = exp(-R * T) * simpson(lambda z: max(S0 * exp((R - Q - 0.5 * SIG * SIG) * T + SIG * sqrt(T) * z) - K, 0.0) * phi(z), -10.0, 10.0, 40000)
print(f"Acme: {S0:.2f} dollars today, drift 5% a year, volatility 20% a year, horizon 1 year")
print("road 1, the formulas")
print(f"{'half variance, log drift, log spread':<38}{0.5 * SIG * SIG * T:>14.6f}{m:>14.6f}{s:>14.6f}")
row("median  S0 e^((mu - sigma^2/2) T)", med)
row("mean    S0 e^(mu T)", mean)
two("mean / median, then e^(sigma^2 T / 2)", mean / med, exp(0.5 * SIG * SIG * T))
row("standard deviation of S_T", sd)
row("mode, the peak of the density", S0 * exp((MU - 1.5 * SIG * SIG) * T))
row("chance S_T lands below 100", below(T, K))
two("5th and 95th percentile of S_T", quantile(SIG, T, z05), quantile(SIG, T, z95))
two("the bell curve's own 5% and 95% points", z05, z95)
print("road 2, slices of the density added up in price space")
row("mean", mean_i)
row("median, the price with half the area below", med_i)
row("chance S_T lands below 100", below_i)
print(f"road 3, {NLAT} multiplicative up-or-down steps")
row("mean", lat_mean)
two("spread of the log return, then sigma sqrt(T)", lat_spread, s)
print(f"road 4, {PATHS} simulated years, {STEPS} steps each")
two("mean, then three standard errors", mc_mean, 3.0 * se_mean)
two("median, then three standard errors", mc_med, 3.0 * se_med)
two("spread of the log return, then sigma sqrt(T)", mc_logsd, s)
row("share of years landing below 100", mc_below)
two("lowest tick, then years ending at or below 0", low, 0.0)
print("the shelf's market: the drift swapped for r - q = 3% a year")
row("forward price, the mean of S_T", fwd)
two("call by this law, then the shelf's price", call, 9.227005508154)
print(f"volatility drag at one year, mean {mean:.6f} in every row")
for sg in (0.10, 0.20, 0.30, 0.40): row(f"sigma {sg * 100:.0f}%   median", median_of(MU, sg, T))
grid("drag, mean - median", [mean - median_of(MU, sg, T) for sg in (0.10, 0.20, 0.30, 0.40)])
print(f"{'horizon':<20}{'median':>7}{'mean':>7}{'5th':>7}{'95th':>7}{'under%':>7}")
for t, name in ((1.0 / 12.0, "1 month"), (1.0, "1 year"), (5.0, "5 years"), (10.0, "10 years")):
    grid(name, [median_of(MU, SIG, t), mean_of(MU, t), quantile(SIG, t, z05), quantile(SIG, t, z95), 100.0 * below(t, K)])
one, _ = walk(Rng(7), 252, 21)
print("chart 1, one simulated year of Acme, month 0 to month 12")
grid("chart 1, price", one)
print("chart 2, density x 1000, at prices 40 to 180 in tens")
prices = [40.0 + 10.0 * i for i in range(15)]
grid("chart 2, lognormal", [1000.0 * dens(v) for v in prices])
grid("chart 2, bell curve", [1000.0 * phi((v - mean) / sd) / sd for v in prices])
print("chart 3, the fan, year 0 to year 10")
for name, z in (("chart 3, 5th", z05), ("chart 3, median", 0.0), ("chart 3, 95th", z95)):
    grid(name, [quantile(SIG, float(y), z) for y in range(11)])
print("what breaks if you drop a piece")
two("drift as the middle, then the real middle", mean, med)
two("+20% then -20% on 100, then its log drag", S0 * 1.20 * 0.80, 0.5 * log(0.96))
two("95th at four years with sigma T, then right", S0 * exp(m * 4.0 + SIG * 4.0 * z95), quantile(SIG, 4.0, z95))
print(f"{'a bell curve on the price, chance below zero':<44}{ncdf(-mean / sd):>14.9f}")
assert abs(mean_i - mean) < 1e-6, "the density's own mean must land on S0 e^(mu T)"
assert abs(med_i - med) < 1e-6, "half the area below must land on S0 e^((mu - sigma^2/2) T)"
assert abs(below_i - below(T, K)) < 1e-6, "two roads to the chance of ending below 100"
assert abs(lat_mean - mean) < 0.02, "400 up-or-down steps must reach the same mean"
assert abs(lat_spread - s) < 1e-3, "the lattice's log spread must be sigma sqrt(T)"
assert abs(mc_mean - mean) < 3.0 * se_mean, "the simulated mean, inside three standard errors"
assert abs(mc_med - med) < 3.0 * se_med, "the simulated median, inside three standard errors"
assert abs(call - 9.227005508154) < 1e-6, "this law prices the shelf's call"
assert low > 0.0 and min(ends) > 0.0, "no simulated price ever reaches zero"
assert mean - med > 2.0, "the mean must sit clearly above the median"
print("ALL CHECKS PASS")
