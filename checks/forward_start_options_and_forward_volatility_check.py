# Forward-start options and forward volatility -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series written out, the integrals are
# Simpson's rule, the root finder is bisection, the random numbers are splitmix64 + Box-Muller.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height at x
def N(x):                                                        # bell-curve area left of x
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    s, t, n = x, x, 0
    while abs(t) > 1e-17 * abs(s) + 1e-300:
        n += 1; t *= x * x / (2 * n + 1); s += t
    return 0.5 + phi(x) * s

def bs_call(S, K, r, q, sig, T):                                # plain Black-Scholes call
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))

def fwd_start(S, a, r, q, sig, t1, T):                          # road 1: shares times a unit call
    return S * exp(-q * t1) * bs_call(1.0, a, r, q, sig, T - t1)

def simpson(f, lo, hi, n):
    h = (hi - lo) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(lo + i * h) for i in range(n + 1))

def two_stage(s1, s2, strike, n=400):                           # road 2: average over both halves
    def outer(z1):                                              # Acme at the reset, then the second half
        S1 = S * exp((r - q - 0.5 * s1 * s1) * t1 + s1 * sqrt(t1) * z1)
        K_ = strike(S1); m, v = (r - q - 0.5 * s2 * s2) * tau, s2 * sqrt(tau)
        cut = min(max((log(K_ / S1) - m) / v, -8.0), 8.0)       # where the payoff starts to be positive
        return phi(z1) * simpson(lambda z2: (S1 * exp(m + v * z2) - K_) * phi(z2), cut, 8.0, n)
    return exp(-r * T) * simpson(outer, -8.0, 8.0, n)

S, a, r, q, t1, T = 100.0, 1.0, 0.05, 0.02, 0.5, 1.0            # house market, reset at half a year
tau = T - t1
sig1, sig2 = 0.18, 0.20                                          # six-month and one-year implied vols
w1, w2 = sig1 ** 2 * t1, sig2 ** 2 * T
sf = sqrt((w2 - w1) / (T - t1))                                  # forward vol from total variances
d1 = (r - q + 0.5 * 0.04) * tau / (0.2 * sqrt(tau)); d2 = d1 - 0.2 * sqrt(tau)
c20, cf = bs_call(1.0, a, r, q, 0.20, tau), bs_call(1.0, a, r, q, sf, tau)
P20, Pf = fwd_start(S, a, r, q, 0.20, t1, T), fwd_start(S, a, r, q, sf, t1, T)
atm = lambda S1: a * S1
P20_int = two_stage(0.20, 0.20, atm)
Pf_int = two_stage(sig1, sf, atm)
Pf_int40 = two_stage(0.40, sf, atm)                              # the first half's vol changed to 40%
van_int = two_stage(sig1, sf, lambda S1: 100.0)                  # one-year vanilla, same two-stage model

# road 3: simulation, two normal draws per path, one for each half-year
MASK, state = (1 << 64) - 1, 20260924
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state; z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
paths, s1_, s2_ = 200000, 0.0, 0.0
for _ in range(paths):
    u1, u2 = 1.0 - uniform(), uniform()
    rad = sqrt(-2.0 * log(u1)); z1, z2 = rad * cos(2 * pi * u2), rad * sin(2 * pi * u2)
    S1 = S * exp((r - q - 0.5 * sig1 * sig1) * t1 + sig1 * sqrt(t1) * z1)
    ST = S1 * exp((r - q - 0.5 * sf * sf) * tau + sf * sqrt(tau) * z2)
    x = exp(-r * T) * max(ST - a * S1, 0.0); s1_ += x; s2_ += x * x
mc = s1_ / paths; se = sqrt((s2_ / paths - mc * mc) / paths)

# the inverse: quote in, forward vol out, by bisection on a price that rises with vol
quote = Pf_int
floor_, ceil_ = S * exp(-q * t1) * (exp(-q * tau) - a * exp(-r * tau)), S * exp(-q * T)
def implied_fwd_vol(p):
    if not floor_ < p < ceil_: return None                      # no volatility reaches this price
    lo, hi = 1e-9, 20.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if fwd_start(S, a, r, q, mid, t1, T) < p else (lo, mid)
    return 0.5 * (lo + hi)
iv = implied_fwd_vol(quote)

# hedge: the parcel of shares buys the reset-date call at any Acme price
hedge = [bs_call(x, a * x, r, q, sf, tau) / x for x in (40.0, 250.0)]
f = lambda **k: fwd_start(**{**dict(S=S, a=a, r=r, q=q, sig=sf, t1=t1, T=T), **k})
delta = (f(S=S + 0.01) - f(S=S - 0.01)) / 0.02
gamma = round(f(S=S + 1.0) - 2 * Pf + f(S=S - 1.0), 9) + 0.0
vega = (f(sig=sf + 1e-4) - f(sig=sf - 1e-4)) / 2e-4 / 100
rho = (f(r=r + 1e-4) - f(r=r - 1e-4)) / 2e-4 / 100
theta = (f(t1=t1 - 1e-4, T=T - 1e-4) - Pf) / 1e-4

