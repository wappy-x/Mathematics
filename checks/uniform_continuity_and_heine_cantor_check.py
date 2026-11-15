# Uniform continuity and Heine-Cantor -- the check behind the card.  Only
# math.sqrt and Fraction are imported.  Example: an office floor 24 m by 12 m,
# distance = walking distance along the aisles, |dx| + |dy|.  A radiator in the
# corner (0, 0); temperature T = 16 + 6 u^2 deg C, u = 1 - s/36, s = x + y.
from math import sqrt
from fractions import Fraction as F
W, H, S, EPS = 24.0, 12.0, 36.0, 0.5

def temp(x, y, amp=6.0):
    u = 1 - (x + y) / S
    return 16 + amp * u * u

def vent(x, y):                            # test field: depends on direction from (12, 6)
    return 20 + 2 * (x - 12) / sqrt((x - 12) ** 2 + (y - 6) ** 2)

def walk(p, q): return abs(p[0] - q[0]) + abs(p[1] - q[1])
def line(p, q): return sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)

def ok(f, x, y, d, n=16):                  # every sampled desk within walking d of (x, y)
    t = f(x, y)
    for i in range(-n, n + 1):
        for j in range(abs(i) - n, n - abs(i) + 1):
            qx, qy = x + d * i / n, y + d * j / n
            if 0 <= qx <= W and 0 <= qy <= H and (qx, qy) != (12.0, 6.0):
                if abs(f(qx, qy) - t) > EPS + 1e-12:
                    return False
    return True

def tol(f, x, y):                          # bisection: the largest d that passes, no roots
    lo, hi = 0.0, 40.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if ok(f, x, y, mid) else (lo, mid)
    return lo

def tol_formula(s):                        # same tolerance from the algebra, c = EPS / 6
    u, c = 1 - s / S, EPS / 6
    toward = S * (sqrt(u * u + c) - u)
    return toward if s >= toward else S * (u - sqrt(u * u - c))

# Road 1: the Lipschitz constant.  |T(p) - T(q)| <= d(p, q) / 3, proved on the card.
K = 12 / S
g = [(x, y) for x in range(25) for y in range(13)]
steep = max(abs(temp(*p) - temp(*q)) / walk(p, q) for i, p in enumerate(g) for q in g[i + 1:])
steep2 = max(abs(temp(*p) - temp(*q)) / line(p, q) for i, p in enumerate(g) for q in g[i + 1:])
print(f"K = 12/36 = {K:.6f} deg C per metre walked; steepest on the 1 m grid: {steep:.6f}")
print(f"steepest per straight-line metre on the grid: {steep2:.6f}")
print(f"temperatures: radiator {temp(0, 0):.6f}, halfway {temp(12, 6):.6f}, far corner {temp(24, 12):.6f}; test field {vent(13, 6):.6f} east, {vent(11, 6):.6f} west")
lip = EPS / K
worst = 6 * (1 - (1 - F(3, 2) / 36) ** 2)
print(f"Lipschitz tolerance 0.5 / K: {lip:.6f} m; radiator to 1.5 m away: {worst} = {float(worst):.6f} deg C")
# Road 2: each desk's own tolerance, by formula and by bisection, along the diagonal.
ss = [0, 6, 12, 18, 24, 30, 36]
pts = [tol(temp, 2 * s / 3, s / 3) for s in ss]
for s, p in zip(ss, pts):
    assert abs(p - tol_formula(s)) < 1e-9                    # bisection against the algebra
best = S * (1 - sqrt(1 - EPS / 6))
print(f"own tolerance at the radiator {pts[0]:.6f} m, halfway (s = 18) {pts[3]:.6f} m, far corner {pts[-1]:.6f} m")
grid_min = min(tol(temp, x, y) for x in range(0, 25, 2) for y in range(0, 13, 2))
assert abs(grid_min - best) < 1e-9                           # smallest own tolerance = formula
print(f"best single tolerance: formula 36(1 - sqrt(11/12)) = {best:.6f} m; smallest of 91 desks' own: {grid_min:.6f} m")
for name, d in (("halfway", pts[3]), ("far corner", pts[-1])):
    print(f"{name} tolerance {d:.6f} m used at the radiator: gap {temp(0, 0) - temp(d, 0):.6f} deg C")
t = lip / sqrt(2)                                            # 1.5 m by tape measure, diagonally
print(f"1.5 m by tape from the radiator to ({t:.4f}, {t:.4f}): walk {2 * t:.6f} m, gap {temp(0, 0) - temp(t, t):.6f} deg C")
# Road 3: the Lebesgue number of three heating zones, by brute force over desks.
zones = [(0, 900), (700, 1700), (1500, 2400)]               # in centimetres: [0, 9), (7, 17), (15, 24]
def exit_cm(x, a, b):                                        # walk needed to leave the zone
    if not ((a == 0 or a < x) and (b == 2400 or x < b)):
        return 0
    return min([x - a] * (a > 0) + [b - x] * (b < 2400))
lam = min(max(exit_cm(x, a, b) for a, b in zones) for x in range(2401))
half = min(zones[i][1] - zones[i + 1][0] for i in range(2)) / 2
assert lam == half                                           # brute force against half the overlap
print(f"zones [0, 9) (7, 17) (15, 24]: Lebesgue number {lam / 100:.2f} m by brute force, half the overlap {half / 100:.2f} m")
# What breaks: the floor with one point (12, 6) missing, and a field that tears there.
for r in (1.0, 0.1, 0.01, 0.001):
    gap = vent(12 + r, 6) - vent(12 - r, 6)
    print(f"missing point, desks {r:.3f} m either side: walk {2 * r:.3f} m, gap {gap:.6f} deg C")
    assert abs(gap - 4) < 1e-9
own = [tol(vent, 12 + r, 6) for r in (1.0, 0.1, 0.01)]
tan0 = sqrt(1 - 0.75 ** 2) / 0.75                            # cos = 0.75 is 21.5 deg C
for r, d in zip((1.0, 0.1, 0.01), own):
    assert abs(d - r * tan0) < 1e-9                         # bisection against the geometry
    print(f"missing point, own tolerance at {r:.3f} m from it: {d:.6f} m (geometry {r * tan0:.6f})")
print(f"try: EPS 0.25 gives {0.25 / K:.6f} m Lipschitz, {S * (1 - sqrt(1 - 0.25 / 6)):.6f} m best;"
      f" amp 12 gives K {24 / S:.6f}, {EPS / (24 / S):.6f} m")
print("figure, s m:", " ".join(f"{s}" for s in ss))
print("figure, own tolerance m:", " ".join(f"{p:.2f}" for p in pts))
assert 0 <= K - steep < 0.005 and steep2 > K                # grid chords against K = 1/3
print("ALL CHECKS PASS")
