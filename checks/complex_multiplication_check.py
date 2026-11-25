# Complex multiplication -- the check behind the card.  Standard library only.
# The curve E is y^2 = x^3 - x.  A point mod p is a pair (x, y); None is O.
# Road 1 counts the points mod p: square every y, then look up each x.
# Road 2 adds up Euler's square test over x, one question per x.
# Road 3 reads a_p from p = a^2 + b^2 alone, with no counting.
# Road 4 tests the Frobenius claim: the Gaussian integer a + b[i] fixes every
# point mod p, and no b + a[i] does.  The map [i](x, y) = (-x, iy) is tested as a map of the group.
# Lattice j-values come from q-series in floats, by two separate series.
from fractions import Fraction as Fr
import math

def add(P, Q, p):  # chord and tangent on y^2 = x^3 - x, mod p
    if P is None: return Q
    if Q is None: return P
    (x1, y1), (x2, y2) = P, Q
    if x1 == x2 and (y1 + y2) % p == 0: return None
    if P == Q: m = (3 * x1 * x1 - 1) * pow(2 * y1, p - 2, p) % p
    else: m = (y2 - y1) * pow(x2 - x1, p - 2, p) % p
    x3 = (m * m - x1 - x2) % p
    return (x3, (m * (x1 - x3) - y1) % p)

def mul(n, P, p):  # n times P by repeated adding; a negative n flips P first
    if n < 0: n, P = -n, (None if P is None else (P[0], -P[1] % p))
    R = None
    for _ in range(n): R = add(R, P, p)
    return R

def imap(i, P, p):  # [i](x, y) = (-x, iy), with i a square root of -1 mod p
    return None if P is None else (-P[0] % p, i * P[1] % p)

def points(p, A=-1, B=0):  # road 1: O, then for each x every y with y^2 = f(x)
    roots = {}
    for y in range(p): roots.setdefault(y * y % p, []).append(y)
    return [None] + [(x, y) for x in range(p) for y in roots.get((x**3 + A * x + B) % p, [])]

