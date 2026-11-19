# Einstein equations in outline: check that the Schwarzschild metric has Ric = 0 outside the Sun,
# then trace a grazing starlight ray through it and read off the bending.
from math import sin, log, exp, pi

GM = 1.3271244e20      # Sun's GM, m^3/s^2, IAU 2015 nominal
c = 299792458.0        # speed of light, m/s, exact
Rsun = 6.957e8         # Sun's radius, m, IAU 2015 nominal
ARCSEC = 648000 / pi   # arcseconds in one radian
rs = 2 * GM / c ** 2   # Schwarzschild radius, m

def show(label, v, d=6):
    print(f"{label:<44}{(0.0 if abs(v) < 5e-13 else v):>16.{d}f}")

# ---- road 1: Ricci tensor from the metric alone, by finite differences (units: r_s = 1, c = 1) ----
def schwarzschild(p):  # coordinates (t, r, phi, theta): phi down from the pole, theta round it
    A = 1 - 1 / p[1]
    return [-A, 1 / A, p[1] ** 2, (p[1] * sin(p[2])) ** 2]
def time_only(p):      # Newton's guess: slow the clocks, leave space flat
    return [-(1 - 1 / p[1]), 1.0, p[1] ** 2, (p[1] * sin(p[2])) ** 2]

def shift(p, i, s):
    q = list(p); q[i] += s; return q

def christoffel(metric, p, h):  # G[l][j][k] = 1/2 g^ll (d_j g_lk + d_k g_lj - d_l g_jk), g diagonal
    g = metric(p)
    dg = [[(a - b) / (2 * h) for a, b in zip(metric(shift(p, m, h)), metric(shift(p, m, -h)))] for m in range(4)]
    def d(m, i, j):
        return dg[m][i] if i == j else 0.0
    return [[[0.5 / g[l] * (d(j, l, k) + d(k, l, j) - d(l, j, k)) for k in range(4)] for j in range(4)] for l in range(4)]

def curvature(metric, p, h=1e-4):  # Rm(l,i,j,k) = R^l_kij, then Ric_jk = sum over i of R^i_jik
    G = christoffel(metric, p, h)
    dG = [[[[(a - b) / (2 * h) for a, b in zip(ra, rb)] for ra, rb in zip(A, B)]
           for A, B in zip(christoffel(metric, shift(p, i, h), h), christoffel(metric, shift(p, i, -h), h))]
          for i in range(4)]
    def Rm(l, i, j, k):
        return (dG[i][l][j][k] - dG[j][l][i][k]
                + sum(G[l][i][m] * G[m][j][k] - G[l][j][m] * G[m][i][k] for m in range(4)))
    Ric = [[sum(Rm(i, i, j, k) for i in range(4)) for k in range(4)] for j in range(4)]
    return Rm, Ric

def largest(Ric):
    return max(abs(Ric[j][k]) for j in range(4) for k in range(4))

# ---- road 2: closed forms for -A dt^2 + B dr^2 + r^2 dOmega^2, with A = e^(2a), B = e^(2b) ----
def ricci_closed(a1, a2, b1, a, b, r):  # a1 = a', a2 = a'', b1 = b'
    tt = (a2 + a1 * a1 - a1 * b1 + 2 * a1 / r) * exp(2 * (a - b))
    rr = -a2 - a1 * a1 + a1 * b1 + 2 * b1 / r
    pp = exp(-2 * b) * (r * (b1 - a1) - 1) + 1
    return tt, rr, pp

worst = []
for r in (1.5, 3.0, 6.0):
    Rm, Ric = curvature(schwarzschild, [0.0, r, 1.0, 0.5])
    worst.append(largest(Ric))
    show(f"r = {r:3.1f} r_s: largest |Ric|, step 1e-4", worst[-1], 9)
    show(f"  radial tidal stretch -R^r_trt/A", -Rm(1, 1, 0, 0) / (1 - 1 / r), 9)
    show(f"  closed form 1/r^3", 1 / r ** 3, 9)
    if r == 3.0:
        st3, coarse = -Rm(1, 1, 0, 0) / (1 - 1 / r), largest(curvature(schwarzschild, [0.0, r, 1.0, 0.5], 1e-3)[1])
        show(f"  largest |Ric|, step 1e-3", coarse, 9)
A = 1 - 1 / 3.0
a1, a2 = 1 / (2 * 9 * A), -5 / (2 * 81 * A * A)          # a = (1/2) ln(1 - 1/r) at r = 3
closed = ricci_closed(a1, a2, -a1, 0.5 * log(A), -0.5 * log(A), 3.0)
show("closed form, Schwarzschild, largest |Ric|", max(abs(v) for v in closed), 9)
Rm0, Ric0 = curvature(time_only, [0.0, 3.0, 1.0, 0.5])
c0 = ricci_closed(a1, a2, 0.0, 0.5 * log(A), 0.0, 3.0)
for j, n in enumerate(["tt", "rr", "phiphi"]):
    show(f"time-only metric, r = 3: Ric_{n}", Ric0[j][j], 9)
    show(f"  closed form", c0[j], 9)

