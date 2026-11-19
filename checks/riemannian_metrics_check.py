# Riemannian metric -- the check behind the card.  Standard library only.
# The globe is a sphere of radius 6371 km.  Chart one is (phi, theta): phi is the
# angle down from the North Pole, theta the longitude east, both in radians.
# Chart two is Mercator's (x, y).  Routes from London to New York are measured by
# adding up the metric, then checked against closed forms and 3D chords.
from math import sin, cos, tan, acos, atan, atan2, asinh, sinh, cosh, sqrt, radians, degrees, pi
R = 6371.0
LON = (radians(90 - 51.5074), radians(-0.1278))         # London (phi, theta)
NYC = (radians(90 - 40.7128), radians(-74.0060))        # New York (phi, theta)

def g_globe(p):        # metric components (g11, g12, g22) in the (phi, theta) chart
    return R * R, 0.0, (R * sin(p[0])) ** 2
def g_mercator(p):     # metric components in Mercator's chart (x, y)
    f = (R / cosh(p[1])) ** 2
    return f, 0.0, f
def to_mercator(p): return (p[1], asinh(1 / tan(p[0])))    # x = theta, y = asinh(tan latitude)
def from_mercator(m): return (pi / 2 - atan(sinh(m[1])), m[0])
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def arrow(p):          # chart point -> point in space, km
    return [R * sin(p[0]) * cos(p[1]), R * sin(p[0]) * sin(p[1]), R * cos(p[0])]
def frame(p):          # r_phi and r_theta: the chart's two step directions in space
    return ([R * cos(p[0]) * cos(p[1]), R * cos(p[0]) * sin(p[1]), -R * sin(p[0])],
            [-R * sin(p[0]) * sin(p[1]), R * sin(p[0]) * cos(p[1]), 0.0])
def g_of(g, p, u, v):  # the metric eats two chart velocities and returns one number
    g11, g12, g22 = g(p)
    return g11 * u[0] * v[0] + g12 * (u[0] * v[1] + u[1] * v[0]) + g22 * u[1] * v[1]

def metric_length(pts, g):     # road one: add sqrt(g(step, step)) at each step's midpoint
    total = 0.0
    for a, b in zip(pts, pts[1:]):
        step = (b[0] - a[0], b[1] - a[1])
        total += sqrt(g_of(g, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), step, step))
    return total
def chord_length(pts):         # road two: straight chords in space through the same points
    return sum(sqrt(dot(*[[x - y for x, y in zip(arrow(a), arrow(b))]] * 2)) for a, b in zip(pts, pts[1:]))
A3, B3 = [x / R for x in arrow(LON)], [x / R for x in arrow(NYC)]
c = acos(dot(A3, B3))                                  # central angle, from one dot product
def great_circle(n, warp=lambda t: t):                 # n steps along the great circle
    pts = []
    for k in range(n + 1):
        t = warp(k / n)
        u = [(sin((1 - t) * c) * a + sin(t * c) * b) / sin(c) for a, b in zip(A3, B3)]
        pts.append((acos(u[2]), atan2(u[1], u[0])))
    return pts
def straight(a, b, n): return [tuple(x + k / n * (y - x) for x, y in zip(a, b)) for k in range(n + 1)]
def rhumb(n): return [from_mercator(m) for m in straight(to_mercator(LON), to_mercator(NYC), n)]

N, d = 2000, R * c
gc = great_circle(N)
roads = [metric_length(gc, g_globe), metric_length([to_mercator(p) for p in gc], g_mercator),
         chord_length(gc), metric_length(great_circle(N, lambda t: t * t), g_globe)]
errs = [abs(metric_length(great_circle(n), g_globe) - d) for n in (20, 200)]
rp, rt = frame(LON)
print(f"London phi = {degrees(LON[0]):.4f} deg, New York phi = {degrees(NYC[0]):.4f} deg; R = {R:.0f} km")
print(f"r_phi.r_phi = {dot(rp, rp):.1f}, r_phi.r_theta = {abs(dot(rp, rt)):.1f}, r_theta.r_theta = {dot(rt, rt):.1f} km^2")
print("g at London, chart (phi, theta): g11 = {:.1f}, g12 = {:.1f}, g22 = {:.1f}".format(*g_globe(LON)))
print("g at London, Mercator chart:     g11 = {:.1f}, g12 = {:.1f}, g22 = {:.1f}".format(*g_mercator(to_mercator(LON))))
for name, p in (("London", LON), ("New York", NYC)):
    print(f"1 deg of longitude at {name}: {R * sin(p[0]) * pi / 180:.2f} km; 1 deg of latitude: {R * pi / 180:.2f} km")
