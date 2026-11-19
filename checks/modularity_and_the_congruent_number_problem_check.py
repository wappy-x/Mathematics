# Congruent numbers and modularity -- the check behind the card.  Standard library only.
# Exact fractions for every triangle and point; point counts mod p by listing every x;
# floats only for the L-function sums, checked to a stated tolerance.
from fractions import Fraction as Fr
from math import exp, log, pi, sqrt, isqrt, gcd

def fs(q): return str(q.numerator) if q.denominator == 1 else f"{q.numerator}/{q.denominator}"
def pt(P): return f"({fs(P[0])}, {fs(P[1])})"
def on_curve(n, P): return P[1] * P[1] == P[0] ** 3 - n * n * P[0]
def tri_to_pt(n, a, b, c): return (n * (a + c) / b, 2 * n * n * (a + c) / (b * b))
def pt_to_tri(n, P):
    x, y = P
    return ((x * x - n * n) / y, 2 * n * x / y, (x * x + n * n) / y)
def double(n, P):                      # the tangent line at P meets the curve again at -2P
    x, y = P; m = (3 * x * x - n * n) / (2 * y); x3 = m * m - 2 * x
    return (x3, m * (x - x3) - y)
def qsqrt(q):                          # exact square root of a positive rational square
    r, s = isqrt(q.numerator), isqrt(q.denominator)
    return Fr(r, s) if r * r == q.numerator and s * s == q.denominator else None
def count(n, p):                       # points on y^2 = x^3 - n^2 x over F_p, plus O
    ways = [0] * p
    for y in range(p): ways[y * y % p] += 1
    return 1 + sum(ways[(x ** 3 - n * n * x) % p] for x in range(p))
def tunnell(n, k):                     # whole-number solutions of 2x^2 + y^2 + k z^2 = n
    R = isqrt(n) + 1
    return sum(1 for x in range(-R, R + 1) for y in range(-R, R + 1) for z in range(-R, R + 1)
               if 2 * x * x + y * y + k * z * z == n)

n = 7
a, b, c = Fr(24, 5), Fr(35, 12), Fr(337, 60)
print(f"n = 7: triangle a = {fs(a)}, b = {fs(b)}, c = {fs(c)}")
print(f"area ab/2 = {fs(a * b / 2)}; a^2 + b^2 = {fs(a * a + b * b)}; c^2 = {fs(c * c)}")
assert a * b / 2 == n and a * a + b * b == c * c
Q = tri_to_pt(n, a, b, c)
print(f"road 1, triangle to point: Q = {pt(Q)}")
print(f"  y^2 = {fs(Q[1] ** 2)}; x^3 - 49x = {fs(Q[0] ** 3 - n * n * Q[0])}")
print(f"  by hand: a + c = {fs(a + c)}; 25^3 = {25 ** 3}, 49 * 25 = {49 * 25}; x^2 - 49 = {fs(Q[0] ** 2 - 49)}, 2nx = {fs(2 * n * Q[0])}, x^2 + 49 = {fs(Q[0] ** 2 + 49)}")
back = pt_to_tri(n, Q)
print(f"  point back to triangle: {', '.join(map(fs, back))}")
assert on_curve(n, Q) and back == (a, b, c)
x2 = (c / 2) ** 2
sq = [qsqrt(x2 - n), qsqrt(x2), qsqrt(x2 + n)]
print(f"road 2, three squares 7 apart: {', '.join(fs(x2 + d) for d in (-n, 0, n))}")
print(f"  = ({fs(sq[0])})^2, ({fs(sq[1])})^2, ({fs(sq[2])})^2")
assert None not in sq and sq[0] == (a - b) / 2 and sq[2] == (a + b) / 2
P2 = double(n, Q)
print(f"  tangent at Q: 2Q = {pt(P2)}")
print(f"  x(2Q) = (c/2)^2: {fs(P2[0])} = {fs(x2)}")
assert P2[0] == x2 and on_curve(n, P2)
r = (sq[2] + sq[0], sq[2] - sq[0], 2 * sq[1])
print(f"  square roots back: {', '.join(map(fs, r))}")
assert r == (a, b, c)
t2 = [abs(v) for v in pt_to_tri(n, P2)]
print(f"new triangle from 2Q: {', '.join(map(fs, t2))}")
print(f"  area {fs(t2[0] * t2[1] / 2)}, a^2 + b^2 = c^2: {t2[0] ** 2 + t2[1] ** 2 == t2[2] ** 2}")
assert t2[0] * t2[1] / 2 == n and t2[0] ** 2 + t2[1] ** 2 == t2[2] ** 2 and t2[2] != c
five = tri_to_pt(5, Fr(3, 2), Fr(20, 3), Fr(41, 6))
print(f"n = 5: triangle 3/2, 20/3, 41/6 gives {pt(five)} on y^2 = x^3 - 25x: {on_curve(5, five)}")
assert on_curve(5, five)
ps = [3, 11, 19, 23, 31]
cnt = [count(n, p) for p in ps]
g = 0
for k in cnt: g = gcd(g, k)
print(f"torsion: #E(F_p) for p = 3, 11, 19, 23, 31: {cnt}; gcd {g}")
print(f"  y = 0 points (0, 0), (7, 0), (-7, 0) on curve: {all(on_curve(n, (Fr(x), Fr(0))) for x in (0, 7, -7))}")
assert cnt == [p + 1 for p in ps] and g == 4
print("Tunnell counts A (k = 32), B (k = 8); congruent forces 2A = B")
for m in (1, 3, 5, 7, 11):
    A, B = tunnell(m, 32), tunnell(m, 8)
    print(f"  n = {m}: A = {A}, B = {B}, 2A = B: {2 * A == B}")
    assert (2 * A == B) == (m in (5, 7))