def legendre(v, p):
    t = pow(v % p, (p - 1) // 2, p)
    return -1 if t == p - 1 else t

def ap_euler(p, A=-1, B=0):  # road 2: a_p is minus the sum of the square test
    return -sum(legendre(x**3 + A * x + B, p) for x in range(p))

def two_squares(p):  # p = a^2 + b^2, a odd, b even, sign of a so a + b = 1 mod 4
    for b in range(0, math.isqrt(p) + 1, 2):
        a = math.isqrt(p - b * b)
        if a * a == p - b * b: return (a if (a + b) % 4 == 1 else -a), b

def ap_cm(p):  # road 3
    return 0 if p % 4 == 3 else 2 * two_squares(p)[0]

def sqrt_m1(p): return next(t for t in range(p) if t * t % p == p - 1)

primes = [p for p in range(3, 1000) if all(p % d for d in range(2, math.isqrt(p) + 1))]
print("E: y^2 = x^3 - x, Delta =", -16 * (4 * (-1)**3 + 27 * 0**2), " [i](x, y) = (-x, iy): (iy)^2 = -y^2 = -(x^3 - x) = (-x)^3 - (-x)")
for p in [7, 11, 13, 17, 29]:
    n = len(points(p))
    if p % 4 == 3: print(f"p = {p}, 3 mod 4: {n} points, a_{p} = {p + 1 - n}")
    else:
        a, b = two_squares(p)
        print(f"p = {p} = {abs(a)}^2 + {b}^2, a = {a}, a + b = {a + b} = {(a + b) % 4} mod 4: "
              f"{n} points, a_{p} = {p + 1 - n} = 2a")
print("p = 7, square test of x^3 - x for x = 1..6:", [legendre(x**3 - x, 7) for x in range(1, 7)])
for p in primes:  # roads 1, 2 and 3 agree at every odd prime below 1000
    n = len(points(p))
    assert n == p + 1 - ap_euler(p) and ap_euler(p) == ap_cm(p)
    assert p % 4 == 3 or n % 8 == 0
print(f"roads 1, 2, 3 agree at all {len(primes)} odd primes below 1000; "
      f"8 divides the count at all {sum(p % 4 == 1 for p in primes)} primes = 1 mod 4")
print("chart, p:", primes[:18])
print("chart, a_p:", [ap_cm(p) for p in primes[:18]])
pt = lambda P: "O" if P is None else str(P)
p, i = 13, sqrt_m1(13); E = points(13)
print(f"figure, E mod 13 (i = {i}):", " ".join(str(P) for P in E[1:]))
orbit = [(5, 4)]
while len(orbit) < 4: orbit.append(imap(i, orbit[-1], p))
print("figure, [i] cycle:", " -> ".join(map(str, orbit)), "->", imap(i, orbit[-1], p))
neg = lambda P: None if P is None else (P[0], -P[1] % p)
assert all(imap(i, P, p) in E and imap(i, imap(i, P, p), p) == neg(P) for P in E)
assert all(imap(i, add(P, Q, p), p) == add(imap(i, P, p), imap(i, Q, p), p) for P in E for Q in E)
assert all(add(R, neg(imap(i, R, p)), p) == mul(2, P, p) for P in E for R in [add(P, imap(i, P, p), p)])
ker = [P for P in E if add(P, imap(i, P, p), p) is None]
print(f"mod 13: [i] keeps the curve, [i][i] = [-1], [i](P + Q) = [i]P + [i]Q for all 64 pairs, "
      f"(1 - [i])(1 + [i]) = [2]; kernel of 1 + [i]: {", ".join(map(pt, ker))}")
Q = (i, (1 - i) % p)
print(f"order-4 point Q = (i, 1 - i) = {Q}: 2Q = {pt(mul(2, Q, p))}, 4Q = {pt(mul(4, Q, p))}")
assert Q in E and mul(2, Q, p) == (0, 0) and mul(4, Q, p) is None
p29, i29 = 29, sqrt_m1(29); E29 = points(29)
k5 = [sum(add(mul(2, P, p29), mul(s, imap(i29, P, p29), p29), p29) is None for P in E29) for s in (1, -1)]
print(f"mod 29 (i = {i29}, {len(E29)} points): kernel of 2 + [i] has {k5[0]}, of 2 - [i] has {k5[1]}")
assert sorted(k5) == [1, 5]
for p in [q for q in primes if q % 4 == 1 and q < 100]:  # road 4: Frobenius = a + b[i], never b + a[i]
    i, (a, b), E = sqrt_m1(p), two_squares(p), points(p)
    fix = [(s, t) for u, v in ((a, b), (b, a)) for s in (u, -u) for t in (v, -v)
           if all(add(mul(s, P, p), mul(t, imap(i, P, p), p), p) == P for P in E)]
    assert fix and all(s == a for s, t in fix) and len(fix) <= 2
    if p in (13, 29): print(f"Frobenius mod {p} (i = {i}): of the eight a + b[i] and b + a[i] with a, b = {abs(a)}, {b} up to sign, "
                            f"those fixing all {len(E)} points:", ", ".join(f"{s} + ({t})[i]" for s, t in fix))
print("house curve y^2 = x^3 - 2:", {p: ap_euler(p, 0, -2) for p in (5, 7, 11, 13)})
print("twist y^2 = x^3 - 49x:", {p: ap_euler(p, -49, 0) for p in (13, 17, 29)})
print("no CM, y^2 = x^3 - x + 1:", {p: ap_euler(p, -1, 1) for p in (7, 11, 13, 17)})
for p in (13, 17, 29): assert ap_euler(p, -49, 0) == legendre(7, p) * ap_cm(p)

curves = {"y^2 = x^3 - x": (-1, 0), "y^2 = x^3 - 30x + 56": (-30, 56), "y^2 = x^3 - 11x + 14": (-11, 14)}
for name, (A, B) in curves.items():
    j = Fr(1728 * 4 * A**3, 4 * A**3 + 27 * B**2); c = round(float(j) ** (1 / 3))
    assert j == c**3
    print(f"{name}: j = {j} = {c}^3")

def j_tau(t):  # tau = i t; road A: 1728 E4^3/(E4^3 - E6^2); road B: E4^3/Delta, Delta a product
    q = math.exp(-2 * math.pi * t); e4 = e6 = 1.0; dprod = q; qn = 1.0
    for n in range(1, 40):
        qn *= q
        e4 += 240 * sum(d * d * d for d in range(1, n + 1) if n % d == 0) * qn
        e6 -= 504 * sum(d * d * d * d * d for d in range(1, n + 1) if n % d == 0) * qn
        f = 1.0 - qn
        for _ in range(24): dprod *= f
    return 1728 * e4**3 / (e4**3 - e6 * e6), e4**3 / dprod

for label, t, want in [("i", 1.0, 1728), ("i sqrt2", math.sqrt(2), 8000), ("2i", 2.0, 287496), ("1.5i", 1.5, None)]:
    ja, jb = j_tau(t)
    assert abs(ja - jb) < 1e-6 * jb and (want is None or abs(jb - want) < 1e-6 * want)
    print(f"j({label}) = {jb:.4f}")
assert abs(j_tau(1.5)[1] - round(j_tau(1.5)[1])) > 0.01

def class_number(D):  # reduced primitive forms ax^2 + bxy + cy^2 with b^2 - 4ac = D
    h = 0
    for a in range(1, math.isqrt(-D // 3) + 1):
        for b in range(-a + 1, a + 1):
            if (b * b - D) % (4 * a): continue
            c = (b * b - D) // (4 * a)
            if c >= a and not (b < 0 and c == a) and math.gcd(math.gcd(a, b), c) == 1: h += 1
    return h

print("class numbers h(D):", {D: class_number(D) for D in (-4, -8, -16, -144)})
assert [class_number(D) for D in (-4, -8, -16, -144)] == [1, 1, 1, 4]

a, b = two_squares(13)  # the three wrong rules, read from 13 = a^2 + b^2
print(f"what breaks, p = 13: rule a_p = 0 gives {13 + 1} points; a = {-a} gives {13 + 1 + 2 * a}; "
      f"2b in place of 2a gives {13 + 1 - 2 * b}; the count is {len(points(13))}")
print("ALL CHECKS PASS")
