# Quantum limits -- the check behind the card.  Standard library only.  Amplitudes are a
# classical simulation (the Qubits card explains the state vector); every matrix is real.
from math import asin, ceil, cos, floor, log2, pi, sin, sqrt

S = [0x2026]                                # SplitMix64, seed 0x2026
def rnd():                                  # a float in [-1, 1)
    z = S[0] = (S[0] + 0x9E3779B97F4A7C15) & (2**64 - 1)
    z = (z ^ z >> 30) * 0xBF58476D1CE4E5B9 & (2**64 - 1)
    z = (z ^ z >> 27) * 0x94D049BB133111EB & (2**64 - 1)
    return ((z ^ z >> 31) >> 11) / 2**52 - 1
def fmt(v): return "below 1e-12" if abs(v) < 1e-12 else f"{v:.6f}"
def diffs(q, k):                            # k-th finite difference of a list
    for _ in range(k):
        q = [b - a for a, b in zip(q, q[1:])]
    return max(map(abs, q))
# ---- 1. the example: one marked entry in N = 1,000,000 ----
N = 1_000_000
th = asin(1 / sqrt(N))
kb = floor(pi / (4 * th))
s, c = sin(th), cos(th)                     # road one: two reflections in the plane
for _ in range(kb):
    s = -s                                  # oracle: flip the key's sign
    d = 2 * (s * sin(th) + c * cos(th))     # diffusion: reflect across the start
    s, c = d * sin(th) - s, d * cos(th) - c
pk = sin((2 * kb + 1) * th) ** 2            # road two: the angle formula
assert abs(s * s - pk) < 1e-9
print(f"N = {N}, sqrt N = {sqrt(N):.0f}: theta = {th:.10f}, Grover rounds floor(pi/(4 theta)) = {kb}, success {pk:.8f}")
t23 = next(t for t in range(kb) if sin((2 * t + 1) * th) ** 2 >= 2 / 3)   # first round past 2/3
print(f"error 1/3: {t23} rounds + 1 checking query = {t23 + 1} queries; classical: {ceil(2 * N / 3)} looks")
poly = sqrt(N) / 4                          # polynomial method: 2T >= sqrt(N/4)
dist = sqrt(2 - 4 * sqrt(2 / 9)); hyb = dist / 2 * sqrt(N)   # hybrid argument
print(f"lower bounds: polynomial method T >= {poly:.1f}; hybrid: distance {dist:.4f}, T >= {dist / 2:.4f} sqrt N = {hyb:.1f}")
assert poly <= t23 + 1
for e in range(2, 7):                       # chart points
    print(f"chart N = 10^{e}: Grover {floor(pi / (4 * asin(10 ** (-e / 2))))}, "
          f"bound {10 ** (e / 2) / 4:.1f}, classical {ceil(2 * 10 ** e / 3)}")
# ---- 2. any T-query algorithm: acceptance is a polynomial of degree <= 2T ----
n, W = 6, 2                                 # 6 input bits; registers (i, b, w)
D = n * 2 * W
wt = [bin(x).count("1") for x in range(2 ** n)]
def orth():                                 # a random rotation, by Gram-Schmidt
    rows = []
    while len(rows) < D:
        v = [rnd() for _ in range(D)]
        for r in rows:
            p = sum(a * b for a, b in zip(v, r))
            v = [a - p * b for a, b in zip(v, r)]
        rows.append([a / sqrt(sum(b * b for b in v)) for a in v])
    return rows
