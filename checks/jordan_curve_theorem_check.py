# Jordan curve theorem -- the check behind the card.  Standard library only.
# A field on a map, in metres: three straight fences and a stream bank with an
# oxbow bend.  Roads: ray parity two ways against the winding angle; a 1 m grid
# flood fill whose piece count meets Euler's V - E + F; limits by finite stages.
from fractions import Fraction as Fr
from math import atan2, pi, sin, sqrt

def field(h):  # h: half-width of the oxbow's neck, in metres
    return [(0, 0), (80, 0), (80, 50), (60, 50), (40 + h, 50), (40 + h, 44), (50, 40),
            (52, 30), (46, 22), (34, 22), (28, 30), (30, 40), (40 - h, 44), (40 - h, 50),
            (20, 50), (0, 50)]

def edges(poly, closed=True):
    n = len(poly)
    es = [(poly[i], poly[(i + 1) % n]) for i in range(n if closed else n - 1)]
    return [(a, b) for a, b in es if a != b]

def east(p, es):  # half-open rule: a corner on the ray counts as just south of it
    n = 0
    for (ax, ay), (bx, by) in es:
        if (ay > p[1]) != (by > p[1]) and ((ax - p[0]) * (by - ay) + (p[1] - ay) * (bx - ax)) * (by - ay) > 0:
            n += 1
    return n

def north(p, es):  # the same count with east and north swapped
    return east((p[1], p[0]), [((ay, ax), (by, bx)) for (ax, ay), (bx, by) in es])

def winding(p, es):  # road 2: total turn of the sight line, in whole turns
    t = 0.0
    for (ax, ay), (bx, by) in es:
        ux, uy, vx, vy = ax - p[0], ay - p[1], bx - p[0], by - p[1]
        t += atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    return round(t / (2 * pi))

