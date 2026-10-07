# Caplet stripping -- the check behind the card.  Standard library only.
# Eight flat cap volatilities in, eight caplet volatilities out, by two roads:
# road 1 differences cap prices and inverts Black's formula by bisection;
# road 2 prices every caplet by integrating the payoff over the bell curve and
# solves each whole cap by the secant method.  Nothing imported knows the answer.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)           # bell-curve height
def simpson(f, a, b, n):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def N(x):                                                         # bell-curve area left of x
    x = max(-10.0, min(10.0, x)); return 0.5 + simpson(phi, 0.0, x, 2000)

L, TAU, K = 1_000_000.0, 0.25, 0.05                               # notional, accrual, strike
def D(t): return exp(-(0.04 + 0.005 * t) * t)                     # discount curve
T = [0.25 * (i + 1) for i in range(8)]                            # fixing dates
F = [(D(t) / D(t + TAU) - 1.0) / TAU for t in T]                  # simple forward rates
FLAT = [0.26, 0.28, 0.295, 0.305, 0.308, 0.306, 0.300, 0.294]     # quoted flat cap vols

def black(i, s, k=K):                                             # Black caplet price
    v = s * sqrt(T[i]); d1 = (log(F[i] / k) + 0.5 * v * v) / v
    return L * TAU * D(T[i] + TAU) * (F[i] * N(d1) - k * N(d1 - v))
def by_integral(i, s):                                            # road 2 caplet price
    v = s * sqrt(T[i]); zk = (log(K / F[i]) + 0.5 * v * v) / v    # below zk it pays nothing
    pay = lambda z: (F[i] * exp(-0.5 * v * v + v * z) - K) * phi(z)
    return L * TAU * D(T[i] + TAU) * simpson(pay, max(zk, -10.0), 10.0, 2000)
def floor_(i): return L * TAU * D(T[i] + TAU) * max(F[i] - K, 0.0)  # value at zero vol
def ceil_(i): return L * TAU * D(T[i] + TAU) * F[i]                 # value as vol -> infinity
def bisect(f, lo, hi):
    for _ in range(100):
        m = 0.5 * (lo + hi)
        if f(m) > 0: hi = m
        else: lo = m
    return 0.5 * (lo + hi)

def strip(flat):                                                  # road 1: bootstrap
    caps = [sum(black(i, flat[k]) for i in range(k + 1)) for k in range(8)]
    sig, parts = [], []
    for k in range(8):
        p = caps[k] - (caps[k - 1] if k else 0.0); parts.append(p)
        sig.append(bisect(lambda s: black(k, s) - p, 1e-6, 5.0) if p > floor_(k) else float("nan"))
    return caps, parts, sig

caps, parts, s1 = strip(FLAT)
s2 = []                                                           # road 2: whole cap, secant
for k in range(8):
    target = sum(by_integral(i, FLAT[k]) for i in range(k + 1))
    known = sum(by_integral(i, s2[i]) for i in range(k))
    g = lambda s: known + by_integral(k, s) - target
    a, b = 0.20, 0.40; ga, gb = g(a), g(b)
    while abs(b - a) > 1e-13:
        a, b, ga = b, b - gb * (b - a) / (gb - ga), gb; gb = g(b)
    s2.append(b)

print(" k  fix  pay  D(pay)     F %   flat %   cap price $  caplet $   floor $   ceiling $  road1 %  road2 %")
for k in range(8):
    print(f"{k+1:>2} {T[k]:4.2f} {T[k]+TAU:4.2f} {D(T[k]+TAU):.5f} {100*F[k]:.4f} {100*FLAT[k]:6.2f} "
          f"{caps[k]:12.2f} {parts[k]:9.2f} {floor_(k):9.2f} {ceil_(k):11.2f} {100*s1[k]:8.4f} {100*s2[k]:8.4f}")

scan = [black(7, 0.10 * j) for j in range(1, 7)]                 # uniqueness: price rises with vol
print("caplet 8 price at vol 10..60%: " + " ".join(f"{p:.2f}" for p in scan))
bumped = strip(FLAT[:6] + [0.301] + FLAT[7:])[2]                  # cap 7 quote up 0.1 vol point
print("cap 7 quote +0.10 pt, caplet vol change in pts: " + " ".join(f"{100*(b-a):+.4f}" for a, b in zip(s1, bumped)))
vg = [L * TAU * D(T[i] + TAU) * F[i] * sqrt(T[i]) * phi((log(F[i] / K) + 0.5 * FLAT[6] ** 2 * T[i]) / (FLAT[6] * sqrt(T[i]))) for i in range(7)]
approx = sum(v * s for v, s in zip(vg, s1)) / sum(vg)
print(f"cap 7: vega-weighted caplet vol {100*approx:.4f} % against flat {100*FLAT[6]:.4f} %")

lowest = bisect(lambda s: sum(black(i, s) for i in range(8)) - caps[6] - floor_(7), 0.01, FLAT[7])
low20 = sum(black(i, 0.20) for i in range(8)) - caps[6]
print(f"lowest cap 8 flat vol with a solution {100*lowest:.4f} %")
print(f"cap 8 quoted at 20%: caplet 8 must be worth {low20:.2f}, below its floor {floor_(7):.2f}")
rebuilt = sum(by_integral(i, s1[i]) for i in range(8))           # cap 8 rebuilt, road 2 pricer
print(f"cap 8 rebuilt from the eight caplet vols by integral {rebuilt:.2f}")
print(f"wrong: flat 30% on caplet 7 alone {black(6, 0.30):.2f}, right {parts[6]:.2f}")
print(f"wrong: vols subtracted, 8 x 29.4 - 7 x 30.0 = {100*(8*FLAT[7]-7*FLAT[6]):.4f} %")
print(f"try: all flat 30%, caplet vols {' '.join(f'{100*s:.2f}' for s in strip([0.30]*8)[2])}")
print(f"try: cap 8 at 31%, caplet 8 vol {100*strip(FLAT[:7] + [0.31])[2][7]:.4f} %")
print("chart, flat vol %   " + " ".join(f"{100*s:.2f}" for s in FLAT))
print("chart, caplet vol % " + " ".join(f"{100*s:.2f}" for s in s1))

assert max(abs(a - b) for a, b in zip(s1, s2)) < 1e-7, "two roads give the same eight vols"
assert abs(s1[0] - FLAT[0]) < 1e-9, "a one-caplet cap: its flat vol is its caplet vol"
assert max(abs(b - a) for a, b in zip(s1[:6], bumped[:6])) < 1e-12, "earlier caplets untouched"
assert bumped[6] - s1[6] > 1e-3, "the bumped cap's own caplet moves"
assert all(x < y for x, y in zip(scan, scan[1:])), "caplet price rises with vol: one root at most"
assert low20 < floor_(7), "a 20% quote leaves caplet 8 below its zero-vol floor"
assert abs(rebuilt - caps[7]) < 1e-6, "road 2 pricer rebuilds the quoted cap from road 1 vols"
assert abs(approx - FLAT[6]) < 0.005, "flat vol is close to the vega-weighted caplet vols"
print("ALL CHECKS PASS")
