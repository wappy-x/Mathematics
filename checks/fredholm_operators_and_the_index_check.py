# Fredholm index: the check behind the card.  Standard library only.
# Every computation is a finite section of an infinite operator; the trend over N
# carries the infinite-dimensional answer.  Ranks are exact (integer elimination).
from math import cos, sin, pi, exp, gcd

def rank(A):                        # exact rank of an integer matrix, row by row
    M = [r[:] for r in A]; rk = 0
    for c in range(len(M[0])):
        p = next((i for i in range(rk, len(M)) if M[i][c] != 0), None)
        if p is None: continue
        M[rk], M[p] = M[p], M[rk]
        for i in range(rk + 1, len(M)):
            row = [M[rk][c] * M[i][j] - M[i][c] * M[rk][j] for j in range(len(M[0]))]
            g = 0
            for v in row: g = gcd(g, abs(v))
            M[i] = [v // g for v in row] if g else row
        rk += 1
    return rk

def zeros(r, c): return [[0] * c for _ in range(r)]
def shift(r, c, k):                 # delay by k: column j has a 1 in row j + k
    A = zeros(r, c)
    for j in range(c):
        if j + k < r: A[j + k][j] = 1
    return A
def transpose(A): return [list(x) for x in zip(*A)]
def mul(A, B): return [[sum(A[i][t] * B[t][j] for t in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def index_row(name, A):
    r = rank(A); ker = len(A[0]) - r; cok = len(A) - r
    print(f"{name:<34}{len(A)}x{len(A[0])}  ker {ker}  coker {cok}  index {ker - cok:+d}")
    return ker - cok

N = 6
print("Finite sections of the delay line S on an endless clip (exact ranks)")
S = shift(N + 1, N, 1); adv = transpose(shift(N + 1, N, 1))      # advance = S* = S transposed
iS = index_row("S, delay by one", S)
iA = index_row("advance S*", adv)
iS3 = index_row("S^3, delay by three", shift(N + 3, N, 3))
iA2 = index_row("advance twice", transpose(shift(N + 3, N + 1, 2)))
P = mul(transpose(shift(N + 3, N + 1, 2)), shift(N + 3, N, 3))
iP = index_row("advance twice after S^3", P)
assert P == S and iP == iA2 + iS3 == -1 and iA == 1 and iS == -1
SK = [row[:] for row in S]; SK[0][0] = 1                        # K x = x1 e1, rank one
iSK = index_row("S + K, K x = x1 e1", SK)
y = [1, -1] + [0] * (N - 1)                                      # the direction S + K misses
assert iSK == -1 and all(sum(y[i] * SK[i][j] for i in range(N + 1)) == 0 for j in range(N))
iH = index_row("2(S - 0.5), inside the circle", [[2 * S[i][j] - (i == j) for j in range(N)] for i in range(N + 1)])
iT = index_row("S - 2, outside the circle", [[S[i][j] - 2 * (i == j) for j in range(N)] for i in range(N + 1)])
iQ = index_row("S cut square", shift(N, N, 1))
assert iH == iT == -1 and iQ == 0
eye = lambda n: [[int(i == j) for j in range(n)] for i in range(n)]
r2 = rank([[x - z for x, z in zip(a, b)] for a, b in zip(mul(S, adv), eye(N + 1))])
print(f"parametrix: advance S = I is {mul(adv, S) == eye(N)}; S advance - I has rank {r2} (minus the projection on e1)")
assert mul(adv, S) == eye(N) and r2 == 1

def count_below(a, b, t):          # Sturm count: eigenvalues < t of a symmetric tridiagonal matrix
    q, n = a[0] - t, int(a[0] - t < 0)
    for i in range(1, len(a)):
        q = a[i] - t - b[i - 1] ** 2 / (q if q != 0 else 1e-300)
        n += q < 0
    return n
def smallest_stretch(lam, n):      # smallest singular value of the (n+1) x n section of S - lam
    cols = [[(-lam if i == j else 1.0 if i == j + 1 else 0.0) for i in range(n + 1)] for j in range(n)]
    a = [sum(v * v for v in c) for c in cols]
    b = [sum(u * v for u, v in zip(cols[j], cols[j + 1])) for j in range(n - 1)]
    lo, hi = 0.0, (1 + abs(lam)) ** 2
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if count_below(a, b, mid) >= 1 else (mid, hi)
    return ((lo + hi) / 2) ** 0.5
print("Smallest stretch of the section of S - lam (closed range test); closed form agrees")
chart = {0.5: [], 1.0: [], 2.0: []}
for n in [5, 10, 20, 40, 80, 160]:
    vals = []
    for lam in [0.5, 1.0, 2.0]:
        s = smallest_stretch(lam, n)
        exact = (1 + lam * lam - 2 * lam * cos(pi / (n + 1))) ** 0.5
        assert abs(s - exact) < 1e-9
        chart[lam].append(s); vals.append(s)
    print(f"N={n:<4} lam 0.5: {vals[0]:.4f}  lam 1: {vals[1]:.4f} (x (N+1)/pi = {vals[1] * (n + 1) / pi:.4f})  lam 2: {vals[2]:.4f}")
assert abs(chart[1.0][-1] * 161 / pi - 1) < 1e-4 and chart[0.5][-1] > 0.49 and chart[2.0][-1] > 0.99
print(f"Missed direction (1, lam, lam^2, ...): energy share in the first 5 entries / at the cut; endless energy at lam 0.5: {sum(0.25 ** j for j in range(200)):.6f}")
for n in [5, 10, 20]:
    out = []
    for lam in [0.5, 2.0]:
        w = [lam ** (2 * j) for j in range(n + 1)]
        A = [[(-lam if i == j else 1.0 if i == j + 1 else 0.0) for j in range(n)] for i in range(n + 1)]
        yv = [lam ** j for j in range(n + 1)]
        assert all(sum(yv[i] * A[i][j] for i in range(n + 1)) == 0 for j in range(n))
        out += [sum(w[:5]) / sum(w), w[-1] / sum(w)]
    print(f"N={n:<3} lam 0.5: first 5 {out[0]:.6f}, at cut {out[1]:.6f}   lam 2: first 5 {out[2]:.6f}, at cut {out[3]:.6f}")
assert out[0] > 0.999 and out[3] > 0.74

print("Multiplication by x on L2[0, 1] plus K u = c <1, u> 1, midpoint grid of N points")
def grid_count(n, c, t):           # eigenvalues < t of diag(x) + (c/n) 1 1^T, by pivots
    s, neg = 1.0, 0
    for i in range(n):
        d = (i + 0.5) / n - t
        p = d + s * c / n
        neg += p < 0
        s = s * d / p
    return neg
def top_secular(n, c):
    lo, hi = (n - 0.5) / n + 1e-15, 1 + abs(c) + 1
    for _ in range(200):
        mid = (lo + hi) / 2
        f = 1 - c / n * sum(1 / (mid - (i + 0.5) / n) for i in range(n))
        lo, hi = (lo, mid) if f > 0 else (mid, hi)
    return (lo + hi) / 2
def top_count(n, c):
    lo, hi = 1.0, 3.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if grid_count(n, c, mid) == n else (mid, hi)
    return (lo + hi) / 2
c = 1.0
lam_star = 1 / (1 - exp(-1 / c))
print(f"closed form, 1 = c ln(lam/(lam - 1)): lam = 1/(1 - {exp(-1 / c):.6f}) = 1/{1 - exp(-1 / c):.6f} = {lam_star:.6f}")
for n in [10, 100, 1000]:
    a, b = top_secular(n, c), top_count(n, c)
    assert abs(a - b) < 1e-9 and abs(a - lam_star) < 1 / n ** 2
    print(f"N={n:<5} top eigenvalue {a:.6f} (secular) {b:.6f} (pivots)  error x N^2 {(a - lam_star) * n * n:+.4f}")
for n in [100, 1000, 10000]:
    below, above = grid_count(n, c, 0.0), n - grid_count(n, c, 1.0)
    mid = grid_count(n, c, 0.6) - grid_count(n, c, 0.4)
    print(f"N={n:<6} below 0: {below}   above 1: {above}   in [0.4, 0.6]: {mid}   without K, above 1: {n - grid_count(n, 0.0, 1.0)}")
    assert below == 0 and above == 1 and abs(mid - 0.2 * n) <= 1
lo, hi = -3.0, 0.0                 # c = -1: the bound state moves below the band
for _ in range(100):
    mid = (lo + hi) / 2
    lo, hi = (lo, mid) if grid_count(1000, -1.0, mid) >= 1 else (mid, hi)
print(f"c = -1, N=1000: one eigenvalue below 0, at {lo:.6f}; closed form -1/(e - 1) = {-1 / (exp(1.0) - 1):.6f}")
assert grid_count(1000, -1.0, 0.0) == 1 and abs(lo + 1 / (exp(1.0) - 1)) < 1e-5
print(f"figure, circle centre 120 120 radius 80; band 270.0 to 390.0; eigenvalue at {270 + 120 * lam_star:.3f}")
print("ALL CHECKS PASS")
