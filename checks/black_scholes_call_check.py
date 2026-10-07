# Black-Scholes call -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing is imported that
# already knows the answer: the normal CDF is built from math.erf, the
# integral is Simpson's rule written out, the tree is a loop.
from math import log, sqrt, exp, erf, pi

def N(x):    return 0.5 * (1.0 + erf(x / sqrt(2.0)))     # bell-curve area to the left of x
def phi(x):  return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def d1d2(S, K, r, q, sigma, T):
    vt = sigma * sqrt(T)                                  # one "wiggle unit" for the whole life
    d1 = (log(S / K) + (r - q + 0.5 * sigma * sigma) * T) / vt
    return d1, d1 - vt

def call(S, K, r, q, sigma, T):                           # the formula itself
    d1, d2 = d1d2(S, K, r, q, sigma, T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)

def by_integral(S, K, r, q, sigma, T, payoff, n=40000):
    # Road 2: average the payoff over the bell curve by brute force (Simpson's rule).
    # Uses no d1, no d2 -- nothing borrowed from the formula.
    a, b = -10.0, 10.0
    h = (b - a) / n
    def f(z):
        ST = S * exp((r - q - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * z)
        return payoff(ST) * phi(z)
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * total * h / 3.0

def by_tree(S, K, r, q, sigma, T, steps=2000):
    # Road 3: the coin-flip version (Cox-Ross-Rubinstein).  Up or down each step, then average back.
    dt = T / steps
    u = exp(sigma * sqrt(dt)); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d)
    disc = exp(-r * dt)
    v = [max(S * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    for step in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(step)]
    return v[0]

# ---- the house example: $100 stock, $100 strike, 1 year, 5% rates, 2% dividend, 20% wiggle ----
S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1, d2 = d1d2(S, K, r, q, sigma, T)
C        = call(S, K, r, q, sigma, T)
C_int    = by_integral(S, K, r, q, sigma, T, lambda ST: max(ST - K, 0.0))
C_tree   = by_tree(S, K, r, q, sigma, T)
P_int    = by_integral(S, K, r, q, sigma, T, lambda ST: max(K - ST, 0.0))   # the put, priced independently
parity_l = C - P_int
parity_r = S * exp(-q * T) - K * exp(-r * T)
h = 0.01
delta_fd = (call(S + h, K, r, q, sigma, T) - call(S - h, K, r, q, sigma, T)) / (2 * h)
delta_an = exp(-q * T) * N(d1)

# ---- what breaks if you get a piece wrong ----
no_discount = S * exp(-q * T) * N(d1) - K * N(d2)            # forgot e^{-rT}
both_d2     = S * exp(-q * T) * N(d2) - K * exp(-r * T) * N(d2)
both_d1     = S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1)
forgot_q    = call(S, K, r, 0.0, sigma, T)                    # priced as if no dividend
def call_sigmaT(S, K, r, q, sigma, T):                       # sigma*T instead of sigma*sqrt(T)
    d1w = (log(S / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * T)
    return S * exp(-q * T) * N(d1w) - K * exp(-r * T) * N(d1w - sigma * T)
wrong_4y, right_4y = call_sigmaT(S, K, r, q, sigma, 4.0), call(S, K, r, q, sigma, 4.0)
wrong_3m, right_3m = call_sigmaT(S, K, r, q, sigma, 0.25), call(S, K, r, q, sigma, 0.25)

# ---- try changing ----
vol_40   = call(S, K, r, q, 0.40, T)
vol_10   = call(S, K, r, q, 0.10, T)
k_120    = call(S, 120.0, r, q, sigma, T)
short_in = call(120.0, K, r, q, sigma, 0.01)

rows = [
    ("d1", d1), ("d2", d2), ("N(d1)  chance, counted in shares", N(d1)), ("N(d2)  chance, counted in cash", N(d2)),
    ("share half  S e^-qT N(d1)", S * exp(-q * T) * N(d1)),
    ("cash half   K e^-rT N(d2)", K * exp(-r * T) * N(d2)),
    ("1 formula", C), ("2 Simpson integral", C_int), ("3 tree, 2000 steps", C_tree),
    ("4 put by integral", P_int), ("  C - P", parity_l), ("  S e^-qT - K e^-rT", parity_r),
    ("5 delta by bump", delta_fd), ("  e^-qT N(d1)", delta_an),
    ("breakeven S = K + C", K + C),
    ("wrong: no discount on K", no_discount), ("wrong: N(d2) both halves", both_d2),
    ("wrong: N(d1) both halves", both_d1), ("wrong: forgot the 2% dividend", forgot_q),
    ("wrong: sigma*T, 4 years", wrong_4y), ("  right, 4 years", right_4y),
    ("wrong: sigma*T, 3 months", wrong_3m), ("  right, 3 months", right_3m),
    ("try: sigma = 0.40", vol_40), ("try: sigma = 0.10", vol_10),
    ("try: K = 120", k_120), ("try: S = 120, T = 0.01", short_in),
]
for name, v in rows:
    print(f"{name:<36} {v:>14.6f}")

# ---- the option has a price every day, not just at expiry ----
print()
print("option price: Acme price across, months left down")
spots = (80.0, 90.0, 100.0, 110.0, 120.0)
print(f"{'months left':>12}" + "".join(f"{s:>9.0f}" for s in spots))
for months in (12, 9, 6, 3, 1, 0):
    t = months / 12.0
    vals = [call(s, K, r, q, sigma, t) if t > 0 else max(s - K, 0.0) for s in spots]
    print(f"{months:>12d}" + "".join(f"{v:>9.2f}" for v in vals))
# ---- one story, followed month by month: Acme 100 -> 110 -> 100 -> 95 -> 105 at expiry ----
print()
print("story: paid 9.23 at month 0; Acme's path and the option's worth")
for months, s in ((0, 100.0), (3, 110.0), (6, 100.0), (9, 95.0), (12, 105.0)):
    t = (12 - months) / 12.0
    v = call(s, K, r, q, sigma, t) if t > 0 else max(s - K, 0.0)
    print(f"  month {months:>2}   Acme {s:7.2f}   option {v:6.2f}   vs 9.23 paid: {v - C:+6.2f}")

# ---- chart points for the pictures: Acme 80..120 in $5 steps ----
print()
chart_spots = [80.0 + 5.0 * i for i in range(9)]
print(f"{'chart, Acme price':<22}" + " ".join(f"{s:6.0f}" for s in chart_spots))
for label, t in (("chart, 12 months left", 1.0), ("chart, 3 months left", 0.25), ("chart, expiry day", 0.0)):
    vals = [call(s, K, r, q, sigma, t) if t > 0 else max(s - K, 0.0) for s in chart_spots]
    print(f"{label:<22}" + " ".join(f"{v:6.2f}" for v in vals))
profit_spots = [80.0 + 5.0 * i for i in range(11)]
print(f"{'chart, Acme at expiry':<22}" + " ".join(f"{s:6.0f}" for s in profit_spots))
print(f"{'chart, profit after 9.23':<22}" + " ".join(f"{max(s - K, 0.0) - C:6.2f}" for s in profit_spots))

assert abs(C - 9.227005508154) < 1e-9,        "formula vs the card's worked number"
assert abs(C_int - C) < 1e-7,                 "integral road must land on the formula"
assert abs(C_tree - C) < 0.01,                "tree road within a cent"
assert abs(parity_l - parity_r) < 1e-6,       "put-call parity with an independent put"
assert abs(delta_fd - delta_an) < 1e-6,       "bumped delta vs e^-qT N(d1)"
assert N(d1) > N(d2),                         "share-counted chance must exceed cash-counted chance"
print("ALL CHECKS PASS")
