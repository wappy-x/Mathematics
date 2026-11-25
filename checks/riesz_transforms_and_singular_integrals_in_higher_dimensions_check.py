# Riesz transforms: for -Lap u = f in the plane, d1 d2 u = R1 R2 f. Source f = exp(-|x|^2).
from math import exp, log, pi, sqrt, sin, cos

EG = 0.5772156649015329  # Euler's constant, used only in the area's closed form


def f(x1, x2):
    return exp(-(x1 * x1 + x2 * x2))


def g(r):  # radial factor: d1 d2 u = cos(t) sin(t) g(r), from solving the radial equation
    s = r * r
    if s < 1e-2:
        return s / 2 - s * s / 3 + s ** 3 / 8 - s ** 4 / 30
    return (1 - (1 + s) * exp(-s)) / s


def D(x1, x2):  # closed form of d1 d2 u
    r2 = x1 * x1 + x2 * x2
    return x1 * x2 / r2 * g(sqrt(r2))


def K(x1, x2):  # kernel of R1 R2: d1 d2 of the point-source potential -ln|x|/(2 pi)
    return x1 * x2 / (pi * (x1 * x1 + x2 * x2) ** 2)


def gamma_half(m):  # Gamma(m/2) for a whole number m >= 1, by Gamma(z + 1) = z Gamma(z)
    v, z = (1.0, 1.0) if m % 2 == 0 else (sqrt(pi), 0.5)
    while z < m / 2 - 1e-9:
        v, z = v * z, z + 1
    return v


def radial(fn, s0, s1, n=20000):  # integral of fn(r) r dr for r = e^s, midpoint in s
    h = (s1 - s0) / n
    return sum(fn(exp(s0 + (k + 0.5) * h)) * exp(2 * (s0 + (k + 0.5) * h)) for k in range(n)) * h


def riesz_mult(rho, phi, eps=1e-3, R=20.0, nr=4000, nt=512):  # transform of the cut kernel x_j/(2 pi |x|^3)
    a1 = a2 = 0.0
    hr, ht = (R - eps) / nr, 2 * pi / nt
    for a in range(nr):
        r = eps + (a + 0.5) * hr
        for b in range(nt):
            t = (b + 0.5) * ht
            s = sin(2 * pi * rho * r * cos(t - phi)) / r
            a1 += cos(t) * s
            a2 += sin(t) * s
    return -a1 * hr * ht / (2 * pi), -a2 * hr * ht / (2 * pi)  # imaginary parts; real parts cancel


def kernel_road(x1, x2, rmax=7.0, nr=700, nt=128):  # p.v. integral of K(x - y) f(y), rings round x
    tot, hr, ht = 0.0, rmax / nr, 2 * pi / nt
    for a in range(nr):
        r = (a + 0.5) * hr
        ring = sum(cos(t) * sin(t) * f(x1 - r * cos(t), x2 - r * sin(t)) for t in ((b + 0.5) * ht for b in range(nt)))
        tot += ring / (pi * r)
    return tot * hr * ht


def mult_road(x1, x2, sign=-1.0, rmax=3.0, nr=300, nt=128):  # inverse transform of sign xi1 xi2/|xi|^2 times pi exp(-pi^2 |xi|^2)
    tot, hr, ht = 0.0, rmax / nr, 2 * pi / nt
    for a in range(nr):
        p = (a + 0.5) * hr
        for b in range(nt):
            t = (b + 0.5) * ht
            tot += sign * cos(t) * sin(t) * pi * exp(-pi * pi * p * p) * cos(2 * pi * p * (x1 * cos(t) + x2 * sin(t))) * p
    return tot * hr * ht


ang = [k * 2 * pi / 36000 for k in range(36000)]  # every hundredth of a degree, 45 included
cs = [cos(t) * sin(t) for t in ang]
big = max(abs(c) for c in cs)
print("multiplier -xi1 xi2/|xi|^2 of R1 R2: largest size over 36000 directions %.6f; mean square %.6f" % (big, sum(c * c for c in cs) / 36000))
assert abs(big - 0.5) < 1e-6 and abs(sum(c * c for c in cs) / 36000 - 0.125) < 1e-9
S = [sum(abs(c) ** p for c in cs) * 2 * pi / 36000 for p in (1, 2, 4)]
print("ring sums of |cos sin|^p: p=1 %.6f (2), p=2 %.6f (pi/4 = %.6f), p=4 %.6f (3pi/64 = %.6f)" % (S[0], S[1], pi / 4, S[2], 3 * pi / 64))
assert abs(S[0] - 2) < 1e-6 and abs(S[1] - pi / 4) < 1e-9 and abs(S[2] - 3 * pi / 64) < 1e-9
x, y, h = 0.3, 0.4, 1e-5
gx, gy = (K(x + h, y) - K(x - h, y)) / (2 * h), (K(x, y + h) - K(x, y - h)) / (2 * h)
print("kernel x1 x2/(pi |x|^4): size constant %.6f, signed ring sum %.6f, |grad K| at (0.3, 0.4) %.6f, 1/(pi r^3) %.6f, so B <= 8"
      % (big / pi, abs(sum(cs)) * 2 * pi / 36000, sqrt(gx * gx + gy * gy), 1 / (pi * 0.5 ** 3)))
