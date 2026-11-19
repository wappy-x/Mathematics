# Sphere, plane and hyperbolic space -- the check behind the card.  Standard library only.
# One length rule, ds = 2|dx| / (1 + k r^2), with k = +1, 0, -1: sphere, plane, Poincare disc.
# Roads: curvature in two charts; a disc side drawn by mirror-and-circle, by a formula, by RK4
# and by a Moebius move; angle excess against area summed on a grid.
from math import sqrt, log, sin, cos, acos, atan2, pi, sinh, cosh, asinh, tanh
DEG = 180 / pi
def lam(k, x, y): return 2 / (1 + k * (x * x + y * y))      # the length factor of the chart
def K_disc(k, x, y, h):                                      # K = -(Laplacian of ln lam) / lam^2
    L = lambda u, v: log(lam(k, u, v))
    lap = (L(x + h, y) + L(x - h, y) + L(x, y + h) + L(x, y - h) - 4 * L(x, y)) / (h * h)
    return -lap / lam(k, x, y) ** 2
def K_polar(f, r, h): return -(f(r + h) - 2 * f(r) + f(r - h)) / (h * h) / f(r)   # K = -f''/f
def sub(p, q): return (p[0] - q[0], p[1] - q[1])
def dot(p, q): return p[0] * q[0] + p[1] * q[1]
def circle3(p, q, s):                                        # circle through three points, two linear equations
    a1, b1 = 2 * (q[0] - p[0]), 2 * (q[1] - p[1]); c1 = dot(q, q) - dot(p, p)
    a2, b2 = 2 * (s[0] - p[0]), 2 * (s[1] - p[1]); c2 = dot(s, s) - dot(p, p)
    det = a1 * b2 - a2 * b1; c = ((c1 * b2 - c2 * b1) / det, (a1 * c2 - a2 * c1) / det)
    return c, sqrt(dot(sub(p, c), sub(p, c)))
def tangent(c, p, q):                                        # direction leaving p along the circle centred c, toward q
    t = (-(p[1] - c[1]), p[0] - c[0]); n = sqrt(dot(t, t))
    return (t[0] / n, t[1] / n) if dot(t, sub(q, p)) > 0 else (-t[0] / n, -t[1] / n)
def angle(u, v): return acos(max(-1.0, min(1.0, dot(u, v) / sqrt(dot(u, u) * dot(v, v))))) * DEG
def rk4(p, v, n):                                            # geodesic equation of the disc, true length 1
    def acc(s):
        g = 2 / (1 - s[0] ** 2 - s[1] ** 2); gx, gy = g * s[0], g * s[1]; w = gx * s[2] + gy * s[3]; vv = s[2] ** 2 + s[3] ** 2
        return (s[2], s[3], -2 * w * s[2] + vv * gx, -2 * w * s[3] + vv * gy)
    s, dt = (p[0], p[1], v[0], v[1]), 1 / n
    for _ in range(n):
        k1 = acc(s); k2 = acc([s[i] + dt / 2 * k1[i] for i in range(4)])
        k3 = acc([s[i] + dt / 2 * k2[i] for i in range(4)]); k4 = acc([s[i] + dt * k3[i] for i in range(4)])
        s = tuple(s[i] + dt / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in range(4))
    return s
def side_of(a, b, p): return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
def disc_area(V, circles, n, factor):                        # sum factor over grid cells inside the curved triangle
    xs, ys = [v[0] for v in V], [v[1] for v in V]; x0, y0 = min(xs), min(ys); hx, hy = (max(xs) - x0) / n, (max(ys) - y0) / n
    o = side_of(V[0], V[1], V[2]); tot = 0.0
    for i in range(n):
        x = x0 + (i + 0.5) * hx
        for j in range(n):
            y = y0 + (j + 0.5) * hy
            if all(side_of(V[m], V[(m + 1) % 3], (x, y)) * o > 0 for m in range(3)) and all((x - c[0]) ** 2 + (y - c[1]) ** 2 > r * r for c, r in circles):
                tot += factor(x * x + y * y)
    return tot * hx * hy
