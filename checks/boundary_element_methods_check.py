# Boundary elements -- the check behind the card.  Standard library only.
# A heated duct: the inside of an ellipse with semi-axes 2 m and 1 m, rim
# temperature g = x^2 - y^2 (degrees above ambient), exact u = x^2 - y^2.
# Roads: (1) Nystrom with the trapezoid rule, (2) flat-panel collocation,
# (3) a finite-difference grid on the same region, (4) GMRES against
# elimination, all read against the exact harmonic function at (0.5, 0.3).
import math
TAU, A, B, PX = 2 * math.pi, 2.0, 1.0, (0.5, 0.3)
G1 = lambda x, y: x * x - y * y                   # the duct's rim temperature
G2 = lambda x, y: math.exp(x) * math.cos(y)       # a second test, not a polynomial
def ell(t):                       # rim point, outward unit normal, speed, curvature
    J = math.sqrt(A * A * math.sin(t) ** 2 + B * B * math.cos(t) ** 2)
    return (A * math.cos(t), B * math.sin(t)), (B * math.cos(t) / J, A * math.sin(t) / J), J, A * B / (J * J * J)
def dk(x, y, n):                  # double-layer kernel d Phi(x - y)/d n_y
    dx, dy = x[0] - y[0], x[1] - y[1]
    return (dx * n[0] + dy * n[1]) / (dx * dx + dy * dy) / TAU
def solve(M0, b):                 # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(M0)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            for k in range(c, n + 1): M[r][k] -= f * M[c][k]
    x = [0.0] * n
    for r in range(n - 1, -1, -1): x[r] = (M[r][n] - sum(M[r][k] * x[k] for k in range(r + 1, n))) / M[r][r]
    return x

def nystrom(N, g, half=-0.5, diag=True):   # matrix of half*I + K, the data, the nodes
    nd = [ell(TAU * j / N) for j in range(N)]; M = [[0.0] * N for _ in range(N)]
    for i, (xi, ni, Ji, ki) in enumerate(nd):
        for j, (yj, nj, Jj, kj) in enumerate(nd):
            kern = (-kj / (2 * TAU) if diag else 0.0) if i == j else dk(xi, yj, nj)
            M[i][j] = kern * Jj * TAU / N + (half if i == j else 0.0)
    return M, [g(*p) for p, *_ in nd], nd
def ny_eval(nd, mu, x): return sum(dk(x, y, n) * m * J * TAU / len(nd) for (y, n, J, k), m in zip(nd, mu))
def ny_u(N, g, x=PX, **kw):
    M, b, nd = nystrom(N, g, **kw); return ny_eval(nd, solve(M, b), x)

def angle(x, p, q):               # signed angle that the panel p -> q subtends at x
    ax, ay, bx, by = p[0] - x[0], p[1] - x[1], q[0] - x[0], q[1] - x[1]
    return math.atan2(ax * by - ay * bx, ax * bx + ay * by)
def panel_u(N, g, x=PX):          # N flat panels, constant density, midpoint collocation
    V = [ell(TAU * j / N)[0] for j in range(N + 1)]
    mid = [((V[j][0] + V[j + 1][0]) / 2, (V[j][1] + V[j + 1][1]) / 2) for j in range(N)]
    M = [[-0.5 if i == j else -angle(mid[i], V[j], V[j + 1]) / TAU for j in range(N)] for i in range(N)]
    mu = solve(M, [g(*ell(TAU * (j + 0.5) / N)[0]) for j in range(N)])   # data read on the true rim
    return sum(-angle(x, V[j], V[j + 1]) / TAU * mu[j] for j in range(N))

