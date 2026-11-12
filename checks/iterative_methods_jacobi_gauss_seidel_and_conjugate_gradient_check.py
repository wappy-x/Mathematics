# Iterating instead of factoring -- the check behind the card.  Standard library only; nothing
# imported holds an answer.  A 10-by-25 grid of junctions joined by 465 pipes, fed by 35 more
# pipes from a main at 50 m: 500 pipes, 250 unknown pressure heads.  Each pipe passes 1 L/s per
# metre of head difference; customers draw 0.1 L/s per metre of head (illustrative numbers).
from math import sqrt, sin, cos, pi, log10
R, C, H0, DRAW, TOL, CHART = 10, 25, 50.0, 0.1, 1e-8, 480; n = R * C
off, diag, b, pipes = [[] for _ in range(n)], [DRAW] * n, [0.0] * n, 0
for r in range(R):
    for c in range(C):
        i = r * C + c
        for rr, cc in ((r, c + 1), (r + 1, c)):
            if rr < R and cc < C:
                j = rr * C + cc; off[i].append((j, -1.0)); off[j].append((i, -1.0))
                diag[i] += 1.0; diag[j] += 1.0; pipes += 1
        for fed in (r == 0, c == 0):           # pipes from the main to the top row and the left column
            if fed: diag[i] += 1.0; b[i] += H0; pipes += 1
M, nnz = (off, diag, b), n + sum(len(o) for o in off)
def dot(u, v):                                 # plain left-to-right sum, as in the Rust
    s = 0.0
    for i in range(len(u)): s += u[i] * v[i]
    return s
def ax(M, x):
    o, d, _ = M; y = []
    for i in range(len(x)):
        s = d[i] * x[i]
        for j, a in o[i]: s += a * x[j]
        y.append(s)
    return y
def sweep(M, x, w, gs):                        # one Jacobi (gs False) or Gauss-Seidel/SOR sweep
    o, d, bb = M; src = x if gs else x[:]; new = x if gs else [0.0] * len(x)
    for i in range(len(x)):
        s = bb[i]
        for j, a in o[i]: s -= a * src[j]
        new[i] = x[i] + w * (s / d[i] - x[i])
    return new
def cholesky_solve(M):                         # road 1, the direct solve: dense L L^T, then two sweeps
    o, d, bb = M; m = len(bb); od = [dict(o[i]) for i in range(m)]
    A = [[d[i] if i == j else od[i].get(j, 0.0) for j in range(m)] for i in range(m)]
    L, y, x = [[0.0] * m for _ in range(m)], [0.0] * m, [0.0] * m
    for j in range(m):
        s = A[j][j]
        for k in range(j): s -= L[j][k] * L[j][k]
        L[j][j] = sqrt(s)
        for i in range(j + 1, m):
            t = A[i][j]
            for k in range(j): t -= L[i][k] * L[j][k]
            L[i][j] = t / L[j][j]
    for i in range(m):
        s = bb[i]
        for k in range(i): s -= L[i][k] * y[k]
        y[i] = s / L[i][i]
    for i in reversed(range(m)):
        s = y[i]
        for k in range(i + 1, m): s -= L[k][i] * x[k]
        x[i] = s / L[i][i]
    return x
xs, ones = cholesky_solve(M), [1.0] * n; bn, xn = sqrt(dot(b, b)), sqrt(dot(xs, xs))
def err(x): return max(abs(x[i] - xs[i]) for i in range(n))
def enA(x): e = [x[i] - xs[i] for i in range(n)]; return sqrt(dot(e, ax(M, e)))
def rel2(x): e = [x[i] - xs[i] for i in range(n)]; return sqrt(dot(e, e)) / xn
def relres(x): r = [b[i] - t for i, t in enumerate(ax(M, x))]; return sqrt(dot(r, r)) / bn
def stationary(w, gs, steps=0, stop=0.0):
    x, k, hist = [0.0] * n, 0, [[0.0] * n]
    while (k < steps if steps else relres(x) > TOL) and k < 20000:
        old = x[:]; x = sweep(M, x, w, gs); k += 1; hist.append(x[:])
        if stop and max(abs(x[i] - old[i]) for i in range(n)) < stop: break
    return k, x, hist
def cg(steps=0):
    x, r = [0.0] * n, b[:]; d, rr, k, hist = r[:], dot(r, r), 0, [[0.0] * n]
    while (k < steps if steps else sqrt(rr) / bn > TOL) and k < 20000:
        Ad = ax(M, d); al = rr / dot(d, Ad)
        x = [x[i] + al * d[i] for i in range(n)]; r = [r[i] - al * Ad[i] for i in range(n)]
        rn = dot(r, r); d = [r[i] + rn / rr * d[i] for i in range(n)]; rr, k = rn, k + 1; hist.append(x)
    return k, x, hist
