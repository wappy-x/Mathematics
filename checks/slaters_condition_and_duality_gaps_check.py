# Slater's condition and duality gaps -- the check behind the card.  Standard library only.
# Minimise pump power (kW) so three mains deliver at least D litres a second (L/s).
from fractions import Fraction as Fr
from itertools import product
from math import sqrt

MAINS = [("A", 60, 45), ("B", 50, 55), ("C", 45, 60)]   # name, flow when open (L/s), power (kW)

def valves():                            # every open/shut pattern: (name, flow, power)
    out = []
    for x in product((0, 1), repeat=3):
        name = "".join(m[0] for m, xi in zip(MAINS, x) if xi) or "none"
        out.append((name, sum(m[1] * xi for m, xi in zip(MAINS, x)), sum(m[2] * xi for m, xi in zip(MAINS, x))))
    return out

def q(lam, D):                           # dual function: price lam (kW per L/s) on the shortfall D - flow
    return lam * D + sum(min(0, c - lam * a) for _, a, c in MAINS)

def solve_valves(D):
    pats = valves()
    best = min((p for p in pats if p[1] >= D), key=lambda p: p[2])          # road 1: every pattern
    lam = max([Fr(0)] + [Fr(c, a) for _, a, c in MAINS], key=lambda l: q(l, D))   # road 2: q's corners
    left, lp, x = Fr(D), Fr(0), {}       # road 3: valves part-open, an LP: cheapest kW per L/s first
    for n, a, c in sorted(MAINS, key=lambda m: Fr(m[2], m[1])):
        x[n] = min(Fr(1), left / a); lp += x[n] * c; left -= x[n] * a
    pts = [(D - f, Fr(c)) for _, f, c in pats]                              # road 4: the picture's hull
    hull = min([c for u, c in pts if u <= 0] + [c1 + (c2 - c1) * u1 / (u1 - u2)
               for (u1, c1), (u2, c2) in product(pts, pts) if u1 < 0 < u2])
    return pats, best, lam, q(lam, D), lp, x, hull

D = 100
pats, best, lam, d, lp, x, hull = solve_valves(D)
for n, f, c in pats:
    print(f"valves {n:<4} flow {f:3d} L/s  shortfall {D - f:4d}  power {c:3d} kW  {'meets demand' if f >= D else '-'}")
print(f"road 1, every pattern: best {best[0]}, {best[1]} L/s, p* = {best[2]} kW")
print(f"road 2, corners of q: price {float(lam):.4f} kW per L/s, d* = {float(d):.4f} kW")
srt = sorted(MAINS, key=lambda m: Fr(m[2], m[1]))   # q's corners, cheapest kW per L/s first; q's slope is D - flow open
print("  corners c/a:", " ".join(f"{n} {float(Fr(c, a)):.4f}" for n, a, c in srt) + "; slope of q before, between, after:",
      " ".join(str(D - sum(m[1] for m in srt[:i])) for i in range(4)))
print(f"  by hand at that price: credit {float(lam * D):.1f}, c - price a:", " ".join(f"{n} {float(c - lam * a):.1f}" for n, a, c in MAINS))
print(f"road 3, part-open LP: {float(lp):.4f} kW with A {float(x['A']):.2f} B {float(x['B']):.2f} C {float(x['C']):.2f}")
print(f"road 4, lower hull at shortfall 0: {float(hull):.4f} kW")
print(f"duality gap {float(best[2] - d):.4f} kW = {100 * float((best[2] - d) / best[2]):.1f}% of p*")
allopen = [f for n, f, c in pats if n == "ABC"][0]   # Slater test on the valves: strict point, then convexity
P = list(product((0, 1), repeat=3))                 # a convex set holds the midpoint of any two of its points
conv = all((u + v) % 2 == 0 for s in P for t in P for u, v in zip(s, t))
print(f"Slater, valves: all open shortfall {D - allopen}; midpoint of every two patterns a pattern: {'yes' if conv else 'no'}")
xs = [Fr(9, 10)] * 3                     # Slater test on the part-open LP
print(f"Slater, part-open: x = 0.9 each, shortfall {float(D - sum(v * a for v, (_, a, _) in zip(xs, MAINS))):.1f}, inside 0 < x < 1")
print("chart, q at price 0 to 2 by 0.25:", " ".join(f"{float(q(Fr(i, 4), D)):.2f}" for i in range(9)))
print("figure, (shortfall, kW):", " ".join(f"{n} {D - f} {c}" for n, f, c in pats), f"hull at 0: {float(hull):.0f}")

