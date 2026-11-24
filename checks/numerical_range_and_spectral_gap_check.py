# Numerical range and spectral gap -- the check behind the card.  Standard library only.
# Complex numbers are (re, im) pairs.  Eigenvalues, norms, exponentials and the heat
# flow are written out here; nothing imported already knows an answer.
from math import sqrt, sin, cos, exp, log, pi, asin, atan2

def f6(t): return f"{t:.6f}"
def cm(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])
def ca(a, b): return (a[0] + b[0], a[1] + b[1])
def cx(A): return [[(a, 0.0) for a in row] for row in A]
def size(z): return sqrt(z[0] * z[0] + z[1] * z[1])
def ip(x, y):                          # <x, y>, conjugating the first slot
    s = (0.0, 0.0)
    for a, b in zip(x, y):
        s = ca(s, cm((a[0], -a[1]), b))
    return s
def mul(T, x):                         # T x for a complex 2 x 2 matrix
    return [ca(cm(row[0], x[0]), cm(row[1], x[1])) for row in T]
def avg(T, x):                         # the average <x, Tx> / <x, x>
    q, n = ip(x, mul(T, x)), ip(x, x)[0]
    return (q[0] / n, q[1] / n)
def unit(al, ph): return [(cos(al), 0.0), (sin(al) * cos(ph), sin(al) * sin(ph))]
def sample(T):                         # averages over a grid of 361 x 360 unit vectors
    return [avg(T, unit(k * pi / 720, m * pi / 180)) for k in range(361) for m in range(360)]
def top(T, th):                        # top eigenvalue of the Hermitian part of e^(i th) T
    M = [[cm((cos(th), sin(th)), t) for t in row] for row in T]
    a, d = M[0][0][0], M[1][1][0]
    br, bi = (M[0][1][0] + M[1][0][0]) / 2, (M[0][1][1] - M[1][0][1]) / 2
    return (a + d) / 2 + sqrt(((a - d) / 2) ** 2 + br * br + bi * bi)
def norm(A):                           # largest stretch of a real 2 x 2: power iteration on A^T A
    v = [1.0, 0.3]
    for _ in range(400):
        w = [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]]
        v = [A[0][0] * w[0] + A[1][0] * w[1], A[0][1] * w[0] + A[1][1] * w[1]]
        s = sqrt(v[0] * v[0] + v[1] * v[1]); v = [v[0] / s, v[1] / s]
    w = [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]]
    return sqrt(w[0] * w[0] + w[1] * w[1])

N, B, Q = [[0.0, 1.0], [0.0, 0.0]], [[1.0, 2.0], [0.0, -1.0]], [[0.0, -1.0], [1.0, 0.0]]
wN, nN = max(size(z) for z in sample(cx(N))), norm(N)
sup = [top(cx(N), k * pi / 180) for k in range(360)]
hit = avg(cx(N), unit(asin(2 * size((0.3, 0.2))) / 2, atan2(0.2, 0.3)))
res = norm([[1.0, 1.0], [0.0, 1.0]])
print("N: trace 0 and determinant 0, so l^2 = 0: spectrum {0}, spectral radius 0")
print(f"N: largest |<x, Nx>| over 129960 unit vectors: w(N) = {f6(wN)}")
print(f"N: top of Re(e^(i th) N) over 360 angles: min {f6(min(sup))}, max {f6(max(sup))}")
print(f"N: ||N|| = {f6(nN)}; w <= ||N|| <= 2w: {f6(wN)} <= {f6(nN)} <= {f6(2 * wN)}")
print(f"N: the point 0.3 + 0.2i as an average: {f6(hit[0])} + {f6(hit[1])}i")
print(f"N: ||(I - N)^-1|| = {f6(res)} (golden ratio {f6((1 + sqrt(5)) / 2)}) <= 1/dist(1, W) = {f6(1 / (1 - wN))}")
ell = max(abs(top(cx(B), k * pi / 4) - sqrt(2 * cos(k * pi / 4) ** 2 + sin(k * pi / 4) ** 2)) for k in range(8))
pts = sample(cx(B))
inside = all(p[0] * p[0] / 2 + p[1] * p[1] <= 1 + 1e-12 for p in pts)
wB, nB = max(size(p) for p in pts), norm(B)
print(f"B: foci 1 and -1, semi-axes {f6(sqrt(2))} and {f6(1.0)}; largest gap, support against ellipse: {f6(ell)}")
print(f"B: all 129960 averages inside the ellipse: {'yes' if inside else 'no'}; w(B) = {f6(wB)}")
print(f"B: ||B|| = {f6(nB)} (1 + sqrt 2 = {f6(1 + sqrt(2))}); w <= ||B|| <= 2w: {f6(wB)} <= {f6(nB)} <= {f6(2 * wB)}")
x, y = [(1.0, 0.0), (0.0, 0.0)], [(sqrt(0.5), 0.0), (0.0, sqrt(0.5))]
a, b = avg(cx(B), x), avg(cx(B), y)    # Step 3's path: T' = (B - aI)/(b - a) runs from 0 to 1
e = (b[0] - a[0], b[1] - a[1])
d = (e[0] / (e[0] * e[0] + e[1] * e[1]), -e[1] / (e[0] * e[0] + e[1] * e[1]))    # 1 / (b - a)
Tp = [[cm(ca(t, (-a[0], -a[1])) if i == j else t, d) for j, t in enumerate(row)] for i, row in enumerate(cx(B))]
g = ca(ip(x, mul(Tp, y)), (-ip(y, mul(Tp, x))[0], ip(y, mul(Tp, x))[1]))    # 2i <x, (Im T') y>
xr = [cm((cos(atan2(g[1], g[0])), sin(atan2(g[1], g[0]))), c) for c in x]
path = lambda t: [ca(cm((1 - t, 0.0), xr[i]), cm((t, 0.0), y[i])) for i in range(2)]
lo, hi = 0.0, 1.0
for _ in range(60):
    lo, hi = ((lo + hi) / 2, hi) if avg(Tp, path((lo + hi) / 2))[0] < 0.5 else (lo, (lo + hi) / 2)
