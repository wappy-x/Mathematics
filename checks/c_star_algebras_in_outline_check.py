# C-star algebras in outline -- the check behind the card.  Standard library
# only.  The matrix model: a 2 x 2 covariance matrix V of two daily returns,
# in %^2 (illustrative), and its square root by the functional calculus, three
# roads.  The function model: multiplication by t on [0, 1], cut to a grid.
# Every norm is found by a search over unit vectors, never by eigenvalues.
import math

def mul(P, Q): return [[P[i][0] * Q[0][j] + P[i][1] * Q[1][j] for j in range(2)] for i in range(2)]
def add(P, Q, c=1.0): return [[P[i][j] + c * Q[i][j] for j in range(2)] for i in range(2)]
def scale(c, P): return [[c * P[i][j] for j in range(2)] for i in range(2)]
def tr(P): return [[P[j][i] for j in range(2)] for i in range(2)]
def gap(P, Q): return max(abs(P[i][j] - Q[i][j]) for i in range(2) for j in range(2))
def stretch2(M, t):                      # |M (cos t, sin t)|^2
    x, y = math.cos(t), math.sin(t)
    a, b = M[0][0] * x + M[0][1] * y, M[1][0] * x + M[1][1] * y
    return a * a + b * b
def norm(M):                             # road A: the largest stretch of a unit vector
    G, j = 2000, 0
    for i in range(1, G):
        if stretch2(M, math.pi * i / G) > stretch2(M, math.pi * j / G): j = i
    lo, hi = math.pi * (j - 1) / G, math.pi * (j + 1) / G
    for _ in range(200):                 # a ternary search refines the best angle
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if stretch2(M, m1) < stretch2(M, m2): lo = m1
        else: hi = m2
    return math.sqrt(stretch2(M, (lo + hi) / 2))
def eig_sym(M):                          # road B: closed form for 2 x 2 symmetric
    m, h = (M[0][0] + M[1][1]) / 2, (M[0][0] - M[1][1]) / 2
    d = math.sqrt(h * h + M[0][1] * M[0][1])
    return m - d, m + d
def mat(P): return "[[%.6f, %.6f], [%.6f, %.6f]]" % (P[0][0], P[0][1], P[1][0], P[1][1])
def root2k(x, k):                        # x to the power 1/2^k, by k square roots
    for _ in range(k): x = math.sqrt(x)
    return x
I = [[1.0, 0.0], [0.0, 1.0]]
V = [[4.0, 2.0], [2.0, 4.0]]
B = [[1.0, 2.0], [0.0, 1.0]]

print("1. the C-star identity |x* x| = |x|^2 in the matrix model")
l1, l2 = eig_sym(V)
print(f"V = {mat(V)}; eigenvalues {l1:.6f} and {l2:.6f}; |V| by search {norm(V):.6f}")
assert abs(norm(V) - l2) < 1e-9 and abs(l1 - 2) < 1e-12 and abs(l2 - 6) < 1e-12
nB, nBB, nBt = norm(B), norm(mul(tr(B), B)), norm(tr(B))
print(f"shear B = {mat(B)}: |B| = {nB:.6f}, |B*| = {nBt:.6f}, closed form 1 + sqrt 2 = {1 + math.sqrt(2):.6f}")
print(f"|B* B| = {nBB:.6f}; |B|^2 = {nB * nB:.6f}; largest eigenvalue of B* B = {eig_sym(mul(tr(B), B))[1]:.6f}")
assert abs(nBB - nB * nB) < 1e-8 and abs(nB - (1 + math.sqrt(2))) < 1e-9 and abs(nBt - nB) < 1e-9

print("2. the square root of V by the functional calculus, three roads")
r = 1 / math.sqrt(2)
P6 = [[r * r, r * r], [r * r, r * r]]    # projection on the eigenvalue 6, direction (1, 1)
P2 = [[r * r, -r * r], [-r * r, r * r]]  # projection on the eigenvalue 2, direction (1, -1)
assert gap(mul(V, P6), scale(6, P6)) < 1e-12 and gap(mul(V, P2), scale(2, P2)) < 1e-12
R1 = add(scale(math.sqrt(6), P6), scale(math.sqrt(2), P2))
R2 = add(scale(math.sqrt(2), I), add(V, I, -2.0), (math.sqrt(6) - math.sqrt(2)) / 4)
print(f"road 1, sqrt on each eigenvalue: {mat(R1)}")
print(f"road 2, the line through (2, sqrt 2) and (6, sqrt 6): {mat(R2)}")
W, X = scale(1 / 6, V), [[0.0, 0.0], [0.0, 0.0]]
for k in range(1, 41):                   # road 3: p <- p + (t - p^2)/2, polynomials only
    X = add(X, add(W, mul(X, X), -1.0), 0.5)
    if k in (5, 10, 20): print(f"road 3, step k = {k:2d}: largest entry error {gap(scale(math.sqrt(6), X), R1):.3e}")
