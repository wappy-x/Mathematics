# Modules and the structure theorem -- the check behind the card.  Nothing is imported.
# M is Z^3 modulo two relations.  Road 1: Smith form by moves whole numbers undo (Bezout's
# 2-by-2 move where an entry fails to divide).  Road 2: gcds of minors.  Road 3: the size of
# M/qM, by listing every mix of the relations mod q.  Then put the answer back in.
R1, R2 = (2, 2, 2), (4, -2, -2)

def bezout(a, b):                        # s, t, g with s*a + t*b = g = gcd(a, b)
    s0, s1, t0, t1 = 1, 0, 0, 1
    while b:
        q = a // b
        a, b, s0, s1, t0, t1 = b, a - q * b, s1, s0 - q * s1, t1, t0 - q * t1
    return (s0, t0, a) if a > 0 else (-s0, -t0, -a)

def gcd(a, b):
    return bezout(a, b)[2]

def move(a, b):                          # a 2-by-2 move of determinant 1: (a, b) -> (g, 0)
    if b % a == 0:
        return 1, 0, -(b // a), 1        # plain subtraction
    s, t, g = bezout(a, b)               # Bezout's move: the pivot shrinks to g
    return s, t, -b // g, a // g

def rows(M, i, j, s, t, u, v):           # rows i, j -> s*i + t*j, u*i + v*j
    M[i], M[j] = ([s * x + t * y for x, y in zip(M[i], M[j])],
                  [u * x + v * y for x, y in zip(M[i], M[j])])

def cols(M, i, j, s, t, u, v):           # the same move on columns
    for r in M:
        r[i], r[j] = s * r[i] + t * r[j], u * r[i] + v * r[j]

def smith(A):                            # returns S, D, T with S A T = D
    m, n = len(A), len(A[0])
    D = [r[:] for r in A]
    S = [[int(i == j) for j in range(m)] for i in range(m)]
    T = [[int(i == j) for j in range(n)] for i in range(n)]
    for k in range(min(m, n)):
        while True:
            live = [(abs(D[i][j]), i, j) for i in range(k, m) for j in range(k, n) if D[i][j]]
            if not live:
                return S, D, T
            _, p, q = min(live)          # smallest entry becomes the pivot
            rows(D, k, p, 0, 1, 1, 0); rows(S, k, p, 0, 1, 1, 0)
            cols(D, k, q, 0, 1, 1, 0); cols(T, k, q, 0, 1, 1, 0)
            for i in range(k + 1, m):    # clear the pivot's column
                mv = move(D[k][k], D[i][k])
                rows(D, k, i, *mv); rows(S, k, i, *mv)
            for j in range(k + 1, n):    # clear the pivot's row
                mv = move(D[k][k], D[k][j])
                cols(D, k, j, *mv); cols(T, k, j, *mv)
            if any(D[i][k] for i in range(k + 1, m)):
                continue                 # a Bezout column move refilled the column
            bad = [i for i in range(k + 1, m) for j in range(k + 1, n) if D[i][j] % D[k][k]]
            if not bad:
                break                    # else fold the offending row into the pivot row
            rows(D, k, bad[0], 1, 1, 0, 1); rows(S, k, bad[0], 1, 1, 0, 1)
        if D[k][k] < 0:                  # flip the sign: -1 is a unit
            rows(D, k, k, -1, 0, -1, 0); rows(S, k, k, -1, 0, -1, 0)
    return S, D, T

def mul(A, B): return [[sum(a * b for a, b in zip(r, c)) for c in zip(*B)] for r in A]

def det(M):
    return M[0][0] if len(M) == 1 else sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)))

def subsets(N, k):
    return [[]] if k == 0 else [p + [x] for x in range(N) for p in subsets(x, k - 1)]