mp = avg(cx(B), path(lo))
print(f"B: <e1, Be1> = {f6(a[0])}, <y, By> = {f6(b[1])}i; the path reaches {f6(mp[0])} + {f6(mp[1])}i")

def lap(u, M):                         # grid heat operator on M cells, insulated ends
    return [M * M * ((u[j - 1] if j > 0 else u[0]) - 2 * u[j] + (u[j + 1] if j < M - 1 else u[M - 1]))
            for j in range(M)]
def spread(u):                         # distance from the average, sqrt(h * sum of squares)
    m = sum(u) / len(u)
    return sqrt(sum((c - m) ** 2 for c in u) / len(u))
print("heat, grid of M cells: gap by power iteration, closed form 4M^2 sin^2(pi/2M), pi^2 - gap, times M^2")
gaps = []
for M in (4, 8, 16, 32, 64):
    v, c = [(j + 1.0) ** 3 for j in range(M)], 4.0 * M * M
    for _ in range(20000):             # power iteration on A + cI, constants projected out
        m = sum(v) / M; v = [t - m for t in v]
        Av = lap(v, M); v = [p + c * q for p, q in zip(Av, v)]
        s = sqrt(sum(t * t for t in v)); v = [t / s for t in v]
    m = sum(v) / M; v = [t - m for t in v]
    g = -sum(p * q for p, q in zip(v, lap(v, M))) / sum(t * t for t in v)
    cf = 4 * M * M * sin(pi / (2 * M)) ** 2
    gaps.append((g, cf, (pi * pi - cf) * M * M))
    print(f"  M = {M:2d}: {f6(g)}  {f6(cf)}  {f6(pi * pi - cf)}  {f6((pi * pi - cf) * M * M)}")
