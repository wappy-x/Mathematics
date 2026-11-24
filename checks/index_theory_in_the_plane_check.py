# Index theory in the plane -- the check behind the card.  Only math is imported.
# The index of a loop is the net number of turns the field's arrow makes while a
# point walks once anticlockwise round the loop.  Roads: (1) add up the arrow's
# small turns, (2) count signed passes of the arrow through "due east",
# (3) the sign of the Jacobian's determinant, (4) the linear-field integral.
import math
TAU = 2 * math.pi
def pp(x, y): return (x - x * y, -y + x * y)                 # predator-prey, rates 1
def sq(x, y): return (x * x - y * y, 2 * x * y)              # the field z^2
def swing(x, y): return (y, -0.5 * y - math.sin(x))          # the damped swing
def circle(cx, cy, r, n=3600, off=0.25):                     # off 0.25: starts just past due east
    return [(cx + r * math.cos(TAU * (k + off) / n), cy + r * math.sin(TAU * (k + off) / n))
            for k in range(n + 1)]
def turns(F, pts):                                           # road 1
    ang = [math.atan2(F(*p)[1], F(*p)[0]) for p in pts]
    return sum((b - a + math.pi) % TAU - math.pi for a, b in zip(ang, ang[1:])) / TAU
def passes(F, pts):                                          # road 2
    v = [F(*p) for p in pts]
    return sum((g1 < 0 <= g2) - (g2 < 0 <= g1) for (f1, g1), (f2, g2) in zip(v, v[1:]) if f1 > 0 and f2 > 0)
def jac(F, x, y, e=1e-6):                                    # the Jacobian, by differences
    fx = [(a - b) / (2 * e) for a, b in zip(F(x + e, y), F(x - e, y))]
    fy = [(a - b) / (2 * e) for a, b in zip(F(x, y + e), F(x, y - e))]
    return fx[0], fy[0], fx[1], fy[1]
def det_sign(a, b, c, d): return (a * d - b * c > 1e-9) - (a * d - b * c < -1e-9)   # road 3
def linear_index(a, b, c, d, n=20000):                       # road 4, midpoint rule
    ts = [TAU * (k + 0.5) / n for k in range(n)]
    return (a * d - b * c) / n * sum(1 / ((a * math.cos(t) + b * math.sin(t)) ** 2
                                          + (c * math.cos(t) + d * math.sin(t)) ** 2) for t in ts)
def lap(h=0.001):                                            # RK4 once round the orbit from (2, 1)
    p, t, pts = (2.0, 1.0), 0.0, [(2.0, 1.0)]
    while True:
        k1 = pp(*p); k2 = pp(p[0] + h / 2 * k1[0], p[1] + h / 2 * k1[1])
        k3 = pp(p[0] + h / 2 * k2[0], p[1] + h / 2 * k2[1]); k4 = pp(p[0] + h * k3[0], p[1] + h * k3[1])
        q = tuple(p[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in range(2))
        if t > 1 and p[1] < 1 <= q[1]:
            return t + h * (1 - p[1]) / (q[1] - p[1]), pts + [(2.0, 1.0)]
        p, t = q, t + h; pts.append(p)
for name, F, cx, cy, r, want in [("z^2 field, r 1 round (0, 0)", sq, 0, 0, 1, 2),
        ("predator-prey, r 0.5 round (1, 1)", pp, 1, 1, 0.5, 1), ("predator-prey, r 0.5 round (0, 0)", pp, 0, 0, 0.5, -1),
        ("predator-prey, r 3 round both rests", pp, 0.5, 0.5, 3, 0), ("predator-prey, r 1 round (3, 3)", pp, 3, 3, 1, 0)]:
    t1, t2 = turns(F, circle(cx, cy, r)), passes(F, circle(cx, cy, r))
    arrows = " ".join(f"({F(cx + r * c, cy + r * d)[0] + 0.0:.2f}, {F(cx + r * c, cy + r * d)[1] + 0.0:.2f})"
                      for c, d in [(1, 0), (0, 1), (-1, 0), (0, -1)])
    print(f"{name}: arrows at E N W S {arrows}; turns {t1:.6f}, passes due east {t2}")
    assert abs(t1 - want) < 1e-6 and t2 == want                 # roads 1 and 2 agree
for name, F, x, y, want in [("predator-prey (0, 0)", pp, 0, 0, -1), ("predator-prey (1, 1)", pp, 1, 1, 1),
        ("swing hanging (0, 0)", swing, 0, 0, 1), ("swing upside down (pi, 0)", swing, math.pi, 0, -1)]:
    J = jac(F, x, y); s, t1, v = det_sign(*J), turns(F, circle(x, y, 0.01)), linear_index(*J)
    print(f"{name}: sign of det J {s:+d}; turns on a circle of radius 0.01 {t1:.6f}; linear integral {v:.6f}")
    assert s == want and abs(t1 - s) < 1e-6 and abs(v - s) < 1e-6   # roads 3, 1 and 4 agree
T, orbit = lap()
print(f"orbit from (2, 1): lap {T:.4f} years, {len(orbit) - 1} points; arrow turns {turns(pp, orbit):.6f}")
assert abs(turns(pp, orbit) - 1) < 1e-6 and abs(T - 6.6085) < 1e-4
print("chart, turns so far after every 30 degrees of the walk:")
for name, F, cx, cy, r in [("round (1, 1)", pp, 1, 1, 0.5), ("round (0, 0)", pp, 0, 0, 0.5), ("z^2, round (0, 0)", sq, 0, 0, 1)]:
    print(f"  {name}: " + " ".join(f"{turns(F, circle(cx, cy, r)[:300 * k + 1]):.2f}" for k in range(13)))
print("mistake 1, walking clockwise round (1, 1): turns %.6f" % turns(pp, circle(1, 1, 0.5)[::-1]))
print("mistake 2, stopping halfway round (1, 1), due east to due west: turns %.6f" % turns(pp, circle(1, 1, 0.5, off=0)[:1801]))
print("mistake 3, sign of det J for z^2 at (0, 0): %d, true index 2" % det_sign(*jac(sq, 0, 0)))
print("ALL CHECKS PASS")
