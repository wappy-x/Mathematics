# Scissors congruence and the Dehn invariant -- the check behind the card.  Standard library only.
from itertools import combinations
from math import acos, cos, pi, sqrt
s, th = sqrt(6), acos(1 / 3)                      # square side; tetrahedron's dihedral angle
def f6(v): return f"{v:.6f}"
def yn(c): return "yes" if c else "no"
def area(P): return sum(P[i - 1][0] * P[i][1] - P[i][0] * P[i - 1][1] for i in range(len(P))) / 2
def inside(P, x, y): return all((b[0] - a[0]) * (y - a[1]) > (b[1] - a[1]) * (x - a[0]) for a, b in zip(P, P[1:] + P[:1]))
before = [[(0, 0), (s, 0), (0, 2)],                           # T: stays put
          [(0, 2), (3 - s, 4 - s), (3 - s, 2)],               # O: small overhang
          [(s, 0), (3, 0), (1.5, 2), (3 - s, 2), (3 - s, 4 - s)],  # Q: rest of the bottom strip
          [(0, 2), (1.5, 2), (0, 4)]]                         # R: top of the triangle
moves = [lambda x, y: (x, y), lambda x, y: (x + 2 * s - 3, y + s - 4),
         lambda x, y: (x + s - 3, y + s - 2), lambda x, y: (s - x, s + 2 - y)]
after = [[m(x, y) for x, y in P] for P, m in zip(before, moves)]
def once(pieces, w, h, region, n=300):                        # grid points covered exactly once
    pts = [((i + .5) * w / n, (j + .25) * h / n) for i in range(n) for j in range(n)]
    return all(sum(inside(P, x, y) for P in pieces) == region(x, y) for x, y in pts)
tri_ok, sq_ok = once(before, 3, 4, lambda x, y: 4 * x + 3 * y < 12), once(after, s, s, lambda x, y: True)
print(f"triangle 3 m by 4 m, area {f6(area([(0, 0), (3, 0), (0, 4)]))}; square side root 6 = {f6(s)} m")
print("piece areas before:", ", ".join(f6(area(P)) for P in before), "| after:", ", ".join(f6(area(P)) for P in after))
print(f"grid 300 x 300: triangle covered exactly once: {yn(tri_ok)}; square covered exactly once: {yn(sq_ok)}")
print(f"figure, 1 m = 40 units: mid-line (0, 2) to ({3 / 2}, 2); cut (0, 2) to ({f6(s)}, 0); slide ({f6(s - 3)}, {f6(s - 2)}); overhang corner ({f6(3 - s)}, {f6(4 - s)}); SVG cut end ({40 + 40 * s:.2f}, 200), overhang corner ({40 + 40 * (3 - s):.2f}, {200 - 40 * (4 - s):.2f}), square top right ({240 + 40 * s:.2f}, {200 - 40 * s:.2f})")
def sub(a, b): return [a[k] - b[k] for k in range(3)]
def dot(a, b): return sum(a[k] * b[k] for k in range(3))
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
def edges(V):                                                 # (length, dihedral angle) of each edge
    faces = {}
    for i, j, k in combinations(range(len(V)), 3):           # a face: a plane with every corner on one side
        n = cross(sub(V[j], V[i]), sub(V[k], V[i])); d = [dot(n, sub(p, V[i])) for p in V]
        if max(d) > 1e-9: n, d = [-c for c in n], [-c for c in d]
        if dot(n, n) > 1e-12 and max(d) < 1e-9:
            faces[frozenset(m for m in range(len(V)) if abs(d[m]) < 1e-9)] = [c / sqrt(dot(n, n)) for c in n]
    return [(sqrt(dot(sub(V[min(e)], V[max(e)]), sub(V[min(e)], V[max(e)]))), pi - acos(max(-1, min(1, dot(faces[f], faces[g])))))
            for f, g in combinations(faces, 2) if len(e := f & g) == 2]
