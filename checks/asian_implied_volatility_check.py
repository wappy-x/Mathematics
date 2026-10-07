# Implied vol from an Asian quote on jet fuel: 52 weekly fixings read the futures curve 100 e^(0.05 t).
# Standard library only.  Nothing imported knows the answer: the bell-curve area, both root finders,
# the random numbers (splitmix64 + Box-Muller) and every simulated path are written out below.
from math import log, sqrt, exp, cos, pi, isnan
from array import array

K, r, T, n, Q = 100.0, 0.05, 1.0, 52, 5.854        # Q: the house Asian quote, $ per barrel

def N(x):                                   # area left of x: Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        i += 2.0
        b, t = b * x * x / i, s
        s += b
    return 0.5 + s * exp(-0.5 * x * x - 0.91893853320467274178)
def black(F, v, k=K, tp=T):                 # Black-76: call on a lognormal with forward F, whole-life log-spread v
    d1 = (log(F / k) + 0.5 * v * v) / v
    return exp(-r * tp) * (F * N(d1) - k * N(d1 - v))
def curve(c, lvl=100.0): return lambda t: lvl * exp(c * t)
def dates(m, t1=T, t0=0.0): return [t0 + (t1 - t0) * (i + 1) / m for i in range(m)]
fw, ts = curve(0.05), dates(n)

def tw(s, f=fw, tx=ts, k=K):                # Turnbull-Wakeman price and its exact slope in s (vega)
    m, Fs = len(tx), [f(t) for t in tx]
    M1 = sum(Fs) / m
    M2 = dM2 = 0.0
    for i in range(m):
        for j in range(m):
            a = Fs[i] * Fs[j] * exp(s * s * min(tx[i], tx[j]))
            M2, dM2 = M2 + a, dM2 + a * 2.0 * s * min(tx[i], tx[j])
    M2, dM2 = M2 / (m * m), dM2 / (m * m)
    v = sqrt(log(M2 / (M1 * M1)))
    e1 = (log(M1 / k) + 0.5 * v * v) / v
    return black(M1, v, k, tx[-1]), exp(-r * tx[-1]) * M1 * exp(-0.5 * e1 * e1) / sqrt(2.0 * pi) * dM2 / (2.0 * v * M2), M1, v

def bisect(f, q, lo=1e-6, hi=5.0):         # f increasing: keep the half that straddles q
    if not f(lo) < q < f(hi): return float("nan")        # outside the band: no volatility fits
    while hi - lo > 1e-13:
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < q else (lo, mid)
    return 0.5 * (lo + hi)
def newton(q, s=0.30):                      # step by price error over vega; the path is kept
    path = [s]
    while True:
        p, vg = tw(s)[:2]
        s -= (p - q) / vg
        path.append(s)
        if abs(path[-1] - path[-2]) < 1e-13: return s, path

state = 20260927                            # splitmix64, the arithmetic-asian-option card's seed
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

PATHS = 50000                               # one set of draws, reused at every trial volatility
Z = array("d", (sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform()) for _ in range(PATHS * n)))

def kv(s):                                  # geometric twin, exact (Kemna-Vorst on the curve)
    mu = sum(log(fw(t)) - 0.5 * s * s * t for t in ts) / n
    var = s * s * sum(min(a, b) for a in ts for b in ts) / (n * n)
    return black(exp(mu + 0.5 * var), sqrt(var))

def mc(s):                                  # controlled simulation: the geometric twin as control
    d, base = exp(-r * T), [log(fw(t)) - 0.5 * s * s * t for t in ts]
    steps = [s * sqrt(t - u) for t, u in zip(ts, [0.0] + ts[:-1])]
    sx = sxx = sy = syy = sxy = 0.0
    for p in range(PATHS):
        W = tot = totlog = 0.0
        for i in range(n):
            W += steps[i] * Z[p * n + i]
            tot, totlog = tot + exp(base[i] + W), totlog + base[i] + W
        X, Y = d * max(tot / n - K, 0.0), d * max(exp(totlog / n) - K, 0.0)
        sx, sxx, sy, syy, sxy = sx + X, sxx + X * X, sy + Y, syy + Y * Y, sxy + X * Y
    mx, my = sx / PATHS, sy / PATHS
    vy, cxy, vx = syy / PATHS - my * my, sxy / PATHS - mx * my, sxx / PATHS - mx * mx
    beta = cxy / vy
    return mx - beta * (my - kv(s)), sqrt((vx - beta * cxy) / PATHS)
def secant(f, q, a=0.19, b=0.21):           # road 3: root of the simulated price, secant steps
    fa, fb, k = f(a) - q, f(b) - q, 2
    while abs(b - a) > 1e-9:
        a, b, fa = b, b - fb * (b - a) / (fb - fa), fb
        fb, k = f(b) - q, k + 1
    return b, k

def row(label, *vals, dp=6):
    print(f"{label:<44}" + "".join(f"{v:>12.{dp}f}" for v in vals))