def gmres(M, b, tol=1e-10):       # GMRES from zero: steps to reach relative residual tol
    n = len(b); beta = math.sqrt(sum(v * v for v in b)); Q = [[v / beta for v in b]]; H = []
    for k in range(1, n + 1):
        w = [sum(M[i][j] * Q[-1][j] for j in range(n)) for i in range(n)]; h = []
        for q in Q:
            c = sum(a * e for a, e in zip(w, q)); h.append(c); w = [a - c * e for a, e in zip(w, q)]
        h.append(math.sqrt(sum(v * v for v in w))); H.append(h); Q.append([v / h[-1] for v in w])
        HH = [[H[c][r] if r < len(H[c]) else 0.0 for c in range(k)] for r in range(k + 1)]
        y = solve([[sum(HH[r][a] * HH[r][c] for r in range(k + 1)) for c in range(k)] for a in range(k)],
                  [beta * HH[0][a] for a in range(k)])   # least squares by its normal equations
        x = [sum(Q[c][i] * y[c] for c in range(k)) for i in range(n)]
        res = math.sqrt(sum((b[i] - sum(M[i][j] * x[j] for j in range(n))) ** 2 for i in range(n))) / beta
        if res < tol: return k, x

def inside(i, j, h): return (i * h / A) * (i * h / A) + (j * h / B) * (j * h / B) < 1 - 1e-12
def grid_pts(h):
    I, Jm = int(A / h) + 1, int(B / h) + 1
    return [(i, j) for i in range(-I, I + 1) for j in range(-Jm, Jm + 1) if inside(i, j, h)]
def grid_u(h, g, omega):          # 5-point grid, Shortley-Weller arms at the curved rim, SOR
    pts = grid_pts(h); u = {p: 0.0 for p in pts}; arms = {}; nnz = len(pts)
    for (i, j) in pts:
        a = []
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if inside(i + di, j + dj, h): a.append((h, (i + di, j + dj), 0.0)); nnz += 1; continue
            x0, y0 = i * h, j * h      # distance s to the rim along this arm: a quadratic in s
            qa, qb = di * di / (A * A) + dj * dj / (B * B), 2 * (x0 * di / (A * A) + y0 * dj / (B * B))
            qc = x0 * x0 / (A * A) + y0 * y0 / (B * B) - 1
            s = (-qb + math.sqrt(qb * qb - 4 * qa * qc)) / (2 * qa)
            a.append((s, None, g(x0 + s * di, y0 + s * dj)))
        arms[(i, j)] = a
    for sweep in range(1, 100000):
        change = 0.0
        for p in pts:
            (sE, pE, vE), (sW, pW, vW), (sN, pN, vN), (sS, pS, vS) = arms[p]
            wE, wW, wN, wS = 1 / (sE * (sE + sW)), 1 / (sW * (sE + sW)), 1 / (sN * (sN + sS)), 1 / (sS * (sN + sS))
            new = (wE * (u[pE] if pE else vE) + wW * (u[pW] if pW else vW) + wN * (u[pN] if pN else vN)
                   + wS * (u[pS] if pS else vS)) / (wE + wW + wN + wS)
            change = max(change, abs(new - u[p])); u[p] += omega * (new - u[p])
        if change < 1e-13: break
    return u[(round(PX[0] / h), round(PX[1] / h))], len(pts), nnz, sweep

e, lg = lambda v: "%.1e" % v, lambda v: "%.2f" % math.log10(v)
print("duct: ellipse 2 m by 1 m, rim temperature x^2 - y^2 K, read at (0.5, 0.3) m")
print("exact u = 0.25 - 0.09 = %.6f K" % G1(*PX))
M, b, nd = nystrom(8, G1); n0, n2 = nd[0], nd[2]
print("N=8, row 0 of -I/2 + K:" + ",".join(" %.6f" % v for v in M[0]))
print("N=8, row 0 adds up to %.6f (the double layer of 1 is -1 inside)" % sum(M[0]))
print("N=8, data at nodes 0 and 2: %.6f, %.6f; weight at node 0: %.6f" % (b[0], b[2], TAU / 8))
print("N=8, node 2 weight %.6f; kernel from node 2 at node 0 %.6f; node 0 curvature %.6f, self-pull %.6f; N=64 spacing at node 0 %.6f m"
      % (n2[2] * TAU / 8, dk(n0[0], n2[0], n2[1]), n0[3], -n0[3] / (2 * TAU) * n0[2] * TAU / 8, n0[2] * TAU / 64))
