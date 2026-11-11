# Separating hyperplanes -- the check behind the card.  Standard library only:
# fractions does exact rational arithmetic, math gives cos and sin.  Each bean
# is a point (caffeine in g/kg, cost in pounds/kg); a blend mixes them with
# weights >= 0 adding to 1.  The spec, 18 g/kg at 5.50 a kilo, is shown out of
# reach three ways: the closest-point wall, every blend on a 1/360 grid, and
# Farkas' certificate against the blend equations.  Then four ways to go wrong.
import math
from fractions import Fraction as Fr

NAMES = ["Robusta", "Brazil", "Ethiopia"]
P = [(Fr(22), Fr(5)), (Fr(13), Fr(8)), (Fr(11), Fr(14))]
SPEC, EASY, EDGE = (Fr(18), Fr(11, 2)), (Fr(15), Fr(10)), (Fr(19), Fr(6))
N = 360                                       # grid step: 1/360 of a kilo

def dot(u, v): return sum(a * b for a, b in zip(u, v))
def sub(u, v): return tuple(a - b for a, b in zip(u, v))
def pt(v): return f"({float(v[0]):.2f}, {float(v[1]):.2f})"
def fl(xs): return ", ".join(str(x) for x in xs)

def nearest_on_edge(x, a, b):                 # minimise |a + t(b - a) - x|^2, 0 <= t <= 1
    d = sub(b, a)
    t = min(max(dot(sub(x, a), d) / dot(d, d), Fr(0)), Fr(1))
    return t, (a[0] + t * d[0], a[1] + t * d[1])

def solve3(rows, rhs):                        # Gauss-Jordan elimination, exact
    m = [[Fr(v) for v in r] + [Fr(c)] for r, c in zip(rows, rhs)]
    for c in range(3):
        piv = next(r for r in range(c, 3) if m[r][c] != 0)
        m[c], m[piv] = m[piv], m[c]
        for r in range(3):
            if r != c:
                f = m[r][c] / m[c][c]
                m[r] = [x - f * y for x, y in zip(m[r], m[c])]
    return [m[i][3] / m[i][i] for i in range(3)]

A = [[1, 1, 1], [p[0] for p in P], [p[1] for p in P]]   # columns: (1, caffeine, cost)

half = tuple((u + v) / 2 for u, v in zip(P[0], P[1]))
print(f"half Robusta, half Brazil: {pt(half)}")

# ---- road one: the closest blend, and the wall at right angles to it ----
cands = []
for i, j in [(0, 1), (1, 2), (0, 2)]:
    t, q = nearest_on_edge(SPEC, P[i], P[j])
    cands.append((dot(sub(q, SPEC), sub(q, SPEC)), i, j, t, q))
d2, i, j, t, p = min(cands)
a = sub(p, SPEC)                              # normal: from the spec to the closest blend
k = 1 / a[0]                                  # rescale to whole numbers
y = (k * a[0], k * a[1])
floor, spec_score = k * dot(a, p), dot(y, SPEC)
bean_scores = [dot(y, b) for b in P]
print(f"closest blend: {NAMES[i]} {1 - t}, {NAMES[j]} {t}, at {pt(p)}")
print(f"squared distance {d2}, distance {math.sqrt(d2):.4f}")
print(f"normal {pt(a)}, scaled by {k}: score = caffeine + {y[1]} x cost")
print(f"bean scores {fl(bean_scores)}; every blend >= {floor}")
print(f"spec scores {float(spec_score):.1f}; gap {float(floor - spec_score):.1f} = {k} x {d2};"
      f" midway wall at {float((floor + spec_score) / 2):.2f}")
cheapest, strongest = (floor - SPEC[0]) / y[1], floor - y[1] * SPEC[1]
print(f"price line: cost >= ({floor} - caffeine) / {y[1]}; at {SPEC[0]} g/kg >= {cheapest}"
      f" = {float(cheapest):.4f}; at {float(SPEC[1])} a kilo, caffeine >= {float(strongest)}")

