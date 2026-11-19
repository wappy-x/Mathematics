# Complex manifolds and Kahler forms -- the check behind the card.  Standard
# library only.  The projective line P^1 has two charts: z, and w = 1/z where
# both work.  Its Fubini-Study form is omega = (i/2) g dz ^ dz-bar, with the
# density g1(z) = 1/(1 + |z|^2)^2, and that equals g dx ^ dy.  Chart agreement
# is checked exactly in fractions; derivatives and areas are floats, to 1e-6.
from fractions import Fraction as Q
import math

def fx(x):                                 # a float to 6 places, never "-0.000000"
    return f"{0.0 if abs(x) < 5e-7 else x:.6f}"

def cx(v):                                 # a complex number as "a + bi"
    return f"{fx(v.real)} {'-' if v.imag < -5e-7 else '+'} {fx(abs(v.imag))}i"

def split(f, z, d=1e-5):                   # road one: (df/dz, df/dz-bar) from x and y slopes
    fx_ = (f(z + d) - f(z - d)) / (2 * d)
    fy_ = (f(z + 1j * d) - f(z - 1j * d)) / (2 * d)
    return (fx_ - 1j * fy_) / 2, (fx_ + 1j * fy_) / 2

def g1(z):                                  # the Fubini-Study density in chart z
    return 1 / (1 + abs(z) ** 2) ** 2

def midpoint(f, a, b, n=20000):            # a plain midpoint-rule integral
    step = (b - a) / n
    return sum(f(a + (k + 0.5) * step) for k in range(n)) * step

z0 = 1 + 1j
tests = [("z^2", lambda z: z * z, 2 * z0, 0),         # road two: the rules by hand
         ("1/z", lambda z: 1 / z, -1 / z0 ** 2, 0),
         ("1/conj z", lambda z: 1 / z.conjugate(), 0, -1 / z0.conjugate() ** 2),
         ("|z|^2", lambda z: abs(z) ** 2, z0.conjugate(), z0)]
worst = 0.0
for name, f, dz_part, dzbar_part in tests:
    a, b = split(f, z0)
    worst = max(worst, abs(a - dz_part), abs(b - dzbar_part))
    print(f"d({name}) at 1 + i: dz part {cx(a)}, dz-bar part {cx(b)}")
d = 1e-3                                   # road two to g: a quarter of the Laplacian of log(1 + |z|^2)
phi = lambda z: math.log(1 + abs(z) ** 2)
lap = (phi(z0 + d) + phi(z0 - d) + phi(z0 + 1j * d) + phi(z0 - 1j * d) - 4 * phi(z0)) / d ** 2
print(f"g(1 + i) = 1/(1 + 2)^2 = {fx(g1(z0))}; quarter Laplacian of the potential {fx(lap / 4)}")
print(f"length per unit step, 1/(1 + |z|^2): at 0 {fx(math.sqrt(g1(0)))}, at 1 + i {fx(math.sqrt(g1(z0)))}, "
      f"at 10 {fx(math.sqrt(g1(10)))}")
agree = []
for x, y in [(Q(1), Q(1)), (Q(2), Q(0)), (Q(1, 2), Q(3, 4)), (Q(3), Q(-2))]:
    s = x * x + y * y                      # |z|^2, exact
    wx, wy = x / s, -y / s                 # w = 1/z, exact
    gw = 1 / (1 + wx * wx + wy * wy) ** 2
    zz = (x * x - y * y, 2 * x * y)        # z^2, so |dw/dz|^2 = 1/|z^2|^2
    factor = 1 / (zz[0] ** 2 + zz[1] ** 2)
    agree.append(gw * factor == 1 / (1 + s) ** 2)
    if (x, y) == (1, 1):
        print(f"exact at z = 1 + i: g_z = {1 / (1 + s) ** 2}, g_w(w) = {gw}, |dw/dz|^2 = {factor}, "
              f"g_w x |dw/dz|^2 = {gw * factor}")
