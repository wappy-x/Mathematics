# Matrix completion by the nuclear norm -- the check behind the card; only math is imported.
# Part 1 fills the gaps of [[1, 2, ?], [2, 4, 6], [?, 6, 9]] with the table of least nuclear norm (sum of
# singular values) by ratios, grid search, a dual certificate and singular value thresholding (SVT).
# Part 2 hides 60% of a 50 by 40 rank-2 table and recovers it by SVT.  A table is a list of its columns.
import math

M64, state = (1 << 64) - 1, 2026
def uniform():                                    # SplitMix64: a draw in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53
def normal():                                     # Box-Muller, cosine half only
    u = uniform()
    return math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * uniform())
def total(xs):                                    # left-to-right sum, so Python and Rust agree exactly
    s = 0.0
    for x in xs: s += x
    return s
def dot(u, v): return total(a * b for a, b in zip(u, v))
def cl(x): return 0.0 if abs(x) < 5e-7 else x     # print a rounding-level number as 0
def svd(cols, V=None):                            # one-sided Jacobi: turn column pairs of A V until all
    n = len(cols)                                 # are perpendicular; returns sigma_k, sigma_k u_k, v_k
    V = [[float(i == j) for i in range(n)] for j in range(n)] if V is None else V
    G = []
    for v in V:
        g = [0.0] * len(cols[0])
        for w, c in zip(v, cols):
            if w != 0.0: g = [a + w * b for a, b in zip(g, c)]
        G.append(g)
    V = [v[:] for v in V]
    for sweep in range(60):
        turns = 0
        for i in range(n - 1):
            for j in range(i + 1, n):
                a, b, g = dot(G[i], G[i]), dot(G[j], G[j]), dot(G[i], G[j])
                if abs(g) <= 1e-15 * math.sqrt(a * b): continue
                turns += 1; z = (b - a) / (2 * g)
                t = math.copysign(1.0, z) / (abs(z) + math.sqrt(1 + z * z)); c = 1 / math.sqrt(1 + t * t); s = c * t
                for P in (G, V):
                    P[i], P[j] = [c * x - s * y for x, y in zip(P[i], P[j])], [s * x + c * y for x, y in zip(P[i], P[j])]
        if turns == 0: break
    return [math.sqrt(dot(g, g)) for g in G], G, V
def sv(A): return sorted(svd(A)[0], reverse=True)
def nuc(A): return total(sv(A))
def eig(A): _, G, V = svd(A); return sorted((dot(g, v) for g, v in zip(G, V)), reverse=True)  # A symmetric
def f6(xs): return " ".join(f"{cl(x):.6f}" for x in xs)
def svt(M, mask, tau, delta, K, tol, truth=None, every=0):
    n, m = len(M), len(M[0]); Y, V, hist = [[0.0] * m for _ in range(n)], None, []
    obs = math.sqrt(total(M[j][i] ** 2 for j in range(n) for i in range(m) if mask[j][i]))
    for k in range(1, K + 1):
        sig, G, V = svd(Y, V)                     # X_k = D_tau(Y_{k-1}): shrink every singular value by tau
        X, rank = [[0.0] * m for _ in range(n)], 0
        for s, g, v in zip(sig, G, V):
            if s > tau:
                rank += 1; f = 1 - tau / s
                for j in range(n): X[j] = [a + f * v[j] * b for a, b in zip(X[j], g)]
        res = 0.0
        for j in range(n):
            for i in range(m):
                if mask[j][i]: d = M[j][i] - X[j][i]; Y[j][i] += delta * d; res += d * d
        res = math.sqrt(res) / obs
        if every and (k % every == 0 or res < tol): hist.append((k, res, hidden_err(X, truth, mask), rank))
        if res < tol: break
    return X, k, rank, res, hist
def hidden_err(X, T, mask):
    cells = [(j, i) for j in range(len(T)) for i in range(len(T[0])) if not mask[j][i]]
    return math.sqrt(total((X[j][i] - T[j][i]) ** 2 for j, i in cells) / total(T[j][i] ** 2 for j, i in cells))
