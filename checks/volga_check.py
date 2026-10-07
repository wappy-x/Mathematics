# Volga -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the
# answer: N(x) is built from math.erf, the integral is Simpson's rule written
# out, the root finder is bisection written out.
from math import log, sqrt, exp, erf, pi

S, r, q, T, SIG = 100.0, 0.05, 0.02, 1.0, 0.20       # the house market
F = S * exp((r - q) * T)                              # forward price

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))   # bell-curve area left of x
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi) # bell-curve height at x

def d1d2(K, s):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return d1, d1 - s * sqrt(T)

def call(K, s):
    d1, d2 = d1d2(K, s)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)

def vega(K, s):                                       # dC/dsigma, from the vega card
    d1, _ = d1d2(K, s)
    return S * exp(-q * T) * phi(d1) * sqrt(T)

def volga(K, s):                                      # road 1: the closed form
    d1, d2 = d1d2(K, s)
    return vega(K, s) * d1 * d2 / s

def volga_bump(K, s, h=1e-5):                         # road 2: nudge sigma, watch vega
    return (vega(K, s + h) - vega(K, s - h)) / (2 * h)

def bisect(f, lo, hi):                                # root finder: halve the bracket
    flo = f(lo)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        fm = f(mid)
        if (fm > 0) == (flo > 0): lo, flo = mid, fm
        else: hi = mid
    return 0.5 * (lo + hi)

def simpson(f, a, b, n=4000):
    h = (b - a) / n
    tot = f(a) + f(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return tot * h / 3.0

def price_by_integral(K, s, put=False):               # no d1, no d2, no N
    a, b = (r - q - 0.5 * s * s) * T, s * sqrt(T)
    ST = lambda z: S * exp(a + b * z)
    zk = bisect(lambda z: ST(z) - K, -10.0, 10.0)     # where the payoff switches on
    if put: v = simpson(lambda z: (K - ST(z)) * phi(z), -10.0, zk)
    else:   v = simpson(lambda z: (ST(z) - K) * phi(z), zk, 10.0)
    return exp(-r * T) * v

def volga_second_diff(K, s, put=False, h=1e-3):       # road 3: curvature of the price itself
    p = {j: price_by_integral(K, s + j * h, put) for j in (-2, -1, 0, 1, 2)}
    d_h = (p[1] - 2 * p[0] + p[-1]) / h ** 2           # steps of h
    d_2h = (p[2] - 2 * p[0] + p[-2]) / (2 * h) ** 2     # steps of 2h
    return (4 * d_h - d_2h) / 3                         # Richardson: cancel the h^2 error

K = 100.0
d1, d2 = d1d2(K, SIG)
v1, v2, v3 = volga(K, SIG), volga_bump(K, SIG), volga_second_diff(K, SIG)
v3put = volga_second_diff(K, SIG, put=True)
m, half_var = log(F / K), 0.5 * SIG * SIG * T
z_lo = bisect(lambda k: volga_bump(k, SIG), 90.0, F)  # sign changes found numerically
z_hi = bisect(lambda k: volga_bump(k, SIG), F, 120.0)
rows = [
    ("d1", d1), ("d2", d2), ("d1 d2", d1 * d2), ("e^(-qT)", exp(-q * T)), ("phi(d1)", phi(d1)),
    ("vega", vega(K, SIG)), ("vega / sigma", vega(K, SIG) / SIG),
    ("1 volga, vega d1 d2 / sigma", v1), ("2 volga, bump of vega", v2),
    ("3 volga, 2nd difference of price", v3), ("  put, 2nd difference of price", v3put),
    ("volga per vol point squared", v1 / 1e4),
    ("vega at 21%, formula", vega(K, 0.21)), ("vega at 21%, vega + 0.01 volga", vega(K, SIG) + 0.01 * v1),
    ("ln(F/K)", m), ("half the variance, sigma^2 T / 2", half_var),
    ("forward F", F), ("vega at K = F", vega(F, SIG)), ("volga at K = F", volga(F, SIG)), ("  -vega sigma T / 4 at K = F", -vega(F, SIG) * SIG * T / 4),
    ("zero strike low, bisection", z_lo), ("  F e^(-sigma^2 T / 2)", F * exp(-half_var)),
    ("zero strike high, bisection", z_hi), ("  F e^(+sigma^2 T / 2)", F * exp(half_var)),
    ("wrong: sign slip in dd1/dsigma", -vega(K, SIG) * d1 * d2 / SIG),
    ("wrong: d1^2 for d1 d2", vega(K, SIG) * d1 * d1 / SIG),
    ("wrong: vega at 21% as vega + volga", vega(K, SIG) + v1),
    ("try: sigma = 40%", volga(K, 0.40)), ("try: K = 130", volga(130.0, SIG)),
    ("try: K = 80", volga(80.0, SIG)),
]
for name, v in rows:
    print(f"{name:<36} {v:>12.6f}")

# ---- volatility itself moves: 15% or 25%, even odds, instead of a sure 20% ----
print()
print("strike   price@20%  avg(15%,25%)  gain(c)  half volga dsig^2 (c)")
mix = {}
for k in (80.0, 90.0, 100.0, F, 110.0, 120.0, 130.0, 140.0):
    avg = 0.5 * (call(k, 0.15) + call(k, 0.25))
    mix[k] = (avg - call(k, SIG), 0.5 * volga(k, SIG) * 0.05 ** 2)
    print(f"{k:7.2f} {call(k, SIG):10.4f} {avg:12.4f} {100 * mix[k][0]:9.2f} {100 * mix[k][1]:12.2f}")
wide = 0.5 * (call(130.0, 0.10) + call(130.0, 0.30)) - call(130.0, SIG)
print(f"try: K = 130, 10% or 30%: gain(c) {100 * wide:.2f}  half volga dsig^2 (c) {100 * 0.5 * volga(130.0, SIG) * 0.01:.2f}")

# ---- chart: volga across strikes ----
ks = [70.0 + 5.0 * i for i in range(15)]
print("chart, strike " + " ".join(f"{k:.0f}" for k in ks))
print("chart, volga  " + " ".join(f"{volga(k, SIG):.2f}" for k in ks))

assert abs(v1 - 2.368822) < 5e-7,               "closed form vs the shelf's house number"
assert abs(v2 - v1) < 1e-6,                     "bump of vega must land on vega d1 d2 / sigma"
assert abs(v3 - v1) < 1e-6,                     "call price curvature, from the integral"
assert abs(v3put - v1) < 1e-6,                  "put price curvature equals the call's"
assert abs(z_lo - F * exp(-half_var)) < 1e-6,   "low zero where d2 = 0"
assert abs(z_hi - F * exp(half_var)) < 1e-6,    "high zero where d1 = 0"
assert abs(mix[130.0][0] - mix[130.0][1]) < 0.005, "wing gain matches half volga times dsigma^2"
assert mix[130.0][0] > 0 > mix[F][0],           "wing gains from vol of vol, forward strike loses"
print("ALL CHECKS PASS")
