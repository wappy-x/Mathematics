# Vanna -- the check behind the card.  Python standard library only: the
# normal CDF (a power series), the integrator (Simpson's rule) and the root
# finder (bisection) are written here.  House market: Acme at S = 100, strike
# K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year.  Five roads to vanna.
from math import exp, log, sqrt, pi

S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
SKEW = 0.005                                  # assumed: vol falls 0.5 points per $1 rise

def phi(x):                                   # bell-curve height
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def N(x):                                     # bell-curve area left of x, by its power series
    if abs(x) > 6.0:
        return 0.0 if x < 0 else 1.0
    term, total, n = x, x, 0
    while abs(term) > 1e-18:
        n += 1
        term *= -x * x / (2.0 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2.0 * pi)

def d12(s, v, t=T, qq=q, k=K):
    d1 = (log(s / k) + (r - qq + 0.5 * v * v) * t) / (v * sqrt(t))
    return d1, d1 - v * sqrt(t)

def delta(s, v, t=T, k=K):
    return exp(-q * t) * N(d12(s, v, t, q, k)[0])

def put_delta(s, v):
    return -exp(-q * T) * N(-d12(s, v)[0])

def vega(s, v, t=T):
    return s * exp(-q * t) * phi(d12(s, v, t)[0]) * sqrt(t)

def gamma(s, v, k=K):
    return exp(-q * T) * phi(d12(s, v, T, q, k)[0]) / (s * v * sqrt(T))

def vanna(s, v, t=T, qq=q, k=K):              # road 1: the formula
    d1, d2 = d12(s, v, t, qq, k)
    return -exp(-qq * t) * phi(d1) * d2 / v

def call_by_integral(s, v, n=4000):           # price with no N at all: Simpson over the bell curve
    lo = (log(K / s) - (r - q - 0.5 * v * v) * T) / (v * sqrt(T))   # below this draw, no payoff
    hi, h = lo + 12.0, 12.0 / n
    f = lambda z: (s * exp((r - q - 0.5 * v * v) * T + v * sqrt(T) * z) - K) * exp(-0.5 * z * z)
    tot = f(lo) + f(hi) + sum((4.0 if i % 2 else 2.0) * f(lo + i * h) for i in range(1, n))
    return exp(-r * T) * tot * h / 3.0 / sqrt(2.0 * pi)

d1, d2 = d12(S, sigma)
v1 = vanna(S, sigma)
v2 = (delta(S, sigma + 1e-4) - delta(S, sigma - 1e-4)) / 2e-4                 # delta bumped in vol
v3 = (vega(S + 0.01, sigma) - vega(S - 0.01, sigma)) / 0.02                    # vega bumped in spot
a, b = 0.05, 0.0005                                                            # price bumped both ways
v4 = (call_by_integral(S + a, sigma + b) - call_by_integral(S + a, sigma - b)
      - call_by_integral(S - a, sigma + b) + call_by_integral(S - a, sigma - b)) / (4 * a * b)
v5 = (put_delta(S, sigma + 1e-4) - put_delta(S, sigma - 1e-4)) / 2e-4         # the put's delta

lo_s, hi_s = 80.0, 120.0                                                       # zero of vanna, by bisection
for _ in range(100):
    mid = 0.5 * (lo_s + hi_s)
    lo_s, hi_s = (mid, hi_s) if vanna(mid, sigma) > 0 else (lo_s, mid)
zero_closed = K * exp(-(r - q - 0.5 * sigma * sigma) * T)
x, y = 80.0, 120.0                                                             # top of vega, by ternary search
for _ in range(200):
    m1, m2 = x + (y - x) / 3, y - (y - x) / 3
    x, y = (m1, y) if vega(m1, sigma) < vega(m2, sigma) else (x, m2)

