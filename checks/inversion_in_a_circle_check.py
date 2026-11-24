# Inversion in a circle -- the check behind the card.  Standard library only.
# Mirror: the unit circle, centre O = (0, 0), radius r = 1.  P goes to P' on the
# ray from O through P, with OP x OP' = r^2.  Images are reached by separate roads:
# the coordinate rule, the complex rule r^2/conj(z), the tangent construction,
# a circle through three image points, and brute force over thousands of points.
from math import sqrt, hypot, atan2, degrees, cos, sin, pi
R = 1.0
def inv(p): s = p[0] ** 2 + p[1] ** 2; return (R * R * p[0] / s, R * R * p[1] / s)  # road 1
def inv_c(p): w = R * R / complex(p[0], -p[1]); return (w.real, w.imag)             # road 2
def inv_t(p):                   # road 3: square up from P to T on the mirror; the tangent at T meets the ray
    d = hypot(*p); u = (p[0] / d, p[1] / d); h = sqrt(R * R - d * d)
    t = (d * u[0] - h * u[1], d * u[1] + h * u[0])
    k = (t[0] ** 2 + t[1] ** 2) / (t[0] * u[0] + t[1] * u[1]); return (k * u[0], k * u[1])
def dist(a, b): return hypot(a[0] - b[0], a[1] - b[1])
def circle3(a, b, c):           # the circle through three points: centre, radius
    (ax, ay), (bx, by), (cx, cy) = a, b, c; sa, sb, sc = ax*ax + ay*ay, bx*bx + by*by, cx*cx + cy*cy
    dd = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    o = ((sa * (by - cy) + sb * (cy - ay) + sc * (ay - by)) / dd, (sa * (cx - bx) + sb * (ax - cx) + sc * (bx - ax)) / dd)
    return o, dist(o, a)
def angle(u, v): return abs(degrees(atan2(u[0] * v[1] - u[1] * v[0], u[0] * v[0] + u[1] * v[1])))
def img_dir(p, e, h=1e-6):      # direction of an image curve at P', by a tiny step either side of P
    a, b = inv((p[0] + h * e[0], p[1] + h * e[1])), inv((p[0] - h * e[0], p[1] - h * e[1])); return (a[0] - b[0], a[1] - b[1])
def worst(pts, c, rad): return max(abs(dist(q, c) - rad) for q in pts)
def f(p): return f"({p[0]:.6f}, {p[1]:.6f})"
P, Q, B, Pi = (0.5, 0.0), (0.5, 0.5), (0.0, 0.5), inv((0.5, 0.0))
for n, p in (("P", P), ("Q", Q)):
    print(f"{n} ({p[0]:.1f}, {p[1]:.1f}) -> {f(inv(p))} rule, {f(inv_c(p))} 1/conj(z), {f(inv_t(p))} tangent; product {hypot(*p) * hypot(*inv(p)):.6f}")
Fi = inv(P); c1, r1 = (Fi[0] / 2, Fi[1] / 2), hypot(*Fi) / 2                          # Thales: diameter O to F'
line_pts = [inv((0.5, y / 20)) for y in range(-1000, 1001) if y != 0] + [Pi]
print(f"line x = 0.5 -> circle centre {f(c1)}, radius {r1:.6f}; 2001 image points, worst miss {worst(line_pts, c1, r1):.9f}")
F2 = inv((0.25, -0.25)); c2, r2 = (F2[0] / 2, F2[1] / 2), hypot(*F2) / 2               # line y = x - 0.5
perp = lambda c: (-(Pi[1] - c[1]), Pi[0] - c[0])
a0, a1, a2 = angle((0, 1), (1, 1)), angle(img_dir(P, (0, 1)), img_dir(P, (1, 1))), angle(perp(c1), perp(c2))
print(f"line y = x - 0.5 -> circle centre {f(c2)}, radius {r2:.6f}")
print(f"angle at P {a0:.6f}; at P' by tiny steps {a1:.6f}, by the two image circles {a2:.6f}")
pq, rule = dist(inv(P), inv(Q)), R * R * dist(P, Q) / (hypot(*P) * hypot(*Q))
print(f"P'Q' measured {pq:.6f}; by r^2 PQ / (OP OQ) = 0.5 / (0.5 x {hypot(*Q):.6f}) = {rule:.6f}")
g, rg = circle3(P, Pi, B); pw = g[0] ** 2 + g[1] ** 2 - rg * rg
s = (g[0] ** 2 + g[1] ** 2 + R * R - rg * rg) / 2; m = sqrt(R * R - s * s / (g[0] ** 2 + g[1] ** 2))
X = (s * g[0] / (g[0] ** 2 + g[1] ** 2) + m * g[1] / hypot(*g), s * g[1] / (g[0] ** 2 + g[1] ** 2) - m * g[0] / hypot(*g))
cross = angle(X, (X[0] - g[0], X[1] - g[1]))
ring = [inv((g[0] + rg * cos(pi * k / 1000), g[1] + rg * sin(pi * k / 1000))) for k in range(2000)]
print(f"circle through P, P', B: centre {f(g)}, radius {rg:.6f}; power of O {g[0] ** 2 + g[1] ** 2:.6f} - {rg * rg:.6f} = {pw:.6f}")
print(f"it crosses the mirror at {f(X)} at {cross:.6f} degrees; B' = {f(inv(B))}, miss {abs(dist(inv(B), g) - rg):.9f}")
print(f"2000 points of it inverted: worst miss {worst(ring, g, rg):.9f}")
k_, pw3 = (1.5, 0.0), 1.5 ** 2 - 0.5 ** 2; c3, r3 = (R * R * 1.5 / pw3, 0.0), R * R * 0.5 / pw3
c4, r4 = circle3(inv((1.0, 0.0)), inv((2.0, 0.0)), inv((1.5, 0.5)))
print(f"circle centre (1.5, 0), radius 0.5: power {pw3:.6f}; image by scaling {f(c3)} r {r3:.6f}, by 3 points {f(c4)} r {r4:.6f}")
wz = 1 / complex(*Q)
print(f"mistake 1, inverted centre {f(inv(k_))} is not the image centre {f(c3)}")
print(f"mistake 2, x = 0.5 sent to the line x = 2: Q' = {f(inv(Q))} is {abs(inv(Q)[0] - 2):.6f} off it")
print(f"mistake 3, 1/z for 1/conj(z): Q goes to {f((wz.real, wz.imag))}, the flip of Q'")
sc = lambda p: f"({100 + 80 * p[0]:.1f}, {250 - 80 * p[1]:.1f})"
print("figure, O (100, 250), 1 = 80 units; P", sc(P), "P'", sc(Pi), "Q", sc(Q), "Q'", sc(inv(Q)), "B", sc(B), "B'", sc(inv(B)),
      "circles", sc(c1), f"r {80 * r1:.1f};", sc(g), f"r {80 * rg:.1f}; crossings", sc(X), sc((X[1], X[0])))
assert all(dist(inv(p), inv_c(p)) < 1e-12 and dist(inv(p), inv_t(p)) < 1e-12 for p in (P, Q, B))   # three roads
assert worst(line_pts, c1, r1) < 1e-9 and worst(ring, g, rg) < 1e-9 and abs(pw - R * R) < 1e-12  # line -> circle; fixed
assert abs(a1 - a0) < 1e-6 and abs(a2 - a0) < 1e-9 and abs(cross - 90) < 1e-9 and abs(pq - rule) < 1e-12
assert dist(c3, c4) < 1e-12 and abs(r3 - r4) < 1e-12 and dist(inv(k_), c3) > 0.08            # circle -> circle
print("ALL CHECKS PASS")
