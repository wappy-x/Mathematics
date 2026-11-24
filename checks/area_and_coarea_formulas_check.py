# Area and coarea formulas -- the check behind the card.  Standard library only.
# Every area is reached by roads that do not share a formula: the Jacobian
# integrated by Simpson's rule, a closed form, and a mesh of flat triangles
# whose areas come from cross products, with no Jacobian anywhere.
from math import sqrt, pi, sin, cos

def gram_jf(cols):                     # Jf = sqrt(det(Df^T Df)) for two columns
    a, b = cols
    aa = sum(x * x for x in a); bb = sum(x * x for x in b); ab = sum(x * y for x, y in zip(a, b))
    return sqrt(aa * bb - ab * ab)

def minors_sq(a, b):                   # sum of squared 2x2 minors (Cauchy-Binet)
    return sum((a[i] * b[j] - a[j] * b[i]) ** 2 for i in range(3) for j in range(i + 1, 3))

def det3(m):
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def simpson(g, a, b, n=2000):
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n))
    return s * h / 3

def tri(p, q, r):                      # area of a flat triangle in space
    u = [q[i] - p[i] for i in range(3)]; v = [r[i] - p[i] for i in range(3)]
    c = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    return 0.5 * sqrt(c[0] ** 2 + c[1] ** 2 + c[2] ** 2)

def mesh(f, a0, a1, b0, b1, na, nb):   # triangle-mesh area of f over a rectangle of parameters
    pts = [[f(a0 + (a1 - a0) * i / na, b0 + (b1 - b0) * j / nb) for j in range(nb + 1)] for i in range(na + 1)]
    return sum(tri(pts[i][j], pts[i + 1][j], pts[i + 1][j + 1]) + tri(pts[i][j], pts[i + 1][j + 1], pts[i][j + 1])
               for i in range(na) for j in range(nb))

def show(label, x):
    print(f"{label:<48}{x:>12.6f}")

dish = lambda r, t, c=1.0: (r * cos(t), r * sin(t), c * r * r)      # z = c(x^2 + y^2) over the unit disc
dish_cols = lambda x, y, c=1.0: ((1.0, 0.0, 2 * c * x), (0.0, 1.0, 2 * c * y))
def dish_area(c):
    return 2 * pi * simpson(lambda r: gram_jf(dish_cols(r, 0.0, c)) * r, 0.0, 1.0)

a, b = dish_cols(0.3, 0.4)
gm = [[sum(p * q for p, q in zip(u, v)) for v in (a, b)] for u in (a, b)]
print("Df^T Df at (0.3, 0.4)" + " " * 21 + " ".join(f"{x:.2f}" for x in gm[0] + gm[1]))
print("2x2 minors of Df at (0.3, 0.4)" + " " * 16 + " ".join(f"{a[i] * b[j] - a[j] * b[i]:.2f}" for i, j in [(0, 1), (0, 2), (1, 2)]))
g = gram_jf((a, b)); show("Jf at (0.3, 0.4): det(Df^T Df)", g * g)
show("Jf at (0.3, 0.4): sum of squared minors", minors_sq(a, b))
show("Jf at (0.3, 0.4)", g)
assert abs(g - sqrt(1 + 4 * 0.25)) < 1e-12 and abs(g * g - minors_sq(a, b)) < 1e-12
big = abs(det3([[a[i] * a[j] + b[i] * b[j] for j in range(3)] for i in range(3)]))   # the wrong 3 by 3
closed = pi / 6 * (5 * sqrt(5) - 1)
by_jf, by_mesh = dish_area(1.0), mesh(dish, 0.0, 1.0, 0.0, 2 * pi, 200, 400)
show("5 sqrt5 - 1", 5 * sqrt(5) - 1); show("pi/6", pi / 6)
show("dish area, closed form (pi/6)(5 sqrt5 - 1)", closed)
show("dish area, Simpson on Jf in polar", by_jf)
show("dish area, mesh of 160000 flat triangles", by_mesh)
show("dish area / flat disc", by_jf / pi)
assert abs(by_jf - closed) < 1e-9 and abs(by_mesh - closed) < 2e-3

sph = lambda p, t: (sin(p) * cos(t), sin(p) * sin(t), cos(p))
sph_jf = lambda p: gram_jf(((cos(p), 0.0, -sin(p)), (0.0, sin(p), 0.0)))   # columns at angle t = 0
s_jf, s_mesh = 2 * pi * simpson(sph_jf, 0.0, pi), mesh(sph, 0.0, pi, 0.0, 2 * pi, 200, 400)
show("sphere area, 4 pi", 4 * pi)
show("sphere area, Simpson on Jf = sin(phi)", s_jf)
show("sphere area, mesh of 160000 flat triangles", s_mesh)
assert abs(s_jf - 4 * pi) < 1e-9 and abs(s_mesh - 4 * pi) < 2e-3

