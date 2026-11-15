# Spectrum and resolvent -- the check behind the card.  Standard library only.
# The delay line S moves a signal one sample later: S(x0, x1, ...) = (0, x0, x1, ...).
# Code holds only truncations, the first N samples.  Inverses, norms and least
# squares are written out here; nothing imported already knows the answer.
from math import sqrt, log10, sin, pi

def f6(t): return f"{t:.6f}"
def dot(a, b):                       # plain running sum, so Python and Rust add in the same order
    s = 0.0
    for p, q in zip(a, b):
        s += p * q
    return s
def size(x): return sqrt(dot(x, x))

def minus_shift(lam, x):             # (lam I - S) x; the delayed copy spills one sample
    return [lam * a - b for a, b in zip(x + [0.0], [0.0] + x)]

def echo(lam, y, steps):             # solve (lam I - S) x = y sample by sample: x_n = (y_n + x_{n-1}) / lam
    x, prev = [], 0.0
    for n in range(steps):
        prev = ((y[n] if n < len(y) else 0.0) + prev) / lam
        x.append(prev)
    return x

def trunc_inverse(lam, N):           # (lam I - S_N)^-1 by forward substitution, one column at a time
    X = [[0.0] * N for _ in range(N)]
    for k in range(N):
        for j in range(N):
            X[j][k] = ((1.0 if j == k else 0.0) + (X[j - 1][k] if j > 0 else 0.0)) / lam
    return X

def matmul(A, B): return [[dot(A[i], [r[j] for r in B]) for j in range(len(B[0]))] for i in range(len(A))]

def opnorm(A, iters=300):            # largest stretch of A: power iteration on A^T A
    n, x = len(A), [1.0] * len(A)
    for _ in range(iters):
        y = [dot(A[i], x) for i in range(n)]
        z = [dot([A[i][j] for i in range(n)], y) for j in range(n)]
        s = size(z)
        x = [t / s for t in z]
    return size([dot(A[i], x) for i in range(n)])

def distance_to_range(lam, M):       # least squares: min ||(lam I - S) x - e0||, x on M samples
    d, o = lam * lam + 1.0, -lam     # normal equations: tridiagonal, solved by elimination (Thomas)
    b = [lam] + [0.0] * (M - 1)
    c, r = [0.0] * M, [0.0] * M
    c[0], r[0] = o / d, b[0] / d
    for i in range(1, M):
        m = d - o * c[i - 1]
        c[i], r[i] = o / m, (b[i] - o * r[i - 1]) / m
    x = [0.0] * M
    x[M - 1] = r[M - 1]
    for i in range(M - 2, -1, -1):
        x[i] = r[i] - c[i] * x[i + 1]
    res = minus_shift(lam, x)
    res[0] -= 1.0
    return size(res)

def ones_ratio(lam, M): return size(minus_shift(lam, [1.0] * M)) / sqrt(M)
def echo_ratio(lam, M): return size(echo(lam, [1.0] * M, M + 400)) / sqrt(M)

print("delay line S on l2: one-sided signals of finite energy; code holds the first N samples")
print("-- outside the disc: a feedback echo with gain 1/lam")
r2 = echo(2.0, [1.0], 60)
print("lam = 2.00, R(2) e0 first five samples:", " ".join(f"{t:.5f}" for t in r2[:5]), "| size", f6(size(r2)), "| sqrt(1/3)", f6(sqrt(1 / 3)))
for lam in (2.0, 1.25):
    bound = 1 / (lam - 1)
    tests = [echo_ratio(lam, M) for M in (10, 100, 1000)]
    print(f"lam = {lam:.2f}: Neumann bound 1/(|lam| - 1) = {f6(bound)}; ones-block test M = 10, 100, 1000:", " ".join(f6(t) for t in tests))
    assert all(t <= bound + 1e-12 for t in tests) and bound - tests[-1] < 0.02 * bound
