# Projective space and homogeneous coordinates -- the check behind the card.
# Standard library only.  Fraction keeps the chart arithmetic exact.  A lamp at
# the origin throws the light cone x^2 + y^2 = z^2.  A point of the projective
# plane is a whole line through the lamp; the ceiling z = 1 and the wall x = 1
# are two charts of it.  Then P^n and the cone are counted over F_p, three ways.
from fractions import Fraction as Q

def cone(v): return v[0] * v[0] + v[1] * v[1] - v[2] * v[2]
def pair(a, b): return f"({a}, {b})"
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def yn(c): return "yes" if c else "no"
def charts(r): return (r[0] / r[2], r[1] / r[2]), (r[1] / r[0], r[2] / r[0]), (r[0] / r[1], r[2] / r[1])
def to_wall(u, v): return (v / u, 1 / u)          # ceiling (u, v) is the triple (u, v, 1)
def to_ceil(s, t): return (1 / t, s / t)          # wall (s, t) is the triple (1, s, t)

r = (Q(3), Q(4), Q(-5))                          # down to the wall; its other half, (-3, -4, 5), goes up
ceil, wall, side = charts(r)
print("lamp at the origin; light cone x^2 + y^2 = z^2; ceiling z = 1 m, wall x = 1 m")
print(f"line (3 : 4 : -5): cone value {cone(r)}; scaled by 2, -1, -1/5: "
      + ", ".join(str(cone([l * c for c in r])) for l in (2, -1, Q(-1, 5))))
print(f"chart z = 1, ceiling: (x, y) = {pair(*ceil)}; x^2 + y^2 = 1: {yn(ceil[0]**2 + ceil[1]**2 == 1)}")
print(f"chart x = 1, wall: (y, z) = {pair(*wall)}; z^2 - y^2 = 1: {yn(wall[1]**2 - wall[0]**2 == 1)}")
print(f"chart y = 1: (x, z) = {pair(*side)}; z^2 - x^2 = 1: {yn(side[1]**2 - side[0]**2 == 1)}")
assert ceil[0]**2 + ceil[1]**2 == 1 and wall[1]**2 - wall[0]**2 == 1 and side[1]**2 - side[0]**2 == 1
print(f"ceiling to wall, (u, v) -> (v/u, 1/u): {pair(*to_wall(*ceil))}; wall back to ceiling: "
      f"{pair(*to_ceil(*to_wall(*ceil)))}")
m = Q(-2)                                         # slope of a ceiling line through (-1, 0)
sl = (1 - m * m, 2 * m, 1 + m * m)
print(f"ceiling line of slope {m} through (-1, 0): (1 - m^2 : 2m : 1 + m^2) = ({sl[0]} : {sl[1]} : {sl[2]}), "
      f"the same point as (3 : 4 : -5): {yn(cross(sl, r) == (0, 0, 0))}")
assert cross(sl, r) == (0, 0, 0) and ceil[1] == m * (ceil[0] + 1)   # proportional; on that line
r2 = (Q(5), Q(12), Q(13))
c2, w2, _ = charts(r2)
print(f"line ({r2[0]} : {r2[1]} : {r2[2]}): ceiling {pair(*c2)}, wall {pair(*w2)}, cone value {cone(r2)}")
t1, t2 = (0, 1, -1), (0, 1, 1)                    # y - z = 0 and y + z = 0
meet = cross(t1, t2)
print(f"ceiling tangents y = 1 and y = -1 are the triples {t1}, {t2}; they meet at {meet} = (1 : 0 : 0)")
print(f"in the wall chart (1 : 0 : 0) is (y, z) = {pair(Q(meet[1], meet[0]), Q(meet[2], meet[0]))}, "
      f"the hyperbola's centre")
far = (1000001.0 ** 0.5) - 1000.0
print(f"wall hyperbola at y = 1000 m: z - y = {far:.12f}, closing on the asymptote z = y")
print("ceiling points (0, 1), (0, -1) are (0 : 1 : 1), (0 : -1 : 1): x = 0, the wall's line at infinity")
gi = lambda a, b: (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])   # complex product
for y in ((0, 1), (0, -1)):
    s = tuple(p + q for p, q in zip(gi((1, 0), (1, 0)), gi(y, y)))
    print(f"over C, horizontal line (1 : {'i' if y[1] == 1 else '-i'} : 0): x^2 + y^2 = {s[0]} + {s[1]}i")
    assert s == (0, 0)

def tuples(m, p):
    out = [()]
    for _ in range(m):
        out = [t + (c,) for t in out for c in range(p)]
    return out

