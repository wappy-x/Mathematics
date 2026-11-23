# Sofic groups and Kothe -- the check behind the card.  Standard library only.
# Part A: the modular group SL(2,Z) is residually finite, so reducing mod a
# prime p and multiplying on the left gives an exact sofic picture of a ball
# of words.  Part B: small rings where Kothe's statement can be checked, and
# the traps around it.  Every search is written out; nothing is imported.

def mul(a, b, p=0):                       # 2x2 matrices as (top-left, top-right, bottom-left, bottom-right)
    r = (a[0]*b[0] + a[1]*b[2], a[0]*b[1] + a[1]*b[3], a[2]*b[0] + a[3]*b[2], a[2]*b[1] + a[3]*b[3])
    return tuple(x % p for x in r) if p else r

def red(g, p):
    return tuple(x % p for x in g)

def yn(claim):
    return "yes" if claim else "no"

I, S, T = (1, 0, 0, 1), (1, 1, 0, 1), (0, -1, 1, 0)
gens = [S, (1, -1, 0, 1), T, (0, 1, -1, 0)]          # S, its undo, T, its undo
ball, layer, sizes = {I}, {I}, []
for r in range(3):                                    # words of length up to 3
    layer = {mul(g, s) for g in layer for s in gens}
    ball |= layer
    sizes.append(len(ball))
F = sorted(ball)
print(f"ball of words of length <= 1, 2, 3 in S, T: {sizes[0]}, {sizes[1]}, {sizes[2]} matrices")
print(f"largest entry in the ball: {max(abs(x) for g in F for x in g)}")

def collapsed(p):                                     # ball members, not I, that read as I mod p
    return [g for g in F if g != I and red(g, p) == red(I, p)]

p = 2
while collapsed(p):
    print(f"p = {p}: {len(collapsed(p))} non-identity ball members reduce to I, e.g. {collapsed(p)[0]}")
    p += 1 if p == 2 else 2
pts = [(a, b, c, d) for a in range(p) for b in range(p) for c in range(p) for d in range(p)
       if (a*d - b*c) % p == 1]                       # road one: count SL(2, F_p) by brute force
n = len(pts)
print(f"first prime keeping the ball apart: p = {p}")
print(f"SL(2,F_{p}) by brute force: {n} points; by p(p^2 - 1): {p * (p*p - 1)}")
index = {x: i for i, x in enumerate(pts)}

def sigma(g):                                         # g acts on the points by left multiplication
    return tuple(index[mul(red(g, p), x, p)] for x in pts)

def test(sig, m):                                     # road two: most points of m where sigma(gh) != sigma(g)sigma(h),
    P = {g: sig(g) for g in F}                        # and most fixed points of sigma(g), g != I
    worst = max(sum(a[i] != P[g][P[h][i]] for i in range(m)) for g in F for h in F for a in [sig(mul(g, h))])
    return worst, max(sum(P[g][i] == i for i in range(m)) for g in F if g != I)

worst, fixed = test(sigma, n)
print(f"pairs g, h in the ball: {len(F) ** 2}; most points where sigma(gh) != sigma(g)sigma(h): {worst} of {n}")
print(f"most fixed points of sigma(g), g != I in the ball: {fixed} of {n}, so epsilon = 0 works")
for q, g in [(2, mul(T, T)), (3, mul(S, mul(S, S)))]:
    qp = [x for x in [(a, b, c, d) for a in range(q) for b in range(q) for c in range(q)
          for d in range(q)] if (x[0]*x[3] - x[1]*x[2]) % q == 1]
    fx = sum(mul(red(g, q), x, q) == x for x in qp)
    print(f"mistake, p = {q} too small: sigma({g}) fixes {fx} of {len(qp)} points")
w1, f1 = test(lambda g: (0,), 1)                     # every g sent to the identity on 1 point
print("mistake, drop the fixed-point rule: send every g to the identity on 1 point:")
print(f"  product errors {w1} of 1, fixed points {f1} of 1, so every group would pass")

