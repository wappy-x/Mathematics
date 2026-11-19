# Birch and Swinnerton-Dyer -- the check behind the card.  Standard library only.
# The curve E: y^2 = x^3 - 2 and its rational point P = (3, 5).  Both sides of the
# strong form are computed by roads that share no arithmetic: L'(E, 1) from point
# counts mod p; the period, height, Tamagawa numbers and torsion.  Ratio: #Sha.
from fractions import Fraction as Fr
import math

A, B, M = 0, -2, 400                         # y^2 = x^3 + Ax + B; terms in each L-series

yn = lambda claim: "yes" if claim else "no"

def primes(n): return [p for p in range(2, n + 1) if all(p % d for d in range(2, math.isqrt(p) + 1))]

def count(p, b):                             # points of y^2 = x^3 + b mod p, with O
    sq = [0] * p
    for y in range(p):
        sq[y * y % p] += 1
    return 1 + sum(sq[(x * x * x + b) % p] for x in range(p))

def count_brute(p, b):                       # second road: try every pair (x, y)
    return 1 + sum(1 for x in range(p) for y in range(p) if (y * y - x ** 3 - b) % p == 0)

def add(P, Q):                               # chord and tangent, exact fractions
    (x1, y1), (x2, y2) = P, Q
    m = (3 * x1 * x1 + A) / (2 * y1) if P == Q else (y2 - y1) / (x2 - x1)
    x3 = m * m - x1 - x2
    return (x3, m * (x1 - x3) - y1)

def e1(x):                                   # exponential integral E1, written out
    if x < 1:
        s, t = -0.5772156649015329 - math.log(x), 1.0
        for k in range(1, 60):
            t *= -x / k
            s -= t / k
        return s
    b, c, d, h = x + 1, 1e300, 1 / (x + 1), 1 / (x + 1)
    for i in range(1, 200):                  # continued fraction, Lentz's method
        b += 2
        d = 1 / (b - i * i * d)
        c = b - i * i / c
        h *= c * d
    return h * math.exp(-x)

def agm(a, b):                               # arithmetic-geometric mean
    while abs(a - b) > 1e-15 * a:
        a, b = (a + b) / 2, math.sqrt(a * b)
    return a

def series(cond, t, kind):                   # L(E,1) or L'(E,1) for a trial conductor and sign
    tot, r = 0.0, math.sqrt(cond)
    for n in range(1, M + 1):
        u, v = 2 * math.pi * n * t / r, 2 * math.pi * n / (t * r)
        f = e1(u) + e1(v) if kind == 0 else math.exp(-u) + kind * math.exp(-v)
        tot += an[n] / n * f
    return tot

disc = -16 * (4 * A ** 3 + 27 * B * B)
print(f"curve y^2 = x^3 - 2; discriminant -16(4A^3 + 27B^2) = {disc}; j = 0")
print(f"P = (3, 5) lies on it, 5^2 = 25 = 3^3 - 2: {yn(5 ** 2 == 3 ** 3 - 2)}")
P = (Fr(3), Fr(5))
mult = [P, add(P, P)]
mult += [add(mult[1], P), add(mult[1], mult[1])]
for n in (2, 3, 4):
    print(f"{n}P = ({mult[n - 1][0]}, {mult[n - 1][1]})")
nh = [math.log(max(abs(x.numerator), x.denominator)) / n ** 2 for n, (x, y) in enumerate(mult, 1)]
print("naive height of x(nP) over n^2, n = 1 to 4: " + ", ".join(f"{v:.4f}" for v in nh))
ps = list(cnt := {p: count(p, B) for p in primes(M)})
print("points mod p, two roads: " + ", ".join(f"p={p}: {cnt[p]} {count_brute(p, B)}" for p in (5, 7, 11, 13)))
print(f"Hasse window at p = 7: 8 +- {2 * math.sqrt(7):.2f}; holds for every p from 5 to {M}: "
      f"{yn(all(abs(p + 1 - cnt[p]) <= 2 * math.sqrt(p) for p in ps if p > 3))}")
print(f"torsion: gcd(#E(F_5), #E(F_7)) = gcd({cnt[5]}, {cnt[7]}) = {math.gcd(cnt[5], cnt[7])}")
fx = {}
for p in (2, 3):                             # Tate's algorithm, steps 1 to 3
    x0 = [x for x in range(p) for y in range(p) if (y * y - x ** 3 - B) % p == 0
          and (2 * y) % p == 0 and (3 * x * x) % p == 0][0]
    a2, a4, a6 = 3 * x0, 3 * x0 * x0, x0 ** 3 + B   # move the singular point to x = 0
    fx[p] = max(v for v in range(20) if disc % p ** v == 0)
    print(f"p = {p}: singular point at x = {x0}; shifted a2, a4, a6 = {a2}, {a4}, {a6}; "
          f"p divides all three: {yn(a2 % p == a4 % p == a6 % p == 0)}; p^2 divides a6: "
          f"{yn(a6 % (p * p) == 0)}; so type II, c_{p} = 1, f_{p} = v_{p}(disc) = {fx[p]}")
    assert a2 % p == a4 % p == a6 % p == 0 != a6 % (p * p)          # Tate's test for type II
