# Covering dimension -- the check behind the card.  Standard library only.
# A 900 mm square wall panel laid in 450 x 225 mm blocks (stretcher bond) or 225 mm square tiles (stack bond).
# Roads: the order of each cover by an exhaustive scan of every cell of its arrangement, against a count of
# joints by hand (for the cube, the panel's order + 1); Lebesgue's theorem by the proof's winding number, whose
# hunt must land on a listed triple point; K5 on the moment curve by 3 x 3 determinants, against the Vandermonde product.
from math import atan2, pi, sqrt, log
from fractions import Fraction
from itertools import combinations, product
S = 900  # panel side, mm

def bond(w, h, shift):  # closed blocks (x0, y0, x1, y1), mm; with shift, odd courses start half a block in
    out = []
    for j in range(S // h):
        xs = sorted({0, S} | set(range(w // 2 if shift and j % 2 else 0, S, w)))
        out += [(a, j * h, b, j * h + h) for a, b in zip(xs, xs[1:])]
    return out

def order(rects, grow=0, closed=True):  # most pieces sharing one point of the panel, and where (exhaustive)
    R = [(2 * (a - grow), 2 * (b - grow), 2 * (c + grow), 2 * (d + grow)) for a, b, c, d in rects]  # doubled
    def cand(i):  # every cut line inside the panel and the middle of every cell between cut lines
        cuts = sorted({v for r in R for v in (r[i], r[i + 2]) if 0 <= v <= 2 * S} | {0, 2 * S})
        mids = [(u + v) // 2 for u, v in zip(cuts, cuts[1:])]
        return sorted(mids + (cuts if closed else []))
    count = {}
    for x in cand(0):
        for y in cand(1):
            k = sum((a <= x <= c and b <= y <= d) if closed else (a < x < c and b < y < d) for a, b, c, d in R)
            count.setdefault(k, []).append((x / 2, y / 2))
    return max(count), count

def mesh(rects): return max(sqrt((c - a) ** 2 + (d - b) ** 2) for a, b, c, d in rects)
def pts(P): return " ".join(f"({x:g},{y:g})" for x, y in P)

blocks, tiles = bond(450, 225, True), bond(225, 225, False)
ob, cb = order(blocks); ot, ct = order(tiles)
print(f"stretcher bond: {len(blocks)} blocks, mesh {mesh(blocks):.1f} mm, order {ob}; points in 3 blocks: {len(cb[3])}")
print(f"stack bond tiles: {len(tiles)} tiles, mesh {mesh(tiles):.1f} mm, order {ot}; points in 4 tiles: {len(ct[4])}")
course = [sum(r[1] == j * 225 for r in blocks) for j in range(4)]  # by hand: a bed joint meets the joints above and below
by_hand = sum(course[j] - 1 + course[j + 1] - 1 for j in range(3))
print(f"by hand: blocks per course {course}; joints meeting the 3 inner bed joints: {by_hand}; tiles: 3 x 3 = 9 corners")
print("figure, triple points:", pts(cb[3]))
print("figure, quadruple points:", pts(ct[4]))
assert ob == 3 and ot == 4 and len(cb[3]) == by_hand == 9 and len(ct[4]) == 9
for w, h in [(150, 75), (90, 45)]:
    o, _ = order(bond(w, h, True)); print(f"finer bond {w} x {h} mm: {len(bond(w, h, True))} blocks, mesh {mesh(bond(w, h, True)):.1f} mm, order {o}")
    assert o == 3
for g in (100, 125):  # thicken every block into an open box g mm bigger on each side
    o, _ = order(blocks, g, False); big = [(a - g, b - g, c + g, d + g) for a, b, c, d in blocks]
    print(f"open blocks thickened by {g} mm: mesh {mesh(big):.1f} mm, order {o}")
    assert o == (3 if g < 112.5 else 6)
U = [(2 * (a - 100), 2 * (b - 100), 2 * (c + 100), 2 * (d + 100)) for a, b, c, d in blocks]  # open, doubled mm
cut = sorted({v for u in U for v in u if 0 < v < 2 * S} | {0, 2 * S}); cut += [(u + v) // 2 for u, v in zip(cut, cut[1:])]
# a set lies in an open box exactly when its bounding box does, and a bounding box can shrink onto these cuts
lam = min(max(x1 - x0, y1 - y0) for x0 in cut for x1 in cut if x0 <= x1 for y0 in cut for y1 in cut if y0 <= y1
          if not any(a < x0 and x1 < c and b < y0 and y1 < d for a, b, c, d in U)) / 2
print(f"open blocks thickened by 100 mm: Lebesgue number {lam:g} mm (every set under {lam:g} mm across lies in one)")
assert lam == 2 * 100  # by hand: each joint is overlapped 100 mm on each side
halves = [(0, 0, 450, 900), (450, 0, 900, 900)]
print(f"coarse cover, two halves: mesh {mesh(halves):.1f} mm (not under 900), order {order(halves)[0]}")
def layer(k, d):  # layer k of a 900 mm cube, 225 mm deep: stretcher bond moved d along and d up; half-mm units
    out = []
    for j in range(-1, 5):
        y0, y1 = max(d + 450 * j, 0), min(d + 450 * j + 450, 2 * S)
        xs = sorted({0, 2 * S} | {x for x in range(d + 450 * (j % 2) - 900, 2 * S, 900) if x > 0})
        out += [(a, y0, 450 * k, b, y1, 450 * k + 450) for a, b in zip(xs, xs[1:]) if y0 < y1]
    return out
def order3(bx):  # the same exhaustive scan in 3 dimensions: every cut plane, and the middle of every cell between
    cand = [sorted({q[i] for q in bx} | {q[i + 3] for q in bx}) for i in range(3)]
    cand = [c + [(u + v) // 2 for u, v in zip(c, c[1:])] for c in cand]
    return max(sum(all(q[i] <= p[i] <= q[i + 3] for i in range(3)) for q in bx) for p in product(*cand))
for d in (225, 0):  # a quarter block along and half a course up are both 112.5 mm, 225 in half-mm
    cube = [q for k in range(4) for q in layer(k, d * (k % 2))]
    o, cm = order3(cube), max(sqrt(sum((q[i + 3] - q[i]) ** 2 for i in range(3))) for q in cube) / 2
    how = f"odd layers moved {d / 2:g} mm along the courses and {d / 2:g} mm up" if d else "layers stacked straight"
    print(f"cube 900 mm, 4 layers 225 mm deep, {how}: {len(cube)} blocks, mesh {cm:.1f} mm, order {o}")
    assert o == (ob + 1 if d else 2 * ob)  # by hand: 3 in one layer + 1 in the next, or 3 + 3 when triple points meet
# Lebesgue's proof: group 1 = blocks on the left side, group 2 = others on the bottom, group 3 = the rest
L = [r for r in blocks if r[0] == 0]; B = [r for r in blocks if r[1] == 0 and r not in L]
A = [L, B, [r for r in blocks if r not in L and r not in B]]
def dist(p, rs): return min(sqrt(max(a - p[0], 0, p[0] - c) ** 2 + max(b - p[1], 0, p[1] - d) ** 2) for a, b, c, d in rs)
V = [(0.0, 1.0), (-sqrt(3) / 2, -0.5), (sqrt(3) / 2, -0.5)]  # the triangle's corners v1, v2, v3
def tri(x, y):  # the point of the triangle's rim with weights d1 : d2 : d3 (some d is 0: every point is covered)
    p = (min(max(x, 0), S), min(max(y, 0), S)); d = [dist(p, g) for g in A]; s = sum(d)
    return sum(d[i] * V[i][0] for i in range(3)) / s, sum(d[i] * V[i][1] for i in range(3)) / s
def winding(x0, y0, size, n=64):  # net turns of tri round the rim of a square, sampled n times per side
    P = [(x0 + size * k / n, y0) for k in range(n)] + [(x0 + size, y0 + size * k / n) for k in range(n)]
    P += [(x0 + size - size * k / n, y0 + size) for k in range(n)] + [(x0, y0 + size - size * k / n) for k in range(n)]
    tot, (px, py) = 0.0, tri(*P[-1])
    for p in P:
        qx, qy = tri(*p); tot += atan2(px * qy - py * qx, px * qx + py * qy); px, py = qx, qy
    return round(tot / (2 * pi))
print(f"proof: groups of {len(A[0])}, {len(A[1])}, {len(A[2])} blocks; winding round the panel's rim: {winding(0, 0, S)}")
x0, y0, size = -37.0, -53.0, 1000.0
for _ in range(30):  # keep a quarter whose rim still winds: it closes in on a point in all three groups
    size /= 2
    x0, y0 = next((a, b) for a in (x0, x0 + size) for b in (y0, y0 + size) if winding(a, b, size) != 0)
hx, hy = x0 + size / 2, y0 + size / 2
inside = sum(a - 1e-6 <= hx <= c + 1e-6 and b - 1e-6 <= hy <= d + 1e-6 for a, b, c, d in blocks)
print(f"proof: the hunt lands at ({hx:.6f}, {hy:.6f}) mm, in {inside} blocks")
assert abs(winding(0, 0, S)) == 1 and inside == 3 and min(abs(hx - x) + abs(hy - y) for x, y in cb[3]) < 1e-6
# Cantor set, level 5: 2^5 closed pieces 1/3^5 long, pairwise apart, so order 1 at every level
I = [(Fraction(0), Fraction(1))]
for _ in range(5): I = [q for a, b in I for q in ((a, a + (b - a) / 3), (b - (b - a) / 3, b))]
gap = min(c - b for (a, b), (c, d) in zip(I, I[1:]))
print(f"Cantor level 5: {len(I)} pieces, each {I[0][1] - I[0][0]} long, smallest gap {gap}: order 1, so dimension 0")
print(f"Cantor box count: log {len(I)} / log 243 = {log(len(I)) / log(243):.6f} = log 2 / log 3 = {log(2) / log(3):.6f}")
assert gap > 0 and abs(log(len(I)) / log(243) - log(2) / log(3)) < 1e-12
# a graph: K5, each edge cut in thirds; a point is a vertex, or (edge, t) at t sixths from the edge's first end
K = list(combinations(range(5), 2))
stars = [{v} | {(e, t) for e in K for t in range(1, 6) if (e[0] == v and t <= 2) or (e[1] == v and t >= 4)} for v in range(5)]
spots = list(range(5)) + [(e, t) for e in K for t in range(1, 6)]  # every vertex, every cut and every cell between
star_mid = [sum(p in s for s in stars) + sum(p in {(e, 2), (e, 3), (e, 4)} for e in K) for p in spots]
print(f"K5 cover: 5 stars (a vertex and the near third of its {sum(0 in e for e in K)} edges) + 10 middles, "
      f"order {max(star_mid)} (checked at {len(spots)} points), so dimension 1")
P = {t: (t, t * t, t * t * t) for t in range(1, 6)}  # K5 on the moment curve (t, t^2, t^3) in R^3
def det(u, v, w): return u[0] * (v[1] * w[2] - v[2] * w[1]) - u[1] * (v[0] * w[2] - v[2] * w[0]) + u[2] * (v[0] * w[1] - v[1] * w[0])
def sub(p, q): return tuple(a - b for a, b in zip(p, q))
dets = []
for (a, b), (c, d) in combinations(combinations(range(1, 6), 2), 2):
    if len({a, b, c, d}) == 4:  # disjoint edges: their 4 corners must not lie in one plane
        s = sorted((a, b, c, d)); vd = 1
        for i, j in combinations(range(4), 2): vd *= s[j] - s[i]
        dk = det(*(sub(P[q], P[s[0]]) for q in s[1:])); dets.append(dk)
        assert dk == vd and dk != 0
print(f"K5 in R^3: {len(dets)} pairs of disjoint edges, smallest determinant {min(dets)}, all equal the Vandermonde product")
E, Vn = sum(1 for _ in combinations(P, 2)), len(P)  # counted from the vertices placed above
print(f"K5 in R^2: {E} edges, but a flat drawing allows at most 3 x {Vn} - 6 = {3 * Vn - 6}; 2n + 1 = 3 for a graph")
assert max(star_mid) == 2 and E > 3 * Vn - 6
print("ALL CHECKS PASS")
