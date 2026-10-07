# Options on commodity futures -- the check behind the card.  Standard library
# only.  Nothing imported knows the answer: the normal CDF is a power series
# written out here, the integral is Simpson's rule, the tree is a loop.
# House Brent: futures 85 USD/bbl, strike 85, vol 30%, six months, rate 5%.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                  # bell-curve area left of x
    if x > 8.0: return 1.0
    if x < -8.0: return 0.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def black76(F, K, r, sig, T, put=False, t_disc=None):
    D = exp(-r * (T if t_disc is None else t_disc))
    d1 = (log(F / K) + 0.5 * sig * sig * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    if put: return D * (K * N(-d2) - F * N(-d1))
    return D * (F * N(d1) - K * N(d2))

def spot_route(S, K, r, y, sig, T):                        # Black-Scholes on the spot, yield y
    d1 = (log(S / K) + (r - y + 0.5 * sig * sig) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    return S * exp(-y * T) * N(d1) - K * exp(-r * T) * N(d2)

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

def by_integral(F, K, r, sig, T, put=False):              # average payoff over the future at expiry
    v = sig * sqrt(T); z0 = (log(K / F) + 0.5 * v * v) / v  # the future ends above K when z > z0
    FT = lambda z: F * exp(-0.5 * v * v + v * z)
    if put: return exp(-r * T) * simpson(lambda z: (K - FT(z)) * phi(z), -10.0, z0)
    return exp(-r * T) * simpson(lambda z: (FT(z) - K) * phi(z), z0, 10.0)

def tree(F, K, disc, sig, T, steps, american):           # coin-flip tree on the futures price
    dt = T / steps; u = exp(sig * sqrt(dt)); d = 1.0 / u
    p = (1.0 - d) / (u - d); g = exp(-disc * dt)          # the future drifts nowhere: p solves p u + (1-p) d = 1
    vals = [max(F * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    for i in range(steps - 1, -1, -1):
        for j in range(i + 1):
            cont = g * (p * vals[j + 1] + (1.0 - p) * vals[j])
            vals[j] = max(cont, F * u ** j * d ** (i - j) - K) if american else cont
    return vals[0]

def bach(F, K, sn, T, r, put=False):                      # Bachelier: absolute moves
    s = sn * sqrt(T); d = (F - K) / s; D = exp(-r * T)
    if put: return D * ((K - F) * N(-d) + s * phi(d))
    return D * ((F - K) * N(d) + s * phi(d))

F, K, r, sig, T, lot = 85.0, 85.0, 0.05, 0.30, 0.5, 1000
D = exp(-r * T); v = sig * sqrt(T)
d1 = (log(F / K) + 0.5 * v * v) / v; d2 = d1 - v
C, P = black76(F, K, r, sig, T), black76(F, K, r, sig, T, put=True)
C_int, P_int = by_integral(F, K, r, sig, T), by_integral(F, K, r, sig, T, put=True)
C_tree = tree(F, K, r, sig, T, 2000, False)
C_amer = tree(F, K, r, sig, T, 2000, True)
V = C / D                                                  # margined, futures-style quote
V_tree = tree(F, K, 0.0, sig, T, 2000, True)               # American, no premium to fund
y87 = r - log(F / 87.0) / T; y80 = r - log(F / 80.0) / T
C87, C80 = spot_route(87.0, K, r, y87, sig, T), spot_route(80.0, K, r, y80, sig, T)
h = 0.01
delta_bump = (black76(F + h, K, r, sig, T) - black76(F - h, K, r, sig, T)) / (2 * h)
Tdel = 7.0 / 12.0                                           # a clock run a month past expiry
sn = sig * F                                                # normal vol matched at 85
rows = [
    ("sig rootT", v), ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("discount D, 6 months", D),
    ("1 formula, call", C), ("2 Simpson integral, call", C_int), ("3 tree 2000 steps, call", C_tree),
    ("4 spot route, spot 87, yield", y87), ("  call from spot 87", C87),
    ("  spot route, spot 80, yield", y80), ("  call from spot 80", C80),
    ("put, formula", P), ("put, Simpson integral", P_int), ("C - P", C - P), ("D (F - K)", D * (F - K)),
    ("call per 1,000-barrel lot", C * lot), ("margined quote C / D", V), ("breakeven future, K + C / D", K + V),
    ("  American tree, no funding", V_tree), ("American tree, premium up front", C_amer),
    ("  early-exercise value", C_amer - C_tree),
    ("delta D N(d1)", D * N(d1)), ("delta by bump", delta_bump),
    ("gamma D phi(d1) / (F sig rootT)", D * phi(d1) / (F * v)), ("vega D F phi(d1) rootT", D * F * phi(d1) * sqrt(T)),
    ("  vega per volatility point", D * F * phi(d1) * sqrt(T) / 100),
    ("rho -T C", -T * C),
    ("wrong: spot 87 used as F", black76(87.0, K, r, sig, T)),
    ("wrong: 7 months for vol and discount", black76(F, K, r, sig, Tdel)),
    ("wrong: future as a share, drift r", spot_route(F, K, r, 0.0, sig, T)),
    ("gap: margined quote minus C", V - C), ("  gap per lot", (V - C) * lot),
    ("try: vol 40%", black76(F, K, r, 0.40, T)), ("try: strike 95", black76(F, 95.0, r, sig, T)),
    ("try: one month left", black76(F, K, r, sig, 1 / 12)),
    ("normal vol sig F, USD/bbl/yr", sn), ("Bachelier call, 85, 6 months", bach(F, K, sn, T, r)),
    ("  Bachelier minus Black-76", bach(F, K, sn, T, r) - C),
    ("normal: chance below 0, 85, 6m", N(-F / (sn * sqrt(T)))),
]
for name, x in rows:
    print(f"{name:<36} {x:>14.6f}")
for lvl in (85.0, 40.0, 20.0, 10.0, 5.0):
    print(f"one month, future {lvl:5.0f}: normal chance below 0 {N(-lvl / (sn * sqrt(1 / 12))):.4f}")
print(f"normal put, strike 0, future 5, one month {bach(5.0, 0.0, sn, 1 / 12, r, put=True):.6f}")
try:
    wti = f"{black76(-37.63, 10.0, r, sig, 1 / 12):.6f}"
except ValueError:
    wti = "no price: log of a negative number"
print(f"Black-76 at future -37.63: {wti}")
print(f"normal put, strike 0, future -37.63, one month {bach(-37.63, 0.0, sn, 1 / 12, r, put=True):.6f}")
xs = [65.0 + 5.0 * i for i in range(9)]
print("chart, future at expiry " + " ".join(f"{x:6.0f}" for x in xs))
print("chart, payoff           " + " ".join(f"{max(x - K, 0.0):6.2f}" for x in xs))
print("chart, profit after C/D " + " ".join(f"{max(x - K, 0.0) - V:6.2f}" for x in xs))

assert abs(C - 7.002679) < 5e-7,                 "house number"
assert abs(C_int - C) < 1e-7,                    "integral road lands on the formula"
assert abs(C_tree - C) < 0.005,                  "tree road within half a cent"
assert abs(C87 - C) < 1e-9 and abs(C80 - C) < 1e-9, "spot enters only through the futures quote"
assert abs((C - P_int) - D * (F - K)) < 1e-7,    "parity with a put priced on its own"
assert abs(V_tree - V) < 0.005,                  "margined American tree equals C / D"
assert abs(delta_bump - D * N(d1)) < 1e-6,       "bumped delta"
print("ALL CHECKS PASS")
