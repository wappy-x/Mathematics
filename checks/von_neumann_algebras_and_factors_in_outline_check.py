# Factors in outline -- the check behind the card.  Standard library only.
# Projections in the 2^n x 2^n matrices with the normalised trace, their sizes,
# the one-third projection of the infinite tensor product, centres of small
# algebras, and the truncated shift.  Exact fractions wherever the answer is.
from fractions import Fraction as F
import math

def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def adj(A): return [[A[j][i] for j in range(len(A))] for i in range(len(A))]  # real entries
def kron(A, B):
    m = len(B)
    return [[A[i // m][j // m] * B[i % m][j % m] for j in range(len(A) * m)] for i in range(len(A) * m)]
def eye(n): return [[F(int(i == j)) for j in range(n)] for i in range(n)]
def unit(n, i, j): return [[F(int(r == i and c == j)) for c in range(n)] for r in range(n)]
def sub(A, B): return [[a - b for a, b in zip(r, s)] for r, s in zip(A, B)]
def tau(A): return sum(A[i][i] for i in range(len(A))) / len(A)   # normalised trace
def is_proj(P): return mul(P, P) == P and adj(P) == P
def rank(A):                              # exact Gaussian elimination, no trace used
    M, r = [row[:] for row in A], 0
    for c in range(len(M[0])):
        p = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if p is None: continue
        M[r], M[p] = M[p], M[r]
        for i in range(len(M)):
            if i != r and M[i][c] != 0:
                f = M[i][c] / M[r][c]
                M[i] = [a - f * b for a, b in zip(M[i], M[r])]
        r += 1
    return r
def dec(x): return "%.6f" % float(x)
I2, E11, E12, E22 = eye(2), unit(2, 0, 0), unit(2, 0, 1), unit(2, 1, 1)

print("1. the 2 x 2 matrices, tau = trace / 2")
u = [F(3, 5), F(4, 5)]
P = [[u[i] * u[j] for j in range(2)] for i in range(2)]   # projection onto the line through u
V = [[u[0], F(0)], [u[1], F(0)]]                           # sends e1 to u, e2 to 0
print(f"P = [[{dec(P[0][0])}, {dec(P[0][1])}], [{dec(P[1][0])}, {dec(P[1][1])}]]; P^2 = P and P* = P: {is_proj(P)}")
print(f"tau(P) = {tau(P)}, rank(P) / 2 = {F(rank(P), 2)}; V*V = E11: {mul(adj(V), V) == E11}; VV* = P: {mul(V, adj(V)) == P}")
assert is_proj(P) and tau(P) == F(rank(P), 2) == F(1, 2)
assert mul(adj(V), V) == E11 and mul(V, adj(V)) == P

print("2. the 4 x 4 matrices: size = trace / 4 = rank / 4")
cases = [("E11 (x) 1", kron(E11, I2)), ("P (x) P", kron(P, P)), ("1 - P (x) P", sub(eye(4), kron(P, P))),
         ("E11 (x) E11", kron(E11, E11)), ("E11 (x) E22", kron(E11, E22)), ("1 (x) 1", eye(4))]
for name, Q in cases:
    print(f"{name:12s} projection {is_proj(Q)}, tau = {tau(Q)}, rank / 4 = {F(rank(Q), 4)}")
    assert is_proj(Q) and tau(Q) == F(rank(Q), 4)
W = kron(E11, E12)                        # links the two halves of E11 (x) 1
print(f"halving: W*W = E11 (x) E22: {mul(adj(W), W) == kron(E11, E22)}; WW* = E11 (x) E11: {mul(W, adj(W)) == kron(E11, E11)}")
assert mul(adj(W), W) == kron(E11, E22) and mul(W, adj(W)) == kron(E11, E11)
assert tau(kron(P, I2)) == tau(P) and tau(kron(P, P)) == tau(P) ** 2
print(f"embedding A -> A (x) 1 keeps tau: tau(P (x) 1) = {tau(kron(P, I2))} = tau(P)")
for n in range(1, 5):                     # every diagonal projection of M_{2^n}
    d = 2 ** n
    sizes = sorted({F(bin(m).count("1"), d) for m in range(2 ** d)})
    print(f"level n = {n}: {len(sizes)} sizes, smallest non-zero {sizes[1]}, one third among them: {F(1, 3) in sizes}")
    assert len(sizes) == d + 1 and sizes[1] == F(1, d) and F(1, 3) not in sizes
assert all(2 ** n % 3 != 0 for n in range(1, 64))      # the arithmetic fact behind Step 2, n up to 63
d10 = [F(1), F(0)]                        # the diagonal of E11
for _ in range(9): d10 = [y for x in d10 for y in (x, F(0))]   # E11 (x) E11 (x) ... (x) E11: rank 1, the smallest
print(f"level n = 10: smallest non-zero size {sum(d10) / len(d10)} = {dec(sum(d10) / len(d10))}")
assert len(d10) == 2 ** 10 and sum(d10) / len(d10) == F(1, 1024)

print("3. the limit: the projection 'binary digits below t' in the weak closure")
for N in (2, 4, 8, 12, 16):
    cnt = sum(1 for k in range(2 ** N) if 3 * k < 2 ** N)   # first N digits below 1/3
    t_N = F(cnt, 2 ** N)
    dist = math.sqrt(t_N - F(1, 3))
    print(f"t = 1/3, N = {N:2d}: tau(f_N) = {dec(t_N)}, GNS distance to f = {dist:.6f}")
    assert t_N == F(2 ** N + 2, 3 * 2 ** N) and abs(dist - math.sqrt(2 / (3 * 2 ** N))) < 1e-12
    assert all(3 * (k >> 2) < 2 ** N for k in range(2 ** (N + 2)) if 3 * k < 2 ** (N + 2))   # f_{N+2} <= f_N
for N in (4, 8, 16):
    cnt = sum(1 for k in range(2 ** N) if 2 * k * k < 4 ** N)   # k / 2^N below 1 / sqrt 2
    print(f"t = 1/sqrt 2 = {1 / math.sqrt(2):.6f}, N = {N:2d}: tau = {dec(F(cnt, 2 ** N))}, gap {cnt / 2 ** N - 1 / math.sqrt(2):.6f}")
    assert 0 < cnt / 2 ** N - 1 / math.sqrt(2) <= 1 / 2 ** N

print("4. centres: X in the algebra with XB = BX for every basis member B")
def centre_dim(basis):
    rows = []
    for Bj in basis:
        comms = [sub(mul(Bk, Bj), mul(Bj, Bk)) for Bk in basis]
        n = len(Bj)
        rows += [[C[r][c] for C in comms] for r in range(n) for c in range(n)]
    return len(basis) - rank(rows)
U3 = lambda i, j: unit(3, i, j)
algebras = [("M_2", [unit(2, i, j) for i in range(2) for j in range(2)], 1),
            ("M_4 = M_2 (x) M_2", [unit(4, i, j) for i in range(4) for j in range(4)], 1),
            ("M_2 (x) 1 in M_4", [kron(unit(2, i, j), I2) for i in range(2) for j in range(2)], 1),
            ("diagonal 2 x 2", [E11, E22], 2),
            ("M_2 (+) M_1 in M_3", [U3(i, j) for i in range(2) for j in range(2)] + [U3(2, 2)], 2),
            ("diagonal 4 x 4", [unit(4, i, i) for i in range(4)], 4)]
for name, basis, blocks in algebras:
    z = centre_dim(basis)
    print(f"{name:20s} dimension {len(basis):2d}, centre dimension {z}, factor: {z == 1}")
    assert z == blocks
D = [[[F(a), F(0)], [F(0), F(b)]] for a in range(-2, 3) for b in range(-2, 3)]
ok = [X for X in D if mul(adj(X), X) == E11 and mul(X, adj(X)) == E22]
normal = sum(1 for X in D if mul(adj(X), X) == mul(X, adj(X)))   # the reason: a diagonal V has V*V = VV*
print(f"diagonal V = diag(a, b) with V*V = E11 and VV* = E22, a and b in -2..2: {len(ok)} found; V*V = VV* for {normal} of {len(D)}")
assert not ok and normal == len(D)

print("5. the shift on l2, cut to N x N")
for N in (4, 8, 16):
    S = [[F(int(r == c + 1)) for c in range(N)] for r in range(N)]
    a, b = mul(adj(S), S), mul(S, adj(S))
    print(f"N = {N:2d}: tr(S*S) = {sum(a[i][i] for i in range(N))}, tr(SS*) = {sum(b[i][i] for i in range(N))}, tr(1) = {N}, S*S = 1: {a == eye(N)}")
    assert a == sub(eye(N), unit(N, N - 1, N - 1)) and b == sub(eye(N), unit(N, 0, 0))

print("6. what breaks")
w = lambda A: F(3, 4) * A[0][0] + F(1, 4) * A[1][1]          # a biased coin, not a trace
print(f"biased state p = 3/4: w(E11) = {dec(w(E11))}, w(E22) = {dec(w(E22))}, ratio lambda = {w(E22) / w(E11)}, though E12 links them")
assert mul(E12, adj(E12)) == E11 and mul(adj(E12), E12) == E22 and w(E11) != w(E22)
raw = [sum(M[i][i] for i in range(len(M))) for M in (E11, kron(E11, I2), kron(kron(E11, I2), I2))]
d = [F(1), F(0)]                          # the diagonal of E11
for _ in range(9): d = [y for x in d for y in (x, x)]          # E11 (x) 1 (x) ... (x) 1 at level 10
print(f"unnormalised trace of E11 at levels 1, 2, 3: {raw[0]}, {raw[1]}, {raw[2]}; at level 10: {sum(d)}")
assert raw == [1, 2, 4] and sum(d) == 2 ** 9
print("ALL CHECKS PASS")
