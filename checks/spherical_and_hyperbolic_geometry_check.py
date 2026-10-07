# Three geometries -- the check behind the card.  Standard library only.
# Escher's fish in the Poincare disc: each fish is 1 unit long, drawn smaller near the rim.
# Every number is reached twice: a closed form, and a road that never uses it
# (thin slices, a many-sided polygon, or a circle solved from three points).
from math import exp, sin, cos, pi, sqrt, acos, atan
DEG, N = 180 / pi, 200000
def drawn(d): return (exp(d) - 1) / (exp(d) + 1)        # true distance from centre -> drawn radius
def by_slices(r):                                        # add 2 x slice / (1 - s^2) over thin slices
    return sum(2 * (r / N) / (1 - ((i + 0.5) * r / N) ** 2) for i in range(N))
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def ang(u, v): return acos(max(-1.0, min(1.0, dot(u, v) / sqrt(dot(u, u) * dot(v, v))))) * DEG
def tangent(p, q): return [b - dot(p, q) * a for a, b in zip(p, q)]  # sphere: direction from p toward q
def dist(p, q): return sqrt(sum((a - b) ** 2 for a, b in zip(p, q)))
def ring(pts, scale): return sum(dist(p, q) * scale(p, q) for p, q in zip(pts, pts[1:]))
def disc_ring(rho, n=20000):                             # polygon on the drawn circle, pieces rescaled
    r = drawn(rho); pts = [(r * cos(2 * pi * i / n), r * sin(2 * pi * i / n)) for i in range(n + 1)]
    return ring(pts, lambda p, q: 2 / (1 - ((p[0] + q[0]) ** 2 + (p[1] + q[1]) ** 2) / 4))
def ball_ring(rho, n=20000):                             # polygon on a ball of radius 1, straight 3-D chords
    pts = [(sin(rho) * cos(2 * pi * i / n), sin(rho) * sin(2 * pi * i / n), cos(rho)) for i in range(n + 1)]
    return ring(pts, lambda p, q: 1)
def f(xs, k=6): return ", ".join(f"{x:.{k}f}" for x in xs)
ends = [drawn(k) for k in range(6)]
lengths = [b - a for a, b in zip(ends, ends[1:])]
back = [by_slices(r) for r in ends[1:]]
sinh = [(exp(p) - exp(-p)) / 2 for p in (1, 2, 3)]
hyp, hyp_poly = [2 * pi * s for s in sinh], [disc_ring(p) for p in (1, 2, 3)]
ball, ball_poly = [2 * pi * sin(p) for p in (1, 2, 3)], [ball_ring(p) for p in (1, 2, 3)]
O, A, B, Astar = (0, 0), (0.5, 0), (0, 0.5), (2, 0)      # Astar: A's mirror in the rim, 1 / 0.5 = 2
# road one to the side AB: the circle through A, B and Astar, solved as two straight-line equations
cx = (Astar[0] ** 2 - A[0] ** 2) / (2 * (Astar[0] - A[0])); cy = (B[1] ** 2 - A[0] ** 2 + 2 * A[0] * cx) / (2 * B[1])
rad = sqrt((A[0] - cx) ** 2 + cy ** 2)
at_A = ang((-1, 0), (-cy, cx - A[0]))                   # tangent at A is square to the radius
flat = [ang((1, 0), (0, 1)), ang((-1, 0), (-0.5, 0.5)), ang((0, -1), (0.5, -0.5))]
V = [(0, 0, 1), (1, 0, 0), (0, 1, 0)]                   # north pole and two equator points a quarter-turn apart
octant = [ang(tangent(V[i], V[(i + 1) % 3]), tangent(V[i], V[(i + 2) % 3])) for i in range(3)]
total = 90 + 2 * at_A
lines = [(u, cy, dist((u, cy), B)) for u in (0, 0.5)]    # circles through B, centre (u, h), h from road one
print("fish far ends, true 1..5, drawn at:", f(ends[1:]))
print("fish drawn lengths:", f(lengths, 3))
print("fish far ends, true, recovered by thin slices:", f(back))
print("ring, true radius 1, 2, 3: flat", f([2 * pi * p for p in (1, 2, 3)], 2), "| hyperbolic 2 pi sinh", f(hyp, 2))
print("ring, hyperbolic by disc polygon:", f(hyp_poly, 2), "| ball 2 pi sin", f(ball, 2), "| ball polygon", f(ball_poly, 2))
print("by hand: e^1..3", f([exp(p) for p in (1, 2, 3)], 3), "| sinh 1..3", f(sinh, 2), "| sin 3", f([sin(3)], 3))
print("flat triangle O, A, B:", f(flat), "sum", f([sum(flat)]), "| octant on a ball:", f(octant), "sum", f([sum(octant)]))
print(f"disc side AB: circle through A, B, A* centre ({cx:.6f}, {cy:.6f}), radius {rad:.6f}")
print(f"disc angle at A: tangent road {at_A:.6f}, atan(3/5) road {atan(0.6) * DEG:.6f}")
print(f"disc triangle sum {total:.6f}, short of 180 by {180 - total:.6f}; at a = 0.05, {90 + 2 * atan((1 - 0.05 ** 2) / (1 + 0.05 ** 2)) * DEG:.6f}")
for u, v, p in lines:
    print(f"line through B, centre ({u:.1f}, {v:.2f}): radius {p:.6f}, rim test {u * u + v * v - p * p:.6f}, lowest y {v - p:.6f}")
def rim(u, v, p):                                        # where the circle centre (u, v), radius p, crosses the rim
    c, m = u * u + v * v, (1 + u * u + v * v - p * p) / 2; w = sqrt(c - m * m); return [((m * u + s * v * w) / c, (m * v - s * u * w) / c) for s in (-1, 1)]
def scr(p): return f"({180 + 160 * p[0]:.1f}, {180 - 160 * p[1]:.1f})"
print("figure 1, disc centre (180, 120), radius 110; fish ends x:", f([180 + 110 * r for r in ends[1:]], 1))
print("figure 2, centre (180, 180), radius 160; A", scr(A), "B", scr(B), "arcs radius", f([160 * r for r in [rad] + [p for _, _, p in lines]], 1), "| rim ends", " ".join(scr(q) for u, v, p in lines for q in rim(u, v, p)))
print(f"mistakes: chord triangle {sum(flat):.6f}; flat ring at 3 is {2 * pi * 3:.2f} not {hyp[2]:.2f}; drawn {ends[4]:.6f} is true {by_slices(ends[4]):.6f}")
assert all(abs(b - k) < 1e-6 for b, k in zip(back, range(1, 6)))                # slices undo the closed form
assert all(abs(a - b) < 1e-3 for a, b in zip(hyp + ball, hyp_poly + ball_poly))  # polygons match 2 pi sinh, 2 pi sin
assert abs(at_A - atan(0.6) * DEG) < 1e-9 and abs(sum(octant) - 270) < 1e-9     # two roads to the disc angle; octant
assert all(abs(dot(q, (q[0] - u, q[1] - v))) < 1e-12 and v - p > 0 for u, v, p in lines for q in rim(u, v, p))  # radii square at rim; miss OA
print("ALL CHECKS PASS")
