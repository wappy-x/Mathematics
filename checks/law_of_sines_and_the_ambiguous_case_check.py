# Law of sines and the ambiguous case -- the check behind the card.  Imports only
# sin, cos, sqrt and pi.  Lighthouses A and B, 10 km apart, fix ship C by two
# bearings (ASA), then in fog by A's bearing and B's radar range (SSA).  Two roads each.
from math import sin, cos, sqrt, pi
c, A, B, TOL = 10.0, 30.0, 105.0, 1e-9       # baseline (km); angles at A and B (degrees)
sn, cs = (lambda d: sin(d * pi / 180)), (lambda d: cos(d * pi / 180))   # sine, cosine in degrees
def arcsin(q):                                # the angle from 0 to 90 whose sine is q,
    lo, hi = 0.0, 90.0                        # by halving: the sine rises steadily there
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if sn(mid) < q else (lo, mid)
    return (lo + hi) / 2

def by_sines(a):                              # SSA road one: sin C = c sin A / a, and its mirror
    q = c * sn(A) / a
    Cs = [] if q > 1 + TOL else [90.0] if q > 1 - TOL else [arcsin(q), 180 - arcsin(q)]
    return q, [(C, 180 - A - C, a * sn(180 - A - C) / sn(A)) for C in Cs if 180 - A - C > TOL]

def by_grid(a):                               # SSA road two: A at (0, 0), B at (c, 0).  The point
    p, e = c * cs(A), (c * cs(A)) ** 2 - (c * c - a * a)    # t along A's sightline is a from B
    return [] if e < -TOL else [p] if e < TOL else [p - sqrt(e), p + sqrt(e)]  # t^2 - 2pt + c^2 - a^2 = 0

C = 180 - A - B                               # ASA: the third angle, from the angle sum
k = c / sn(C)                                 # the common ratio: a side over the sine facing it
a, b = k * sn(A), k * sn(B)                   # road one: the law of sines
ux, uy, vx, vy = cs(A), sn(A), cs(180 - B), sn(180 - B)   # road two: sightlines from A and B
t = -c * vy / (vx * uy - ux * vy)             # t (ux, uy) = (c, 0) + w (vx, vy), by Cramer's rule
px, py = t * ux, t * uy                       # the ship on the grid; C = 45 is never used
ga, gb = sqrt((px - c) ** 2 + py ** 2), sqrt(px ** 2 + py ** 2)
oy = (px * px + py * py - c * px) / (2 * py)  # centre (c/2, oy): as far from the ship as from A, B
print(f"ASA: c = {c:.2f} km, A = {A:.2f}, B = {B:.2f}, so C = {C:.2f} degrees; sin A = {sn(A):.4f}, sin B = {sn(B):.4f}, sin C = {sn(C):.4f}")
print(f"road one, law of sines: c / sin C = {k:.4f} km, so a = {a:.2f} km (ship to B), b = {b:.2f} km (ship to A)")
print(f"road two, sightlines at {A:.0f} and {180 - B:.0f} degrees on a grid: ship at ({px:.2f}, {py:.2f}); a = {ga:.2f} km, b = {gb:.2f} km")
print(f"one height, two ways: b sin A = {b * sn(A):.2f} km, a sin B = {a * sn(B):.2f} km")
print(f"circle through A, B and ship: centre ({c / 2:.2f}, {oy:.2f}), diameter {2 * sqrt(c * c / 4 + oy * oy):.4f} km")
print(f"SSA: A = {A:.2f}, c = {c:.2f} km; c cos A = {c * cs(A):.2f} km, gap from B to A's sightline d = c sin A = {c * sn(A):.2f} km")
counts, sides = [], []
for r in (4.0, 5.0, a, 12.0):                 # B's radar range; a is the true ship's
    q, tri = by_sines(r)
    roots = [x for x in by_grid(r) if x > TOL]
    counts.append((len(tri), len(roots)))
    sides += list(zip(sorted(x[2] for x in tri), roots))
    print(f"range {r:.2f} km: sin C = {q:.4f}; triangles by sines {len(tri)}, by the grid {len(roots)}")
    for Cx, Bx, bx in tri:
        print(f"  C = {Cx:.2f}, B = {Bx:.2f}, sin B = {sn(Bx):.4f}, b = {bx:.2f} km")
m = arcsin(by_sines(12.0)[0])                 # the calculator's angle at a 12 km range
print(f"mistake, both mirrors kept at 12 km: C = {180 - m:.2f} leaves B = {m - A:.2f}; "
      f"the grid's other crossing is {by_grid(12.0)[0]:.2f} km, behind A")
print(f"mistake, sides in proportion to angles: b = {a * B / A:.2f} km; sin B / sin A = {sn(B) / sn(A):.2f}, not {B / A:.2f}")
fix = lambda x, y: f"({24 + 22 * x:.2f}, {196 - 22 * y:.2f})"   # km to figure units, y pointing down
fog = lambda x, y: f"({14 + 19 * x:.2f}, {206 - 19 * y:.2f})"
foot, ph = c * cs(A), by_grid(a)[0]           # fog: foot of B's square-on line; the phantom
print(f"figure, fix, 1 km = 22 units: A {fix(0, 0)}, B {fix(c, 0)}, ship {fix(px, py)}, foot {fix(px, 0)}")
print(f"figure, fog, 1 km = 19 units: A {fog(0, 0)}, B {fog(c, 0)}, foot {fog(foot * cs(A), foot * sn(A))}, "
      f"ship {fog(px, py)}, phantom {fog(ph * cs(A), ph * sn(A))}, radius {19 * a:.2f}")
assert max(abs(a - ga), abs(b - gb)) < 1e-9                   # ASA: sines and grid agree
assert abs(2 * sqrt(c * c / 4 + oy * oy) - k) < 1e-9          # the common ratio is the circle's diameter
assert counts == [(0, 0), (1, 1), (2, 2), (1, 1)]             # SSA: none, one, two, one, by both roads
assert max(abs(x - y) for x, y in sides) < 1e-9               # and the same distances, road for road
print("ALL CHECKS PASS")
