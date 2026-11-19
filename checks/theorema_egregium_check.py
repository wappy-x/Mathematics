# Theorema Egregium -- the check behind the card.  Standard library only.
# Gaussian curvature K, three independent roads:
#   1 inside:  Brioschi's formula, fed only the table E, F, G (derivatives by central differences)
#   2 outside: det of the shape operator, (LN - M^2)/(EG - F^2), which needs the normal in space
#   3 taped:   lay a tape round a circle walked out on the surface and compare it with 2 pi s
from math import sin, cos, asin, acos, sqrt, pi, radians

def d1(f, u, v, h): return (f(u + h, v) - f(u - h, v)) / (2 * h), (f(u, v + h) - f(u, v - h)) / (2 * h)
def det3(m): return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
                     + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
def vec(a, b, s): return [(x - y) * s for x, y in zip(a, b)]
def total(xs):                            # plain left-to-right sum, as in the Rust check
    t = 0.0
    for x in xs: t += x
    return t
def dot(a, b): return total(x * y for x, y in zip(a, b))
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]

def brioschi(E, F, G, u, v, h):           # road 1: E, F, G and their derivatives, nothing else
    e, f, g = E(u, v), F(u, v), G(u, v)
    (Eu, Ev), (Fu, Fv), (Gu, Gv) = d1(E, u, v, h), d1(F, u, v, h), d1(G, u, v, h)
    Evv = (E(u, v + h) - 2 * e + E(u, v - h)) / h ** 2
    Guu = (G(u + h, v) - 2 * g + G(u - h, v)) / h ** 2
    Fuv = (F(u + h, v + h) - F(u + h, v - h) - F(u - h, v + h) + F(u - h, v - h)) / (4 * h * h)
    a = [[-Evv / 2 + Fuv - Guu / 2, Eu / 2, Fu - Ev / 2], [Fv - Gu / 2, e, f], [Gv / 2, f, g]]
    b = [[0.0, Ev / 2, Gu / 2], [Ev / 2, e, f], [Gu / 2, f, g]]
    return (det3(a) - det3(b)) / (e * g - f * f) ** 2

def gauss_orth(E, G, u, v, h):            # Gauss's shorter formula, valid only where F = 0
    w = lambda a, b: sqrt(E(a, b) * G(a, b))
    A = lambda a, b: d1(G, a, b, h)[0] / w(a, b)
    B = lambda a, b: d1(E, a, b, h)[1] / w(a, b)
    return -(d1(A, u, v, h)[0] + d1(B, u, v, h)[1]) / (2 * w(u, v))

def outside(r, u, v, h):                  # road 2: the patch in space, its normal, L, M, N
    p = lambda i, j: r(u + i * h, v + j * h)
    ru, rv = vec(p(1, 0), p(-1, 0), 0.5 / h), vec(p(0, 1), p(0, -1), 0.5 / h)
    ruu = [(x + y - 2 * z) / h ** 2 for x, y, z in zip(p(1, 0), p(-1, 0), p(0, 0))]
    rvv = [(x + y - 2 * z) / h ** 2 for x, y, z in zip(p(0, 1), p(0, -1), p(0, 0))]
    ruv = [(a - b - c + d) / (4 * h * h) for a, b, c, d in zip(p(1, 1), p(1, -1), p(-1, 1), p(-1, -1))]
    m = cross(ru, rv); n = [x / sqrt(dot(m, m)) for x in m]
    E, F, G, L, M, N = dot(ru, ru), dot(ru, rv), dot(rv, rv), dot(ruu, n), dot(ruv, n), dot(rvv, n)
    K, H = (L * N - M * M) / (E * G - F * F), (E * N - 2 * F * M + G * L) / (2 * (E * G - F * F))
    root = sqrt(max(H * H - K, 0.0))
    return K, H, H + root, H - root, (E, F, G)

def sphere(R): return lambda ph, th: (R * sin(ph) * cos(th), R * sin(ph) * sin(th), R * cos(ph))
def tape(R, s, n):                        # road 3: n straight tape pieces round the circle s from the pole
    pts = [sphere(R)(s / R, 2 * pi * k / n) for k in range(n + 1)]
    return total(sqrt(dot(vec(b, a, 1.0), vec(b, a, 1.0))) for a, b in zip(pts, pts[1:]))
def k_from_circle(s, C): return 3 * (2 * pi * s - C) / (pi * s ** 3)
def z(x): return 0.0 if abs(x) < 5e-13 else x   # print a rounding-level zero as 0

