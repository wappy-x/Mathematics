# The ellipsoid method -- the check behind the card.  Standard library only.
# Question: is there a workshop plan earning at least T pounds?  Each limit is relaxed
# by EPS so a plan, if one exists, leaves room of area at least (2 EPS/39)^2.
# Roads to the answer: central-cut ellipsoid steps plus bisection on T; every corner
# of the region listed in exact fractions; the prices y = (3, 0, 7) as a dual bound.
import math
from fractions import Fraction as F

G = [[4, 2], [3, 1], [1, 2], [-1, 0], [0, -1], [-19, -20]]   # rows a_i: a_i x <= h_i
H = [160, 120, 64, 0, 0]                                       # the sixth limit is -T
NAMES = ["timber", "labour", "finish", "tables>=0", "chairs>=0", "profit"]
EPS = 0.05
RATIO = (2 / 3) * math.sqrt(4 / 3)          # area factor per central cut, n = 2
S, BETA = math.sqrt(4 / 3), 1 - math.sqrt(1 / 3)

def step_L(c, L, a):     # one central cut, with P = L L^T kept as its factor L
    w = [L[0][0] * a[0] + L[1][0] * a[1], L[0][1] * a[0] + L[1][1] * a[1]]
    q = math.sqrt(w[0] * w[0] + w[1] * w[1]); u = [w[0] / q, w[1] / q]          # q = sqrt(a^T P a)
    b = [L[0][0] * u[0] + L[0][1] * u[1], L[1][0] * u[0] + L[1][1] * u[1]]  # b = P a / q
    c = [c[0] - b[0] / 3, c[1] - b[1] / 3]
    return c, [[S * (L[i][j] - BETA * b[i] * u[j]) for j in range(2)] for i in range(2)]

def step_P(c, P, a, sym=False):     # the same cut written on P itself, as in The formula
    Pa = [P[0][0] * a[0] + P[0][1] * a[1], P[1][0] * a[0] + P[1][1] * a[1]]
    q2 = a[0] * Pa[0] + a[1] * Pa[1]
    if q2 <= 0: return None, None, q2, None
    b = [Pa[0] / math.sqrt(q2), Pa[1] / math.sqrt(q2)]
    e = lambda i, j: 4 / 3 * (P[i][j] - 2 / 3 * b[i] * b[j])    # sym: the off-diagonal is worked out once
    return [c[0] - b[0] / 3, c[1] - b[1] / 3], [[e(min(i, j), max(i, j)) if sym else e(i, j) for j in range(2)] for i in range(2)], q2, b

def PofL(L): return [[sum(L[i][k] * L[j][k] for k in range(2)) for j in range(2)] for i in range(2)]

def decide(T, eps=EPS, rad=100.0, vmin=None, hist=None, side=1):
    h = H + [-T]; c = [0.0, 0.0]; L = [[rad, 0.0], [0.0, rad]]
    vmin = (2 * eps / 39) ** 2 if vmin is None else vmin
    k = 0
    while True:
        area = math.pi * abs(L[0][0] * L[1][1] - L[0][1] * L[1][0])
        cut = next((i for i in range(6) if G[i][0] * c[0] + G[i][1] * c[1] > h[i] + eps), None)
        if hist is not None: hist.append((k, c, L, area, cut))
        if cut is None: return True, k, c
        if area < vmin: return False, k, c
        c, L = step_L(c, L, [side * G[cut][0], side * G[cut][1]]); k += 1

def bisect(eps=EPS, vmin=None, log=None):
    lo, hi = 0, 2759             # the disc's best profit is 100 sqrt(761) = 2758.6
    while hi - lo > 1:
        m = (lo + hi) // 2; ok, k, c = decide(m, eps, vmin=vmin)
        if log is not None: log.append((m, ok, k, c))
        lo, hi = (m, hi) if ok else (lo, m)
    return lo

def inside(v, c, P):     # (v - c)^T P^-1 (v - c): at most 1 means inside the ellipse
    d = P[0][0] * P[1][1] - P[0][1] * P[1][0]; x, y = v[0] - c[0], v[1] - c[1]
    return (P[1][1] * x * x - 2 * P[0][1] * x * y + P[0][0] * y * y) / d

