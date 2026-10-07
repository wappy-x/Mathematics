# Slope fields and the phase line -- the check behind the card.  Nothing is
# imported but math.exp and math.log.  The skydiver: v' = 9.8 - 0.2 v, speed
# v in m/s, time t in s.  Road one reads the equilibrium and its stability off
# the rate alone; road two steps along the slope field; the closed form referees.
from math import exp, log
G, K = 9.8, 0.2

def rate(v, g=G, k=K): return g - k * v                    # the right-hand side

def bisect(f, lo, hi):                                     # root finder, written out
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

def closed(v0, t): return G / K + (v0 - G / K) * exp(-K * t)

def euler(v0, t, h, f=rate):                               # small steps along the slope
    v = v0
    for _ in range(round(t / h)): v += h * f(v)
    return v

def f2(xs): return " ".join(f"{x:.2f}" for x in xs)
star = bisect(rate, 0.0, 100.0)
slope = (rate(star + 1e-3) - rate(star - 1e-3)) / 2e-3     # f' at the rest, by differences
ts = [5, 10, 20]
e90, v, n = G / K * 0.9, 0.0, 0                             # step until 90% of terminal
while v < e90: v, n = v + 0.001 * rate(v), n + 1
err = [euler(0, 10, h) - closed(0, 10) for h in (0.1, 0.05, 0.025)]
cof = lambda T: -0.1 * (T - 20)                             # the shelf's coffee, same test
cstar = bisect(cof, 0.0, 100.0)
chute = 5 + (closed(0, 10) - 5) * exp(-1.96 * 2)            # parachute opens at t = 10 s
wrong = -49 + 49 * exp(0.2 * 5)                             # drag sign flipped, v' = 9.8 + 0.2v
print("rate law v' = 9.8 - 0.2 v; units m/s per s")
print(f"equilibrium by bisection {star:.6f} m/s; g/k = {G / K:.6f} m/s")
print(f"slope of the rate at the rest {slope:.6f} per s -> {'stable' if slope < 0 else 'unstable'}")
arrow = lambda x: "up" if rate(x) > 0 else "down"
print(f"phase line signs: rate at 0 = {rate(0):.2f} ({arrow(0)}), rate at 70 = {rate(70):.2f} ({arrow(70)})")
print("slope field rows v = 5, 15, ..., 75:", f2(rate(v) for v in range(5, 80, 10)))
for v0 in (0, 70):
    print(f"from {v0}, closed form at t = 5, 10, 20 s: {f2(closed(v0, t) for t in ts)}")
    print(f"from {v0}, Euler h = 0.001 at t = 5, 10, 20 s: {f2(euler(v0, t, 0.001) for t in ts)}")
print(f"90% of terminal ({e90:.2f} m/s) at t = {log(10) / K:.2f} s closed, {n * 0.001:.2f} s Euler")
print("Euler error at t = 10 s, h = 0.1, 0.05, 0.025:", " ".join(f"{e:.4f}" for e in err))
print(f"coffee T' = -0.1(T - 20): rest {cstar:.6f} C, slope {(cof(cstar + 1e-3) - cof(cstar - 1e-3)) / 2e-3:.6f} per min")
print(f"mistake 1, chute opens at 10 s: v(12) = {chute:.2f} m/s, not near 49")
print("mistake 2, Euler with h = 10 s from 70:", " ".join(f"{euler(70, 10 * i, 10):.2f}" for i in range(5)))
print(f"mistake 3, drag sign flipped: v(5) = {wrong:.2f} m/s, rest -49 with slope +0.2, unstable")
X = lambda t: 50 + 10 * t; Y = lambda v: 210 - 2 * v        # 10 units per s, 2 per m/s
print(f"figure, rest line y = {Y(star):.1f}; phase dot at (300, {Y(star):.1f})")
for v0 in (0, 70):
    print(f"figure, from {v0}:", " ".join(f"{X(t):.0f},{Y(closed(v0, t)):.1f}" for t in range(0, 21, 2)))
assert abs(star - G / K) < 1e-9                              # the rest, two roads
assert max(abs(euler(v0, t, 0.001) - closed(v0, t)) for v0 in (0, 70) for t in ts) < 0.01
assert 1.9 < err[0] / err[1] < 2.1                          # error halves with h: order one
assert abs(slope + K) < 1e-6 and abs(n * 0.001 - log(10) / K) < 0.01
print("ALL CHECKS PASS")
