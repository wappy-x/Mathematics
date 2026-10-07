# Kemna-Vorst on a commodity: the geometric Asian call on weekly jet fuel fixings, priced
# from the futures curve.  Standard library only.  Nothing imported knows the answer: the normal
# CDF is a series written out, the integral is Simpson's rule, the random numbers are
# splitmix64 + Box-Muller, and the variance of ln G is a brute-force sum over the fixing dates.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                                        # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = total = x; k = 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def black76(F, K, r, sig, T, put=False):                         # Black-76 on a forward F
    d1 = (log(F / K) + 0.5 * sig * sig * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    if put: return exp(-r * T) * (K * N(-d2) - F * N(-d1))
    return exp(-r * T) * (F * N(d1) - K * N(d2))

def kv_inputs(S0, c, sig, T, n):     # road 1: the two doctored inputs, closed form, curve S0 e^(c t)
    tbar = T * (n + 1) / (2.0 * n)                               # centre of the fixing dates
    frac = (n + 1) * (2 * n + 1) / (6.0 * n * n)                 # variance fraction
    FG = S0 * exp(c * tbar) * exp(-0.5 * sig * sig * (tbar - frac * T))
    return FG, sig * sqrt(frac)

def kv(S0, K, r, c, sig, T, n, put=False):
    FG, sG = kv_inputs(S0, c, sig, T, n)
    return black76(FG, K, r, sG, T, put)

def kv_cont(S0, K, r, c, sig, T):                                # continuous limit: sigma/sqrt 3
    return black76(S0 * exp(0.5 * c * T - sig * sig * T / 12.0), K, r, sig / sqrt(3.0), T)

def simpson(m, v, payoff, r, T, panels=200000):                  # E[payoff(G)], ln G ~ normal(m, v)
    a, b = -10.0, 10.0; h = (b - a) / panels
    f = lambda z: payoff(exp(m + sqrt(v) * z)) * phi(z)
    tot = f(a) + f(b)
    for i in range(1, panels):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

S0, K, r, c, sig, T, n = 100.0, 100.0, 0.05, 0.05, 0.20, 1.0, 52
fwd = lambda t: S0 * exp(c * t)                                  # the futures curve today
FG, sG = kv_inputs(S0, c, sig, T, n)
tbar, frac = T * (n + 1) / (2.0 * n), (n + 1) * (2 * n + 1) / (6.0 * n * n)
d1 = (log(FG / K) + 0.5 * sG * sG * T) / (sG * sqrt(T)); d2 = d1 - sG * sqrt(T)
C, P = kv(S0, K, r, c, sig, T, n), kv(S0, K, r, c, sig, T, n, put=True)

# road 2: the law of ln G fixing by fixing, from the curve: no 1/2, no 1/3, no d1 or d2
ts = [T * i / n for i in range(1, n + 1)]
m2 = sum(log(fwd(t)) - 0.5 * sig * sig * t for t in ts) / n
v2 = sig * sig * sum(min(x, y) for x in ts for y in ts) / n ** 2
C2 = simpson(m2, v2, lambda G: max(G - K, 0.0), r, T)
P2 = simpson(m2, v2, lambda G: max(K - G, 0.0), r, T)

# road 3: simulate the one Brownian path that moves every futures price, read it weekly
MASK = (1 << 64) - 1
state = 20260927
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53
paths, h = 100000, T / n
acc = [0.0, 0.0, 0.0, 0.0]; am_below_gm = 0; disc = exp(-r * T)
for _ in range(paths):
    w = 0.0; sum_log = 0.0; sum_px = 0.0
    for i in range(0, n, 2):
        rad = sqrt(-2.0 * log(uniform())); ang = 2.0 * pi * uniform()
        for zz, t in ((rad * cos(ang), ts[i]), (rad * sin(ang), ts[i + 1])):
            w += sqrt(h) * zz
            x = log(fwd(t)) - 0.5 * sig * sig * t + sig * w      # fixing = F(0,t) e^(sig W - sig^2 t/2)
            sum_log += x; sum_px += exp(x)
    g, a = exp(sum_log / n), sum_px / n
    am_below_gm += a < g
    pg, pa = disc * max(g - K, 0.0), disc * max(a - K, 0.0)
    acc[0] += pg; acc[1] += pg * pg; acc[2] += pa; acc[3] += pa * pa
mean_se = lambda s1, s2: (s1 / paths, sqrt((s2 / paths - (s1 / paths) ** 2) / paths))
mc_g, mc_a = mean_se(acc[0], acc[1]), mean_se(acc[2], acc[3])

# Greeks: the whole curve moves with the prompt price S0; rho holds the curve still
bump = lambda **kw: kv(**{**dict(S0=S0, K=K, r=r, c=c, sig=sig, T=T, n=n), **kw})
delta = (bump(S0=S0 + 0.01) - bump(S0=S0 - 0.01)) / 0.02
gamma = (bump(S0=S0 + 0.5) - 2 * C + bump(S0=S0 - 0.5)) / 0.25
vega = (bump(sig=sig + 1e-4) - bump(sig=sig - 1e-4)) / 2e-4 / 100
rho = (bump(r=r + 1e-4) - bump(r=r - 1e-4)) / 2e-4 / 100
swap = sum(fwd(t) for t in ts) / n                               # arithmetic mean of the forwards

rows = [("forward for the last fixing, F(0,T)", fwd(T)), ("centre of the fixings, tbar", tbar),
        ("variance fraction (n+1)(2n+1)/6n^2", frac), ("sigma_G = sigma sqrt(fraction)", sG),
        ("F(0,tbar), geometric mean of forwards", fwd(tbar)), ("haircut e^(-sig^2(tbar-frac T)/2)", FG / fwd(tbar)),
        ("F_G, forward of the average", FG), ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("discount e^-rT", disc),
        ("average half e^-rT F_G N(d1)", disc * FG * N(d1)), ("cash half e^-rT K N(d2)", disc * K * N(d2)),
        ("1 closed form, 52 weekly fixings", C), ("2 centre of ln G, summed", m2), ("  ln F_G - sigma_G^2 T/2", log(FG) - 0.5 * sG * sG * T),
        ("2 var ln G, 52x52 min sum", v2), ("  sigma_G^2 T", sG * sG * T), ("2 Simpson over that law", C2),
        ("3 simulation, 100000 paths", mc_g[0]), ("  standard error", mc_g[1]),
        ("4 put, closed form", P), ("4 put, Simpson", P2), ("  C - P, Simpson", C2 - P2), ("  e^-rT (F_G - K)", disc * (FG - K)),
        ("arithmetic average, same paths", mc_a[0]), ("  paths where AM < GM", am_below_gm)]
rows += [(f"ladder: {m} fixings", kv(S0, K, r, c, sig, T, m)) for m in (1, 2, 4, 12, 52, 252, 1000000)]
rows += [("continuous: sigma/sqrt 3", kv_cont(S0, K, r, c, sig, T)),
         ("curve flat: one futures contract", kv(S0, K, r, 0.0, sig, T, n)),
         ("curve backwardated, c = -5%", kv(S0, K, r, -0.05, sig, T, n)),
         ("delta by bump", delta), ("  e^-rT N(d1) F_G/S0", disc * N(d1) * FG / S0),
         ("gamma by bump", gamma), ("vega per vol point", vega), ("rho per rate point, curve held", rho),
         ("swap price, mean of the forwards", swap),
         ("wrong: raw sigma, F_G kept", black76(FG, K, r, sig, T)),
         ("wrong: swap price as F_G", black76(swap, K, r, sG, T)),
         ("try: sigma = 0.40", kv(S0, K, r, c, 0.40, T, n)), ("try: K = 110", kv(S0, 110.0, r, c, sig, T, n)),
         ("try: one month, 21 daily fixings", kv(S0, K, r, c, sig, 1.0 / 12, 21))]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}" if isinstance(v, float) else f"{name:<40} {v:>12}")
