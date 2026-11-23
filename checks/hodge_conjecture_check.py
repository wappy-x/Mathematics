# The Hodge conjecture in degree 4, on the Fermat cubic fourfold -- the check behind the card.
# Standard library only.  X: x0^3 + x1^3 + ... + x5^3 = 0 in P^5, a smooth cubic fourfold.
#   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
#   road 2 (cycle side): its 405 planes, how each pair meets (exact algebra in Z[w], w^3 = 1),
#                        and the rank of their intersection matrix, mod a prime and exactly
#   road 3 (one class two ways): h^2 as three planes in one 3-space, for all 405 such triples
from itertools import product
from math import comb

def mul(x, y):                    # Z[w] with w^2 = -1 - w; the pair (a, b) means a + b w
    return (x[0] * y[0] - x[1] * y[1], x[0] * y[1] + x[1] * y[0] - x[1] * y[1])
def sub(x, y):
    return (x[0] - y[0], x[1] - y[1])
Z0, ONE = (0, 0), (1, 0)
ROOTS = [(-1, 0), (0, -1), (1, 1)]                    # -1, -w, -w^2: the three cube roots of -1

def matchings(s):                 # the ways to split the list s into pairs
    if not s:
        return [[]]
    return [[(s[0], s[k])] + m for k in range(1, len(s)) for m in matchings(s[1:k] + s[k + 1:])]

def meet_dim(P, Q):               # dim of P n Q in C^6: 3 minus the rank of P's forms on Q's basis
    M = [[sub(ONE if l == i else (b if k == i else Z0), mul(a, ONE if l == j else (b if k == j else Z0)))
          for (k, l, b) in Q] for (i, j, a) in P]     # form x_i - a x_j on basis vector b e_k + e_l
    minor = lambda r, s, c, e: sub(mul(M[r][c], M[s][e]), mul(M[r][e], M[s][c]))
    det = Z0
    for c in range(3):
        t = mul(M[0][c], minor(1, 2, (c + 1) % 3, (c + 2) % 3))
        det = (det[0] + t[0], det[1] + t[1])
    if det != Z0:
        return 0
    if any(minor(r, s, c, e) != Z0 for r, s in ((0, 1), (0, 2), (1, 2)) for c, e in ((0, 1), (0, 2), (1, 2))):
        return 1
    return 2 if any(x != Z0 for row in M for x in row) else 3

PRIME = 2 ** 31 - 1
def rank_mod(G, p=PRIME):         # rank by elimination modulo a prime: a lower bound for the rank over Q
    m, r = [[x % p for x in row] for row in G], 0
    for c in range(len(m[0])):
        piv = next((i for i in range(r, len(m)) if m[i][c]), None)
        if piv is None:
            continue
        m[r], m[piv] = m[piv], m[r]
        inv = pow(m[r][c], p - 2, p)
        for i in range(r + 1, len(m)):
            if m[i][c]:
                f = m[i][c] * inv % p
                m[i] = [(x - f * y) % p for x, y in zip(m[i], m[r])]
        r += 1
    return r

def bareiss_det(m):               # exact determinant by fraction-free elimination
    m, prev, sign, n = [row[:] for row in m], 1, 1, len(m)
    for c in range(n):
        piv = next((i for i in range(c, n) if m[i][c] != 0), None)
        if piv is None:
            return 0
        if piv != c:
            m[c], m[piv], sign = m[piv], m[c], -sign
        for i in range(c + 1, n):
            for j in range(c + 1, n):
                m[i][j] = (m[c][c] * m[i][j] - m[i][c] * m[c][j]) // prev
        prev = m[c][c]
    return sign * prev

# ---- road 1: Hodge numbers of a smooth cubic fourfold ----
n, d = 4, 3
deg = [(p + 1) * d - (n + 2) for p in range(n + 1)]
jac = [sum(1 for e in product(range(d - 1), repeat=n + 2) if sum(e) == t) for t in deg]
hodge = jac[:]
hodge[2] += 1                                         # the class h^2 of a plane section of a plane section
b4 = sum(hodge)
chern = sum(comb(n + 2, i) * (-d) ** (n - i) for i in range(n + 1))
euler = d * chern
p1, p2 = comb(6, 1) - d ** 2, comb(6, 2) - 6 * d ** 2 + d ** 4
assert d * (7 * p2 - p1 ** 2) % 45 == 0
sig = d * (7 * p2 - p1 ** 2) // 45
sig_hodge = sum((-1) ** p * hodge[p] for p in range(n + 1)) + sum((-1) ** k for k in (0, 1, 3, 4))  # + h^k,k
print(f"road 1, the Hodge side of a smooth fourfold of degree {d}")
print(f"monomials with exponents at most {d - 2}, of degree {', '.join(map(str, deg))}: {', '.join(map(str, jac))}")
print(f"h^4,0 = {hodge[0]}, h^3,1 = {hodge[1]}, h^2,2 = {jac[2]} + 1 = {hodge[2]}, h^1,3 = {hodge[3]}, "
      f"h^0,4 = {hodge[4]}; b4 = {b4}")
