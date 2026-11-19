# Integration on an oriented manifold -- the check behind the card.
# Standard library only.  A bowl-shaped valley (part of a sphere, radius 5 km,
# rim radius 3 km, 1 km deep) catches a storm whose rain rate grows with height.
# The rain is the 2-form p dx^dy.  It is integrated three ways: closed form,
# two overlapping charts glued by a partition of unity, and a triangle mesh.
import math

R, A, P0, H0 = 5.0, 3.0, 10.0, 1.0           # km, km, mm/h on the floor, km per extra P0
LO, HI = 1.0, 2.0                            # km: chart V starts at plan radius LO, chart U stops at HI
PHI0, PHI1 = math.asin(A / R), math.asin(LO / R)   # polar angle at the rim and at plan radius LO
def height(rho): return R - math.sqrt(R * R - rho * rho)  # km above the valley floor
def rain(rho): return P0 * (1 + height(rho) / H0)     # mm/h, measured on level ground
def f(t): return math.exp(-1 / t) if t > 0 else 0.0
def psi_u(rho, lo=LO, hi=HI): return f(hi - rho) / (f(hi - rho) + f(rho - lo))  # 1 inside lo, 0 outside hi
def psi_v(rho): return 1 - psi_u(rho)
def det2(a, b, c, d): return a * d - b * c

def simpson2(g, a, b, c, d, n):              # Simpson's rule on an n-by-n grid, n even
    hu, hv, s = (b - a) / n, (d - c) / n, 0.0
    w = [1 if i in (0, n) else (4 if i % 2 else 2) for i in range(n + 1)]
    for i in range(n + 1):
        for j in range(n + 1):
            s += w[i] * w[j] * g(a + i * hu, c + j * hv)
    return s * hu * hv / 9

def chart_v(ph, th):                         # slope chart: polar angle ph from the floor, longitude th
    x, y = R * math.sin(ph) * math.cos(th), R * math.sin(ph) * math.sin(th)
    xp, xt = R * math.cos(ph) * math.cos(th), -R * math.sin(ph) * math.sin(th)
    yp, yt = R * math.cos(ph) * math.sin(th), R * math.sin(ph) * math.cos(th)
    return math.hypot(x, y), det2(xp, xt, yp, yt)  # plan radius, coefficient of dph^dth
def u_part(x, y, weight):                    # floor chart: plan x, y; dx^dy pulls back to itself
    rho = math.hypot(x, y)
    return weight(rho) * rain(rho) if rho < HI else 0.0
def v_part(ph, th, weight, order=1):         # order -1: the chart read as (th, ph)
    rho, j = chart_v(ph, th)
    return weight(rho) * rain(rho) * j * order

f6 = lambda v: f"{v:.6f}"
plan, zint = math.pi * A * A, math.pi * A * A * R - 2 * math.pi / 3 * (R ** 3 - (R * R - A * A) ** 1.5)
closed = P0 * (plan + zint / H0)
print("rim polar angle rad", f6(PHI0), "deg", f6(math.degrees(PHI0)), "rim height km", f6(height(A)), "rim gauge mm/h", f6(rain(A)))
print("plan area km^2", f6(plan), "integral of z dA km^3", f6(zint))
print("closed form, mm/h x km^2", f6(closed), "m^3/h", f6(closed * 1000), "6 h storm m^3", f6(closed * 6000))
rho = 1.5
ph = math.asin(rho / R)
print("at plan radius 1.5 km: sin phi", f6(math.sin(ph)), "cos phi", f6(math.cos(ph)), "z", f6(height(rho)), "p mm/h", f6(rain(rho)), "psi_U", f6(psi_u(rho)), "psi_V", f6(psi_v(rho)))
print("  coefficient in chart U", f6(rain(rho)), "in chart V", f6(rain(rho) * chart_v(ph, 0.7)[1]),
      "Jacobian", f6(chart_v(ph, 0.7)[1]), "R^2 sin cos", f6(R * R * math.sin(ph) * math.cos(ph)))