grid = [80.0 + 5.0 * i for i in range(9)]
print("chart, G at expiry " + " ".join(f"{x:6.0f}" for x in grid))
print("chart, profit      " + " ".join(f"{max(x - K, 0.0) - C:6.2f}" for x in grid))
ladder = [kv(S0, K, r, c, sig, T, m) for m in (1, 2, 4, 12, 52, 252)] + [kv_cont(S0, K, r, c, sig, T)]
print("chart, fixings     " + " ".join(f"{m:>6}" for m in (1, 2, 4, 12, 52, 252, "cont")))
print("chart, price       " + " ".join(f"{v:6.2f}" for v in ladder))

assert abs(C2 - C) < 1e-7, "fixing-by-fixing law of ln G must reproduce the closed form"
assert abs(mc_g[0] - C) < 3 * mc_g[1], "simulation within 3 standard errors of the formula"
assert abs((C2 - P2) - disc * (FG - K)) < 1e-7, "parity: Simpson call and put against the closed F_G"
assert abs(P2 - P) < 1e-7, "put: Simpson against the closed form"
bs1 = (log(S0 / K) + (r + 0.5 * sig * sig) * T) / (sig * sqrt(T))          # spot-form Black-Scholes, no yield
assert abs(kv(S0, K, r, c, sig, T, 1) - (S0 * N(bs1) - K * disc * N(bs1 - sig * sqrt(T)))) < 1e-10, "one fixing is the plain call"
assert abs(kv(S0, K, r, c, sig, T, 1000000) - kv_cont(S0, K, r, c, sig, T)) < 1e-5, "ladder tends to sigma/sqrt 3"
assert abs(delta - disc * N(d1) * FG / S0) < 1e-6, "bumped delta vs e^-rT N(d1) F_G/S0"
print("ALL CHECKS PASS")