print(f"Euler number {d} x {chern} = {euler}, so b4 = {euler} - 4 = {euler - 4}")
print(f"signature from p1 = {p1}, p2 = {p2}: {d} x (7 x {p2} - {p1 * p1}) / 45 = {sig}; "
      f"from Hodge numbers: {sig_hodge}; so H^4 has signature ({(b4 + sig) // 2}, {(b4 - sig) // 2})")

# ---- road 2: the 405 planes and their intersection matrix ----
planes = [[(i, j, c) for (i, j), c in zip(mt, cs)] for mt in matchings(list(range(6)))
          for cs in product(ROOTS, repeat=3)]
assert all(mul(mul(r, r), r) == (-1, 0) for r in ROOTS)   # c^3 = -1: each plane lies on X
N = len(planes)
VAL = {3: 3, 2: -1, 1: 1, 0: 0}                       # same plane, a line, a point, empty
dims = [[3 if r == c else None for c in range(N)] for r in range(N)]
for r in range(N):
    for c in range(r + 1, N):
        dims[r][c] = dims[c][r] = meet_dim(planes[r], planes[c])
G = [[VAL[x] for x in row] for row in dims]
kinds = [sorted({row.count(k) for row in dims}) for k in (2, 1, 0)]
print(f"road 2, the cycle side: {len(matchings(list(range(6))))} pairings x 3^3 roots = {N} planes on the Fermat cubic fourfold")
print(f"each plane meets {kinds[0][0]} others in a line, {kinds[1][0]} in a point, misses {kinds[2][0]}; "
      f"P.P = {G[0][0]}")
r405 = rank_mod(G)
print(f"rank of the {N} x {N} intersection matrix modulo the prime {PRIME}: {r405}")
basis, minors = [], [1]
for c in range(N):                                    # grow a basis while the Gram determinant stays nonzero
    dt = bareiss_det([[G[a][b] for b in basis + [c]] for a in basis + [c]])
    if dt != 0:
        basis, minors = basis + [c], minors + [dt]
neg = sum(1 for u, v in zip(minors, minors[1:]) if (u > 0) != (v > 0))
print(f"independent planes found: {len(basis)}; exact Gram determinant of the {len(basis)}: {minors[-1]}")
print(f"signature of the intersection form on them: ({len(basis) - neg}, {neg})")

# ---- road 3: h^2 as three planes in one 3-space ----
triples = [[t for t in range(N) if all(planes[t][q] == planes[s][q] for q in range(3) if q != v)]
           for s in range(N) for v in range(3)]
triples = sorted({tuple(t) for t in triples})
rows = {tuple(sum(G[m][c] for m in t) for c in range(N)) for t in triples}
row = next(iter(rows))
h2sq = sum(row[m] for m in triples[0])
print(f"road 3, h^2 as three planes sharing a line: {len(triples)} triples; distinct rows h^2.P: {len(rows)}")
print(f"h^2.P for every plane: {', '.join(map(str, sorted(set(row))))}; h^2.h^2 = 3 x 3 + 6 x (-1) = {h2sq}")

# ---- what breaks ----
wrong = [[1 if r == c else G[r][c] for c in range(N)] for r in range(N)]
flip = [[-x if x == -1 else x for x in row] for row in G]
print(f"mistake 1, a plane meets itself once (P.P = 1): rank {rank_mod(wrong)}, more than b4 = {b4}")
print(f"mistake 2, a line meeting counted +1, not -1: rank {rank_mod(flip)}, more than b4 = {b4}")
print(f"mistake 3, every rational class in H^4 algebraic: {b4} claimed, {len(basis)} algebraic here")
print(f"mistake 4, every (2,2) class algebraic: h^2,2 = {hodge[2]} claimed, 1 for a very general cubic (quoted)")
for k in range(1, 7):                                 # degrees 2p left open by Lefschetz (p = 0, 1, n-1, n)
    left = [str(p) for p in range(k + 1) if p not in (0, 1, k - 1, k)]
    print(f"dimension {k}: codimensions p not covered by Lefschetz: {', '.join(left) or 'none'}")
assert hodge == [0, 1, 21, 1, 0] and b4 == euler - 4 == 23           # road 1 against the Euler number
assert sig == sig_hodge == 19 and all(len(k) == 1 for k in kinds)   # road 1 against the signature
assert r405 == len(basis) == hodge[2] == 21                         # road 2 meets road 1
assert neg == 0 and minors[-1] > 0                                  # positive definite, as (2,2) classes are
assert len(rows) == 1 and set(row) == {1} and h2sq == 3             # road 3: h^2.P = 1, h^4 = 3 = degree
assert rank_mod(wrong) > b4 and rank_mod(flip) > b4                 # the wrong forms are impossible
print("ALL CHECKS PASS")
