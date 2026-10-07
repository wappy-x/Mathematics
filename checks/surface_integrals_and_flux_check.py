# Surface integrals -- the check behind the card.  Tarp z = 0.75y over the ground
# rectangle 4 m by 3 m; rain F = (0, w, -0.01) metres of water per hour.  Road one
# adds |N| and F.N over small ground cells.  Road two forms no cross product:
# Pythagoras, a triangle mesh measured by Heron's formula, the shadow along the rain.
from math import sqrt

def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def dot(a, b): return sum(p * q for p, q in zip(a, b))
def flat(x, y): return 0.75 * y                                    # the tarp pulled taut
def sag(x, y): return 0.75 * y - 0.05 * x * (4 - x) * y * (3 - y)  # the same edges, sagging
WINDS = (("still air", 0.0), ("blown north", 0.005), ("blown south", -0.005))

def road_one(z, n=200, h=1e-5):             # midpoint sums; tangents by central differences
    area, flux, cell = 0.0, [0.0] * 3, (4 / n) * (3 / n)
    for i in range(n):
        for j in range(n):
            x, y = (i + 0.5) * 4 / n, (j + 0.5) * 3 / n
            N = cross((1, 0, (z(x + h, y) - z(x - h, y)) / (2 * h)), (0, 1, (z(x, y + h) - z(x, y - h)) / (2 * h)))
            area += sqrt(dot(N, N)) * cell
            for k, (_, w) in enumerate(WINDS): flux[k] += dot((0, w, -0.01), N) * cell
    return area, flux

def heron(p, q, s):                          # triangle area from its three side lengths
    a, b, c = (sqrt(sum((m - k) ** 2 for m, k in zip(P, Q))) for P, Q in ((p, q), (q, s), (s, p)))
    t = (a + b + c) / 2; return sqrt(max(t * (t - a) * (t - b) * (t - c), 0.0))

def road_two(z, n):                          # triangle mesh through points on the sheet
    P = lambda i, j: (4 * i / n, 3 * j / n, z(4 * i / n, 3 * j / n))
    return sum(heron(P(i, j), P(i + 1, j), P(i + 1, j + 1)) + heron(P(i, j), P(i + 1, j + 1), P(i, j + 1))
               for i in range(n) for j in range(n))

def shadow(z, w, m=400):                     # the edge, slid down the rain onto the ground; shoelace area
    edge = [(4 * k / m, 0) for k in range(m)] + [(4, 3 * k / m) for k in range(m)]
    edge += [(4 - 4 * k / m, 3) for k in range(m)] + [(0, 3 - 3 * k / m) for k in range(m)]
    pts = [(x, y + (w / 0.01) * z(x, y)) for x, y in edge]
    return abs(sum(p[0] * q[1] - q[0] * p[1] for p, q in zip(pts, pts[1:] + pts[:1]))) / 2

def vec(v): return "(" + ", ".join(f"{c:.2f}" for c in v) + ")"
N0 = cross((1, 0, 0), (0, 1, 0.75))                 # the taut tarp's area vector, exact
print(f"flat tarp: r_u = (1, 0, 0), r_v = (0, 1, 0.75), N = {vec(N0)}, |N| = {sqrt(dot(N0, N0)):.2f}")
A1, F1 = road_one(flat)
print(f"flat area: cross-product sum {A1:.6f} m^2; Pythagoras 4 x {sqrt(9 + 2.25 ** 2):.2f} = {4 * sqrt(9 + 2.25 ** 2):.6f} m^2")
for (name, w), f in zip(WINDS, F1):
    s = shadow(flat, w)
    print(f"flat, {name}: F.N = {1000 * dot((0, w, -0.01), N0):.2f} mm/h, sum {1000 * f:.3f} L/h; "
          f"shadow {s / 4:.3f} m deep, {s:.4f} m^2 x 10 mm/h = {10 * s:.3f} L/h")
    assert abs(1000 * f + 10 * s) < 1e-6                     # road one meets the shadow
print(f"slant chart: N = {vec(cross((1, 0, 0), (0, 0.8, 0.6)))}, area 4 x 3.75 = {4 * 3.75:.2f} m^2, still air {1000 * 15 * dot((0, 0, -0.01), cross((1, 0, 0), (0, 0.8, 0.6))):.3f} L/h")
(A2, F2), mesh = road_one(sag), [road_two(sag, n) for n in (10, 40, 160)]
print(f"sagging tarp, {0.75 * 1.5 - sag(2, 1.5):.2f} m deep at centre: cross-product sum {A2:.6f} m^2")
print("sagging area, Heron mesh 10, 40, 160 per side: " + ", ".join(f"{a:.6f}" for a in mesh))
print("sagging flux, L/h: " + ", ".join(f"{n} {1000 * f:.3f}" for (n, _), f in zip(WINDS, F2)))
print(f"mistake, ground area for tarp area: {12:.2f} m^2, not {A1:.2f}; rain rate x tarp area: {10 * A1:.3f} L/h, not {-1000 * F1[0]:.3f}")
print(f"mistake, unit normal with ground cells: {1000 * 12 * 0.01 / 1.25:.3f} L/h, not {-1000 * F1[0]:.3f}")
print(f"mistake, r_v x r_u (normal points down): {1000 * dot((0, 0, -0.01), cross((0, 1, 0.75), (1, 0, 0))) * 12:.3f} L/h")
print(f"figure, 60 px per m: tarp (40, 200) to ({40 + 60 * 3:.1f}, {200 - 60 * 2.25:.1f}); shadow ends at {40 + 60 * 3 * 1.375:.1f}; normal ({40 + 60 * 1.5:.1f}, {200 - 60 * 1.125:.1f}) to ({130 - 50 * 0.6:.1f}, {132.5 - 50 * 0.8:.1f})")
assert abs(A1 - 4 * sqrt(9 + 2.25 ** 2)) < 1e-6                 # cross product meets Pythagoras
assert abs(A2 - mesh[-1]) < 1e-3                                 # two roads to the curved area
assert all(abs(1000 * f + 10 * shadow(sag, w)) < 1e-3 for (_, w), f in zip(WINDS, F2))
print("ALL CHECKS PASS")
