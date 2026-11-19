# Minimal surfaces and soap films -- the check behind the card.  Standard library only.
# A soap film spans two coaxial wire rings of radius 5 cm, 4 cm apart.  Mean curvature H
# comes from finite differences of any chart, not the catenoid's closed form; area by
# Simpson's rule; the first variation by pushing the film; a polygon profile minimised.
import math
RING, HALF = 5.0, 2.0                  # ring radius (cm); rings at z = -2 and z = +2 (cm)
def f6(v): return f"{0.0 if abs(v) < 5e-7 else v:.6f}"
def bisect(f, lo, hi):
    flo = f(lo)
    for _ in range(200):
        mid = (lo + hi) / 2
        if (f(mid) < 0) == (flo < 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2
def asinh(x): return math.log(x + math.sqrt(x * x + 1))
def add(a, b, k=1.0): return tuple(a[i] + k * b[i] for i in range(3))
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def tangents(r, u, v, d=1e-5):         # 2d times r_u and r_v, by central differences
    return add(r(u + d, v), r(u - d, v), -1.0), add(r(u, v + d), r(u, v - d), -1.0), 2 * d
def shape(r, u, v, d=1e-4):            # E, F, G, H, K, k1, k2 from the chart alone
    p = r(u, v)
    ru = tuple(x / (2 * d) for x in add(r(u + d, v), r(u - d, v), -1.0))
    rv = tuple(x / (2 * d) for x in add(r(u, v + d), r(u, v - d), -1.0))
    ruu = tuple(x / (d * d) for x in add(add(r(u + d, v), r(u - d, v)), p, -2.0))
    rvv = tuple(x / (d * d) for x in add(add(r(u, v + d), r(u, v - d)), p, -2.0))
    ruv = tuple(x / (4 * d * d) for x in add(add(r(u + d, v + d), r(u - d, v - d)), add(r(u + d, v - d), r(u - d, v + d)), -1.0))
    c = cross(ru, rv); n = tuple(x / math.sqrt(dot(c, c)) for x in c)
    E, F, G, L, M, N = dot(ru, ru), dot(ru, rv), dot(rv, rv), dot(ruu, n), dot(ruv, n), dot(rvv, n)
    W = E * G - F * F; H = (E * N - 2 * F * M + G * L) / (2 * W); K = (L * N - M * M) / W
    s = math.sqrt(max(H * H - K, 0.0))
    return E, F, G, H, K, H + s, H - s
def area(r, u0, u1, v0, v1, n):        # Simpson's rule on sqrt(EG - F^2)
    hu, hv, tot = (u1 - u0) / n, (v1 - v0) / n, 0.0
    w = [1 if i in (0, n) else (4 if i % 2 else 2) for i in range(n + 1)]
    for i in range(n + 1):
        for j in range(n + 1):
            ru, rv, s = tangents(r, u0 + i * hu, v0 + j * hv)
            c = cross(ru, rv); tot += w[i] * w[j] * math.sqrt(dot(c, c)) / (s * s)
    return tot * hu * hv / 9
def simpson(f, a, b, n=400):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else (4 if i % 2 else 2)) * f(a + i * h) for i in range(n + 1))
def cat_area(a, h): return math.pi * a * (2 * h + a * math.sinh(2 * h / a))
T = bisect(lambda t: t * math.tanh(t) - 1, 0.5, 2.0)        # where a cosh(h/a) is least
def waists(h, R=RING):                 # the two catenoids a cosh(h/a) = R: fat, thin
    f = lambda a: a * math.cosh(h / a) - R
    return bisect(f, h / T, R), bisect(f, h / 30, h / T)
a, thin = waists(HALF)
print("rings: radius", f6(RING), "cm, separation", f6(2 * HALF), "cm")
print("catenoid waists a: fat", f6(a), "thin", f6(thin), "cm")
cat1 = lambda z, th: (a * math.cosh(z / a) * math.cos(th), a * math.cosh(z / a) * math.sin(th), z)
cat2 = lambda s, th: (math.sqrt(a * a + s * s) * math.cos(th), math.sqrt(a * a + s * s) * math.sin(th), a * asinh(s / a))
S = a * math.sinh(HALF / a)            # arc length from waist to ring along the profile
for name, r, u in (("chart 1 (z, theta) at ring ", cat1, HALF), ("chart 2 (s, theta) at ring ", cat2, S),
                   ("chart 1 (z, theta) at waist", cat1, 0.0), ("chart 2 (s, theta) at waist", cat2, 0.0)):
    E, F, G, H, K, k1, k2 = shape(r, u, 0.7)
    print(name, "E", f6(E), "G", f6(G), "k1", f6(k1), "k2", f6(k2), "H", f6(H), "K", f6(K))
    rho = a * math.cosh(u / a) if r is cat1 else math.sqrt(a * a + u * u)
    assert abs(k1 - a / rho ** 2) < 1e-5 and abs(H) < 1e-5     # closed form k1 = a / rho^2 = -k2
