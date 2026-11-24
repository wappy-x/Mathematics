# Hyperbolic trigonometry -- the check behind the card.  Standard library only.
# Triangles with legs 1 and 1, at 90 and at 60 degrees, and the angle of parallelism at
# distance 1: each solved by the laws, then built in the half-plane map and measured there.
from math import sinh, cosh, tanh, acosh, asin, acos, atan, atan2, exp, sqrt, sin, cos, degrees, radians
def dist(p, q):                         # half-plane distance between points (x, y)
    return acosh(1 + ((p[0] - q[0])**2 + (p[1] - q[1])**2) / (2 * p[1] * q[1]))
def turn(z, t):                         # turn the whole half-plane by angle t about the point i
    return (cos(t / 2) * z + sin(t / 2)) / (-sin(t / 2) * z + cos(t / 2))
def tangent(p, q):                      # direction leaving p along the line to q
    if abs(p[0] - q[0]) < 1e-12: return (0.0, q[1] - p[1])
    m = (q[0]**2 + q[1]**2 - p[0]**2 - p[1]**2) / (2 * (q[0] - p[0]))   # the arc's centre
    t = (-p[1], p[0] - m)
    return t if t[0] * (q[0] - p[0]) > 0 else (-t[0], -t[1])
def corner(p, q, r):                    # the drawn angle, which is the true angle
    u, v = tangent(p, q), tangent(p, r)
    return atan2(abs(u[0] * v[1] - u[1] * v[0]), u[0] * v[0] + u[1] * v[1])
def solve(a, b, C):                     # road one: the law of cosines, then solved for corners
    c = acosh(cosh(a) * cosh(b) - sinh(a) * sinh(b) * cos(C))
    A = acos((cosh(b) * cosh(c) - cosh(a)) / (sinh(b) * sinh(c)))
    return c, A, acos((cosh(a) * cosh(c) - cosh(b)) / (sinh(a) * sinh(c)))
def build(a, b, C):                     # road two: C at i, A straight up, B turned by C
    z = turn(1j * exp(a), -C)
    return (0.0, exp(b)), (z.real, z.imag), (0.0, 1.0)
f, deg = lambda x: f"{x:.6f}", lambda x: f"{degrees(x):.2f}"
for Cd in (90, 60):
    C = radians(Cd); c, A, B = solve(1, 1, C); PA, PB, PC = build(1, 1, C)
    side, ang = [dist(PA, PB), dist(PB, PC), dist(PC, PA)], [corner(PA, PB, PC), corner(PB, PC, PA), corner(PC, PA, PB)]
    print(f"legs 1, 1 at {Cd} deg: cosh c = {f(cosh(c))}, c = {f(c)}; flat {f(sqrt(2 - 2 * cos(C)))}")
    print(f"  built: A (0, {exp(1):.6f}), B ({PB[0]:.6f}, {PB[1]:.6f}), C (0, 1); measured sides {', '.join(map(f, side))}")
    print(f"  corners A, B, C by the laws {deg(A)}, {deg(B)}, {deg(C)}; measured {', '.join(map(deg, ang))}; sum {deg(A + B + C)}")
    sines = [sin(A) / sinh(1), sin(B) / sinh(1), sin(C) / sinh(c)]
    assert max(abs(x - y) for x, y in zip(side + ang, [c, 1, 1, A, B, C])) < 1e-9          # two roads agree
    assert max(sines) - min(sines) < 1e-12 and abs(sin(A) - sinh(1) / sinh(c) * sin(C)) < 1e-12  # sine law
    if Cd == 90: c90, A90, s90 = c, A, sines[0]
print(f"right triangle: sinh 1 = {f(sinh(1))}, sinh c = {f(sinh(c90))}, sine law ratio {f(s90)}; shortfall {deg(radians(90) - 2 * A90)} deg = {f(radians(90) - 2 * A90)} rad")
u = tanh(1)                             # rapidity 1: a speed, as a fraction of light's
einstein = sqrt(u * u + u * u * (1 - u * u))   # perpendicular velocity addition, no geometry
print(f"two boosts of rapidity 1 at right angles: speed {f(u)} c each, gamma {f(cosh(1))}; combined gamma {f(cosh(c90))}, speed {f(tanh(c90))} c; Einstein's rule {f(einstein)} c")
assert abs(einstein - tanh(c90)) < 1e-12
Pi = 2 * atan(exp(-1))                  # angle of parallelism at distance 1
lo, hi = 0.0, 1.5                       # road two: swing a line about i until it just misses L
for _ in range(60):
    mid = (lo + hi) / 2
    if turn(0j, mid).real < exp(-1): lo = mid    # its foot still lands inside L: it meets L
    else: hi = mid
far = [deg(solve(x, 1, radians(90))[1]) for x in (1, 2, 5, 10)]
print(f"angle of parallelism at d = 1: e^-1 = {f(exp(-1))}, 2 atan(e^-1) = {degrees(Pi):.4f} deg; cos = {f(cos(Pi))} = tanh 1; swung line {degrees(lo):.4f} deg")
print(f"right triangles, legs 1 and x, angle at P for x = 1, 2, 5, 10: {', '.join(far)} deg")
assert abs(lo - Pi) < 1e-12 and abs(cos(Pi) - tanh(1)) < 1e-12 and abs(solve(10, 1, radians(90))[1] - Pi) < 1e-6
cs = solve(0.01, 0.01, radians(90))[0]
print(f"small: legs 0.01 give c = {cs:.8f}, flat {sqrt(2) * 0.01:.8f}, ratio {cs / (sqrt(2) * 0.01):.7f}")
assert abs(cs / (sqrt(2) * 0.01) - 1) < 1e-4 and c90 > sqrt(2)
plus = acosh(cosh(1)**2 + sinh(1)**2 * cos(radians(60)))
print(f"mistakes: flat Pythagoras {f(sqrt(2))}; flat corners 45.00 deg; speeds by flat Pythagoras {f(sqrt(2) * u)} c; sphere's plus sign at 60 deg {f(plus)}")
X = lambda x: 120 + 100 * x; Y = lambda y: 320 - 100 * y
m = (1 - exp(2)) / (2 * build(1, 1, radians(90))[1][0])
B9 = build(1, 1, radians(90))[1]
print(f"figure, left 100 = 1: A {X(0):.1f},{Y(exp(1)):.1f} B {X(B9[0]):.1f},{Y(B9[1]):.1f} C {X(0):.1f},{Y(1):.1f} arc AB centre {X(m):.1f} radius {100 * sqrt(m * m + exp(2)):.1f}")
print(f"figure, right 150 = 1 from 470,320: P 470.0,170.0 L radius {150 * exp(-1):.1f} parallel centre {470 - 150 * sinh(1):.1f} radius {150 * cosh(1):.1f}")
print("ALL CHECKS PASS")
