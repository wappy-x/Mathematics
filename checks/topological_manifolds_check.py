# Topological manifolds -- the check behind the card.  Standard library only.
# Charts for the circle and the sphere by stereographic projection, checked exactly
# with fractions; the Earth's two polar charts in km; the vertex-link test for a
# triangulated surface, with and without an edge; and the cases that fail.
from fractions import Fraction as F
from math import sin, cos, tan, radians, pi, sqrt

def lift(u):  # inverse of the chart from the top pole: a point u of R^n onto the unit sphere
    s = sum(c * c for c in u)
    return [2 * c / (s + 1) for c in u] + [(s - 1) / (s + 1)]

def from_top(p): return [c / (1 - p[-1]) for c in p[:-1]]     # chart missing the top pole
def from_bottom(p): return [c / (1 + p[-1]) for c in p[:-1]]  # chart missing the bottom pole

def invert(u):  # the transition map, by its formula: u / |u|^2
    s = sum(c * c for c in u)
    return [c / s for c in u]

def show(v): return "(" + ", ".join(str(c) for c in v) + ")"

for name, u in (("S1", [F(1, 2)]), ("S2", [F(1, 2), F(1, 2)])):
    p = lift(u)
    print(f"{name}: u = {show(u)}, |u|^2 = {sum(c * c for c in u)}, lifts to {show(p)}, |p|^2 = {sum(c * c for c in p)}, "
          f"bottom chart {show(from_bottom(p))}, u/|u|^2 = {show(invert(u))}")
for n, grid in ((1, [[F(a, 4)] for a in range(-12, 13) if a]),
                (2, [[F(a, 2), F(b, 2)] for a in range(-6, 7) for b in range(-6, 7) if a or b])):
    on = back = trans = 0
    for u in grid:  # road 1: the formula u/|u|^2; road 2: lift to the sphere, then the other chart
        p = lift(u)
        on += sum(c * c for c in p) == 1
        back += from_top(p) == u
        trans += from_bottom(p) == invert(u)
    print(f"S{n}: {len(grid)} rational points, on the sphere {on}, top chart undoes lift {back}, "
          f"bottom chart equals u/|u|^2 {trans}")
    assert on == back == trans == len(grid)

R = 6371.0  # the Earth as a sphere of radius 6371 km
def earth(lat, lon):
    a, b = radians(lat), radians(lon)
    return [R * cos(a) * cos(b), R * cos(a) * sin(b), R * sin(a)]
def north_map(p): return [R * c / (R + p[2]) for c in p[:2]]  # North Pole at 0; misses the South Pole
def south_map(p): return [R * c / (R - p[2]) for c in p[:2]]  # South Pole at 0; misses the North Pole

P = earth(51.5074, -0.1278)  # London
a, b = north_map(P), south_map(P)
ra, rb = sqrt(a[0] ** 2 + a[1] ** 2), sqrt(b[0] ** 2 + b[1] ** 2)
print(f"London 51.5074 N, 0.1278 W, in space: ({P[0]:.1f}, {P[1]:.1f}, {P[2]:.1f}) km")
print(f"half-latitude {51.5074 / 2:.4f}; tan({45 - 51.5074 / 2:.4f}) = {tan(radians(45 - 51.5074 / 2)):.6f}, "
      f"tan({45 + 51.5074 / 2:.4f}) = {tan(radians(45 + 51.5074 / 2)):.6f}")
print(f"north map: ({a[0]:.1f}, {a[1]:.1f}) km, {ra:.1f} km from the centre; "
      f"by R tan(45 - lat/2): {R * tan(radians(45 - 51.5074 / 2)):.1f}")
print(f"south map: ({b[0]:.1f}, {b[1]:.1f}) km, {rb:.1f} km from the centre; "
      f"by R tan(45 + lat/2): {R * tan(radians(45 + 51.5074 / 2)):.1f}")
t = [R * R * c / (ra * ra) for c in a]  # the transition map R^2 u / |u|^2
print(f"transition R^2 u/|u|^2 from the north map: ({t[0]:.1f}, {t[1]:.1f}) km; "
      f"product of distances {ra * rb:.0f} = R^2 {R * R:.0f}")
