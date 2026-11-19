# Rational points on y^2 = x^3 - x: Mordell-Weil with torsion and rank, the check behind the card.
# Standard library only: Fraction is exact fractions, isqrt an exact whole-number square root.
from fractions import Fraction as F
from math import gcd, isqrt

def add(p, q, a):                    # chord-tangent rule on y^2 = x^3 + a x + b; None is O
    if p is None: return q
    if q is None: return p
    if p[0] == q[0] and p[1] == -q[1]: return None   # vertical line, tangents at y = 0 too
    m = (3 * p[0] ** 2 + a) / (2 * p[1]) if p == q else (q[1] - p[1]) / (q[0] - p[0])
    x = m * m - p[0] - q[0]
    return (x, m * (p[0] - x) - p[1])

def show(p): return "O" if p is None else f"({p[0]}, {p[1]})"
def whole(p): return p is None or (p[0].denominator == 1 and p[1].denominator == 1)

# Road 1: chord and tangent on the four obvious points
pts = [None, (F(-1), F(0)), (F(0), F(0)), (F(1), F(0))]
print("group table of y^2 = x^3 - x (row + column):")
for p in pts: print(f"  {show(p):>8} |", " ".join(f"{show(add(p, q, -1)):>8}" for q in pts))
def order(p, a):
    k, s = 1, p
    while s is not None and k <= 12: k, s = k + 1, add(s, p, a)
    return k
orders = [order(p, -1) for p in pts]
print("orders of O, (-1, 0), (0, 0), (1, 0):", orders, "-> no point of order 4, so Z/2 x Z/2")
assert add(pts[1], pts[2], -1) == pts[3]                      # the chord along y = 0, by hand
assert all(add(p, q, -1) in pts for p in pts for q in pts) and max(orders) == 2

# Road 2: Nagell-Lutz -- a torsion point has whole coordinates, and y = 0 or y^2 | 4a^3 + 27b^2
def nagell_lutz(a, b):
    D = abs(4 * a ** 3 + 27 * b ** 2)
    ys = [0] + [y for y in range(1, isqrt(D) + 1) if D % (y * y) == 0]
    cands = []
    for y in ys:
        c = b - y * y                                         # x^3 + a x + c = 0, whole roots
        for x in range(-1 - abs(a) - abs(c), 2 + abs(a) + abs(c)):
            if x ** 3 + a * x + c == 0: cands += [(F(x), F(y))] + ([(F(x), F(-y))] if y else [])
    return D, ys, cands
print("y = 2: x^3 - x at x = 1, -1, 2, -2, 4, -4:", ", ".join(str(x ** 3 - x) for x in (1, -1, 2, -2, 4, -4)), "(never 4)")
for a, b, name in ((-1, 0, "x^3 - x"), (-1, 1, "x^3 - x + 1")):
    D, ys, cands = nagell_lutz(a, b)
    print(f"y^2 = {name}: |4a^3 + 27b^2| = {D}; allowed y: {ys}; candidates: {len(cands)}")
    tors = [None]
    for p in cands:
        k, s = 1, p
        while s is not None and whole(s) and k <= 12: k, s = k + 1, add(s, p, a)
        if s is None: tors.append(p)
        print(f"  {show(p)}: " + (f"order {k}" if s is None else f"{k}P = {show(s)}, not whole: infinite order"))
    print(f"  torsion subgroup: {len(tors)} point(s)")
    if b == 0: tors0 = tors
assert tors0 == pts                                          # the search finds exactly the table

# Road 3: reduction mod good primes; torsion embeds in each E(GF(p)), so its size divides the gcd
def count_mod(p, a, b): return 1 + sum((y * y - x ** 3 - a * x - b) % p == 0 for x in range(p) for y in range(p))
for a, b, D, name in ((-1, 0, 4, "x^3 - x"), (-1, 1, 23, "x^3 - x + 1")):
    cs = [(p, count_mod(p, a, b)) for p in (3, 5, 7, 11, 13, 17, 19, 23, 29) if 2 * D % p]
    g = 0
    for _, c in cs: g = gcd(g, c)
    print(f"y^2 = {name}, points mod p: " + ", ".join(f"{p}:{c}" for p, c in cs) + f"; gcd {g}")
    if b == 0: g0 = g
assert g0 == len(tors0)                                       # 4 points, reached a second way

# Road 4: rank. Search the box H = max(|k|, e^2) <= 900 for x = k/e^2, y = h/e^3 on both curves
HB = 900                                                      # the search box
def search(a, b, H=HB):
    found = []
    for e in range(1, isqrt(H) + 1):
        for k in range(-H, H + 1):
            if gcd(k, e) != 1: continue
            r = k ** 3 + a * k * e ** 4 + b * e ** 6
            if r >= 0 and isqrt(r) ** 2 == r: found.append((F(k, e * e), F(isqrt(r), e ** 3)))
    return found
f0, f1 = search(-1, 0), search(-1, 1)
print(f"box H <= {HB}: y^2 = x^3 - x has {len(f0)} points with y >= 0: {', '.join(show(p) for p in f0)}")
print(f"box H <= {HB}: y^2 = x^3 - x + 1 has {len(f1)} points with y >= 0, e.g. {show(f1[-1])}")
assert [p for p in f0] == pts[1:]                             # nothing beyond the torsion
Q, mult = (F(1), F(1)), [None]
for k in range(6): mult.append(add(mult[-1], Q, -1))
print("multiples of Q = (1, 1) on y^2 = x^3 - x + 1:", ", ".join(show(p) for p in mult[1:]))
quart = [(X, Y) for X in range(2, 301) for Y in range(1, X) if isqrt(X ** 4 - Y ** 4) ** 2 == X ** 4 - Y ** 4]
print(f"X^4 - Y^4 = Z^2 with 0 < Y < X <= 300: {len(quart)} solutions (Fermat: none ever)")
assert quart == [] and not whole(mult[6])                     # rank 0 evidence; Q of infinite order
assert all(p[1] ** 2 == p[0] ** 3 - p[0] + 1 for p in mult[1:] + f1)   # every point on its curve

# What breaks: a cusp, a bad prime, a whole point that is not torsion
c = add((F(1), F(1)), (F(1, 4), F(1, 8)), 0)
ok = all(add((F(1, s * s), F(1, s ** 3)), (F(1, t * t), F(1, t ** 3)), 0) == (F(1, (s + t) ** 2), F(1, (s + t) ** 3))
         for s in range(1, 7) for t in range(1, 7))
print(f"cusp y^2 = x^3: (1, 1) + (1/4, 1/8) = {show(c)}; x/y adds as fractions on 36 pairs: {'yes' if ok else 'no'}")
print(f"bad prime 2: y^2 = x^3 - x mod 2 has {count_mod(2, -1, 0)} points; gcd with 4 is {gcd(4, count_mod(2, -1, 0))}")
assert c == (F(1, 9), F(1, 27)) and ok and count_mod(2, -1, 0) == 3
print("ALL CHECKS PASS")
