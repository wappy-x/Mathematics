# Covectors and tensor fields -- the check behind the card.  Standard library only.
# The Earth is a sphere of radius R = 6371 km.  A low of 982 hPa sits at 60 N, 20 W:
# pressure P = 1012 - 30 exp(-(1 - n.c)/W) hPa, n the unit arrow to a place, c to the low.
# At London the wind blows 12 m/s toward heading 20 deg, clockwise from north.
# Sheet A is (phi, theta): phi down from the North Pole, theta longitude east, radians.
# Sheet B is Mercator: x = theta, y = asinh(tan latitude).
# dP(wind) by three roads: sheet A, along the drifting path, and g(grad P, wind) in
# space; sheet B checks the two change rules.  grad P by three roads: sheet A, sheet B,
# and from space; the steepest direction is also found by brute force over 3600 headings.
from math import sin, cos, tan, atan, asinh, cosh, sinh, exp, acos, atan2, sqrt, radians, degrees, pi
R, DEPTH, W, SPEED, HEAD = 6371.0, 30.0, 0.03, 12.0 * 3.6, 20.0   # km, hPa, width, km/h, deg
def unit(lat, lon): return (cos(radians(lat)) * cos(radians(lon)), cos(radians(lat)) * sin(radians(lon)), sin(radians(lat)))
C = unit(60.0, -20.0)
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def n_a(a): return (sin(a[0]) * cos(a[1]), sin(a[0]) * sin(a[1]), cos(a[0]))
def p_space(n): return 1012.0 - DEPTH * exp(-(1.0 - dot(n, C)) / W)
def p_a(a): return p_space(n_a(a))
def a_of_b(b): return (pi / 2 - atan(sinh(b[1])), b[0])
def p_b(b): return p_a(a_of_b(b))
LON = (radians(90 - 51.5074), radians(-0.1278))         # London in sheet A
LONB = (LON[1], asinh(1 / tan(LON[0])))                  # London in sheet B
ph, ch = LON[0], cosh(LONB[1])
E = exp(-(1.0 - dot(n_a(LON), C)) / W)
r_ph = (cos(ph) * cos(LON[1]), cos(ph) * sin(LON[1]), -sin(ph))   # d n / d phi
r_th = (-sin(ph) * sin(LON[1]), sin(ph) * cos(LON[1]), 0.0)      # d n / d theta
dpA = (-DEPTH * E / W * dot(r_ph, C), -DEPTH * E / W * dot(r_th, C))     # hPa per radian, exact
def fd(f, x, i, h=1e-6):
    up, dn = list(x), list(x); up[i] += h; dn[i] -= h
    return (f(up) - f(dn)) / (2 * h)
dpA_fd = (fd(p_a, LON, 0), fd(p_a, LON, 1))
dpB = (dpA[1], -dpA[0] / ch)                            # covector rule: d phi/d y = -1/cosh y
dpB_fd = (fd(p_b, LONB, 0), fd(p_b, LONB, 1))
north, east = SPEED * cos(radians(HEAD)), SPEED * sin(radians(HEAD))
vA = (-north / R, east / (R * sin(ph)))                   # radians per hour
vB = (vA[1], -ch * vA[0])                                  # vector rule: d y/d phi = -cosh y
def pair(a, v): return a[0] * v[0] + a[1] * v[1]
gA, gB = (R * R, R * R * sin(ph) ** 2), (R * R / ch ** 2, R * R / ch ** 2)   # diagonal tables
nE = (-sin(LON[1]), cos(LON[1]), 0.0); nN = tuple(-x for x in r_ph)     # east, north unit arrows
def path(t):                                               # great circle leaving London at the wind
    n0, k = n_a(LON), SPEED * t / R
    d = tuple((north * a + east * b) / SPEED for a, b in zip(nN, nE))
    return tuple(cos(k) * a + sin(k) * b for a, b in zip(n0, d))