def corners(h):          # every crossing of two limit lines that keeps all limits, exact
    out = set()
    for p in range(len(h)):
        for q in range(p + 1, len(h)):
            det = G[p][0] * G[q][1] - G[p][1] * G[q][0]
            if det:
                v = (F(h[p] * G[q][1] - G[p][1] * h[q], det), F(G[p][0] * h[q] - h[p] * G[q][0], det))
                if all(G[i][0] * v[0] + G[i][1] * v[1] <= h[i] for i in range(len(h))): out.add(v)
    m = [sum(float(v[i]) for v in out) / len(out) for i in (0, 1)]
    pts = sorted(out, key=lambda v: math.atan2(float(v[1]) - m[1], float(v[0]) - m[0]))
    return pts, abs(sum(pts[i][0] * pts[i - 1][1] - pts[i - 1][0] * pts[i][1] for i in range(len(pts)))) / 2

def f4(v): return f"{v:.4f}"
def real(T, c): return all(G[i][0] * c[0] + G[i][1] * c[1] <= (H + [-T])[i] for i in range(6)), c[0] + 2 * c[1]  # unloosened limits kept? finish used
print("maximise 19 x1 + 20 x2 pounds: timber 4,2 <= 160 m; labour 3,1 <= 120 h; finish 1,2 <= 64 l; limits relaxed by 0.05")
c1, P1, q2, b = step_P([0.0, 0.0], [[1e4, 0.0], [0.0, 1e4]], G[5])
print(f"step 0, T = 900: a = (-19, -20), a^T P a = {f4(q2)}, root {f4(math.sqrt(q2))}, d = ({f4(b[0])}, {f4(b[1])})")
r0 = math.sqrt(P1[0][0] * P1[1][1] - P1[0][1] * P1[1][0]) / 1e4     # area ratio from det P, no L
print(f"centre 1 = ({f4(c1[0])}, {f4(c1[1])}); P1 rows {f4(P1[0][0])}, {f4(P1[0][1])}; {f4(P1[1][0])}, {f4(P1[1][1])}; area ratio {r0:.6f}")
hist = []; found = decide(900, hist=hist)
print(" k       x1       x2        area  cut by")
for (k, c, L, area, cut) in hist:
    print(f"{k:2d} {c[0]:8.4f} {c[1]:8.4f} {area:11.4f}  {NAMES[cut] if cut is not None else 'fits: a plan'}")
c = hist[-1][1]; r900 = real(900, c)
print(f"plan found: ({f4(c[0])}, {f4(c[1])}) earns {f4(19 * c[0] + 20 * c[1])}; real limits kept: {'yes' if r900[0] else 'no'}, finish {f4(r900[1])} l")
print("chart log10 area: " + ", ".join(f"{math.log10(h[3]):.2f}" for h in hist))
ratios = [hist[k + 1][3] / hist[k][3] for k in range(len(hist) - 1)]
Q900, aQ = corners([160 + F(1, 20), 120 + F(1, 20), 64 + F(1, 20), F(1, 20), F(1, 20), -900 + F(1, 20)])
worst = max(inside(v, h[1], PofL(h[2])) for h in hist for v in Q900)
print(f"area ratio each step: min {min(ratios):.6f}, max {max(ratios):.6f}; formula (2/3) sqrt(4/3) = {RATIO:.6f}")
print(f"relaxed region for 900: {len(Q900)} corners, area {f4(float(aQ))}; worst corner score over all 22 ellipses {f4(worst)}")
R0, _ = corners(H); P900, a9 = corners(H + [-900])
print("corners: " + "; ".join(f"({v[0]}, {v[1]}) {19 * v[0] + 20 * v[1]}" for v in sorted(R0)))
print("plans earning >= 900: corners " + ", ".join(f"({v[0]}, {v[1]})" for v in P900) + f"; area {f4(float(a9))}")
yc = [3, 0, 7]; ceil = sum(H[i] * yc[i] for i in range(3)); slack = ceil + EPS * sum(yc)
cover = [sum(G[i][j] * yc[i] for i in range(3)) for j in range(2)]
print(f"certificate y = (3, 0, 7): tables {cover[0]}, chairs {cover[1]}; bound {ceil}; relaxed: profit <= {f4(slack)} < 929 - 0.05")
log = []; best = bisect(log=log)
for i in (0, 6):
    print("tests: " + ", ".join(f"{m} {'yes' if ok else 'no'} ({k})" for m, ok, k, _ in log[i:i + 6]))
