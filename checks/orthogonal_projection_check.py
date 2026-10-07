# Projection -- the check behind the card.  Nothing is imported.  A rower pulls
# with force (6, 2) while the boat points along (1, 1).  Road one is the formula.
# Road two never touches it: it fits the parabola through three squared distances
# from the pull to the line and takes that parabola's lowest point.  The plane
# case is done twice too, from two perpendicular pairs inside the same plane.
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def scale(t, a): return tuple(t * x for x in a)
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def add(a, b): return tuple(x + y for x, y in zip(a, b))
def n(x): return f"{x:.4f}".rstrip("0").rstrip(".")
def show(a): return "(" + ", ".join(n(x) for x in a) + ")"
def one(name, value): print(f"{name:<44}{value}")
def project(u, v): return scale(dot(u, v) / dot(v, v), v)          # road one

u, v = (6, 2), (1, 1)                        # the pull, and the boat's heading
p = project(u, v)                            # the shadow
e = sub(u, p)                                # the leftover
one("the pull u and the boat's heading v", show(u) + " and " + show(v))
one("u . v and v . v", f"{n(dot(u, v))} and {n(dot(v, v))}")
one("t = (u . v) / (v . v)", n(dot(u, v) / dot(v, v)))
one("the shadow p = t v", show(p))
one("the leftover e = u - p", show(e))
one("e . v and e . p", f"{n(dot(e, v))} and {n(dot(e, p))}")
one("lengths of u, p, e: squared, then actual",
    f"{n(dot(u, u))}, {n(dot(p, p))}, {n(dot(e, e))} then "
    f"{n(dot(u, u) ** 0.5)}, {n(dot(p, p) ** 0.5)}, {n(dot(e, e) ** 0.5)}")

def dist2(t): return sum((x - t * y) ** 2 for x, y in zip(u, v))   # no dot product used
one("squared distance from u to t v, t = 0 to 8", ", ".join(n(dist2(t)) for t in range(9)))
c = dist2(0)                                             # road two: fit the parabola
a, b = (dist2(1) + dist2(-1)) / 2 - c, (dist2(1) - dist2(-1)) / 2
t_low = -b / (2 * a)
one("road two: the parabola a, b, c", f"{n(a)}, {n(b)}, {n(c)}")
one("road two: lowest at t, and the point there", f"{n(t_low)}, {show(scale(t_low, v))}")

f, w1, w2 = (6, 2, 3), (1, 1, 0), (1, -1, 0)     # the same pull, now lifting a little
pp = add(project(f, w1), project(f, w2))
ee = sub(f, pp)
one("the plane: pull " + show(f) + ", parts w1, w2",
    show(project(f, w1)) + " + " + show(project(f, w2)))
one("the shadow on the plane", show(pp))
one("the leftover, then its dots with w1 and w2",
    f"{show(ee)}, {n(dot(ee, w1))} and {n(dot(ee, w2))}")
alt = add(project(f, (1, 0, 0)), project(f, (0, 1, 0)))   # road two: another pair
one("road two: same plane, from (1,0,0), (0,1,0)", show(alt))

m1 = scale(dot(u, v), v)                                  # forgot to divide at all
m2 = scale(dot(u, v) / dot(v, v) ** 0.5, v)               # divided by the length
m3 = project(v, u)                                        # projected the wrong way round
m4 = sub(f, project(f, w1))                               # used one direction of two
one("mistake 1: never divided", f"{show(m1)}, leftover . v = {n(dot(sub(u, m1), v))}")
one("mistake 2: divided by the length",
    f"{show(m2)}, squared miss {n(sum((x - y) ** 2 for x, y in zip(u, m2)))}")
one("mistake 3: projected the wrong way round", show(m3))
one("mistake 4: one direction of the two", f"{show(m4)}, and m4 . w2 = {n(dot(m4, w2))}")
assert p == (4.0, 4.0) and e == (2.0, -2.0) and dot(e, v) == 0 and dot(e, p) == 0
assert t_low == 4.0 and scale(t_low, v) == p and abs(dist2(t_low) - dot(e, e)) < 1e-12
assert dot(u, u) == dot(p, p) + dot(e, e) == 40
assert pp == alt == (6.0, 2.0, 0.0) and ee == (0.0, 0.0, 3.0) and dot(ee, w1) == dot(ee, w2) == 0
print("ALL CHECKS PASS")
