# Circles and parabolas -- the check behind the card.  Only sqrt is imported.
# A dish 80 cm across and 10 cm deep, cut through its centre: the vertex at
# (0, 0), y in cm up the axis.  Each fact is reached by two roads.
from math import sqrt
W, DEPTH = 80.0, 10.0                     # dish width and depth (cm)
p = (W / 2) ** 2 / (4 * DEPTH)            # road one: x^2 = 4py at the rim gives p
def curve(x): return x * x / (4 * p)      # the dish's height at x
def dist(P, Q): return sqrt((P[0] - Q[0]) ** 2 + (P[1] - Q[1]) ** 2)

def ray_crossing(x):                      # road two: a signal falls straight down,
    e = 1e-6                              # bounces off the dish and crosses the axis
    m = (curve(x + e) - curve(x - e)) / (2 * e)        # slope of a very short chord
    ux, uy = 1 / sqrt(1 + m * m), m / sqrt(1 + m * m)  # unit arrow along the surface
    d = -uy                                # dot product of (0, -1) with that arrow
    rx, ry = 2 * d * ux, 2 * d * uy + 1    # mirror image: 2 (v . u) u - v
    t = -x / rx                            # distance travelled to reach x = 0
    return curve(x) + t * ry, t

print(f"dish {W:.0f} cm across, {DEPTH:.0f} cm deep: 4p = {4 * p:.2f}, p = {p:.2f} cm")
print(f"focus F (0, {p:.2f}); directrix y = {-p:.2f}; equation x^2 = {4 * p:.0f} y")
for x in (0.0, 20.0, 40.0):
    P = (x, curve(x))
    print(f"point ({x:.0f}, {P[1]:.2f}): to F {dist(P, (0, p)):.2f} cm, to directrix {P[1] + p:.2f} cm")
for x in (12.0, 20.0, 28.0, 40.0):
    y, t = ray_crossing(x)
    print(f"ray down at x = {x:.0f}: bounces, crosses the axis at y = {y:.2f} after {t:.2f} cm")
Fp, Dp = (0.0, p), (40.0, -p)            # focus, and the rim point's foot on the directrix
m = 40.0 / (2 * p)                        # tangent: at right angles to F->D, through P
b, c = -4 * p * m, -4 * p * (DEPTH - 40 * m) # put y = DEPTH + m(x - 40) in x^2 = 4py
chord = (curve(40 + 1e-6) - curve(40 - 1e-6)) / 2e-6
print(f"tangent at P (40, {DEPTH:.0f}): through midpoint ({(Fp[0] + Dp[0]) / 2:.2f}, {(Fp[1] + Dp[1]) / 2:.2f}) "
      f"of F and D (40, {Dp[1]:.2f}), slope {m:.2f}; x^2 {b:+.0f}x {c:+.0f} = 0, discriminant {b * b - 4 * c:.2f}")
D, E, F = 0, -80, -900                    # the circle x^2 + y^2 + Dx + Ey + F = 0
h, k = -D / 2, -E / 2                     # road one: complete both squares
r = sqrt(h * h + k * k - F)
pts = [(40, 10), (-40, 10), (30, 80)]     # three points that satisfy it exactly
on = "yes" if all(x * x + y * y + D * x + E * y + F == 0 for x, y in pts) else "no"
(x1, y1), (x2, y2), (x3, y3) = pts        # road two: the point equally far from all
a1, b1, c1 = 2 * (x2 - x1), 2 * (y2 - y1), x2 * x2 + y2 * y2 - x1 * x1 - y1 * y1
a2, b2, c2 = 2 * (x3 - x1), 2 * (y3 - y1), x3 * x3 + y3 * y3 - x1 * x1 - y1 * y1
det = a1 * b2 - a2 * b1                   # two straight-line equations, Cramer's rule
cx, cy = (c1 * b2 - c2 * b1) / det + 0.0, (a1 * c2 - a2 * c1) / det
cr = dist((cx, cy), pts[0])
print(f"circle x^2 + y^2 - 80y - 900 = 0: centre ({h:.2f}, {k:.2f}), radius {r:.2f} cm")
print(f"three points on it: {on}; the point equally far from them: ({cx:.2f}, {cy:.2f}), {cr:.2f} cm")
print(f"mistake, 4p read as p: focus at {4 * p:.2f} cm, rim point {dist((40, DEPTH), (0, 4 * p)):.2f} cm "
      f"from it, {DEPTH + 4 * p:.2f} cm from its directrix")
print(f"mistake, full width for half: p = {W * W / (4 * DEPTH):.2f} cm")
print(f"mistake, r^2 read as r: radius {r * r:.2f}; sign flipped: centre (0.00, {-k:.2f})")
s, Y0 = 2.2, 122.0                        # figure: 1 cm = 2.2 units, y down
def fig(x, y): return f"({180 + s * x:.2f}, {Y0 - s * y:.2f})"
print(f"figure, 1 cm = {s} units: V {fig(0, 0)}, F {fig(0, p)}, P {fig(40, DEPTH)}, Q {fig(-40, DEPTH)}, "
      f"control {fig(0, -DEPTH)}, D {fig(40, -p)}, ray top {fig(40, 40)}")
for x in (12.0, 20.0, 28.0, 40.0):
    assert abs(ray_crossing(x)[0] - p) < 1e-6              # the bounce finds the focus
for x in (5.0, 25.0, 40.0):
    assert abs(dist((x, curve(x)), (0, p)) - (curve(x) + p)) < 1e-9   # the distance rule
assert abs(m - chord) < 1e-6 and abs(b * b - 4 * c) < 1e-9  # tangent: two roads, one touch
assert on == "yes" and abs(cx - h) + abs(cy - k) + abs(cr - r) < 1e-9  # centre and radius
print("ALL CHECKS PASS")
