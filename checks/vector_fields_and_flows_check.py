# Vector field and its flow -- the check behind the card.  Standard library only.
# Model current: the globe turning about the axis through the equator at 80E,
# 7 km a day at the North Pole.  Road one: RK4 steps chart by chart, chart A
# (polar angle, longitude) -> chart B (polar stereographic, km) -> chart A.
# Road two: RK4 in chart B alone.  Road three: the exact flow, a rotation.
import math
R, OM, AL, D = 6371.0, 7.0 / 6371.0, math.radians(80.0), math.pi / 180.0
SA, CA = math.sin(AL), math.cos(AL)                  # the axis is (CA, SA, 0)

def XA(s):                                           # field in chart A: (phi', theta'), rad/day
    return [-OM * math.sin(s[1] - AL), -OM * math.cos(s[1] - AL) / math.tan(s[0])]

def XB(s):                                           # field in chart B: (u', v'), km/day
    u, v = s
    c, w = (4 * R * R - u * u - v * v) / (4 * R), u * SA - v * CA
    return [OM * (c * SA + w * u / (2 * R)), OM * (-c * CA + w * v / (2 * R))]

def rk4(F, s, days, n):                              # classical Runge-Kutta, n equal steps
    h = days / n
    for _ in range(n):
        k1 = F(s)
        k2 = F([s[i] + h / 2 * k1[i] for i in (0, 1)])
        k3 = F([s[i] + h / 2 * k2[i] for i in (0, 1)])
        k4 = F([s[i] + h * k3[i] for i in (0, 1)])
        s = [s[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)]
    return s

def A2B(s):                                          # transition map, chart A to chart B
    rho = 2 * R * math.tan(s[0] / 2)
    return [rho * math.cos(s[1]), rho * math.sin(s[1])]

def B2A(s): return [2 * math.atan(math.sqrt(s[0] ** 2 + s[1] ** 2) / (2 * R)), math.atan2(s[1], s[0])]
def P3(s): return [R * math.sin(s[0]) * math.cos(s[1]), R * math.sin(s[0]) * math.sin(s[1]), R * math.cos(s[0])]

def exact(s, t):                                     # the flow: turn by OM t about the axis
    p, c, n = P3(s), math.cos(OM * t), math.sin(OM * t)
    ap, axp, ax = CA * p[0] + SA * p[1], [SA * p[2], -CA * p[2], CA * p[1] - SA * p[0]], [CA, SA, 0.0]
    q = [p[i] * c + axp[i] * n + ax[i] * ap * (1 - c) for i in (0, 1, 2)]
    return [math.atan2(math.sqrt(q[0] ** 2 + q[1] ** 2), q[2]), math.atan2(q[1], q[0])]

def dist(s, t):                                      # great-circle distance, km
    p, q = P3(s), P3(t)
    ch = math.sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2)
    return 2 * R * math.asin(min(1.0, ch / (2 * R)))

def ll(s):                                           # latitude and longitude as text
    lon = (s[1] / D + 180) % 360 - 180
    return f"{90 - s[0] / D:.2f}N {abs(lon):.2f}{'W' if lon < 0 else 'E'}"

def chartwise(s, n): return rk4(XA, B2A(rk4(XB, A2B(rk4(XA, s, 150, n)), 110, n)), 105, n)

b1 = [13 * D, 170 * D]                               # buoy 1: 77N 170E
b2 = [13 * D, 170 * D + 5.0 / (R * math.sin(13 * D))]  # buoy 2: 5 km east of buoy 1
e1, e2 = exact(b1, 365), exact(b2, 365)
print(f"turn rate {OM:.7f} rad/day = {OM / D:.5f} deg/day; 13 deg to the pole = {13 * D * R:.1f} km")
print(f"buoy 1 start {ll(b1)}; reaches the pole on day {13 * D / OM:.2f}")
print(f"exact flow, day 365: {ll(e1)}; arc {OM * 365 * R:.1f} km = {OM * 365 / D:.3f} deg, {OM * 365 / D - 13:.3f} past the pole")
errs = []
for n in (10, 20):
    c1, bb = chartwise(b1, n), B2A(rk4(XB, A2B(b1), 365, 2 * n))
    errs += [dist(c1, e1), dist(bb, e1)]
    print(f"{n} steps a leg: chart by chart {ll(c1)}, off by {dist(c1, e1):.2e} km; chart B alone, {2 * n} steps, off by {dist(bb, e1):.2e} km")
print(f"halving the step cuts the errors {errs[0] / errs[2]:.1f}-fold and {errs[1] / errs[3]:.1f}-fold")
sa, sb, gap = b1, A2B(b1), 0.0                       # overlap: A-motion seen in B = B-motion
for _ in range(150):
    sa, sb = rk4(XA, sa, 1, 2), rk4(XB, sb, 1, 2)
    gap = max(gap, math.sqrt((A2B(sa)[0] - sb[0]) ** 2 + (A2B(sa)[1] - sb[1]) ** 2))