cone = lambda r, t: (r * cos(t), r * sin(t), r)                    # z = |x|: Lipschitz, no slope at 0
c_jf = 2 * pi * simpson(lambda r: gram_jf(((1.0, 0.0, 1.0), (0.0, 1.0, 0.0))) * r, 0.0, 1.0)
c_mesh = mesh(cone, 0.0, 1.0, 0.0, 2 * pi, 200, 400)
show("cone area, sqrt2 pi", sqrt(2) * pi)
show("cone area, Simpson on Jf = sqrt2", c_jf)
show("cone area, mesh of 160000 flat triangles", c_mesh)
assert abs(c_jf - sqrt(2) * pi) < 1e-9 and abs(c_mesh - sqrt(2) * pi) < 2e-3

def seg_len(p, q, t):                  # length of {p x + q y = t} inside the unit square
    lo, hi = max(0.0, (t - q) / p), min(1.0, t / p)
    return max(0.0, hi - lo) * sqrt(1 + (p / q) ** 2)
def coarea_linear(p, q):               # breaks at q and p, so Simpson is exact piece by piece
    return sum(simpson(lambda t: seg_len(p, q, t), u, v, 20) for u, v in [(0, p), (p, q), (q, p + q)])
show("linear u = 3x + 4y: |grad u| x area", sqrt(3 * 3 + 4 * 4) * 1.0)
show("linear u = 3x + 4y: integral of level lengths", coarea_linear(3.0, 4.0))
show("linear u = 5x + 12y: integral of level lengths", coarea_linear(5.0, 12.0))
assert abs(coarea_linear(3.0, 4.0) - 5.0) < 1e-12 and abs(coarea_linear(5.0, 12.0) - 13.0) < 1e-12

n = 1000; h = 2.0 / n; cnt = 0; gsum = 0.0
for i in range(n):
    for j in range(n):
        x, y = -1 + (i + 0.5) * h, -1 + (j + 0.5) * h
        if x * x + y * y < 1:
            cnt += 1; gsum += 2 * sqrt(x * x + y * y)
poly = lambda t, k=1000: sum(sqrt((t * cos(2 * pi * (i + 1) / k) - t * cos(2 * pi * i / k)) ** 2
                                  + (t * sin(2 * pi * (i + 1) / k) - t * sin(2 * pi * i / k)) ** 2) for i in range(k))
show("u = |x|: integral of |grad u| = 1, grid count", cnt * h * h)
show("u = |x|: integral of circle lengths 2 pi t", simpson(lambda t: 2 * pi * t, 0.0, 1.0))
show("u = |x|: integral of 1000-gon perimeters", simpson(poly, 0.0, 1.0, 40))
assert abs(cnt * h * h - pi) < 1e-3 and abs(simpson(poly, 0.0, 1.0, 40) - pi) < 1e-4
lhs = 2 * pi * simpson(lambda r: 2 * r * r, 0.0, 1.0)
rhs = simpson(lambda t: 2 * pi * sqrt(t), 0.0, 1.0, 200000)
show("u = x^2 + y^2: integral of |grad u| = 2r, polar", lhs)
show("u = x^2 + y^2: integral of |grad u|, grid", gsum * h * h)
show("u = x^2 + y^2: integral of contour lengths", rhs)
m = 200; cmap = sum(poly(sqrt((k + 0.5) / m)) / (2 * sqrt((k + 0.5) / m)) for k in range(m)) / m
show("contour map: integral of length / |grad u|", cmap)
assert abs(cmap - pi) < 1e-4 and abs(lhs - 4 * pi / 3) < 1e-9 and abs(rhs - lhs) < 1e-5 and abs(gsum * h * h - lhs) < 1e-3

print("chart, lengths of {|x| = t}   " + " ".join(f"{2 * pi * k / 10:.2f}" for k in range(11)))
print("chart, lengths of {r^2 = t}   " + " ".join(f"{2 * pi * sqrt(k / 10):.2f}" for k in range(11)))
wrong = [("break, no Jacobian (shadow area)", pi), ("break, Jf = 1 + |grad h|", 2 * pi * simpson(lambda r: (1 + 2 * r) * r, 0.0, 1.0)),
         ("break, det(Df Df^T), 3 by 3, at (0.3, 0.4)", big), ("break, unnormalised H^2 (x 4/pi)", closed * 4 / pi),
         ("break, angle run twice round", 2 * dish_area(1.0)), ("break, contour lengths added, no |grad u|", rhs)]
show("4/pi, the Hausdorff card's area constant", 4 / pi)
for label, v in wrong:
    show(label, v)
assert big < 1e-12 and abs(wrong[1][1] - 7 * pi / 3) < 1e-9
show("try, dish z = 2(x^2 + y^2), Simpson on Jf", dish_area(2.0))
show("try, dish z = 2(x^2 + y^2), closed form", pi / 24 * (17 * sqrt(17) - 1))
show("try, dish mesh starved to 10 x 20", mesh(dish, 0.0, 1.0, 0.0, 2 * pi, 10, 20))
print("ALL CHECKS PASS")
