# Power of a point -- the check behind the card.  math supplies hypot, sqrt,
# cos, sin, atan2 and pi, nothing more.  A round pond, radius 5 m, has its
# centre at (0, 0).  Road one: the formula d^2 - r^2.  Road two: lines and
# tangents measured on the drawing, each meeting point found by bisection.
import math

def dist(p, q): return math.hypot(p[0] - q[0], p[1] - q[1])
def power(p, c, r): return dist(p, c) ** 2 - r ** 2   # road one

def halve(f, lo, hi):                          # bisection: f changes sign on [lo, hi]
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (f(lo) > 0) == (f(mid) > 0) else (lo, mid)
    return (lo + hi) / 2

def crossing(p, deg, c, r):                    # road two: walk a line through p
    u = (math.cos(deg * math.pi / 180), math.sin(deg * math.pi / 180))
    f = lambda t: dist((p[0] + t * u[0], p[1] + t * u[1]), c) - r
    lo, hi = -60.0, 60.0                       # closest approach to c, by thirds
    for _ in range(200):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, b) if f(a) < f(b) else (a, hi)
    return tuple(sorted((abs(halve(f, -60.0, lo)), abs(halve(f, lo, 60.0)))))

def tangent(p, c, r):                          # road two: the rim point where CT is square to PT
    a, rim = math.atan2(p[1] - c[1], p[0] - c[0]), lambda f: (c[0] + r * math.cos(f), c[1] + r * math.sin(f))
    g = lambda f: (rim(f)[0] - c[0]) * (rim(f)[0] - p[0]) + (rim(f)[1] - c[1]) * (rim(f)[1] - p[1])
    t = rim(halve(g, a, a + math.pi))
    return dist(t, p), t

O, R, P, Q, O2, R2, O3, R3 = (0.0, 0.0), 5.0, (13.0, 0.0), (-3.0, 0.0), (28.0, 0.0), 9.0, (0.0, 20.0), 5.0
(near, far), (tp, T) = crossing(P, 0, O, R), tangent(P, O, R)
outs, ins = [crossing(P, d, O, R) for d in (0, 10, 20)], [crossing(Q, d, O, R) for d in (0, 30, 60, 90)]
x_ax = (28 ** 2 + R ** 2 - R2 ** 2) / (2 * 28)
tl = [(tangent((x_ax, y), O, R)[0], tangent((x_ax, y), O2, R2)[0]) for y in (0.0, 5.0, 10.0)]
rc = (x_ax, (O3[1] ** 2 + R ** 2 - R3 ** 2) / (2 * O3[1]))
t3 = [tangent(rc, c, r)[0] for c, r in ((O, R), (O2, R2), (O3, R3))]
pairs = lambda xs: ", ".join(f"{a:.3f} x {b:.3f} = {a * b:.3f}" for a, b in xs)
print(f"pond radius {R:g} m; stake P {P[0]:g} m out: power {P[0]:g}^2 - 5^2 = {power(P, O, R):g}")
print(f"tangent measured {tp:.3f} m, touching at ({T[0]:.3f}, {T[1]:.3f}); line through O: {near:.3f} and {far:.3f}")
print(f"tilted 0, 10, 20 deg: {pairs(outs)}")
print(f"diameter from the bank: far bank {power(P, O, R):g} / {near:g} = {power(P, O, R) / near:.3f} m, minus {near:g} = {power(P, O, R) / near - near:.3f} m")
print(f"fountain Q {abs(Q[0]):g} m from O: power {abs(Q[0]):g}^2 - 5^2 = {power(Q, O, R):g}")
print(f"crossings at 0, 30, 60, 90 deg: {pairs(ins)}")
print(f"second pond: centre (28, 0), radius {R2:g}; radical axis x = (28^2 + 5^2 - {R2:g}^2) / 56 = {x_ax:g}")
print("on it, y = 0, 5, 10: tangents " + ", ".join(f"{a:.3f} and {b:.3f}" for a, b in tl))
print(f"third pond (0, 20), radius 5: radical centre ({rc[0]:g}, {rc[1]:g}), power {power(rc, O, R):g}, "
      f"tangents {t3[0]:.3f}, {t3[1]:.3f}, {t3[2]:.3f}")
print(f"horizon from 1.7 m: sqrt(0.0017 x (2 x 6371 + 0.0017)) = {math.sqrt(0.0017 * (2 * 6371 + 0.0017)):.3f} km")
print(f"arch 8 m wide, 2 m high: 4 x 4 = 2 x (2r - 2), so r = {(4 * 4 / 2 + 2) / 2:g} m")
print(f"mistake 1, outside x inside: {near:g} x {far - near:g} = {near * (far - near):g}, tangent {math.sqrt(near * (far - near)):.3f} m")
print(f"mistake 2, tangent taken as d - r: {P[0] - R:g} m, not {tp:.0f}")
print(f"mistake 3, axis at the midpoint x = 14: tangents {tangent((14.0, 0.0), O, R)[0]:.3f} and {tangent((14.0, 0.0), O2, R2)[0]:.3f}")
print(f"figure, 1 m = 20 units: O (130, 120), radius 100, P (390, 120), T ({130 + 20 * T[0]:.1f}, {120 - 20 * T[1]:.1f}), "
      f"Q (70, 120), chord (70, 40) to (70, 200)")
assert all(abs(a * b - power(P, O, R)) < 1e-9 for a, b in outs)            # every secant: 144
assert all(abs(a * b + power(Q, O, R)) < 1e-9 for a, b in ins)             # every chord: 16
assert abs(tp ** 2 - power(P, O, R)) < 1e-9 and abs(far - near - 2 * R) < 1e-9  # tangent; diameter
assert all(abs(a - b) < 1e-9 for a, b in tl) and abs(t3[2] ** 2 - power(rc, O2, R2)) < 1e-9
print("ALL CHECKS PASS")