assert abs(sqrt(gx * gx + gy * gy) - 1 / (pi * 0.125)) < 1e-6
print("Riesz constants Gamma((n+1)/2)/pi^((n+1)/2): n=1 %.6f, n=2 %.6f, n=3 %.6f" % tuple(gamma_half(n + 1) / pi ** ((n + 1) / 2) for n in (1, 2, 3)))
assert abs(gamma_half(3) / pi ** 1.5 - 1 / (2 * pi)) < 1e-12
phi = pi / 6
for rho in (1.0, 2.0):
    m1, m2 = riesz_mult(rho, phi)
    lo, hi = pi * rho * 1e-3, 1 / (pi * rho * 20.0)
    print("|xi| = %.0f at 30 deg: kernel road m1 = %.6f i, m2 = %.6f i (exact %.6f i, %.6f i); m1 m2 = %.6f (exact %.6f); cut-off error at most %.6f + %.6f"
          % (rho, m1, m2, -cos(phi), -sin(phi), -m1 * m2, -cos(phi) * sin(phi), lo, hi))
    assert abs(m1 + cos(phi)) < lo + hi and abs(m2 + sin(phi)) < lo + hi
e2 = exp(-2)
print("by hand at (1, 1): r^2 = 2, e^-2 = %.6f, 3e^-2 = %.6f, 1 - 3e^-2 = %.6f, x1 x2/r^4 = 0.25" % (e2, 3 * e2, 1 - 3 * e2))
dk, dm = kernel_road(1.0, 1.0), mult_road(1.0, 1.0)
print("d1 d2 u at (1, 1): closed form %.6f, kernel road %.6f (cut at r = 7, f < %.1e there), multiplier road %.6f"
      % (D(1.0, 1.0), dk, exp(-(7 - sqrt(2)) ** 2), dm))
assert abs(dk - D(1.0, 1.0)) < 1e-5 and abs(dm - D(1.0, 1.0)) < 1e-5
I2 = radial(lambda r: g(r) ** 2, -12.0, 10.0)
n2f, n2D = sqrt(pi / 2), sqrt(S[1] * I2)
print("p = 2: ||f||_2^2 = pi/2 = %.6f, ||D||_2^2 = %.6f (pi/16 = %.6f); ||f||_2 = %.6f, ||D||_2 = %.6f; ratio %.6f, 1/sqrt(8) = %.6f; bound 0.5"
      % (pi / 2, S[1] * I2, pi / 16, n2f, n2D, n2D / n2f, 1 / sqrt(8)))
assert abs(n2D / n2f - 1 / sqrt(8)) < 1e-6
I4 = radial(lambda r: g(r) ** 4, -12.0, 10.0)
hg = 0.04
grid4 = sum(D(-8 + (i + 0.5) * hg, -8 + (j + 0.5) * hg) ** 4 for i in range(400) for j in range(400)) * hg * hg
n4f = (pi / 4) ** 0.25
print("p = 4: ||f||_4 = %.6f; ||D||_4^4 by rings %.8f, by a 0.04 grid %.8f; ratio %.6f; bound (p* - 1)/2 = 1.5"
      % (n4f, S[2] * I4, grid4, (S[2] * I4) ** 0.25 / n4f))
assert abs(grid4 - S[2] * I4) < 1e-4 * S[2] * I4 and (S[2] * I4) ** 0.25 / n4f < 1.5
print("p = 1: ||f||_1 = pi = %.6f" % pi)
for R in (10, 100, 1000, 10000):
    area = S[0] * radial(g, -12.0, log(R))
    print("area of |D| inside radius %d: rings %.6f, closed form 2 ln R + gamma - 1 = %.6f" % (R, area, 2 * log(R) + EG - 1))
    assert abs(area - (2 * log(R) + EG - 1)) < 1e-5
print("growth per factor of ten in R: 2 ln 10 = %.6f" % (2 * log(10)))
hq, cb = 0.002, 0.0
for i in range(500):
    for j in range(500):
        a, b = (i + 0.5) * hq, (j + 0.5) * hq
        if 0.01 < a * a + b * b < 1:
            cb += K(a, b)
print("checkerboard source sgn(x1 x2) on 0.1 < |x| < 1: d1 d2 u at 0 by a 0.002 grid %.6f, closed form (2/pi) ln 10 = %.6f" % (4 * cb * hq * hq, 2 / pi * log(10)))
assert abs(4 * cb * hq * hq - 2 / pi * log(10)) < 5e-3
for k in range(1, 7):
    print("checkerboard hole eps = 1e-%d: d1 d2 u at 0 = %.6f, source never above 1" % (k, 2 / pi * log(10 ** k)))
print("wrong sign, multiplier +xi1 xi2/|xi|^2: d1 d2 u at (1, 1) comes out %.6f" % mult_road(1.0, 1.0, 1.0))
rs = [0.25 * k for k in range(17)]
print("chart r: [" + ", ".join("%.2f" % r for r in rs) + "]")
print("chart f on the diagonal: [" + ", ".join("%.3f" % exp(-r * r) for r in rs) + "]")
print("chart d1 d2 u on the diagonal: [" + ", ".join("%.3f" % (g(r) / 2) for r in rs) + "]")
print("ALL CHECKS PASS")