bad = 25 ** 3 - n * 25
print(f"breaks: y^2 = x^3 - 7x at x = 25 gives {bad}, a square: {isqrt(bad) ** 2 == bad}")
xr, yr = (1 + sqrt(5)) / 2, 2 * (1 + sqrt(5)) / 4
print(f"breaks: legs 1, 2, hypotenuse sqrt 5, area 1: x = {xr:.10f}, y = {yr:.10f}, off curve by {abs(yr * yr - xr ** 3 + xr):.10f}")
assert isqrt(bad) ** 2 != bad and abs(yr * yr - xr ** 3 + xr) < 1e-12

def coeffs(n, M):                      # a_m for m <= M, from point counts mod p
    a = [0] * (M + 1); a[1] = 1
    for m in range(2, M + 1):
        p = next(q for q in range(2, m + 1) if m % q == 0)
        r = m
        while r % p == 0: r //= p
        if r > 1: a[m] = a[r] * a[m // r]; continue
        bad = (2 * n) % p == 0         # p = 2 and p | n: additive, a_p = 0
        ap = 0 if bad else (p + 1 - count(n, p) if m == p else a[p])
        a[m] = ap if m == p else ap * a[m // p] - (0 if bad else p) * a[m // p // p]
    return a
def E1(x):                             # exponential integral, series or continued fraction
    if x < 1:
        s, term = 0.0, 1.0
        for k in range(1, 40):
            term *= -x / k; s += term / k
        return -0.5772156649015329 - log(x) - s
    f = 0.0
    for k in range(60, 0, -1): f = k * k / (x + 2 * k + 1 - f)
    return exp(-x) / (x + 1 - f)
def gsum(a, N, t):
    s = 0.0
    for m in range(1, len(a)): s += a[m] * exp(-2 * pi * m * t / sqrt(N))
    return s
def L1(a, N, w, A):
    s, k = 0.0, 2 * pi / sqrt(N)
    for m in range(1, len(a)): s += a[m] / m * (exp(-k * m * A) + w * exp(-k * m / A))
    return s
def dL1(a, N, A):                      # L'(E, 1) when the sign w is -1
    s, k = 0.0, 2 * pi / sqrt(N)
    for m in range(1, len(a)):
        s += a[m] / m * (exp(-k * m * A) * log(A) + E1(k * m * A) - exp(-k * m / A) * log(A) + E1(k * m / A))
    return s

a7 = coeffs(7, 400)
print("a_p for y^2 = x^3 - 49x, p = 3, 5, 11, 13, 17, 19, 23, 29:", [a7[p] for p in (3, 5, 11, 13, 17, 19, 23, 29)])
assert all(a7[p] == 0 for p in (3, 11, 19, 23)) and all(a7[p] ** 2 <= 4 * p for p in (5, 13, 17, 29))
for m, N in ((1, 32), (7, 1568)):
    am = a7 if m == 7 else coeffs(1, 400)
    w = gsum(am, N, 0.8) / (1.25 ** 2 * gsum(am, N, 1.25))
    print(f"n = {m}, N = {N}: g(0.8) = {gsum(am, N, 0.8):.10f}, 1.25^2 g(1.25) = {1.25 ** 2 * gsum(am, N, 1.25):.10f}, sign w = {w:.10f}")
    assert abs(w - (-1 if m % 8 in (5, 6, 7) else 1)) < 1e-9
    wi = round(w)
    print(f"  L(E, 1) split at 1: {abs(L1(am, N, wi, 1.0)):.10f}; split at 1.25: {abs(L1(am, N, wi, 1.25)):.10f}")
    assert abs(L1(am, N, wi, 1.0) - L1(am, N, wi, 1.25)) < 1e-9
d1, d2 = dL1(a7, 1568, 1.0), dL1(a7, 1568, 1.25)
print(f"n = 7: L'(E, 1) split at 1: {d1:.10f}; split at 1.25: {d2:.10f}")
assert abs(d1 - d2) < 1e-9 and d1 > 0.1
print("ALL CHECKS PASS")
