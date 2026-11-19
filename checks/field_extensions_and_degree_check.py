# Field extensions and degree -- the check behind the card.  Standard library
# only.  The field Q(a), a = 2^(1/4), is stored as Q[x]/(x^4 - 2): a number is
# four rational coordinates on the basis 1, a, a^2, a^3.  The degree 4 comes by
# three roads: a complete factor search, Eisenstein's test at 2, and the tower
# Q < Q(r2) < Q(a), whose two steps of 2 multiply.  r2 is the square root of 2.
from fractions import Fraction as F
import math

def mul(u, v, f):                      # multiply, then trade x^n for -(f - x^n)
    n = len(f) - 1                     # f: integer coefficients, constant first, monic
    prod = [F(0)] * (2 * n - 1)
    for i, x in enumerate(u):
        for j, y in enumerate(v):
            prod[i + j] += x * y
    for k in range(2 * n - 2, n - 1, -1):
        c, prod[k] = prod[k], F(0)
        for i in range(n):
            prod[k - n + i] -= c * f[i]
    return prod[:n]

def reduce(rows):                      # Gauss-Jordan over Q: (reduced rows, rank)
    rows, r = [[F(x) for x in row] for row in rows], 0
    for col in range(len(rows[0])):
        piv = next((i for i in range(r, len(rows)) if rows[i][col] != 0), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        rows[r] = [x / rows[r][col] for x in rows[r]]
        for i in range(len(rows)):
            if i != r and rows[i][col] != 0:
                t = rows[i][col]
                rows[i] = [x - t * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return rows, r

def degree(beta, f):                   # first n with 1, beta, ..., beta^n dependent
    powers = [[F(1)] + [F(0)] * (len(f) - 2)]
    while True:
        nxt = mul(powers[-1], beta, f)
        if reduce(powers + [nxt])[1] == len(powers):
            return len(powers)
        powers.append(nxt)

def divisors(n):
    return [d for d in range(1, abs(n) + 1) if n % d == 0]

def rational_roots(c):                 # every candidate p/q, p | constant, q | leading
    cands = {F(s * p, q) for p in divisors(c[0]) for q in divisors(c[-1]) for s in (1, -1)}
    return sorted(r for r in cands if sum(ci * r ** i for i, ci in enumerate(c)) == 0)

def quadratic_factors(c):              # monic integer quartic = (x^2+ax+b)(x^2+gx+d)?
    bound = 2 * (1 + max(abs(x) for x in c[:4]))   # every root is smaller than 1 + max|c_i|
    found = []
    for b in [s * d for d in divisors(c[0]) for s in (1, -1)]:
        d = c[0] // b
        for a in range(-bound, bound + 1):
            g = c[3] - a
            if (b + d + a * g, a * d + b * g) == (c[2], c[1]) and (a, b) <= (g, d):
                found.append((a, b, g, d))
    return found

def eisenstein(c, p):
    return all(x % p == 0 for x in c[:-1]) and c[0] % (p * p) != 0 and c[-1] % p != 0

def gf2_mul(u, v, f, n):               # GF(2) polynomials as bit masks, wrapped at f
    out = 0
    while v:
        if v & 1:
            out ^= u
        v, u = v >> 1, u << 1
        if u >> n & 1:
            u ^= f
    return out

def show(v):
    return "[" + ", ".join(str(x) for x in v) + "]"

f4, f6, g4 = [-2, 0, 0, 0, 1], [-2, 0, 0, 0, 0, 0, 1], [4, 0, 0, 0, 1]
e = lambda k, n=4: [F(int(i == k)) for i in range(n)]
one, a, r2 = e(0), e(1), e(2)
rr4, qf4 = rational_roots(f4), quadratic_factors(f4)
step1, step2 = rational_roots([-2, 0, 1]), rational_roots([1, 0, 0, 0, 2])
deg_r2 = degree(r2, f4)
tower = (2 if not step1 else 1) * (2 if not step2 else 1)
products = [mul(x, y, f4) for x in (one, r2) for y in (one, a)]
names = ["3", "a", "a^2", "a^3", "a + a^2", "1 + a^2"]
elems = [[F(3), 0, 0, 0], a, r2, e(3), [0, 1, 1, 0], [1, 0, 1, 0]]
degs = [degree([F(x) for x in v], f4) for v in elems]
outside = reduce([one, r2, a])[1]
one_plus_a = [F(1), F(1), F(0), F(0)]
cols = [mul(one_plus_a, e(j), f4) for j in range(4)]
rows, _ = reduce([[cols[j][i] for j in range(4)] + [one[i]] for i in range(4)])
inv = [row[4] for row in rows]
series = [F(-1), F(1), F(-1), F(1)]    # (1 + a)(1 - a + a^2 - a^3) = 1 - a^4 = -1
x = math.sqrt(math.sqrt(2))
d6 = [degree(e(k, 6), f6) for k in (3, 2, 1)]
qg4, rg4, rg2 = quadratic_factors(g4), rational_roots(g4), rational_roots([2, -2, 1])
pos = rational_roots([-4, 0, 1]), rational_roots([-1, 0, 0, 0, 1]), eisenstein(g4, 2)
real = sum(1 for k in range(-300, 300) if ((k / 100) ** 4 - 2) * (((k + 1) / 100) ** 4 - 2) < 0)
gf8_ok = all(any(gf2_mul(u, v, 0b1011, 3) == 1 for v in range(1, 8)) for u in range(1, 8))
w8 = sum(1 for w in range(8) if gf2_mul(w, w, 0b1011, 3) ^ w ^ 1 == 0)
w16 = sum(1 for w in range(16) if gf2_mul(w, w, 0b10011, 4) ^ w ^ 1 == 0)
aes = 0b100011011                      # x^8 + x^4 + x^3 + x + 1
aes_units = sum(1 for u in range(1, 256) if any(gf2_mul(u, v, aes, 8) == 1 for v in range(1, 256)))
aes_ex = gf2_mul(0x57, 0x83, aes, 8)
print(f"a = 2^(1/4) = {x:.11f}; Q(a) stored on the basis 1, a, a^2, a^3")
print(f"road 1, factor search on x^4 - 2, roots under {1 + max(abs(c) for c in f4[:4])}: rational roots {rr4}, quadratic factors {qf4}: {'irreducible' if not rr4 + qf4 else 'factors'}")
print(f"road 2, Eisenstein at 2 on x^4 - 2: {'yes' if eisenstein(f4, 2) else 'no'}")
print(f"road 3, x^2 - 2 rational roots {step1}: [Q(r2):Q] = 2; dependence search on r2 = a^2: {deg_r2}")
print(f"        x^2 - r2 has a root in Q(r2) only if 2t^4 + 1 has a rational root: {step2}: [Q(a):Q(r2)] = 2")
print(f"        tower: [Q(a):Q] = 2 x 2 = {tower}")
print(f"other answers: rational roots of x^2 - 4 {show(pos[0])}, of x^4 - 1 {show(pos[1])}; Eisenstein at 2 on x^4 + 4: {'yes' if pos[2] else 'no'}")
print(f"basis products 1, a, r2, r2 a as coordinates: {' '.join(show(p) for p in products)}; rank {reduce(products)[1]}")
print(f"a outside Q(r2): rank of 1, r2, a is {outside}")
print(f"degrees over Q of {', '.join(names)}: {degs}")
print(f"every degree divides 4: {'yes' if all(4 % d == 0 for d in degs) else 'no'}; so no element has degree 3")
print(f"1/(1 + a) by solving the 4 x 4 system: {show(inv)}")
print(f"1/(1 + a) by the geometric series:    {show(series)}; product {show(mul(one_plus_a, inv, f4))}")
print(f"as decimals: 1/(1 + a) = {1 / (1 + x):.12f}; -1 + a - a^2 + a^3 = {-1 + x - x * x + x * x * x:.12f}")
print(f"x^6 - 2: Eisenstein at 2 {'yes' if eisenstein(f6, 2) else 'no'}; degrees of r2, 2^(1/3), 2^(1/6): {d6}")
print(f"tower law on Q < Q(2^(1/3)) < Q(2^(1/6)): top step = {d6[2]} / {d6[1]} = {d6[2] // d6[1]}")
print(f"splitting field Q(a, i): i is not real and Q(a) is, so the top step is 2; tower law 4 x 2 = {tower * 2}")
print(f"GF(8) = GF(2)[x]/(x^3 + x + 1): {2 ** 3} elements, all nonzero invertible: {'yes' if gf8_ok else 'no'}")
print(f"roots of w^2 + w + 1: in GF(8) {w8}, in GF(16) {w16}")
print(f"GF(256) with x^8 + x^4 + x^3 + x + 1: {aes_units} of 255 nonzero bytes invertible; 57 x 83 = {aes_ex:02x}")
print(f"mistake 1, x^4 + 4: rational roots {rg4}, yet quadratic factors {qg4}")
print(f"           its root 1 + i solves x^2 - 2x + 2, rational roots {rg2}: degree 2, not 4")
print(f"mistake 2, adding up the tower: 3 + 2 = {d6[1] + 2}, true degree {d6[2]}")
print(f"mistake 3, base field dropped: a has degree {degree(a, f4) // deg_r2} over Q(r2), {degree(a, f4)} over Q")
print(f"symmetries: x^4 - 2 changes sign {real} times on [-3, 3], so the real field Q(a) holds {real} of its roots: {real} symmetries, not 4")
assert rr4 == [] and qf4 == [] and eisenstein(f4, 2)           # roads 1 and 2
assert tower == 4 and deg_r2 == 2                               # road 3
assert pos == ([-2, 2], [-1, 1], False) and real == 2          # the tests can say the other thing
assert reduce(products)[1] == 4 and outside == 3
assert degs == [1, 4, 2, 4, 4, 2]
assert inv == series and mul(one_plus_a, inv, f4) == one
assert abs((-1 + x - x * x + x * x * x) - 1 / (1 + x)) < 1e-12
assert d6 == [2, 3, 6] and qg4 == [(-2, 2, 2, 2)] and rg4 == rg2 == []
assert gf8_ok and (w8, w16) == (0, 2) and aes_units == 255 and aes_ex == 0xC1
print("ALL CHECKS PASS")
