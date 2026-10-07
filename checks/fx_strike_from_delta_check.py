# FX strike from delta -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: N(x) is the erf Taylor series written out,
# the quantile is Newton on it, the premium is Simpson's rule over the bell curve.
from math import log, sqrt, exp, pi, factorial

def N(x):                                     # bell-curve area left of x (series good for |x| <= 5)
    if abs(x) > 5.0: return 0.0 if x < 0 else 1.0
    y = x / sqrt(2.0)
    s = sum((-1) ** n * y ** (2 * n + 1) / (factorial(n) * (2 * n + 1)) for n in range(90))
    return 0.5 + s / sqrt(pi)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def N_inv(p):                                 # Newton on N; None when p is outside (0, 1)
    if not 0.0 < p < 1.0: return None
    x = 0.0
    for _ in range(60): x -= (N(x) - p) / phi(x)
    return x

S, rd, rf, T = 1.10, 0.05, 0.03, 1.0          # EURUSD, USD rate, EUR rate, years
F = S * exp((rd - rf) * T)                    # forward
VOL = {"put": 0.1075, "call": 0.0975}         # each 25-delta strike at its own vol
W = {"call": 1.0, "put": -1.0}
CONVS = ("spot", "fwd", "pa spot", "pa fwd")

def delta(K, sg, kind, conv):                 # the forward map: strike in, delta out
    vt, w = sg * sqrt(T), W[kind]
    d1 = (log(F / K) + 0.5 * vt * vt) / vt
    core = w * (K / F) * N(w * (d1 - vt)) if conv.startswith("pa") else w * N(w * d1)
    return core * exp(-rf * T) if conv.endswith("spot") else core

def slope(K, sg, kind, conv):                 # d(delta)/dK for the premium-adjusted deltas
    vt, w = sg * sqrt(T), W[kind]
    d2 = (log(F / K) - 0.5 * vt * vt) / vt
    g = (w * N(w * d2) - phi(d2) / vt) / F
    return g * exp(-rf * T) if conv.endswith("spot") else g

def strike_closed(target, sg, kind, conv):    # Road 1, spot and forward deltas
    z = N_inv(abs(target) * (exp(rf * T) if conv == "spot" else 1.0))
    if z is None: return None
    return F * exp(-W[kind] * z * sg * sqrt(T) + 0.5 * sg * sg * T)

def strike_newton(target, sg, kind, conv, K):  # Road 1, premium-adjusted: Newton from K
    for _ in range(50): K -= (delta(K, sg, kind, conv) - target) / slope(K, sg, kind, conv)
    return K

def bisect(f, lo, hi):                        # Road 2: halve a bracket whose ends differ in sign
    flo = f(lo)
    assert (flo > 0) != (f(hi) > 0), "bracket must straddle the target"
    for _ in range(200):
        mid = sqrt(lo * hi)
        if (f(mid) > 0) == (flo > 0): lo = mid
        else: hi = mid
    return sqrt(lo * hi)

def peak(sg):                                 # pa call delta peaks where vt N(d2) = phi(d2)
    vt = sg * sqrt(T)
    d2 = bisect(lambda x: vt * N(x - 3.0) - phi(x - 3.0), 1.0, 9.0) - 3.0
    return F * exp(-d2 * vt - 0.5 * vt * vt)

def price(s0, K, sg, kind, n=2000):           # Road 3: premium in USD by Simpson
    f0, vt, w = s0 * exp((rd - rf) * T), sg * sqrt(T), W[kind]
    zs = (log(K / f0) + 0.5 * vt * vt) / vt   # where the option starts to pay
    a, b = (zs, zs + 12.0) if kind == "call" else (zs - 12.0, zs)
    g = lambda z: w * (f0 * exp(-0.5 * vt * vt + vt * z) - K) * phi(z)
    h = (b - a) / n
    tot = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return exp(-rd * T) * tot * h / 3.0

def bump(K, sg, kind, conv, h=1e-4):          # delta from its definition, never from N(d1)
    d = (price(S + h, K, sg, kind) - price(S - h, K, sg, kind)) / (2 * h)
    if conv.startswith("pa"): d -= price(S, K, sg, kind) / S       # premium paid in EUR
    return d * exp(rf * T) if conv.endswith("fwd") else d

