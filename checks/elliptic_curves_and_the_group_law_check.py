# The group law on y^2 = x^3 - 2 -- the check behind the card.  Standard library only; Fraction
# is exact arithmetic on fractions, nothing more.  The point at infinity O, doubling (3, 5) three
# ways, associativity where points coincide (formulas, a Cayley-Bacharach certificate, mod 11).
from fractions import Fraction as Fr
B, O = -2, None                                  # the curve y^2 = x^3 + B; None stands for O

def neg(p): return O if p is O else (p[0], -p[1])
def add(p, q):                                   # road one: chord or tangent, then reflect
    if p is O or q is O: return q if p is O else p
    if p[0] == q[0] and p[1] == -q[1]: return O      # a vertical line: its third point is O
    m = Fr(3 * p[0] ** 2, 2 * p[1]) if p == q else (q[1] - p[1]) / (q[0] - p[0])
    x = m * m - p[0] - q[0]
    return (x, m * (p[0] - x) - p[1])
def show(p): return "O" if p is O else f"({p[0]}, {p[1]})"
def line(p, q):                                  # the line through p and q (tangent if equal),
    if p[0] == q[0] and p != q: return {(1, 0): Fr(1), (0, 0): -p[0]}   # as {(i, j): coefficient
    m = Fr(3 * p[0] ** 2, 2 * p[1]) if p == q else (q[1] - p[1]) / (q[0] - p[0])  # of x^i y^j}
    return {(0, 1): Fr(1), (1, 0): -m, (0, 0): m * p[0] - p[1]}
def mul(f, g):
    h = {}
    for (a, b), u in f.items():
        for (c, d), v in g.items(): h[(a + c, b + d)] = h.get((a + c, b + d), 0) + u * v
    return h
def cubic(*ls): return mul(mul(ls[0], ls[1]), ls[2])

P = (Fr(3), Fr(5))
print(f"curve y^2 = x^3 - 2 over the rationals; P = {show(P)}: 5^2 = {5 ** 2} = 3^3 - 2 = {3 ** 3 + B}")
print(f"4a^3 + 27b^2 = {27 * B * B}, {'not zero: no cusp, no self-crossing' if 27 * B * B else 'zero: a cusp or a self-crossing'}")
# O in projective coordinates (X : Y : Z), curve Y^2 Z = X^3 - 2 Z^3, so x = X/Z and y = Y/Z
Fh = lambda X, Y, Z: Y * Y * Z - X ** 3 - B * Z ** 3
roots = [X for X in range(-9, 10) if Fh(X, 1, 0) == 0]
yn = lambda t: "yes" if t else "no"
vert = lambda X, Y, Z: X - 3 * Z                                     # the line x = 3, made projective
print(f"on the line at infinity Z = 0 the equation is -X^3 = 0: X = {roots}, so the one point there is (0 : 1 : 0)")
grad = lambda X, Y, Z: (-3 * X * X, 2 * Y * Z, Y * Y - 3 * B * Z * Z)  # rates of change in X, Y, Z
print(f"slopes of the equation at (0 : 1 : 0): {grad(0, 1, 0)}; not all zero, so O is a smooth point; tangent line Z = 0")
print(f"Z = 0 meets the curve where X^3 = 0: a triple root, so O is a flex; vertical x = 3 is X = 3Z, "
      f"through O: {yn(Fh(0, 1, 0) == 0 and vert(0, 1, 0) == 0)}")
# doubling P: road one is the formula; road two divides the line's cubic by (x - 3)^2
m = Fr(3 * 9, 2 * 5); k = 5 - m * 3; R = (m * m - 6, m * (m * m - 6) + k); D = add(P, P)
print(f"tangent at P: slope {m}, line y = {m} x - {-k}; x of third point = m^2 - 3 - 3 = {m * m} - 6 = {R[0]}")
cub = [Fr(1), -m * m, -2 * m * k, B - k * k]           # x^3 - (mx + k)^2 - 2, leading first
quo, r = [], cub[:]                                     # long division by x^2 - 6x + 9
for i in range(2):
    quo.append(r[i])
    for j, d in enumerate((1, -6, 9)): r[i + j] -= quo[i] * d
print(f"x^3 - (mx + k)^2 - 2 divided by (x - 3)^2: quotient x - {-quo[1]}, remainder {r[2]}x + {r[3]}")
print(f"third point R = {show(R)}, on curve: {yn(R[1] ** 2 == R[0] ** 3 + B)}; 2P = {show(D)}, "
      f"y^2 = {D[1] ** 2} = x^3 - 2 = {D[0] ** 3 + B}")
assert -quo[1] == R[0] == D[0] and r[2] == r[3] == 0 and D[1] ** 2 == D[0] ** 3 + B
print(f"three on a line: P + P + R = {show(add(add(P, P), R))}; 2P + (-2P) + O = {show(add(add(D, neg(D)), O))}; O + O + O = {show(add(O, add(O, O)))}")
for t in (0.1, 0.01, 0.001):                    # road three: chords to nearby points tend to 2P
    x2 = 3 + t; y2 = (x2 * x2 * x2 + B) ** 0.5; s = (y2 - 5) / t; x3 = s * s - 3 - x2
    print(f"chord to ({x2:.3f}, {y2:.6f}): slope {s:.6f}, sum ({x3:.6f}, {s * (3 - x3) - 5:.6f})")
