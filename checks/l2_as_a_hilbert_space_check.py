# L2 as a Hilbert space -- the check behind the card.  Standard library only.
# Turbine A's week of daily mean wind speeds (m/s), Monday to Sunday, is a
# function on 7 days.  Projection three ways: normal equations, cell averages,
# grid search.  The Riesz representer two ways: the rule applied to each day,
# and the proof's direction perpendicular to the rule's kernel.  Fractions keep
# every rational answer exact; floats appear only for square roots.
from fractions import Fraction as Fr

F = [3, 5, 8, 2, 6, 4, 7]
ONE, WKND, DAYS, P = [1] * 7, [0, 0, 0, 0, 0, 1, 1], range(7), Fr(1, 7)  # P: uniform weight per day
CELLS = [[0, 1, 2, 3, 4], [5, 6]]                  # weekdays, weekend

def ip(u, v, w=1):                                 # <u, v> = sum of u times v times each day's weight
    return sum(Fr(a) * b for a, b in zip(u, v)) * w

def sqrt(x):                                       # square root by Newton's method, written out
    x, r = float(x), max(float(x), 1.0)
    for _ in range(60):
        r = (r + x / r) / 2
    return r

show = lambda v: "[" + ", ".join(str(a) for a in v) + "]"

def project(f, basis):                             # road 1: normal equations, Cramer's rule
    G = [[ip(b, c) for c in basis] for b in basis]
    r = [ip(f, b) for b in basis]
    if len(basis) == 1:
        a = [r[0] / G[0][0]]
    else:
        det = G[0][0] * G[1][1] - G[0][1] * G[1][0]
        a = [(r[0] * G[1][1] - G[0][1] * r[1]) / det, (G[0][0] * r[1] - G[1][0] * r[0]) / det]
    return [sum(ak * b[i] for ak, b in zip(a, basis)) for i in DAYS]

def cell_average(f, cells):                        # road 2: average f over each cell
    out = [0] * 7
    for cell in cells:
        for i in cell:
            out[i] = Fr(sum(f[j] for j in cell), len(cell))
    return out

def grid(cells):                                   # road 3: every height 0.0, 0.1, ..., 10.0 per cell
    best = None
    tries = [(k,) for k in range(101)] if len(cells) == 1 else [(k, j) for k in range(101) for j in range(101)]
    for ks in tries:
        s = sum((10 * F[i] - k) ** 2 for k, cell in zip(ks, cells) for i in cell)
        if best is None or s < best[0]:
            best = (s, ks)
    return Fr(best[0], 100), [Fr(k, 10) for k in best[1]]

def dist2(u, v, w=1):
    d = [a - b for a, b in zip(u, v)]
    return ip(d, d, w)

def rule(h):                                       # weekend mean minus weekday mean
    return (h[5] + h[6]) / 2 - (h[0] + h[1] + h[2] + h[3] + h[4]) / 5

unit = lambda i: [Fr(int(j == i)) for j in DAYS]  # the indicator of day i

def riesz_by_kernel(w):                            # road 2: the proof's construction
    phi = [rule(unit(i)) for i in DAYS]
    kernel = [[unit(i)[j] - phi[i] / phi[0] * unit(0)[j] for j in DAYS] for i in range(1, 7)]
    q = []                                         # Gram-Schmidt: an orthogonal basis of the kernel
    for v in kernel:
        for b in q:
            c = ip(v, b, w) / ip(b, b, w)
            v = [x - c * y for x, y in zip(v, b)]
        q.append(v)
    z = unit(0)
    for b in q:                                    # z = e_Mon minus its projection onto the kernel
        c = ip(unit(0), b, w) / ip(b, b, w)
        z = [x - c * y for x, y in zip(z, b)]
    return [rule(z) / ip(z, z, w) * x for x in z]

print(f"wind f = {F} m/s, Mon to Sun; counting measure: <f, f> = {ip(F, F)}, ||f|| = {sqrt(ip(F, F)):.4f}")
c1 = project(F, [ONE])
g1, h1 = grid([list(DAYS)])
r1 = [a - b for a, b in zip(F, c1)]
print(f"constants, normal equations: c = <f, 1>/<1, 1> = {ip(F, ONE)}/{ip(ONE, ONE)} = {c1[0]}")
print(f"constants, grid search: best c = {h1[0]}, least squared distance {g1}")
print(f"residual f - 5 = {show(r1)}; <residual, 1> = {ip(r1, ONE)}")
print(f"residual norm sqrt({dist2(F, c1)}) = {sqrt(dist2(F, c1)):.4f}; Pythagoras {ip(c1, c1)} + {dist2(F, c1)} = {ip(c1, c1) + dist2(F, c1)}")
print(f"constant 4 instead: squared distance {dist2(F, [4] * 7)} = 28 + 7 x 1^2, distance {sqrt(dist2(F, [4] * 7)):.4f}")
s1 = project(F, [ONE, WKND])
s2 = cell_average(F, CELLS)
g2, h2 = grid(CELLS)
r2 = [a - b for a, b in zip(F, s1)]
print(f"steps, normal equations on 1 and the weekend indicator: {show(s1)}")
print(f"steps, cell averages: weekday {s2[0]} = {float(s2[0]):.2f}, weekend {s2[6]} = {float(s2[6]):.2f}")
print(f"steps, grid search: best heights {h2[0]} and {h2[1]}, least squared distance {g2}")
print(f"residual = {show(r2)}; <residual, 1> = {ip(r2, ONE)}, <residual, weekend> = {ip(r2, WKND)}")
print(f"residual norm sqrt({dist2(F, s1)}) = {sqrt(dist2(F, s1)):.4f}; Pythagoras {ip(s1, s1)} + {dist2(F, s1)} = {ip(s1, s1) + dist2(F, s1)}")
print(f"nested: ||steps - constants||^2 = {dist2(s1, c1)} = 28 - 273/10")
print(f"uniform probability 1/7: residual norms {sqrt(dist2(F, c1, P)):.4f} (constants), {sqrt(dist2(F, s1, P)):.4f} (steps)")
print(f"chart, bars {F}, constants line {float(c1[0]):.2f}, steps line {float(s2[0]):.2f} weekdays, {float(s2[6]):.2f} weekend")
print(f"figure, 16 px per m/s: O (40, 200), foot at c = 5 ({40 + 16 * 5 * sqrt(7):.2f}, 200), "
      f"tip ({40 + 16 * 5 * sqrt(7):.2f}, {200 - 16 * sqrt(28):.2f}), c = 4 at ({40 + 16 * 4 * sqrt(7):.2f}, 200)")
