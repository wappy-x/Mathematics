# Harnack and regularity: a 10 cm round plate, faces insulated, rim held at 100 C on its top half
# and 0 C on its bottom half. Temperatures are rises above the 0 C clamp; positions scaled by R.
# Roads: closed form, Poisson-kernel sum, sine series, finite differences, and sharp extremal cases.
from math import pi, atan2, sin, cos, sqrt, log, exp, factorial

R, HOT = 0.1, 100.0           # plate radius in m; hot clamp in C
M = HOT / 2                   # largest |u - 50| anywhere: the size the slope bounds use


def u(x, y):                  # closed form: 50 + (100/pi) * angle, inside the unit disc
    return HOT / 2 + HOT / pi * atan2(2 * y, 1 - x * x - y * y)


def poisson(x, y, a, b, n=20000):  # rim held at HOT on angles a..b, 0 elsewhere: kernel sum
    s, w = 0.0, (b - a) / n
    for k in range(n):
        t = a + (k + 0.5) * w
        s += (1 - x * x - y * y) / ((x - cos(t)) ** 2 + (y - sin(t)) ** 2)
    return HOT * s * w / (2 * pi)


def series(x, y, n=21):     # 50 + (200/pi) sum over odd k of r^k sin(k t) / k
    r, t = sqrt(x * x + y * y), atan2(y, x)
    return HOT / 2 + 2 * HOT / pi * sum(r ** k * sin(k * t) / k for k in range(1, n + 1, 2))


def arc(x, y, w):             # rim held at 1 on angles pi/2-w..pi/2+w: harmonic measure
    a, b = pi / 2 - w, pi / 2 + w
    px, py, qx, qy = cos(b) - x, sin(b) - y, cos(a) - x, sin(a) - y
    return atan2(py * qx - px * qy, px * qx + py * qy) / pi - w / pi


def close(a, b, tol):
    assert abs(a - b) <= tol, (a, b)


c0 = [u(0, 0), poisson(0, 0, 0, pi), series(0, 0)]
print("centre: closed form %.4f, Poisson sum %.4f, series %.4f C" % tuple(c0))
for y in (0.5, -0.5):
    v = [u(0, y), poisson(0, y, 0, pi), series(0, y)]
    print("at y = %+.0f cm: closed form %.4f, Poisson sum %.4f, series %.4f C" % (y * 10, *v))
    close(v[0], v[1], 1e-6); close(v[0], v[2], 1e-6)  # inside the tail bound
tail = 2 * HOT / pi * 0.5 ** 23 / 23 / 0.75  # odd terms from k = 23 on, a geometric tail
print("series to k = 21, tail bound at r = 5 cm: %.7f C" % tail)
ring = [u(0.5 * cos(2 * pi * k / 3600), 0.5 * sin(2 * pi * k / 3600)) for k in range(3600)]
lo, hi = min(ring), max(ring)
c = c0[0]                     # centre value: Harnack needs nothing else
print("Harnack on the 5 cm circle: floor u(0)/3 = %.4f, cap 3u(0) = %.4f C" % (c / 3, 3 * c))
print("actual on the 5 cm circle: min %.4f, max %.4f, ratio %.4f <= 9" % (lo, hi, hi / lo))
assert c / 3 <= lo and hi <= 3 * c and hi / lo <= 9
pts = [i / 10 for i in range(11)]
print("chart, distance down, cm: " + ", ".join("%d" % (10 * r) for r in pts))
print("chart, true temperature:  " + ", ".join("%.2f" % u(0, -r) for r in pts))
print("chart, Harnack floor:     " + ", ".join("%.2f" % (c * (1 - r) / (1 + r)) for r in pts))
assert all(u(0, -r) >= c * (1 - r) / (1 + r) - 1e-12 for r in pts)
for deg in (90, 10, 1, 0.1):  # a narrower hot arc pushes the ratio down to the floor 1/3
    w = deg * pi / 180
    q = arc(0, -0.5, w) / arc(0, 0, w)
    q2 = poisson(0, -0.5, pi / 2 - w, pi / 2 + w) / poisson(0, 0, pi / 2 - w, pi / 2 + w)
    print("hot arc half-width %4.1f deg: u(5 cm down)/u(centre) = %.6f (kernel sum %.6f)" % (deg, q, q2))
    close(q, q2, 1e-6); assert q >= 1 / 3
pk2 = lambda y: (1 - y * y) / (1 - y) ** 2          # 2-D Poisson kernel, pole at the top
pk3 = lambda y: (1 - y * y) / abs(1 - y) ** 3       # 3-D Poisson kernel, pole at the top
r3 = [1.5 / 0.5, pk2(0.5) / pk2(-0.5), pk3(0.5) / pk3(-0.5)]
print("Harnack max/min on the half ball, 3^d: d=1 %.4f, d=2 %.4f, d=3 %.4f" % tuple(r3))
close(r3[1], 9, 1e-9); close(r3[2], 27, 1e-9)
h = 1e-5                      # slopes in K per m: scaled slope / R
g0 = 2 * HOT / pi / R
fd = (u(0, h) - u(0, -h)) / (2 * h) / R
print("slope at centre: exact %.4f, centred difference %.4f, bound 2M/R = %.4f K/m" % (g0, fd, 2 * M / R))
close(g0, fd, 1e-3); assert g0 <= 2 * M / R
for d in (0.05, 0.01, 0.001):  # approaching the rim point where 100 C meets 0 C
    s = 1 - d / R
    ex = 2 * HOT / pi / (1 - s * s) / R
    fd = (u(s, h) - u(s, -h)) / (2 * h) / R
    print("slope %5.1f mm from the jump: exact %.1f, centred difference %.1f, bound 2M/d = %.1f K/m"
          % (d * 1000, ex, fd, 2 * M / d))
    close(ex, fd, 1e-3 * ex); assert ex <= 2 * M / d
