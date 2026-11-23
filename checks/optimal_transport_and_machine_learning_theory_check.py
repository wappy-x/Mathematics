# Optimal transport check: a sand pile moved into a trench, W1 and W2 by four roads,
# Monge's problem failing on a split, and the VC bound for a network that fits any labels.
# Standard library only: the integrals, the brute force and the bound are written out.
import math
from fractions import Fraction as Fr
from itertools import permutations

# Pile: triangle cross-section on [0, 2] m, peak 1 m high at x = 1. Trench: [3, 4] m, 1 m deep.
# Each holds 1 m^2 of cross-section, so 1 m^3 of sand per metre of trench. Shares sum to 1.
def F(x):  # share of the pile's sand to the left of x
    if x <= 0: return 0.0
    if x <= 1: return x * x / 2
    if x <= 2: return 1 - (2 - x) * (2 - x) / 2
    return 1.0
def G(y): return min(1.0, max(0.0, y - 3))  # share of the trench's room to the left of y
def Finv(u): return math.sqrt(2 * u) if u <= 0.5 else 2 - math.sqrt(2 * (1 - u))
def Ginv(u): return 3 + u
def pile(x): return 1 - abs(x - 1) if 0 <= x <= 2 else 0.0  # the roof's height in m: its density
N = 200000
us = [(k + 0.5) / N for k in range(N)]

# ---- road 1: exact fractions. Integrate polynomials piece by piece.
def integ(c, a, b):  # integral of sum c[k] x^k from a to b
    return sum(ck * (Fr(b) ** (k + 1) - Fr(a) ** (k + 1)) / (k + 1) for k, ck in enumerate(c))
h = Fr(1, 2)
mX = integ([0, 0, 1], 0, 1) + integ([0, 2, -1], 1, 2)                  # E[X] = 1
mX2 = integ([0, 0, 0, 1], 0, 1) + integ([0, 0, 2, -1], 1, 2)           # E[X^2] = 7/6
mXF = integ([0, 0, 0, 0, h], 0, 1) + integ([0, 2, -1, -1, h], 0, 1)    # E[X F(X)], by w = 2 - x
mY, mY2 = Fr(7, 2), Fr(37, 3)                                           # trench: uniform on [3, 4]
w1x = mY - mX                                                           # every grain moves right
w2x = mX2 + mY2 - 2 * (3 * mX + mXF)                                    # monotone plan: Y = 3 + F(X)
anti = mX2 + mY2 - 2 * (4 * mX - mXF)                                   # reversed plan: Y = 4 - F(X)
indep = mX2 + mY2 - 2 * mX * mY                                         # independent plan
print(f"exact: E[X] = {mX}, E[X^2] = {mX2}, E[X F(X)] = {mXF}, trench E[Y] = {mY}, E[Y^2] = {mY2}")
print(f"exact pieces: E[X^2] = {integ([0, 0, 0, 1], 0, 1)} + {integ([0, 0, 2, -1], 1, 2)},"
      f" E[X F(X)] = {integ([0, 0, 0, 0, h], 0, 1)} + {integ([0, 2, -1, -1, h], 0, 1)}")
print(f"exact: E[XY] in the monotone plan = 3 E[X] + E[X F(X)] = {3 * mX + mXF}")
print(f"exact: W1 = {w1x} m, W2^2 = {w2x} m^2 = (5/2)^2 + {w2x - w1x ** 2}")
assert mX == 1 and mX2 == Fr(7, 6) and w1x == Fr(5, 2) and w2x == Fr(94, 15)

# ---- road 2: quantile integral, matching equal shares of sand and room in order
q1 = sum(abs(Finv(u) - Ginv(u)) for u in us) / N
q2 = sum((Finv(u) - Ginv(u)) ** 2 for u in us) / N
qa = sum((Finv(u) - Ginv(1 - u)) ** 2 for u in us) / N
print(f"quantile road: W1 = {q1:.6f} m, W2^2 = {q2:.6f} m^2, W2 = {math.sqrt(q2):.6f} m")
assert abs(q1 - float(w1x)) < 1e-6 and abs(q2 - float(w2x)) < 1e-6 and abs(qa - float(anti)) < 1e-6

# ---- road 3: area between the two cumulative curves, x from 0 to 4 m
M = 400000
cdf = sum(abs(F(4 * (k + 0.5) / M) - G(4 * (k + 0.5) / M)) for k in range(M)) * 4 / M
print(f"area road: W1 = {cdf:.6f} m")
assert abs(cdf - float(w1x)) < 1e-6

# ---- the dual price f(x) = x: value of the trench's sand minus the pile's, a floor under every plan
K = 4000  # midpoint sums over the two densities, not the moments of road 1
floor = sum(3 + (k + 0.5) / K for k in range(K)) / K - sum(2 * (k + 0.5) / K * pile(2 * (k + 0.5) / K) for k in range(K)) * 2 / K
print(f"dual road: price f(x) = x gives floor {floor:.6f} m; the monotone plan costs {q1:.6f} m")
assert abs(floor - q1) < 1e-6