mu = solve(M, b); print("N=8, density mu at nodes 0, 1, 2: %.6f, %.6f, %.6f" % tuple(mu[:3]))
ny, pa = {}, {}
for N in [8, 16, 32, 64]:
    ny[N], pa[N] = abs(ny_u(N, G1) - 0.16), abs(panel_u(N, G1) - 0.16)
    print("N=%d: Nystrom error %s K, panels error %s K" % (N, e(ny[N]), e(pa[N])))
for N in [128, 256]: pa[N] = abs(panel_u(N, G1) - 0.16); print("N=%d: panels error %s K" % (N, e(pa[N])))
print("panel order, log2 of the error ratio from 128 to 256: %.2f" % math.log2(pa[128] / pa[256]))
print("Nystrom N=64 gives u = %.6f K" % ny_u(64, G1))
assert ny[64] < 1e-9 and ny[32] < 1e-4 < ny[16]       # exponential: each doubling far more than 4x
assert 1.9 < math.log2(pa[128] / pa[256]) < 2.1        # panels: a power, error / 4 per doubling
print("chart,N, 8, 16, 32, 64")
print("chart,log10 error Nystrom," + ",".join(" " + lg(ny[N]) for N in [8, 16, 32, 64]))
print("chart,log10 error panels," + ",".join(" " + lg(pa[N]) for N in [8, 16, 32, 64]))

ex = math.exp(0.5) * math.cos(0.3); print("second test: rim data e^x cos y, exact u at (0.5, 0.3) = %.6f" % ex)
for N in [16, 32, 64]: print("Nystrom N=%d: error %s" % (N, e(abs(ny_u(N, G2) - ex))))
for N in [16, 32, 64, 128]:
    M, b, nd = nystrom(N, G2); k, x = gmres(M, b)
    print("GMRES N=%d: %d steps to residual 1e-10" % (N, k))
assert k <= 10 and abs(ny_eval(nd, x, PX) - ny_eval(nd, solve(M, b), PX)) < 1e-9   # GMRES = elimination
P = sum(ell(TAU * j / 1000)[2] * TAU / 1000 for j in range(1000))
print("rim length %.6f m; dense matrix N=32: %d entries" % (P, 32 * 32))
gr = {}
for h, om in [(0.1, 1.7), (0.05, 1.8), (0.025, 1.9)]:
    v, n, nnz, sw = grid_u(h, G2, om); gr[h] = abs(v - ex)
    print("grid h=%.3f m: %d unknowns, %d nonzeros, %d sweeps, error %s" % (h, n, nnz, sw, e(gr[h])))
print("grid order, log2 of the error ratio from h=0.05 to 0.025: %.2f" % math.log2(gr[0.05] / gr[0.025]))
assert 1.8 < math.log2(gr[0.05] / gr[0.025]) < 2.2 and gr[0.025] > 10 * abs(ny_u(32, G2) - ex)
v = grid_u(0.1, G1, 1.7)[0]; print("grid h=0.1 on x^2 - y^2: u = %.6f K, exact on quadratics" % v)
assert abs(v - 0.16) < 1e-11
for N in [32, 64]: print("grid with spacing = rim length / %d: %d unknowns" % (N, len(grid_pts(P / N))))

print("near the rim, N=64, points (2 - d, 0): error in K, against the exact (2 - d)^2")
for d in [0.25, 0.1, 0.05, 0.02]:
    x = (2 - d, 0.0); print("d=%.2f m: u exact %.4f, error %s" % (d, x[0] * x[0], e(abs(ny_u(64, G1, x) - x[0] * x[0]))))
assert abs(ny_u(64, G1, (1.98, 0.0)) - 1.98 * 1.98) > 1.0
print("what breaks")
for N in [32, 64]: print("curvature diagonal dropped, N=%d: error %s" % (N, e(abs(ny_u(N, G1, diag=False) - 0.16))))
assert abs(ny_u(64, G1, diag=False) - 0.16) > 1e5 * ny[64]
M = nystrom(32, G1, half=0.5)[0]
print("sign flipped, +I/2 + K, N=32: every row sums to 0 within 1e-12: %s" % ("yes" if max(abs(sum(r)) for r in M) < 1e-12 else "no"))
print("ALL CHECKS PASS")
