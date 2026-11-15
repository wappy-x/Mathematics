# Contractible and simply connected -- the check behind the card.  Standard library only.
# A round lawn, radius 10 m, centred on a lamp post whose base has radius 1 m.
# Disc: the lawn with no post.  Annulus: 1 <= |x| <= 10.  Punctured plane: |x| > 0.
# A walker's loop is a polygon with whole-metre corners.  Roads to its winding number:
# signed crossings of the ray east from the post (exact), and the total turn of the
# sight line from the post (atan2).  Homotopies are checked stage by stage: N cases.
from fractions import Fraction as Fr
from math import atan2, pi, sqrt

SQ = [(4, -4), (4, 4), (-4, 4), (-4, -4)]  # 8 m square round the post, anticlockwise
def scale(poly, k):
    return [(k * x, k * y) for x, y in poly]
def edges(poly):
    return [(poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly))]

def crossings(poly):  # road 1: signed crossings of the ray east from (0, 0)
    up = down = 0
    for (ax, ay), (bx, by) in edges(poly):
        if (ay <= 0) != (by <= 0) and ax + Fr(-ay) * (bx - ax) / (by - ay) > 0:
            if by > ay: up += 1
            else: down += 1
    return up, down

def turns(poly):  # road 2: total turn of the sight line, in whole turns
    t = 0.0
    for (ax, ay), (bx, by) in edges(poly):
        t += atan2(ax * by - ay * bx, ax * bx + ay * by)
    w = t / (2 * pi)
    return 0.0 if abs(w) < 1e-9 else w  # print 0, never -0

def near2(poly):  # exact squared distance from the post's centre to the nearest point
    best = None
    for (ax, ay), (bx, by) in edges(poly):
        dx, dy = bx - ax, by - ay
        L = dx * dx + dy * dy
        u = min(Fr(1), max(Fr(0), Fr(-(ax * dx + ay * dy)) / L)) if L else Fr(0)
        d = (ax + u * dx) ** 2 + (ay + u * dy) ** 2
        best = d if best is None else min(best, d)
    return best
far2 = lambda poly: max(x * x + y * y for x, y in poly)  # a polygon's farthest point is a corner

loops = [("once round, anticlockwise", SQ), ("once round, clockwise", SQ[::-1]),
         ("round, then back the other way", SQ + [(4, -4)] + SQ[::-1][:-1]),
         ("twice round", SQ + SQ), ("beside the post, not round it", [(3, -2), (7, -2), (7, 2), (3, 2)])]
wind = []
for name, p in loops:
    u, d = crossings(p); w = turns(p); wind.append((u - d, round(w)))
    print(f"{name:<31}: ray crossings up {u} down {d}, signed {u - d}; turns {w:.6f}; "
          f"nearest {sqrt(near2(p)):.6f} m")

print("shrink H(x, t) = (1 - t) x on the once-round square, stage by stage:")
stages = []
for k in range(9):
    t = Fr(k, 8); p = scale(SQ, 1 - t); n2 = near2(p)
    where = "disc and annulus" if n2 >= 1 else "disc only: inside the base"
    sig = crossings(p)[0] - crossings(p)[1] if n2 > 0 else "none: a point on the post"
    stages.append((t, n2, sig))
    print(f"  t = {str(t):<4} half-side {float(SQ[1][0] * (1 - t)):.1f} m, nearest {float(sqrt(n2)):.6f} m, "
          f"farthest {float(sqrt(far2(p))):.6f} m, winding {sig}; {where}")
t_hit = min(t for t, n2, s in stages if n2 <= 1)
print(f"straight shrink touches the 1 m base at t = {t_hit} (formula 1 - 1/4 = {1 - Fr(1, 4)})")

rim = (6, 8)  # a point on the disc's edge, 10 m out
half = tuple(Fr(c, 2) for c in rim)
print(f"disc contraction of the rim point (6, 8): t = 1/2 gives ({half[0]}, {half[1]}), t = 1 gives (0, 0)")

def retract(x, y, t):  # punctured plane onto the circle of radius 1 m, H(x, t) = x / ((1 - t) + t|x|)
    r = sqrt(x * x + y * y)
    return (x / ((1 - t) + t * r), y / ((1 - t) + t * r))
print("retract the punctured plane, (3, 4) at t = 0, 1/2, 1: " +
      " -> ".join("({:.6f}, {:.6f})".format(*retract(3.0, 4.0, t)) for t in (0.0, 0.5, 1.0)))
side = [(4 - 8 * Fr(j, 16), Fr(4)) for j in range(16)] + [(Fr(-4), 4 - 8 * Fr(j, 16)) for j in range(16)]
samples = side + [(-x, -y) for x, y in side]  # the square, 16 points a side, round from (4, 4)
circ = [retract(float(x), float(y), 1.0) for x, y in samples]
r_min = min(sqrt(x * x + y * y) for s in range(11) for x, y in
            [retract(float(a), float(b), s / 10) for a, b in samples])
print(f"retracted square, 64 sample points: turns {turns(circ):.6f}; nearest to the hole over 11 stages {r_min:.6f} m")

# in space, remove only one point: lift the loop of radius 4 m over it
grid = [Fr(k, 100) for k in range(101)]
d2 = [16 * ((1 - t) ** 2 + t * t) for t in grid]
best = min(d2); t_best = grid[d2.index(best)]
print(f"space minus a point: lift H(s, t) = ((1 - t) 4 cos 2 pi s, (1 - t) 4 sin 2 pi s, 4t); "
      f"nearest {sqrt(best):.6f} m at t = {t_best} (101 stages), formula 2 sqrt 2 = {2 * sqrt(2):.6f}")

print(f"figure, panel centres (120, 130) (350, 130) (580, 130); 10 units a metre; disc and lawn radius 100; "
      f"base radius 10; squares half-side 40, 20, 10")

assert [s for s, w in wind] == [w for s, w in wind] == [1, -1, 0, 2, 0], "two roads to the winding number"
assert near2(loops[4][1]) == 9, "beside the post: nearest 3 m, at (3, 0)"
assert all(s == 1 for t, n2, s in stages if n2 >= 1), "winding stays 1 while the loop avoids the base"
assert t_hit == 1 - Fr(1, 4) and stages[6][1] == 1, "the shrink meets the base exactly at t = 3/4"
assert all(far2(scale(SQ, 1 - t)) <= 100 for t, n2, s in stages), "every stage stays in the 10 m disc"
assert round(turns(circ)) == 1 and abs(r_min - 1) < 1e-12, "retraction keeps the winding and avoids the hole"
assert best == 8 and t_best == Fr(1, 2), "lift: nearest squared distance 8 m2 at t = 1/2"
print("ALL CHECKS PASS")
