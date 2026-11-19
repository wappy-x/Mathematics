# Splitting fields -- the check behind the card.  Standard library only.  The roots of
# x^4 - 2 are a, -a, ia, -ia, with a = 2^(1/4).  The field is built twice as remainder
# arithmetic, Q(a) then b = ia, and Q(i) then c = a; a search counts the relabellings
# between the builds; primes where x^4 - 2 splits mod p are counted against 1/8.
from fractions import Fraction
from itertools import product
from math import gcd

def add(x, y): return [u + v for u, v in zip(x, y)]
def bmul(x, y, d, r):                  # bottom field: g^d = r[0] + r[1] g + ...
    c = [0] * (2 * d - 1)
    for i in range(d):
        for j in range(d): c[i + j] += x[i] * y[j]
    for e in range(2 * d - 2, d - 1, -1):
        t, c[e] = c[e], 0
        for i in range(d): c[e - d + i] += t * r[i]
    return c[:d]
def mul(F, X, Y):                      # top: h^d2 = r2[0] + r2[1] h + ..., r2 in bottom
    d1, r1, d2, r2 = F
    c = [[0] * d1 for _ in range(2 * d2 - 1)]
    for i in range(d2):
        for j in range(d2): c[i + j] = add(c[i + j], bmul(X[i], Y[j], d1, r1))
    for e in range(2 * d2 - 2, d2 - 1, -1):
        t, c[e] = c[e], [0] * d1
        for i in range(d2): c[e - d2 + i] = add(c[e - d2 + i], bmul(t, r2[i], d1, r1))
    return c[:d2]
def nest(F, flat): return [list(flat[k * F[0]:(k + 1) * F[0]]) for k in range(F[2])]
def flat(X): return tuple(v for row in X for v in row)
def const(F, n): return nest(F, [n] + [0] * (F[0] * F[2] - 1))
def gen(F, k): return nest(F, [1 if k == s else 0 for s in range(F[0] * F[2])])
def pw(F, X, k):
    out = const(F, 1)
    for _ in range(k): out = mul(F, out, X)
    return out
def lin(G, coeffs, elts):               # sum of integer coefficients times elements
    out = const(G, 0)
    for c, e in zip(coeffs, elts): out = add_e(out, [[c * v for v in row] for row in e])
    return out
def add_e(X, Y): return [add(x, y) for x, y in zip(X, Y)]
def rank(rows):                         # exact Gaussian elimination over Q
    m, r = [[Fraction(v) for v in row] for row in rows], 0
    for col in range(len(m[0])):
        piv = next((i for i in range(r, len(m)) if m[i][col] != 0), None)
        if piv is None: continue
        m[r], m[piv] = m[piv], m[r]
        for i in range(len(m)):
            if i != r and m[i][col] != 0:
                f = m[i][col] / m[r][col]; m[i] = [u - f * w for u, w in zip(m[i], m[r])]
        r += 1
    return r
def phi(F, G, A, B, X):                 # the map sending g -> A, h -> B
    imgs = [mul(G, pw(G, A, j), pw(G, B, k)) for k in range(F[2]) for j in range(F[0])]
    return lin(G, flat(X), imgs)
def is_iso(F, G, A, B):                 # products kept on every basis pair, and one-to-one
    n = F[0] * F[2]; basis = [nest(F, [int(s == t) for s in range(n)]) for t in range(n)]
    bad = sum(phi(F, G, A, B, mul(F, e, f)) != mul(G, phi(F, G, A, B, e), phi(F, G, A, B, f))
              for e in basis for f in basis)
    return bad, rank([flat(phi(F, G, A, B, e)) for e in basis]) == n
def maps(F, G):                         # search coordinates -1, 0, 1 for images of g, h
    pool = [nest(G, t) for t in product((-1, 0, 1), repeat=G[0] * G[2])]
    ev = lambda A, co: lin(G, co, [pw(G, A, j) for j in range(F[0])])
    As = [A for A in pool if pw(G, A, F[0]) == ev(A, F[1])]
    found = [(A, B) for A in As for B in pool if pw(G, B, F[2]) ==
             lin_top(G, [ev(A, r) for r in F[3]], B)]
    return As, [ab for ab in found if is_iso(F, G, *ab) == (0, True)]
def lin_top(G, cs, B):
    out = const(G, 0)
    for k, c in enumerate(cs): out = add_e(out, mul(G, c, pw(G, B, k)))
    return out