N = 6
Ra, Rb = trunc_inverse(2.0, N), trunc_inverse(1.25, N)
P = matmul(Ra, Rb)
gap = max(abs(Ra[i][j] - Rb[i][j] - (1.25 - 2.0) * P[i][j]) for i in range(N) for j in range(N))
closed = max(abs(Ra[j][k] - (2.0 ** -(j - k + 1) if j >= k else 0.0)) for j in range(N) for k in range(N))
print(f"resolvent identity, N = 6: R(2) - R(1.25) at (0,0) = {f6(Ra[0][0] - Rb[0][0])}; (1.25 - 2) R(2) R(1.25) = {f6(-0.75 * P[0][0])}; gap below 1e-14: {'yes' if gap < 1e-14 else 'no'}")
print(f"forward substitution against the formula lam^-(j-k+1): gap below 1e-15: {'yes' if closed < 1e-15 else 'no'}")
assert gap < 1e-14 and closed < 1e-15
print("-- no eigenvalues")
x0 = [0.0] * 8
x0[7] = 1.0
print(f"truncated S_8 sends e7 to {f6(size(minus_shift(0.0, x0)[:8]))}, so 0 is its eigenvalue; the true S sends e7 to size {f6(size(minus_shift(0.0, x0)))}")
assert size(minus_shift(0.0, x0)[:8]) == 0.0 and size(minus_shift(0.0, x0)) == 1.0
print("-- inside the disc, lam = 0.5: residual spectrum")
blow = echo(0.5, [1.0], 5)
print("echo of e0 at lam = 0.5:", " ".join(f"{t:.0f}" for t in blow), "... doubling, infinite energy")
v = [0.5 ** n for n in range(60)]
w = minus_shift(0.5, [3.0, -1.0, 4.0, 1.0, -5.0])
print(f"obstruction v = (1, 0.5, 0.25, ...): <v, (0.5 I - S) x> for x = (3, -1, 4, 1, -5) = {f6(dot(v, w))}")
adj = max(abs(v[n + 1] - 0.5 * v[n]) for n in range(59))
print(f"left shift S* v - 0.5 v, largest entry = {f6(adj)}; ||v||^2 = {f6(size(v) ** 2)}")
dists = [distance_to_range(0.5, M) for M in (3, 24, 99)]
print("distance from e0 to the range, least squares M = 3, 24, 99:", " ".join(f6(t) for t in dists), "| closed form sqrt(1 - lam^2) =", f6(sqrt(0.75)))
assert abs(dists[-1] - sqrt(0.75)) < 1e-12 and abs(dot(v, w)) < 1e-15 and adj < 1e-15 and abs(size(v) ** 2 - 4 / 3) < 1e-12
low = [ones_ratio(0.5, M) for M in (2, 200, 20000)]
print("bounded below: ||(0.5 I - S) x|| / ||x|| on ones blocks M = 2, 200, 20000:", " ".join(f6(t) for t in low), "| never below 1 - |lam| = 0.5")
assert all(t >= 0.5 for t in low)
print("-- on the circle, lam = 1: continuous spectrum")
print("echo of e0 at lam = 1:", " ".join(f"{t:.0f}" for t in echo(1.0, [1.0], 5)), "... never decays, infinite energy")
d1 = [distance_to_range(1.0, M) for M in (3, 24, 99)]
print("distance from e0 to the range, least squares M = 3, 24, 99:", " ".join(f6(t) for t in d1), "| 1/sqrt(M + 1) =", " ".join(f6(1 / sqrt(M + 1)) for M in (3, 24, 99)))
assert all(abs(d - 1 / sqrt(M + 1)) < 1e-12 for d, M in zip(d1, (3, 24, 99)))
c1 = [ones_ratio(1.0, M) for M in (2, 200, 20000)]
print("||(I - S) x|| / ||x|| on ones blocks M = 2, 200, 20000:", " ".join(f6(t) for t in c1), "| sqrt(2/M) ->", f6(sqrt(2 / 20000)))
assert abs(c1[-1] - 0.01) < 1e-12
print("-- the truncation's honesty: ||(lam I - S_N)^-1|| by power iteration")
Ns, table = (5, 10, 20, 40), {}
for lam in (0.5, 1.0, 1.25, 2.0):
    table[lam] = [opnorm(trunc_inverse(lam, n)) for n in Ns]
    print(f"lam = {lam:.2f}, N = 5, 10, 20, 40:", " ".join(f"{t:.4f}" if t < 1e9 else f"{t:.6e}" for t in table[lam]))
    print(f"   log10:", " ".join(f"{log10(t):.3f}" for t in table[lam]))
sine = [1 / (2 * sin(pi / (4 * n + 2))) for n in Ns]
print("lam = 1 closed form 1/(2 sin(pi/(4N + 2))):", " ".join(f"{t:.4f}" for t in sine))
assert all(abs(a - b) < 1e-9 * b for a, b in zip(table[1.0], sine))
assert all(abs(t / (4 / 3 * 2.0 ** n) - 1) < 0.01 for t, n in zip(table[0.5], Ns))
assert all(a < b <= 1.0 for a, b in zip(table[2.0], table[2.0][1:]))
print("-- spectral radius r = lim ||T^n||^(1/n)")
sig = [1.0, -2.0, 0.5]
grown = sig
for n in range(5):
    grown = [0.0] + grown
print(f"S is an isometry: ||S^5 x|| / ||x|| = {f6(size(grown) / size(sig))}, so ||S^n||^(1/n) = 1 and r(S) = 1")
last = [1.0] * 8
for n in range(8):
    last = minus_shift(0.0, last)[:8]
print(f"truncated S_8: eight delays push every sample off the end, ||S_8^8 x|| = {f6(size(last))}, so r(S_8) = 0")
assert abs(size(grown) / size(sig) - 1) < 1e-15 and size(last) == 0.0
print("-- what breaks")
tail = size(echo(0.5, [1.0], 10))
print(f"Neumann series at lam = 0.5, ten terms on e0: size {tail:.1f}, and growing")
dets = [(t / 100) ** 2 + 1 for t in range(-300, 301)]   # det(lam I - A) for the quarter turn A
print(f"quarter turn [[0, -1], [1, 0]]: smallest det(lam I - A) = lam^2 + 1 over real lam in [-3, 3] is {f6(min(dets))}; roots i and -i")
assert min(dets) == 1.0
assert abs(tail - sqrt(4 * (4 ** 10 - 1) / 3)) < 1e-9
print("figure, unit 80 px, centre and lam = 0 at (180, 160); lam = 0.5 at (220, 160), 1 at (260, 160), 1.25 at (280, 160), 2 at (340, 160); safe disc round 2, radius 1/||R(2)|| = 80 px")
print("ALL CHECKS PASS")