# ---- road 4: brute force over every plan for 6 equal barrow loads (720 one-to-one plans)
n = 6
xs = [Finv((k + 0.5) / n) for k in range(n)]
ys = [Ginv((k + 0.5) / n) for k in range(n)]
c1 = [sum(abs(xs[i] - ys[s[i]]) for i in range(n)) / n for s in permutations(range(n))]
c2 = [sum((xs[i] - ys[s[i]]) ** 2 for i in range(n)) / n for s in permutations(range(n))]
best = min(c2); arg = [s for s, c in zip(permutations(range(n)), c2) if c - best < 1e-12]
ties = sum(1 for c in c1 if abs(c - min(c1)) < 1e-12)
print("loads at x =", " ".join(f"{x:.4f}" for x in xs), "m")
print(f"brute force, {len(c1)} plans: W1 cost {min(c1):.6f} m, tied by {ties} plans; worst {max(c1):.6f}")
print(f"brute force: best W2^2 {best:.6f}, {len(arg)} best plan(s), in order: {arg[0] == tuple(range(n))}; reversed {c2[-1]:.6f}")
assert ties == 720 and len(arg) == 1 and arg[0] == tuple(range(n)) and abs(min(c1) - 2.5) < 1e-12
assert c2.index(max(c2)) == len(c2) - 1  # the last plan, (5, 4, 3, 2, 1, 0), fully reversed, is the worst
for n2 in (60, 600):
    d2 = sum((Finv((k + 0.5) / n2) - Ginv((k + 0.5) / n2)) ** 2 for k in range(n2)) / n2
    print(f"{n2} loads in order: W2^2 {d2:.6f}")

# ---- Monge's map T(x) = G^-1(F(x)) = 3 + F(x), and where each slice of sand goes
for x in (0.0, 0.5, 1.0, 1.5, 2.0):
    print(f"Monge map: sand at {x:.2f} m goes to {3 + F(x):.4f} m, carried {3 + F(x) - x:.4f} m")
fig = [(x, 3 + F(x)) for x in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75)]
print("figure, arrows", " ".join(f"{a:.2f}>{b:.4f}" for a, b in fig))

# ---- what breaks
print(f"reversed plan (near sand to near end): W1 {float(w1x):.6f}, W2 {math.sqrt(anti):.6f} (exact W2^2 {anti})")
print(f"independent plan (each grain spread over the trench): W2 {math.sqrt(indep):.6f} (exact W2^2 {indep})")
dbl = sum((x - y) ** 2 * pile(x) for x in (2 * (i + 0.5) / 1000 for i in range(1000)) for y in (3 + (j + 0.5) / 500 for j in range(500)))
assert abs(dbl * (2 / 1000) * (1 / 500) - float(indep)) < 1e-5  # double integral over the densities
mass = integ([0, 1], 0, 1) + integ([2, -1], 1, 2)  # the pile's area, exact: 1
for far in (3, 100):  # height-by-height comparison: the shares that do not overlap
    tv = sum(abs(pile(x) - (1 if far <= x <= far + 1 else 0))
             for x in (k * 0.001 + 0.0005 for k in range((far + 2) * 1000))) * 0.001 / 2
    print(f"trench at {far} m: height difference {tv:.6f}, W1 {far + 0.5 - 1:.6f} m")
    assert abs(tv - float(mass + 1) / 2) < 1e-9  # no overlap, so half of (pile's mass + trench's mass)
src, dst = [(0.0, 1.0)], [(-1.0, 0.5), (1.0, 0.5)]  # one heap, two half-holes
maps_ok = sum(1 for t in range(2) if all(abs(m - (1.0 if j == t else 0.0)) < 1e-12 for j, (_, m) in enumerate(dst)))
split = sum(m * abs(y - src[0][0]) for y, m in dst)
print(f"split: maps that fill both holes {maps_ok} of 2; Kantorovich plan half each, cost {split:.6f} m")
assert abs(math.sqrt(anti) - math.sqrt(qa)) < 1e-6

# ---- the VC bound from the PAC card: smallest m with 2 (2em/d)^d 2^(-eps m/2) <= delta
EPS, DELTA = 0.05, 0.01
def log2_bound(m, d): return 1 + d * math.log2(2 * math.e * m / d) - EPS * m / 2
def vc_m(d):
    lo = max(math.ceil(8 / EPS), d); hi = lo
    while log2_bound(hi, d) > math.log2(DELTA): hi *= 2
    while lo < hi:
        mid = (lo + hi) // 2
        if log2_bound(mid, d) > math.log2(DELTA): lo = mid + 1
        else: hi = mid
    return lo
m1, mbig = vc_m(1), vc_m(50000)
print(f"VC bound, d = 1 (PAC card's caps): {m1} sales")
print(f"VC bound, d = 50000 (network fitting any labels of 50000 photos): {mbig} photos")
print(f"bound at m = 50000, d = 50000: log10 = {log2_bound(50000, 50000) * math.log10(2):.1f}")
assert m1 == 789 and mbig > 400 * 50000 and log2_bound(50000, 50000) > 0

# ---- try changing: a far trench, the power p = 3, a smaller network
far1 = sum(abs(Finv(u) - Ginv(u) - 7) for u in us) / N
far2 = sum((Finv(u) - Ginv(u) - 7) * (Finv(u) - Ginv(u) - 7) for u in us) / N
w3 = sum(abs(Finv(u) - Ginv(u)) * (Finv(u) - Ginv(u)) * (Finv(u) - Ginv(u)) for u in us) / N
print(f"try: trench at [10, 11] m: W1 {far1:.6f} m, W2 {math.sqrt(far2):.6f} m; p = 3: W3 {w3 ** (1 / 3):.6f} m")
print(f"try: VC bound, d = 1000: {vc_m(1000)} photos")
assert abs(far2 - (9.5 ** 2 + 1 / 60)) < 1e-6

# ---- chart: the two cumulative curves, x = 0 to 4 m in 0.25 m steps
print("chart, x", " ".join(f"{k / 4:.2f}" for k in range(17)))
print("chart, F", " ".join(f"{F(k / 4):.3f}" for k in range(17)))
print("chart, G", " ".join(f"{G(k / 4):.3f}" for k in range(17)))
print("ALL CHECKS PASS")
