# Parallel transport and holonomy -- the check behind the card.  Standard library only.
# A level gyroscope flown North Pole -> London -> New York -> North Pole on great circles,
# Earth a sphere of radius 6371 km.  Four roads to the angle it comes back turned by.
from math import sin, cos, acos, atan2, sqrt, radians, degrees, pi
R = 6371.0
def dot(u, v): return u[0]*v[0] + u[1]*v[1] + u[2]*v[2]
def cross(u, v): return [u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0]]
def add(u, v, k=1.0): return [x + k * y for x, y in zip(u, v)]
def unit(u): return [x / sqrt(dot(u, u)) for x in u]
def point(lat, lon):
    la, lo = radians(lat), radians(lon)
    return [cos(la) * cos(lo), cos(la) * sin(lo), sin(la)]
def toward(a, b): return unit(add(b, a, -dot(a, b)))      # direction leaving a for b
def turned(u, v, n): return atan2(dot(cross(u, v), n), dot(u, v))   # anticlockwise about n
def heading(p, v):                                        # clockwise from north, degrees
    north = unit(add([0.0, 0.0, 1.0], p, -p[2])); east = cross(north, p)
    return degrees(atan2(dot(v, east), dot(v, north))) % 360
def path(a, t, s): return add([x * cos(s) for x in a], t, sin(s)), add([-x * sin(s) for x in a], t, cos(s))
def rk4(f, s, w, h):
    k1 = f(s, w); k2 = f(s + h/2, add(w, k1, h/2)); k3 = f(s + h/2, add(w, k2, h/2)); k4 = f(s + h, add(w, k3, h))
    return [w[i] + h / 6 * (k1[i] + 2*k2[i] + 2*k3[i] + k4[i]) for i in range(len(w))]
def rotate(v, n, t):                                      # Rodrigues: turn v by t about unit axis n
    return add(add([x * cos(t) for x in v], cross(n, v), sin(t)), n, dot(n, v) * (1 - cos(t)))
P, L, Y = [0.0, 0.0, 1.0], point(51.5074, -0.1278), point(40.7128, -74.0060)
legs = [(P, L), (L, Y), (Y, P)]
V0 = toward(P, L)                                         # gyro starts pointing along leg one

# Road 1: on a great circle the transport is the rotation that slides the circle along itself
def by_rotations(legs):
    V, story = V0, []
    for a, b in legs:
        V = rotate(V, unit(cross(a, b)), acos(dot(a, b))); story.append((b, V))
    return V, story
V, story = by_rotations(legs)
psi_rot = turned(V0, V, P)

# Road 2: Euler steps of V' = -(V . p') p along each leg, at two step counts
def euler(n):
    V = V0
    for a, b in legs:
        t, c = toward(a, b), acos(dot(a, b)); h = c / n
        for k in range(n):
            p, dp = path(a, t, k * h); V = add(V, p, -h * dot(V, dp))
    return turned(V0, unit(add(V, P, -V[2])), P), sqrt(dot(V, V))
e100, e200, e10 = euler(100), euler(200), euler(10)

# Road 3: Christoffel symbols in a chart whose pole sits at 0 N, 90 E, away from the route
F1, F2, F3 = [0.0, 0.0, 1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]    # chart axes; pole is F3
def frame(p):                                             # chart angles and basis vectors d_phi, d_theta
    ph, th = acos(dot(p, F3)), atan2(dot(p, F2), dot(p, F1))
    dph = add(add([x * cos(ph) * cos(th) for x in F1], F2, cos(ph) * sin(th)), F3, -sin(ph))
    dth = add([x * -sin(ph) * sin(th) for x in F1], F2, sin(ph) * cos(th))
    return ph, dph, dth
def rhs(a, t):                                            # dV^k/ds = -Gamma^k_ij x'^i V^j
    def f(s, w):
        p, dp = path(a, t, s); ph, dph, dth = frame(p); dphi, dthe = dot(dp, dph), dot(dp, dth) / sin(ph) ** 2
        return [sin(ph) * cos(ph) * dthe * w[1], -cos(ph) / sin(ph) * (dphi * w[1] + dthe * w[0])]
    return f
ph, dph, dth = frame(P)
w, polar = [dot(V0, dph), dot(V0, dth) / sin(ph) ** 2], []
for a, b in legs:
    t, n = toward(a, b), 200; h = acos(dot(a, b)) / n
    for k in range(n):
        w = rk4(rhs(a, t), k * h, w, h); polar.append(frame(path(a, t, k * h)[0])[0])
lo, hi = min(polar), max(polar); ph, dph, dth = frame(P)
psi_chart = turned(V0, add([x * w[0] for x in dph], dth, w[1]), P)

# Road 4: the angle excess, from corner angles measured by tangent directions
def corner(p, q, r): return acos(dot(toward(p, q), toward(p, r)))
angles = [corner(P, L, Y), corner(L, Y, P), corner(Y, P, L)]
excess = sum(angles) - pi

