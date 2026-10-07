# Triangle centres -- the check behind the card.  Nothing is imported.  Farms in km:
# A = (0, 0), B = (8, 0), C = (2, 6).  Each centre is found twice: by its formula, and by
# a blind zoom search for the point with the centre's defining property.  Then an obtuse case.
def dist(p, q): return ((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2) ** 0.5
def side(p, u, v):                        # distance from p to the road u-v,
    cr = (v[0] - u[0]) * (p[1] - u[1]) - (v[1] - u[1]) * (p[0] - u[0])
    return cr / dist(u, v)                # signed: positive on the triangle's side
def zoom(f, x=0.0, y=0.0, w=40.0):        # road two: best point of a 21 x 21 grid,
    for _ in range(70):                   # then a smaller grid round it, repeated
        pts = [(x + w * i / 10, y + w * j / 10) for i in range(-10, 11) for j in range(-10, 11)]
        x, y = min(pts, key=f)
        w *= 0.7
    return (x, y)
def centres(A, B, C):                     # road one: the formulas on the card
    a, b, c = dist(B, C), dist(C, A), dist(A, B)
    G = ((A[0] + B[0] + C[0]) / 3, (A[1] + B[1] + C[1]) / 3)
    (p1, q1, k1), (p2, q2, k2) = [(2 * (Q[0] - A[0]), 2 * (Q[1] - A[1]),  # perpendicular
             Q[0] ** 2 + Q[1] ** 2 - A[0] ** 2 - A[1] ** 2) for Q in (B, C)]  # bisectors
    det = p1 * q2 - q1 * p2                               # Cramer's rule
    O = ((k1 * q2 - q1 * k2) / det, (p1 * k2 - k1 * p2) / det)
    n = a + b + c
    I = ((a * A[0] + b * B[0] + c * C[0]) / n, (a * A[1] + b * B[1] + c * C[1]) / n)
    return (a, b, c), G, O, I

def pt(p): return f"({p[0]:.2f}, {p[1]:.2f})"
def three(xs): return ", ".join(f"{x:.2f}" for x in xs)

A, B, C = (0.0, 0.0), (8.0, 0.0), (2.0, 6.0)
(a, b, c), G, O, I = centres(A, B, C)
K, s = c * (C[1] - A[1]) / 2, (a + b + c) / 2            # AB is level: height is C's rise
roads = lambda p: [side(p, A, B), side(p, B, C), side(p, C, A)]
sq = lambda p: sum(dist(p, F) ** 2 for F in (A, B, C))
G2 = zoom(sq)                                             # least total squared distance
O2 = zoom(lambda p: (dist(p, A) ** 2 - dist(p, B) ** 2) ** 2 + (dist(p, A) ** 2 - dist(p, C) ** 2) ** 2)
I2 = zoom(lambda p: -min(roads(p)))                       # furthest from the nearest road
print(f"farms A {pt(A)}, B {pt(B)}, C {pt(C)} km; sides a = {a:.2f}, b = {b:.2f}, c = {c:.2f} km")
print(f"area K = {K:.2f} km^2; half-perimeter s = {s:.4f} km; r = K / s = {K / s:.4f} km")
print(f"centroid G: by averaging {pt(G)}; by least total squared distance {pt(G2)}")
print(f"circumcentre O: by two bisectors {pt(O)}; by equal-distance search {pt(O2)}")
print(f"incentre I: by side weights {pt(I)}; by furthest-from-roads search {pt(I2)}")
print(f"O to farms A, B, C: {three(dist(O, F) for F in (A, B, C))} km")
print(f"I to roads AB, BC, CA: {three(roads(I))} km; largest pond found: radius {min(roads(I2)):.4f} km")
print(f"G to farms A, B, C: {three(dist(G, F) for F in (A, B, C))} km")
print(f"G to roads AB, BC, CA: {three(roads(G))} km")
print(f"total squared distance to the farms: at G {sq(G):.2f}, at O {sq(O):.2f}, at I {sq(I):.2f}")
A3, B3, C3 = (0.0, 0.0), (8.0, 0.0), (2.0, 2.0)          # second case: an obtuse layout
_, _, O3, _ = centres(A3, B3, C3)
O4 = zoom(lambda p: (dist(p, A3) ** 2 - dist(p, B3) ** 2) ** 2 + (dist(p, A3) ** 2 - dist(p, C3) ** 2) ** 2)
M3 = ((A3[0] + B3[0]) / 2, (A3[1] + B3[1]) / 2)
print(f"obtuse farms {pt(A3)}, {pt(B3)}, {pt(C3)}: O by bisectors {pt(O3)}, by search {pt(O4)}")
print(f"obtuse: O to farms {three(dist(O3, F) for F in (A3, B3, C3))} km; O to road AB {side(O3, A3, B3):.2f} km")
print(f"obtuse: midpoint of AB {pt(M3)} to farms {three(dist(M3, F) for F in (A3, B3, C3))} km")
svg = lambda p: f"({80 + 22 * p[0]:.2f}, {178 - 22 * p[1]:.2f})"
print(f"figure, 1 km = 22 units: A {svg(A)}, B {svg(B)}, C {svg(C)}, G {svg(G)}, O {svg(O)}, I {svg(I)}, "
      f"R {22 * dist(O, A):.2f}, r {22 * K / s:.2f}")
assert dist(G, G2) < 1e-6 and dist(O, O2) < 1e-6 and dist(I, I2) < 1e-6   # two roads each
assert abs(min(roads(I2)) - K / s) < 1e-6                 # largest pond = area / half-perimeter
assert max(dist(O3, F) for F in (A3, B3, C3)) - min(dist(O3, F) for F in (A3, B3, C3)) < 1e-9
assert dist(O3, O4) < 1e-6 and side(O3, A3, B3) < 0      # obtuse: the well leaves the triangle
print("ALL CHECKS PASS")