def unit(colat, lon): return (sin(colat) * cos(lon), sin(colat) * sin(lon), cos(colat))
def det3(a, b, c): return a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0])
def sphere_angles(V):                                        # corner angles from tangent arrows, in degrees
    def tan_(p, q): d = sum(a * b for a, b in zip(p, q)); return [b - d * a for a, b in zip(p, q)]
    def ang3(u, v): return acos(sum(a * b for a, b in zip(u, v)) / sqrt(sum(a * a for a in u) * sum(b * b for b in v))) * DEG
    return [ang3(tan_(V[i], V[(i + 1) % 3]), tan_(V[i], V[(i + 2) % 3])) for i in range(3)]
def sphere_area(V, top, lo, hi, n):                          # unit sphere: sum sin(colat) over cells inside
    o = det3(V[0], V[1], V[2]); hp, ht = top / n, (hi - lo) / n; tot = 0.0
    for i in range(n):
        ph = (i + 0.5) * hp; w = sin(ph)
        for j in range(n):
            p = unit(ph, lo + (j + 0.5) * ht)
            if all(det3(V[m], V[(m + 1) % 3], p) * o > 0 for m in range(3)): tot += w
    return tot * hp * ht
def f(xs, d=6): return ", ".join(f"{(0.0 if abs(x) < 5e-7 else x):.{d}f}" for x in xs)
# 1. curvature of the one length rule, chart one (the disc picture) and chart two (polar)
pts = [(0.0, 0.0), (0.3, 0.4), (-0.5, 0.1)]
for k, name, fn in [(1, "sphere, k = +1", sin), (0, "plane, k = 0", lambda r: r), (-1, "disc, k = -1", sinh)]:
    a, b = [K_disc(k, x, y, 1e-3) for x, y in pts], [K_disc(k, x, y, 1e-2) for x, y in pts]
    print(f"K, {name}: chart one at 3 points {f(a)} | error h=0.01 {max(abs(u - k) for u in b):.9f}, h=0.001 {max(abs(u - k) for u in a):.9f}")
    print(f"  chart two, -f''/f at r = 0.5, 1.0: {f([K_polar(fn, r, 1e-3) for r in (0.5, 1.0)])}")
    assert all(abs(u - k) < 1e-5 for u in a) and abs(K_polar(fn, 0.7, 1e-3) - k) < 1e-5   # two charts, one number
