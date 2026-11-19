# Osculating circle on a bus corner: radius and centre by formula, by a second chart and by three-point circles.
from math import sqrt

A = 20.0      # m from the crossing point O to where the turn starts and ends
BUS = 12.0    # m: the tightest radius the bus's centre line can follow (assumed)
SIDE = 1.75   # m: half the bus's 2.5 m width plus a 0.5 m margin


def pos(t): return (A * t * t, A * (1 - t) ** 2)
def vel(t): return (2 * A * t, -2 * A * (1 - t))
def acc(t): return (2 * A, 2 * A)


def curvature(dx, dy, ax, ay):  # signed: positive turning left
    return (dx * ay - dy * ax) / sqrt(dx * dx + dy * dy) ** 3


def normal(t):  # unit tangent turned a quarter turn left
    dx, dy = vel(t)
    s = sqrt(dx * dx + dy * dy)
    return (-dy / s, dx / s)


def by_formula(t):  # curvature, then the centre 1/k along the unit normal
    k = curvature(*vel(t), *acc(t))
    (x, y), (nx, ny) = pos(t), normal(t)
    return k, (x + nx / k, y + ny / k)


def by_graph(x):  # second chart: the same corner as the graph y = (sqrt(A) - sqrt(x))^2
    y, d1, d2 = (sqrt(A) - sqrt(x)) ** 2, 1 - sqrt(A / x), 0.5 * sqrt(A) * x ** -1.5
    q = 1 + d1 * d1
    return d2 / q ** 1.5, (x - d1 * q / d2, y + q / d2)


def three_point(t, h):  # circle through three nearby points of the path
    (x0, y0), (x1, y1), (x2, y2) = pos(t - h), pos(t), pos(t + h)
    bx, by, cx, cy = x0 - x1, y0 - y1, x2 - x1, y2 - y1
    d = 2 * (bx * cy - by * cx)
    b2, c2 = bx * bx + by * by, cx * cx + cy * cy
    ux, uy = (cy * b2 - by * c2) / d, (bx * c2 - cx * b2) / d
    return sqrt(ux * ux + uy * uy), (x1 + ux, y1 + uy)


def dist(a, b): return sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)
def p(label, v): print(f"{label:<44}{v}")
def xy(c): return f"({c[0]:.2f}, {c[1]:.2f})"


for t, name in [(0.0, "entry"), (0.25, "quarter"), (0.5, "apex")]:
    k, c = by_formula(t)
    p(f"{name} t={t}: point", xy(pos(t)))
    p("  curvature k (1/m), radius 1/k (m)", f"{k:.6f}  {1 / k:.6f}")
    p("  centre", xy(c))
    if t > 0:
        kg, cg = by_graph(pos(t)[0])
        p("  graph chart: k, centre", f"{kg:.6f}  {xy(cg)}")
        assert abs(kg - k) < 1e-12 and dist(cg, c) < 1e-9
        for h in (0.01, 0.001):
            r3, c3 = three_point(t, h)
            p(f"  three-point circle, step {h}", f"{r3:.6f}  ({c3[0]:.6f}, {c3[1]:.6f})")
            assert abs(r3 - 1 / k) < 100 * h * h and dist(c3, c) < 100 * h * h

(dx, dy), (ax, ay), (nx, ny) = vel(0.5), acc(0.5), normal(0.5)
p("apex by hand: velocity, acceleration", f"{xy((dx, dy))}  {xy((ax, ay))}")
p("  cross, speed, speed^3, N", f"{dx * ay - dy * ax:.2f}  {sqrt(dx * dx + dy * dy):.2f}  {sqrt(dx * dx + dy * dy) ** 3:.2f}  ({nx:.4f}, {ny:.4f})")
p("  graph at x = 5: y', y''", f"{1 - sqrt(A / 5):.6f}  {0.5 * sqrt(A) * 5 ** -1.5:.6f}")
kq, cq = by_formula(0.25)
ka, ca = by_formula(0.5)
assert abs(1 / ka - A / sqrt(2)) < 1e-12 and dist(ca, (15, 15)) < 1e-12 and dist(cq, (20, 17.5)) < 1e-12
assert abs(1 / by_formula(0.0)[0] - 2 * A) < 1e-12