g_day = [rule(unit(i)) for i in DAYS]              # road 1: the rule applied to each day's indicator
g_ker = riesz_by_kernel(1)
print(f"rule(f) = weekend mean - weekday mean = {rule([Fr(a) for a in F])}")
print(f"Riesz, rule on each day: g = {show(g_day)}")
print(f"Riesz, perpendicular to the kernel: g = {show(g_ker)}")
print(f"<f, g> = {ip(F, g_ker)}; ||g||^2 = {ip(g_ker, g_ker)}, ||g|| = {sqrt(ip(g_ker, g_ker)):.4f}")
gP = riesz_by_kernel(P)
print(f"uniform probability: g = {show(gP)}; <f, g>_P = {ip(F, gP, P)}")
M64, seed, top = (1 << 64) - 1, 20260929, 0.0
for _ in range(2000):                              # SplitMix64 search for the rule's size
    h = []
    for _ in DAYS:
        seed = (seed + 0x9E3779B97F4A7C15) & M64
        z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        h.append(((z ^ (z >> 31)) >> 11) * 2.0 ** -53 * 2 - 1)
    top = max(top, abs(rule(h)) / sqrt(sum(x * x for x in h)))
at_g = float(rule(g_ker)) / sqrt(ip(g_ker, g_ker))
print(f"2000 random weeks, seed 20260929: largest |rule(h)|/||h|| = {top:.4f}; at h = g: {at_g:.4f}")
print("breaks 1, not closed: continuous ramps against the calm-to-wind step on [0, 1], Lebesgue measure")
rs = {n: sum((1.0 - min(max(((j + 0.5) / K - 0.5) * n, 0.0), 1.0)) ** 2 for j in range(K // 2, K)) / K
      for n, K in ((2, 100000), (10, 100000), (100, 100000), (1000, 100000))}   # squared distance per ramp
for n, s in rs.items():
    print(f"  ramp width 1/{n}: distance by midpoint sums {sqrt(s):.4f}, by formula sqrt(1/(3n)) {sqrt(1 / (3 * n)):.4f}")
l1 = [abs(4 - c) + abs(7 - c) for c in (4, 5, 5.5, 6, 7)]
l2 = [sqrt((4 - c) ** 2 + (7 - c) ** 2) for c in (4, 5, 5.5, 6, 7)]
print(f"breaks 2, L1: weekend readings 4 and 7, constants 4, 5, 5.5, 6, 7 at distance {', '.join(f'{x:g}' for x in l1)}")
print(f"  L2 distances {', '.join(f'{x:.4f}' for x in l2)}: one closest constant, 5.5")
par = {p: sum(float(sum(abs(a + sg * b) ** p for a, b in zip(unit(0), unit(1)))) ** (2 / p) for sg in (1, -1)) for p in (1, 2, 3)}
for p, lhs in par.items():                         # squared p-sizes of Mon + Tue and Mon - Tue, added
    print(f"  parallelogram, Mon and Tue indicators, p = {p}: {lhs:.4f} against 4")
print(f"breaks 3, counting-measure g used under 1/7: <f, g>_P = {ip(F, g_ker, P)}, not 7/10")
wrong = [a + b for a, b in zip(c1, project(F, [WKND]))]
print(f"breaks 4, separate projections added: {show(wrong)}, distance {sqrt(dist2(F, wrong)):.4f}")
assert s1 == s2 and h2 == [s2[0], s2[6]] and g2 == dist2(F, s1)   # three roads, one projection
assert h1 == [c1[0]] and g1 == 28 and ip(r2, ONE) == 0 == ip(r2, WKND)
assert ip(s1, s1) + dist2(F, s1) == sum(x * x for x in F)          # Pythagoras against the raw sum
assert g_day == g_ker and ip(F, g_ker) == rule([Fr(a) for a in F])  # two roads to the representer
assert gP == [7 * x for x in g_day] and ip(F, gP, P) == Fr(7, 10)
assert top <= at_g + 1e-12 and abs(at_g - sqrt(Fr(7, 10))) < 1e-12
assert set(l1) == {3} and min(l2) == l2[2] < l2[1] and ip(F, g_ker, P) == Fr(1, 10) and dist2(F, wrong) > 28  # breaks
assert all(abs(sqrt(s) - sqrt(1 / (3 * n))) < 1e-6 for n, s in rs.items())        # breaks 1: two roads to each ramp
assert all(abs(x - 2 * 2 ** (2 / p)) < 1e-12 for p, x in par.items()) and wrong == [5] * 5 + [Fr(21, 2)] * 2  # breaks 2 and 4
print("ALL CHECKS PASS")