print("closed form a/rho^2: ring", f6(a / RING ** 2), "waist", f6(1 / a))
A1, A2, Ac = area(cat1, -HALF, HALF, 0, 2 * math.pi, 60), area(cat2, -S, S, 0, 2 * math.pi, 60), cat_area(a, HALF)
print("film area: chart 1", f6(A1), "chart 2", f6(A2), "closed form", f6(Ac))
assert abs(A1 - Ac) < 1e-4 and abs(A2 - Ac) < 1e-4
print("hand: h/a", f6(HALF / a), "cosh(h/a)", f6(math.cosh(HALF / a)), "a cosh(h/a)", f6(a * math.cosh(HALF / a)), "sinh(2h/a)", f6(math.sinh(2 * HALF / a)))
print("      s at ring", f6(S), "cylinder minus film", f6(2 * math.pi * RING * 2 * HALF - Ac), "cylinder int phi dA", f6(2 * math.pi * RING * HALF))
print("rivals: cylinder", f6(2 * math.pi * RING * 2 * HALF), "two discs", f6(2 * math.pi * RING ** 2), "thin catenoid", f6(cat_area(thin, HALF)))
def pushed(rho, drho, phi, eps):       # area after moving each point eps*phi along n (toward the axis)
    def pt(z):
        w = math.sqrt(1 + drho(z) ** 2)
        return rho(z) - eps * phi(z) / w, z + eps * phi(z) * drho(z) / w
    def band(z, d=1e-4):
        (r0, z0), (r1, z1) = pt(z - d), pt(z + d)
        return 2 * math.pi * pt(z)[0] * math.hypot(r1 - r0, z1 - z0) / (2 * d)
    return simpson(band, -HALF, HALF)
bump = lambda z: math.cos(math.pi * z / (2 * HALF)) ** 2      # 1 at the waist, 0 at both rings
for name, rho, drho, Hc in (("catenoid", lambda z: a * math.cosh(z / a), lambda z: math.sinh(z / a), lambda z: 0.0),
                            ("cylinder", lambda z: RING, lambda z: 0.0, lambda z: 1 / (2 * RING))):
    e = 1e-4
    slope = (pushed(rho, drho, bump, e) - pushed(rho, drho, bump, -e)) / (2 * e)
    pred = -2 * simpson(lambda z: Hc(z) * bump(z) * 2 * math.pi * rho(z) * math.sqrt(1 + drho(z) ** 2), -HALF, HALF)
    print("first variation,", name, "dA/d(eps)", f6(slope), "predicted -2 int H phi dA", f6(pred), "H", f6(Hc(0.0)))
    assert abs(slope - pred) < 1e-5
for name, w in (("fat", a), ("thin", thin)):
    rho, drho = (lambda z, w=w: w * math.cosh(z / w)), (lambda z, w=w: math.sinh(z / w))
    base = pushed(rho, drho, bump, 0.0)
    d = [pushed(rho, drho, bump, e) - base for e in (0.05, -0.05)]
    print("second variation,", name, "catenoid: change at eps +0.05", f6(d[0]), "at -0.05", f6(d[1]))
    assert (min(d) > 0) == (name == "fat")
