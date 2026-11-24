# Holomorphic functional calculus and Riesz projections -- the check behind the card.  Standard library only.
# f(T) = (1/(2 pi i)) x (loop integral of f(z) (zI - T)^-1 dz), computed by the trapezoid rule on a circle.
# Inverses, products, exponentials and norms are written out; nothing imported already knows the answer.
from math import cos, sin, pi, exp, sqrt, log10

def f6(t): return f"{(t if abs(t) >= 5e-7 else 0.0):.6f}"      # never print "-0.000000"
def cexp(z): return exp(z.real) * complex(cos(z.imag), sin(z.imag))
def mat(A): return "[[" + "], [".join(", ".join(f6(v) for v in row) for row in A) + "]]"
def dot(a, b):                       # plain running sum, so Python and Rust add in the same order
    s = 0.0
    for p, q in zip(a, b):
        s += p * q
    return s
def mul(A, B): return [[dot(A[i], [r[j] for r in B]) for j in range(len(B[0]))] for i in range(len(A))]
def gap(A, B): return max(abs(a - b) for ra, rb in zip(A, B) for a, b in zip(ra, rb))
def inverse(A):                      # Gauss-Jordan with partial pivoting, complex entries
    n = len(A)
    M = [list(A[i]) + [complex(1.0 if j == i else 0.0) for j in range(n)] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        piv = M[c][c]
        M[c] = [v / piv for v in M[c]]
        for r in range(n):
            if r != c:
                f = M[r][c]
                M[r] = [a - f * b for a, b in zip(M[r], M[c])]
    return [row[n:] for row in M]
def calculus(f, A, centre, radius, nodes):   # (1/(2 pi i)) loop integral of f(z) (zI - A)^-1 dz, trapezoid rule
    n = len(A)
    S = [[0j] * n for _ in range(n)]
    for k in range(nodes):
        w = radius * complex(cos(2 * pi * k / nodes), sin(2 * pi * k / nodes))
        z = centre + w               # dz = i w dtheta; the i cancels the i in 1/(2 pi i)
        R = inverse([[(z if i == j else 0j) - A[i][j] for j in range(n)] for i in range(n)])
        for i in range(n):
            for j in range(n):
                S[i][j] += f(z) * R[i][j] * w / nodes
    return [[v.real for v in row] for row in S]
def opnorm(A, iters=200):            # largest stretch: power iteration on A^T A
    x = [1.0] * len(A[0])
    for _ in range(iters):
        y = [dot(row, x) for row in A]
        z = [dot([row[j] for row in A], y) for j in range(len(x))]
        s = sqrt(dot(z, z))
        x = [t / s for t in z]
    y = [dot(row, x) for row in A]
    return sqrt(dot(y, y))
one = lambda z: 1.0 + 0j

print("A = [[1, 1], [0, 2]], spectrum {1, 2}; (zI - A)^-1 = [[1/(z-1), 1/((z-1)(z-2))], [0, 1/(z-2)]]")
A = [[1.0, 1.0], [0.0, 2.0]]
P = [[0.0, 1 / (2 - 1)], [0.0, 1.0]]  # residues at z = 2, entry by entry: none, 1/(2-1), 1
print("road 1, residues at 2 by hand: P =", mat(P))
print("road 2, trapezoid rule on |z - 2| = 0.5 with M nodes:")
errs = []
for M in (4, 8, 16, 32):
    PM = calculus(one, A, 2.0, 0.5, M)
    err, pred = gap(PM, P), 0.5 ** M / (1 - 0.5 ** M)
    errs.append(log10(err))
    print(f"  M = {M:2d}: P_M = {mat(PM)}, error {err:.12f}, r^M/(1 - r^M) = {pred:.12f}, log10 error {log10(err):.3f}")
    assert abs(err - pred) < 1e-13
print("chart, log10 error against M = 4, 8, 16, 32:", ", ".join(f"{e:.3f}" for e in errs))
P2, AP, PA = mul(P, P), mul(A, P), mul(P, A)
print("road 3, invariants: P^2 =", mat(P2), "| AP =", mat(AP), "| PA =", mat(PA))
print("  P (1, 1) =", mat([[dot(P[0], [1.0, 1.0]), dot(P[1], [1.0, 1.0])]]), "| P (1, 0) =", mat([[P[0][0], P[1][0]]]), "| trace P =", f6(P[0][0] + P[1][1]))
nP = opnorm(P)
print("  ||P|| by power iteration =", f6(nP), "| sqrt 2 =", f6(sqrt(2)), "| above 1, so P is oblique, not orthogonal")
assert gap(P2, P) == 0 and gap(AP, PA) == 0 and abs(nP - sqrt(2)) < 1e-12
Q = [[1 - P[0][0], -P[0][1]], [-P[1][0], 1 - P[1][1]]]
Q1 = calculus(one, A, 1.0, 0.5, 64)
print("I - P =", mat(Q), "| loop |z - 1| = 0.5, 64 nodes:", mat(Q1))
assert gap(Q, Q1) < 1e-15
print("e^A, three roads:")
E1 = calculus(cexp, A, 1.5, 2.0, 64)
E2, term = [[1.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]]
for k in range(1, 30):
    term = [[v / k for v in row] for row in mul(term, A)]
    E2 = [[a + b for a, b in zip(r, s)] for r, s in zip(E2, term)]
E3 = [[exp(1) * Q[i][j] + exp(2) * P[i][j] for j in range(2)] for i in range(2)]
print("  loop |z - 1.5| = 2, 64 nodes:", mat(E1))
print("  power series, 30 terms:     ", mat(E2))
print("  e (I - P) + e^2 P:          ", mat(E3))
assert gap(E1, E3) < 1e-12 and gap(E2, E3) < 1e-12
tr, det = E1[0][0] + E1[1][1], E1[0][0] * E1[1][1] - E1[0][1] * E1[1][0]
disc = sqrt(tr * tr - 4 * det)
lo, hi = (tr - disc) / 2, (tr + disc) / 2
print(f"spectral mapping: z^2 - {f6(tr)} z + {f6(det)} has roots {f6(lo)}, {f6(hi)} | e, e^2 = {f6(exp(1))}, {f6(exp(2))}")
print(f"  det e^A = {f6(det)} | e^(trace A) = e^3 = {f6(exp(3))}")
assert abs(lo - exp(1)) < 1e-9 and abs(hi - exp(2)) < 1e-9 and abs(det - exp(3)) < 1e-9
print("what breaks:")
J = [[2.0, 1.0], [0.0, 2.0]]
EJ = calculus(cexp, J, 2.0, 1.0, 64)
print("  Jordan block [[2, 1], [0, 2]]: loop gives e^J =", mat(EJ), "| e^2 on the eigenvalue alone:", mat([[exp(2), 0.0], [0.0, exp(2)]]))
assert abs(EJ[0][1] - exp(2)) < 1e-12
F = calculus(lambda z: 1 / (z - 2), A, 1.5, 2.0, 64)
FA = mul(F, [[-1.0, 1.0], [0.0, 0.0]])
print("  f = 1/(z - 2), a pole on the spectrum: loop gives", mat(F), "| times (A - 2I):", mat(FA), "not I")
assert gap(F, [[0.0, 0.0], [0.0, 0.0]]) < 1e-12
W = calculus(one, A, 2.0, 1.5, 64)
print("  loop |z - 2| = 1.5 also encloses 1:", mat(W), "| trace", f6(W[0][0] + W[1][1]))
assert gap(W, [[1.0, 0.0], [0.0, 1.0]]) < 1e-9
O = [[0.5, 0.5], [0.5, 0.5]]
C = [[a - b for a, b in zip(r, s)] for r, s in zip(mul(A, O), mul(O, A))]
print("  nearest-point projection O onto (1, 1): AO - OA =", mat(C), "| ||O|| =", f6(opnorm(O)))
assert gap(C, [[0.5, -0.5], [0.5, -0.5]]) == 0 and abs(opnorm(O) - 1) < 1e-12
print("infinite dimensions: leaning blur on L2[0, 1], k(x, y) = e^(x - y) min(x, y) (1 - max(x, y)), N grid points")
lam1, limit = 1 / pi ** 2, (exp(1) - exp(-1)) / 2 * pi ** 2 / (1 + pi ** 2)
print("  exact: top eigenvalue 1/pi^2 =", f6(lam1), "| ||P|| = sinh(1) pi^2 / (1 + pi^2) =", f6(limit))
for N in (10, 20, 40, 80):
    xs = [(i + 0.5) / N for i in range(N)]
    K = [[exp(x - y) * min(x, y) * (1 - max(x, y)) / N for y in xs] for x in xs]
    PN = calculus(one, K, 0.1, 0.04, 48)
    trP = dot([PN[i][i] for i in range(N)], [1.0] * N)
    lamN = dot([dot(K[i], [PN[j][i] for j in range(N)]) for i in range(N)], [1.0] * N) / trP
    nrm = sqrt(dot([v for row in PN for v in row], [v for row in PN for v in row]))
    idem = gap(mul(PN, PN), PN)
    print(f"  N = {N:2d}: trace P_N {f6(trP)} | eigenvalue {f6(lamN)}, (eigenvalue - 1/pi^2) x N^2 = {f6((lamN - lam1) * N * N)} | ||P_N|| {f6(nrm)} | P_N^2 = P_N: {'yes' if idem < 1e-10 else 'no'}")
    assert abs(trP - 1) < 1e-9 and idem < 1e-10 and abs(lamN - lam1) < 0.1 / N ** 2
assert abs(nrm - limit) < 1e-5
print("figure, 80 px per unit, 0 at (60, 190): z = 1 at (140, 190), z = 2 at (220, 190), loop |z - 2| = 0.5 radius 40, loop |z - 1.5| = 2 centre (180, 190) radius 160")
print("ALL CHECKS PASS")
