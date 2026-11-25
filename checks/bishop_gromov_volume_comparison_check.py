# Bishop-Gromov volume comparison -- the check behind the card.  Standard library only.
# A ball is everything within flying distance r of one point.  Roads: closed-form ball
# areas against areas built from Jacobi fields stepped by RK4; the flattened Earth's polar
# ball from its geometry against the Jacobi equation; a no-fly zone by rays against a grid.
from math import sin, cos, sqrt, pi, acos, asin, asinh, cosh, hypot

R = 6371.0                                   # the globe, km (a model)
A_EQ, B_POL = 6378.137, 6356.752314245       # WGS 84 semi-axes, km
def flat(r): return pi * r * r
def globe(r, rr=R): return 2 * pi * rr * rr * (1 - cos(r / rr))
def saddle(r): return 2 * pi * R * R * (cosh(r / R) - 1)

def rk4(F, y, h):
    k1 = F(y); k2 = F([a + h / 2 * b for a, b in zip(y, k1)])
    k3 = F([a + h / 2 * b for a, b in zip(y, k2)]); k4 = F([a + h * b for a, b in zip(y, k3)])
    return [a + h / 6 * (p + 2 * q + 2 * u + v) for a, p, q, u, v in zip(y, k1, k2, k3, k4)]

def jacobi_area(K, r, steps):                # state: gap per radian f, its rate, area
    y, h = [0.0, 1.0, 0.0], r / steps
    for _ in range(steps): y = rk4(lambda z: [z[1], -K * z[0], 2 * pi * z[0]], y, h)
    return y[2]

# ---- 1. the globe: ball of 1,000 km, two roads, and the ratio against flat ----
g1000, j1000 = globe(1000.0), jacobi_area(1 / R**2, 1000.0, 100)
print(f"globe ball r=1000 km   closed {g1000:.1f}   Jacobi RK4 {j1000:.1f}   flat {flat(1000.0):.1f}")
print(f"r/R {1000 / R:.6f}   cos(r/R) {cos(1000 / R):.6f}   2 pi R^2 {2 * pi * R * R:.1f}")
print(f"shortfall {flat(1000.0) - g1000:.1f} km2   1-cos(r/R) {1 - cos(1000 / R):.9f}")
radii = [1000.0, 2000.0, 5000.0, 10000.0, 15000.0, pi * R]
ratios = [globe(r) / flat(r) for r in radii]
print(f"ratio area/(pi r^2) at r = 1000 2000 5000 10000 15000 piR={pi * R:.2f}:", " ".join(f"{q:.6f}" for q in ratios))
print(f"doubling: area(2000)/area(1000) = {globe(2000.0) / g1000:.6f}  (Ric >= 0 caps it at 4)")

# ---- 2. the flattened Earth, ball round the North Pole: polar caps ----
C2 = A_EQ**2 - B_POL**2
def w(be): return sqrt(A_EQ**2 * sin(be)**2 + B_POL**2 * cos(be)**2)
def K_ell(be): return B_POL**2 / w(be)**4   # Gaussian curvature at parametric latitude be
def cap(be):                                  # cap area from the pole down to latitude be, closed form
    G = lambda u: u / 2 * sqrt(B_POL**2 + C2 * u * u) + B_POL**2 / (2 * sqrt(C2)) * asinh(sqrt(C2) * u / B_POL)
    return 2 * pi * A_EQ * (G(1.0) - G(sin(be)))