R3 = scale(math.sqrt(6), X)
print(f"road 3, after 40 steps: {mat(R3)}")
print(f"(sqrt V)^2 = {mat(mul(R1, R1))}; |sqrt V| = {norm(R1):.6f}; sqrt 6 = {math.sqrt(6):.6f}")
assert gap(R1, R2) < 1e-12 and gap(R1, R3) < 1e-12 and gap(mul(R1, R1), V) < 1e-12
assert abs(norm(R1) - math.sqrt(6)) < 1e-9
Q = add(add(mul(V, V), V, -7.0), I, 11.0)            # q(t) = t^2 - 7t + 11
print(f"q(t) = t^2 - 7t + 11: q(2) = {2 * 2 - 7 * 2 + 11}, q(6) = {6 * 6 - 7 * 6 + 11}, |q(V)| by search = {norm(Q):.6f}")
assert abs(norm(Q) - 5) < 1e-9

print("3. the function model: multiplication by t on [0, 1], cut to a grid of N + 1 = 2001 points")
N = 2000                                 # grid t = s^2 with s = j/N, fine near 0
for k in (1, 4, 16, 64, 256):
    err = err2 = 0.0
    for j in range(N + 1):
        s = j / N
        t, p, e = s * s, 0.0, s              # e: the fold's error recursion, e <- e (1 - s + e/2)
        for _ in range(k): p, e = p + (t - p * p) / 2, e * (1 - s + e / 2)
        err, err2 = max(err, s - p), max(err2, e)
    print(f"chart,k={k},sup error on [0,1] {err:.6f},log10 error {math.log10(err):.3f},k x error {k * err:.4f}")
    assert 0 < err <= 2 / k and abs(err - err2) < 1e-12
t, p, e = 1 / 3, 0.0, math.sqrt(1 / 3)
for k in range(1, 17):
    p, e = p + (t - p * p) / 2, e * (1 - math.sqrt(t) + e / 2)
    if k in (1, 4, 8, 16): print(f"spectrum of V/6 is {{1/3, 1}}: error at t = 1/3 after k = {k:2d} steps {math.sqrt(t) - p:.3e}")
    assert abs(math.sqrt(t) - p - e) < 1e-12

print("4. what breaks")
L = [[2.0, 0.0], [1.0, math.sqrt(3)]]
print(f"Cholesky L = {mat(L)}: L L* = {mat(mul(L, tr(L)))}, but L^2 = {mat(mul(L, L))}")
E = [[math.sqrt(V[i][j]) for j in range(2)] for i in range(2)]
print(f"entry-by-entry roots {mat(E)} square to {mat(mul(E, E))}")
assert gap(mul(L, tr(L)), V) < 1e-12 and gap(mul(L, L), V) > 1 and gap(mul(E, E), V) > 1
print(f"B has spectrum {{1}}, so a root read off the spectrum alone is I; I^2 - B has largest entry {gap(I, B):.0f}")
Bn = B
for k in range(7):
    print(f"Gelfand: |B^{2 ** k}|^(1/{2 ** k}) = {root2k(norm(Bn), k):.6f}")
    Bn = mul(Bn, Bn)
x = {0: 1, 1: 1, 2: -1}                  # l^1 on the integers, mirror x*(n) = conj x(-n)
xx = {}
for a, ca in x.items():
    for b, cb in x.items(): xx[b - a] = xx.get(b - a, 0) + ca * cb
xhat = 0.0                               # |1 + z - z^2| on the unit circle
for j in range(100000):
    th = 2 * math.pi * j / 100000
    re, im = 1 + math.cos(th) - math.cos(2 * th), math.sin(th) - math.sin(2 * th)
    xhat = max(xhat, math.sqrt(re * re + im * im))
n1, n2 = sum(abs(c) for c in x.values()), sum(abs(c) for c in xx.values())
print(f"l^1: x = d0 + d1 - d2: |x|_1 = {n1}, |x* x|_1 = {n2}, |x|_1^2 = {n1 * n1}; sup |x^| on the circle = {xhat:.6f}")
assert n2 == 5 and n1 * n1 == 9 and abs(xhat - math.sqrt(5)) < 1e-9
print("ALL CHECKS PASS")
