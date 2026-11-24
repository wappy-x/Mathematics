# Subspace identification: the Hankel matrix's rank is the model's order.
# Standard library only. Radiator panel: h_k = 0.8^k + 0.5^k degC per valve-minute.
from math import sqrt, log, cos, pi
M64, state = (1 << 64) - 1, 2026
def splitmix():                       # SplitMix64 random bits, seed 2026
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
def unif(): return ((splitmix() >> 11) + 0.5) / 2.0**53
def gauss(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())   # Box-Muller
def jacobi(S):                        # eigenvalues and eigenvectors of a symmetric matrix
    n = len(S); a = [r[:] for r in S]
    V = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    for _ in range(60):
        for p in range(n):
            for q in range(p + 1, n):
                if abs(a[p][q]) < 1e-300: continue
                th = (a[q][q] - a[p][p]) / (2.0 * a[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1.0))
                c = 1.0 / sqrt(t * t + 1.0); s = t * c
                for k in range(n):
                    x, y = a[k][p], a[k][q]; a[k][p] = c * x - s * y; a[k][q] = s * x + c * y
                    x, y = V[k][p], V[k][q]; V[k][p] = c * x - s * y; V[k][q] = s * x + c * y
                for k in range(n):
                    x, y = a[p][k], a[q][k]; a[p][k] = c * x - s * y; a[q][k] = s * x + c * y
    return [a[i][i] for i in range(n)], V
def svd_sym(S):                       # symmetric S: singular values = |eigenvalues|, largest first
    ev, V = jacobi(S); n = len(S)
    idx = sorted(range(n), key=lambda i: -abs(ev[i]))
    U = [[V[r][i] for i in idx] for r in range(n)]
    W = [[V[r][i] * (1.0 if ev[i] >= 0 else -1.0) for i in idx] for r in range(n)]
    return [abs(ev[i]) for i in idx], U, W
def hankel(h, shift): return [[h[i + j + 1 + shift] for j in range(4)] for i in range(4)]
def era(h, n, shift=1):               # Ho-Kalman / ERA: factor H0, read A from the shifted H1
    sig, U, W = svd_sym(hankel(h, 0)); H1 = hankel(h, shift)
    A = [[sum(U[r][a] * H1[r][c] * W[c][b] for r in range(4) for c in range(4))
          / sqrt(sig[a] * sig[b]) for b in range(n)] for a in range(n)]
    return A, [sqrt(sig[a]) * W[0][a] for a in range(n)], [sqrt(sig[a]) * U[0][a] for a in range(n)]
def roots2(M):                        # eigenvalues of a 2x2 matrix (real case), larger first
    tr = M[0][0] + M[1][1]; d = sqrt(tr * tr / 4.0 - (M[0][0] * M[1][1] - M[0][1] * M[1][0]))
    return tr / 2.0 + d, tr / 2.0 - d
def markov(A, B, C, k):               # h_k = C A^(k-1) B
    x = B[:]
    for _ in range(k - 1): x = [sum(A[i][j] * x[j] for j in range(len(x))) for i in range(len(x))]
    return sum(C[i] * x[i] for i in range(len(x)))
def tau(p): return -1.0 / log(p)      # time constant in minutes, one sample = 1 min
def row(v): return " ".join(f"{x:.6f}" for x in v)
h = [None] + [0.8**k + 0.5**k for k in range(1, 13)]
H0 = hankel(h, 0)
print("Hankel H0 from h_1..h_7 (degC per valve-minute):")
for r in H0: print("  " + row(r))
sig, _, _ = svd_sym(H0)
print("singular values, clean:", row(sig), " 2x2 minor h1*h3 - h2^2 = %.6f" % (h[1] * h[3] - h[2] * h[2]))
assert sig[1] > 1e-2 and sig[2] < 1e-12
m, rank, prev = [[8**(i + j + 1) + 5**(i + j + 1) for j in range(4)] for i in range(4)], 0, 1
for k in range(4):                    # Bareiss elimination on 10^(i+j-1) h, exact integers
    piv = next((r for r in range(k, 4) if m[r][k] != 0), None)
    if piv is None: break
    m[k], m[piv] = m[piv], m[k]; rank += 1
    for i in range(k + 1, 4):
        for j in range(k + 1, 4): m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) // prev
        m[i][k] = 0
    prev = m[k][k]
print("exact integer rank of [8^(i+j-1) + 5^(i+j-1)]:", rank)
assert rank == 2

At, Bt, Ct = [[0.8, 0.0], [0.0, 0.5]], [0.8, 0.5], [1.0, 1.0]       # one known realisation
Obs = [[Ct[a] * At[a][a]**k for a in range(2)] for k in range(4)]  # rows C, CA, CA^2, CA^3
Con = [[At[a][a]**k * Bt[a] for k in range(4)] for a in range(2)]  # columns B, AB, A^2B, A^3B
assert max(abs(sum(Obs[i][a] * Con[a][j] for a in range(2)) - H0[i][j]) for i in range(4) for j in range(4)) < 1e-12
s2 = roots2([[sum(Con[a][k] * Obs[k][b] for k in range(4)) for b in range(2)] for a in range(2)])
print("singular values from the 2x2 product Con*Obs:", row(s2))
assert abs(s2[0] - sig[0]) < 1e-9 and abs(s2[1] - sig[1]) < 1e-9