along = (p_space(path(1e-4)) - p_space(path(-1e-4))) / 2e-4
gradA = (dpA[0] / gA[0], dpA[1] / gA[1])                    # g^-1 times dP, sheet A
gradB = (dpB[0] / gB[0], dpB[1] / gB[1])
enA = (R * sin(ph) * gradA[1], -R * gradA[0])                # (east, north) hPa per km
enB = (R / ch * gradB[0], R / ch * gradB[1])
s3 = tuple(-DEPTH * E / W / R * (c - dot(n_a(LON), C) * x) for c, x in zip(C, n_a(LON)))
enS = (dot(s3, nE), dot(s3, nN))
def mag(v): return sqrt(v[0] ** 2 + v[1] ** 2)
def hdg(v): return degrees(atan2(v[0], v[1])) % 360
best = max((pair(dpA, (-cos(radians(k / 10)) / R, sin(radians(k / 10)) / (R * sin(ph)))), k / 10) for k in range(3600))
gv = east * enS[0] + north * enS[1]                         # g(grad P, wind) in space: a plain dot product
print(f"pressure at London: {p_a(LON):.2f} hPa; at the low: {p_space(C):.2f} hPa")
print(f"angle at the centre from London to the low: d = {degrees(acos(dot(n_a(LON), C))):.2f} deg")
print(f"wind: {SPEED:.1f} km/h toward {HEAD:.0f} deg = north {north:.4f}, east {east:.4f} km/h")
print("dP, sheet A, exact:  ({:.4f}, {:.4f}) hPa/rad".format(*dpA))
print("dP, sheet A, slopes: ({:.4f}, {:.4f}) hPa/rad".format(*dpA_fd))
print("dP, sheet B, rule:   ({:.4f}, {:.4f}) hPa per unit".format(*dpB))
print("dP, sheet B, slopes: ({:.4f}, {:.4f}) hPa per unit".format(*dpB_fd))
print("wind, sheet A: ({:.6f}, {:.6f}) rad/h; sheet B: ({:.6f}, {:.6f}) per hour".format(*vA, *vB))
road = [pair(dpA, vA), pair(dpB, vB), along, gv]
print(f"sheet A by hand: phi = {degrees(ph):.4f} deg, sin(phi) = {sin(ph):.6f}, R sin(phi) = {R * sin(ph):.2f} km; terms {dpA[0] * vA[0]:.4f} + {dpA[1] * vA[1]:.4f}; g terms {gA[0] * vA[0] ** 2:.4f} + {gA[1] * vA[1] ** 2:.4f}")
print("dP(wind): sheet A {:.4f}, sheet B {:.4f}, along the path {:.4f}, g(grad P, wind) {:.4f} hPa/h".format(*road))
print("g at London, sheet A: g11 = {:.1f}, g22 = {:.1f}; sheet B: {:.1f}, {:.1f} km^2".format(*gA, *gB))
print(f"speed^2 from g: sheet A {gA[0] * vA[0] ** 2 + gA[1] * vA[1] ** 2:.4f}, sheet B {gB[0] * vB[0] ** 2 + gB[1] * vB[1] ** 2:.4f} km^2/h^2")
print("grad P in millionths, sheet A: ({:.4f}, {:.4f}); sheet B: ({:.4f}, {:.4f})".format(*(1e6 * x for x in gradA + gradB)))
for name, v in (("sheet A", enA), ("sheet B", enB), ("space", enS)):
    print(f"grad P from {name}: east {v[0]:.6f}, north {v[1]:.6f} hPa/km, {100 * mag(v):.4f} hPa per 100 km, heading {hdg(v):.2f} deg")
print(f"brute force over 3600 headings: steepest {best[1]:.1f} deg, rising {100 * best[0]:.4f} hPa per 100 km")
print("chart, heading:", ", ".join(str(30 * k) for k in range(13)))
print("chart, dP(u) hPa per 100 km:", ", ".join(f"{100 * pair(dpA, (-cos(radians(30 * k)) / R, sin(radians(30 * k)) / (R * sin(ph)))):.4f}" for k in range(13)))
ang = degrees(acos(dot(enA, (east, north)) / (mag(enA) * SPEED)))
print(f"angle between grad P and the wind: {ang:.2f} deg; 1 hPa isobars {1 / mag(enA):.2f} km apart")
naiveA = (R * sin(ph) * dpA[1], -R * dpA[0]); naiveB = (dpB[0], dpB[1])
print(f"mistake, dP read as an arrow in sheet A: heading {hdg(naiveA):.2f} deg")
print(f"mistake, dP read as an arrow in sheet B: heading {hdg(naiveB):.2f} deg, length off by {gB[0]:.1f}")
bad = (dpA[1], -ch * dpA[0])                                # covector moved by the vector rule
print(f"mistake, dP moved to sheet B by the vector rule: dP(wind) = {pair(bad, vB):.4f} hPa/h")
print(f"mistake, sheet A's dP paired with sheet B's wind: {pair(dpA, vB):.4f}, not {road[0]:.4f}")
print(f"mistake, grad P dotted with the wind without g: {pair(gradA, vA):.12f}, mixed units, not hPa/h")
print(f"mistake, wind dotted with itself without g: {vA[0] ** 2 + vA[1] ** 2:.6f} instead of {SPEED ** 2:.4f}")
print(f"at the North Pole, sheet A: g22 = R^2 sin^2(0) = {R * R * sin(0.0) ** 2:.1f}: no inverse, no grad P there")
rho, f = 1.225, 2 * 7.2921e-5 * sin(radians(51.5074))
print(f"geostrophic wind: |grad P| {mag(enA) * 0.1:.6f} Pa/m, f {f:.7f} 1/s, speed {mag(enA) * 0.1 / (rho * f):.2f} m/s")
s = 1 / mag(enA); u = (enA[0] / mag(enA), enA[1] / mag(enA))
print(f"figure, wind 3 h {3 * SPEED:.1f} km, tip ({3 * east:.2f}, {3 * north:.2f}) km; 1 hPa step tip ({s * u[0]:.2f}, {s * u[1]:.2f}) km; spacing {s:.2f} km; in 3 h {3 * road[0]:.2f} hPa")
assert all(abs(x - road[0]) < 1e-6 for x in road)                  # three roads and sheet B, one rate
assert all(abs(a - b) < 1e-4 for a, b in zip(dpA + dpB, dpA_fd + dpB_fd))   # rule against slopes
assert all(abs(a - b) < 1e-9 for v in (enB, enS) for a, b in zip(enA, v))   # three roads to grad P
assert abs(best[1] - hdg(enA)) < 0.1 and abs(best[0] - mag(enA)) < 1e-6 # brute force agrees
assert abs(hdg(naiveA) - hdg(enA)) > 5 and abs(pair(bad, vB) - road[0]) > 0.01
print("ALL CHECKS PASS")