res = {}
for conv in CONVS:
    for kind in ("put", "call"):
        sg, t = VOL[kind], 0.25 * W[kind]
        f = lambda K: delta(K, sg, kind, conv) - t
        if kind == "call" and conv.startswith("pa"):
            k1 = strike_newton(t, sg, kind, conv, strike_closed(t, sg, kind, conv[3:]))
            k2 = bisect(f, peak(sg), 3.0)     # the right-hand branch
        elif conv.startswith("pa"):
            k1 = strike_newton(t, sg, kind, conv, strike_closed(t, sg, kind, conv[3:]))
            k2 = bisect(f, 0.3, 3.0)
        else:
            k1, k2 = strike_closed(t, sg, kind, conv), bisect(f, 0.3, 3.0)
        res[(conv, kind)] = (k1, k2, bump(k1, sg, kind, conv))
        print(f"{conv + ' ' + kind:<14} road1 {k1:.6f}  road2 {k2:.6f}  bumped delta {res[(conv, kind)][2]:+.6f}")

sc = VOL["call"]
Kpk = peak(sc)
lower = bisect(lambda K: delta(K, sc, "call", "pa spot") - 0.25, 0.05, Kpk)
rows = [
    ("forward F", F), ("drag e^-rf T", exp(-rf * T)), ("spot target N(d1) = 0.25 e^rf T", 0.25 * exp(rf * T)),
    ("d1 at the spot 25-delta call", N_inv(0.25 * exp(rf * T))), ("d1 times vol, spot 25-delta call", N_inv(0.25 * exp(rf * T)) * sc),
    ("half vol^2 T, call", 0.5 * sc * sc),
    ("ln(K/F), spot 25-delta call", log(res[("spot", "call")][0] / F)),
    ("house call K 1.10 vol 10%, Simpson", price(S, 1.10, 0.10, "call")),
    ("house put  K 1.10 vol 10%, Simpson", price(S, 1.10, 0.10, "put")),
    ("house spot delta", delta(1.10, 0.10, "call", "spot")),
    ("pa call peak strike", Kpk), ("pa spot call delta at peak", delta(Kpk, sc, "call", "pa spot")),
    ("pa fwd call delta at peak", delta(Kpk, sc, "call", "pa fwd")),
    ("pa spot 25-delta call, lower root", lower),
    ("wrong: spot formula, no e^rf T", strike_closed(0.25, sc, "call", "fwd")),
    ("wrong: e^rd T in place of e^rf T", F * exp(-N_inv(0.25 * exp(rd * T)) * sc + 0.5 * sc * sc)),
    ("wrong: 10% vol on both, call", strike_closed(0.25, 0.10, "call", "spot")),
    ("wrong: 10% vol on both, put", strike_closed(-0.25, 0.10, "put", "spot")),
]
for name, v in rows: print(f"{name:<36} {v:>12.6f}")
none = strike_closed(0.98, sc, "call", "spot") is None and delta(Kpk, sc, "call", "pa spot") < 0.80
print(f"{'spot 0.98 / pa spot 0.80 call':<36} {'none' if none else 'found':>12}")
for label, sg, tt in (("try: vol 20%", 0.20, 1.0), ("try: 3 months", sc, 0.25), ("try: vol 60%, 5y", 0.60, 5.0)):
    T, F = tt, S * exp((rd - rf) * tt)          # move the clock, and the forward with it
    kp = peak(sg)
    print(f"{label:<17} spot {strike_closed(0.25, sg, 'call', 'spot'):.6f}  pa peak {kp:.6f}"
          f"  peak delta {delta(kp, sg, 'call', 'pa spot'):.6f}")
T, F = 1.0, S * exp((rd - rf) * 1.0)
ks = [0.2 + 0.1 * i for i in range(13)]
print(f"{'chart, strike':<18}" + "".join(f"{k:6.1f}" for k in ks))
print(f"{'chart, spot delta':<18}" + "".join(f"{delta(k, sc, 'call', 'spot'):6.2f}" for k in ks))
print(f"{'chart, pa spot':<18}" + "".join(f"{delta(k, sc, 'call', 'pa spot'):6.2f}" for k in ks))

SPEC = {("spot", "put"): 1.052466, ("spot", "call"): 1.201425, ("fwd", "put"): 1.049780, ("fwd", "call"): 1.204213}
for key, k in SPEC.items(): assert abs(res[key][0] - k) < 5e-7, f"spec: {key}"
for (conv, kind), (k1, k2, bd) in res.items():
    assert abs(k1 - k2) < 1e-8, f"{conv} {kind}: road 1 vs road 2"
    assert abs(bd - 0.25 * W[kind]) < 1e-6, f"{conv} {kind}: bumped delta must be the quote"
assert abs(price(S, 1.10, 0.10, "call") - 0.053556) < 5e-7, "Simpson premium vs the shelf's house call"
assert lower < Kpk < res[("pa spot", "call")][0], "two pa roots either side of the peak"
assert all(delta(Kpk, sc, "call", "pa spot") > delta(Kpk * m, sc, "call", "pa spot") for m in (0.999, 1.001)), "peak is a maximum"
assert none, "deltas above the ceiling or the peak have no strike"
print("ALL CHECKS PASS")