assert abs(chart_v(ph, 0.7)[1] - R * R * math.sin(ph) * math.cos(ph)) < 1e-12
iu = simpson2(lambda x, y: u_part(x, y, psi_u), -HI, HI, -HI, HI, 400)
iv = simpson2(lambda p, t: v_part(p, t, psi_v), PHI1, PHI0, 0.0, 2 * math.pi, 200)
print("chart U piece", f6(iu), "chart V piece", f6(iv), "sum", f6(iu + iv), "closed", f6(closed))
assert abs(iu + iv - closed) < 1e-4
whole_v = simpson2(lambda p, t: v_part(p, t, lambda r: 1.0), 0.0, PHI0, 0.0, 2 * math.pi, 200)
print("chart V alone over the whole bowl (floor point is one point)", f6(whole_v))
assert abs(whole_v - closed) < 1e-6
dets = [chart_v(PHI1 + k * (math.asin(HI / R) - PHI1) / 10, 0.3 * k)[1] for k in range(11)]
print("overlap: smallest dph^dth coefficient", f6(min(dets)), "all positive", "yes" if min(dets) > 0 else "no")

def mesh(n):                                 # flat triangles on the bowl, vertices in anticlockwise order
    m, tot = 4 * n, 0.0
    pt = lambda i, j: (A * i / n * math.cos(2 * math.pi * j / m), A * i / n * math.sin(2 * math.pi * j / m), height(A * i / n))
    for i in range(n):
        for j in range(m):
            p, q, r, s = pt(i, j), pt(i + 1, j), pt(i + 1, j + 1), pt(i, j + 1)
            for a, b, c in ((p, q, r), (p, r, s)):
                proj = det2(b[0] - a[0], c[0] - a[0], b[1] - a[1], c[1] - a[1]) / 2  # signed dx^dy
                tot += proj * P0 * (1 + (a[2] + b[2] + c[2]) / 3 / H0)
    return tot
m1, m2 = mesh(30), mesh(60)
print("mesh 30 rings", f6(m1), "error", f6(m1 - closed))
print("mesh 60 rings", f6(m2), "error", f6(m2 - closed), "ratio", f6((m1 - closed) / (m2 - closed)))
assert abs(m2 - closed) < abs(m1 - closed) / 3.5

print("rim at (3, 0): outward d/dphi, along d/dtheta, dx^dy coefficient", f6(chart_v(PHI0, 0.0)[1]), "rim length km", f6(2 * math.pi * A))
c3 = lambda r, t: (math.cos(t), -r * math.sin(t), 0.0, math.sin(t), r * math.cos(t), 0.0, 0.0, 0.0, 1.0)  # d(x,y,z)/d(rho,theta,z)
def det3(m): return m[0] * (m[4] * m[8] - m[5] * m[7]) - m[1] * (m[3] * m[8] - m[5] * m[6]) + m[2] * (m[3] * m[7] - m[4] * m[6])
swap = lambda m: [m[k] for k in (0, 2, 1, 3, 5, 4, 6, 8, 7)]         # columns reordered to (rho, z, theta)
lake = simpson2(lambda r, t: det3(c3(r, t)) * (height(A) - height(r)), 0.0, A, 0.0, 2 * math.pi, 200)
lake2 = simpson2(lambda r, t: det3(swap(c3(r, t))) * (height(A) - height(r)), 0.0, A, 0.0, 2 * math.pi, 200)
print("3-form dx^dy^dz, lake to the rim, km^3: order (rho, theta, z)", f6(lake), "order (rho, z, theta)", f6(lake2), "closed 14 pi/3", f6(14 * math.pi / 3))
assert abs(lake - 14 * math.pi / 3) < 1e-6 and abs(lake2 + 14 * math.pi / 3) < 1e-6