rows = [
    ("d1, d2", f"{d1:.6f}  {d2:.6f}"),
    ("phi(d1), e^-qT, their product", f"{phi(d1):.6f}  {exp(-q * T):.6f}  {exp(-q * T) * phi(d1):.6f}"),
    ("call price, formula N", f"{S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2):.6f}"),
    ("call price, Simpson integral", f"{call_by_integral(S, sigma):.6f}"),
    ("delta, vega, gamma", f"{delta(S, sigma):.6f}  {vega(S, sigma):.6f}  {gamma(S, sigma):.6f}"),
    ("road 1 formula", f"{v1:.6f}"),
    ("road 2 delta bumped in vol", f"{v2:.6f}"),
    ("road 3 vega bumped in spot", f"{v3:.6f}"),
    ("road 4 price bumped both ways", f"{v4:.6f}"),
    ("road 5 put delta bumped in vol", f"{v5:.6f}"),
    ("d1 and delta at $100, 30% vol", f"{d12(S, 0.30)[0]:.6f}  {delta(S, 0.30):.6f}"),
    ("delta at 19.5% / 20.5% vol", f"{delta(S, 0.195):.6f}  {delta(S, 0.205):.6f}"),
    ("  change, and vanna x 0.01", f"{delta(S, 0.205) - delta(S, 0.195):.6f}  {v1 * 0.01:.6f}"),
    ("vega at $99.50 / $100.50", f"{vega(S - 0.5, sigma):.6f}  {vega(S + 0.5, sigma):.6f}"),
    ("  change, and vanna x 1", f"{vega(S + 0.5, sigma) - vega(S - 0.5, sigma):.6f}  {v1:.6f}"),
    ("one-sided: delta 20% -> 21% vol", f"{delta(S, 0.21) - delta(S, 0.20):.6f}"),
    ("one-sided: vega $100 -> $101", f"{vega(S + 1, sigma) - vega(S, sigma):.6f}"),
    ("vanna zero, bisection", f"{lo_s:.6f}"),
    ("vanna zero, K e^-(r-q-sig^2/2)T", f"{zero_closed:.6f}"),
    ("vega top, ternary search", f"{x:.6f}"),
    ("vanna at $80, $120", f"{vanna(80.0, sigma):.6f}  {vanna(120.0, sigma):.6f}"),
]
for k, s_k in ((80.0, "80 put"), (100.0, "100 call"), (120.0, "120 call")):
    g, va = gamma(S, sigma, k), vanna(S, sigma, T, q, k)
    rows.append((f"skew {s_k}: gamma, vanna, x skew", f"{g:.6f}  {va:.6f}  {-va * SKEW:.6f}  {-va * SKEW / g:+.0%}"))
d_now, d_after = delta(S, sigma, T, 120.0), delta(S + 5, sigma - 5 * SKEW, T, 120.0)
g120, va120 = gamma(S, sigma, 120.0), vanna(S, sigma, T, q, 120.0)
rows += [
    ("120 call, $5 up, vol 20% -> 17.5%", f"{d_now:.6f} -> {d_after:.6f}  change {d_after - d_now:.6f}"),
    ("  gamma only / gamma + vanna", f"{5 * g120:.6f}  {5 * g120 - 5 * SKEW * va120:.6f}"),
    ("wrong: d1 in place of d2", f"{-exp(-q * T) * phi(d1) * d1 / sigma:.6f}"),
    ("wrong: no e^-qT", f"{-phi(d1) * d2 / sigma:.6f}"),
    ("try: q = 4%", f"{vanna(S, sigma, T, 0.04):.6f}"),
    ("try: sigma = 30%", f"{vanna(S, 0.30):.6f}"),
    ("try: T = 3 months", f"{vanna(S, sigma, 0.25):.6f}"),
]
for name, val in rows:
    print(f"{name:<36} {val}")

spots = [70.0 + 5.0 * i for i in range(13)]
charts = [("chart, Acme price", [f"{s:.0f}" for s in spots]),
          ("chart, delta at 20%", [f"{delta(s, 0.20):.2f}" for s in spots]),
          ("chart, delta at 30%", [f"{delta(s, 0.30):.2f}" for s in spots]),
          ("chart, vega at 20%", [f"{vega(s, 0.20):.2f}" for s in spots]),
          ("chart, vanna 1 year", [f"{vanna(s, 0.20):.2f}" for s in spots]),
          ("chart, vanna 3 months", [f"{vanna(s, 0.20, 0.25):.2f}" for s in spots])]
for name, vals in charts:
    print(f"{name:<22}" + " ".join(f"{v:>6}" for v in vals))

assert abs(v1 - (-0.094753)) < 5e-7, "formula vs the shelf's house number"
assert abs(v2 - v1) < 1e-7 and abs(v3 - v1) < 1e-7, "both bumped readings land on the formula"
assert abs(v4 - v1) < 1e-6, "price-only integral road, no N used"
assert abs(v5 - v1) < 1e-7, "the put's vanna equals the call's"
assert abs(lo_s - zero_closed) < 1e-9 and abs(x - zero_closed) < 1e-5, "zero of vanna = top of vega"
assert abs((d_after - d_now) - (5 * g120 - 5 * SKEW * va120)) < abs((d_after - d_now) - 5 * g120), "vanna improves the skewed hedge"
print("ALL CHECKS PASS")