def norm(v, p):                                   # scale so the first nonzero entry is 1
    i = next(k for k, c in enumerate(v) if c % p)
    inv = pow(v[i], p - 2, p)
    return tuple(c * inv % p for c in v)

primes = (2, 3, 5, 7)
print(f"P^n(F_p) for p = {', '.join(map(str, primes))}: canonical forms / nonzero lists over p - 1 / 1 + p + ... + p^n")
for n in (1, 2, 3):
    brute, orbit, strata, chart_ok = [], [], [], True
    for p in primes:
        nz = [v for v in tuples(n + 1, p) if any(v)]
        pts = {norm(v, p) for v in nz}
        brute.append(len(pts))
        assert len(nz) % (p - 1) == 0
        orbit.append(len(nz) // (p - 1))
        strata.append(sum(p ** k for k in range(n + 1)))
        chart_ok &= all(sum(1 for q in pts if q[i]) == p ** n for i in range(n + 1))
    print(f"n = {n}: {brute} {orbit} {strata}; each of the {n + 1} charts holds p^{n} points: {yn(chart_ok)}")
    assert brute == orbit == strata and chart_ok

seen, miss = {}, {}
for p in (5, 7, 11, 13):
    pts = sorted({norm(v, p) for v in tuples(3, p) if any(v) and cone(v) % p == 0})
    par = {norm(((1 - m * m) % p, 2 * m % p, (1 + m * m) % p), p) for m in range(p)} | {norm((p - 1, 0, 1), p)}
    ceil_n = sum(1 for q in pts if q[2]); inf_n = len(pts) - ceil_n
    wall_n = sum(1 for q in pts if q[0])
    chi = 1 if pow(p - 1, (p - 1) // 2, p) == 1 else -1   # Euler: is -1 a square mod p?
    print(f"cone over F_{p}: {len(pts)} points; ceiling chart {ceil_n}, at the ceiling's infinity {inf_n}, "
          f"wall chart {wall_n}; by (1 - m^2 : 2m : 1 + m^2): {len(par)}, same set: {yn(par == set(pts))}")
    assert par == set(pts) and len(pts) == p + 1 and ceil_n == p - chi and wall_n == p - 1
    seen[p], miss[p] = len(pts), (len(pts) - wall_n, len(pts) - ceil_n)
    if p == 5:
        print(f"  over F_5 at infinity: {[q for q in pts if q[2] == 0]}; m = 2 gives {norm((1 - 4, 4, 5), 5)}")

all7 = tuples(3, 7)
nz7 = [v for v in all7 if any(v)]
print(f"mistake 1, scaled copies counted as points: F_7 has {len(nz7)} nonzero triples; P^2(F_7) has "
      f"{len({norm(v, 7) for v in nz7})} points")
print(f"mistake 2, (0, 0, 0) kept: {len(all7)} triples / 6 scalings = {Q(len(all7), 6)}, not a whole number")
bad = lambda v: v[0] * v[0] + v[1] * v[1] - v[2]
print(f"mistake 3, x^2 + y^2 - z is not homogeneous: (1, 0, 1) gives {bad((1, 0, 1))}, (2, 0, 2) gives {bad((2, 0, 2))}")
print(f"mistake 4, one chart only: the wall chart misses {miss[7][0]} of the {seen[7]} points over F_7; "
      f"the ceiling chart, {miss[5][1]} of {seen[5]} over F_5")
k = 80                                            # figure: 80 units per metre
fx = lambda cx, a, b: f"({float(cx + k * a):.2f}, {float(160 - k * b):.2f})"
print(f"figure, {k} units per metre: ceiling point {fx(160, *ceil)}, tangent points {fx(160, 0, 1)} {fx(160, 0, -1)}; wall point {fx(480, *wall)}, "
      f"vertices {fx(480, 0, 1)} {fx(480, 0, -1)}, asymptote z = y ends {fx(480, -1.8, -1.8)} {fx(480, 1.8, 1.8)}, "
      f"asymptote z = -y ends {fx(480, -1.8, 1.8)} {fx(480, 1.8, -1.8)}")

assert to_wall(*ceil) == wall and to_ceil(*wall) == ceil and to_wall(*c2) == w2   # transition = direct
assert dot(meet, t1) == 0 and dot(meet, t2) == 0 and meet[2] == 0 and meet[0] != 0
assert 0 < far < 0.0006 and cone(r) == 0 and cone(r2) == 0
print("ALL CHECKS PASS")
