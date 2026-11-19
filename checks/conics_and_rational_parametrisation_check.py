# Conics and rational parametrisation -- the check behind the card.  Standard library
# only; Fraction keeps every step exact.  A conic a x^2 + b xy + c y^2 + d x + e y + f = 0
# is stored as (a, b, c, d, e, f).  Lines through one rational point P give every other one.
from fractions import Fraction as Q
from math import gcd, isqrt

def F(C, x, y): a, b, c, d, e, f = C; return a*x*x + b*x*y + c*y*y + d*x + e*y + f
def matrix(C):
    a, b, c, d, e, f = map(Q, C)
    return [[a, b / 2, d / 2], [b / 2, c, e / 2], [d / 2, e / 2, f]]
def det3(M):
    return (M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) - M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0])
            + M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0]))
def rank(M):                                   # Gaussian elimination: a second road to det M = 0
    R, r = [row[:] for row in M], 0
    for col in range(3):
        piv = next((i for i in range(r, 3) if R[i][col] != 0), None)
        if piv is None: continue
        R[r], R[piv] = R[piv], R[r]
        for i in range(3):
            if i != r and R[i][col] != 0:
                k = R[i][col] / R[r][col]; R[i] = [u - k * v for u, v in zip(R[i], R[r])]
        r += 1
    return r
def kind(C):
    M = matrix(C); D = det3(M); dA = M[0][0] * M[1][1] - M[0][1] ** 2
    if D == 0: return "degenerate: lines"
    if dA < 0: return "hyperbola"
    if dA == 0: return "parabola"
    return "ellipse" if M[0][0] * D < 0 else "ellipse, no real points"
def directions(C):                             # second road to the shape: real directions at infinity, from the
    a, b, c = C[:3]                            # signs of a x^2 + b xy + c y^2 at whole-number (x, y), -3 to 3
    v = {a*x*x + b*x*y + c*y*y for x in range(-3, 4) for y in range(-3, 4) if (x, y) != (0, 0)}
    return 2 if min(v) < 0 < max(v) else (1 if 0 in v else 0)
def at_centre(C):                              # F at the centre, where both partial derivatives vanish
    a, b, c, d, e, f = C; D = 4 * a * c - b * b
    return None if D == 0 else F(C, Q(b * e - 2 * c * d, D), Q(b * d - 2 * a * e, D))
def count(C, p):                               # projective points over F_p: nonzero solutions / (p - 1)
    a, b, c, d, e, f = C
    n = sum(1 for x in range(p) for y in range(p) for z in range(p) if (x, y, z) != (0, 0, 0)
            and (a*x*x + b*x*y + c*y*y + d*x*z + e*y*z + f*z*z) % p == 0)
    return n // (p - 1)
def coeffs(C, P, t):                           # F(x0 + s, y0 + t s) = A2 s^2 + A1 s, as F(P) = 0
    a, b, c, d, e, f = C; x0, y0 = P
    A2 = a + b * t + c * t * t
    A1 = 2 * a * x0 + b * (y0 + t * x0) + 2 * c * t * y0 + d + e * t
    return A2, A1
def second(C, P, t):                           # the line through P of slope t meets C once more
    A2, A1 = coeffs(C, P, t); s = -A1 / A2
    return (P[0] + s, P[1] + t * s)
