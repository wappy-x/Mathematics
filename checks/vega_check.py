# Vega -- the check behind the card.  Standard library only, and nothing
# imported knows the answer: the bell-curve area N(x) is summed from its own
# series, the integrals are Simpson's rule, the random numbers are home-made.
from math import log, sqrt, exp, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x
def N(x):                                                 # bell-curve area left of x
    if abs(x) > 8.5: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 0                              # x + x^3/3 + x^5/(3*5) + ...
    while abs(term) > 1e-17 * abs(total):
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total

def d1d2(S, K, r, q, s, T):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return d1, d1 - s * sqrt(T)
def call(S, K, r, q, s, T):
    d1, d2 = d1d2(S, K, r, q, s, T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def vega(S, K, r, q, s, T):                               # the card's formula
    return S * exp(-q * T) * phi(d1d2(S, K, r, q, s, T)[0]) * sqrt(T)

def simpson_price(S, K, r, q, s, T, payoff, n=20000):     # no d1, no d2, no N
    a, h = -10.0, 20.0 / n
    f = lambda z: payoff(S * exp((r - q - 0.5 * s * s) * T + s * sqrt(T) * z)) * phi(z)
    tot = f(a) + f(a + n * h)
    for i in range(1, n): tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

S, K, r, q, s, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1, d2 = d1d2(S, K, r, q, s, T)
v = vega(S, K, r, q, s, T)
v_cash = K * exp(-r * T) * phi(d2) * sqrt(T)
h = 1e-4
bump = (call(S, K, r, q, s + h, T) - call(S, K, r, q, s - h, T)) / (2 * h)
cpay, ppay = (lambda x: max(x - K, 0.0)), (lambda x: max(K - x, 0.0))
bump_int = (simpson_price(S, K, r, q, s + h, T, cpay) - simpson_price(S, K, r, q, s - h, T, cpay)) / (2 * h)
bump_put = (simpson_price(S, K, r, q, s + h, T, ppay) - simpson_price(S, K, r, q, s - h, T, ppay)) / (2 * h)

state = 20260919                                          # splitmix64 random numbers
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
paths, acc, acc2 = 200000, 0.0, 0.0
for _ in range(paths):                                    # pathwise: d(payoff)/d(sigma) per path
    z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
    ST = S * exp((r - q - 0.5 * s * s) * T + s * sqrt(T) * z)
    g = exp(-r * T) * ST * (sqrt(T) * z - s * T) if ST > K else 0.0
    acc += g; acc2 += g * g
mc = acc / paths
mc_se = sqrt((acc2 / paths - mc * mc) / paths)

def curve(f, x, e):                                       # second difference, Richardson-refined
    d = lambda e: (f(x + e) - 2 * f(x) + f(x - e)) / e ** 2
    return (4 * d(e) - d(2 * e)) / 3
gamma = curve(lambda y: call(y, K, r, q, s, T), S, 0.1)
volga = curve(lambda y: call(S, K, r, q, y, T), s, 2e-3)
c20, c21 = call(S, K, r, q, 0.20, T), call(S, K, r, q, 0.21, T)
p20 = c20 - S * exp(-q * T) + K * exp(-r * T)
peak_s = max((vega(70 + i / 1000, K, r, q, s, T), 70 + i / 1000) for i in range(60001))[1]
peak_k = max((vega(S, 70 + i / 1000, r, q, s, T), 70 + i / 1000) for i in range(60001))[1]
peak_t = max((vega(S, K, r, q, s, i / 100), i / 100) for i in range(1, 3001))[1]
grid = [vega(S, k, r, q, s, t) for k in range(60, 161, 5) for t in (0.25, 1, 5, 30)]

quote, x, steps = 12.0, 0.20, []                          # implied vol: Newton steers by vega
for _ in range(4):
    x -= (call(S, K, r, q, x, T) - quote) / vega(S, K, r, q, x, T); steps.append(x)
lo, hi = 0.01, 2.0                                        # a second road: bisection
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if call(S, K, r, q, mid, T) < quote else (lo, mid)
far_q = call(S, 150.0, r, q, 0.40, T)                     # a far strike, a poor start
far_v = vega(S, 150.0, r, q, 0.10, T)
far_step = 0.10 - (call(S, 150.0, r, q, 0.10, T) - far_q) / far_v
far_step20 = 0.20 - (call(S, 150.0, r, q, 0.20, T) - far_q) / vega(S, 150.0, r, q, 0.20, T)

rows = [("d1", d1), ("d2", d2), ("phi(d1)", phi(d1)), ("phi(d2)", phi(d2)),
    ("S e^-qT", S * exp(-q * T)), ("K e^-rT", K * exp(-r * T)),
    ("1 vega, S e^-qT phi(d1) rootT", v), ("2 vega, K e^-rT phi(d2) rootT", v_cash),
    ("3 bump the formula price", bump), ("4 bump the Simpson call", bump_int),
    ("5 bump the Simpson put", bump_put), ("6 pathwise Monte Carlo", mc), ("  standard error", mc_se),
    ("7 gamma by bump", gamma), ("  sigma T S^2 gamma", s * T * S * S * gamma),
    ("per vol point", v / 100), ("call at 20%", c20), ("call at 21%", c21),
    ("  full reprice, 20% to 21%", c21 - c20), ("  vega times 0.01", v * 0.01),
    ("volga by bump", volga), ("  plus half volga times 0.01^2", v * 0.01 + 0.5 * volga * 1e-4),
    ("put at 20%, by parity", p20), ("put at 21%, by parity", c21 - S * exp(-q * T) + K * exp(-r * T)),
    ("forward S e^(r-q)T", S * exp((r - q) * T)),
    ("peak in spot, K e^-(r-q-s^2/2)T", K * exp(-(r - q - 0.5 * s * s) * T)), ("  grid search", peak_s),
    ("peak in strike, S e^(r-q+s^2/2)T", S * exp((r - q + 0.5 * s * s) * T)), ("  grid search", peak_k),
    ("peak in maturity, grid (years)", peak_t), ("  vega there", vega(S, K, r, q, s, peak_t)),
    ("smallest vega on an 84-point grid", min(grid)),
    ("wrong: N(d1) for phi(d1)", S * exp(-q * T) * N(d1) * sqrt(T)),
    ("wrong: S e^-qT with phi(d2)", S * exp(-q * T) * phi(d2) * sqrt(T)),
    ("wrong: no rootT, 4 years", vega(S, K, r, q, s, 4.0) / 2.0), ("  right, 4 years", vega(S, K, r, q, s, 4.0)),
    ("wrong: 20% to 20.2%, vega x 0.002", v * 0.002),
    ("Newton, quote 12.00, step 1", steps[0]), ("  step 2", steps[1]), ("  step 4", steps[3]),
    ("  bisection, 60 halvings", 0.5 * (lo + hi)),
    ("far: K 150 call at 40% vol", far_q), ("  vega at a 10% start", far_v), ("  first Newton step", far_step),
    ("  first step from a 20% start", far_step20), ("call at 1e-6 vol, the floor", call(S, K, r, q, 1e-6, T)),
    ("try: vega at 10% vol", vega(S, K, r, q, 0.10, T)), ("try: vega at 30% vol", vega(S, K, r, q, 0.30, T)),
    ("try: vega at 3 months", vega(S, K, r, q, s, 0.25)), ("phi(0), top of the bell curve", phi(0.0))]
for name, val in rows: print(f"{name:<34} {val:>16.6f}")
spots = list(range(70, 131, 5))
print("chart spot " + " ".join(f"{x:6d}" for x in spots))
for t in (1.0, 0.25): print(f"chart T={t:<4}" + " ".join(f"{vega(float(x), K, r, q, s, t):6.2f}" for x in spots))
mats = (0.25, 0.5, 1, 2, 4, 10, 20, 30)
print("bars " + " ".join(f"{t}y {vega(S, K, r, q, s, t):.2f}" for t in mats))

assert abs(v - 37.901157510017) < 1e-9, "formula vs the shelf's house vega"
assert abs(v_cash - v) < 1e-12, "share side vs cash side, Step 1"
assert abs(bump - v) < 1e-6, "bumped formula price vs vega"
assert abs((call(S, K, r, q, s + h, 4.0) - call(S, K, r, q, s - h, 4.0)) / (2 * h)
           - vega(S, K, r, q, s, 4.0)) < 1e-6, "bumped price vs vega at four years"
assert abs(bump_int - v) < 1e-4, "bumped Simpson call vs vega"
assert abs(bump_put - v) < 1e-4, "put vega by its own integral vs call vega"
assert abs(mc - v) < 3 * mc_se, "pathwise Monte Carlo within three standard errors"
assert abs(s * T * S * S * gamma - v) < 1e-4, "gamma link"
assert abs(peak_s - K * exp(-(r - q - 0.5 * s * s) * T)) < 2e-3, "peak in spot"
assert abs(peak_k - S * exp((r - q + 0.5 * s * s) * T)) < 2e-3, "peak in strike"
assert min(grid) > 0, "vega positive everywhere on the grid"
assert abs(steps[3] - 0.5 * (lo + hi)) < 1e-9, "Newton vs bisection"
print("ALL CHECKS PASS")