KMIN, KMAX = K_ell(pi / 2), K_ell(0.0)
RHO = 1 / sqrt(KMIN)                          # radius of the least curved comparison sphere
y, h, ok = [pi / 2, 0.0, 1.0, 0.0], 1.0, True # beta, Jacobi f, f', area by Jacobi
prev_ratio, prev_dens, prev_m, worst_riccati, rows = 1.0, 1.0, None, 0.0, []
for i in range(1, 5001):
    y = rk4(lambda z: [-1 / w(z[0]), z[2], -K_ell(z[0]) * z[1], 2 * pi * z[1]], y, h)
    s = i * h; be, f, fp, area = y
    m, m_model = fp / f, sqrt(KMIN) / (sin(sqrt(KMIN) * s) / cos(sqrt(KMIN) * s))
    dens = f / (sin(sqrt(KMIN) * s) / sqrt(KMIN))
    if prev_m is not None and s > 500:        # Riccati: m' + m^2 = -K, m' by a difference quotient
        mid_m, mid_K = (m + prev_m) / 2, K_ell(be + h / (2 * w(be)))
        worst_riccati = max(worst_riccati, abs((m - prev_m) / h + mid_m * mid_m + mid_K) / mid_K)
    prev_m = m
    ok = ok and m <= m_model + 1e-12 and dens <= prev_dens + 1e-12
    prev_dens = dens
    if i % 1000 == 0:
        ratio = area / globe(s, RHO)
        ok = ok and ratio <= prev_ratio + 1e-12; prev_ratio = ratio
        if i == 1000: print(f"pole r=1000  m = f'/f {m:.9f}  model {m_model:.9f}  flat 1/r {1 / s:.9f}")
        rows.append((s, A_EQ * cos(be), f, cap(be), area, globe(s, RHO), globe(s), ratio, area / flat(s)))
for s, fg, fj, ac, aj, am, a6371, q, qf in rows:
    print(f"pole r={s:5.0f}  f geom {fg:.6f}  f Jacobi {fj:.6f}  area cap {ac:.1f}  Jacobi {aj:.1f}")
    print(f"           model rho {am:.1f}  globe 6371 {a6371:.1f}  area/model {q:.9f}  area/flat {qf:.6f}")
print(f"Riccati m' + m^2 + K, worst relative error {worst_riccati:.9f}")
print(f"sphere of radius b = {B_POL:.3f} km, ball r=1000: {globe(1000.0, B_POL):.1f}  (below the pole's ball)")
print(f"comparison radius rho = a^2/b = {RHO:.3f} km   pinching Kmin/Kmax = {KMIN / KMAX:.6f}")

# ---- 3. what breaks: the saddle (Ric < 0), the no-fly zone (not complete), a 3D slip ----
D, Z = 600.0, 300.0                           # zone centre 600 km east, radius 300 km, flat map
def fly(x, yy):                               # flying distance from the airport at the origin
    cx = x - D; dc = hypot(cx, yy)
    if dc < Z: return None
    beta = acos(max(-1.0, min(1.0, -cx / dc))) - acos(Z / D) - acos(Z / dc)
    return hypot(x, yy) if beta <= 0 else sqrt(D * D - Z * Z) + sqrt(dc * dc - Z * Z) + Z * beta
def zone_rays(r, m=4000):
    tot = 0.0
    for i in range(m):
        th = (i + 0.5) * pi / m
        if th >= asin(Z / D): tot += r * r / 2; continue
        q = sqrt(Z * Z - (D * sin(th))**2); t1, t2 = D * cos(th) - q, D * cos(th) + q
        if r <= t1: tot += r * r / 2; continue
        tot += t1 * t1 / 2; lo, hi = t2 * 1.000001, r
        if lo >= r or fly(lo * cos(th), lo * sin(th)) > r: continue
        for _ in range(60):
            mid = (lo + hi) / 2
            if fly(mid * cos(th), mid * sin(th)) <= r: lo = mid
            else: hi = mid
        tot += (lo * lo - t2 * t2) / 2
    return 2 * tot * pi / m
def zone_grid(r, cell=5.0):
    n, cnt = int(r / cell) + 1, 0
    for i in range(-n, n):
        for j in range(n):
            x, yy = (i + 0.5) * cell, (j + 0.5) * cell
            d = fly(x, yy) if x * x + yy * yy <= r * r else None
            if d is not None and d <= r: cnt += 1
    return 2 * cnt * cell * cell
