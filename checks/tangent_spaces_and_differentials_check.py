# Tangent space and differential -- the check behind the card.  Standard library only.
# The Earth is a sphere of radius R = 6371 km.  A plane has just left the runway at
# London Heathrow: ground speed 300 km/h on a track of 300 deg, clockwise from north.
# Chart A is (phi, theta): phi down from the North Pole, theta longitude east, radians.
# Chart B is polar stereographic: (xi, eta) = R tan(phi/2) (cos theta, sin theta), km.
# The map F sends the globe to a Mercator sheet: X = R theta, Y = R ln cot(phi/2), km.
# Road 1: dF_p as a Jacobian in chart A.  Road 2: dF_p as a Jacobian in chart B, with
# the velocity's chart-B components taken from space, not from chart A.  Road 3: no
# Jacobian at all: central differences of F along two different paths through p.
from math import sin, cos, tan, atan, atan2, log, sqrt, radians, degrees, pi
R, LAT, LON, SPEED, TRACK = 6371.0, 51.47, -0.4543, 300.0, 300.0
def pos(a):                                    # chart A -> space, km
    return (R * sin(a[0]) * cos(a[1]), R * sin(a[0]) * sin(a[1]), R * cos(a[0]))
def chart_a(P): return (atan2(sqrt(P[0] ** 2 + P[1] ** 2), P[2]), atan2(P[1], P[0]))
def chart_b(P): return (R * P[0] / (R + P[2]), R * P[1] / (R + P[2]))
def b_to_a(b): return (2 * atan(sqrt(b[0] ** 2 + b[1] ** 2) / R), atan2(b[1], b[0]))
def F(a): return (R * a[1], R * log(1 / tan(a[0] / 2)))          # the Mercator sheet
def mv(J, v): return tuple(sum(J[i][j] * v[j] for j in range(len(v))) for i in range(len(J)))
def norm(v): return sqrt(sum(c * c for c in v))
def lin(*terms): return tuple(sum(k * v[i] for k, v in terms) for i in range(len(terms[0][1])))
def vec(v, d=4): return "(" + ", ".join(f"{c:.{d}f}" for c in v) + ")"
def mat(J, d=4): return "[" + "; ".join(vec(r, d)[1:-1] for r in J) + "]"
def basis_a(a):                                # d_phi and d_theta as arrows in space
    return ((R * cos(a[0]) * cos(a[1]), R * cos(a[0]) * sin(a[1]), -R * sin(a[0])),
            (-R * sin(a[0]) * sin(a[1]), R * sin(a[0]) * cos(a[1]), 0.0))
def JF_a(a): return ((0.0, R), (-R / sin(a[0]), 0.0))             # rows X, Y; columns phi, theta
def JF_b(b):
    r2 = b[0] ** 2 + b[1] ** 2
    return ((-R * b[1] / r2, R * b[0] / r2), (-R * b[0] / r2, -R * b[1] / r2))
def JB_space(P):                               # chart B differentiated in space, 2 x 3
    d = R + P[2]
    return ((R / d, 0.0, -R * P[0] / d / d), (0.0, R / d, -R * P[1] / d / d))
def JT(a):                                     # transition A -> B
    k, t = R / (2 * cos(a[0] / 2) ** 2), R * tan(a[0] / 2)
    return ((k * cos(a[1]), -t * sin(a[1])), (k * sin(a[1]), t * cos(a[1])))
def track(v): return degrees(atan2(v[0], v[1])) % 360            # map heading from (X', Y')
p = (radians(90 - LAT), radians(LON))
P = pos(p)
north, east = SPEED * cos(radians(TRACK)), SPEED * sin(radians(TRACK))
va = (-north / R, east / (R * sin(p[0])))                         # chart A components, rad/h
ephi, eth = basis_a(p)
print(f"Heathrow: phi = {degrees(p[0]):.4f} deg = {p[0]:.6f} rad, theta = {p[1]:.6f} rad")
print(f"ground velocity: north {north:.4f} km/h, east {east:.4f} km/h")
print(f"basis lengths: |d_phi| = {norm(ephi):.4f} km/rad, |d_theta| = {norm(eth):.4f} km/rad")
print(f"chart A components: v = {vec(va, 6)} rad/h")
NH = (-cos(p[0]) * cos(p[1]), -cos(p[0]) * sin(p[1]), sin(p[0]))
EH = (-sin(p[1]), cos(p[1]), 0.0)
v3 = lin((va[0], ephi), (va[1], eth))                             # the same arrow, in space
v3h = lin((north, NH), (east, EH))
print(f"in space from chart A: {vec(v3)} km/h, speed {norm(v3):.4f}, |v.p| = {abs(sum(x * y for x, y in zip(v3, P))):.4f}")
print(f"in space from heading: {vec(v3h)} km/h")
b = chart_b(P)
vb = mv(JB_space(P), v3)                                          # chart B components, from space
print(f"chart B point (xi, eta) = {vec(b)} km, components v = {vec(vb)} km/h")
print(f"transition Jacobian A -> B: {mat(JT(p))}; times chart A components: {vec(mv(JT(p), va))}")
print(f"TM point, chart A: {vec(p + va, 6)}; chart B: {vec(b + vb)}")
print(f"Mercator sheet: F(p) = (X, Y) = {vec(F(p))} km")
print(f"dF_p in chart A: {mat(JF_a(p))}")
print(f"dF_p in chart B: {mat(JF_b(b), 6)}")
r1, r2 = mv(JF_a(p), va), mv(JF_b(b), vb)
print(f"road 1, chart A: dF_p(v) = {vec(r1)} km/h")
print(f"road 2, chart B: dF_p(v) = {vec(r2)} km/h")
u, w = tuple(c / SPEED for c in v3), SPEED / R
def great(t): return chart_a(lin((cos(w * t), P), (R * sin(w * t), u)))
def straight_b(t): return b_to_a((b[0] + vb[0] * t, b[1] + vb[1] * t))
errs = []
for name, path in (("great circle", great), ("straight line in chart B", straight_b)):
    for secs in (60, 6):
        h = secs / 3600
        d = tuple((x - y) / (2 * h) for x, y in zip(F(path(h)), F(path(-h))))
        errs.append(norm(tuple(x - y for x, y in zip(d, r1))))
        print(f"road 3, {name}, step {secs:2d} s: {vec(d)} km/h, off by {errs[-1]:.7f}")
