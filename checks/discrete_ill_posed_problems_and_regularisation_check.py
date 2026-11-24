# Deblurring a 64-channel spectrum. Roads: singular values by a cosine sum, by aliasing and by
# Jacobi on A; Tikhonov by filter factors against Cholesky on (A^T A + lam^2 I) x = A^T b.
import math
def sm(v):  # plain left-to-right sum, so Python and Rust add in the same order
    t = 0.0
    for a in v: t += a
    return t
def E(x, d):  # e-notation written the same way in both languages
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
n, s, dl = 64, 2.0, 1e-3
g = [math.exp(-min(j, n - j) ** 2 / (2 * s * s)) for j in range(n)]
g = [v / sm(g) for v in g]
A = [[g[(i - j) % n] for j in range(n)] for i in range(n)]
xt = [math.exp(-(j - 26) ** 2 / 8) + 0.6 * math.exp(-(j - 34) ** 2 / 8) for j in range(n)]
st, M64 = 0x2026, 2**64 - 1
def rnd():  # SplitMix64, seed 0x2026, uniform on [0, 1)
    global st
    st = (st + 0x9E3779B97F4A7C15) & M64
    z = ((st ^ (st >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
mv = lambda v: [sm(A[i][j] * v[j] for j in range(n)) for i in range(n)]
nrm = lambda v: math.sqrt(sm(t * t for t in v))
dot = lambda u, v: sm(p * q for p, q in zip(u, v))
sub = lambda u, v: [p - q for p, q in zip(u, v)]
noise = [dl * (sm(rnd() for _ in range(12)) - 6.0) for _ in range(n)]
b = [p + q for p, q in zip(mv(xt), noise)]
K, U = [], []  # real Fourier vectors: the singular vectors of a symmetric circulant blur
for k in range(n // 2 + 1):
    for f in (math.cos, math.sin) if 0 < k < n // 2 else (math.cos,):
        u = [f(2 * math.pi * k * j / n) for j in range(n)]
        K.append(k); U.append([t / nrm(u) for t in u])
sig = [sm(g[j] * math.cos(2 * math.pi * k * j / n) for j in range(n)) for k in K]
c, cn = [dot(u, b) for u in U], [dot(u, noise) for u in U]
ali = 2 * math.exp(-math.pi * math.pi * s * s / 2)
print(f"sigma_max {sig[0]:.6f}  sigma_min {E(sig[-1], 4)}  kappa {E(sig[0] / sig[-1], 4)}")
print(f"aliasing estimate 2exp(-pi^2 s^2/2) {E(ali, 4)}")
assert abs(sig[-1] - ali) / ali < 1e-6
B = [row[:] for row in A]  # road 2: cyclic Jacobi rotations until A is diagonal
for sweep in range(12):
    for p in range(n - 1):
        for q in range(p + 1, n):
            if B[p][q] == 0.0: continue
            th = (B[q][q] - B[p][p]) / (2 * B[p][q])
            t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1))
            cs = 1 / math.sqrt(t * t + 1); sn = t * cs
            for r in range(n):
                B[r][p], B[r][q] = cs * B[r][p] - sn * B[r][q], sn * B[r][p] + cs * B[r][q]
            for r in range(n):
                B[p][r], B[q][r] = cs * B[p][r] - sn * B[q][r], sn * B[p][r] + cs * B[q][r]
ev = sorted(B[i][i] for i in range(n))
gap = max(abs(a - e) for a, e in zip(sorted(sig), ev))
print(f"jacobi, 12 sweeps: largest |closed form - jacobi| {E(gap, 1)}, smallest {E(ev[0], 4)}")
assert gap < 1e-13
pc = [math.sqrt(sm(c[i] * c[i] for i in range(n) if K[i] == k) / K.count(k)) for k in range(33)]  # rms share of each cos-sin pair
print("picard: k  sigma_k  |cos share|  |sin share|  rms share  rms/sigma")
for k in (0, 4, 8, 12, 16, 20, 24, 28, 32):
    i = K.index(k)
    print(f"  {k:2d}  {E(sig[i], 2)}  {E(abs(c[i]), 2)}  {E(abs(c[i + 1]), 2) if 0 < k < 32 else '-'}  {E(pc[k], 2)}  {E(pc[k] / sig[i], 2)}")
for name, v in (("log10 sigma", sig), ("log10 rms share", [pc[k] for k in K])):
    print(f"chart {name}:", " ".join(f"{math.log10(v[K.index(k)]):.2f}" for k in range(0, 33, 2)))
print(f"chart noise per coefficient: log10 {E(dl, 0)} = {math.log10(dl):.2f}")
def tik(lam, cc=c):  # filter factors f_i, then x = sum f_i c_i / sigma_i u_i
    f = [sg * sg / (sg * sg + lam * lam) for sg in sig]
    x = [sm(f[i] * cc[i] / sig[i] * U[i][j] for i in range(n)) for j in range(n)]
    return x, math.sqrt(sm(((1 - f[i]) * cc[i]) * ((1 - f[i]) * cc[i]) for i in range(n))), f
err = lambda x: nrm(sub(x, xt)) / nrm(xt)
xn, rn, _ = tik(0.0)
print(f"|x_true| {nrm(xt):.4f}  |noise| {nrm(noise):.5f}  |A x - b| of plain solve {E(nrm(sub(mv(xn), b)), 1)}")
print(f"plain solve: error {E(nrm(sub(xn, xt)), 4)}  bound |noise|/sigma_min {E(nrm(noise) / sig[-1], 4)}"
      f"  bound/true {nrm(noise) / sig[-1] / nrm(sub(xn, xt)):.2f}")
def dp(target):  # bisection on log10 lambda: the residual grows with lambda
    lo, hi = -10.0, 0.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if tik(10 ** mid)[1] < target else (lo, mid)
    return 10 ** lo
target = math.sqrt(n) * dl
lam = dp(target)
xd, rd, fd = tik(lam)
print(f"discrepancy target sqrt(64) x 1e-3 = {target:.4f}  lambda_DP {E(lam, 4)}")
print(f"  residual by formula {rd:.6f}  by A x - b {nrm(sub(mv(xd), b)):.6f}  rel error {err(xd):.4f}")
assert abs(rd - target) < 1e-9 and abs(nrm(sub(mv(xd), b)) - rd) < 1e-12
xe = tik(lam, cn)[0]
print(f"  noise gain {nrm(xe) / nrm(noise):.3f}  bound 1/(2 lambda) {1 / (2 * lam):.3f}  bound/true {nrm(noise) / (2 * lam * nrm(xe)):.2f}")
assert nrm(xe) / nrm(noise) <= 1 / (2 * lam)
for m in (10.0, 1.0, 0.1):
    print(f"filter factor at sigma = {m:g} lambda: {m * m / (m * m + 1):.4f}")
print(f"factor > 0.5 for {sum(1 for f in fd if f > 0.5)} of {n}, frequencies 0..{max(k for k, f in zip(K, fd) if f > 0.5)}; sigma_12 {sig[K.index(12)]:.6f}; factor at k = 8, 12, 16:",
      " ".join(f"{fd[K.index(k)]:.4f}" for k in (8, 12, 16)))
for j in (26, 30, 34):
    print(f"channel {j}: true {xt[j]:.4f}  blurred {b[j]:.4f}  Tikhonov {xd[j]:.4f}")
N = [[sm(A[r][i] * A[r][j] for r in range(n)) + (lam * lam if i == j else 0.0) for j in range(n)] for i in range(n)]
L = [[0.0] * n for _ in range(n)]  # road 3: Cholesky of A^T A + lam^2 I
for i in range(n):
    for j in range(i + 1):
        t = N[i][j] - sm(L[i][q] * L[j][q] for q in range(j))
        L[i][j] = math.sqrt(t) if i == j else t / L[j][j]
y, xc = [0.0] * n, [0.0] * n
for i in range(n):
    y[i] = (sm(A[r][i] * b[r] for r in range(n)) - sm(L[i][q] * y[q] for q in range(i))) / L[i][i]
for i in reversed(range(n)):
    xc[i] = (y[i] - sm(L[q][i] * xc[q] for q in range(i + 1, n))) / L[i][i]
dif = nrm(sub(xc, xd)) / nrm(xd)
print(f"cholesky against filter formula: relative difference {E(dif, 1)}")
assert dif < 1e-10
for kc in range(33):  # TSVD: keep frequencies 0..kc, smallest kc meeting the target
    keep = [k <= kc for k in K]
    rt = math.sqrt(sm(c[i] * c[i] for i in range(n) if not keep[i]))
    if rt <= target:
        break
xk = [sm(c[i] / sig[i] * U[i][j] for i in range(n) if keep[i]) for j in range(n)]
print(f"TSVD by discrepancy: frequencies 0..{kc}, {sum(keep)} components, residual {rt:.5f}"
      f" (A x - b {nrm(sub(mv(xk), b)):.5f}), rel error {err(xk):.4f}")
grid = [-6 + 0.05 * i for i in range(121)]  # L-curve and GCV, lambda = 10^grid
rho, eta, gcv, ers = [], [], [], []
for e in grid:
    x, r, f = tik(10 ** e)
    rho.append(math.log10(r)); eta.append(math.log10(nrm(x)))
    gcv.append(r * r / ((n - sm(f)) * (n - sm(f)))); ers.append(err(x))
cur = [-1e300] * 121
for i in range(1, 120):
    r1, e1 = (rho[i + 1] - rho[i - 1]) / 0.1, (eta[i + 1] - eta[i - 1]) / 0.1
    r2, e2 = (rho[i + 1] - 2 * rho[i] + rho[i - 1]) / 0.0025, (eta[i + 1] - 2 * eta[i] + eta[i - 1]) / 0.0025
    cur[i] = (r1 * e2 - r2 * e1) / (r1 * r1 + e1 * e1) ** 1.5
pick = [("L-curve corner", cur.index(max(cur))), ("GCV minimum", gcv.index(min(gcv))),
        ("best possible, needs x_true", ers.index(min(ers)))]
for name, i in pick:
    print(f"{name}: lambda {E(10 ** grid[i], 2)}  residual {10 ** rho[i]:.5f}  rel error {ers[i]:.4f}")
assert ers[pick[1][1]] < 2 * ers[pick[2][1]] < ers[pick[0][1]] and err(xd) < 1.1 * ers[pick[2][1]]
print("chart log10 lambda:", " ".join(f"{grid[i]:.1f}" for i in range(0, 121, 10)))
print("chart log10 residual:", " ".join(f"{rho[i]:.2f}" for i in range(0, 121, 10)))
print("chart log10 |x|:", " ".join(f"{eta[i]:.2f}" for i in range(0, 121, 10)))
for l in (1e-6, math.sqrt(lam)):
    print(f"what breaks: lambda {E(l, 2)}  rel error {err(tik(l)[0]):.4f}  height at 26 {tik(l)[0][26]:.4f}")
l1 = dp(dl)
print(f"what breaks: target 1e-3, no sqrt(64): lambda {E(l1, 2)}  rel error {err(tik(l1)[0]):.4f}")
print(f"cost per lambda: cholesky n^3/3 + 2n^2 = {n ** 3 // 3 + 2 * n * n} flops; filter route 2n^2 + 4n = {2 * n * n + 4 * n}")
print("ALL CHECKS PASS")
