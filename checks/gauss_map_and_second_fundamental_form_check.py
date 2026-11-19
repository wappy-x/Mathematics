# Gauss map and second fundamental form -- the check behind the card.  Standard library only.
# Roof: the saddle middle, z = 30 + (u^2 - v^2)/120 m (plan chart), the same saddle in the
# seam chart u = p + q, v = p - q, and the dome over the east end, a sphere of radius 60 m.
# Every number on the card is printed here.  No geometry package is used.
from math import sqrt, sin, cos, acos, pi, degrees

R = 60.0
def plan(u, v): return (u, v, 30.0 + (u * u - v * v) / 120.0)
def seam(p, q): return (p + q, p - q, 30.0 + p * q / 30.0)
def dome(f, t): return (R * sin(f) * cos(t), R * sin(f) * sin(t), R * cos(f))
def barrel(u, v): return (R * sin(u / R), v, R * cos(u / R))      # a barrel vault, for "try"
def ridge(u, v): return (u, v, 30.0 - 0.3 * abs(u))              # a crease, for "breaks"

def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def scl(a, s): return tuple(x * s for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def unit(a): return scl(a, 1.0 / sqrt(dot(a, a)))

def arrows(ch, a, b, h=1e-3):
    # tangent arrows r_u, r_v and second derivatives r_uu, r_uv, r_vv by central differences
    c, pu, mu, pv, mv = ch(a, b), ch(a + h, b), ch(a - h, b), ch(a, b + h), ch(a, b - h)
    ru, rv = scl(sub(pu, mu), 0.5 / h), scl(sub(pv, mv), 0.5 / h)
    ruu = scl(sub(sub(pu, c), sub(c, mu)), 1 / h ** 2)
    rvv = scl(sub(sub(pv, c), sub(c, mv)), 1 / h ** 2)
    ruv = scl(sub(sub(ch(a + h, b + h), ch(a + h, b - h)), sub(ch(a - h, b + h), ch(a - h, b - h))), 0.25 / h ** 2)
    return ru, rv, ruu, ruv, rvv

def up(n): return n if n[2] > 0 else scl(n, -1.0)     # house rule: the normal points up, out of the roof

def gauss(ch, a, b): ru, rv = arrows(ch, a, b)[:2]; return up(unit(cross(ru, rv)))

def forms(ch, a, b, unit_normal=True, h=1e-3):   # h = 0.1 on the quadratic saddle: exact, less rounding
    ru, rv, ruu, ruv, rvv = arrows(ch, a, b, h)
    n = up(cross(ru, rv))
    if unit_normal: n = unit(n)
    return (dot(ru, ru), dot(ru, rv), dot(rv, rv)), (dot(ruu, n), dot(ruv, n), dot(rvv, n))

def shape(I, II):          # road 1: W = I^-1 II, written out
    (E, F, G), (L, M, N) = I, II
    d = E * G - F * F
    return ((G * L - F * M) / d, (G * M - F * N) / d), ((E * M - F * L) / d, (E * N - F * M) / d)

def weingarten(ch, a, b, h):   # road 2: how the Gauss map moves; -n_u = w11 r_u + w21 r_v
    ru, rv = arrows(ch, a, b)[:2]
    nu = scl(sub(gauss(ch, a + h, b), gauss(ch, a - h, b)), -0.5 / h)
    nv = scl(sub(gauss(ch, a, b + h), gauss(ch, a, b - h)), -0.5 / h)
    E, F, G = dot(ru, ru), dot(ru, rv), dot(rv, rv)
    d = E * G - F * F
    col = [((G * dot(x, ru) - F * dot(x, rv)) / d, (E * dot(x, rv) - F * dot(x, ru)) / d) for x in (nu, nv)]
    return (col[0][0], col[1][0]), (col[0][1], col[1][1])

def det(W): return W[0][0] * W[1][1] - W[0][1] * W[1][0]
def tr(W): return W[0][0] + W[1][1]
def fx(x, d=6): return f"{0.0 if abs(x) < 0.5 * 10 ** -d else x:.{d}f}"   # no "-0.000000"
def two(W): return f"{fx(W[0][0])} {fx(W[0][1])} / {fx(W[1][0])} {fx(W[1][1])}"

def image_ratio(ch, a, b, h):  # road 4: signed globe area of a small square's normals / roof area
    c = [(a - h / 2, b - h / 2), (a + h / 2, b - h / 2), (a + h / 2, b + h / 2), (a - h / 2, b + h / 2)]
    n, r, n0 = [gauss(ch, *p) for p in c], [ch(*p) for p in c], gauss(ch, a, b)
    return dot(cross(sub(n[2], n[0]), sub(n[3], n[1])), n0) / dot(cross(sub(r[2], r[0]), sub(r[3], r[1])), n0)

def gap(a, b):             # the roof's distance from P's tangent plane, along n, after a plan step (a, b)
    return dot(sub(plan(30 + a, 20 + b), plan(30, 20)), gauss(plan, 30, 20))

I1, II1 = forms(plan, 30, 20, h=0.1); W1 = shape(I1, II1)
I2, II2 = forms(seam, 25, 5, h=0.1); W2 = shape(I2, II2)
n = gauss(plan, 30, 20)
F0 = 0.5 * 0.643501108793284          # halfway up the dome's slope; rim polar angle acos(0.8)
Wd = shape(*forms(dome, F0, 0.0))
dome_area, cap = pi * R * 12.0, pi * (1 - 0.8)  # half dome pi R h; its half-cap on the globe
Iu, IIu = forms(plan, 30, 20, unit_normal=False, h=0.1)
Wdn = shape(I2, tuple(-x for x in II2))         # r_p x r_q points down; not flipped
kink = [sqrt(dot(sub(gauss(ridge, h / 2, 0), gauss(ridge, -h / 2, 0)), sub(gauss(ridge, h / 2, 0), gauss(ridge, -h / 2, 0)))) / h for h in (1.0, 0.1)]
E, F, G = I1; L, M, N = II1
ar = arrows(plan, 30, 20); c = cross(ar[0], ar[1])
rows = [
    ("unit normal n at P", f"{n[0]:.6f} {n[1]:.6f} {n[2]:.6f}"),
    ("  by hand (-3, 2, 6)/7", f"{-3 / 7:.6f} {2 / 7:.6f} {6 / 7:.6f}"),
    ("  tilt from vertical, deg", f"{degrees(acos(n[2])):.6f}"),
    ("r_u x r_v at P, its length", f"{c[0]:.6f} {c[1]:.6f} {c[2]:.6f} {sqrt(dot(c, c)):.6f}"),
    ("r_uu, r_vv at P", f"{fx(ar[2][0])} {fx(ar[2][1])} {ar[2][2]:.6f} / {fx(ar[4][0])} {fx(ar[4][1])} {ar[4][2]:.6f}"),
    ("E, F, G at P", f"{E:.6f} {F:.6f} {G:.6f}"),
    ("I^-1 at P", two(shape(I1, (1.0, 0.0, 1.0)))),
    ("L, M, N at P, plan chart", f"{fx(L)} {fx(M)} {fx(N)}"),
    ("  by hand 1/70, 0, -1/70", f"{1 / 70:.6f} {0.0:.6f} {-1 / 70:.6f}"),
    ("EG - F^2, LN - M^2", f"{E * G - F * F:.6f} {L * N - M * M:.9f}"),
    ("1 W = I^-1 II, plan chart", two(W1)),
    ("2 W from the Gauss map, h = 1 m", two(weingarten(plan, 30, 20, 1.0))),
    ("  same, h = 0.1 m", two(weingarten(plan, 30, 20, 0.1))),
    ("3 W in the seam chart at (25, 5)", two(W2)),
    ("  seam L, M, N", f"{fx(II2[0])} {fx(II2[1])} {fx(II2[2])}"),
    ("det W: plan, seam", f"{det(W1):.9f} {det(W2):.9f}"),
    ("  (LN - M^2)/(EG - F^2)", f"{(L * N - M * M) / (E * G - F * F):.9f}"),
    ("trace W: plan, seam", f"{tr(W1):.9f} {tr(W2):.9f}"),
    ("  by hand -9/60025, -1/686", f"{-9 / 60025:.9f} {-1 / 686:.9f}"),
    ("4 globe area / roof area, 2 m square", f"{image_ratio(plan, 30, 20, 2.0):.9f}"),
    ("  same, 0.2 m square", f"{image_ratio(plan, 30, 20, 0.2):.9f}"),
    ("gap above tangent plane, 10 m east", f"{gap(10, 0):.6f} half II {0.5 * L * 100:.6f}"),
    ("  10 m east, measured straight up", f"{plan(40, 20)[2] - plan(30, 20)[2] - 10 * ar[0][2]:.6f}"),
    ("  10 m north", f"{gap(0, 10):.6f} half II {0.5 * N * 100:.6f}"),
    ("  10 m along the seam (10, 10)", f"{fx(gap(10, 10))} half II {fx(0.5 * (L + 2 * M + N) * 100)}"),
    ("  1 m east", f"{gap(1, 0):.6f}"),
    ("dome W halfway up, outward n", two(Wd)),
    ("  -1/R", f"{-1 / R:.6f}"),
    ("  det W and 1/R^2", f"{det(Wd):.9f} {1 / R ** 2:.9f}"),
    ("half dome: roof area m^2", f"{dome_area:.6f}"),
    ("  globe area of its normals, cap", f"{cap:.6f}"),
    ("  det W times roof area", f"{det(Wd) * dome_area:.6f}"),
    ("  rim tilt, deg; globe radius", f"{degrees(0.643501108793284):.6f} {sin(0.643501108793284):.6f}"),
    ("wrong: normal not unit, W", two(shape(Iu, IIu))),
    ("wrong: W = II, det", f"{L * N - M * M:.9f}"),
    ("wrong: seam normal left pointing down", two(Wdn)),
    ("  its det and trace", f"{det(Wdn):.9f} {tr(Wdn):.9f}"),
    ("breaks: crease, |dn|/h at h = 1, 0.1", f"{kink[0]:.6f} {kink[1]:.6f}"),
    ("try: W at the centre O", two(shape(*forms(plan, 0, 0)))),
    ("try: barrel vault R = 60, W", two(shape(*forms(barrel, 10.0, 5.0)))),
    ("try: lamp fixing (30, -20), det W", f"{det(shape(*forms(plan, 30, -20))):.9f}"),
]
for name, v in rows:
    print(f"{name:<38} {v}")
for u, v in ((30, -20), (30, 20), (-30, 20), (-30, -20)):
    g = gauss(plan, u, v)
    print(f"figure, saddle corner ({u}, {v}) -> globe {g[0]:.4f} {g[1]:.4f}")

assert abs(n[0] + 3 / 7) + abs(n[1] - 2 / 7) + abs(n[2] - 6 / 7) < 1e-9, "unit normal by hand"
assert abs(L - 1 / 70) + abs(M) + abs(N + 1 / 70) < 1e-6, "second form by hand"
Wg = weingarten(plan, 30, 20, 0.1)
assert max(abs(Wg[i][j] - W1[i][j]) for i in (0, 1) for j in (0, 1)) < 1e-5, "Gauss map road agrees"
assert abs(det(W1) - det(W2)) < 1e-9 and abs(tr(W1) - tr(W2)) < 1e-8, "det and trace ignore the chart"
assert abs(W1[0][0] - W2[0][0]) > 1e-3, "entries of W do depend on the chart"
assert abs(det(W1) + 9 / 60025) < 1e-12 and abs(tr(W1) + 1 / 686) < 1e-10, "det and trace by hand"
e2, e02 = abs(image_ratio(plan, 30, 20, 2.0) - det(W1)), abs(image_ratio(plan, 30, 20, 0.2) - det(W1))
assert e02 < e2 / 50 and e02 < 1e-9, "the globe area ratio closes in on det W"
assert abs(gap(10, 0) - 0.5 * L * 100) < 1e-6, "the roof leaves its tangent plane by II/2"
assert abs(Wd[0][0] + 1 / R) + abs(Wd[1][1] + 1 / R) + abs(Wd[0][1]) < 1e-6, "dome W = -I/R"
assert abs(det(Wd) * dome_area - cap) < 1e-6, "dome: det W times area = globe area"
assert kink[1] > 9 * kink[0], "a crease has no shape operator"
print("ALL CHECKS PASS")