def table(x, y): return [[1.0, 2.0, y], [2.0, 4.0, 6.0], [x, 6.0, 9.0]]   # x = entry (1,3), y = entry (3,1)
gap = [[1, 1, 0], [1, 1, 1], [0, 1, 1]]
x = 2.0 * 6.0 / 4.0                               # road 1: rank 1 makes row 1 half of row 2
print("table [[1, 2, ?], [2, 4, 6], [?, 6, 9]]; rank-1 fill by ratios: both gaps", f"{x:.6f}")
R1 = table(x, x); s1 = sv(R1)
print(f"u = (1, 2, 3): u u^T has trace 1 + 4 + 9 = {1.0 + 4.0 + 9.0:.6f}; singular values {f6(s1)}; nuclear norm {nuc(R1):.6f}")
best = min((nuc(table(i / 20, j / 20)), i / 20, j / 20) for i in range(121) for j in range(121))
print(f"grid search, both gaps 0 to 6 in steps of 0.05: best ({best[1]:.2f}, {best[2]:.2f}), nuclear norm {best[0]:.6f}")
line = [nuc(table(t / 2, t / 2)) for t in range(13)]
print("chart, gap t  ", " ".join(f"{t / 2:5.1f}" for t in range(13)))
print("chart, norm   ", " ".join(f"{v:5.2f}" for v in line))
Z0 = table(0.0, 0.0)
print(f"zero fill: singular values {f6(sv(Z0))}, nuclear norm {nuc(Z0):.6f}, rank {sum(s > 1e-9 for s in sv(Z0))}")
W = [[c / 14.0 for c in col] for col in ([4.0, 5.0, 0.0], [5.0, 7.0, 3.0], [0.0, 3.0, 12.0])]
sW = sv(W); floor = total(W[j][i] * R1[j][i] for j in range(3) for i in range(3) if gap[j][i]) / sW[0]
print(f"certificate W = [[4, 5, 0], [5, 7, 3], [0, 3, 12]] / 14: zero on both gaps; singular values {f6(sW)}")
print(f"floor <W, seen entries> / largest singular value of W = {floor:.6f}; rank-1 fill minus floor {cl(nuc(R1) - floor):.6f}")
B = [R1[j] + R1[j] for j in range(3)] * 2                     # [[P, X], [X^T, Q]] with P = Q = X = u u^T
D = [[float(i == j) - (W[j % 3][i % 3] if (i < 3) != (j < 3) else 0.0) for i in range(6)] for j in range(6)]  # [[I, -W], [-W, I]]
print(f"SDP primal: eigenvalues of [[P, X], [X^T, Q]] {f6(eig(B))}; (tr P + tr Q) / 2 = {(14.0 + 14.0) / 2:.6f}")
print(f"SDP dual:   eigenvalues of [[I, -W], [-W, I]] {f6(eig(D))}")
Y0, tau = Z0, 2.0                                             # road 3: D_tau is the prox of tau |.|_*
def phi(X): return tau * nuc(X) + 0.5 * total((a - b) ** 2 for c, d in zip(X, Y0) for a, b in zip(c, d))
sig, G, V = svd(Y0); P = [[total(max(s - tau, 0.0) / s * g[i] * v[j] for s, g, v in zip(sig, G, V)) for i in range(3)] for j in range(3)]
excess = min(phi([[a + 0.1 * normal() for a in col] for col in P]) - phi(P) for _ in range(300))
print(f"prox check, tau 2 on the zero fill: D_tau beats 300 random nearby tables; smallest excess {excess:.6f}")
tau0 = 42.0 / (math.sqrt(65.0) - 3.0)
print(f"threshold needed for the exact fill: 42 / (sqrt 65 - 3) = {tau0:.6f}")
runs = {}
for tau in (1.0, 5.0, 8.0, 8.4, 20.0):
    X, k, rank, res, _ = svt(table(x, x), gap, tau, 1.0, 5000, 1e-10)
    runs[tau] = (X[2][0], X[0][2])
    print(f"SVT tau {tau:4.1f}, step 1: gaps {X[2][0]:.6f} {X[0][2]:.6f}, rank {rank}, iteration {k}, seen-entry miss {res:.1e}")