print(f"great circle, closed form R x c: c = {c:.6f} rad, d = {d:.2f} km")
print(f"great circle, metric in (phi, theta), {N} steps: {roads[0]:.4f} km")
print(f"great circle, metric in Mercator, {N} steps: {roads[1]:.4f} km")
print(f"great circle, 3D chords, {N} steps: {roads[2]:.4f} km")
print(f"great circle, uneven speed t^2, {N} steps: {roads[3]:.4f} km")
print(f"stepping error: 20 steps {errs[0]:.4f} km, 200 steps {errs[1]:.6f} km")
cs = straight(LON, NYC, N)
ls, lsc = metric_length(cs, g_globe), chord_length(cs)
m0, m1 = to_mercator(LON), to_mercator(NYC)
k_slope = (m1[0] - m0[0]) / (m1[1] - m0[1])
lr, lrc = metric_length(rhumb(N), g_globe), R * abs(NYC[0] - LON[0]) * sqrt(1 + k_slope ** 2)
print(f"straight in the (phi, theta) chart: metric {ls:.2f} km, chords {lsc:.2f} km")
print(f"rhumb line (one heading): metric {lr:.2f} km, closed form {lrc:.2f} km")
for eps in (-0.02, -0.01, 0.01, 0.02):
    bent = [(p[0] + eps * sin(pi * k / N), p[1]) for k, p in enumerate(gc)]
    print(f"great circle pushed {'south' if eps > 0 else 'north'} {abs(eps):.2f} rad ({R * abs(eps):.2f} km) "
          f"mid-route: {metric_length(bent, g_globe):.2f} km")
nv = [A3[1] * B3[2] - A3[2] * B3[1], A3[2] * B3[0] - A3[0] * B3[2], A3[0] * B3[1] - A3[1] * B3[0]]
top = (pi / 2 - acos(abs(nv[2]) / sqrt(dot(nv, nv))), atan2(-nv[2] * nv[1], -nv[2] * nv[0]))  # vertex, closed form
print(f"great circle peaks at {90 - degrees(top[0]):.2f} deg N, {-degrees(top[1]):.2f} deg W")
def heading(p, v):     # compass heading of chart velocity v: g against north and east unit arrows
    g11, g12, g22 = g_globe(p)
    return degrees(atan2(sqrt(g22) * v[1], -sqrt(g11) * v[0])) % 360
t3 = [b - dot(A3, B3) * a for a, b in zip(A3, B3)]     # great circle's direction leaving London
v_gc = (dot(t3, rp) / dot(rp, rp), dot(t3, rt) / dot(rt, rt))
v_rh = (-(m1[1] - m0[1]) / cosh(m0[1]), m1[0] - m0[0])  # rhumb's direction, moved back from Mercator
la1, la2, dl = pi / 2 - LON[0], pi / 2 - NYC[0], NYC[1] - LON[1]
h_trig = degrees(atan2(sin(dl) * cos(la2), cos(la1) * sin(la2) - sin(la1) * cos(la2) * cos(dl))) % 360
h_merc = degrees(atan2(m1[0] - m0[0], m1[1] - m0[1])) % 360
cosang = g_of(g_globe, LON, v_gc, v_rh) / sqrt(g_of(g_globe, LON, v_gc, v_gc) * g_of(g_globe, LON, v_rh, v_rh))
print(f"heading leaving London, great circle: metric {heading(LON, v_gc):.4f} deg, spherical trig {h_trig:.4f} deg")
print(f"heading leaving London, rhumb line: metric {heading(LON, v_rh):.4f} deg, Mercator slope {h_merc:.4f} deg")
print(f"angle between the two at London: metric {degrees(acos(cosang)):.4f} deg, "
      f"heading difference {heading(LON, v_gc) - heading(LON, v_rh):.4f} deg")
lons = [LON[1] + k / 10 * dl for k in range(11)]
fmt = lambda xs: ", ".join(f"{x:.2f}" for x in xs)
print("chart, longitude W:", ", ".join(f"{-degrees(x):.1f}" for x in lons))
print("chart, great circle latitude:", fmt(degrees(atan(-(nv[0] * cos(x) + nv[1] * sin(x)) / nv[2])) for x in lons))
print("chart, rhumb latitude:", fmt(degrees(atan(sinh(m0[1] + (x - LON[1]) / dl * (m1[1] - m0[1])))) for x in lons))
print("chart, straight-in-chart latitude:", fmt(90 - degrees(LON[0] + k / 10 * (NYC[0] - LON[0])) for k in range(11)))
flat = R * sqrt((NYC[0] - LON[0]) ** 2 + dl ** 2)
mixed = metric_length(gc, lambda p: (R * R, 0.0, (R * cos(p[0])) ** 2))
print(f"mistake, chart read as flat (g22 = R^2): {flat:.2f} km")
print(f"mistake, great circle measured with g22 = R^2 cos^2 phi: {mixed:.2f} km")
print(f"mistake, angles in degrees: {R * degrees(c):.0f} km")
print(f"mistake, the same great circle the long way round: {2 * pi * R - d:.2f} km")
assert all(abs(x - d) < 1e-3 for x in roads)                       # four roads, one length
assert abs(dot(rp, rp) - g_globe(LON)[0]) < 1e-6 and abs(dot(rt, rt) - g_globe(LON)[2]) < 1e-6
assert abs(lr - lrc) < 1e-3 and abs(ls - lsc) < 1e-2                # metric against closed form and chords
assert abs(heading(LON, v_gc) - h_trig) < 1e-9 and abs(heading(LON, v_rh) - h_merc) < 1e-9
assert d < lr < ls and errs[1] < errs[0] / 50                       # shortest; error falls as step^2
assert abs(degrees(acos(cosang)) - (heading(LON, v_gc) - heading(LON, v_rh))) < 1e-9   # angle = heading gap
assert abs(top[0] - min(gc)[0]) < 1e-6 and abs(top[1] - min(gc)[1]) < 1e-3   # vertex against the sampled route
print("ALL CHECKS PASS")
