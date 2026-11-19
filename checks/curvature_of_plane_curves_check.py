# Curvature of a plane curve -- the check behind the card.  Nothing is imported.
# A rider on a cycle-track bend that keeps tightening is at r(t) = (8t - 0.1t^3, 0.09t^3)
# metres after t seconds, t = 0 to 4.  Signed curvature (positive = turning left) comes
# by four roads: the formula (vx ay - vy ax) / speed^3; the direction angle's turn per metre;
# the same formula on other rides of the same track, with derivatives taken from raw
# positions; and the turn between survey chords.  The total turn is checked against the
# integral of curvature over arc length.  The formula's polynomials run slightly past 4 s.
PI = 3.141592653589793
def atan(z):                                   # arctangent: halve the angle 3 times, then series
    if z < 0: return -atan(-z)
    if z > 1: return PI / 2 - atan(1 / z)
    for _ in range(3): z = z / (1 + (1 + z * z) ** 0.5)
    return 8 * sum((-1) ** k * z ** (2 * k + 1) / (2 * k + 1) for k in range(12))
def direction(dx, dy):                         # direction of (dx, dy), radians anticlockwise from east
    if dx > 0: return atan(dy / dx)
    return (PI / 2 if dy >= 0 else -PI / 2) - atan(dx / dy)
def r(t): return (8 * t - 0.1 * t ** 3, 0.09 * t ** 3)       # position, metres
def vel(t): return (8 - 0.3 * t * t, 0.27 * t * t)         # velocity, m/s
def acc(t): return (-0.6 * t, 0.54 * t)                     # acceleration, m/s^2
def speed(t): return (vel(t)[0] ** 2 + vel(t)[1] ** 2) ** 0.5
def curv(v, a): return (v[0] * a[1] - v[1] * a[0]) / (v[0] ** 2 + v[1] ** 2) ** 1.5
def kappa(t): return curv(vel(t), acc(t))       # the card's formula, per metre
def simpson(f, b, n=400):                      # integral of f from 0 to b
    h = b / n
    return h / 3 * sum((1 if k in (0, n) else 4 if k % 2 else 2) * f(k * h) for k in range(n + 1))
def arc(t): return simpson(speed, t)           # arc length from the start, metres
def raw(path, u, e=1e-3):                      # curvature from raw positions only
    p, q, w = path(u - e), path(u), path(u + e)
    v = ((w[0] - p[0]) / (2 * e), (w[1] - p[1]) / (2 * e))
    a = ((w[0] - 2 * q[0] + p[0]) / e ** 2, (w[1] - 2 * q[1] + p[1]) / e ** 2)
    return curv(v, a)
def chord(t, h):                               # turn between two survey chords, per metre
    p, q, w = r(t - h), r(t), r(t + h)
    a, b = (q[0] - p[0], q[1] - p[1]), (w[0] - q[0], w[1] - q[1])
    ang = direction(a[0] * b[0] + a[1] * b[1], a[0] * b[1] - a[1] * b[0])
    return ang / ((a[0] ** 2 + a[1] ** 2) ** 0.5 / 2 + (b[0] ** 2 + b[1] ** 2) ** 0.5 / 2)
def z(x): return round(x, 9) + 0.0             # prints -0.00 as 0.00

(xp, yp), (xpp, ypp), v = vel(4), acc(4), speed(4)
cross = xp * ypp - yp * xpp
print(f"at 4 s: position ({r(4)[0]:.2f}, {r(4)[1]:.2f}) m, velocity ({xp:.2f}, {yp:.2f}) m/s, acceleration ({xpp:.2f}, {ypp:.2f}) m/s^2")
print(f"cross term vx ay - vy ax = {xp:.2f} x {ypp:.2f} - {yp:.2f} x ({xpp:.2f}) = {cross:.2f}; speed^2 {v * v:.4f}, speed {v:.4f} m/s, speed^3 {v ** 3:.2f}")
print(f"curvature {kappa(4):.6f} per m, radius {1 / kappa(4):.4f} m; sideways acceleration {cross / v:.4f} m/s^2")
assert abs(cross - 6 * 8 * 0.09 * 4) < 1e-12        # algebra: the cross term is 6 x 8 x 0.09 x t
lat = v * v * kappa(4)
print(f"speed^2 x curvature {lat:.4f} m/s^2; rider's lean from upright: atan({lat:.4f} / 9.80665) = {atan(lat / 9.80665) * 180 / PI:.2f} degrees")
assert abs(lat - cross / v) < 1e-12
print("chart: t s | arc length m | speed m/s | direction deg | curvature per m")
pts = [k / 2 for k in range(9)]
for t in pts:
    print(f"chart {t:.1f} | {arc(t):.2f} | {speed(t):.4f} | {z(direction(*vel(t)) * 180 / PI):.2f} | {z(kappa(t)):.6f}")
assert all(kappa(k / 100) < kappa((k + 1) / 100) for k in range(400))  # it keeps tightening
total = direction(*vel(4)) - direction(*vel(0))
integral = simpson(lambda t: kappa(t) * speed(t), 4)
print(f"bend length {arc(4):.4f} m; total turn {total:.6f} rad = {total * 180 / PI:.4f} deg; integral of curvature ds {integral:.6f} rad")
assert abs(total - integral) < 1e-9 and abs(total - 0.9332475286562039) < 1e-14  # atan 1.35, from tables
slow_start = lambda u: r(u * u / 4)            # same track, ridden slowly then fast (u = 0 to 4)
backwards = lambda u: r(4 - u)                  # same track, ridden from the tight end out
mirror = lambda u: (r(u)[0], -r(u)[1])          # the same bend turning right
for t in (2.0, 4.0):
    e = 1e-4                                   # road 2: direction turn per metre of arc
    dth = (direction(*vel(t + e)) - direction(*vel(t - e))) / (arc(t + e) - arc(t - e))
    k3 = raw(slow_start, 2 * t ** 0.5)
    print(f"t = {t:.0f} s: formula {kappa(t):.6f}; direction turn per metre {dth:.6f}; slow-start ride {k3:.6f};"
          f" backwards {raw(backwards, 4 - t):.6f}; mirror {raw(mirror, t):.6f}")
    assert abs(dth - kappa(t)) < 1e-7 and abs(k3 - kappa(t)) < 1e-5
    assert abs(raw(backwards, 4 - t) + kappa(t)) < 1e-5 and abs(raw(mirror, t) + kappa(t)) < 1e-5
for h in (0.5, 0.05):
    print(f"survey chords every {h} s around 2 s: {chord(2, h):.6f} per m, off by {abs(chord(2, h) - kappa(2)):.6f}")
assert abs(chord(2, 0.05) - kappa(2)) < abs(chord(2, 0.5) - kappa(2)) / 50
print(f"mistakes at 4 s: divide by speed^2 {cross / v ** 2:.4f}; graph formula on y(t) {0.54 * 4 / (1 + yp ** 2) ** 1.5:.6f};"
      f" factors swapped {(yp * xpp - xp * ypp) / v ** 3:.6f}")
cusp = lambda u: (u * u, u ** 3)                # zero speed at u = 0
for u in (0.1, 0.01):
    print(f"cusp (u^2, u^3) at u = {u}: speed {(4 * u * u + 9 * u ** 4) ** 0.5:.6f}, curvature {curv((2 * u, 3 * u * u), (2, 6 * u)):.4f} per m")
print("ALL CHECKS PASS")