exk = []                      # the formula's k-th slopes, checked by differences below
for k in (1, 3, 5, 7):        # k-th slope up the middle at the centre, scaled (per R^k)
    ex, bd = 2 * HOT / pi * factorial(k - 1), M * (2 * k) ** k
    exk.append(ex)
    print("k = %d: |d^k u/dy^k| at centre exact %.2f, bound M(2k)^k = %.0f" % (k, ex, bd))
    assert ex <= bd
d3 = (u(0, 2e-2) - 2 * u(0, 1e-2) + 2 * u(0, -1e-2) - u(0, -2e-2)) / (2 * 1e-6)
d5 = (u(0, 3e-2) - 4 * u(0, 2e-2) + 5 * u(0, 1e-2) - 5 * u(0, -1e-2) + 4 * u(0, -2e-2) - u(0, -3e-2)) / (2 * 1e-10)
print("third and fifth slopes by differences, step 0.01: %.2f and %.2f (formula %.2f and %.2f)" % (-d3, d5, exk[1], exk[2]))
close(-d3, exk[1], 0.1); close(d5, exk[2], 5e-3 * exk[2])  # step^2 error: 0.1 % at k = 5
ty = sum(2 * HOT / pi * (-1) ** (k // 2) * 0.5 ** k / k for k in range(1, 200, 2))
print("Taylor series up the middle at y = 5 cm: %.6f, closed form %.6f" % (HOT / 2 + ty, u(0, 0.5)))
close(HOT / 2 + ty, u(0, 0.5), 1e-9)
for big in (10, 100, 1000):   # Liouville by Harnack in 3-D: bounds at 1 m from the centre
    print("3-D Harnack, ball of %4d m, point 1 m out: %.6f <= u/u(0) <= %.6f"
          % (big, big * (big - 1) / (big + 1) ** 2, big * (big + 1) / (big - 1) ** 2))
print("Liouville slope bound d*M/r, M = %.0f C, d = 2: r = 1 m %.4f, r = 1 km %.4f K/m" % (M, 2 * M / 1, 2 * M / 1000))
x0, y0, rho, num, den, nq = 0.3, 0.2, 0.3, 0.0, 0.0, 0.0
for i in range(200):          # Weyl: a radial smoothing bump leaves a harmonic function unchanged
    s = (i + 0.5) / 200
    eta = exp(-1 / (1 - s * s)) * s
    for j in range(64):
        t = 2 * pi * j / 64
        xx, yy = x0 + rho * s * cos(t), y0 + rho * s * sin(t)
        num += eta * u(xx, yy); nq += eta * (xx * xx + yy * yy); den += eta
print("Weyl smoothing at (3, 2) cm, radius 3 cm: smoothed %.6f, point value %.6f C" % (num / den, u(x0, y0)))
print("same smoothing of |x|^2 (not harmonic): smoothed %.6f, point value %.6f" % (nq / den, x0 * x0 + y0 * y0))
close(num / den, u(x0, y0), 1e-9); assert nq / den - 0.13 > 0.01
print("breaks, sign: u = 100y/R has centre 0, Harnack forces 0, true value at 5 cm %.1f C" % (100 * 0.5))
ph = lambda r: 10 * log(R / r)  # point heater at the centre, rim 0 C
print("breaks, point heater: %.4f C at 5 cm, %.4f C at 1 micron, ratio %.2f > 9"
      % (ph(0.05), ph(1e-6), ph(1e-6) / ph(0.05)))
assert ph(1e-6) / ph(0.05) > 9
a, b = u(0, 0.99), u(0, -0.99)
print("breaks, circle reaching 9.9 cm: %.4f and %.4f C, ratio %.1f > 9" % (a, b, a / b))
sch = lambda x, y: (x * x - y * y) * sqrt(-log(sqrt(x * x + y * y)))  # scaled, near 0
for e in (2, 4, 8, 16):
    s = e * log(10)
    print("breaks, continuous f at r = 10^-%d: f = %.4f, u_x1x1 = %.4f" % (e, 2 / sqrt(s) + 0.25 * s ** -1.5,
                                                                       2 * sqrt(s) + 0.5 / sqrt(s)))
hh, y1 = 1e-4, 1e-2
uxx = (sch(hh, y1) - 2 * sch(0, y1) + sch(-hh, y1)) / hh ** 2
lap = uxx + (sch(0, y1 + hh) - 2 * sch(0, y1) + sch(0, y1 - hh)) / hh ** 2
print("breaks, differences at r = 0.01: u_x1x1 %.4f, f %.4f" % (uxx, lap))
close(uxx, 2 * sqrt(log(100)) + 0.5 / sqrt(log(100)), 1e-3)
close(lap, 2 / sqrt(log(100)) + 0.25 * log(100) ** -1.5, 1e-3)
print("ALL CHECKS PASS")