print(f"corner angles: pole {degrees(angles[0]):.2f}, London {degrees(angles[1]):.2f}, New York {degrees(angles[2]):.2f} deg")
print(f"angle sum {degrees(sum(angles)):.2f} deg; excess {degrees(excess):.2f} deg = {excess:.6f} rad")
print(f"area R^2 x excess {R * R * excess:.0f} km^2; K = 1/R^2 = {1 / R**2:.6e} per km^2")
turns = [180 - degrees(x) for x in angles[1:] + angles[:1]]
print(f"route's right turns at London, New York, pole: {turns[0]:.2f}, {turns[1]:.2f}, {turns[2]:.2f}; total {sum(turns):.2f} deg")
print(f"leg lengths: {R * acos(dot(P, L)):.2f}, {R * acos(dot(L, Y)):.2f}, {R * acos(dot(Y, P)):.2f} km")
print("story: place, route heading in -> out, gyro heading (clockwise from north, deg)")
for (a, b), (q, Vq), nxt in zip(legs, story, legs[1:]):
    hin, hout = heading(q, toward(q, a)) - 180, heading(q, toward(q, nxt[1]))
    print(f"  {'London' if q is L else 'New York':9s} in {hin % 360:7.2f} -> out {hout:7.2f}  gyro {heading(q, Vq):7.2f}")
print(f"1 rotations, closed form      {degrees(psi_rot):+.6f} deg")
print(f"2 Euler, 100 steps per leg    {degrees(e100[0]):+.6f} deg, length {e100[1]:.6f}")
print(f"  Euler, 200 steps per leg    {degrees(e200[0]):+.6f} deg, length {e200[1]:.6f}")
print(f"  errors {degrees(e100[0] - psi_rot):+.6f} and {degrees(e200[0] - psi_rot):+.6f} deg")
print(f"3 Christoffel chart, RK4      {degrees(psi_chart):+.6f} deg (chart polar angle {degrees(lo):.2f} to {degrees(hi):.2f})")
print(f"4 minus the angle excess      {-degrees(excess):+.6f} deg (minus: the loop runs clockwise)")
phL = radians(90 - 51.5074)
print(f"Gamma at London, latitude-longitude chart: {-sin(phL) * cos(phL):.6f}, {cos(phL) / sin(phL):.6f}")
pL, dpL, dtL = frame(L)
print(f"Gamma at London, tilted chart:             {-sin(pL) * cos(pL):.6f}, {cos(pL) / sin(pL):.6f}")

# What breaks: (a) arrow held fixed in space; (b) London's parallel, not a great circle
tilt = 90 - degrees(acos(abs(dot(V0, L))))
print(f"wrong: arrow fixed in space   {degrees(turned(V0, unit(add(V0, P, -V0[2])), P)):+.6f} deg, tilted {tilt:.2f} deg off level at London")
def round_parallel(rate):                                 # (south, east) parts turning at rate per radian flown
    u, n = [1.0, 0.0], 3600; h = 2 * pi / n
    for k in range(n): u = rk4(lambda s, u: [rate * u[1], -rate * u[0]], k * h, u, h)
    return degrees(atan2(u[1], u[0])) % 360
psi_lat, psi_fixed = round_parallel(cos(phL)), round_parallel(0.0)   # the chart's equations; fixed angle to the route
print(f"London's parallel eastward: RK4 {psi_lat:.4f} deg; 360(1 - cos phi) {360 * (1 - cos(phL)):.4f}; "
      f"fixed-angle-to-route rule {psi_fixed:.4f}")
print(f"cap area 2 pi R^2 (1 - cos phi) {2 * pi * R * R * (1 - cos(phL)):.0f} km^2")
print(f"wrong: Euler, 10 steps per leg {degrees(e10[0]):+.4f} deg, length {e10[1]:.4f}")
print(f"try: loop flown backwards     {degrees(turned(V0, by_rotations([(P, Y), (Y, L), (L, P)])[0], P)):+.6f} deg")
print(f"try: octant, 3 right angles   {degrees(sum([pi / 2] * 3) - pi):.2f} deg, area {pi * R * R / 2:.0f} km^2")
print(f"real: Foucault at Paris (48.8462 N), 360 sin(lat) = {360 * sin(radians(48.8462)):.2f} deg per sidereal day")
print(f"real: heading gyro, 900 km/h east at London: {degrees(900 / R * cos(phL) / sin(phL)):.2f} deg per hour")
# figure: orthographic view from above the triangle's middle, 150 units = 6371 km
D = unit(add(add(P, L), Y)); up = unit(add(P, D, -D[2])); right = cross(up, D)
xy = lambda p: f"{200 + 150 * dot(p, right):.1f},{175 - 150 * dot(p, up):.1f}"
print(f"figure, pole {xy(P)}, London {xy(L)}, New York {xy(Y)}, arrow start {xy(add(P, V0, 0.3))}, "
      f"arrow end {xy(add(P, V, 0.3))}")
assert abs(psi_rot + excess) < 1e-12                      # holonomy = minus excess (clockwise loop)
assert abs(psi_chart - psi_rot) < 1e-8                    # chart road agrees with closed form
assert abs(e200[0] - psi_rot) < 0.6 * abs(e100[0] - psi_rot) and abs(e200[0] - psi_rot) < 2e-3
assert abs(psi_lat - 360 * (1 - cos(phL))) < 1e-6         # non-geodesic loop: cap area, not 0
assert abs(abs(R * R * excess) - 11873957) < 1            # matches the spherical-triangle card
print("ALL CHECKS PASS")
