# Rigid motions in space and screws -- the check behind the card.  Standard library only.
# The drone's move: turn 90 degrees about the vertical through (0, 0, 0), then shift (1, 0, 2).
# Road one: axis and screw by formula.  Two: grid search for the least move.  Three: four mirrors.
from math import atan2, cos, sin, tan, sqrt, degrees

def dot(a, b): return sum(x * y for x, y in zip(a, b))
def add(a, b, k=1): return [x + k * y for x, y in zip(a, b)]
def cross(a, b): return [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]
def move(R, t, x): return add([dot(row, x) for row in R], t)
def unit(v): return [x / sqrt(dot(v, v)) for x in v]
def gap(a, b): return sqrt(dot(add(a, b, -1), add(a, b, -1)))
def f(v, n=6): return "(" + ", ".join(f"{(x if abs(x) >= 5e-7 else 0.0):.{n}f}" for x in v) + ")"
def screw(R, t):                       # road one: axis u, angle, slide s, axis point c
    w = [R[2][1] - R[1][2], R[0][2] - R[2][0], R[1][0] - R[0][1]]   # = 2 sin(angle) u
    u = unit(w)
    th = atan2(sqrt(dot(w, w)) / 2, (R[0][0] + R[1][1] + R[2][2] - 1) / 2)
    s = dot(t, u)
    tp = add(t, u, -s)                 # the sideways part of the shift
    return u, th, s, tp, [(a + b / tan(th / 2)) / 2 for a, b in zip(tp, cross(u, tp))]
def axis_two(R):                       # second road: cross two rows of R - I, turn a side arrow
    m = [[R[i][j] - (i == j) for j in range(3)] for i in range(3)]
    u = unit(cross(m[0], m[1]))
    v = cross(u, [1, 0, 0])
    rv = move(R, [0, 0, 0], v)
    return u, atan2(dot(u, cross(v, rv)), dot(v, rv)), dot(m[0], cross(m[1], m[2]))
def rebuilt(u, th, s, c, x):           # turn about the line through c, then slide s along u
    v = add(x, c, -1)
    r = add([a * cos(th) + b * sin(th) for a, b in zip(v, cross(u, v))], u, dot(u, v) * (1 - cos(th)))
    return add(add(c, r), u, s)
def mirror(n, k, x): return add(x, n, -2 * (dot(n, x) - k) / dot(n, n))   # plane n.x = k

R, Rc, t, p = [[0, -1, 0], [1, 0, 0], [0, 0, 1]], [[0, 0, 1], [1, 0, 0], [0, 1, 0]], [1, 0, 2], [2, 3, 5]
tests = [p, [0, 0, 0], [10, 0, 0], [10, 4.8, 3.6], [0, 4.8, 3.6]]   # drone, panel corners
for name, Q in (("drone turn", R), ("camera mount x->y->z->x", Rc)):
    u, th, s, tp, c = screw(Q, t)
    u2, th2, d = axis_two(Q)
    err = max(gap(rebuilt(u, th, s, c, x), move(Q, t, x)) for x in tests)
    print(f"{name}: det(R - I) = {d:.6f}, trace {Q[0][0] + Q[1][1] + Q[2][2]}")
    print(f"  axis {f(u)} from the lopsided entries, {f(u2)} from rows of R - I")
    print(f"  angle {degrees(th):.6f} from the trace, {degrees(th2):.6f} by turning a side arrow")
    print(f"  slide {s:.6f}, sideways shift {f(tp)}, axis point {f(c)}, screw rebuilt matches: {'yes' if err < 1e-9 else 'no'}")
    assert abs(d) < 1e-12 and gap(u, u2) < 1e-12 and abs(th - th2) < 1e-12 and err < 1e-9
u, th, s, tp, c = screw(R, t)
best = min((gap(move(R, t, [i / 100, j / 100, 0]), [i / 100, j / 100, 0]), i, j)
           for i in range(-300, 301) for j in range(-300, 301))   # road two
print(f"drone {f(p, 0)} -> {f(move(R, t, p), 0)}, moved {gap(p, move(R, t, p)):.6f} m; grid search: least move {best[0]:.6f} at ({best[1] / 100:.2f}, {best[2] / 100:.2f})")
four = [move(R, t, x) for x in tests]
for n, k in ([0, 0, 1], 0), ([0, 0, 1], 1), ([0, 1, 0], 0.5), ([-1, 1, 0], 0): tests = [mirror(n, k, x) for x in tests]          # road three
print(f"four mirrors z = 0, z = 1, y = 0.5, y = x send the drone to {f(tests[0], 0)}, all five points match: {'yes' if max(gap(a, b) for a, b in zip(tests, four)) < 1e-12 else 'no'}")
w = rebuilt(u, th, s, [0, 0, 0], p)
print(f"mistake, axis through (0, 0, 0): drone -> {f(w, 0)}, {gap(w, move(R, t, p)):.6f} m from the truth")
print(f"mistake, whole shift as the slide: {sqrt(dot(t, t)):.6f} m, not {s:.6f} m")
print(f"mistake, shift before the turn: axis point {f(screw(R, move(R, [0, 0, 0], t))[4], 1)}")
P = lambda v: f"({200 + 50 * v[0]:.2f}, {220 - 50 * v[1]:.2f})"
print(f"figure, 1 m = 50 units, axis {P(c)} start {P(p)} end {P(move(R, t, p))} radius {50 * gap(p[:2], c[:2]):.2f}")
assert abs(best[0] - s) < 1e-12 and gap([best[1] / 100, best[2] / 100], c[:2]) < 1e-9   # roads one and two
assert gap(c, [0.5, 0.5, 0]) < 1e-12 and abs(s - 2) < 1e-12          # the hand solution
assert max(gap(a, b) for a, b in zip(tests, four)) < 1e-12            # road three
print("ALL CHECKS PASS")