# ---- the paper: an A4 sheet, 297 mm side rolled round, 210 mm along the tube ----
a = 0.297 / (2 * pi)
sheet = lambda x, y: (x, y, 0.0)
tube = lambda x, y: (a * sin(x / a), a * cos(x / a), y)        # normal points in, toward the axis
helix = [tube(0.297 * k / 1000, 0.210 * k / 1000) for k in range(1001)]
helix_len = total(sqrt(dot(vec(q, p, 1.0), vec(q, p, 1.0))) for p, q in zip(helix, helix[1:]))
one, zero = (lambda x, y: 1.0), (lambda x, y: 0.0)
Kt, Ht, k1t, k2t, efg_t = outside(tube, 0.1, 0.05, 1e-5)
Ks, Hs, _, _, _ = outside(sheet, 0.1, 0.05, 1e-5)
# ---- the dome (sphere of radius 60 m) and the globe (6371 km), polar angle phi, longitude theta ----
Ed, Gd = (lambda ph, th: 3600.0), (lambda ph, th: 3600.0 * sin(ph) ** 2)
Rg = 6371.0
Eg, Gg = (lambda ph, th: Rg * Rg), (lambda ph, th: Rg * Rg * sin(ph) ** 2)
# ---- the saddle: plan chart (u east, v north) and seam chart (u = p + q, v = p - q) ----
seam = lambda p, q: (p + q, p - q, 30.0 + p * q / 30.0)       # the seam chart's patch in space
Ep, Fp, Gp = (lambda u, v: 1 + u * u / 3600), (lambda u, v: -u * v / 3600), (lambda u, v: 1 + v * v / 3600)
Es, Fs, Gs = (lambda p, q: 2 + q * q / 900), (lambda p, q: p * q / 900), (lambda p, q: 2 + p * p / 900)
K_P_hand = -(1 / 3600) / (1 + 0.25 + 1 / 9) ** 2
b = 0.210 / (2 * pi)                                            # try: roll the other side round
Kn, _, _, _, _ = outside(lambda x, y: (b * sin(x / b), b * cos(x / b), y), 0.1, 0.05, 1e-5)

rows = [
    ("tube radius a, m", f"{a:.6f}"),
    ("tube E, F, G from the patch", " ".join(f"{z(x):.6f}" for x in efg_t)),
    ("sheet diagonal, flat, m", f"{sqrt(0.297 ** 2 + 0.210 ** 2):.6f}"),
    ("same line on the tube, 1000 tape pieces, m", f"{helix_len:.6f}"),
    ("1 K tube, inside (E=1, F=0, G=1)", f"{z(brioschi(one, zero, one, 0.1, 0.05, 1e-3)):.9f}"),
    ("2 K tube, outside, 1/m^2", f"{z(Kt):.9f}"),
    ("  tube kappa1, kappa2, 1/m", f"{k1t:.6f} {z(k2t):.6f}"),
    ("  H tube, sheet, 1/m", f"{Ht:.6f} {z(Hs):.6f}"),
    ("1 K dome, inside, 1/m^2", f"{brioschi(Ed, zero, Gd, 0.3, 0.4, 1e-4):.9f}"),
    ("  Gauss F=0 formula", f"{gauss_orth(Ed, Gd, 0.3, 0.4, 1e-4):.9f}"),
    ("2 K dome, outside", f"{outside(sphere(60.0), 0.3, 0.4, 1e-4)[0]:.9f}"),
    ("  1/60^2", f"{1 / 3600:.9f}"),
    ("D (12 m E, 16 m N of crown): to cut, rim, m", f"{60 * asin(12 / 60):.6f} {60 * (acos(0.8) - asin(20 / 60)):.6f}"),
]
for s in (10.0, 5.0):
    C = 2 * pi * 60 * sin(s / 60)
    rows += [(f"dome circle s = {s:.0f} m: 2 pi s, closed C, m", f"{2 * pi * s:.6f} {C:.6f}"),
             ("  tape 360, 3600 pieces, m", f"{tape(60.0, s, 360):.6f} {tape(60.0, s, 3600):.6f}"),
             ("  sin(s/60); g, shortfall, m; 3 K: C, tape", f"{sin(s / 60):.6f} {60 * sin(s / 60):.6f} {2 * pi * s - C:.6f} {k_from_circle(s, C):.9f} {k_from_circle(s, tape(60.0, s, 3600)):.9f}")]