rows = [("d1, flat 20%", d1), ("d2, flat 20%", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)),
        ("unit call c, flat 20%", c20), ("waiting drag e^-q t1", exp(-q * t1)),
        ("1 formula, flat 20%", P20), ("2 two-stage Simpson, flat 20%", P20_int),
        ("total variance to 0.5 yr, 18%", w1), ("total variance to 1 yr, 20%", w2),
        ("forward vol sigma_f", sf), ("unit call c at sigma_f", cf), ("shares to buy c e^-q t1", cf * exp(-q * t1)),
        ("1 formula at sigma_f", Pf), ("2 Simpson, 18% then sigma_f", Pf_int), ("2 Simpson, 40% then sigma_f", Pf_int40),
        ("3 simulation, 200000 paths", mc), ("  standard error", se),
        ("two-stage one-year vanilla", van_int), ("  Black-Scholes at 20%", bs_call(S, 100.0, r, q, 0.2, T)),
        ("inverse: floor, vol -> 0", floor_), ("inverse: ceiling, vol -> infinity", ceil_),
        ("inverse: vol from the quote", iv), ("inverse: vols that reach 1.00", 0.0 if implied_fwd_vol(1.0) is None else 1.0),
        ("hedge: call / Acme, Acme 40", hedge[0]), ("hedge: call / Acme, Acme 250", hedge[1]),
        ("delta by bump", delta), ("  price / S", Pf / S), ("gamma by bump", gamma), ("vega per vol point", vega),
        ("rho per rate point", rho), ("theta per year", theta), ("  q times price", q * Pf),
        ("wrong: 18% six-month quote", f(sig=sig1)), ("wrong: full year in unit call", S * exp(-q * t1) * bs_call(1.0, a, r, q, sf, T)),
        ("wrong: waiting drag at r", S * exp(-r * t1) * cf), ("wrong: no waiting drag", S * cf),
        ("try: reset at 0.25, flat 20%", fwd_start(S, a, r, q, 0.2, 0.25, T)), ("try: strike 110% of reset", f(a=1.1)),
        ("try: flat 40%", fwd_start(S, a, r, q, 0.4, t1, T))]
for name, v in rows: print(f"{name:<34} {v:>12.6f}")
for label, s, t in (("story: month 0", 100.0, 0.0), ("story: month 3", 110.0, 0.25), ("story: month 6 reset", 110.0, 0.5)):
    print(f"{label:<34} {s * exp(-q * (t1 - t)) * cf:>12.6f}")
print(f"{'story: month 9, Acme 115':<34} {bs_call(115.0, 110.0, r, q, sf, 0.25):>12.6f}")
print(f"{'story: month 12, Acme 118':<34} {max(118.0 - 110.0, 0.0):>12.6f}")
print("bars, Acme at month 3   " + " ".join(f"{x:7.0f}" for x in (80.0, 90.0, 100.0, 110.0, 120.0)))
print("bars, value at month 3  " + " ".join(f"{x * exp(-q * 0.25) * cf:7.2f}" for x in (80.0, 90.0, 100.0, 110.0, 120.0)))
grid = [80.0 + 5.0 * i for i in range(11)]
print("chart, Acme at expiry   " + " ".join(f"{x:6.0f}" for x in grid))
for s1 in (90.0, 100.0, 110.0):
    print(f"chart, reset at {s1:3.0f}     " + " ".join(f"{max(x - a * s1, 0.0):6.2f}" for x in grid))
vols = [0.10 + 0.05 * i for i in range(7)]
print("chart, forward vol %    " + " ".join(f"{100 * v:6.0f}" for v in vols))
print("chart, price            " + " ".join(f"{f(sig=v):6.2f}" for v in vols))

assert abs(P20 - 6.244873) < 1e-6, "formula vs the shelf's house number"
assert abs(P20_int - P20) < 1e-7 and abs(Pf_int - Pf) < 1e-7, "two-stage average vs shares times unit call"
assert abs(Pf_int40 - Pf_int) < 1e-7, "the first half's vol must not matter"
assert abs(mc - Pf) < 3 * se, "simulation within 3 standard errors"
assert abs(van_int - 9.227005508154) < 1e-7, "the two-stage model reproduces the one-year 20% quote"
assert abs(iv - 0.218174) < 1e-6, "the quote inverts to the forward vol"
assert abs(hedge[0] - cf) < 1e-12 and abs(hedge[1] - cf) < 1e-12, "call value at the reset is c shares"
print("ALL CHECKS PASS")