# ---- road two: every blend on a 1/360 grid, in exact fractions ----
best_d = best_s = best_c = None
count = hits = 0
for r in range(N + 1):
    for b in range(N + 1 - r):
        mix = (Fr(r, N), Fr(b, N), Fr(N - r - b, N))
        x = (dot(mix, A[1]), dot(mix, A[2]))  # the blend's caffeine and cost
        dd, s = dot(sub(x, SPEC), sub(x, SPEC)), dot(y, x)
        count, hits = count + 1, hits + (dd == 0)
        if best_d is None or dd < best_d[0]: best_d = (dd, r, b, N - r - b)
        if best_s is None or s < best_s: best_s = s
        if x[0] == SPEC[0] and (best_c is None or x[1] < best_c[0]): best_c = (x[1], r, b, N - r - b)
grid_d2 = best_d[0]
print(f"grid: {count} blends, {hits} hit the spec; closest {best_d[1:]} / {N}, squared distance {grid_d2}")
print(f"grid: lowest score {best_s}; cheapest at exactly {SPEC[0]} g/kg {best_c[1:]} / {N},"
      f" cost {best_c[0]}")

# ---- road three: Farkas, either a recipe with weights >= 0 or a certificate ----
w = solve3(A, (1,) + SPEC)
cert = (-floor, y[0], y[1])
at_cert = [dot(cert, col) for col in zip(*A)]
print(f"the only mix with exact numbers: {fl(w)}; Ethiopia {float(w[2]):.5f}")
print(f"certificate y = ({fl(cert)}): A^T y = ({fl(at_cert)}), "
      f"b.y = {float(dot(cert, (1,) + SPEC)):.1f}")
w_easy = solve3(A, (1,) + EASY)
print(f"reachable spec {pt(EASY)}: weights {fl(w_easy)}, b.y = {dot(cert, (1,) + EASY)}")

# ---- what breaks ----
lo = lambda m: min(q[m] for q in P)
hi = lambda m: max(q[m] for q in P)
print(f"mistake 1, one number at a time: caffeine {SPEC[0]} in [{lo(0)}, {hi(0)}], cost {float(SPEC[1])} in"
      f" [{lo(1)}, {hi(1)}]: both pass")
nb = min(range(3), key=lambda m: dot(sub(P[m], SPEC), sub(P[m], SPEC)))
z = tuple(2 * v for v in sub(P[nb], SPEC))
print(f"mistake 2, wall from nearest bean {NAMES[nb]}: normal {pt(z)}, beans "
      f"{fl(dot(z, q) for q in P)}, spec {float(dot(z, SPEC)):.1f}")
gaps = []
for deg in range(360):
    u = (math.cos(math.radians(deg)), math.sin(math.radians(deg)))
    gaps.append(min(dot(u, sub(q, EASY)) for q in P))
print(f"mistake 3, single origins only, spec {pt(EASY)}: best gap over 360 directions"
      f" {max(gaps):.4f}")
edge_w = solve3(A, (1,) + EDGE)
dists = []
for eps in (Fr(1, 10), Fr(1, 100), Fr(1, 1000)):
    mix = [(1 - eps) * edge_w[m] + eps / 3 for m in range(3)]
    q = (dot(mix, A[1]), dot(mix, A[2]))
    dists.append(math.sqrt(dot(sub(q, EDGE), sub(q, EDGE))))
print(f"mistake 4, all three beans required, spec {pt(EDGE)} = {fl(edge_w)}: "
      f"distances {', '.join(f'{x:.4f}' for x in dists)}; wall gap {dot(y, EDGE) - floor}")
sx = lambda v: 40 + 20 * (v - 10)
sy = lambda v: 270 - 20 * (v - 3)
mid = (floor + spec_score) / 2
w1, w2 = (Fr(11), (mid - 11) / 3), (Fr(24), (mid - 24) / 3)
print("figure, " + ", ".join(f"{float(sx(q[0])):.2f} {float(sy(q[1])):.2f}"
                             for q in P + [SPEC, p, w1, w2]))

assert d2 == grid_d2 == Fr(5, 8) and (best_d[1], best_d[2]) == (210, 150)   # road one = road two
assert all(s >= floor for s in bean_scores) and spec_score < floor and hits == 0
assert best_s == floor and best_c[0] == cheapest             # bound is met
assert min(w) < 0 and all(v >= 0 for v in at_cert) and dot(cert, (1,) + SPEC) < 0
assert all(v >= 0 for v in w_easy) and dot(cert, (1,) + EASY) >= 0
assert max(gaps) <= 1e-12 and dot(y, EDGE) == floor
assert min(dot(z, q) for q in P) < dot(z, SPEC)                  # the nearest-bean line fails
print("ALL CHECKS PASS")
