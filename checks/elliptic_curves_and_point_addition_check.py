# Elliptic curves -- the check behind the card.  Standard library only; Fraction is
# exact arithmetic on fractions, nothing more.  Curve y^2 = x^3 - x + 1.  Each sum by the
# slope formula and by scanning the line for its crossings; group laws on samples, then mod 7.
from fractions import Fraction as F
A, B, O = -1, 1, None                          # coefficients a, b; O, the point at infinity

def red(v, n): return v % n if n else v        # n = 0: fractions; n = 7: remainders mod 7
def div(u, v, n): return F(u, v) if n == 0 else u * next(t for t in range(n) if v * t % n == 1)
def on(p, n=0): return p is O or red(p[1] ** 2 - p[0] ** 3 - A * p[0] - B, n) == 0
def neg(p, n=0): return O if p is O else (p[0], red(-p[1], n))
def slope(p, q, n=0):                          # tangent if the points agree, else chord
    if p == q: return red(div(3 * p[0] ** 2 + A, 2 * p[1], n), n)
    return red(div(q[1] - p[1], q[0] - p[0], n), n)
def add(p, q, n=0):                            # road one: x3 = m^2 - x1 - x2, then reflect
    if p is O or q is O: return q if p is O else p
    if p[0] == q[0] and red(p[1] + q[1], n) == 0: return O   # vertical line
    m = slope(p, q, n); x3 = red(m * m - p[0] - q[0], n)
    return (x3, red(m * (p[0] - x3) - p[1], n))
def crossings(m, k):                           # road two: where y = mx + k meets the curve,
    g = lambda x: x ** 3 + A * x + B - (m * x + k) ** 2      # found by sign changes in steps
    roots = []                                 # of 0.01 from -5, then halving 60 times
    for i in range(1000):
        lo, hi = -5.0037 + i / 100, -4.9937 + i / 100
        if g(lo) * g(hi) < 0:
            for _ in range(60): lo, hi = (lo, (lo + hi) / 2) if g(lo) * g((lo + hi) / 2) <= 0 else ((lo + hi) / 2, hi)
            roots.append(lo)
    return roots
show = lambda p: "O" if p is O else f"({p[0]},{p[1]})"; yes = lambda t: "yes" if t else "no"

P, Q, mult = (F(0), F(1)), (F(1), F(1)), [O]
print(f"curve y^2 = x^3 - x + 1: 4a^3 + 27b^2 = {4 * A ** 3 + 27 * B ** 2}, not zero, so no cusp or crossing")
for name, p, q in (("P + Q", P, Q), ("Q + Q", Q, Q), ("P + P", P, P)):
    s, m = add(p, q), float(slope(p, q)); k = float(p[1]) - m * float(p[0])
    xs = crossings(m, k); x = [v for v in xs if min(abs(v - p[0]), abs(v - q[0])) > 1e-6][0]
    print(f"{name}: slope {slope(p, q)}, sum {show(s)}, y^2 {s[1] ** 2} = x^3 - x + 1 {s[0] ** 3 + A * s[0] + B}; crosses at "
          + ", ".join(f"{round(v, 4) + 0.0:.4f}" for v in xs) + f"; new one reflected ({x:.4f},{-(m * x + k):.4f})")
    assert abs(x - s[0]) < 1e-9 and abs(-(m * x + k) - s[1]) < 1e-9   # exact and scanned agree
for i in range(9): mult.append(add(mult[-1], Q))
for lo, hi in ((1, 6), (6, 10)): print("multiples:", ", ".join(f"{i}Q {show(mult[i])}" for i in range(lo, hi)))
print(f"6Q by six additions {show(mult[6])}; minus the tangent double of P {show(neg(add(P, P)))}")
assert mult[6] == neg(add(P, P))               # two routes through the group, one point
S = [O, P, Q, neg(Q), mult[2], (F(3), F(5))]
bad = sum(add(add(u, v), w) != add(u, add(v, w)) for u in S for v in S for w in S)
print(f"associativity on {len(S) ** 3} rational triples: {bad} failures (a sample, not a proof)")
m = F(3, 2); x3 = m * m - 2; wrong = (x3, m * (1 - x3) - 1)   # tangent slope at Q with a dropped
print(f"mistakes: (0+1,1+1) = (1,2) on curve {yes(on((F(1), F(2))))}; unreflected {show(neg(add(P, Q)))}; "
      f"tangent without a: slope {m}, {show(wrong)} on curve {yes(on(wrong))}")
pts = [O] + [(x, y) for x in range(7) for y in range(7) if on((x, y), 7)]
print("mod 7:", len(pts), "points:", " ".join(show(p) for p in pts))
bad7 = sum(add(add(u, v, 7), w, 7) != add(u, add(v, w, 7), 7) for u in pts for v in pts for w in pts)
laws = all(on(add(u, v, 7), 7) and add(u, v, 7) == add(v, u, 7) and add(u, neg(u, 7), 7) is O for u in pts for v in pts)
print(f"mod 7: {len(pts) ** 3} triples, {bad7} associativity failures; closed, commutative, inverses: {yes(laws)}")
assert bad == 0 and bad7 == 0 and laws         # grouping never mattered; small curve in full
r = crossings(0.0, 0.0)[0]; xs = [r + (1.75 - r) * (i / 20) ** 2 for i in range(21)]   # r: the curve meets the x-axis
print(f"figure, 1 unit = 50, origin (150,120), crossing x = {r:.4f}, upper half:",
      " ".join(f"{150 + 50 * x:.1f},{120 - 50 * max(0.0, x ** 3 + A * x + B) ** 0.5:.1f}" for x in xs))
sv = lambda x, y: f"({150 + 50 * x:.0f},{120 - 50 * y:.0f})"      # a point, in drawing units
print("figure, P, Q, R, P + Q at", *[sv(x, y) for x, y in ((0, 1), (1, 1), (-1, 1), (-1, -1))], "; chord", sv(-1.6, 1), "to",
      sv(1.9, 1), "; tangent", sv(-1.6, -1.6), "to", sv(1.7, 1.7), "; axes", sv(-1.8, 0), "to", sv(3, 0), "and", sv(0, 2.2), "to", sv(0, -2.2))
print("ALL CHECKS PASS")