print(f"map speed {norm(r1):.4f} km/h, stretch {norm(r1) / SPEED:.6f} = 1/cos(lat) {1 / cos(radians(LAT)):.6f}, map track {track(r1):.4f} deg")
k = 1 / (1 + sin(radians(LAT)))
print(f"stereographic sheet: map speed {norm(vb):.4f} km/h, stretch {norm(vb) / SPEED:.6f} = 1/(1 + sin lat) {k:.6f}")
print("chart Mercator speed, lat 0..80: " + ", ".join(f"{SPEED / cos(radians(L)):.1f}" for L in range(0, 81, 10)))
print("chart stereo speed, lat 0..80: " + ", ".join(f"{SPEED / (1 + sin(radians(L))):.1f}" for L in range(0, 81, 10)))
deg = (va[0], degrees(va[1]))
print(f"mistake, theta' in deg/h: X' = {mv(JF_a(p), deg)[0]:.1f} km/h")
nosin = mv(JF_a(p), (va[0], east / R))
print(f"mistake, no sin phi: {vec(nosin)} km/h, speed {norm(nosin):.4f}, map track {track(nosin):.4f} deg")
mix = mv(JF_a(p), vb)
print(f"mistake, chart A Jacobian on chart B components: {vec(mix, 1)} km/h")
eq = mv(JF_a((pi / 2, p[1])), va)                              # Heathrow's components
print(f"mistake, Jacobian read at the equator: {vec(eq)} km/h, speed {norm(eq):.4f}, map track {track(eq):.4f} deg")
h = 1 / 3600                                   # over the pole along theta = 0, 1 s each side
before, after = chart_a(pos((SPEED * h / R, 0.0))), chart_a(pos((-SPEED * h / R, 0.0)))
print(f"pole crossing, chart A: phi' = {-SPEED / R:.6f} then {SPEED / R:.6f} rad/h, theta {abs(degrees(before[1])):.1f} then {abs(degrees(after[1])):.1f} deg")
xb = tuple((x - y) / (2 * h) for x, y in zip(chart_b(pos((-SPEED * h / R, 0.0))), chart_b(pos((SPEED * h / R, 0.0)))))
print(f"pole crossing, chart B: xi' = {xb[0]:.4f}, |eta'| = {abs(xb[1]):.4f} km/h, smooth through the pole")
print(f"Mercator stretch at lat 89 and 89.9: {1 / cos(radians(89)):.2f}, {1 / cos(radians(89.9)):.2f}")
assert abs(norm(v3) - SPEED) < 1e-9 and norm(lin((1, v3), (-1, v3h))) < 1e-9   # basis lengths right
assert norm(lin((1, vb), (-1, mv(JT(p), va)))) < 1e-9          # chart B parts from space = transition
assert norm(lin((1, r1), (-1, r2))) < 1e-9                       # one differential, two charts
assert errs[1] < errs[0] / 50 and errs[3] < errs[2] / 50 and max(errs[1], errs[3]) < 1e-4 * norm(r1)   # differences close in
assert abs(norm(r1) / SPEED - 1 / cos(radians(LAT))) < 1e-9      # Mercator stretch = sec(lat)
assert abs(norm(vb) / SPEED - k) < 1e-9 and abs(track(r1) - TRACK) < 1e-9   # stereo stretch; conformal
assert abs(after[1] - before[1]) > 3 and abs(xb[0] + SPEED / 2) < 1e-3     # chart A jumps, B does not
print("ALL CHECKS PASS")