assert abs(t[0] - b[0]) < 1e-6 and abs(t[1] - b[1]) < 1e-6 and abs(ra * rb - R * R) < 1e-3
assert abs(ra - R * tan(radians(45 - 51.5074 / 2))) < 1e-6
r0 = R * tan(radians(45 - 66.56 / 2))
eq = north_map(earth(0, 30))
print(f"north map: equator at radius {sqrt(eq[0] ** 2 + eq[1] ** 2):.1f}, Arctic Circle (66.56 N) at {r0:.1f}")

def components(nodes, links):  # pieces of a small graph, by repeated merging
    group = {v: v for v in nodes}
    def top(v):
        while group[v] != v:
            v = group[v]
        return v
    for x, y in links:
        group[top(x)] = top(y)
    return len({top(v) for v in nodes})

def manifold_test(faces):  # every edge in 1 or 2 faces; every vertex link one cycle or one path
    count = {}
    for f in faces:
        for e in ((f[0], f[1]), (f[0], f[2]), (f[1], f[2])):
            e = tuple(sorted(e))
            count[e] = count.get(e, 0) + 1
    inner = sum(1 for c in count.values() if c == 2)
    edge = sum(1 for c in count.values() if c == 1)
    worse = sum(1 for c in count.values() if c > 2)
    kinds = {"disc": 0, "half-disc": 0, "neither": 0}
    bad = []
    for v in sorted({v for f in faces for v in f}):
        link = [tuple(x for x in f if x != v) for f in faces if v in f]
        nodes = sorted({x for e in link for x in e})
        deg = [sum(x in e for e in link) for x in nodes]
        pieces = components(nodes, link)
        if pieces == 1 and all(d == 2 for d in deg):
            kinds["disc"] += 1
        elif pieces == 1 and deg.count(1) == 2 and deg.count(2) == len(deg) - 2:
            kinds["half-disc"] += 1
        else:
            kinds["neither"] += 1
            bad.append(f"vertex {v}: link has {pieces} pieces, {len(link)} edges")
    return len(count), inner, edge, worse, kinds, bad

# The Earth as an octahedron: vertex 0 North Pole, 1 South Pole, 2..5 the equator at 0, 90E, 180, 90W.
octa = [(pole, 2 + i, 2 + (i + 1) % 4) for pole in (0, 1) for i in range(4)]
north_half = [f for f in octa if f[0] == 0]
two_globes = octa + [(0 if pole == 0 else 11, 12 + i, 12 + (i + 1) % 4) for pole in (0, 1) for i in range(4)]
for name, faces, want in (("octahedron", octa, (12, 12, 0, 0, 6, 0, 0)),
                          ("northern half", north_half, (8, 4, 4, 0, 1, 4, 0)),
                          ("two globes touching at the pole", two_globes, (24, 24, 0, 0, 10, 0, 1))):
    e, inner, edge, worse, k, bad = manifold_test(faces)
    print(f"{name}: {len(faces)} faces, {e} edges ({inner} in two faces, {edge} in one, {worse} in more); "
          f"vertices: {k['disc']} disc, {k['half-disc']} half-disc, {k['neither']} neither")
    for line in bad:
        print("  " + line)
    assert (e, inner, edge, worse, k["disc"], k["half-disc"], k["neither"]) == want

# What breaks: one chart for the whole circle by angle in [0, 2 pi); and the doubled origin.
t1, t2 = 0.001, 2 * pi - 0.001
gap = sqrt((cos(t1) - cos(t2)) ** 2 + (sin(t1) - sin(t2)) ** 2)
print(f"wrap chart: points at angles {t1} and {t2:.6f} are {gap:.6f} apart on the circle, "
      f"{t2 - t1:.6f} apart in the chart")
assert abs(gap - 2 * sin(0.001)) < 1e-12 and t2 - t1 > 6
x = [1 / k for k in (10, 100, 1000)]
print("doubled origin: 1/k for k = 10, 100, 1000 lies " + ", ".join(f"{v:.3f}" for v in x) +
      " from origin A and the same from origin B; both are limits")
p, w = lift([F(1, 2)]), from_bottom(lift([F(1, 2)]))[0]
print(f"figure, unit 100 px, centre (240,140): N (240,40) S (240,240) P ({240 + 100 * p[0]},{140 - 100 * p[1]}) "
      f"u ({240 + 100 * F(1, 2)},140) w ({240 + 100 * w},140)")
print("ALL CHECKS PASS")