def orient(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

def meets(a, b, c, d):  # do the closed segments ab and cd share a point?
    o = (orient(a, b, c), orient(a, b, d), orient(c, d, a), orient(c, d, b))
    if o[0] * o[1] < 0 and o[2] * o[3] < 0:
        return True
    box = lambda p, q, r: min(p[0], q[0]) <= r[0] <= max(p[0], q[0]) and min(p[1], q[1]) <= r[1] <= max(p[1], q[1])
    return any(o[k] == 0 and box(*s) for k, s in enumerate(((a, b, c), (a, b, d), (c, d, a), (c, d, b))))

def flood(w, h, ok, wrap=False):  # union-find over a w by h grid; returns piece of each point
    up = list(range(w * h))
    def find(k):
        while up[k] != k:
            up[k] = up[up[k]]; k = up[k]
        return k
    for i in range(w):
        for j in range(h):
            for di, dj in ((1, 0), (0, 1)):
                i2, j2 = ((i + di) % w, (j + dj) % h) if wrap else (i + di, j + dj)
                if i2 < w and j2 < h and ok(i, j, i2, j2):
                    up[find(i * h + j)] = find(i2 * h + j2)
    return [find(k) for k in range(w * h)]
def map_pieces(es):  # grid points at (x + 1/3, y + 1/2) m, x from -5 to 84, y from -5 to 54
    e6 = [((6 * a[0], 6 * a[1]), (6 * b[0], 6 * b[1])) for a, b in es]
    pt = lambda i, j: (6 * i - 28, 6 * j - 27)
    return flood(90, 60, lambda i, j, k, l: not any(meets(pt(i, j), pt(k, l), a, b) for a, b in e6))
def euler_faces(es):  # V - E + F = 2 for a drawing in one piece, crossings made into corners
    und = {tuple(sorted(e)) for e in es}
    cross = sum(1 for e in und for f in und if e < f and not set(e) & set(f)
                and orient(*e, f[0]) * orient(*e, f[1]) < 0 and orient(*f, e[0]) * orient(*f, e[1]) < 0)
    v, e = len({p for s in und for p in s}) + cross, len(und) + 2 * cross
    return cross, v, e, 2 - v + e

def area(poly):
    return Fr(sum(orient((0, 0), a, b) for a, b in edges(poly)), 2)
cell = lambda x, y: (x + 5) * 60 + (y + 5)  # grid index of the point just north-east of (x, y)
F = field(2); es = edges(F)
print(f"field, neck 4 m wide: {len(F)} corners, area by shoelace {area(F)} m2")
print(f"corners, anticlockwise from the south-west, metres: {F}")
verdicts = []
for name, p in (("well", (40, 10)), ("heron", (40, 32)), ("cow", (20, 34))):
    e, n, w = east(p, es), north(p, es), winding(p, es)
    verdicts.append((e % 2, n % 2, w))
    print(f"{name:<5} {p}: east ray {e}, north ray {n}, winding {w} -> {'inside' if w else 'outside'}")
piece = map_pieces(es); sizes = {r: piece.count(r) for r in set(piece)}
inside = sizes[piece[cell(40, 10)]]
print(f"grid 90 x 60 points 1 m apart: pieces {len(sizes)}; inside {inside} points, outside {sizes[piece[0]]}")
print(f"same piece: well and cow {piece[cell(40, 10)] == piece[cell(20, 34)]}, heron and far corner {piece[cell(40, 32)] == piece[0]}")
cases = [(f"neck {2 * h} m wide", edges(field(h))) for h in (2, 1, 0)]
cases += [("corners out of order SW SE NW NE", edges([(0, 0), (80, 0), (0, 50), (80, 50)])),
          ("west fence missing", edges(F, closed=False))]
counts = []  # each fence two ways: Euler's count of faces, and a flood fill of the grid
for name, c in cases:
    cr, v, e, f = euler_faces(c); g = len(set(map_pieces(c))); counts.append((g, f))
    print(f"{name:<32}: crossings {cr}, V {v}, E {e}, Euler faces {f}, grid pieces {g}")
lake = map_pieces(edges(field(0))); lake_n = lake.count(lake[cell(40, 32)])
print(f"neck closed: heron with the far corner {lake[cell(40, 32)] == lake[0]}; lake {lake_n} points, "
      f"shoelace {abs(area(field(0)[5:12]))} m2")
print(f"corners out of order: shoelace area {area([(0, 0), (80, 0), (0, 50), (80, 50)])} m2")
wall = lambda i, j, k, l: not (j == l and {i, k} == {0, 1})  # a closed loop on the tube, between columns 0 and 1
print(f"loop round the inner tube (12 x 8 grid, both edge pairs glued): pieces {len(set(flood(12, 8, wall, True)))}; "
      f"the tube cut open flat: {len(set(flood(12, 8, wall)))}")
wig = []
for N in (10, 100, 1000):  # y = x sin(pi/x) meets y = 0 at x = 1, 1/2, ..., 1/N
    s, last = 0, None
    for j in range(800, 1000 * N + 501):  # u = 1/x from 0.8 to N + 0.5, steps of 0.001
        sign = sin(pi * j / 1000) >= 0; s += last is not None and sign != last; last = sign
    wig.append((N, s)); print(f"wiggle, crossings with x >= 1/{N}: formula {N}, sampled {s}")

def koch(n):  # level-n snowflake on a 90 m triangle, clockwise, as floats
    pts = [(0.0, 0.0), (45.0, 45.0 * sqrt(3)), (90.0, 0.0)]
    for _ in range(n):
        new = []
        for k in range(len(pts)):
            (ax, ay), (bx, by) = pts[k], pts[(k + 1) % len(pts)]
            dx, dy = (bx - ax) / 3, (by - ay) / 3
            px, py = ax + 1.5 * dx - dy * sqrt(3) / 2, ay + 1.5 * dy + dx * sqrt(3) / 2  # the new peak
            new += [(ax, ay), (ax + dx, ay + dy), (px, py), (ax + 2 * dx, ay + 2 * dy)]
        pts = new
    return pts
tri = 8100 * sqrt(3) / 4
for n in (0, 1, 2, 5):
    k = koch(n); m = len(k)
    per = sum(sqrt((k[(i + 1) % m][0] - k[i][0]) ** 2 + (k[(i + 1) % m][1] - k[i][1]) ** 2) for i in range(m))
    ar = abs(sum(k[i][0] * k[(i + 1) % m][1] - k[(i + 1) % m][0] * k[i][1] for i in range(m))) / 2 / tri
    P, A = 270 * Fr(4, 3) ** n, Fr(8, 5) - Fr(3, 5) * Fr(4, 9) ** n
    assert abs(per - P) < 1e-9 * P and abs(ar - A) < 1e-9, "Koch polygon against the formulas"
    print(f"Koch level {n}: {m} sides, perimeter {P} = {float(P):.2f} m (summed {per:.2f}), area {A} = {float(A):.6f} triangles (shoelace {ar:.6f})")
print(f"Koch level 20: perimeter {float(270 * Fr(4, 3) ** 20):.1f} m; area limit 8/5 of the triangle")
adj = lambda x, y: (x < 3) != (y < 3)  # K33: three houses 0-2, three utilities 3-5
tris = sum(1 for a in range(6) for b in range(a + 1, 6) for c in range(b + 1, 6) if adj(a, b) and adj(b, c) and adj(a, c))
ke = sum(1 for a in range(6) for b in range(a + 1, 6) if adj(a, b)); girth = 3 if tris else 4
print(f"K33: V 6, E {ke}; Euler needs F = {2 - 6 + ke}; triangles {tris} of 20, so {girth}F <= 2E gives F <= {Fr(2 * ke, girth)}")
svg = lambda x, y: (30 + 5 * x, 290 - 5 * y)  # 5 drawing units a metre
print(f"figure, corners {[svg(*c) for c in F]}")
print(f"figure, well {svg(40, 10)}, heron {svg(40, 32)}, cow {svg(20, 34)}")

assert verdicts == [(1, 1, 1), (0, 0, 0), (1, 1, 1)], "ray parity both ways must match the winding angle"
assert [g for g, f in counts] == [f for g, f in counts] == [2, 2, 3, 3, 1], "grid pieces must equal Euler faces"
assert abs(inside - area(F)) < 40, "inside grid points must match the shoelace area"
assert all(N == s for N, s in wig), "sampled sign changes must match the zeros at 1/k"
assert 2 - 6 + ke > Fr(2 * ke, girth), "K33 needs more faces than its edges allow"
assert abs(lake_n - abs(area(field(0)[5:12]))) < 20, "lake grid points against its shoelace area"
print("ALL CHECKS PASS")