flip = iu + simpson2(lambda p, t: v_part(p, t, psi_v, -1), PHI1, PHI0, 0.0, 2 * math.pi, 200)
iu_all = simpson2(lambda r, t: rain(r) * r, 0.0, HI, 0.0, 2 * math.pi, 200)  # chart U at full weight, in plan polar form
iv_all = simpson2(lambda p, t: v_part(p, t, lambda r: 1.0), PHI1, PHI0, 0.0, 2 * math.pi, 200)
slope = simpson2(lambda p, t: rain(R * math.sin(p)) * R * R * math.sin(p), 0.0, PHI0, 0.0, 2 * math.pi, 200)
print("breaks: chart V read as (theta, phi)", f6(flip))
ring = lambda r: P0 * (math.pi * r * r * (1 + R / H0) + 2 * math.pi / (3 * H0) * (R * R - r * r) ** 1.5)  # rain on plan disc r
print("breaks: no partition of unity", f6(iu_all + iv_all), "excess", f6(iu_all + iv_all - closed), "ring 1 to 2 km", f6(ring(HI) - ring(LO)))
print("breaks: slope area dS for dx^dy", f6(slope), "closed 150 pi", f6(150 * math.pi), "ratio", f6(slope / closed))
assert flip < closed / 2 and abs(slope - 150 * math.pi) < 1e-6 and abs(iu_all + iv_all - closed - ring(HI) + ring(LO)) < 1e-6

def mob(s, t):                               # Mobius strip of mid-radius 1 km, width 1 km
    return ((1 + t / 2 * math.cos(s / 2)) * math.cos(s), (1 + t / 2 * math.cos(s / 2)) * math.sin(s), t / 2 * math.sin(s / 2))
def normal(s, t, e=1e-6):
    a = [(mob(s + e, t)[k] - mob(s - e, t)[k]) / (2 * e) for k in range(3)]
    b = [(mob(s, t + e)[k] - mob(s, t - e)[k]) / (2 * e) for k in range(3)]
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
sign = lambda u, v: 1 if sum(u[k] * v[k] for k in range(3)) > 0 else -1
same = max(abs(mob(4.0, 0.3)[k] - mob(4.0 - 2 * math.pi, -0.3)[k]) for k in range(3))
print("mobius: chart B point (s - 2 pi, -t) is chart A point (s, t), gap", f6(same))
print("mobius: orientation agreement on overlap piece 1 (same numbers in both charts)", sign(normal(1.0, 0.3), normal(1.0, 0.3)),
      "piece 2", sign(normal(4.0, 0.3), normal(4.0 - 2 * math.pi, -0.3)))
assert same < 1e-12 and sign(normal(4.0, 0.3), normal(4.0 - 2 * math.pi, -0.3)) == -1

print("chart psi_U", " ".join(f"{psi_u(k / 5):.3f}" for k in range(16)))
print("chart psi_V", " ".join(f"{psi_v(k / 5):.3f}" for k in range(16)))
narrow = (simpson2(lambda x, y: u_part(x, y, lambda r: psi_u(r, 1.25, 1.75)), -HI, HI, -HI, HI, 400)
          + simpson2(lambda p, t: v_part(p, t, lambda r: 1 - psi_u(r, 1.25, 1.75)), PHI1, PHI0, 0.0, 2 * math.pi, 200))
print("try: H0 = 0.5 km", f6(P0 * (plan + zint / 0.5)), "try: overlap 1.25 to 1.75 km", f6(narrow))
print("try: mesh 6 rings", f6(mesh(6)))
px = 60.0                                    # figure scale, pixels per km
print("figure,", f"{px:.0f}", "px per km: chart U radius", f6(HI), "chart V from", f6(LO), "to", f6(A), "rim height", f6(height(A)),
      "radii px", " ".join(f"{px * r:.1f}" for r in (LO, HI, A)), "section depth px", f"{px * height(A):.1f}")
print("ALL CHECKS PASS")