print(f"incoherence mu of u: 3 x max(u_i^2) / |u|^2 = {3 * 9.0 / 14.0:.6f} (range 1 to 3)")
col_gap = [[1, 1, 1], [1, 1, 1], [0, 0, 0]]
Xc = svt(table(x, x), col_gap, 20.0, 1.0, 5000, 1e-10)[0]
print(f"mistake, whole third column hidden: SVT fills {f6(Xc[2])}; truth 3 6 9")
spike = [[5.0, 0.0, 0.0], [4.0, 0.0, 0.0], [3.0, 0.0, 0.0]]       # only viewer 1 rates (5, 4, 3); mu = 3
Xs = svt(spike, [[1, 1, 1], [1, 1, 1], [0, 1, 1]], 20.0, 1.0, 5000, 1e-10)[0]
print(f"mistake, coherent table, viewer 1 alone rates (5, 4, 3), the 3 hidden: SVT fills {cl(Xs[2][0]):.6f}")
sig, G, V = svd(Z0); k1 = max(range(3), key=lambda k: sig[k])
print(f"mistake, one SVD of the zero fill, keep rank 1: gaps {G[k1][0] * V[k1][2]:.6f} {G[k1][2] * V[k1][0]:.6f}, seen (1,1) {G[k1][0] * V[k1][0]:.6f}")

state, m, n, r = 4, 50, 40, 2                     # part 2, seed 4: 50 viewers, 40 films, two tastes
Lf = [[normal() for _ in range(r)] for _ in range(m)]; Rf = [[normal() for _ in range(r)] for _ in range(n)]
T = [[dot(Lf[i], Rf[j]) for i in range(m)] for j in range(n)]
order = list(range(m * n))
for i in range(m * n - 1, 0, -1):                 # Fisher-Yates shuffle; the first 800 cells are seen
    j = int(uniform() * (i + 1)) % (i + 1); order[i], order[j] = order[j], order[i]
mask = [[0] * m for _ in range(n)]
for c in order[:800]: mask[c // m][c % m] = 1
sT, GT, _ = svd(T); top = sorted(range(n), key=lambda k: -sT[k])[:r]
muU = m / r * max(total((GT[k][i] / sT[k]) ** 2 for k in top) for i in range(m))
print(f"50 x 40 rank-2 table: 800 of 2000 seen (40%), degrees of freedom r(m + n - r) = {r * (m + n - r)}, n r log n = {m * r * math.log(m):.1f}")
print(f"truth: singular values {f6(sv(T)[:3])}, viewer-side incoherence mu {muU:.3f} (range 1 to 25)")
X, k, rank, res, hist = svt(T, mask, 6.0 * m, 1.2 / 0.4, 1000, 1e-4, T, 25)
print(f"SVT tau 6 x 50 = {6.0 * m:.0f}, step 1.2 / 0.4 = {1.2 / 0.4:.1f}; stop when the seen-entry miss < 1e-4")
print("     k   seen-entry miss   hidden error   rank")
for kk, rr, hh, rk in hist: print(f"{kk:6d} {rr:17.6f} {hh:14.6f} {rk:6d}")
print(f"recovered: singular values {f6(sv(X)[:3])}; nuclear norm {nuc(X):.3f} against the truth's {nuc(T):.3f}")
print("chart, k      ", " ".join(f"{kk:5d}" for kk, _, _, _ in hist))
print("chart, log10  ", " ".join(f"{math.log10(hh):5.2f}" for _, _, hh, _ in hist))
assert abs(best[0] - floor) < 1e-9 and (best[1], best[2]) == (x, x)   # grid search meets the dual floor
assert abs(sW[0] - 1.0) < 1e-12                                          # W is a valid certificate
assert min(eig(D)) > -1e-12 and min(eig(B)) > -1e-12                     # both SDP blocks are PSD
assert excess > 0.0                                                      # D_tau minimises the prox target
assert abs(runs[20.0][0] - 3.0) < 1e-6 and abs(runs[8.4][1] - 3.0) < 1e-6  # threshold above tau0: exact
assert abs(runs[8.0][0] - 3.0) > 0.05 and abs(runs[1.0][0] - 3.0) > 2.0  # threshold below tau0: not exact
assert max(map(abs, Xc[2])) < 1e-9 and abs(Xs[2][0]) < 1e-9             # the two broken hypotheses
assert hist[-1][2] < 1e-3 and rank == 2                                  # the 50 x 40 table is recovered
print("ALL CHECKS PASS")