def score(a):                     # f: the r with a - r th a rational multiple of pi, so f(pi) = 0 and f(th) = 1
    return next(r for r in [k / 2 for k in range(-4, 5)] if any(abs((a - r * th) / pi * q - round((a - r * th) / pi * q)) < 1e-9 for q in range(1, 13)))
def dehn(V): return sum(l * score(a) for l, a in edges(V))
def raw(V): return sum(l * a for l, a in edges(V))
cube = [(x, y, z) for x in (0, 1) for y in (0, 1) for z in (0, 1)]; prisms = [[p for p in cube if p[0] >= p[1]], [p for p in cube if p[0] <= p[1]]]
e = (6 * sqrt(2)) ** (1 / 3); k = e / (2 * sqrt(2))           # tetrahedron edge for volume 1 m^3
A, B, C, D = [(k * a, k * b, k * c) for a, b, c in [(1, 1, 1), (1, -1, -1), (-1, 1, -1), (-1, -1, 1)]]
M = tuple((C[i] + D[i]) / 2 for i in range(3)); vol = abs(dot(sub(B, A), cross(sub(C, A), sub(D, A)))) / 6
an = [1, 1]
for n in range(60): an.append(2 * an[-1] - 9 * an[-2])        # a_n = 3^n cos(n th), by the recurrence
print(f"cube 1 m: {len(edges(cube))} edges, dihedral angles all {f6(max(a for _, a in edges(cube)) * 180 / pi)} deg, Dehn {f6(dehn(cube))}")
print(f"tetrahedron edge {f6(e)} m, volume {f6(vol)} m^3 (formula {f6(e ** 3 / (6 * sqrt(2)))}), dihedral {th * 180 / pi:.6f} deg")
print(f"tetrahedron Dehn {f6(dehn([A, B, C, D]))} = 6 x edge {f6(6 * e)}")
print(f"a_n, n = 0..8, by recurrence {an[:9]}; by 3^n cos(n th) {[round(3 ** n * cos(n * th)) for n in range(9)]}")
print(f"any of a_0 .. a_61 divisible by 3: {yn(any(a % 3 == 0 for a in an))}")
print(f"cut in two: tetrahedron halves Dehn {f6(dehn([A, B, C, M]))} + {f6(dehn([A, B, D, M]))}; cube prisms {f6(dehn(prisms[0]))} + {f6(dehn(prisms[1]))}")
print(f"mistake 1, raw sum length x angle: cube {f6(raw(cube))}, its two prisms {f6(raw(prisms[0]) + raw(prisms[1]))}")
print(f"mistake 2, face angle 60 deg in place of {th * 180 / pi:.6f}: score {score(pi / 3):.0f}, so Dehn 0 like the cube")
print(f"mistake 3, th taken as 72 deg: score {score(2 * pi / 5):.0f}, so Dehn 0 like the cube; true 5 x th = {5 * th * 180 / pi:.6f} deg, cos = {an[5]}/{3 ** 5} = {f6(an[5] / 3 ** 5)}")
assert tri_ok and sq_ok and abs(sum(map(area, after)) - 6) < 1e-12
assert all(abs(3 ** n * cos(n * th) - an[n]) < 1e-6 for n in range(12)) and all(a % 3 for a in an)
assert abs(vol - 1) < 1e-12 and abs(dehn(cube)) < 1e-12 and abs(dehn(prisms[0]) + dehn(prisms[1])) < 1e-12
assert abs(dehn([A, B, C, D]) - 6 * e) < 1e-9 and abs(dehn([A, B, C, M]) + dehn([A, B, D, M]) - 6 * e) < 1e-9
assert abs(raw(cube) - 6 * pi) < 1e-9 and abs(raw(prisms[0]) + raw(prisms[1]) - (6 + 2 * sqrt(2)) * pi) < 1e-9
print("ALL CHECKS PASS")