def kernel(M):                                 # a nonzero v with M v = 0: cross product of two rows
    cr = lambda a, b: [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
    v = next(w for w in (cr(M[0], M[1]), cr(M[0], M[2]), cr(M[1], M[2])) if any(w))
    f = next(u for u in v if u != 0); return [u / f for u in v]
def pt(v): return "(" + ", ".join(str(u) for u in v) + ")"
def yn(c): return "yes" if c else "no"
def triple(v):                                 # clear denominators: (x, y) -> whole sides over c
    c = v[0].denominator * v[1].denominator // gcd(v[0].denominator, v[1].denominator)
    a, b = int(v[0] * c), int(v[1] * c); g = gcd(gcd(a, b), c)
    return tuple(sorted((a // g, b // g))) + (c // g,)

circle, eis, P = (1, 0, 1, 0, 0, -1), (1, 1, 1, 0, 0, -1), (Q(-1), Q(0))
print("unit circle x^2 + y^2 = 1, start point P = (-1, 0), line y = t(x + 1)")
A2, A1 = coeffs(circle, P, Q(1, 2)); print(f"  t = 1/2: A2 = {A2}, A1 = {A1}, step s = -A1/A2 = {-A1 / A2}")
for t in (Q(1, 2), Q(2, 3), Q(1, 4)):
    X = second(circle, P, t); closed = ((1 - t * t) / (1 + t * t), 2 * t / (1 + t * t))
    print(f"  t = {t}: second point {pt(X)}, on circle: {yn(F(circle, *X) == 0)}; closed form {pt(closed)};"
          f" back to t = y/(x + 1) = {X[1] / (X[0] + 1)}; triple {triple(X)}")
    assert X == closed and X[1] / (X[0] + 1) == t and F(circle, *X) == 0
by_slope = {triple(second(circle, P, Q(n, m))) for m in range(2, 31) for n in range(1, m)}
brute = {(a, b, c) for c in range(1, 101) for a in range(1, c) for b in range(a + 1, c)
         if a * a + b * b == c * c and gcd(gcd(a, b), c) == 1}
by_slope = {v for v in by_slope if v[2] <= 100}
print(f"primitive triples, long side <= 100: by slopes {len(by_slope)}, by brute force {len(brute)}, same: {yn(by_slope == brute)}")
print("  " + " ".join(f"{a}-{b}-{c}" for a, b, c in sorted(brute, key=lambda v: (v[2], v[0]))))
print("120-degree conic x^2 + xy + y^2 = 1 (a^2 + ab + b^2 = c^2), same start P = (-1, 0)")
for t in (Q(1, 2), Q(1, 3), Q(2, 3)):
    X = second(eis, P, t); a, b, c = triple(X)
    print(f"  t = {t}: {pt(X)}, on conic: {yn(F(eis, *X) == 0)}; sides {a}, {b}, {c}: {a*a} + {a*b} + {b*b} = {c*c}")
    assert F(eis, *X) == 0 and a * a + a * b + b * b == c * c
eis_slope = {v for v in (triple(second(eis, P, Q(n, m))) for m in range(2, 31) for n in range(1, m)) if v[2] <= 50}
eis_brute = {(a, b, c) for c in range(1, 51) for a in range(1, c) for b in range(a, c)
             if a * a + a * b + b * b == c * c and gcd(gcd(a, b), c) == 1}
print(f"primitive 120-degree triangles, long side <= 50: by slopes {len(eis_slope)}, by brute force {len(eis_brute)}, same: {yn(eis_slope == eis_brute)}")
print("  " + " ".join(f"{a}-{b}-{c}" for a, b, c in sorted(eis_brute, key=lambda v: (v[2], v[0]))))
assert by_slope == brute and len(brute) == 16 and eis_slope == eis_brute and len(eis_brute) == 7

table = [("x^2 + y^2 - 1", circle), ("x^2 + xy + y^2 - 1", eis), ("xy - 1", (0, 1, 0, 0, 0, -1)),
         ("x^2 - y", (1, 0, 0, 0, -1, 0)), ("x^2 + y^2 + 1", (1, 0, 1, 0, 0, 1)),
         ("x^2 + y^2 - 3", (1, 0, 1, 0, 0, -3)), ("x^2 + xy + y^2 + x + y + 1", (1, 1, 1, 1, 1, 1)),
         ("x^2 - y^2", (1, 0, -1, 0, 0, 0)), ("x^2 + 2xy + y^2 - 1", (1, 2, 1, 0, 0, -1))]
print(f"{'conic':<28}{'det M':>7}{'det A':>7}{'rank':>6}  {'type':<25}{'points over F_7':>15}{'at infinity':>13}{'F at centre':>13}")
for name, C in table:
    M = matrix(C); D = det3(M); dA = M[0][0] * M[1][1] - M[0][1] ** 2; n7 = count(C, 7)
    n, Fc = directions(C), at_centre(C)
    print(f"{name:<28}{str(D):>7}{str(dA):>7}{rank(M):>6}  {kind(C):<25}{n7:>15}{n:>13}{'-' if Fc is None else str(Fc):>13}")
    assert (D != 0) == (rank(M) == 3) and (n7 == 8 if D != 0 else n7 == 15)
    assert Fc is None or Fc * dA == D           # Step 5: F at the centre is det M / det A
    assert D == 0 or kind(C) == ("hyperbola" if n == 2 else "parabola" if n == 1
                                 else "ellipse" if C[0] * Fc < 0 else "ellipse, no real points")
inv = lambda v: pow(v % 7, 5, 7)               # 1/v mod 7, since v^6 = 1 mod 7
by7 = [((1 - t * t) * inv(1 + t * t) % 7, 2 * t * inv(1 + t * t) % 7) for t in range(7)]
on7 = {(x, y) for x in range(7) for y in range(7) if (x * x + y * y - 1) % 7 == 0}
print("circle over F_7 from P = (6, 0), slopes 0 to 6: " + " ".join(pt(v) for v in by7) +
      f"; with P: {len(set(by7) | {(6, 0)})} points, all of x^2 + y^2 = 1 mod 7: {yn(set(by7) | {(6, 0)} == on7)}")
assert len(set(by7)) == 7 and set(by7) | {(6, 0)} == on7 and len(on7) == count(circle, 7)
sols = [(x, y, z) for z in range(1, 61) for x in range(0, 2 * z) for y in range(x, 2 * z) if x*x + y*y == 3*z*z]
print(f"x^2 + y^2 = 3: whole-number solutions of x^2 + y^2 = 3z^2 with 1 <= z <= 60: {len(sols)};"
      f" squares mod 3: {sorted({k * k % 3 for k in range(3)})}")
assert sols == []
X = 1 / (1 + Q(1, 4))                         # line y = x/2 through (0, 0), not on the circle
print(f"mistake, start off the curve at (0, 0), slope 1/2: x^2 = {X}, a rational square: "
      f"{yn(isqrt(X.numerator) ** 2 == X.numerator and isqrt(X.denominator) ** 2 == X.denominator)}")
for t in (Q(1, 2), Q(3)):
    Y = second((1, 0, -1, 0, 0, 0), (Q(1), Q(1)), t)
    print(f"mistake, two lines x^2 - y^2 = 0 from (1, 1), slope {t}: {pt(Y)}, on y = -x: {yn(Y[1] == -Y[0])}")
    assert Y[1] == -Y[0]
M = matrix(table[7][1])
print(f"mistake, x^2 - y^2 read by det A alone: det A = {M[0][0] * M[1][1] - M[0][1] ** 2} says hyperbola;"
      f" det M = {det3(M)} says two lines y = x, y = -x")
M7 = matrix(table[8][1]); k6, k7 = kernel(M), kernel(M7)
print("kernel of M, the singular point: x^2 - y^2 ({} : {} : {}); x^2 + 2xy + y^2 - 1 ({} : {} : {})".format(*k6, *k7))
assert all(sum(X[r][j] * v[j] for j in range(3)) == 0 for v, X in ((k6, M), (k7, M7)) for r in range(3))
for t in (Q(2), Q(3)):                         # the house example: lines through the node
    x, y = t * t - 1, t * (t * t - 1)
    print(f"house example y^2 = x^2(x + 1), line of slope {t} through the node: ({x}, {y}); {y*y} = {x*x*(x+1)}")
    assert y * y == x * x * (x + 1)
print(f"try: circle, slope 1/3: {pt(second(circle, P, Q(1, 3)))}; xy = 1 from (1, 1), slope 4: "
      f"{pt(second((0, 1, 0, 0, 0, -1), (Q(1), Q(1)), Q(4)))}; points over F_11: circle {count(circle, 11)}, "
      f"x^2 - y^2 {count((1, 0, -1, 0, 0, 0), 11)}")
M = matrix((1, 2, 1, 0, 0, -1))                # x^2 + xy + y^2 - 1 with b = 1 put in unhalved
print(f"mistake, b not halved in x^2 + xy + y^2 - 1: det A = {M[0][0] * M[1][1] - M[0][1] ** 2}, which says parabola")
fx = lambda cx, v: f"({float(cx + 120 * v[0]):.2f}, {float(170 - 120 * v[1]):.2f})"
print("figure, 120 units per unit: circle P " + fx(160, P) + ", points " + " ".join(
    fx(160, second(circle, P, t)) for t in (Q(1, 2), Q(2, 3), Q(1, 4))) + ", on the y-axis " + " ".join(
    fx(160, (0, t)) for t in (Q(1, 2), Q(2, 3), Q(1, 4))) + "; 120-degree conic P " + fx(480, P)
    + ", point " + fx(480, second(eis, P, Q(1, 2))))
print("ALL CHECKS PASS")