def invariants(A):                       # road 2: d_k = g_k / g_(k-1), g_k = gcd of k-by-k minors
    out, prev = [], 1
    for k in range(1, min(len(A), len(A[0])) + 1):
        g = 0
        for rs in subsets(len(A), k):
            for cs in subsets(len(A[0]), k):
                g = gcd(g, det([[A[r][c] for c in cs] for r in rs]))
        if g == 0:
            break
        out.append(g // prev); prev = g
    return out

def size_mod(rels, n):                   # road 3: |(Z/n)^3 / span of the relations|, by listing
    span = {tuple((a * x + b * y) % n for x, y in zip(*rels)) for a in range(n) for b in range(n)}
    return n ** 3 // len(span)

def in_span(v, lim=12):                  # is v a whole-number mix of r1 and r2?
    return any(all(a * x + b * y == w for x, y, w in zip(R1, R2, v))
               for a in range(-lim, lim + 1) for b in range(-lim, lim + 1))

def order(v):                            # smallest k with k*v a mix; 0 means none up to 30
    return next((k for k in range(1, 31) if in_span([k * x for x in v])), 0)

A = [[R1[i], R2[i]] for i in range(3)]   # the relations as columns
S, D, T = smith(A)
d = [D[i][i] for i in range(2) if D[i][i]]
phi = lambda v: (v[0] % 2, (v[0] - v[1]) % 6, v[2] - v[1])   # the decomposition, read off S
print(f"relations r1 = {R1}, r2 = {R2}; relation matrix A = {A}")
print(f"S = {S}, det {det(S)}; T = {T}, det {det(T)}")
print(f"S A T = {mul(mul(S, A), T)}; diagonal {d}; free rank {3 - len(d)}")
print(f"road 2, minors: invariant factors {invariants(A)}; g1 = {invariants(A)[0]}, g2 = {invariants(A)[0] * invariants(A)[1]}")
print("M = Z (+) Z/2 (+) Z/6 = Z (+) Z/2 (+) Z/2 (+) Z/3, through (x, y, z) -> (x mod 2, (x - y) mod 6, z - y)")
sizes = [size_mod((R1, R2), n) for n in range(1, 13)]
pred = [n * gcd(n, 2) * gcd(n, 6) for n in range(1, 13)]
print(f"road 3, |M/qM| for q = 1..12 by listing: {sizes}")
print(f"predicted q * gcd(q, 2) * gcd(q, 6):      {pred}")
box = [(x, y, z) for x in range(-6, 7) for y in range(-6, 7) for z in range(-6, 7)]
zero_mix = [v for v in box if in_span(v)]
zero_phi = [v for v in box if phi(v) == (0, 0, 0)]
print(f"triples in the box -6..6 that are mixes: {len(zero_mix)}; sent to zero: {len(zero_phi)}")
print(f"phi(r1) = {phi(R1)}, phi(r2) = {phi(R2)}; phi(e1), phi(e2), phi(e3) = "
      f"{phi((1, 0, 0))}, {phi((0, 1, 0))}, {phi((0, 0, 1))}")
tests = [(1, 0, 0), (3, 3, 3), (0, 1, 1), (0, 0, 1)]
for v in tests:
    print(f"order of {v}: {order(v) or 'infinite (none up to 30)'}")
tors = sorted({phi((x, y, y))[:2] for x in range(12) for y in range(12)})
orders = [next(k for k in range(1, 13) if (k * a % 2, k * b % 6) == (0, 0)) for a, b in tors]
print(f"torsion part: {len(tors)} members, largest order {max(orders)}")
W, qrank = [r[:] for r in A], 0          # rank over Q, by fraction-free elimination
for c in range(2):
    p = next((r for r in range(qrank, 3) if W[r][c]), None)
    if p is not None:
        W[qrank], W[p] = W[p], W[qrank]
        for r in range(qrank + 1, 3):
            W[r] = [W[qrank][c] * a - W[r][c] * b for a, b in zip(W[r], W[qrank])]
        qrank += 1
print(f"mistake 1, Smith over Q: rank {qrank}, diagonal {[1] * qrank}; M reads Q^{3 - qrank}, torsion lost")
print(f"mistake 2, torsion read as Z/12: Z/12 has order 12, M only {max(orders)}; "
      f"|M/2M| = {sizes[1]}, Z (+) Z/12 gives {2 * gcd(2, 12)}")
dd = invariants([[2, 4], [2, 4], [2, 4]])
print(f"mistake 3, free rank 3 - 2 = 1: r2 = (4, 4, 4) gives diagonal {dd}, free rank {3 - len(dd)}")
for r2 in [(2, 4, -2), (6, 3, 0), (3, 5, 7)]:
    B = [[R1[i], r2[i]] for i in range(3)]
    E = smith(B)[1]
    road1 = [E[i][i] for i in range(2) if E[i][i]]
    print(f"r2 = {r2}: Smith diagonal {road1}, minors {invariants(B)}, |M/2M| = {size_mod((R1, r2), 2)}")
    assert road1 == invariants(B)                               # road 1 = road 2
assert mul(mul(S, A), T) == D and abs(det(S)) == 1 == abs(det(T))  # substitution
assert d == invariants(A) == [2, 6]                             # road 1 = road 2
assert sizes == pred                                            # road 3, the count
assert zero_mix == zero_phi and len(zero_mix) > 1               # mixes = what phi kills
assert [order(v) for v in tests] == [6, 2, 6, 0]
print("ALL CHECKS PASS")