Kg = brioschi(Eg, zero, Gg, 0.9, 0.2, 1e-4)
Cg = 2 * pi * Rg * sin(1000 / Rg)
rows += [
    ("1 K globe, inside, x 1e8 per km^2", f"{Kg * 1e8:.6f}"),
    ("  1/sqrt(K), km", f"{1 / sqrt(Kg):.3f}"),
    ("2 K globe, outside, x 1e8", f"{outside(sphere(Rg), 0.9, 0.2, 1e-4)[0] * 1e8:.6f}"),
    ("globe circle s = 1000 km: 2 pi s, C, km", f"{2 * pi * 1000:.3f} {Cg:.3f}"),
    ("  tape 10000 pieces, km; shortfall, km", f"{tape(Rg, 1000.0, 10000):.3f} {2 * pi * 1000 - Cg:.3f}"),
    ("3 K from tape, x 1e8", f"{k_from_circle(1000.0, tape(Rg, 1000.0, 10000)) * 1e8:.6f}"),
    ("  rim kept 2 pi s on a flat map: stretch", f"{2 * pi * 1000 / Cg:.6f}"),
    ("Mercator at 72 deg: length, area stretch", f"{1 / cos(radians(72)):.6f} {1 / cos(radians(72)) ** 2:.6f}"),
    ("1 K roof at P, plan chart, 1/m^2", f"{brioschi(Ep, Fp, Gp, 30.0, 20.0, 1.0):.9f}"),
    ("1 K roof at P, seam chart", f"{brioschi(Es, Fs, Gs, 25.0, 5.0, 1.0):.9f}"),
    ("2 K roof at P, outside, seam patch", f"{outside(seam, 25.0, 5.0, 1.0)[0]:.9f}"),
    ("  hand: 1.361111^2, -(1/3600)/1.361111^2", f"{(1 + 0.25 + 1 / 9) ** 2:.6f} {K_P_hand:.9f}"),
    ("K roof at O, inside, 1/m^2", f"{brioschi(Ep, Fp, Gp, 0.0, 0.0, 1.0):.9f}"),
    ("wrong: F=0 formula on plan chart at P; F there", f"{z(gauss_orth(Ep, Gp, 30.0, 20.0, 1.0)):.9f} {Fp(30.0, 20.0):.6f}"),
    ("wrong: circle test at s = pi R/2, x 1e8; % low", f"{k_from_circle(pi * Rg / 2, 2 * pi * Rg) * 1e8:.6f} {100 * (1 - k_from_circle(pi * Rg / 2, 2 * pi * Rg) * Rg * Rg):.2f}"),
    ("breaks: cone tip, quarter cut, K at 0.1, 0.01 m", f"{k_from_circle(0.1, 1.5 * pi * 0.1):.3f} {k_from_circle(0.01, 1.5 * pi * 0.01):.3f}"),
    ("try: roll the 210 mm side: kappa1 = 1/b, K", f"{1 / b:.6f} {z(Kn):.9f}"),
    ("try: 10 m circle on a 120 m dome, shortfall", f"{2 * pi * 10 - 2 * pi * 120 * sin(10 / 120):.6f}"),
    ("try: K roof at the corner (30, 36)", f"{brioschi(Ep, Fp, Gp, 30.0, 36.0, 1.0):.9f}"),
]
for name, v in rows:
    print(f"{name:<48} {v}")
ss = [250.0 * k for k in range(9)]
print("figure, s km", " ".join(f"{s:.0f}" for s in ss))
print("figure, shortfall km", " ".join(f"{2 * pi * s - 2 * pi * Rg * sin(s / Rg):.1f}" for s in ss))
print("figure, pi K s^3/3 km", " ".join(f"{pi * s ** 3 / (3 * Rg * Rg):.1f}" for s in ss))

assert abs(helix_len - sqrt(0.297 ** 2 + 0.210 ** 2)) < 1e-6, "rolling keeps the diagonal's length"
assert abs(brioschi(Ed, zero, Gd, 0.3, 0.4, 1e-4) * 3600 - 1) < 1e-6, "dome: inside K = 1/60^2"
assert abs(outside(sphere(60.0), 0.3, 0.4, 1e-4)[0] * 3600 - 1) < 1e-6, "dome: outside K = 1/60^2"
assert abs(gauss_orth(Ed, Gd, 0.3, 0.4, 1e-4) * 3600 - 1) < 1e-6, "dome: Gauss's F = 0 form gives 1/60^2"
assert abs(Kg * Rg * Rg - 1) < 1e-6, "globe: inside K = 1/R^2"
assert abs(brioschi(Ep, Fp, Gp, 30, 20, 1.0) / K_P_hand - 1) < 1e-9, "roof, plan chart, against the hand value"
assert abs(brioschi(Es, Fs, Gs, 25, 5, 1.0) / K_P_hand - 1) < 1e-9, "roof, seam chart: K is not chart-made"
assert abs(outside(seam, 25.0, 5.0, 1.0)[0] / K_P_hand - 1) < 1e-9, "roof: outside agrees with inside"
assert abs(Kt) < 1e-6, "tube: outside K = 0, as the inside table says"
assert abs(Ht - 1 / (2 * a)) < 1e-4, "tube: H = 1/(2a), not 0: H is not felt from inside"
assert abs(k_from_circle(5.0, tape(60.0, 5.0, 3600)) * 3600 - 1) < abs(k_from_circle(10.0, tape(60.0, 10.0, 3600)) * 3600 - 1) < 0.01, "circle test closes in"
assert abs(k_from_circle(1000.0, tape(Rg, 1000.0, 10000)) * Rg * Rg - 1) < 0.002, "globe felt by a tape"
print("ALL CHECKS PASS")