# Part B.  R = F_2 + N, where N = strictly upper triangular 3x3 matrices over F_2.
# An element (e, x, y, z) means e*I + [[0, x, y], [0, 0, z], [0, 0, 0]].
def rmul(u, v):
    return (u[0]*v[0] % 2, (u[0]*v[1] + u[1]*v[0]) % 2,
            (u[0]*v[2] + u[2]*v[0] + u[1]*v[3]) % 2, (u[0]*v[3] + u[3]*v[0]) % 2)

def radd(u, v):
    return tuple((s + t) % 2 for s, t in zip(u, v))

Z = (0, 0, 0, 0)
Nset = [(0, x, y, z) for x in (0, 1) for y in (0, 1) for z in (0, 1)]

def mmul(A, B):                                       # 2x2 matrices with entries in R
    return (radd(rmul(A[0], B[0]), rmul(A[1], B[2])), radd(rmul(A[0], B[1]), rmul(A[1], B[3])),
            radd(rmul(A[2], B[0]), rmul(A[3], B[2])), radd(rmul(A[2], B[1]), rmul(A[3], B[3])))

def nil_index(A, mult, zero, cap=12):                 # first k with A^k = 0, or None
    P = A
    for k in range(1, cap + 1):
        if P == zero:
            return k
        P = mult(P, A)
    return None

ZM = (Z, Z, Z, Z)
M2N = [(a, b, c, d) for a in Nset for b in Nset for c in Nset for d in Nset]
idx = [nil_index(W, mmul, ZM) for W in M2N]           # road one: every 2x2 matrix over N
triple = all(rmul(rmul(u, v), w) == Z for u in Nset for v in Nset for w in Nset)
print(f"N has {len(Nset)} elements; every product of three is 0 (road two): {yn(triple)}")
print(f"M2(N): {len(M2N)} matrices, all nilpotent: {yn(None not in idx)}, largest index {max(idx)}")
L0 = [(a, Z, c, Z) for a in Nset for c in Nset]       # first column in N, second column 0
L1 = [(Z, b, Z, d) for b in Nset for d in Nset]
basis = [(1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)]
unitsE = [tuple(r if k == j else Z for k in range(4)) for r in basis for j in range(4)]
closed = all(mmul(E, A) in set(L) for L in (L0, L1) for A in L for E in unitsE)
nil01 = all(nil_index(A, mmul, ZM) for A in L0 + L1)
sums = {tuple(radd(a, b) for a, b in zip(A, B)) for A in L0 for B in L1}
print(f"column ideals L0, L1: {len(L0)} and {len(L1)} members, left-closed: {yn(closed)}, nil: {yn(nil01)}")
print(f"L0 + L1 has {len(sums)} members = all of M2(N): {yn(sums == set(M2N))}")
nilz = [x for x in range(72) if any(pow(x, k, 72) == 0 for k in range(1, 8))]
print(f"Z/72, nilpotent by brute force: {len(nilz)}; multiples of 6: {len(range(0, 72, 6))}")
E12, E21 = (0, 1, 0, 0), (0, 0, 1, 0)
W = (0, 1, 1, 0)
print(f"mistake, two nilpotents: E12^2 = {mul(E12, E12)}, E21^2 = {mul(E21, E21)}, "
      f"(E12 + E21)^2 = {mul(W, W)}, nilpotent: {yn(nil_index(W, mul, (0, 0, 0, 0)) is not None)}")
Mall = [(a, b, c, d) for a in (0, 1) for b in (0, 1) for c in (0, 1) for d in (0, 1)]
gen = sorted({mul(A, E12, 2) for A in Mall})
print(f"mistake, left ideal of M2(F_2) made from E12: {gen}; E22 = (0, 0, 0, 1) idempotent: "
      f"{yn(mul((0, 0, 0, 1), (0, 0, 0, 1), 2) == (0, 0, 0, 1))}")

assert n == p * (p*p - 1) and worst == 0 and fixed == 0         # sofic picture, two roads
assert all(collapsed(q) for q in (2, 3)) and p == 5             # p = 5 is the first that works
assert (w1, f1) == (0, 1)                                       # the trivial picture passes products
assert triple and None not in idx and max(idx) == 3             # brute force agrees with N^3 = 0
assert closed and nil01 and sums == set(M2N)                    # two nil left ideals, nil sum
assert nilz == list(range(0, 72, 6)) and nil_index(W, mul, (0, 0, 0, 0)) is None
print("ALL CHECKS PASS")
