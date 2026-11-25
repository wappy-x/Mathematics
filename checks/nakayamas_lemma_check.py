# Nakayama's lemma -- the check behind the card.  Standard library only.
# Ring: Q[x, y] near the origin, maximal ideal m = (x, y).  A polynomial is a
# dict {(i, j): c} meaning c x^i y^j.  Roads: linear parts in m/m^2 against
# membership certificates, against brute force in the finite local ring
# F_5[x, y]/(x, y)^3; then searches over the finite local ring Z/4 and Z/6.
from itertools import combinations, product

def add(*fs):
    out = {}
    for f in fs:
        for e, c in f.items():
            out[e] = out.get(e, 0) + c
    return {e: c for e, c in out.items() if c}

def mul(f, g):
    return add(*[{(a + c, b + d): s * t} for (a, b), s in f.items() for (c, d), t in g.items()])

def neg(f):
    return {e: -c for e, c in f.items()}

def show(f):                                    # leading term first, x > y
    s = ""
    for (i, j), c in sorted(f.items(), reverse=True):
        mono = ("x" if i else "") + (f"^{i}" if i > 1 else "") + ("y" if j else "") + (f"^{j}" if j > 1 else "")
        num = str(abs(c)) if abs(c) != 1 or not mono else ""
        s += (" - " if c < 0 else " + ") + num + mono
    return (s[3:] if s.startswith(" + ") else "-" + s[3:]) if s else "0"

def at(f, x, y):
    return sum(c * x**i * y**j for (i, j), c in f.items())

def rank(rows, p=0):                            # p = 0: over Q, fraction-free; else mod p
    rows, r = [list(v) for v in rows], 0
    for col in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(r, len(rows)) if (rows[i][col] % p if p else rows[i][col])), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(r + 1, len(rows)):
            a, b = rows[r][col], rows[i][col]
            rows[i] = [(a * u - b * w) % p if p else a * u - b * w for u, w in zip(rows[i], rows[r])]
        r += 1
    return r

X, Y, ONE = {(1, 0): 1}, {(0, 1): 1}, {(0, 0): 1}
g1, g2 = add(X, mul(Y, Y)), add(Y, mul(X, X))
gens = [("x + y^2", g1), ("y", Y), ("x", X)]
lin = lambda f: (f.get((1, 0), 0), f.get((0, 1), 0))     # the image in m/m^2
BASIS = [(1, 0), (0, 1), (2, 0), (1, 1), (0, 2)]          # m_A in F_5[x, y]/(x, y)^3

def ideal_dim(fs, p=5):                         # dim over F_5 of the ideal of A they span
    vecs = [mul(m, f) for f in fs for m in (ONE, X, Y)]
    return rank([[v.get(e, 0) % p for e in BASIS] for v in vecs], p)

print("-- the ideal I = (x + y^2, y, x) in Q[x, y] localised at m = (x, y) --")
for name, f in gens:
    print(f"generator {name}: value at the origin {at(f, 0, 0)}, image in m/m^2 = {lin(f)}")
dim_I = rank([lin(f) for _, f in gens])
print(f"dimension of the image of I in m/m^2: {dim_I}, so I needs exactly {dim_I} generators")
pair_rows = []
for (n1, f1), (n2, f2) in combinations(gens, 2):
    r, d = rank([lin(f1), lin(f2)]), ideal_dim([f1, f2])
    pair_rows.append((r, d))
    print(f"pair {n1}, {n2}: rank in m/m^2 {r}; ideal in F_5[x, y]/(x, y)^3 has dimension {d} of 5")
print(f"certificate: (x + y^2) - y*y = {show(add(g1, neg(mul(Y, Y))))}")
one_gen = max(ideal_dim([dict(zip(BASIS, c))]) for c in product(range(5), repeat=5))
print(f"largest ideal one element spans, over all 5^5 = 3125 members of m_A: dimension {one_gen} of 5")

print("-- local, not global: N = (x + y^2, y + x^2) --")
dim_N = rank([lin(g1), lin(g2)])
print(f"images in m/m^2: {lin(g1)}, {lin(g2)}: rank {dim_N}, so N = m in the local ring")
c1, c2 = add(g1, neg(mul(Y, g2))), add(g2, neg(mul(X, g1)))
print(f"certificate: (x + y^2) - y*(y + x^2) = {show(c1)}")
print(f"certificate: (y + x^2) - x*(x + y^2) = {show(c2)}")
A = [[{}, neg(Y)], [neg(X), {}]]                 # x = (-y) y and y = (-x) x modulo N
B = [[add(ONE if i == j else {}, neg(A[i][j])) for j in range(2)] for i in range(2)]
det = add(mul(B[0][0], B[1][1]), neg(mul(B[0][1], B[1][0])))
print(f"determinant trick on m/N: A = [[0, -y], [-x, 0]], det(Id - A) = {show(det)}, value at the origin {at(det, 0, 0)}")
print(f"det(Id - A) times x equals the first certificate: {'yes' if mul(det, X) == c1 else 'no'}")
print(f"det(Id - A) times y equals the second certificate: {'yes' if mul(det, Y) == c2 else 'no'}")
print(f"at (-1, -1): x + y^2 = {at(g1, -1, -1)}, y + x^2 = {at(g2, -1, -1)}, 1 - xy = {at(det, -1, -1)}, x = -1")