L = (4, [2, 0, 0, 0], 2, [[0, 0, -1, 0], [0, 0, 0, 0]])   # a^4 = 2, then b^2 = -a^2
M = (2, [-1, 0], 4, [[2, 0], [0, 0], [0, 0], [0, 0]])     # i^2 = -1, then c^4 = 2
Qa = (4, [2, 0, 0, 0], 1, [[0, 0, 0, 0]])                 # a^4 = 2 and nothing more
a, b = gen(L, 1), gen(L, 4)
roots = [a, [[-v for v in r] for r in a], b, [[-v for v in r] for r in b]]
poly = [const(L, 1)]                   # multiply out (x - r1)(x - r2)(x - r3)(x - r4)
for r in roots:
    neg = [[-v for v in row] for row in r]
    poly = [add_e(p, q) for p, q in zip([const(L, 0)] + poly, [mul(L, neg, c) for c in poly] + [const(L, 0)])]
coef = [flat(c) for c in poly]
mod5 = sum(((u + w) % 5, (v + z + u * w) % 5, (u * z + v * w) % 5, (v * z) % 5) == (0, 0, 0, 3)
           for u, v, w, z in product(range(5), repeat=4))
root5 = sum(pow(x, 4, 5) == 2 for x in range(5))
Rq = (4, [1, 0, 0, 0], 1, [[0, 0, 0, 0]])                 # x^4 = 1: reducible
zd = mul(Rq, nest(Rq, [-1, 1, 0, 0]), nest(Rq, [1, 1, 1, 1]))
As_LM, iso_LM = maps(L, M)
_, aut_L = maps(L, L)
As_Qa, aut_Qa = maps(Qa, Qa)
wrong, _ = is_iso(L, M, gen(M, 2), gen(M, 1))             # a -> c but b -> i
N = 10 ** 6
sieve = bytearray([1]) * (N + 1); sieve[0:2] = b"\x00\x00"
for p in range(2, int(N ** 0.5) + 1):
    if sieve[p]: sieve[p * p::p] = bytearray(len(range(p * p, N + 1, p)))
def nroots(p):
    g = gcd(4, p - 1)
    return g if pow(2, (p - 1) // g, p) == 1 else 0
brute = all(nroots(p) == sum(pow(x, 4, p) == 2 for x in range(p)) for p in range(3, 2000) if sieve[p])
al = 2 ** 0.25
print(f"a = 2^(1/4) = {al:.9f}; a^2 = {al * al:.9f}; roots +-{al:.9f}, +-{al:.9f}i")
print(f"x^4 - 2 mod 5: roots {root5}, monic quadratic factorisations {mod5}")
print(f"degree by the tower law (Step 3): [Q(a):Q] = 4, [L:Q(a)] = 2, [L:Q] = 4 x 2 = {4 * 2}; the bound 4! = {1 * 2 * 3 * 4}")
print(f"(x - a)(x + a)(x - ia)(x + ia) in L: rational parts of x^0..x^4 "
      f"{', '.join(str(c[0]) for c in coef)}; other 35 coordinates all 0: {all(not any(c[1:]) for c in coef)}")
print(f"Kronecker on x^4 - 1: (x - 1)(x^3 + x^2 + x + 1) = {flat(zd)}")
print(f"fourth roots of 2 found: in M {len(As_LM)}, in Q(a) {len(As_Qa)}")
print(f"relabellings L -> M {len(iso_LM)}; symmetries of L {len(aut_L)}; of Q(a) {len(aut_Qa)}")
print(f"a -> c, b -> i: products broken on {wrong} of 64 basis pairs")
print(f"brute force agrees with the root formula for every prime below 2000: {brute}")
print("primes p up to N (p > 2): count, share with 4 roots, 2 roots, 0 roots mod p")
shares = []
for top in (10 ** 3, 10 ** 4, 10 ** 5, 10 ** 6):
    cnt = {0: 0, 2: 0, 4: 0}
    for p in range(3, top + 1):
        if sieve[p]: cnt[nroots(p)] += 1
    tot = sum(cnt.values()); shares.append(cnt[4] / tot)
    print(f"  N = {top}: {tot}, {cnt[4] / tot:.4f}, {cnt[2] / tot:.4f}, {cnt[0] / tot:.4f}")
print(f"Chebotarev for degree 8: {1 / 8:.4f}, {2 / 8:.4f}, {5 / 8:.4f}; for degree 4: {1 / 4:.4f}")
assert coef == [(-2,) + (0,) * 7] + [(0,) * 8] * 3 + [(1,) + (0,) * 7]
assert mod5 == 0 and root5 == 0 and flat(zd) == (0, 0, 0, 0)
assert len(As_LM) == 4 and len(iso_LM) == 8 and len(aut_L) == 8 and len(aut_Qa) == 2
assert len(As_Qa) == 2 and wrong > 0 and brute
assert abs(shares[-1] - 1 / 8) < 0.005 and abs(shares[-1] - 1 / 4) > 0.1
print("ALL CHECKS PASS")