print("gap from path to circle at steps 0.04 0.02 0.01 (micrometres); halving ratios")
p("  step lengths along the road, quarter (m)", " ".join(f"{dist(pos(0.25 + st), pos(0.25)):.2f}" for st in (0.04, 0.02, 0.01)))
nq = normal(0.25)
tangent12 = (pos(0.25)[0] + BUS * nq[0], pos(0.25)[1] + BUS * nq[1])
for label, t, c, r, order in [("osculating circle at quarter", 0.25, cq, 1 / kq, 8),
                              ("12 m tangent circle at quarter", 0.25, tangent12, BUS, 4),
                              ("osculating circle at apex", 0.5, ca, 1 / ka, 16)]:
    g = [dist(pos(t + st), c) - r for st in (0.04, 0.02, 0.01)]
    p("  " + label, " ".join(f"{1e6 * v:.2f}" for v in g) + f"   {g[0] / g[1]:.2f} {g[1] / g[2]:.2f}")
    assert abs(g[1] / g[2] - order) < 0.1 * order

kerb = 1 / ka - SIDE
near = min(abs(dist(pos(i / 2000), ca) - kerb) for i in range(2001))
v = 15 / 3.6
p("bus: kerb arc radius round the apex centre", f"{kerb:.2f} m")
p("bus: closest path to kerb arc, 2001 samples", f"{near:.4f} m")
p("bus: shortest turn-in distance for 12 m", f"{BUS * sqrt(2):.2f} m")
p("bus at 15 km/h: v^2 k at entry, apex", f"{v * v * by_formula(0.0)[0]:.3f}  {v * v * ka:.3f} m/s^2")
assert abs(near - SIDE) < 1e-9 and 1 / ka >= BUS

(dx, dy), (ax, ay) = vel(0.25), acc(0.25)
wrong_r = (dx * dx + dy * dy) / sqrt(ax * ax + ay * ay)
wrong_c = (pos(0.25)[0] + ax / sqrt(ax * ax + ay * ay) / kq, pos(0.25)[1] + ay / sqrt(ax * ax + ay * ay) / kq)
p("wrong: speed^2 / |acceleration|, quarter", f"{wrong_r:.2f} m (right {1 / kq:.2f})")
p("wrong: centre on the other side, apex", xy((2 * pos(0.5)[0] - ca[0], 2 * pos(0.5)[1] - ca[1])))
p("wrong: centre along acceleration, quarter", f"{xy(wrong_c)}, {dist(wrong_c, cq):.2f} m off")
p("wrong: 1/|y''| on the graph, apex", f"{1 / (0.5 * sqrt(A) * 5 ** -1.5):.2f} m (right {1 / ka:.2f})")
for t in (0.1, 0.01):
    p(f"cusp (t^2, t^3): radius at t={t}", f"{1 / curvature(2 * t, 3 * t * t, 2, 6 * t):.6f} m")
assert abs(wrong_r - 1 / kq) > 1 and dist(wrong_c, cq) > 1
p("try: A = 15, apex radius (m)", f"{1 / curvature(15, -15, 30, 30):.2f}")
p("try: centres at t=0.1, t=0.4", f"{xy(by_formula(0.1)[1])}  {xy(by_formula(0.4)[1])}")
g19 = [dist(pos(0.25 + st), (pos(0.25)[0] + 19 * nq[0], pos(0.25)[1] + 19 * nq[1])) - 19 for st in (0.02, 0.01)]
p("try: 19 m tangent circle, halving ratio", f"{g19[0] / g19[1]:.2f}")
p("try: 30 km/h, v^2 k at apex", f"{(30 / 3.6) ** 2 * ka:.3f} m/s^2")
p("figure, path (0,20) via O (0,0) to (20,0)", f"centre {xy(ca)} r {1 / ka:.2f}; kerb r {kerb:.2f}")
print("ALL CHECKS PASS")