print(f"days 0-150, motion in A mapped into B against motion in B: largest gap below 1e-9 km: {'yes' if gap < 1e-9 else 'no'}")
xa, (u, v) = XA(b2), A2B(b2)
xb, r = XB([u, v]), math.sqrt(u * u + v * v)
ph, th = b2
j1, j2 = R / math.cos(ph / 2) ** 2, 2 * R * math.tan(ph / 2)  # d rho/d phi, rho
jx = [j1 * math.cos(th) * xa[0] - j2 * math.sin(th) * xa[1], j1 * math.sin(th) * xa[0] + j2 * math.cos(th) * xa[1]]
xfa, xfb = R * xa[0], (u * xb[0] + v * xb[1]) / (r * (1 + r * r / (4 * R * R)))
print(f"buoy 2 start {ll(b2)}, chart B ({u:.3f}, {v:.3f}) km")
print(f"  chart A components: phi' {xa[0]:.8f}, theta' {xa[1]:.8f} rad/day")
print(f"  chart B components: u' {xb[0]:.6f}, v' {xb[1]:.6f} km/day; Jacobian times A: {jx[0]:.6f}, {jx[1]:.6f}")
print(f"  Xf, f = distance to the pole: chart A {xfa:.6f}, chart B {xfb:.6f} km/day")
p0 = XB([0.0, 0.0])
print(f"pole in chart B: u' {p0[0]:.3f}, v' {p0[1]:.3f}, speed {math.sqrt(p0[0] ** 2 + p0[1] ** 2):.3f} km/day")
for s in ([90 * D, AL], [90 * D, AL - math.pi]):
    x = XA(s)
    print(f"still point {ll(s)}: speed {math.sqrt((R * x[0]) ** 2 + (R * math.sin(s[0]) * x[1]) ** 2):.6f} km/day")
sep = [dist(exact(b1, t), exact(b2, t)) for t in range(366)]
near = min(exact(b2, 200 + k / 100)[0] * R for k in range(1300))
print(f"buoys 1 and 2 apart, days 0-365: {min(sep):.3f} to {max(sep):.3f} km; buoy 2 passes {near:.3f} km from the pole")
print("chart, buoy 2 longitude east 0-360, days 200..213: " + " ".join(f"{(exact(b2, d)[1] / D) % 360:.1f}" for d in range(200, 214)))
ea = [dist(rk4(XA, b2, 365, n), e2) for n in (73, 146, 365)]
eb = dist(B2A(rk4(XB, A2B(b2), 365, 73)), e2)
print(f"buoy 2, chart A alone, steps 5, 2.5, 1 days: off by {ea[0]:.3f}, {ea[1]:.3f}, {ea[2]:.3f} km; chart B, 5-day steps: {eb:.2e} km")
na = rk4(XA, b1, 365, 365)
print(f"mistake, buoy 1 in chart A through the pole: polar angle {na[0] / D:.2f} deg, read as {90 - na[0] / D:.2f}N")
n1, n2 = [-OM * R * math.cos(170 * D), -OM * R * math.sin(170 * D)], [-OM * R * math.cos(10 * D), -OM * R * math.sin(10 * D)]
jump = math.sqrt((n1[0] - n2[0]) ** 2 + (n1[1] - n2[1]) ** 2)
print(f"mistake, 'due north at 7 km/day' at the pole, chart B: from 170E ({n1[0]:.3f}, {n1[1]:.3f}), from 10E ({n2[0]:.3f}, {n2[1]:.3f}); jump {jump:.3f} km/day")
back, b76 = exact(e1, -365), exact([14 * D, 170 * D], 365)
b3 = [13 * D, 170 * D + 50.0 / (R * math.sin(13 * D))]
e3 = dist(rk4(XA, b3, 365, 73), exact(b3, 365))
print(f"try, run back 365 days from {ll(e1)}: {ll(back)}; start 76N 170E: day 365 at {ll(b76)}")
print(f"try, buoy 50 km east: chart A 5-day steps off by {e3:.3f} km; speed 14 km/day: pole on day {13 * D / (2 * OM):.2f}")
sc = 0.14                                            # figure: px per km, pole at (250, 220)
fx = lambda t: [250 + sc * (A2B(exact(b1, t))[0] * SA - A2B(exact(b1, t))[1] * CA), 220 - sc * (A2B(exact(b1, t))[0] * CA + A2B(exact(b1, t))[1] * SA)]
print("figure, buoy 1 px at days 0, 100, 300, 365: " + "; ".join(f"{fx(t)[0]:.1f} {fx(t)[1]:.1f}" for t in (0, 100, 300, 365))
      + f"; 77N circle r {sc * 2 * R * math.tan(6.5 * D):.1f}; 80N circle r {sc * 2 * R * math.tan(5 * D):.1f}")
print(f"figure, scale {sc:.2f} px/km; 30-day arrow at the pole {sc * 30 * OM * R:.1f} px; 300 km grid {sc * 300:.1f} px")
assert dist(chartwise(b1, 20), e1) < 1e-8 and dist(B2A(rk4(XB, A2B(b1), 365, 40)), e1) < 1e-7
assert abs(90 - e1[0] / D - (90 - (OM * 365 / D - 13))) < 1e-9          # hand count past the pole
assert 14 < errs[0] / errs[2] < 18 and 14 < errs[1] / errs[3] < 18      # RK4 is fourth order
assert gap < 1e-9 and abs(jx[0] - xb[0]) < 1e-9 and abs(jx[1] - xb[1]) < 1e-9
assert abs(xfa - xfb) < 1e-9 and abs(xfa + 7 * math.cos(b2[1] - 170 * D)) < 1e-9
assert abs(min(sep) - 5) < 1e-4 and abs(max(sep) - 5) < 1e-4 and abs(near - 5) < 1e-3
assert ea[0] > 1 and eb < 1e-6 and na[0] < 0 and jump > 13 and dist(back, b1) < 1e-9
print("ALL CHECKS PASS")
