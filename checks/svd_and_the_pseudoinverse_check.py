# SVD and the pseudoinverse -- the check behind the card.  Standard library only.
# A greenhouse logs 20 sensors every hour for 10 days (240 rows, 10 more days to test);
# the readings carry three hidden signals (sun, night heating, watering) plus noise.
# Road one: a one-sided Jacobi SVD.  Road two: power iteration, normal equations and
# Penrose's four conditions.  Road three: the known signal and noise the log was built from.
from math import sqrt, log10

S = [2026]
def nxt():                                   # SplitMix64, seed 2026
    S[0] = (S[0] + 0x9E3779B97F4A7C15) & (2**64 - 1); z = S[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return z ^ (z >> 31)
def unif(): return (nxt() >> 11) * 2.0**-53
def gauss(): return (2 * unif() - 1) + (2 * unif() - 1) + (2 * unif() - 1)   # mean 0, sd 1
def dot(x, y):                               # plain left-to-right sum, as in the Rust
    s = 0.0
    for a, b in zip(x, y): s += a * b
    return s
def nrm(x): return sqrt(dot(x, x))
def col(M, j): return [r[j] for r in M]
def mv(M, x): return [dot(r, x) for r in M]
def mtv(M, y): return [dot(col(M, j), y) for j in range(len(M[0]))]
def fro(M): return sqrt(dot([dot(r, r) for r in M], [1.0] * len(M)))
def sub(P, Q): return [[a - b for a, b in zip(p, q)] for p, q in zip(P, Q)]
def tr(M): return [col(M, j) for j in range(len(M[0]))]
def norm2(M):                                # largest singular value by power iteration
    x = [1.0] * len(M[0])
    for _ in range(400):
        z = mtv(M, mv(M, x)); nz = nrm(z); x = [v / nz for v in z]
    return nrm(mv(M, x))
def svd(A):                                  # one-sided Jacobi: rotate columns until orthogonal
    m, n = len(A), len(A[0])
    W, V = tr(A), [[float(i == j) for i in range(n)] for j in range(n)]
    fl, sweeps, rot = 0, 0, 1
    while rot:
        sweeps += 1; rot = 0
        for p in range(n - 1):
            for q in range(p + 1, n):
                a, b, c = dot(W[p], W[p]), dot(W[q], W[q]), dot(W[p], W[q]); fl += 6 * m
                if abs(c) <= 1e-15 * sqrt(a * b): continue
                z = (b - a) / (2 * c); t = (1.0 if z >= 0 else -1.0) / (abs(z) + sqrt(1 + z * z))
                cs = 1 / sqrt(1 + t * t); sn = cs * t; rot += 1; fl += 6 * (m + n)
                for X in (W, V):
                    xp, xq = X[p], X[q]
                    X[p] = [cs * u - sn * v for u, v in zip(xp, xq)]
                    X[q] = [sn * u + cs * v for u, v in zip(xp, xq)]
    s = [nrm(w) for w in W]
    o = sorted(range(n), key=lambda j: -s[j])
    return [s[j] for j in o], [[x / s[j] for x in W[j]] for j in o], [V[j] for j in o], sweeps, fl
def chol_solve(G, B):                        # G x = b for each b in B, G symmetric positive definite
    n = len(G); L = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            s = G[i][j] - dot(L[i][:j], L[j][:j])
            if i == j: L[i][i] = sqrt(s)
            else: L[i][j] = s / L[j][j]
    X = [list(b) for b in B]
    for y in X:                              # forward with L, then back with L transposed
        for i in range(n): y[i] = (y[i] - dot(L[i][:i], y[:i])) / L[i][i]
        for i in range(n - 1, -1, -1): y[i] = (y[i] - dot(col(L, i)[i + 1:], y[i + 1:])) / L[i][i]
    return X
def lowrank(s, U, V, k): return [[dot([s[i] * U[i][r] for i in range(k)], [V[i][j] for i in range(k)])
                                  for j in range(len(V[0]))] for r in range(len(U[0]))]
def e(x): return f"{x:.3e}"                  # three-digit e-notation, same in the Rust
def rms(x, M, b): r = [p - q for p, q in zip(mv(M, x), b)]; return sqrt(dot(r, r) / len(b))
def gap(x, y): return nrm([a - b for a, b in zip(x, y)]) / nrm(y)

base = [(1.0, 0.8, -0.2)] * 8 + [(-0.6, -0.2, 1.0)] * 6 + [(1.2, 0.0, 0.0)] * 4 + [(0.0, 0.0, 1.2)] * 2
Ld = [[base[j][k] + 0.3 * (2 * unif() - 1) for j in range(20)] for k in range(3)]   # loadings
days = [(0.6 + 0.4 * unif(), 0.5 + unif()) for _ in range(20)]                      # cloud, cold
sig = []
for t in range(480):
    h, (cl, co) = t % 24, days[t // 24]
    k = h - 6 if 6 <= h < 15 else (h - 15 if h >= 15 else h + 9); w = 1.0
    for _ in range(k): w *= 0.6                # moisture decays 40% an hour after watering
    sig.append((cl * max(0.0, 1 - (h - 13) / 6 * ((h - 13) / 6)), co if (h < 7 or h >= 19) else 0.0, w))
dlt = 0.01                                     # sensor noise, standard units (illustrative)
S0 = [[dot(sg, col(Ld, j)) for j in range(20)] for sg in sig]   # noise-free log, A0 on the card
E = [[dlt * gauss() for j in range(20)] for t in range(480)]
A = [[a + b for a, b in zip(p, q)] for p, q in zip(S0, E)]
y = [3 * s1 + s2 + 5 * s3 + 0.3 * gauss() for (s1, s2, s3) in sig]   # water use, L/h above base
At, Ate, yt, yte, St, Et, m, n = A[:240], A[240:], y[:240], y[240:], S0[:240], E[:240], 240, 20
s, U, V, sweeps, fl = svd(At)
s0, nE, eps = svd(St)[0], norm2(Et), 2.0**-52
print(f"log: m = {m} hours, n = {n} sensors, noise sd {dlt}; Jacobi sweeps {sweeps}, flops {fl}")
print(f"Householder QR of the same table: 2mn^2 - 2n^3/3 = {2*m*n*n - 2*n**3//3} flops; "
      f"Jacobi / QR = {fl / (2*m*n*n - 2*n**3//3):.1f}")
print("singular values 1-5:", " ".join(f"{v:.4f}" for v in s[:5]) + "\nsingular values 16-20:", " ".join(f"{v:.4f}" for v in s[15:]))
print("chart, log10 sigma_i:", " ".join(f"{log10(v):.2f}" for v in s))
tr_, tn = max(m, n) * eps * s[0], dlt * (sqrt(m) + sqrt(n))
r_round, r_noise = len([v for v in s if v > tr_]), len([v for v in s if v > tn])
print(f"rank, rounding tolerance max(m,n) eps sigma1 = {e(tr_)}: {r_round}")
print(f"rank, noise tolerance delta(sqrt m + sqrt n) = {tn:.4f} (log10 {log10(tn):.2f}): {r_noise}")
print(f"noise-free log: sigma_4 = {e(s0[3])}, rank at rounding tolerance {len([v for v in s0 if v > tr_])}")
wey = max(abs(a - b) for a, b in zip(s, s0))
print(f"||E||_2 = {nE:.4f}; Weyl: largest shift |sigma_i(A) - sigma_i(A0)| = {wey:.4f}, bound / shift {nE / wey:.3f}; tolerance / ||E||_2 {tn / nE:.3f}")
print(f"kappa_2(A) = sigma1/sigma20 = {s[0] / s[19]:.1f}; rank-3 part sigma1/sigma3 = {s[0] / s[2]:.2f}")
A3 = lowrank(s, U, V, 3)
cols = [col(At, j) for j in (0, 8, 14)]          # one temperature, humidity and light sensor
Z = chol_solve([[dot(a, b) for b in cols] for a in cols], [[dot(c, col(At, j)) for c in cols] for j in range(n)])
Csub = [[dot(col(cols, i), Z[j]) for j in range(n)] for i in range(m)]
fA, fbest, ftrue, fsub, sp = fro(At), fro(sub(At, A3)), fro(Et), fro(sub(At, Csub)), norm2(sub(At, A3))
print(f"Eckart-Young, ||A - B||_F over rank-3 B: SVD {fbest:.4f} (formula {nrm(s[3:]):.4f}), "
      f"true signal {ftrue:.4f}, three sensors {fsub:.4f}")
print(f"spectral: ||A - A_3||_2 by power iteration {sp:.4f}, sigma_4 = {s[3]:.4f}")
fS, f3S = fro(St), fro(sub(A3, St))
print(f"compression: {3 * (m + n + 1)} numbers for {m * n} ({3 * (m + n + 1) / (m * n):.1%}); error {fbest / fA:.3e}")
print(f"distance to the true signal: raw log {ftrue / fS:.3e}, rank-3 fit {f3S / fS:.3e}")
c = [dot(u, yt) for u in U]
def trunc(k): return [dot([c[i] / s[i] for i in range(k)], col(V[:k], j)) for j in range(n)]
xf, x3, x1, x6 = trunc(20), trunc(3), trunc(1), trunc(6)
(xne,) = chol_solve([[dot(a, b) for b in tr(At)] for a in tr(At)], [mtv(At, yt)])
P = [mv(At, V[i]) for i in range(3)]
zs = chol_solve([[dot(a, b) for b in P] for a in P], [[dot(a, yt) for a in P]])[0]
x3b = [dot(zs, col(V[:3], j)) for j in range(n)]
for lab, x in (("all 20", xf), ("rank 3", x3)):
    print(f"{lab}: |x| = {nrm(x):.3f}, largest |x_j| {max(map(abs, x)):.3f}; "
          f"fit rms {rms(x, At, yt):.4f}, test rms {rms(x, Ate, yte):.4f} L/h")
print(f"normal equations vs SVD, all 20: relative gap {gap(xne, xf):.1e}; kappa^2 u = {e((s[0] / s[19]) ** 2 * eps / 2)}")
print(f"rank 3 by the scores road: relative gap {gap(x3b, x3):.1e}")
print(f"sensor 6 drifts +0.5: prediction moves {0.5 * xf[5]:+.3f} L/h all 20, {0.5 * x3[5]:+.3f} L/h rank 3")
print("i = 1, 3, 4, 20: c_i = u_i.y", " ".join(f"{c[i]:.4f}" for i in (0, 2, 3, 19)),
      "| 1/sigma_i", " ".join(f"{1 / s[i]:.4f}" for i in (0, 2, 3, 19)), "| c_i/sigma_i", " ".join(f"{c[i] / s[i]:.4f}" for i in (0, 2, 3, 19)))
X3 = [[dot([V[i][j] / s[i] for i in range(3)], col(U[:3], r)) for r in range(m)] for j in range(n)]
XA, X3t = [[dot(X3[i], col(A3, j)) for j in range(n)] for i in range(n)], tr(X3)
AX = [[dot(a, x) for x in X3t] for a in A3]
pen = [fro(sub([mtv(XA, r) for r in A3], A3)), fro(sub([[dot(r, x) for x in X3t] for r in XA], X3)),
       fro(sub(AX, tr(AX))), fro(sub(XA, tr(XA)))]
print("Penrose conditions on A_3^+, residuals:", " ".join(e(v) for v in pen))
print(f"break, rank = count of sigma > 0: {len([v for v in s if v > 0])}; noise-free log: {len([v for v in s0 if v > 0])}")
print(f"break, keep 1 value: test rms {rms(x1, Ate, yte):.4f}; keep 6: test rms {rms(x6, Ate, yte):.4f}")

assert abs(fbest - nrm(s[3:])) < 1e-10 * fA and fbest < ftrue < fsub       # Eckart-Young, Frobenius
assert abs(sp - s[3]) < 1e-6 and abs(s[0] - norm2(At)) < 1e-9             # Eckart-Young, spectral
assert abs(fA ** 2 - dot(s, s)) < 1e-9 * fA ** 2                           # squares of entries
assert wey <= nE and s[2] > tn > nE > s[3] and r_noise == 3 and r_round == 20   # Weyl, the gap
assert gap(xne, xf) < 1e-8 and gap(x3b, x3) < 1e-12                        # two roads to each fit
assert max(pen) < 1e-10 and f3S < ftrue and rms(x3, Ate, yte) < rms(xf, Ate, yte)
print("ALL CHECKS PASS")