behind = 2 * sqrt(D * D - Z * Z) + Z * pi / 3    # straight behind the zone: two tangents, a 60-degree arc
print(f"point 1200 km east, behind the zone: by air {fly(1200.0, 0.0):.3f} km, by hand {behind:.3f} km")
zr = [zone_rays(r) / flat(r) for r in (300.0, 500.0, 700.0, 900.0, 1200.0, 2000.0)]
zg = [zone_grid(r) / flat(r) for r in (700.0, 2000.0)]
print("no-fly zone ratio at r = 300 500 700 900 1200 2000:", " ".join(f"{q:.4f}" for q in zr))
print(f"  grid count at 700 and 2000: {zg[0]:.4f} {zg[1]:.4f}")
zmin = min((zone_rays(r) / flat(r), r) for r in [10.0 * i for i in range(60, 101)])
zgm = zone_grid(zmin[1]) / flat(zmin[1])
print(f"  lowest ratio, r = 600 to 1000 km in 10 km steps: {zmin[0]:.4f} at {zmin[1]:.0f} km, grid count {zgm:.4f}")
sj = [jacobi_area(-1 / R**2, r, 300) / flat(r) for r in (1000.0, 3000.0)]
print(f"saddle ratio at 1000 and 3000: {saddle(1000.0) / flat(1000.0):.6f} {saddle(3000.0) / flat(3000.0):.6f}   Jacobi RK4 {sj[0]:.6f} {sj[1]:.6f}")
def s3_ball(r, rr): return pi * rr * rr * (2 * r - rr * sin(2 * r / rr))
def s3_shells(r, rr, n=2000): return sum(4 * pi * (rr * sin((i + 0.5) * r / n / rr))**2 * r / n for i in range(n))
true3, wrong3 = s3_ball(1000.0, R), s3_ball(1000.0, R / sqrt(2))
print(f"3D globe ball r=1000: true {true3:.0f} km3, model read as k=2/R^2 gives {wrong3:.0f}")
chart_r = [250.0 * i for i in range(1, 13)]
print("chart r:", " ".join(f"{r:.0f}" for r in chart_r))
print("chart globe:", " ".join(f"{globe(r) / flat(r):.4f}" for r in chart_r))
print("chart saddle:", " ".join(f"{saddle(r) / flat(r):.4f}" for r in chart_r))
print("chart no-fly:", " ".join(f"{zone_rays(r, 2000) / flat(r):.4f}" for r in chart_r))

assert abs(j1000 - g1000) < 1e-3, "Jacobi-built area must match the closed form"
assert abs(flat(1000.0) - g1000 - 6444.6) < 0.1, "shortfall agrees with the Ricci card"
assert all(a > b for a, b in zip(ratios, ratios[1:])), "Ric >= 0: the ratio only falls"
assert worst_riccati < 1e-3, "the mean curvature of the circles obeys the Riccati equation"
assert ok, "Riccati bound m <= model, density ratio and volume ratio never rise"
assert all(abs(r[1] - r[2]) < 1e-6 for r in rows), "circle radius: geometry and Jacobi agree"
assert all(abs(r[3] - r[4]) < 1e-3 for r in rows), "ball area: closed form and Jacobi agree"
assert all(r[4] <= r[5] for r in rows), "Bishop: no bigger than the comparison sphere"
assert globe(1000.0, B_POL) < rows[0][4], "the most curved sphere is not a valid upper bound"
assert abs(zr[2] - zg[0]) < 2e-3 and abs(zr[5] - zg[1]) < 2e-3 and abs(zmin[0] - zgm) < 2e-3, "rays and grid agree"
assert abs(fly(1200.0, 0.0) - behind) < 1e-9, "wrap-around distance against the hand formula"
assert zmin[0] < zr[2] < zr[3], "no-fly zone: the ratio falls past 700 km, then rises, so completeness was needed"
assert saddle(1000.0) > flat(1000.0), "saddle: Ric < 0 lets the ball beat flat"
assert all(abs(q - saddle(r) / flat(r)) < 1e-9 for q, r in zip(sj, (1000.0, 3000.0))), "saddle: Jacobi-built area matches the closed form"
assert abs(ratios[-1] - 4 / pi**2) < 1e-12, "whole globe: 4 pi R^2 over pi (pi R)^2 is 4/pi^2"
assert all(abs(s3_shells(1000.0, q) / s3_ball(1000.0, q) - 1) < 1e-6 for q in (R, R / sqrt(2))), "3D ball: shells against closed form"
assert wrong3 < true3, "3D slip: the misread model is smaller than the true ball"
print("ALL CHECKS PASS")