def sci(x): m, e = f"{x:.3e}".split("e"); return f"{m}e{int(e)}"
j1, g1 = sweep(M, [0.0] * n, 1.0, False), sweep(M, [0.0] * n, 1.0, True)
inflow = dot([2.0 if i == 0 else 1.0 if i < C or i % C == 0 else 0.0 for i in range(n)], [H0 - t for t in xs])
print(f"network: {n} junctions, {pipes} pipes, {nnz} nonzeros of {n * n} ({100 * nnz / (n * n):.2f}%), diagonal {min(diag):.1f} to {max(diag):.1f}")
print(f"Jacobi sweep 1 at (0,0) (0,1) (1,0) (1,1): {j1[0]:.6f} {j1[1]:.6f} {j1[C]:.6f} {j1[C + 1]:.6f}")
print(f"Gauss-Seidel sweep 1 at the same four:    {g1[0]:.6f} {g1[1]:.6f} {g1[C]:.6f} {g1[C + 1]:.6f}")
print(f"settled heads, m: corner (0,0) {xs[0]:.6f}  far corner {xs[n - 1]:.6f}  mean {dot(xs, ones) / n:.6f}")
print(f"mass balance, L/s: in from the main {inflow:.6f}  drawn by customers {DRAW * dot(xs, ones):.6f}")
def mu(m, k): return 2.0 - 2.0 * cos((2 * k - 1) * pi / (2 * m + 1))
xsp = [0.0] * n                                # road 2: the spectral theorem, eigenvectors in closed form
for kc in range(1, C + 1):
    for kr in range(1, R + 1):
        q = [sin((2 * kc - 1) * pi * (c + 1) / (2 * C + 1)) * sin((2 * kr - 1) * pi * (r + 1) / (2 * R + 1))
             for r in range(R) for c in range(C)]
        cf = dot(q, b) / (dot(q, q) * (mu(C, kc) + mu(R, kr) + DRAW))
        for i in range(n): xsp[i] += cf * q[i]
print(f"spectral road: corner {xsp[0]:.6f}  far corner {xsp[n - 1]:.6f}  agrees with Cholesky to 1e-10: {'yes' if err(xsp) < 1e-10 else 'no'}")
lmin, lmax = mu(C, 1) + mu(R, 1) + DRAW, mu(C, C) + mu(R, R) + DRAW; kap = lmax / lmin; rcg = (sqrt(kap) - 1) / (sqrt(kap) + 1)
qd = max(sum(abs(a) for _, a in off[i]) / diag[i] for i in range(n))
Z, v = (off, diag, [0.0] * n), [1.0] * n       # rho of the Jacobi matrix G, by power iteration
for _ in range(3000): v = sweep(Z, v, 1.0, False); s = sqrt(dot(v, v)); v = [t / s for t in v]
g2 = sweep(Z, sweep(Z, v, 1.0, False), 1.0, False); rhoj = sqrt(sqrt(dot(g2, g2))); wy = 2.0 / (1.0 + sqrt(1.0 - rhoj * rhoj))
print(f"lambda min {lmin:.6f}  max {lmax:.6f}  kappa {kap:.4f}  sqrt kappa {sqrt(kap):.4f}  CG factor {rcg:.4f}")
print(f"dominance q {qd:.6f}  rho Jacobi {rhoj:.6f}  rho^2 {rhoj * rhoj:.6f}  Young omega {wy:.4f}")
fj, fcg = 2 * (nnz - n) + n, (2 * nnz - n) + 2 * (2 * n - 1) + 3 * 2 * n + 2
scan = [(w / 10, stationary(w / 10, True)[0]) for w in range(10, 20)]; wb = min(scan, key=lambda t: t[1])[0]
runs = [("Jacobi", stationary(1.0, False), fj), ("Gauss-Seidel", stationary(1.0, True), fj),
        (f"SOR omega {wb:.1f}", stationary(wb, True), fj + 3 * n), ("conjugate gradient", cg(), fcg)]
for name, (k, x, _), f in runs:
    print(f"{name:<19} steps {k:>4}  flops {k * f:>9,}  max error {sci(err(x)):>9} m  rel residual {sci(relres(x))}")
print(f"flops: dense Cholesky {(2 * n ** 3 + 3 * n ** 2 + n) // 6:,}; per step: sweep {fj:,}, SOR {fj + 3 * n:,}, CG {fcg:,}; Cholesky / CG {(2 * n ** 3 + 3 * n ** 2 + n) // 6 / (runs[3][1][0] * fcg):.1f}")
def band(p): return sum(2 * (j - max(0, i - p)) + 1 for j in range(n) for i in range(j, min(j + p, n - 1) + 1)) + 2 * sum(2 * min(i, p) + 1 for i in range(n))
print(f"flops: band Cholesky and two solves, half-bandwidth {C} (row by row) {band(C):,}, {R} (column by column) {band(R):,}; CG / band {runs[3][1][0] * fcg / band(C):.2f}, {runs[3][1][0] * fcg / band(R):.2f}")
print("SOR scan, omega:steps " + " ".join(f"{w:.1f}:{k}" for w, k in scan))
hj, hg, hc, e0, a0 = runs[0][1][2], runs[1][1][2], runs[3][1][2], err([0.0] * n), enA([0.0] * n)
for k in (100, 200, 300, 400):
    t, bd = err(hj[k]), qd ** k * e0
    print(f"Jacobi sweep {k}: true max error {sci(t)} m  bound q^k e0 {sci(bd)} m  ratio {bd / t:.1f}")
