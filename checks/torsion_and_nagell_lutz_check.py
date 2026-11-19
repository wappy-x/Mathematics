# Torsion on y^2 = x^3 - 2: Nagell-Lutz, division polynomials and Mazur's list, the check behind the card.
# Standard library only: Fraction is exact fractions, isqrt an exact whole-number square root.
from fractions import Fraction as F
from math import gcd, isqrt

def add(p, q, a):                     # chord-tangent rule on y^2 = x^3 + a x + b; None is O
    if p is None: return q
    if q is None: return p
    if p[0] == q[0] and p[1] == -q[1]: return None
    m = (3 * p[0] ** 2 + a) / (2 * p[1]) if p == q else (q[1] - p[1]) / (q[0] - p[0])
    x = m * m - p[0] - q[0]
    return (x, m * (p[0] - x) - p[1])
def whole(p): return p is None or (p[0].denominator == 1 and p[1].denominator == 1)
def order(p, a, stop=True):           # smallest n <= 13 with nP = O; 0 once a multiple is not whole
    k, s = 1, p                       # (Nagell-Lutz: then P has infinite order, for whole a and b)
    while s is not None and k <= 13 and (whole(s) or not stop): k, s = k + 1, add(s, p, a)
    return k if s is None else 0
def show(p): return "O" if p is None else f"({p[0]}, {p[1]})"
def curve(a, b): return "y^2 = x^3" + (f" {'+-'[a < 0]} {abs(a) if abs(a) > 1 else ''}x" if a else "") + (f" {'+-'[b < 0]} {abs(b)}" if b else "")
def divisors(n): return {d for k in range(1, isqrt(n) + 1) if n % k == 0 for d in (k, n // k)}
def is_prime(n): return n > 1 and all(n % d for d in range(2, isqrt(n) + 1))
def count_mod(p, a, b):               # points of y^2 = x^3 + a x + b mod p, O included (Euler's square test)
    s = 1
    for x in range(p):
        r = (x ** 3 + a * x + b) % p
        s += 1 if r == 0 else (2 if pow(r, (p - 1) // 2, p) == 1 else 0)
    return s
def gcd_counts(a, b, top):
    D, g = 4 * a ** 3 + 27 * b ** 2, 0
    for p in range(5, top):
        if is_prime(p) and D % p: g = gcd(g, count_mod(p, a, b))
    return g

A, B = 0, -2                          # the house curve y^2 = x^3 - 2
# Road 1: Nagell-Lutz -- a torsion point other than O has whole x, y, and y = 0 or y^2 divides 4a^3 + 27b^2
D = 4 * A ** 3 + 27 * B ** 2
ys = [0] + [y for y in range(1, isqrt(D) + 1) if D % (y * y) == 0]
cands = [(x, y) for y in ys for x in range(-50, 51) if x ** 3 + A * x + B == y * y]
print(f"Nagell-Lutz on {curve(A, B)}: 4a^3 + 27b^2 = {D}; allowed y: {ys}")
print(f"  y^2 - b = {', '.join(str(y * y - B) for y in ys)}; whole x with x^3 + ax = y^2 - b: {', '.join(f'({x}, {y})' for x, y in cands) or 'none'}; candidates: {len(cands)}")
assert cands == [] and ys == [0, 1, 2, 3, 6]
ident = all((3 * x * x + 4 * a) * (x ** 4 - 2 * a * x * x - 8 * b * x + a * a) - (3 * x ** 3 - 5 * a * x - 27 * b) * (x ** 3 + a * x + b)
            == 4 * a ** 3 + 27 * b ** 2 for x in range(8) for a in range(5) for b in range(4))
print(f"identity (3x^2 + 4a)(x^4 - 2ax^2 - 8bx + a^2) - (3x^3 - 5ax - 27b)(x^3 + ax + b) = 4a^3 + 27b^2 on an 8 x 5 x 4 grid: {ident}")
assert ident

# Road 2: division polynomials. g_n = psi_n for odd n; nP = O exactly when g_n(x) = 0 (n = 2: when y = 0)
def pmul(p, q):
    r = [0] * (len(p) + len(q) - 1)
    for i, s in enumerate(p):
        for j, t in enumerate(q): r[i + j] += s * t
    return r
def psub(p, q):
    r = [s - t for s, t in zip(p + [0] * len(q), q + [0] * len(p))]
    while r[-1] == 0: r.pop()
    return r
def divpolys(a, b):                   # coefficient lists, constant term first
    f2 = pmul([4 * b, 4 * a, 0, 4], [4 * b, 4 * a, 0, 4])          # (2y)^4 = (4x^3 + 4ax + 4b)^2
    g = {1: [1], 2: [1], 3: [-a * a, 12 * b, 6 * a, 0, 3], 4: [-16 * b * b - 2 * a ** 3, -8 * a * b, -10 * a * a, 40 * b, 10 * a, 0, 2]}
    g[5] = psub(pmul(f2, pmul(g[4], pmul(g[2], pmul(g[2], g[2])))), pmul(g[1], pmul(g[3], pmul(g[3], g[3]))))
    g[7] = psub(pmul(g[5], pmul(g[3], pmul(g[3], g[3]))), pmul(f2, pmul(g[2], pmul(g[4], pmul(g[4], g[4])))))
    return g
def rat_roots(c):                     # rational root test: a root u/v has u | constant term, v | leading term
    roots = []
    while c[0] == 0: roots, c = [F(0)], c[1:]
    cs = sorted({F(s * u, v) for u in divisors(abs(c[0])) for v in divisors(abs(c[-1])) for s in (1, -1)})
    return roots + [r for r in cs if sum(ci * r ** i for i, ci in enumerate(c)) == 0], len(cs)
g = divpolys(A, B)
r2, n2 = rat_roots([B, A, 0, 1])
print(f"order 2: y = 0 needs x^3 - 2 = 0; {n2} candidates, rational roots: {[str(r) for r in r2]}")
r3, n3 = rat_roots(g[3])
print(f"order 3: psi_3 = 3x^4 - 24x; {n3} candidates, rational roots: {[str(r) for r in r3]};"
      f" x^3 - 2 there: {', '.join(str(r ** 3 - 2) for r in r3)}, not squares")
roots = {}
for n in (5, 7):
    roots[n], k = rat_roots(g[n])
    print(f"order {n}: psi_{n} has degree {len(g[n]) - 1}, leading {g[n][-1]}, constant {g[n][0]}; {k} candidates, rational roots: {len(roots[n])}")
assert r2 == [] and r3 == [0, 2] and all(isqrt(int(r ** 3 - 2)) ** 2 != r ** 3 - 2 for r in r3 if r ** 3 > 2) and roots[5] == roots[7] == []
for n, a, b, x in ((3, 0, 4, 0), (5, -432, 8208, -12), (7, -43, 166, 3)):    # psi_n vanishes on known n-torsion
    assert sum(c * x ** i for i, c in enumerate(divpolys(a, b)[n])) == 0
print("psi_3, psi_5, psi_7 vanish at (0, 2), (-12, 108), (3, 8) on y^2 = x^3 + 4, x^3 - 432x + 8208, x^3 - 43x + 166: True")

# Road 3: torsion maps one-to-one into the points mod an odd good prime, so its size divides every count
cs = [(p, count_mod(p, A, B)) for p in range(5, 40) if is_prime(p)]
print("points mod p on y^2 = x^3 - 2: " + ", ".join(f"{p}:{c}" for p, c in cs) + f"; gcd {gcd_counts(A, B, 40)}")
assert gcd_counts(A, B, 40) == 1

# Road 4: the house point P = (3, 5) has infinite order
P = (F(3), F(5))
mult = [P, add(P, P, A), add(add(P, P, A), P, A)]
print(f"P = (3, 5): 5^2 = 25 does not divide 108; 2P = {show(mult[1])}; 3P = {show(mult[2])}")
assert all(q[1] ** 2 == q[0] ** 3 - 2 for q in mult) and mult[1][0].denominator == 100 and order(P, A) == 0

# Mazur's list: one curve y^2 = x^3 + a x + b for each of the fifteen groups, with generators P (and T)
mazur = [("Z/1", 0, -2, None, None), ("Z/2", -2, 0, (0, 0), None), ("Z/3", 0, 4, (0, 2), None), ("Z/4", 4, 0, (2, 4), None),
         ("Z/5", -432, 8208, (-12, 108), None), ("Z/6", 0, 1, (2, 3), None), ("Z/7", -43, 166, (3, 8), None),
         ("Z/8", 45333, -1978074, (87, 1620), None), ("Z/9", -219, 1654, (-13, 48), None), ("Z/10", -58347, 3954150, (-213, 2592), None),
         ("Z/12", -1947, 108214, (-37, 360), None), ("Z/2 x Z/2", -1, 0, (0, 0), (1, 0)), ("Z/2 x Z/4", -12987, -263466, (-57, 540), (-102, 0)),
         ("Z/2 x Z/6", -24003, 1296702, (-69, 1620), (-177, 0)), ("Z/2 x Z/8", -1386747, 368636886, (-933, 29160), (-1293, 0))]
print("Mazur's fifteen groups, one curve each (group size = gcd of counts mod good primes below 100):")
for name, a, b, p, t in mazur:
    gens = [(F(q[0]), F(q[1])) for q in (p, t) if q is not None]
    assert all(q[1] ** 2 == q[0] ** 3 + a * q[0] + b for q in gens)
    grp, frontier = {None}, [None]
    while frontier and len(grp) <= 16:           # 16 is the largest group on the list
        s = frontier.pop()
        for q in gens:
            u = add(s, q, a)
            if u not in grp: grp.add(u); frontier.append(u)
    orders = [order(q, a) for q in gens]
    size, g = len(grp), gcd_counts(a, b, 100)
    print(f"  {name:<9}: {curve(a, b)}; " + (", ".join(f"{show(q)} order {o}" for q, o in zip(gens, orders)) or "only O") + f"; {size} point(s); gcd {g}")
    assert size == g and all(q is None or q[0].denominator == 1 for q in grp)

# What breaks
h = (F(1, 2), F(3, 8))
print(f"fraction coefficients: (1/2, 3/8) on y^2 = x^3 + 1/64 has order {order(h, 0, False)}, yet is not whole")
x0 = F(2); x2 = (x0 ** 4 - 8 * B * x0) / (4 * (x0 ** 3 + B))
print(f"root 2 of psi_3 read as a point: y^2 = {x0 ** 3 + B}, not a square; over Q(sqrt 6) x(2P) = {x2}, so 3P = O there")
c8 = sorted({(x, s * y) for y in range(42) if y == 0 or 1728 % (y * y) == 0 for x in range(-9, 9) for s in (1, -1) if x ** 3 + 8 == y * y})
print("y^2 = x^3 + 8, 4a^3 + 27b^2 = 1728, candidates: " + ", ".join(f"({x}, {y}) order {order((F(x), F(y)), 0) or 'infinite'}" for x, y in c8))
print(f"bad prime 3: y^2 = x^3 + 1 mod 3 has {count_mod(3, 0, 1)} points; gcd with the true 6 is {gcd(6, count_mod(3, 0, 1))}")
assert order(h, 0, False) == 6 and x2 == 2 and count_mod(3, 0, 1) == 4 and [order((F(x), F(y)), 0) for x, y in c8] == [2, 0, 0, 0, 0]
d1, d2, d3 = (add((F(x), F(y)), (F(x), F(y)), a)[0] for x, y, a in ((2, 3, 0), (1, 3, 0), (2, 4, 0)))
print(f"by hand: slope at (3, 5) = {F(3 * 9 + A, 2 * 5)}; x^3 - 2 at 1, -1, 2, -2: {[x ** 3 - 2 for x in (1, -1, 2, -2)]}; x^3 - 2 mod 5 at 0..4: {[(x ** 3 - 2) % 5 for x in range(5)]}")
print(f"by hand: x(2(2, 3)) on y^2 = x^3 + 1 is {d1}; x(2(1, 3)) and x(2(2, 4)) on y^2 = x^3 + 8 are {d2} and {d3}")
assert d1 == 0 and d2 == d3 == F(-7, 4) and sorted((x ** 3 - 2) % 5 for x in range(5)) == [0, 1, 2, 3, 4]
print("ALL CHECKS PASS")
