# States and the GNS construction -- the check behind the card.  Standard library only.
# Algebra: 2 x 2 complex matrices.  State of a coin with heads chance p: omega(A) = p a11 + (1-p) a22.
# Roads: the Gram matrix built from omega against its closed form; pi(A) built from omega alone
# against the Bell-pair formula A (x) I; commutants by Gaussian elimination against known answers;
# the one-third event by counting all 2^N flip sequences against exact integer closed forms.
import math

def mul(A, B): return [[sum(A[i][t] * B[t][j] for t in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def star(A): return [[A[j][i].conjugate() for j in range(len(A))] for i in range(len(A[0]))]
def kron(A, B): return [[A[i // 2][k // 2] * B[i % 2][k % 2] for k in range(4)] for i in range(4)]
def omega(A, p): return p * A[0][0] + (1 - p) * A[1][1]
def unit(i, j): return [[1 + 0j if (r, c) == (i, j) else 0j for c in range(2)] for r in range(2)]
def close(a, b, tol=1e-12): assert abs(a - b) < tol, (a, b)
def same(A, B): [close(x, y) for ra, rb in zip(A, B) for x, y in zip(ra, rb)]
def re(z): close(z.imag, 0); return f"{z.real:.6f}"

def rank_null(rows, tol=1e-9):  # Gaussian elimination: rank, and a basis of the null space
    rows, piv, r = [row[:] for row in rows], [], 0
    for c in range(len(rows[0])):
        b = max(range(r, len(rows)), key=lambda i: abs(rows[i][c]))
        if abs(rows[b][c]) < tol: continue
        rows[r], rows[b] = rows[b], rows[r]
        rows[r] = [x / rows[r][c] for x in rows[r]]
        for i in range(len(rows)):
            f = rows[i][c]
            if i != r and abs(f) > 0: rows[i] = [x - f * y for x, y in zip(rows[i], rows[r])]
        piv.append(c); r += 1
        if r == len(rows): break
    null = []
    for fc in [c for c in range(len(rows[0])) if c not in piv]:
        v = [0j] * len(rows[0]); v[fc] = 1
        for i, c in enumerate(piv): v[c] = -rows[i][fc]
        null.append(v)
    return len(piv), null

def commutant(gens, d):  # every d x d matrix T with T G = G T for each G in gens
    rows = []
    for G in gens:
        for i in range(d):
            for j in range(d):
                row = [0j] * (d * d)
                for t in range(d): row[i * d + t] += G[t][j]; row[t * d + j] -= G[i][t]
                rows.append(row)
    return [[v[a * d:(a + 1) * d] for a in range(d)] for v in rank_null(rows)[1]]

# 1. The fair coin's expectation, first on payoffs (diagonal), then on every 2 x 2 matrix.
X, S = [[10 + 0j, 0j], [0j, -6 + 0j]], [[0j, 1 + 0j], [1 + 0j, 0j]]
Y, Z = [[1 + 0j, 2 + 0j], [1j, 3 + 0j]], [[0j, 1j], [2 + 0j, -1 + 0j]]  # two test matrices
I2 = [[1 + 0j, 0j], [0j, 1 + 0j]]
EX, EX2 = omega(X, 0.5), omega(mul(star(X), X), 0.5)
close(EX, 0.5 * 10 + 0.5 * -6); close(EX2, 0.5 * 100 + 0.5 * 36)
print(f"coin, E[X] = {re(EX)}, E[X^2] = {re(EX2)}, standard deviation = {math.sqrt(EX2.real - EX.real ** 2):.6f}")
print(f"state, omega(I) = {re(omega(I2, .5))}, omega(S) = {re(omega(S, .5))}, omega(Y) = {re(omega(Y, .5))}")
for M in (Y, Z):  # positivity, against the closed form p(|a11|^2 + |a21|^2) + (1-p)(|a12|^2 + |a22|^2)
    close(omega(mul(star(M), M), .5), .5 * sum(abs(M[i][j]) ** 2 for i in range(2) for j in range(2)))
yy, zz, yz = omega(mul(star(Y), Y), .5), omega(mul(star(Z), Z), .5), omega(mul(star(Y), Z), .5)
assert abs(yz) ** 2 <= yy.real * zz.real
print(f"positive, omega(Y*Y) = {re(yy)}, omega(Z*Z) = {re(zz)}, |omega(Y*Z)|^2 = {abs(yz) ** 2:.6f} <= {yy.real * zz.real:.6f}")
rho = [[omega(unit(j, i), .5) for j in range(2)] for i in range(2)]  # density matrix rho_ij = omega(E_ji)
for M in (X, S, Y, Z): close(sum(mul(rho, M)[i][i] for i in range(2)), omega(M, .5))
assert rank_null(rho)[0] == 2  # rank 2, so no single vector psi (rho = psi psi*, rank 1) gives the fair coin
print(f"density, rho = [[{re(rho[0][0])}, {re(rho[0][1])}], [{re(rho[1][0])}, {re(rho[1][1])}]], omega(M) = trace(rho M) on 4 tests")

# 2. GNS: vectors are matrices, <C, D> = omega(C* D); pi(M) acts by left multiplication.
E = [unit(i, j) for i in range(2) for j in range(2)]  # order E11, E12, E21, E22
def gns(p):
    G = [[omega(mul(star(C), D), p) for D in E] for C in E]
    same(G, [[(k == l) * [p, 1 - p][k % 2] for l in range(4)] for k in range(4)])  # closed form
    dim = rank_null(G)[0]
    basis = [[[x / math.sqrt(G[k][k].real) for x in row] for row in E[k]] for k in range(4) if abs(G[k][k]) > 1e-12]
    pi = lambda M: [[omega(mul(star(u), mul(M, v)), p) for v in basis] for u in basis]
    Om = [omega(star(u), p) for u in basis]  # coordinates of the vector [I]
    return dim, basis, pi, Om
for p in (0.5, 0.75, 1.0):
    dim, basis, pi, Om = gns(p)
    for M in (X, S, Y, Z):
        PM = pi(M)
        close(sum(Om[u].conjugate() * PM[u][v] * Om[v] for u in range(dim) for v in range(dim)), omega(M, p))
        same(pi(mul(M, Y)), mul(PM, pi(Y))); same(pi(star(M)), star(PM))
    gens = [pi(Ek) for Ek in E]
    dimA = rank_null([[x for row in P for x in row] for P in gens])[0]
    C1 = commutant(gens, dim); C2 = commutant(C1, dim)
    for P in gens:
        for T in C1: same(mul(P, T), mul(T, P))
    print(f"gns, p = {p:.2f}, dim H = {dim}, dim pi(A) = {dimA}, dim commutant = {len(C1)}, dim double commutant = {len(C2)}")
    assert (dim, len(C1), len(C2)) == {0.5: (4, 4, 4), 0.75: (4, 4, 4), 1.0: (2, 1, 4)}[p] and dimA == len(C2)
dim, basis, pi, Om = gns(0.5)  # the Bell-pair road: pi(M) = M (x) I and Omega = (e11 + e22)/sqrt 2
for M in (X, S, Y, Z): same(pi(M), kron(M, I2))
same([Om], [[1 / math.sqrt(2), 0, 0, 1 / math.sqrt(2)]])
for T in (kron(I2, S), kron(I2, Y)):
    for Ek in E: same(mul(pi(Ek), T), mul(T, pi(Ek)))
PX, PS = pi(X), pi(S)
SOm = [sum(PS[u][v] * Om[v] for v in range(4)) for u in range(4)]
XOmv = [sum(PX[u][v] * Om[v] for v in range(4)) for u in range(4)]
XOm = sum(Om[u].conjugate() * XOmv[u] for u in range(4))
print(f"bell, pi(X) Omega = ({', '.join(re(z) for z in XOmv)}), <Omega, pi(X) Omega> = {re(XOm)}")
print(f"bell, pi(S) Omega = ({', '.join(re(z) for z in SOm)}), <Omega, pi(S) Omega> = {re(sum(Om[u].conjugate() * SOm[u] for u in range(4)))}")
print(f"bell, Omega = ({', '.join(re(z) for z in Om)}), pi(M) = M (x) I on 4 tests, I (x) S and I (x) Y commute with pi")

# 3. What breaks.
bad = lambda M: 1.5 * M[0][0] - 0.5 * M[1][1]
print(f"breaks, 1.5 a11 - 0.5 a22: omega(I) = {re(bad(I2))}, omega(E22* E22) = {re(bad(mul(star(E[3]), E[3])))}")
n12, bad_r = omega(mul(star(E[1]), E[1]), 1.0), mul(E[1], E[2])
print(f"breaks, p = 1, right action: |E12|^2 = {re(n12)} but |E12 E21|^2 = {re(omega(mul(star(bad_r), bad_r), 1.0))}")
e1 = [1 + 0j, 0j]; v11 = sum(e1[i].conjugate() * E[0][i][j] * e1[j] for i in range(2) for j in range(2))
print(f"breaks, one vector in C^2 for the fair coin: e1* E11 e1 = {re(v11)}, omega(E11) = {re(omega(E[0], .5))}")

# 4. Infinitely many flips: f = 1 if 0.X1X2X3... (binary) < 1/3, f_N reads only the first N flips.
chart = []
for N in range(2, 17, 2):
    count = sum(1 for m in range(2 ** N) if 3 * m < 2 ** N)
    assert 3 * count == 2 ** N + 2  # closed form: omega(f_N) = (2^N + 2) / (3 2^N)
    d2 = (3 * count - 2 ** N) / (3 * 2 ** N)  # f <= f_N, so |f_N - f|^2 = f_N - f, mean 2 / (3 2^N)
    below = lambda k: int(3 * k < 2 ** N)  # f at k / 2^N, and f_N on the prefix k
    sup = max(abs(below(m) - below(m + 1)) for m in range(2 ** N))  # prefix m covers m / 2^N up to (m + 1) / 2^N
    w = count - 1  # witness: first N digits spell w, then tails forever: f_N = 1, f = 0
    assert sup == 1 and below(w) == 1 and below(w + 1) == 0
    dist = math.sqrt(d2)
    close(dist, math.sqrt(2 / 3) * 2 ** (-N / 2))
    chart.append(f"{math.log10(dist):.3f}")
    print(f"flips, N = {N}, omega(f_N) = {count / 2 ** N:.6f}, GNS distance = {dist:.6f}, sup distance = {sup}")
print(f"chart, log10 GNS distance, N = 2..16 step 2, {', '.join(chart)}")
print("ALL CHECKS PASS")