# ---- the ray: Hamilton's equations for light give w'' = F'(w)/2, w = r0/r, the angle as clock ----
def bend(eps, kind, N=40000):  # from closest approach (w = 1) out to infinity (w = 0), RK4
    def acc(w):
        if kind == "full":
            return -w + 1.5 * eps * w * w
        if kind == "time":
            return (1 - eps) * eps / (2 * (1 - eps * w) ** 2) - w
        return -0.5 * eps * (1 - w * w) - w * (1 - eps * w)   # space part only
    h, n, w, v = 2.0 / N, 0, 1.0, 0.0
    while True:
        k1w, k1v = v, acc(w)
        k2w, k2v = v + h / 2 * k1v, acc(w + h / 2 * k1w)
        k3w, k3v = v + h / 2 * k2v, acc(w + h / 2 * k2w)
        k4w, k4v = v + h * k3v, acc(w + h * k3w)
        nw, nv = w + h / 6 * (k1w + 2 * k2w + 2 * k3w + k4w), v + h / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)
        if nw < 0:
            return 2 * h * (n + w / (w - nw)) - pi   # twice the swept angle, minus a straight line
        n, w, v = n + 1, nw, nv

eps = rs / Rsun
show("Schwarzschild radius of the Sun r_s, m", rs, 2)
show("r_s / R_sun", eps, 10)
weak = 2 * eps
full, tpart, spart = bend(eps, "full"), bend(eps, "time"), bend(eps, "space")
show("arcseconds in one radian", ARCSEC, 3)
show("weak field 2 r_s / r0, radians", weak, 10)
show("weak field 2 r_s / r0, arcsec", weak * ARCSEC, 4)
show("ray traced, full metric, arcsec", full * ARCSEC, 4)
show("ray traced, time part only, arcsec", tpart * ARCSEC, 4)
show("ray traced, space part only, arcsec", spart * ARCSEC, 4)
second = (15 * pi / 16 - 1) * eps * eps
show("traced minus weak field, microarcsec", (full - weak) * ARCSEC * 1e6, 3)
show("second-order term, microarcsec", second * ARCSEC * 1e6, 3)
show("Newton's tide 2GM/R^3 at the surface, 1/s^2", 2 * GM / Rsun ** 3, 12)
show("same from r_s c^2 / r^3, 1/s^2", rs * c * c / Rsun ** 3, 12)
show("measured 2004: gamma", 0.99983, 5)
show("measured 2004: (1+gamma)/2 x prediction", (1 + 0.99983) / 2 * weak * ARCSEC, 5)
show("measured 2004: standard error, arcsec", 0.00045 / 2 * weak * ARCSEC, 5)

# ---- what breaks ----
show("wrong: sign of r_s flipped, arcsec", bend(-eps, "full") * ARCSEC, 4)
ns = 2 * 1.4 * GM / c ** 2 / 12000                  # neutron star: 1.4 Suns, radius 12 km
show("neutron star r_s / R", ns, 4)
show("neutron star weak field, degrees", 2 * ns * 180 / pi, 2)
show("neutron star ray traced, degrees", bend(ns, "full") * 180 / pi, 2)
show("try: Jupiter's limb, arcsec", 4 * 1.26686534e17 / (c * c * 7.1492e7) * ARCSEC, 4)

# ---- chart: deflection against closest approach ----
xs = [1, 2, 3, 4, 5, 6, 8, 10]
print("chart r0/R_sun " + " ".join(f"{x:6d}" for x in xs))
print("einstein       " + " ".join(f"{bend(eps / x, 'full', 4000) * ARCSEC:6.3f}" for x in xs))
print("newton         " + " ".join(f"{bend(eps / x, 'time', 4000) * ARCSEC:6.3f}" for x in xs))

assert max(worst) < 1e-6 and coarse > 10 * worst[1], "Schwarzschild has Ric = 0, error shrinks with step"
assert abs(st3 - 1 / 27) < 1e-6, "tidal stretch against closed form 1/r^3"
assert max(abs(v) for v in closed) < 1e-12, "closed-form Ric vanishes"
assert abs(Ric0[1][1] - c0[1]) < 1e-6 and abs(c0[1]) > 0.01, "time-only metric fails Ric = 0"
assert abs((full - weak) - second) < 5e-14, "traced ray against weak field plus second order"
assert abs(tpart + spart - full) < 1e-10, "time half plus space half"
assert abs(bend(ns, "full") - bend(ns, "full", 80000)) < 1e-9, "neutron star at two step sizes"
print("ALL CHECKS PASS")