Rkm = 6371.0; Rcm = 1 / log(1.2)                           # globe; ruffle with 1 cm rows, one extra stitch in 5
print(f"globe K = 1/R^2 = {1e8 / Rkm ** 2:.4f} x 10^-8 per km^2 | ruffle R = 1 / ln 1.2 = {Rcm:.4f} cm, K = {-1 / Rcm ** 2:.6f} per cm^2")
print(f"ruffle rim growth per 1 cm row: at 5 cm out {sinh(6 / Rcm) / sinh(5 / Rcm):.4f}, at 20 cm out {sinh(21 / Rcm) / sinh(20 / Rcm):.4f}")
# 2. draw the equilateral disc triangle with true sides 1
rc = asinh(sqrt((cosh(1) - 1) / 1.5)); r0 = tanh(rc / 2)
P = [(r0 * cos(t), r0 * sin(t)) for t in (pi / 2, pi / 2 + 2 * pi / 3, pi / 2 + 4 * pi / 3)]
D = r0 + 1 / r0; kr = sqrt(D * D - 1)
star = (P[0][0] / r0 ** 2, P[0][1] / r0 ** 2)
cen, rad = circle3(P[0], P[1], star)
print(f"disc triangle: corners at true {rc:.6f}, drawn r0 = {r0:.6f}; P1* = ({star[0]:.6f}, {star[1]:.6f})")
print(f"side P1P2: mirror circle centre ({cen[0]:.6f}, {cen[1]:.6f}) radius {rad:.6f} | formula D = {D:.6f}, radius {kr:.6f}, D^2 - radius^2 = {D * D - kr * kr:.6f}")
assert abs(sqrt(dot(cen, cen)) - D) < 1e-9 and abs(rad - kr) < 1e-9                  # mirror road = formula road
C = [(D * cos(t), D * sin(t)) for t in (pi / 2 + pi / 3, pi / 2 + pi, pi / 2 + 5 * pi / 3)]
t01, t02 = tangent(C[0], P[0], P[1]), tangent(C[2], P[0], P[2])
A_arc, A_law = angle(t01, t02), acos(cosh(1) / (cosh(1) + 1)) * DEG
A_sph = acos(cos(1) / (1 + cos(1))) * DEG
print(f"corner angle: disc arcs {A_arc:.6f}, hyperbolic cosine law {A_law:.6f} | sphere {A_sph:.6f} | plane 60")
print(f"angle sums: sphere {3 * A_sph:.6f}, plane 180, disc {3 * A_law:.6f}")
print(f"by hand: cosh 1 = {cosh(1):.6f}, cos 1 = {cos(1):.6f}; cos A disc {cosh(1) / (cosh(1) + 1):.6f}, sphere {cos(1) / (1 + cos(1)):.6f}; sinh^2 of corner distance {(cosh(1) - 1) / 1.5:.6f}")
assert abs(A_arc - A_law) < 1e-9                                                    # drawn angle = law of cosines
# 3. the arc is the geodesic: shoot it, and move it to a diameter
for n in (8, 64):
    v = ((1 - r0 * r0) / 2 * t01[0], (1 - r0 * r0) / 2 * t01[1]); s = rk4(P[0], v, n)
    print(f"RK4, {n} steps, true length 1 from P1: lands {sqrt((s[0] - P[1][0]) ** 2 + (s[1] - P[1][1]) ** 2):.9f} from P2, off the arc by {abs(sqrt((s[0] - C[0][0]) ** 2 + (s[1] - C[0][1]) ** 2) - kr):.9f}")
assert sqrt((s[0] - P[1][0]) ** 2 + (s[1] - P[1][1]) ** 2) < 1e-6                 # stepped geodesic hits P2
def mob(z, a):                                               # (z - a) / (1 - conj(a) z), a disc isometry
    nr, ni = z[0] - a[0], z[1] - a[1]; dr, di = 1 - (a[0] * z[0] + a[1] * z[1]), -(a[0] * z[1] - a[1] * z[0])
    m = dr * dr + di * di; return ((nr * dr + ni * di) / m, (ni * dr - nr * di) / m)
