# FX implied volatility -- the check behind the card.  Standard library only.
# EURUSD: spot 1.1000 USD per EUR, strike 1.1000, USD (domestic) 5%, EUR (foreign) 3%, one year.
# Nothing imported knows the answer: the normal CDF is a series written out, the root finder
# is bracketed Newton written out, the second price comes from Simpson's rule on the payoff.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height
def N(x):                                                       # bell-curve area left of x, by series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, n = x, x, 0
    while abs(term) > 1e-18:
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def gk(S, K, rd, rf, v, T, call=True):                          # Garman-Kohlhagen, domestic per foreign
    A, B = S * exp(-rf * T), K * exp(-rd * T)
    if v <= 0.0: return max(A - B, 0.0) if call else max(B - A, 0.0)
    d1 = (log(S / K) + (rd - rf + 0.5 * v * v) * T) / (v * sqrt(T))
    d2 = d1 - v * sqrt(T)
    return A * N(d1) - B * N(d2) if call else B * N(-d2) - A * N(-d1)

def vega(S, K, rd, rf, v, T):
    d1 = (log(S / K) + (rd - rf + 0.5 * v * v) * T) / (v * sqrt(T))
    return S * exp(-rf * T) * phi(d1) * sqrt(T)

def bounds(S, K, rd, rf, T, call=True):                         # floor and ceiling of the price
    A, B = S * exp(-rf * T), K * exp(-rd * T)
    return (max(A - B, 0.0), A) if call else (max(B - A, 0.0), B)

def implied(p, S, K, rd, rf, T, call=True, v0=None, trace=None):
    lo_p, hi_p = bounds(S, K, rd, rf, T, call)
    if not lo_p < p < hi_p: return None                          # no volatility exists: refuse
    lo, hi = 0.0, 4.0
    while gk(S, K, rd, rf, hi, T, call) < p: hi *= 2.0           # grow the bracket until it straddles
    v = v0 if v0 is not None else sqrt(2.0 * abs(log(S / K) + (rd - rf) * T) / T)   # inflection seed
    if not lo < v < hi: v = 0.5 * (lo + hi)
    for i in range(200):
        f = gk(S, K, rd, rf, v, T, call) - p
        if trace is not None: trace.append((i, v, f))
        if abs(f) < 1e-14: break
        if f > 0: hi = v
        else: lo = v
        g = vega(S, K, rd, rf, v, T)
        step = v - f / g if g > 0.0 else lo                      # flat curve: no tangent, so halve
        v = step if lo < step < hi else 0.5 * (lo + hi)          # Newton inside the bracket, else halve
    return v

def by_integral(S, K, rd, rf, v, T, n=20000):                  # road 2: average the payoff, no d1 or d2
    a, b = -10.0, 10.0
    h = (b - a) / n
    def f(z):
        ST = S * exp((rd - rf - 0.5 * v * v) * T + v * sqrt(T) * z)
        return max(ST - K, 0.0) * phi(z)
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return exp(-rd * T) * s * h / 3.0

def bisect(fn, target, lo, hi, n=50):
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        if fn(mid) < target: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

S, K, rd, rf, T = 1.10, 1.10, 0.05, 0.03, 1.0
C = gk(S, K, rd, rf, 0.10, T)                                   # the house premium at 10% vol
P = gk(S, K, rd, rf, 0.10, T, call=False)
floor, ceil = bounds(S, K, rd, rf, T)
q_house, q_pips, q_pct = 0.053556, 535.6, 4.869                 # three quotes of one premium
from_pips, from_pct = q_pips / 1e4, q_pct / 100.0 * S           # both to USD per EUR
tr = []
v_house = implied(q_house, S, K, rd, rf, T, trace=tr)
v_exact = implied(C, S, K, rd, rf, T)
v_road2 = bisect(lambda v: by_integral(S, K, rd, rf, v, T), C, 0.0001, 1.0)
eur_put = C / (S * K)                                           # EUR per USD, for one USD of notional
v_mirror = implied(eur_put, 1 / S, 1 / K, rf, rd, T, call=False)  # the mirror: USD put seen from EUR
v_parity = implied(C - (S * exp(-rf * T) - K * exp(-rd * T)), S, K, rd, rf, T, call=False)
tr_bad = []
implied(C, S, K, rd, rf, T, v0=1.5, trace=tr_bad)
bare = 1.5 - (gk(S, K, rd, rf, 1.5, T) - C) / vega(S, K, rd, rf, 1.5, T)   # one unguarded Newton step
naive = lambda p: bisect(lambda v: gk(S, K, rd, rf, v, T), p, 1e-6, 5.0)   # a solver with no bounds check
bump = (gk(S, K, rd, rf, 0.1001, T) - gk(S, K, rd, rf, 0.0999, T)) / 0.0002