print(f"  limit pi^2 = {f6(pi * pi)}; the error times M^2 tends to pi^4/12 = {f6(pi ** 4 / 12)}")
M, dt, ts = 50, 1e-4, (1, 5, 10, 20, 30)
u, rows, chart = [1.0 if j < M // 2 else 0.0 for j in range(M)], [], []
for n in range(3001):
    if n % 500 == 0: chart.append((spread(u), 0.5 * exp(-pi * pi * n * dt)))
    if n % 100 == 0 and n // 100 in ts: rows.append((n * dt, spread(u)))
    Au = lap(u, M); u = [p + dt * q for p, q in zip(u, Au)]
g50 = 4 * M * M * sin(pi / (2 * M)) ** 2
print("hot left half, cold right half: t, grid M = 50, cosine series, bound 0.5 e^(-pi^2 t)")
for t, gr in rows:
    se = sqrt(sum(2 / (n * n * pi * pi) * exp(-2 * n * n * pi * pi * t) for n in range(1, 400, 2)))
    print(f"  {t:.2f}  {f6(gr)}  {f6(se)}  {f6(0.5 * exp(-pi * pi * t))}")
    assert abs(gr - se) < 2e-3 and se <= 0.5 * exp(-pi * pi * t) and gr <= 0.5 * exp(-g50 * t) + 1e-12
print("chart, t = 0, 0.05, ..., 0.3, grid:", ", ".join(f"{p:.4f}" for p, q in chart))
print("chart, bound:", ", ".join(f"{q:.4f}" for p, q in chart))
unit_s = 1 / 1.1e-4
print(f"1 m bar, kappa 1.1e-4 m^2/s: time unit {unit_s:.1f} s; settles by e in {unit_s / pi ** 2:.1f} s, "
      f"to 1% in {unit_s * log(100) / pi ** 2:.1f} s")
A = [[-1.0, 6.0], [0.0, -2.0]]
om = (-3 + sqrt(37)) / 2
omS = max(p[0] for p in sample(cx(A)))
def expA(t): return [[exp(-t), 6 * (exp(-t) - exp(-2 * t))], [0.0, exp(-2 * t)]]
def taylor(t):                         # sum of (tA)^k / k!, 60 terms
    S, P = [[1.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]]
    for k in range(1, 60):
        P = [[sum(P[i][l] * A[l][j] for l in range(2)) * t / k for j in range(2)] for i in range(2)]
        S = [[S[i][j] + P[i][j] for j in range(2)] for i in range(2)]
    return S
tay = max(abs(expA(0.3)[i][j] - taylor(0.3)[i][j]) for i in range(2) for j in range(2))
scan = [(norm(expA(k / 100)), k / 100) for k in range(301)]
pk = max(scan)
print(f"A = [[-1, 6], [0, -2]]: eigenvalues -1, -2; top of Re W: {f6(om)} closed form, {f6(omS)} sampled")
print(f"A: ||e^(0.3A)|| = {f6(norm(expA(0.3)))}; spectrum predicts {f6(exp(-0.3))}; bound e^(0.3 w) = {f6(exp(0.3 * om))}")
print(f"A: largest ||e^(tA)|| = {f6(pk[0])} at t = {pk[1]:.2f}; Taylor against closed form {f6(tay)}")
real = max(abs(avg(cx(Q), unit(k * pi / 720, 0.0))[0]) for k in range(1441))
wQ = max(size(p) for p in sample(cx(Q)))
print(f"quarter turn Q: trace 0, determinant 1, eigenvalues i and -i; real vectors give at most {f6(real)}; complex w(Q) = {f6(wQ)}")
print(f"figure, left: centre (160, 150), 120 px per unit, W(N) radius {120 * wN:.1f}, norm circle {120 * nN:.1f}; "
      f"right: centre (470, 150), 100 px per unit, rx {100 * sqrt(2):.1f}, ry {100 * 1.0:.1f}, "
      f"foci x {470 - 100 * 1.0:.1f} and {470 + 100 * 1.0:.1f}, midpoint ({470 + 100 * mp[0]:.1f}, {150 - 100 * mp[1]:.1f})")
assert abs(wN - max(sup)) < 1e-9 and abs(min(sup) - 0.5) < 1e-9       # sampling against support
assert abs(nN - 1) < 1e-9 and abs(nB - (1 + sqrt(2))) < 1e-9           # power iteration, closed form
assert abs(res - (1 + sqrt(5)) / 2) < 1e-9 and res <= 1 / (1 - wN)     # resolvent bound
assert inside and ell < 1e-12 and abs(wB - sqrt(2)) < 1e-9 and wB <= nB <= 2 * wB
assert abs(mp[0] - 0.5) < 1e-9 and abs(mp[1] - 0.5) < 1e-9           # convexity path
assert all(abs(g - cf) < 1e-6 for g, cf, e in gaps) and abs(gaps[-1][2] - pi ** 4 / 12) < 1e-2
assert abs(om - omS) < 1e-4 and tay < 1e-12 and pk[0] > 1 and all(n <= exp(t * om) + 1e-12 for n, t in scan)
assert real < 1e-15 and abs(wQ - 1) < 1e-9
print("ALL CHECKS PASS")