c928 = [e[3] for e in log if e[0] == 928][0]; r928 = real(928, c928)
print(f"best whole target {best}: loosened point ({f4(c928[0])}, {f4(c928[1])}), real limits kept: {'yes' if r928[0] else 'no'}, finish {f4(r928[1])} l; {len(log)} tests, {sum(e[2] for e in log)} steps")
vmin = (2 * EPS / 39) ** 2; v0 = math.pi * 1e4
K = math.ceil(math.log(v0 / vmin) / -math.log(RATIO)); Kb = math.ceil(math.log(v0 / vmin) / (1 / 6))
print(f"floor area {vmin * 1e6:.4f} millionths; steps to reach it: exact ratio {K}, bound exp(-1/6) {Kb}")
nr = [(n, n / (n + 1) * (n * n / (n * n - 1)) ** ((n - 1) / 2), math.exp(-1 / (2 * (n + 1)))) for n in (2, 3, 10, 100)]
print("volume ratio by n (exact, bound): " + "; ".join(f"{n} {r:.4f} {e:.4f}" for n, r, e in nr) + f"; centre of gravity at most {1 - math.exp(-1):.4f}")
bad = [c1[0] * -1, c1[1] * -1]   # the wrong half's centre: old centre + b/3
rw = decide(900, side=-1)
print(f"break, wrong half kept: corner (32, 16) scores {f4(inside([32, 16], bad, P1))} > 1 after one cut; target 900 says {'yes' if rw[0] else 'no'} after {rw[1]} steps")
b0 = bisect(eps=0.0, vmin=vmin); b5 = bisect(eps=0.5)
print(f"break, no relaxation, same budget: says {b0}; relaxed by 0.5: says {b5}")
r20 = decide(900, rad=20.0)
print(f"break, start disc radius 20: target 900 says {'yes' if r20[0] else 'no'} after {r20[1]} steps")
runs = []                # target 929 on P itself: the off-diagonal worked out twice, then once
for sym in (False, True):
    h, k, c, P = H + [-929], 0, [0.0, 0.0], [[1e4, 0.0], [0.0, 1e4]]
    while k < K:
        r = step_P(c, P, G[next(i for i in range(6) if G[i][0] * c[0] + G[i][1] * c[1] > h[i] + EPS)], sym)
        if r[2] <= 0: break
        c, P, k = r[0], r[1], k + 1
    runs.append((k, c, P, r[2]))
(k, _, P, q71), (ks, cs, _, _), r929 = runs[0], runs[1], decide(929)
print(f"break, P updated with two off-diagonals worked out apart, target 929: at step {k} a^T P a = {q71:.6f}; off-diagonals {P[0][1]:.6f} against {P[1][0]:.6f}")
print(f"P updated with one off-diagonal, target 929: {ks} steps, centre ({f4(cs[0])}, {f4(cs[1])}); factor L run: ({f4(r929[2][0])}, {f4(r929[2][1])})")
fig = []
for j in (0, 1, 2, 21):
    Pk = PofL(hist[j][2]); p, q, s = Pk[0][0], Pk[0][1], Pk[1][1]
    m = math.sqrt((p - s) * (p - s) / 4 + q * q); th = 0.5 * math.atan2(2 * q, p - s)
    fig.append(f"k{j} ({170 + 1.1 * hist[j][1][0]:.1f},{140 - 1.1 * hist[j][1][1]:.1f}) r {1.1 * math.sqrt((p + s) / 2 + m):.1f} {1.1 * math.sqrt((p + s) / 2 - m):.1f} rot {0.0 - math.degrees(th) + 0.0:.1f}")
reg = " ".join(f"({170 + 1.1 * float(v[0]):.1f},{140 - 1.1 * float(v[1]):.1f})" for v in sorted(R0))
print("figure, px = 170 + 1.1*x1, py = 140 - 1.1*x2: region " + reg + "; " + "; ".join(fig))

top = max(R0, key=lambda v: 19 * v[0] + 20 * v[1])
assert top == (32, 16) and best == 19 * top[0] + 20 * top[1]                          # ellipsoid meets enumeration
assert cover[0] >= 19 and cover[1] >= 20 and ceil == best and slack < best + 1 - EPS   # dual bound meets it
assert all(abs(r - RATIO) < 1e-9 and r < math.exp(-1 / 6) for r in ratios + [r0]) and worst <= 1 + 1e-9  # ratio, bound, containment
assert all(abs(PofL(hist[1][2])[i][j] - P1[i][j]) < 1e-6 for i in range(2) for j in range(2))
assert found[0] and found[1] == 21 and all(e[2] == K for e in log if not e[1]) and r900[0] and not r928[0]
assert inside([32, 16], bad, P1) > 1 and not rw[0] and b0 == 927 and b5 > 928 and not r20[0] and q71 <= 0 and k == 71
assert ks == K and all(abs(cs[i] - r929[2][i]) < 1e-9 for i in (0, 1))                 # P form meets factor form
print("ALL CHECKS PASS")
