# Gamma -- the check behind the card.  Python standard library only.
# Every number on the card is printed here.  The bell-curve area N is a power
# series written out below (no erf); the tree is a loop; nothing imported knows the answer.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                                  # bell-curve area left of x
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term = total = x; k = 1
    while abs(term) > 1e-18 * abs(total):                  # x + x^3/3 + x^5/15 + ...
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def d1(S, K, r, q, s, T): return (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
def call(S, K, r, q, s, T):
    a = d1(S, K, r, q, s, T); return S * exp(-q * T) * N(a) - K * exp(-r * T) * N(a - s * sqrt(T))
def put(S, K, r, q, s, T):
    a = d1(S, K, r, q, s, T); return K * exp(-r * T) * N(s * sqrt(T) - a) - S * exp(-q * T) * N(-a)
def delta(S, K, r, q, s, T): return exp(-q * T) * N(d1(S, K, r, q, s, T))
def gamma(S, K, r, q, s, T): return exp(-q * T) * phi(d1(S, K, r, q, s, T)) / (S * s * sqrt(T))

def tree_gamma(S, K, r, q, s, T, n=2000):
    # Road 6: Cox-Ross-Rubinstein coin-flip tree; gamma read off the three nodes two steps in.
    dt = T / n; u = exp(s * sqrt(dt)); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    v = [max(S * u ** j * d ** (n - j) - K, 0.0) for j in range(n + 1)]
    for step in range(n, 2, -1):
        v = [disc * (p * v[j + 1] + (1 - p) * v[j]) for j in range(step)]
    up, mid, dn = S * u * u, S, S * d * d
    return ((v[2] - v[1]) / (up - mid) - (v[1] - v[0]) / (mid - dn)) / (0.5 * (up - dn))

S, K, r, q, s, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
a, g, C, D = d1(S, K, r, q, s, T), gamma(S, K, r, q, s, T), call(S, K, r, q, s, T), delta(S, K, r, q, s, T)
h = 0.01
g_price = (call(S + h, K, r, q, s, T) - 2 * C + call(S - h, K, r, q, s, T)) / (h * h)
g_delta = (delta(S + h, K, r, q, s, T) - delta(S - h, K, r, q, s, T)) / (2 * h)
g_put = (put(S + h, K, r, q, s, T) - 2 * put(S, K, r, q, s, T) + put(S - h, K, r, q, s, T)) / (h * h)
mu, v = log(S) + (r - q - 0.5 * s * s) * T, s * sqrt(T)     # Road 5: log-price centre and spread
f_K = exp(-(log(K) - mu) ** 2 / (2 * v * v)) / (K * v * sqrt(2 * pi))
g_density = exp(-r * T) * (K / S) ** 2 * f_K
g_tree = tree_gamma(S, K, r, q, s, T)
dT = 1e-4                                                  # Road 7: the pricing equation turned round
theta = -(call(S, K, r, q, s, T + dT) - call(S, K, r, q, s, T - dT)) / (2 * dT)
g_pde = (r * C - theta - (r - q) * S * D) / (0.5 * s * s * S * S)

up5, dn5 = delta(S + 5, K, r, q, s, T) - D, delta(S - 5, K, r, q, s, T) - D
full5 = call(S + 5, K, r, q, s, T) - C - 5 * D             # hedged long call after +5, repriced
book = 10000                                               # a desk short 10,000 calls, hedged
sh_before, sh_after = book * D, book * delta(S + 5, K, r, q, s, T)
day = S * s * sqrt(1 / 252)                                # one typical daily move, in dollars
S_star = K * exp(-(r - q + 1.5 * s * s) * T)               # where the hump peaks
scan = max((gamma(60 + i / 100, K, r, q, s, T), 60 + i / 100) for i in range(8001))
g40 = gamma(S, K, r, q, 0.40, T)
wrongs = [("wrong: N(d1) for phi(d1)", exp(-q * T) * N(a) / (S * s * sqrt(T))),
          ("wrong: phi(d2) for phi(d1)", exp(-q * T) * phi(a - s) / (S * s * sqrt(T))),
          ("wrong: S missing downstairs", exp(-q * T) * phi(a) / (s * sqrt(T))),
          ("wrong: sigma*T, 3 months", exp(-q * .25) * phi((log(S / K) + (r - q + .02) * .25) / (s * .25)) / (S * s * .25)),
          ("  right, 3 months", gamma(S, K, r, q, s, 0.25))]

rows = [("d1", a), ("phi(d1)  bell height", phi(a)), ("e^-qT", exp(-q * T)),
        ("call", C), ("delta", D),
        ("1 formula", g), ("2 price bumped twice", g_price), ("3 delta bumped", g_delta),
        ("4 put bumped twice", g_put), ("5 density at the strike", g_density), ("  f(K)", f_K),
        ("6 tree, 2000 steps", g_tree), ("7 from the pricing equation", g_pde), ("  theta by bump", theta),
        ("delta at 105", D + up5), ("delta shift +5, actual", up5),
        ("delta shift -5, actual", dn5), ("  gamma * 5", 5 * g),
        ("hedged P&L +5, full reprice", full5), ("  half gamma * 25", 0.5 * g * 25), ("  gamma * 25, no half", g * 25),
        ("book: shares before", sh_before), ("  shares after +5", sh_after), ("  shares to buy", sh_after - sh_before),
        ("  dollars spent at 105", (sh_after - sh_before) * 105), ("  book loss, full reprice", book * full5),
        ("daily 1-sd move, dollars", day), ("  shares per daily move", book * g * day),
        ("peak S*, formula", S_star), ("  peak S*, scan by cents", scan[1]), ("  gamma at the peak", scan[0]),
        ("gamma, sigma = 0.40", g40), ("  ratio to sigma = 0.20", g40 / g)] + wrongs + [
        ("try: T = 1 week", gamma(S, K, r, q, s, 1 / 52))]
for name, x in rows:
    print(f"{name:<30} {x:>14.6f}")

print("\ntime left   gamma@100  gamma@95  shares/$1 at 100")
for lab, t in (("12 months", 1.0), ("6 months", 0.5), ("3 months", 0.25), ("1 month", 1 / 12),
               ("1 week", 1 / 52), ("1 day", 1 / 365)):
    g100 = gamma(S, K, r, q, s, t)
    print(f"{lab:<10} {g100:>10.4f} {gamma(95.0, K, r, q, s, t):>9.4f} {book * g100:>10.0f}")

print("\nchart, Acme price  " + " ".join(f"{70 + 5 * i:>6d}" for i in range(13)))
for lab, sg, t in (("gamma x100 20% 1y", 0.20, 1.0), ("gamma x100 40% 1y", 0.40, 1.0), ("gamma x100 20% 3m", 0.20, 0.25)):
    print(f"{lab:<19}" + " ".join(f"{100 * gamma(70 + 5 * i, K, r, q, sg, t):>6.2f}" for i in range(13)))
print("call, 1y left      " + " ".join(f"{call(70 + 5 * i, K, r, q, s, T):>6.2f}" for i in range(13)))
print("hedge line         " + " ".join(f"{C + D * (5 * i - 30):>6.2f}" for i in range(13)))

assert abs(g - 0.018950578755) < 1e-11,        "formula vs the house number"
assert abs(g_price - g) < 1e-7,                "price bumped twice"
g3 = [call(S + e, K, r, q, s, 0.25) for e in (h, 0, -h)]
assert abs((g3[0] - 2 * g3[1] + g3[2]) / (h * h) - gamma(S, K, r, q, s, 0.25)) < 1e-7, "3 months, bumped twice"
assert abs(g_put - g) < 1e-7,                  "put gamma equals call gamma"
assert abs(g_density - g) < 1e-12,             "density at the strike, no d1 used"
assert abs(g_tree - g) < 1e-4,                 "tree within a ten-thousandth"
assert abs(g_pde - g) < 1e-6,                  "gamma from theta and delta"
assert abs(scan[1] - S_star) < 0.01,           "hump peaks at S*"
assert abs(full5 - 0.5 * g * 25) / full5 < 0.05, "half gamma m^2 within 5% at a 5-dollar move"
assert 0.45 < g40 / g < 0.55,                  "doubling vol about halves gamma at the strike"
print("ALL CHECKS PASS")