print(f"chart agreement at 1 + i, 2, 1/2 + 3i/4, 3 - 2i: {sum(agree)} of 4 exact")
print("R, share of the area in |z| <= R: closed form, Archimedes zone, midpoint rule")
chart = []
for R in [Q(1, 2), Q(1), Q(3, 2), Q(2), Q(5, 2), Q(3), Q(7, 2), Q(4)]:
    closed = 1 - 1 / (1 + R * R)
    t = (R * R - 1) / (R * R + 1)          # height on the unit sphere above |z| = R
    zone = (t + 1) / 2                     # Archimedes: a zone's area is its height's share
    num = midpoint(lambda r: 2 * r * g1(r), 0, float(R))   # area / pi
    chart.append((closed, zone, num))
    print(f"figure, {float(R)}: {closed} = {zone}, {fx(float(zone))}, {fx(num)}")
total = 2 * midpoint(lambda r: 2 * math.pi * r * g1(r), 0, 1)
print(f"whole sphere: two unit discs, one per chart: {fx(total)}; pi = {fx(math.pi)}; "
      f"integral of omega/pi: {fx(total / math.pi)}")
dist = midpoint(lambda r: math.sqrt(g1(r)), 0, 1)
angle = math.acos(1 / math.sqrt(2))     # |<0|+>| = 1/sqrt 2 for the two qubit states
print(f"distance z = 0 to z = 1: {fx(dist)}; qubit angle between |0> and |+>: {fx(angle)}")

def g_fs(z1, z2):                          # Fubini-Study on the chart C^2 of P^2
    n = 1 + abs(z1) ** 2 + abs(z2) ** 2
    v = (z1, z2)
    return [[((n if j == k else 0) - v[j].conjugate() * v[k]) / n ** 2 for k in range(2)] for j in range(2)]

def g_bad(z1, z2):                         # positive, but not closed
    return [[1 + abs(z2) ** 2, 0], [0, 1]]

def asym(g, p, d=1e-5):                    # largest |d_l g_jk - d_j g_lk| over l, j, k
    def dl(l, j, k):
        e = [[d, 0], [0, d]][l]
        up = g(*[p[m] + e[m] for m in range(2)])[j][k] - g(*[p[m] - e[m] for m in range(2)])[j][k]
        vp = g(*[p[m] + 1j * e[m] for m in range(2)])[j][k] - g(*[p[m] - 1j * e[m] for m in range(2)])[j][k]
        return (up - 1j * vp) / (4 * d)
    return max(abs(dl(l, j, k) - dl(j, l, k)) for l in range(2) for j in range(2) for k in range(2))

p = (1 + 1j, 2 - 1j)
g = g_fs(*p)
det = (g[0][0] * g[1][1] - g[0][1] * g[1][0]).real
print(f"P^2 at (1 + i, 2 - i): g11 {fx(g[0][0].real)}, g22 {fx(g[1][1].real)}, g12 {cx(g[0][1])}, 1/det {fx(1 / det)}")
print(f"Kahler test, largest mismatch: Fubini-Study {fx(asym(g_fs, p))}; diag(1 + |z2|^2, 1) {fx(asym(g_bad, p))}")
print(f"torus C/Z[i], flat form (i/2) dz ^ dz-bar: area of one cell, Im(conj(1) x i) = {fx((1j * (1 + 0j).conjugate()).imag)}")
dz, dzb = (1, 1j), (1, -1j)                # the dx and dy parts of dz and dz-bar
wedge = dz[0] * dzb[1] - dz[1] * dzb[0]    # dz ^ dz-bar = wedge times dx ^ dy
print(f"mistake 1, the factor i/2 dropped: area {cx(wedge * total)}, not {fx((0.5j * wedge * total).real)}")
print(f"mistake 2, g_w(w) without |dw/dz|^2 at 1 + i: {fx(g1(1 / z0))}, not {fx(g1(z0))}")
print(f"mistake 3, unit-sphere form 4g as the class: integral/pi {fx(4 * total / math.pi)}, not 1")
assert worst < 1e-6                                          # slopes against the rules by hand
assert abs(lap / 4 - g1(z0)) < 1e-6                           # potential against density
assert all(agree)                                            # the two charts give one form
assert all(c == z for c, z, _ in chart) and all(abs(float(c) - n) < 1e-6 for c, _, n in chart)
assert abs(total - math.pi) < 1e-6 and abs(dist - angle) < 1e-6
assert abs(1 / det - 512) < 1e-6 and asym(g_fs, p) < 1e-6 and abs(asym(g_bad, p) - math.sqrt(5)) < 1e-6
print("ALL CHECKS PASS")