def elems(orders):
    return list(product(*[range(o) for o in orders]))

def span(vs, orders, n):
    return {tuple(sum(c * v[i] for c, v in zip(cs, vs)) % orders[i] for i in range(len(orders)))
            for cs in product(range(n), repeat=len(vs))}

def min_gens(members, orders, n):
    full = set(members)
    return next(r for r in range(len(orders) + 2) if any(span(s, orders, n) == full for s in combinations(members, r)))

print("-- minimal generators over the local ring Z/4, m = (2), residue field F_2 --")
gen_rows = []
for orders in [(4,), (2,), (2, 4), (4, 4), (2, 2, 4)]:
    M = elems(orders)
    twoM = {tuple(2 * a % o for a, o in zip(v, orders)) for v in M}
    d, mu = (len(M) // len(twoM)).bit_length() - 1, min_gens(M, orders, 4)
    gen_rows.append((d, mu))
    print(f"M = {' + '.join(f'Z/{o}' for o in orders)}: dim M/2M = {d}, smallest generating set by search = {mu}")

def idempotents(n):
    out = []
    for a, b, c, d in product(range(n), repeat=4):
        if ((a * a + b * c) % n, (a * b + b * d) % n, (c * a + d * c) % n, (c * b + d * d) % n) == (a, b, c, d):
            out.append((a, b, c, d))
    return out

def image(E, n):
    a, b, c, d = E
    return sorted({((a * u + b * v) % n, (c * u + d * v) % n) for u in range(n) for v in range(n)})

print("-- projective is free over a local ring: images of idempotent 2 x 2 matrices E --")
free_ok = []
for E in idempotents(4):
    P, r = image(E, 4), rank([[E[0] % 2, E[1] % 2], [E[2] % 2, E[3] % 2]], 2)
    free_ok.append(len(P) == 4**r and min_gens(P, (4, 4), 4) == r)
print(f"over Z/4: {len(free_ok)} idempotents; each image free of rank = rank of E mod 2: {'yes' if all(free_ok) else 'no'}")
sizes6 = sorted({len(image(E, 6)) for E in idempotents(6)})
print(f"over Z/6: {len(idempotents(6))} idempotents; image sizes {sizes6}; no power of 6: {[s for s in sizes6 if s not in (1, 6, 36)]}")

print("-- what breaks --")
M3 = [0, 3]
print(f"not local: over Z/6, M = {M3} has 3M = {sorted({3 * v % 6 for v in M3})}, yet M is not 0; (1 - 3)M = {sorted({4 * v % 6 for v in M3})}, and 1 - 3 = 4 mod 6 is no unit")
v2 = lambda a: (a & -a).bit_length() - 1
v2d = lambda a: 0 if a % 2 else 1 + v2d(a // 2)                        # the same order, by halving
fr = [(1, 2), (3, 4), (5, 8)]
low = min(v2(a) - v2(b) for a, b in fr)
print(f"not finitely generated: Q over Z_(2) has 2Q = Q, since 1/16 = 2 * 1/32; generators 1/2, 3/4, 5/8 reach 2-adic order {low} only, 1/16 has order {v2(1) - v2(16)}")
print(f"counting generators instead of the dimension: I has {len(gens)} generators, m/m^2 has dimension {dim_I}")
assert dim_I == 2 and dim_N == 2 and one_gen == 3                    # two needed, one never enough
assert all((r == 2) == (d == 5) for r, d in pair_rows)                # m/m^2 test against direct span
assert mul(det, X) == c1 and mul(det, Y) == c2 and at(det, 0, 0) == 1 # determinant trick = certificate
assert at(g1, -1, -1) == 0 == at(g2, -1, -1) and at(det, -1, -1) == 0
assert all(d == mu for d, mu in gen_rows) and all(free_ok)            # mu(M) = dim M/mM; projective = free
assert [s for s in sizes6 if s not in (1, 6, 36)]                      # Z/6: projective, not free
assert low == -3 == min(v2d(a) - v2d(b) for a, b in fr) and v2(1) - v2(16) == -4 == v2d(1) - v2d(16)
print("ALL CHECKS PASS")