for k in (10, 20, 30, 40, 50):
    t, bd = enA(hc[k]), 2 * rcg ** k * a0
    print(f"CG step {k}: true A-norm error {sci(t)}  bound {sci(bd)}  ratio {bd / t:.1f}")
obs = ((err(hj[400]) / err(hj[300])) ** 0.01, (err(hg[200]) / err(hg[100])) ** 0.01, (enA(hc[50]) / enA(hc[10])) ** 0.025)
print(f"observed factor per step: Jacobi {obs[0]:.4f}  Gauss-Seidel {obs[1]:.4f}  CG {obs[2]:.4f}")
xc = runs[3][1][1]; rc = [b[i] - t for i, t in enumerate(ax(M, xc))]; e2 = rel2(xc) * xn
print(f"CG certificate: |error| {sci(e2)} <= |residual| / lambda min {sci(sqrt(dot(rc, rc)) / lmin)}  ratio {sqrt(dot(rc, rc)) / lmin / e2:.1f}")
print(f"CG forward: rel error {sci(rel2(xc))} <= kappa x rel residual {sci(kap * relres(xc))}  ratio {kap * relres(xc) / rel2(xc):.1f}")
fJ, fG, fC = stationary(1.0, False, CHART)[2], stationary(1.0, True, CHART)[2], cg(CHART)[2]
for k in range(0, CHART + 1, 40):
    print(f"figure, step {k}, log10 max error J {log10(err(fJ[k])):.2f} GS {log10(err(fG[k])):.2f} CG {log10(err(fC[k])):.2f}")
ks, xstop, hs = stationary(1.0, False, stop=1e-3); mv = max(abs(hs[-1][i] - hs[-2][i]) for i in range(n))
print(f"wrong: stop Jacobi when a sweep moves < 1e-3 m: sweep {ks}, true max error {err(xstop):.6f} m; last move {mv:.6f} m x rho/(1-rho) {rhoj / (1 - rhoj):.4f} = {mv * rhoj / (1 - rhoj):.6f} m")
T, tj, tg = ([[(1, 0.8), (2, 0.8)], [(0, 0.8), (2, 0.8)], [(0, 0.8), (1, 0.8)]], [1.0] * 3, [2.6] * 3), [0.0] * 3, [0.0] * 3
for _ in range(30): tp = tj; tj = sweep(T, tj, 1.0, False); tg = sweep(T, tg, 1.0, True)
ej, eg, ep = (max(abs(t - 1) for t in u) for u in (tj, tg, tp))
ev = [(v, dot(v, ax(T, v)) / dot(v, v)) for v in ([1.0] * 3, [1.0, -1.0, 0.0], [1.0, 1.0, -2.0])]   # three eigenvectors
print("3x3: eigenvalues " + " ".join(f"{l:.1f}" for _, l in ev) + f" at (1,1,1) (1,-1,0) (1,1,-2); Jacobi error grows {ej / ep:.4f} per sweep")
print(f"wrong: Jacobi on [[1,.8,.8],[.8,1,.8],[.8,.8,1]], 30 sweeps: error {ej:.1f}; Gauss-Seidel {sci(eg)}")
assert err(xsp) < 1e-10 and abs(inflow - DRAW * dot(xs, ones)) < 1e-9   # roads 1 and 2 agree; water balances
assert all(relres(x) <= TOL and rel2(x) <= kap * relres(x) for _, (k, x, _), _ in runs)
assert all(qd ** k * e0 >= err(hj[k]) for k in range(len(hj)))          # dominance bound, every sweep
assert all(2 * rcg ** k * a0 >= enA(hc[k]) for k in range(len(hc)))      # CG bound, every step
assert rhoj < qd and abs(obs[0] - rhoj) < 2e-3 and abs(obs[1] - rhoj ** 2) < 2e-3 and abs(wy - wb) < 0.05
assert e2 <= sqrt(dot(rc, rc)) / lmin and runs[3][1][0] < runs[1][1][0] < runs[0][1][0]
assert band(n - 1) == (2 * n ** 3 + 3 * n ** 2 + n) // 6 + 2 * n * n      # full band = the dense count, plus two solves
assert err(xstop) > 10 * 1e-3 and ej > 1e3 and eg < 1e-3 and all(l > 0 and max(abs(a - l * c) for a, c in zip(ax(T, v), v)) < 1e-12 for v, l in ev)
print("ALL CHECKS PASS")