A, B, C = era(h, 2); p = roots2(A)
print("ERA order 2: A =", row(A[0]), "/", row(A[1]), " B =", row(B), " C =", row(C))
print("ERA poles:", row(p), " trace %.6f det %.6f" % (A[0][0] + A[1][1], A[0][0] * A[1][1] - A[0][1] * A[1][0]),
      " time constants (min): %.2f %.2f" % (tau(p[0]), tau(p[1])))
det = h[1] * h[3] - h[2] * h[2]       # recurrence h(k+2) = a1 h(k+1) + a0 h(k), from h_1..h_4
a0 = (h[3] * h[3] - h[2] * h[4]) / det; a1 = (h[1] * h[4] - h[2] * h[3]) / det
q = roots2([[a1, a0], [1.0, 0.0]])
print("recurrence: h(k+2) = %.6f h(k+1) - %.6f h(k); roots %s" % (a1, -a0, row(q)))
assert abs(p[0] - 0.8) < 1e-9 and abs(p[1] - 0.5) < 1e-9 and abs(q[0] - p[0]) < 1e-9 and abs(q[1] - p[1]) < 1e-9
pred = [markov(A, B, C, k) for k in range(9, 13)]
print("model h_9..h_12:", row(pred), " true:", row(h[9:13]))
assert max(abs(pred[i] - h[9 + i]) for i in range(4)) < 1e-9

hn = [None] + [h[k] + 0.005 * gauss() for k in range(1, 9)]
sn, _, _ = svd_sym(hankel(hn, 0))
print("noisy h_1..h_8 (sd 0.005 degC):", row(hn[1:]))
print("singular values, noisy:", row(sn), " gap sigma2/sigma3 = %.1f" % (sn[1] / sn[2]))
assert sn[1] / sn[2] > 5.0 and sn[2] / sn[3] < 5.0
An, Bn, Cn = era(hn, 2); pn = roots2(An)
print("noisy ERA poles:", row(pn), " time constants (min): %.2f %.2f" % (tau(pn[0]), tau(pn[1])))
assert abs(pn[0] - 0.8) < 0.02 and abs(pn[1] - 0.5) < 0.05
err = max(abs(markov(An, Bn, Cn, k) - h[k]) for k in range(1, 13))
print("noisy model, worst error on true h_1..h_12: %.6f degC" % err)

print("WHAT BREAKS")
A1, B1, C1 = era(hn, 1)
e1 = max(abs(markov(A1, B1, C1, k) - h[k]) for k in range(1, 13))
print("order 1: pole %.6f, time constant %.2f min, worst error %.6f degC" % (A1[0][0], tau(A1[0][0]), e1))
assert e1 > 10 * err
print("count every non-zero singular value of the noisy H0: order", sum(1 for s in sn if s > 1e-12))
p0 = roots2(era(h, 2, shift=0)[0])
print("forget the shift (H0 for H1): poles", row(p0))
assert abs(p0[1] - 1.0) < 1e-9
state = 2026
hb = [None] + [h[k] + 0.05 * gauss() for k in range(1, 9)]
sb, _, _ = svd_sym(hankel(hb, 0))
print("noise sd 0.05 degC: singular values", row(sb), " gap %.1f" % (sb[1] / sb[2]))
assert sb[1] / sb[2] < 2.0

N, x, us, ys = 1440, [0.0, 0.0], [], []           # subspace core from a day of valve data
for t in range(N + 4):
    u = 0.5 if splitmix() >> 63 else -0.5         # valve 50% above or below its middle, each minute
    us.append(u); ys.append(Ct[0] * x[0] + Ct[1] * x[1])
    x = [At[0][0] * x[0] + Bt[0] * u, At[1][1] * x[1] + Bt[1] * u]
Uf = [[us[j + i] for j in range(N)] for i in range(4)]
Yf = [[ys[j + i] for j in range(N)] for i in range(4)]
dot = lambda P, Q: [[sum(a * b for a, b in zip(P[i], Q[j])) / N for j in range(4)] for i in range(4)]
YY, YU, UU = dot(Yf, Yf), dot(Yf, Uf), dot(Uf, Uf)
G = [UU[i][:] + [YU[r][i] for r in range(4)] for i in range(4)]   # solve UU X = YU^T, Gauss-Jordan
for k in range(4):
    G[k] = [v / G[k][k] for v in G[k]]
    for i in range(4):
        if i != k: G[i] = [a - G[i][k] * b for a, b in zip(G[i], G[k])]
P = [[YY[i][j] - sum(YU[i][k] * G[k][4 + j] for k in range(4)) for j in range(4)] for i in range(4)]
sp, Up, _ = svd_sym(P)
print("subspace core, inputs projected out: singular values", row(sp))
L = [[sum(Up[k][a] * Up[k][b] for k in range(3)) for b in range(2)] for a in range(2)]
R = [[sum(Up[k][a] * Up[k + 1][b] for k in range(3)) for b in range(2)] for a in range(2)]
d = L[0][0] * L[1][1] - L[0][1] * L[1][0]
Li = [[L[1][1] / d, -L[0][1] / d], [-L[1][0] / d, L[0][0] / d]]
ps = roots2([[sum(Li[i][k] * R[k][j] for k in range(2)) for j in range(2)] for i in range(2)])
print("subspace core poles (shift of the observability block):", row(ps))
assert sp[2] < 1e-9 * sp[1] and abs(ps[0] - 0.8) < 1e-9 and abs(ps[1] - 0.5) < 1e-9
print("ALL CHECKS PASS")