rows = [("forward F = S e^((rd-rf)T)", S * exp((rd - rf) * T)), ("USD discount e^(-rd T)", exp(-rd * T)),
        ("EUR discount e^(-rf T)", exp(-rf * T)), ("discounted strike K e^-rdT", K * exp(-rd * T)),
        ("ln(F/K), the seed's input", log(S / K) + (rd - rf) * T), ("floor  (S e^-rfT - K e^-rdT)+", floor),
        ("ceiling  S e^-rfT", ceil), ("call at 10% vol, USD per EUR", C), ("put at 10% vol, USD per EUR", P),
        ("call in USD pips", C * 1e4), ("call in % of EUR", C / S * 100), ("call in % of USD", C / K * 100),
        ("mirror spot 1/S, EUR per USD", 1 / S), ("call in EUR pips (EUR per USD)", eur_put * 1e4), ("vega at 10%, USD per EUR per unit", vega(S, K, rd, rf, 0.10, T)),
        ("vega by bump", bump), ("1 Newton, exact premium", v_exact), ("1 Newton, quote 0.053556", v_house),
        ("1 Newton, quote 535.6 pips", implied(from_pips, S, K, rd, rf, T)),
        ("1 Newton, quote 4.869% of EUR", implied(from_pct, S, K, rd, rf, T)),
        ("2 bisection on Simpson price", v_road2), ("3 mirror USD put, EUR terms", v_mirror),
        ("4 USD-put from parity, inverted", v_parity), ("gap to floor at quote 0.0200", floor - 0.0200),
        ("wrong: 4.869% fed as USD per EUR", implied(0.04869, S, K, rd, rf, T)),
        ("wrong: rates swapped", implied(C, S, K, rf, rd, T)),
        ("wrong: 442.6 EUR pips read as USD", implied(0.04426, S, K, rd, rf, T)),
        ("wrong: 0.0200, no bounds check", naive(0.0200)), ("wrong: 535.6 unscaled, no check", naive(535.6)),
        ("try: quote 600 pips", implied(0.0600, S, K, rd, rf, T)), ("try: rates both 5%", implied(C, S, K, rd, rd, T)),
        ("try: half a year", implied(C, S, K, rd, rf, 0.5))]
for name, v in rows:
    print(f"{name:<36} " + ("          none" if v is None else f"{v:>14.6f}"))
d1 = (log(S / K) + (rd - rf + 0.005) * T) / 0.10
print(f"d1, d2 at 10%:        {d1:.6f}  {d1 - 0.10:.6f}")
print(f"N(d1), N(d2) at 10%:  {N(d1):.6f}  {N(d1 - 0.10):.6f}")
print("Newton from the seed:  step, vol, |price error| USD per EUR")
for i, v, f in tr: print(f"  {i:>2}  {v:.12f}  {abs(f):.12f}")
print(f"bare Newton from 1.5, first step: {bare:.6f}")
print("guarded Newton from 1.5: " + " ".join(f"{v:.6f}" for _, v, _ in tr_bad[:6]))
print("ladder, USD pips -> vol %:")
for qp in (200.0, 250.0, 400.0, 535.56, 800.0, 1500.0, 10000.0, 10700.0):
    v = implied(qp / 1e4, S, K, rd, rf, T)
    print(f"  {qp:>8.2f}  " + ("none" if v is None else f"{100 * v:.4f}"))
print("chart, vol %        " + " ".join(f"{2 * i:7d}" for i in range(11)))
print("chart, call pips    " + " ".join(f"{gk(S, K, rd, rf, 0.02 * i, T) * 1e4:7.2f}" for i in range(11)))
print(f"chart, lines: quote {C * 1e4:.2f}  floor {floor * 1e4:.2f}  bad quote {200:.2f}")

assert abs(v_exact - 0.10) < 1e-10, "Newton must recover the 10% that made the premium"
assert abs(v_road2 - v_exact) < 1e-6, "bisection on an integral price must land on the same vol"
assert abs(v_mirror - v_exact) < 1e-9, "the mirror put from the EUR side must imply the same vol"
assert abs(v_parity - v_exact) < 1e-9, "the parity put must imply the same vol"
assert abs(bump - vega(S, K, rd, rf, 0.10, T)) < 1e-6, "vega by bump vs formula"
assert implied(0.0200, S, K, rd, rf, T) is None, "a quote below the floor must be refused"
assert abs(gk(S, K, rd, rf, 0.003, T) - floor) < 1e-9, "tiny vol must price at the floor"
assert abs(C - 0.053556) < 5e-7 and abs(P - 0.032418) < 5e-7, "house call and put, USD per EUR"
assert abs(floor - 0.021138) < 5e-7 and abs(S * exp((rd - rf) * T) - 1.122221) < 5e-7, "house floor and forward"
assert all(abs(implied(q, S, K, rd, rf, T) - 0.10) < 2e-5 for q in (from_pips, from_pct)), "rounded quotes give 10.00%"
assert implied(ceil, S, K, rd, rf, T) is None and implied(1.07, S, K, rd, rf, T) is None, "at or above the ceiling: refuse"
assert bare < 0.0 and abs(tr_bad[-1][1] - 0.10) < 1e-9, "bare Newton goes negative; the bracketed one still lands"
print("ALL CHECKS PASS")