def polygon(n, steps):                 # least-area polygon profile, ends pinned on the rings
    dz, rho = 2 * HALF / n, [RING] * (n + 1)
    for _ in range(steps):
        g = [0.0] * (n + 1)
        for i in range(n):
            l = math.hypot(dz, rho[i + 1] - rho[i]); q = (rho[i] + rho[i + 1]) * (rho[i + 1] - rho[i]) / l
            g[i] += math.pi * (l - q); g[i + 1] += math.pi * (l + q)
        for i in range(1, n): rho[i] -= 0.9 * dz / (4 * math.pi * RING) * g[i]
    return rho[n // 2], sum(math.pi * (rho[i] + rho[i + 1]) * math.hypot(dz, rho[i + 1] - rho[i]) for i in range(n))
for n in (10, 20):
    wst, ar = polygon(n, 8000)
    print("polygon,", n, "bands: waist", f6(wst), "error", f6(wst - a), "area", f6(ar))
e10, e20 = polygon(10, 8000)[0] - a, polygon(20, 8000)[0] - a
print("polygon waist error ratio", f6(e10 / e20))
assert 3.5 < e10 / e20 < 4.5
gmax = 2 * T / math.cosh(T)            # widest gap a catenoid spans, in ring radii
def least_radius(h):                   # min over a of a cosh(h/a), by golden-section search
    lo, hi = h / 5, 5 * h
    for _ in range(200):
        m1, m2 = lo + 0.382 * (hi - lo), hi - 0.382 * (hi - lo)
        if m1 * math.cosh(h / m1) < m2 * math.cosh(h / m2): hi = m2
        else: lo = m1
    return lo * math.cosh(h / lo)
gscan = 2 * bisect(lambda h: least_radius(h) - RING, 1.0, 5.0) / RING
print("widest gap / radius: t tanh t = 1 gives", f6(gmax), "t", f6(T), "; search gives", f6(gscan), "; gap", f6(gmax * RING), "cm")
assert abs(gmax - gscan) < 1e-6
print("rings 7 cm apart: thinnest catenoid end radius", f6(least_radius(3.5)), "> 5, so no film of that shape")
gdisc = 2 * bisect(lambda h: cat_area(waists(h)[0], h) - 2 * math.pi * RING ** 2, 1.0, 3.3)
print("discs beat the catenoid beyond separation", f6(gdisc), "cm =", f6(gdisc / RING), "radii")
for gap in (1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 6.6):
    fa, ta = waists(gap / 2)
    print("separation", f6(gap), "fat a", f6(fa), "area", f6(cat_area(fa, gap / 2)), "thin a", f6(ta), "area", f6(cat_area(ta, gap / 2)))
c = 1.0 / 25                           # wing 19's saddle z = (x^2 - y^2)/25 cm on a 5 cm loop
sad = lambda x, y: (x, y, c * (x * x - y * y))
for x, y in ((0.0, 0.0), (5.0, 0.0), (3.0, 4.0)):
    fx, fy, fxx, fyy = 2 * c * x, -2 * c * y, 2 * c, -2 * c
    Hf = ((1 + fx * fx) * fyy + (1 + fy * fy) * fxx) / (2 * (1 + fx * fx + fy * fy) ** 1.5)
    E, F, G, H, K, k1, k2 = shape(sad, x, y)
    print("Laplace saddle at", f6(x), f6(y), "H", f6(H), "formula", f6(Hf), "k1", f6(k1), "k2", f6(k2), "Laplace fxx+fyy", f6(fxx + fyy))
    assert abs(H - Hf) < 1e-6
E, F, G, H, K, k1, k2 = shape(lambda u, v: (v * math.cos(u), v * math.sin(u), u), 0.7, 2.0)
print("helicoid, rise 1 cm per radian, 2 cm out: H", f6(H), "K", f6(K), "closed form K", f6(-1 / (1 + 4) ** 2))
assert abs(H) < 1e-6 and abs(K + 1 / (1 + 4) ** 2) < 1e-6
cyl = lambda z, th: (RING * math.cos(th), RING * math.sin(th), z)   # n toward the axis; swap the grid and n points away
Hin, Hout = shape(cyl, 0.5, 0.7)[3], shape(lambda th, z: cyl(z, th), 0.7, 0.5)[3]
print("cylinder by finite differences: H", f6(Hin), "with n toward the axis,", f6(Hout), "with n away from it")
assert abs(Hin - 1 / (2 * RING)) < 1e-6 and abs(Hout + 1 / (2 * RING)) < 1e-6
print("cylinder film, 0.025 N/m per face, H = 10 1/m: pressure 4 gamma H", f6(4 * 0.025 * 10), "Pa")
print("figure, z", " ".join(f"{210 + 30 * z:.1f},{190 - 30 * a * math.cosh(z / a):.1f}" for z in [k / 4 - 2 for k in range(17)]))
print("figure, thin", " ".join(f"{210 + 30 * z:.1f},{190 - 30 * thin * math.cosh(z / thin):.1f}" for z in [k / 4 - 2 for k in range(17)]))
print("ALL CHECKS PASS")