assert abs(x3 - 1.29) < 0.01 and abs(s * (3 - x3) - 5 + 0.383) < 0.01
T3, T4 = add(D, P), add(D, D)
print(f"3P = {show(T3)}\n4P = {show(T4)}")
# associativity with Q = P and W = 2P: (P + P) + 2P against P + (P + 2P)
left, right = add(add(P, P), D), add(P, add(P, D))
print(f"(P + P) + 2P = 2P + 2P, a tangent; P + (P + 2P) = P + 3P, a chord; equal: {yn(left == right)}")
C1 = cubic(line(P, P), line(D, D), line(T3, neg(T3)))       # left grouping's two tangents, right's vertical
C2 = cubic(line(P, D), line(D, neg(D)), line(P, T3))        # right grouping's two chords, left's vertical
Fc = {(0, 2): Fr(1), (3, 0): Fr(-1), (0, 0): Fr(-B)}        # the curve itself: y^2 - x^3 + 2
lam = C2[(2, 1)] / C1[(2, 1)]
mu = (C2.get((3, 0), 0) - lam * C1.get((3, 0), 0)) / Fc[(3, 0)]
gap = [C2.get(e, 0) - lam * C1.get(e, 0) - mu * Fc.get(e, 0) for e in set(C1) | set(C2) | set(Fc)
       if C1.get(e, 0) or C2.get(e, 0) or Fc.get(e, 0)]
print(f"Cayley-Bacharach certificate: C2 = {lam} x C1 + {mu} x curve; "
      f"{len(gap)} coefficients compared, {sum(g != 0 for g in gap)} differ")
assert left == right == T4 and all(g == 0 for g in gap)
on = lambda pt: any(sum(c * pt[0] ** i * pt[1] ** j for (i, j), c in l.items()) == 0
                   for l in (line(P, D), line(D, neg(D)), line(P, T3)))   # a cubic of lines is 0
print(f"C2 passes through -((P + P) + 2P): {yn(on(neg(left)))}; "            # where one line is
      f"through (P + P) + 2P unreflected: {yn(on(left))}")
assert on(neg(left)) and not on(left)
# every triple mod 11, coincidences included
p = 11
def addp(a, b):
    if a is O or b is O: return b if a is O else a
    if a[0] == b[0] and (a[1] + b[1]) % p == 0: return O
    num, den = (3 * a[0] ** 2, 2 * a[1]) if a == b else (b[1] - a[1], b[0] - a[0])
    mm = num * pow(den, p - 2, p) % p; x = (mm * mm - a[0] - b[0]) % p
    return (x, (mm * (a[0] - x) - a[1]) % p)
pts = [O] + [(x, y) for x in range(p) for y in range(p) if (y * y - x ** 3 - B) % p == 0]
ngp, fail, coin = lambda u: O if u is O else (u[0], -u[1] % p), 0, 0
for a in pts:
    for b in pts:
        for c in pts:
            s, t = addp(a, b), addp(b, c); fail += addp(s, c) != addp(a, t)
            nine = (a, b, c, s, ngp(s), t, ngp(t), O, ngp(addp(s, c)))   # Step 4's nine points
            coin += len(set(nine)) < 9
print(f"mod {p}: {len(pts)} points, {len(pts) ** 3} triples, {len(pts) ** 3 - coin} with nine distinct points, "
      f"{coin} without; associativity failures {fail}")
assert len(pts) == 12 and fail == 0
# what breaks
print(f"mistake, R taken as the sum: third point of P and O is {show(neg(P))}, so O is not a zero")
print(f"mistake, chord formula at P = Q: slope ({P[1]} - {P[1]})/({P[0]} - {P[0]}) = {P[1] - P[1]}/{P[0] - P[0]}")
thirds = [Fr(y, x) ** 2 - x for x, y in ((1, 1), (4, 8))]      # sum of roots: m^2 - 0 - x
print(f"mistake, cusp y^2 = x^3: lines from (0, 0) to (1, 1) and (4, 8) meet again at x = {thirds[0]} and {thirds[1]}, "
      f"so (0, 0) + (1, 1) and (0, 0) + (4, 8) both give (0, 0): no cancelling")
print(f"mistake, O read as the origin: (0, 0) on the curve? 0^2 = 0, 0^3 - 2 = {B}: no")
# figure: 1 unit = 30, origin (40, 240); upper half of the curve, mirrored for the lower half
c = 2 ** (1 / 3); xs = [c + (51 ** (1 / 3) - c) * (i / 12) * (i / 12) for i in range(13)]
sv = lambda x, y: f"{40 + 30 * x:.1f},{240 - 30 * y:.1f}"
print("figure, 1 unit = 30, origin (40,240), curve:", " ".join(sv(x, max(0.0, x * x * x + B) ** 0.5) for x in xs))
print("figure, P", sv(3, 5), "R", sv(*map(float, R)), "2P", sv(*map(float, D)), "tangent", sv(1, float(m + k)), "to",
      sv(3.4, float(m * Fr(17, 5) + k)), "vertical", sv(float(R[0]), 7.6), "to", sv(float(R[0]), -7.6), "axes", sv(-1, 0), "to", sv(4.5, 0), "and", sv(0, 7.6), "to", sv(0, -7.6))
print("ALL CHECKS PASS")
