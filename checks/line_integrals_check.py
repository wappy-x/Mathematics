# Line integrals of a field -- the check behind the card.  Standard library
# only; math gives sqrt as a primitive, and every sum is written out here.
# Wind pushes a cart with force F(x, y) = (y/10, -1) newtons at the point
# x m east and y m north of corner A.  The cart goes from A to B by four routes.
from math import sqrt

def F(x, y): return (y / 10, -1.0)
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def line(p, q):                    # a straight piece from p to q, clock t from 0 to 1
    return (lambda t: (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t),
            lambda t: (q[0] - p[0], q[1] - p[1]))
A, B, NW, SE = (0, 0), (40, 30), (0, 30), (40, 0)
curve = (lambda t: (40 * t, 30 * t * t), lambda t: (40.0, 60 * t))
routes = {"straight": [line(A, B)], "curve": [curve],
          "east, then north": [line(A, SE), line(SE, B)],
          "north, then east": [line(A, NW), line(NW, B)]}
by_hand = {"straight": 120 / 2 - 30, "curve": 120 / 3 - 60 / 2,
           "east, then north": 0 - 30, "north, then east": -30 + 3 * 40}

def simpson(g, n=100):             # road one: integral of F(r(t)).r'(t) dt, Simpson's rule
    h = 1 / n
    return h / 3 * (g(0) + g(1) + sum((4 if i % 2 else 2) * g(i * h) for i in range(1, n)))
def formula(route): return sum(simpson(lambda t: dot(F(*r(t)), v(t))) for r, v in route)
def chords(route, n):              # road two, the definition: mid-piece force . each chord
    total = 0.0
    for r, _ in route:
        for i in range(n):
            p, q, m = r(i / n), r((i + 1) / n), r((i + 0.5) / n)
            total += dot(F(*m), (q[0] - p[0], q[1] - p[1]))
    return total

print("wind force (y/10, -1) N at (x, y) m; cart from A (0, 0) to B (40, 30)")
print(f"by hand: straight length {sqrt(40 ** 2 + 30 ** 2):.0f} m, direction ({40 / 50:.1f}, {30 / 50:.1f}); "
      f"north leg {-1 * 30:.0f} J; east leg at y = 30: {F(0, 30)[0]:.0f} N x 40 m = {F(0, 30)[0] * 40:.0f} J")
for name, route in routes.items():
    print(f"{name}: formula {formula(route):.6f} J, by hand {by_hand[name]:.6f} J, "
          f"1024 chords {chords(routes[name], 1024):.6f} J")
for n in (4, 16, 32, 64):
    print(f"curve, {n:2d} chords: {chords([curve], n):.6f} J, short by {10 - chords([curve], n):.6f} J")
pace = formula([(lambda s: (40 * s * s, 30 * s * s), lambda s: (80 * s, 60 * s))])
back = formula([line(B, A)])
loop = formula(routes["north, then east"]) + formula([line(B, SE), line(SE, A)])
print(f"straight, slow start (40s^2, 30s^2): {pace:.6f} J; straight, B to A: {back:.6f} J")
print(f"loop, north-then-east out, hedge route back: {loop:.6f} J; 0.1 N/m x 40 m x 30 m = {0.1 * 40 * 30:.6f}")
print(f"mistake 1, B to A with the A-to-B velocity: {simpson(lambda t: dot(F(*line(B, A)[0](t)), (40, 30))):.3f} J, not -30")
print(f"mistake 2, speed factor dropped: {simpson(lambda t: dot(F(40 * t, 30 * t), (0.8, 0.6))):.3f} J, not 30")
print(f"mistake 3, strength |F| times length: {simpson(lambda t: 50 * sqrt((3 * t) ** 2 + 1)):.3f} N m, not 30 J")
print(f"mistake 4, same ends so same work: straight 30 J copied to north-then-east, truly {by_hand['north, then east']:.0f} J")
X, Y = (lambda x: 50 + 6 * x), (lambda y: 210 - 6 * y)
print("figure, 6 units per m, curve:", " ".join(f"({X(40 * t / 8):.1f},{Y(30 * (t / 8) ** 2):.1f})" for t in range(9)))
print("figure, arrows 6 units per N, tail->head:", " ".join(
    f"({X(x):.0f},{Y(y):.0f})->({X(x + y / 10):.1f},{Y(y - 1):.0f})" for x, y in ((6, 12), (6, 24), (16, 26), (26, 26), (34, 4), (34, 12))))
for name in routes:
    assert abs(formula(routes[name]) - by_hand[name]) < 1e-9     # road one against the hand
    assert abs(chords(routes[name], 1024) - by_hand[name]) < 1e-4  # road two, the definition
assert abs(pace - 30) < 1e-9 and abs(back + 30) < 1e-9 and abs(chords([line(B, A)], 1024) + 30) < 1e-9  # new clock: same; reversed: negated, both roads
assert abs(loop - 0.1 * 40 * 30) < 1e-9                         # the loop against wind gain x area
print("ALL CHECKS PASS")