NC = 2 ** fx[2] * 3 ** fx[3]
print(f"conductor N = 2^{fx[2]} * 3^{fx[3]} = {NC}")
ap = {p: 0 if p < 5 else p + 1 - cnt[p] for p in ps}
print("a_p for p up to 31: " + ", ".join(f"{p}:{ap[p]}" for p in ps if p <= 31))
an = [0, 1] + [0] * (M - 1)
for n in range(2, M + 1):                    # multiply a_n out of the a_p
    p = next(q for q in ps if n % q == 0)
    pk, m = p, n // p
    while m % p == 0:
        pk, m = pk * p, m // p
    if m > 1:
        an[n] = an[pk] * an[m]
    else:
        an[n] = ap[p] if pk == p else 0 if p < 5 else ap[p] * an[pk // p] - p * an[pk // p // p]
l0 = [series(NC, t, -1) for t in (1.2, 1.5)]
l1 = [series(NC, t, 0) for t in (1.0, 1.2, 1.5)]
print("size of L(E,1), sign -1, at t = 1.2 and 1.5: " + ", ".join(f"{abs(v):.12f}" for v in l0))
print("L'(E,1) at t = 1.0, 1.2, 1.5: " + ", ".join(f"{v:.12f}" for v in l1))
wrong = [series(NC, t, 1) for t in (1.0, 1.2)] + [series(NC // 2, t, 0) for t in (1.0, 1.2)]
print(f"wrong sign +1: L(E,1) at t = 1.0 and 1.2: {wrong[0]:.4f}, {wrong[1]:.4f}")
print(f"wrong conductor {NC // 2}: L'(E,1) at t = 1.0 and 1.2: {wrong[2]:.4f}, {wrong[3]:.4f}")
e = 2 ** (1 / 3)                             # the real root of x^3 - 2
z = math.sqrt(3 * e * e + A)
om = 2 * math.pi / agm(2 * math.sqrt(z), math.sqrt(2 * z + 3 * e))
def g(th):                                   # integrand after x = e + tan(th)^2
    u = e + math.tan(th) ** 2
    return 2 / math.cos(th) ** 2 / math.sqrt(u * u + e * u + e * e) if th < math.pi / 2 else 2.0
hs = math.pi / 4000                          # Simpson's rule, 2000 steps
om_q = hs / 3 * (g(0) + g(math.pi / 2) + sum((4 if i % 2 else 2) * g(i * hs) for i in range(1, 2000)))
print(f"real period Omega by the AGM: {om:.12f}; by Simpson's rule: {om_q:.12f}")
x, h, parts = 3.0, math.log(3.0), [math.log(3.0)]
for j in range(40):                          # Tate's series for the canonical height
    zz = 1 - 2 * A / x ** 2 - 8 * B / x ** 3 + A * A / x ** 4
    h += math.log(zz) / 4 ** (j + 1)
    parts.append(h)
    x = x ** 4 * zz / (4 * (x ** 3 + A * x + B))
print("canonical height, Tate's series after 0 to 5 terms: " + ", ".join(f"{v:.6f}" for v in parts[:6])
      + f"; limit {h:.12f}")
rhs = om * h * 1 * 1 / 1 ** 2
print(f"right side Omega * Reg * c_2 * c_3 / tors^2 = {om:.6f} * {h:.6f} * 1 * 1 / 1 = {rhs:.12f}")
print(f"#Sha = L'(E,1) / right side = {(sha := l1[0] / rhs):.12f}")
print(f"mistake 1, height halved to {h / 2:.4f}: #Sha comes out {l1[0] / (rhs / 2):.4f}")
print(f"mistake 2, naive height log 3 = {math.log(3):.4f}: #Sha comes out {l1[0] / (om * math.log(3)):.4f}")
marks, big = [10, 100, 200, 500, 1000, 2000, 5000, 10000, 20000], primes(20000)
last = [max(q for q in big if q <= m) for m in marks]    # the last prime under each mark
for b, name in ((-2, "rank 1, y^2 = x^3 - 2"), (1, "rank 0, y^2 = x^3 + 1")):
    pr, out = 1.0, []
    for p in big:
        pr *= count(p, b) / p if p > 3 else 1.0
        if p in last:
            out.append(pr)
    print(f"product of N_p/p up to {marks}, {name}: " + ", ".join(f"{v:.2f}" for v in out))
assert all(cnt[p] == count_brute(p, B) for p in (5, 7, 11, 13))          # two roads to N_p
assert math.gcd(cnt[5], cnt[7]) == 1 and NC == 1728                       # torsion; conductor
assert max(abs(v) for v in l0) < 1e-12 and max(l1) - min(l1) < 1e-12     # sign -1, N = 1728
assert abs(wrong[0] - wrong[1]) > 1e-3 and abs(wrong[2] - wrong[3]) > 1e-3
assert abs(om - om_q) < 1e-12 and abs(nh[3] - h) < 0.01                   # two roads each
assert abs(sha - 1) < 1e-10                                                # the strong form
print("ALL CHECKS PASS")