def run(U, x):                              # U0, query, U1, query, ..., UT
    v = [1.0] + [0.0] * (D - 1)
    for t, M in enumerate(U):
        if t:                               # query: |i, b, w> -> |i, b xor x_i, w>
            v = [v[j ^ ((x >> (j // (2 * W)) & 1) * W)] for j in range(D)]
        v = [sum(a * b for a, b in zip(r, v)) for r in M]
    return sum(v[j] ** 2 for j in range(D) if j % W == 1)   # accept: w reads 1
for T in (1, 2):
    U = [orth() for _ in range(T + 1)]
    p = [run(U, x) for x in range(2 ** n)]
    co = p[:]                               # Moebius inversion: multilinear coefficients
    for i in range(n):
        for x in [x for x in range(2 ** n) if x >> i & 1]:
            co[x] -= co[x ^ 1 << i]
    big = [max(abs(co[x]) for x in range(2 ** n) if wt[x] == k) for k in range(n + 1)]
    print(f"T = {T}: largest coefficient by degree 0..6: " + ", ".join(fmt(b) for b in big))
    assert max(big[2 * T + 1:]) < 1e-9 and big[2 * T] > 1e-3
    q = [sum(p[x] for x in range(2 ** n) if wt[x] == k) / wt.count(k) for k in range(n + 1)]
    print(f"T = {T}: symmetrised q(k), difference of order {2 * T + 1}: largest {fmt(diffs(q, 2 * T + 1))}")
    assert diffs(q, 2 * T + 1) < 1e-9
# ---- 3. Grover on 16 entries: its polynomial, and the hybrid sum ----
G, T = 16, 3
def grover(marked):                         # T rounds; returns the 16 amplitudes
    v = [1 / 4] * G
    for _ in range(T):
        v = [-a if j in marked else a for j, a in enumerate(v)]
        v = [2 * sum(v) / G - a for a in v]  # diffusion: twice the mean minus each
    return v
q = [sum(grover(range(k))[j] ** 2 for j in range(k)) for k in range(G + 1)]
assert max(abs(q[k] - sin(7 * asin(sqrt(k / G))) ** 2) for k in range(G + 1)) < 1e-12
print(f"Grover, 16 entries, 3 rounds + check: q(0) = {q[0]:.4f}, q(1) = {q[1]:.4f}, q(2) = {q[2]:.4f}, "
      f"q(4) = {q[4]:.4f}; difference of order 8: largest {fmt(diffs(q, 8))}")
assert diffs(q, 8) < 1e-9 and diffs(q, 7) > 1e-3
hs = sum(sqrt(sum((a - 1 / 4) ** 2 for a in grover({i}))) for i in range(G))
print(f"hybrid sum of distances: {hs:.4f} <= 2 T sqrt(16) = {2 * T * 4}")
assert abs(hs - 32 * sin(3 * asin(1 / 4))) < 1e-9; assert hs <= 2 * T * 4   # 16 x 2 sin(3 theta)
# ---- 4. local Hamiltonians on 2 qubits: basis 00, 01, 10, 11 ----
def kron(A, B):
    k = len(B)
    return [[A[i // k][j // k] * B[i % k][j % k] for j in range(len(A) * k)] for i in range(len(A) * k)]
def below(A, lam):                          # eigenvalues below lam, from pivot signs
    B = [[A[i][j] - (lam if i == j else 0) for j in range(len(A))] for i in range(len(A))]
    neg = 0
    for i in range(len(B)):
        piv = B[i][i] if abs(B[i][i]) > 1e-300 else 1e-300
        neg += piv < 0
        for r in range(i + 1, len(B)):
            B[r] = [a - B[r][i] / piv * b for a, b in zip(B[r], B[i])]
    return neg
def lowest(A):                              # bisection on that count
    lo, hi = -10.0, 10.0
    for _ in range(60):
        lo, hi = (lo, (lo + hi) / 2) if below(A, (lo + hi) / 2) >= 1 else ((lo + hi) / 2, hi)
    return (lo + hi) / 2
def energy(A, v): return sum(v[i] * A[i][j] * v[j] for i in range(len(v)) for j in range(len(v)))
Z, X = [[1, 0], [0, -1]], [[0, 1], [1, 0]]
ZZ = kron(Z, Z)
print("H = Z x Z: diagonal " + ", ".join(f"{ZZ[i][i]}" for i in range(4)) + f"; lowest by bisection "
      f"{lowest(ZZ):.4f}; eigenvalues below -0.5: {below(ZZ, -0.5)}, below 0.5: {below(ZZ, 0.5)}")
assert abs(lowest(ZZ) + 1) < 1e-9 and below(ZZ, -0.5) == 2
for name, v in (("|01>", [0, 1, 0, 0]), ("|00>", [1, 0, 0, 0]), ("|++>", [0.5] * 4)):
    e = energy(ZZ, v)
    print(f"witness {name}: energy {e:.4f}, verifier accepts with probability (1 - energy)/2 = {(1 - e) / 2:.4f}")
H2 = [[a + b for a, b in zip(r, s)] for r, s in zip(ZZ, kron(X, X))]
u = lambda a: (cos(pi * a / 72), sin(pi * a / 72))  # real one-qubit states, 2.5 degree steps
best = min(energy(H2, [r * s for r in u(a) for s in u(b)]) for a in range(72) for b in range(72))   # product states
sing = energy(H2, [0, sqrt(0.5), -sqrt(0.5), 0])
print(f"H = ZxZ + XxX: lowest by bisection {lowest(H2):.4f}; (|01> - |10>)/sqrt 2 has energy {sing:.4f}; best product state {best:.4f}")
assert abs(lowest(H2) + 2) < 1e-9 and abs(sing + 2) < 1e-12
assert abs(best + 1) < 1e-9; assert best > lowest(H2) + 0.5   # no product state gets near the ground energy
# ---- 5. Kitaev's construction on a one-gate circuit: witness w, work q, clock c ----
for deg in (0, 30, 60, 90):                 # gate: if w = 1, turn q by deg degrees
    f = deg * pi / 180
    U = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, cos(f), -sin(f)], [0, 0, sin(f), cos(f)]]
    H = [[0.0] * 8 for _ in range(8)]       # index 2 (2w + q) + c
    for a in range(4):
        H[2 * a][2 * a] += 0.5; H[2 * a + 1][2 * a + 1] += 0.5   # propagation term
        for b in range(4):
            H[2 * a + 1][2 * b] -= 0.5 * U[a][b]; H[2 * b][2 * a + 1] -= 0.5 * U[a][b]
        H[2 * a + 1 - a % 2][2 * a + 1 - a % 2] += 1   # q = 1 at c = 0, or q = 0 at c = 1
    acc = sin(f) ** 2                       # best witness w = 1
    e0, e1 = lowest(H), 1 - sqrt((1 + sqrt(acc)) / 2)   # bisection; closed form
    print(f"gate {deg:2d} deg: best acceptance {acc:.4f}; ground energy {abs(e0):.6f} "
          f"(formula {e1:.6f}); history state (1 - acceptance)/2 = {(1 - acc) / 2:.6f}")
    assert abs(e0 - e1) < 1e-9 and e0 <= (1 - acc) / 2 + 1e-12
# ---- 6. what breaks ----
print(f"mistake 1, degree T not 2T: bound sqrt(N)/2 = {sqrt(N) / 2:.0f} > {t23 + 1} queries Grover uses")
print(f"mistake 2, q(k) = (1 + k)/3 has degree 1 but q(N) = {(1 + N) / 3:.2f}, not a probability")
print(f"mistake 3, a sorted list: binary search needs {ceil(log2(N))} classical looks")
print(f"mistake 4, classical witness for ZxZ + XxX: energy {best:.4f}, not {sing:.4f}")
print("ALL CHECKS PASS")