TW20, vega20, M1, vA20 = tw(0.20)
floor, ceil = exp(-r * T) * max(M1 - K, 0.0), exp(-r * T) * M1
iv_bis = bisect(lambda s: tw(s)[0], Q)
iv_new, npath = newton(Q)
mc20, se20 = mc(0.20)
iv_mc, evals = secant(lambda s: mc(s)[0], Q)
van_M1 = bisect(lambda v: black(M1, v), Q)           # vanilla formula on the strip's forward (the swap price)
van_dec = bisect(lambda v: black(fw(T), v), Q)       # vanilla formula on the December futures
c_week, below = (n + 1) * (2 * n + 1) / (6.0 * n * n), bisect(lambda s: tw(s)[0], 2.40)  # c: variance kept

for label, *vals in [("quote Q; strip forward M1; Dec futures", Q, M1, fw(T)),
        ("band: floor e^-rT (M1-K)+, ceiling e^-rT M1", floor, ceil),
        ("TW at 20%; vega/pt; gap to Q; one Newton step", TW20, vega20 / 100, TW20 - Q, 0.20 - (TW20 - Q) / vega20), ("TW log-spread vA at 20%", vA20),
        ("controlled simulation at 20%; error bar", mc20, se20),
        ("1 implied vol, bisection on TW", iv_bis), ("2 implied vol, Newton on TW", iv_new),
        ("3 implied vol, secant on simulation", iv_mc), ("  simulated prices used", evals),
        ("vanilla formula on M1 reads", van_M1), ("  TW log-spread at the TW implied vol", tw(iv_bis)[3]),
        ("vanilla formula on Dec futures reads", van_dec),
        ("sanity: read x sqrt(3); x 1/sqrt(c); c", van_M1 * sqrt(3.0), van_M1 / sqrt(c_week), c_week),
        ("wrong: flat curve at $100, TW implied", bisect(lambda s: tw(s, curve(0.0))[0], Q)),
        ("wrong: fixings independent, implied", bisect(lambda s: black(M1, s * sqrt(sum(ts)) / n), Q)),
        ("wrong: quote 2.40, below the floor", below)]:
    row(label, *vals)
print(f"{'Newton from 30%, vol in % after each step':<44}" + "".join(f"{100 * s:>12.6f}" for s in npath[1:5]))

dec = [11.0 / 12 + (i + 1) / 252.0 for i in range(21)]      # December average: 21 daily fixings
TWd, _, M1d, _ = tw(0.20, tx=dec)
van_d, rule_d = bisect(lambda v: black(M1d, v), TWd), 0.20 * sqrt(11.0 / 12 + 1.0 / 36)
row("Dec-only average: TW at 20%; M1; Dec vanilla", TWd, M1d, black(fw(T), 0.20))
row("  vanilla on its M1 reads; x sqrt(3); rule", van_d, van_d * sqrt(3.0), rule_d)
vols = [0, 5, 10, 15, 20, 25, 30, 35, 40]
curves = [[tw(max(v, 1e-4) / 100)[0] for v in vols], [black(fw(T), max(v, 1e-4) / 100) for v in vols]]
print(f"{'chart, vol %':<28}" + "".join(f"{v:>8d}" for v in vols))
for lab, cv in (("chart, Asian TW price", curves[0]), ("chart, vanilla on Dec price", curves[1])):
    print(f"{lab:<28}" + "".join(f"{p:>8.2f}" for p in cv))

assert abs(iv_bis - iv_new) < 1e-10, "bisection and Newton land on one root"
assert abs(tw(iv_bis)[0] - Q) < 1e-9, "the implied vol reprices the quote"
assert abs(vega20 - (tw(0.200001)[0] - tw(0.199999)[0]) / 2e-6) < 1e-5, "exact vega matches the price's slope"
assert abs(iv_mc - 0.20) < 0.002 and abs(mc20 - Q) < 3 * se20, "the simulation reads back 20% from its own price"
assert 0.0 < iv_mc - iv_bis < 0.003, "TW's small overpricing makes its implied vol slightly low"
assert abs(van_M1 - tw(iv_bis)[3]) < 1e-9, "vanilla on M1 reads exactly TW's fitted log-spread"
assert abs(van_M1 * sqrt(3.0) - iv_mc) < 0.01, "total variance over three: within one vol point"
assert abs(c_week - sum(min(a, b) for a in ts for b in ts) / (n * n * T)) < 1e-12, "c counts the weekly overlap"
assert abs(van_d - rule_d) < 0.001, "the window rule reads the December average"
assert all(a < b for a, b in zip(curves[0], curves[0][1:])) and abs(curves[0][0] - floor) < 1e-9, "rising from the floor"
assert isnan(below) and not isnan(bisect(lambda s: tw(s)[0], floor + 0.01)), "no vol below the floor, one just above"
print("ALL CHECKS PASS")