th0, th1 = atan2(P[0][1] - C[0][1], P[0][0] - C[0][0]), atan2(P[1][1] - C[0][1], P[1][0] - C[0][0])
arc = [(C[0][0] + kr * cos(th0 + (th1 - th0) * i / 1000), C[0][1] + kr * sin(th0 + (th1 - th0) * i / 1000)) for i in range(1001)]
img = [mob(z, P[0]) for z in arc[1:]]; d0 = atan2(img[-1][1], img[-1][0])
print(f"Moebius move P1 -> 0: arc lands on the line at {d0 * DEG:.6f} deg, widest miss {max(abs(atan2(w[1], w[0]) - d0) for w in img) * DEG:.9f} deg")
assert max(abs(atan2(w[1], w[0]) - d0) for w in img) < 1e-9                       # image is a diameter
def true_len(path): return sum(lam(-1, (p[0] + q[0]) / 2, (p[1] + q[1]) / 2) * sqrt(dot(sub(q, p), sub(q, p))) for p, q in zip(path, path[1:]))
chord = [(P[0][0] + (P[1][0] - P[0][0]) * i / 1000, P[0][1] + (P[1][1] - P[0][1]) * i / 1000) for i in range(1001)]
print(f"true length P1 to P2: along the arc {true_len(arc):.6f}, along the drawn chord {true_len(chord):.6f}")
assert abs(true_len(arc) - 1) < 1e-5 and true_len(chord) > true_len(arc)           # arc is the shorter, length 1
# 4. angle excess against area, by grid sums that never use the angles
hyp = lambda q: 4 / (1 - q) ** 2
short = (180 - 3 * A_law) / DEG
grid = [disc_area(P, [(c, kr) for c in C], n, hyp) for n in (300, 600)]
print(f"disc triangle: shortfall {180 - 3 * A_law:.6f} deg = {short:.6f} rad | area on grids 300, 600: {f(grid)}")
OAB = [(0.0, 0.0), (0.5, 0.0), (0.0, 0.5)]; OAB_c = [((1.25, 1.25), sqrt(1.25 ** 2 * 2 - 1))]
osum = 90 + 2 * angle(tangent(OAB_c[0][0], OAB[1], OAB[2]), (-1.0, 0.0))   # right angle at O, two drawn corners
g2 = [disc_area(OAB, OAB_c, n, hyp) for n in (300, 600)]
print(f"disc triangle O, A, B: shortfall {180 - osum:.6f} deg = {(180 - osum) / DEG:.6f} rad | area on grids 300, 600: {f(g2)}")
assert abs(grid[1] - short) < 1e-3 and abs(g2[1] - (180 - osum) / DEG) < 1e-3   # shortfall = area
SV = [(0.0, 0.0, 1.0), unit(1, 0), unit(1, A_sph / DEG)]
sg = [sphere_area(SV, 1.0, 0.0, A_sph / DEG, n) for n in (300, 600)]
print(f"sphere triangle: excess {3 * A_sph - 180:.6f} deg = {(3 * A_sph - 180) / DEG:.6f} rad | area on grids 300, 600: {f(sg)}")
LV = [unit((90 - 51.5074) / DEG, -0.1278 / DEG), unit((90 - 40.7128) / DEG, -74.0060 / DEG), (0.0, 0.0, 1.0)]
La = sphere_angles(LV); Lg = sphere_area(LV, 0.9, -74.0060 / DEG, -0.1278 / DEG, 600); E = (sum(La) - 180) / DEG
print(f"London, New York, pole: angles {f(La, 2)}, excess {sum(La) - 180:.2f} deg = {E:.6f} rad, area R^2 x excess {Rkm ** 2 * E:.0f} km^2, grid {Rkm ** 2 * Lg:.0f} km^2")
assert abs(sg[1] - (3 * A_sph - 180) / DEG) < 1e-3 and abs(Lg - E) < 1e-3          # excess = area, sphere
print(f"same triangles, real sizes: globe side {Rkm:.0f} km, area {Rkm ** 2 * (3 * A_sph - 180) / DEG:.0f} km^2 | ruffle side {Rcm:.2f} cm, R^2 = {Rcm ** 2:.2f} cm^2, area {Rcm ** 2 * short:.2f} cm^2")
# 5. mistakes
flat = disc_area(P, [], 600, hyp)
print(f"mistake, chord sides: angle sum 180, yet true area {flat:.6f} | lam not squared: area on grids 300, 600: {f([disc_area(P, [(c, kr) for c in C], n, lambda q: 2 / (1 - q)) for n in (300, 600)])}")
lap0 = (4 * lam(-1, 1e-3, 0) - 4 * lam(-1, 0, 0)) / 1e-6
print(f"mistake, ln left out: -lap(lam)/lam^2 at the centre {-lap0 / lam(-1, 0, 0) ** 2:.6f} | ruffle area without R^2: {short:.2f} cm^2 not {Rcm ** 2 * short:.2f}")
def scr(p): return f"({180 + 150 * p[0]:.1f}, {170 - 150 * p[1]:.1f})"
def rim(c, r):                                               # where a circle centre c, radius r, crosses the rim
    cc = dot(c, c); m = (1 + cc - r * r) / 2; w = sqrt(cc - m * m); return [((m * c[0] + s * c[1] * w) / cc, (m * c[1] - s * c[0] * w) / cc) for s in (-1, 1)]
print("figure, rim radius 150 at (180, 170); corners", " ".join(scr(p) for p in P), f"arc radius {150 * kr:.1f}; rim ends", " ".join(scr(q) for c in C for q in rim(c, kr)))
print("ALL CHECKS PASS")