# --- variable-speed pumps: convex.  Power c (f/a)^3 kW at flow f, 0 <= f <= a.  Dual ascent, gap as stop.
def flows(lam): return [min(a, a * sqrt(lam * a / (3 * c))) for _, a, c in MAINS]   # 3c f^2 / a^3 = lam
def power(f): return sum(c * (fi / a) ** 3 for (_, a, c), fi in zip(MAINS, f))
def qc(lam): f = flows(lam); return lam * D + power(f) - lam * sum(f)
def ascent(step, tol, lam=0.5, kmax=200):
    rows = []
    for k in range(kmax):
        f = flows(lam); s = sum(f)
        plan = [fi * D / s for fi in f]   # scaled to meet demand exactly: a feasible plan, an upper bound
        assert all(p <= a for p, (_, a, _) in zip(plan, MAINS))
        rows.append((k, lam, s, qc(lam), power(plan), power(plan) - qc(lam)))
        if rows[-1][5] <= tol: break
        lam = max(0.0, lam + step * (D - s))
    return rows
fs = [50, 40, 35]                        # Slater test on the variable-speed pumps
print(f"Slater, variable-speed: flows 50 40 35 give shortfall {D - sum(fs)}, strictly inside 0 < w < a: {'yes' if all(0 < f < a for f, (_, a, _) in zip(fs, MAINS)) else 'no'}")
rows = ascent(0.01, 0.01)
for k, l, s, lo, up, g in rows:
    ratio = f"{g / rows[k - 1][5]:.3f}" if k else "-"
    print(f"k={k} price {l:.6f} flow {s:7.4f} lower {lo:.6f} upper {up:.6f} gap {g:.6f} ratio {ratio}")
per = [a * sqrt(a / (3 * c)) for _, a, c in MAINS]                       # road 2: KKT in closed form
print("KKT: flow per root-price, a sqrt(a / 3c):", " ".join(f"{v:.4f}" for v in per), f"sum {sum(per):.4f}")
lam_star = (D / sum(per)) ** 2
f_star = flows(lam_star)
print(f"KKT: price {lam_star:.6f}, flows " + " ".join(f"{v:.4f}" for v in f_star), f"power {power(f_star):.6f} kW")
print(f"predicted gap ratio (1 - 0.01 D / (2 price))^2 = {(1 - 0.01 * D / (2 * lam_star)) ** 2:.3f}; steps below "
      f"4 price / D = {4 * lam_star / D:.4f} settle; factor at step 0.06: {1 - 0.06 * D / (2 * lam_star):.2f}")
def tern(g, lo, hi):
    for _ in range(100):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, m2) if g(m1) <= g(m2) else (m1, hi)
    return (lo + hi) / 2
inner = lambda fa: tern(lambda fb: power([fa, fb, D - fa - fb]), max(0, D - fa - 45), min(50, D - fa))
fa = tern(lambda fa: power([fa, inner(fa), D - fa - inner(fa)]), 10, 60)
brute = power([fa, inner(fa), D - fa - inner(fa)])
print(f"road 3, search over flows: {brute:.6f} kW")

# --- what breaks
def sq(lam):                             # dual of: minimise 0.75 w kW subject to (w - 40)^2 <= 0
    g = lambda w: 0.75 * w + lam * (w - 40) ** 2
    return g(tern(g, 0, 80))
print(f"no strict point, (w-40)^2 <= 0: p* = 30 kW; p* - q at price 1: {30 - sq(1.0):.6f}; at 14.0625: "
      f"{30 - sq(14.0625):.6f}; at 1e6: {30 - sq(1e6):.9f}")
lam_v, top = 0.0, -1000.0                # subgradient ascent on the valve dual, same stopping test
for k in range(200):
    top = max(top, q(lam_v, D))
    if best[2] - top <= 0.01: break
    lam_v = max(0.0, lam_v + 0.05 / (k + 1) * (D - sum(a for _, a, c in MAINS if c < lam_v * a)))
print(f"valve dual ascent, 200 steps: best bound {float(top):.4f}, gap {float(best[2] - top):.4f}: test never met")
for Dt in (110, 90):
    _, b2, _, d2, _, _, _ = solve_valves(Dt)
    print(f"try: demand {Dt}: p* {b2[2]} kW, d* {float(d2):.4f} kW, gap {100 * float((b2[2] - d2) / b2[2]):.1f}%")
print(f"try: tolerance 1e-6: {len(ascent(0.01, 1e-6))} rows; step 0.03: {len(ascent(0.03, 0.01))} rows; step 0.06: {len(ascent(0.06, 0.01))} rows, cap 200")

assert best[2] == 100 and d == 89 and lam == Fr(11, 10)         # enumeration and dual corners
assert lp == d and hull == d                                    # LP and hull meet the dual: d* = 89
assert all(q(Fr(i, 100), D) <= d for i in range(301))           # no price beats 89 on a fine grid
assert abs(rows[-1][3] - power(f_star)) < 0.01 and abs(brute - power(f_star)) < 1e-6
assert abs(rows[-1][1] - lam_star) < 0.02 and rows[-1][5] <= 0.01
assert abs((30 - sq(1.0)) - 0.140625) < 1e-6 and best[2] - top > 10
assert abs((30 - sq(1e6)) - 0.140625 / 1e6) < 1e-12              # d* = 30 = p*, approached but never reached
print("ALL CHECKS PASS")
