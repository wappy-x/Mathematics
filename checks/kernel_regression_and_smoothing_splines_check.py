# Kernel regression and smoothing splines -- the check behind the card; only math is imported.
# Twelve coffee waits, one every 20 minutes from 7:00 to 10:40.  Time x is in hours after 7:00.
# Nadaraya-Watson and local-linear fits with bell weights, bandwidth 30 minutes; a cubic
# smoothing spline by Reinsch's equations, checked against a fine-grid penalised fit; and the
# smoothing level chosen by leave-one-out cross-validation, by refitting and by the hat shortcut.
import math

X = [i / 3 for i in range(12)]
Y = [1.5, 3.2, 4.4, 6.5, 7.2, 8.1, 6.8, 6.6, 4.7, 4.4, 2.9, 2.7]
H = 0.5
clock = lambda x: f"{7 + int(round(x * 60)) // 60}:{int(round(x * 60)) % 60:02d}"

def bell(x0, xs, h): return [math.exp(-((x - x0) / h) ** 2 / 2) for x in xs]

def nw(x0, xs, ys, h):
    w = bell(x0, xs, h)
    return sum(a * b for a, b in zip(w, ys)) / sum(w)

def loclin(x0, xs, ys, h):                  # weighted least-squares line, read at x0
    w = bell(x0, xs, h)
    s0, s1, s2 = sum(w), sum(a * (x - x0) for a, x in zip(w, xs)), sum(a * (x - x0) ** 2 for a, x in zip(w, xs))
    l = [a * (s2 - (x - x0) * s1) / (s0 * s2 - s1 * s1) for a, x in zip(w, xs)]
    return sum(a * b for a, b in zip(l, ys)), l

def solve(A, b):                            # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [v] for row, v in zip(A, b)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            if f: M[r] = [a - f * d for a, d in zip(M[r], M[c])]
    z = [0.0] * n
    for r in range(n - 1, -1, -1):
        z[r] = (M[r][n] - sum(M[r][k] * z[k] for k in range(r + 1, n))) / M[r][r]
    return z

def spline(xs, ys, lam):                    # Reinsch: (R + lam Q'Q) gamma = Q'y, g = y - lam Q gamma
    n, h = len(xs), [xs[i + 1] - xs[i] for i in range(len(xs) - 1)]
    Q = [[0.0] * (n - 2) for _ in range(n)]
    R = [[0.0] * (n - 2) for _ in range(n - 2)]
    for j in range(n - 2):
        Q[j][j], Q[j + 1][j], Q[j + 2][j] = 1 / h[j], -1 / h[j] - 1 / h[j + 1], 1 / h[j + 1]
        R[j][j] = (h[j] + h[j + 1]) / 3
        if j < n - 3: R[j][j + 1] = R[j + 1][j] = h[j + 1] / 6
    A = [[R[a][b] + lam * sum(Q[i][a] * Q[i][b] for i in range(n)) for b in range(n - 2)] for a in range(n - 2)]
    gam = solve(A, [sum(Q[i][a] * ys[i] for i in range(n)) for a in range(n - 2)])
    g = [ys[i] - lam * sum(Q[i][a] * gam[a] for a in range(n - 2)) for i in range(n)]
    pen = sum(gam[a] * R[a][b] * gam[b] for a in range(n - 2) for b in range(n - 2))
    return g, pen

def grid_fit(lam, per=20):                  # road 2: values on a 1-minute grid, second differences
    m, d = 11 * per + 1, 1 / (3 * per)
    A = [[0.0] * m for _ in range(m)]; b = [0.0] * m
    for i, y in enumerate(Y): A[i * per][i * per] += 1; b[i * per] += y
    for k in range(1, m - 1):
        c = {k - 1: 1.0, k: -2.0, k + 1: 1.0}
        for p, u in c.items():
            for q, v in c.items(): A[p][q] += lam * u * v / d ** 3
    g = solve(A, b)
    return [g[i * per] for i in range(12)]

def loo(lam):                               # leave-one-out: real refits, and the hat shortcut
    g, _ = spline(X, Y, lam)
    refit = shortcut = 0.0
    for i in range(12):
        gi, _ = spline(X[:i] + X[i + 1:], Y[:i] + Y[i + 1:], lam)
        refit += (Y[i] - spline_at(X[:i] + X[i + 1:], gi, X[i])) ** 2
        sii = spline(X, [1.0 if j == i else 0.0 for j in range(12)], lam)[0][i]
        shortcut += ((Y[i] - g[i]) / (1 - sii)) ** 2
    return refit / 12, shortcut / 12

def spline_at(xs, g, x0):                   # natural cubic spline through (xs, g), evaluated at x0
    n, h = len(xs), [xs[i + 1] - xs[i] for i in range(len(xs) - 1)]
    A = [[0.0] * n for _ in range(n)]; b = [0.0] * n
    A[0][0] = A[n - 1][n - 1] = 1.0
    for i in range(1, n - 1):
        A[i][i - 1], A[i][i], A[i][i + 1] = h[i - 1] / 6, (h[i - 1] + h[i]) / 3, h[i] / 6
        b[i] = (g[i + 1] - g[i]) / h[i] - (g[i] - g[i - 1]) / h[i - 1]
    s = solve(A, b)
    if x0 < xs[0]: return g[0] + ((g[1] - g[0]) / h[0] - h[0] * s[1] / 6) * (x0 - xs[0])  # straight past the ends
    if x0 > xs[-1]: return g[-1] + ((g[-1] - g[-2]) / h[-1] + h[-1] * s[-2] / 6) * (x0 - xs[-1])
    i = max(j for j in range(n - 1) if xs[j] <= x0)
    a, t = xs[i + 1] - x0, x0 - xs[i]
    return (s[i] * a ** 3 + s[i + 1] * t ** 3) / (6 * h[i]) + (g[i] / h[i] - s[i] * h[i] / 6) * a + (g[i + 1] / h[i] - s[i + 1] * h[i] / 6) * t

print("waits, time  " + " ".join(f"{clock(x):>5}" for x in X))
print("waits, min   " + " ".join(f"{y:5.1f}" for y in Y))
w9 = bell(2.0, X, H)
print("9:00 weights " + " ".join(f"{w:.4f}" for w in w9))
print("9:00 w*wait  " + " ".join(f"{w * y:.4f}" for w, y in zip(w9, Y)))
nw9 = nw(2.0, X, Y, H)
print(f"9:00 NW: sum(w*wait) {sum(w * y for w, y in zip(w9, Y)):.4f} / sum(w) {sum(w9):.4f} = {nw9:.4f}")
nw7, (ll7, l7) = nw(0.0, X, Y, H), loclin(0.0, X, Y, H)
w7 = bell(0.0, X, H)
print(f"7:00 NW: sum(w*wait) {sum(w * y for w, y in zip(w7, Y)):.4f} / sum(w) {sum(w7):.4f} = {nw7:.4f}")
hand = lambda c: [math.exp(-2 * (i - c) ** 2 / 9) for i in range(12)]   # by hand: visits 20|i - c| min away weigh e^(-2(i-c)^2/9)
assert all(abs(sum(a * y for a, y in zip(hand(c), Y)) / sum(hand(c)) - v) < 1e-12 for c, v in ((6, nw9), (0, nw7))), "NW from hand-built weights"
print(f"7:00 weighted mean time of its weights {sum(a * x for a, x in zip(w7, X)) / sum(w7) * 60:.2f} min; local-linear {ll7:.4f}; observed {Y[0]}")
print("7:00 local-linear weights " + " ".join(f"{v:.4f}" for v in l7[:5]))
line = [1.5 + 5.0 * x for x in X]            # a wait rising 5 minutes per hour
print(f"on a straight line 1.5 + 5x: NW at 7:00 {nw(0.0, X, line, H):.4f}, local-linear {loclin(0.0, X, line, H)[0]:.4f}, "
      f"NW at 9:00 {nw(2.0, X, line, H):.4f}, NW at 10:40 {nw(X[-1], X, line, H):.4f} (true {line[-1]:.4f})")
assert abs(sum(l7) - 1) < 1e-12 and abs(sum(v * x for v, x in zip(l7, X))) < 1e-12, "local-linear weights reproduce lines"
assert abs(loclin(0.0, X, line, H)[0] - 1.5) < 1e-12, "local-linear has no edge bias on a line"
assert nw(0.0, X, line, H) > 1.5 + 0.5, "the plain average is pulled inward at the edge"

LAMS = [10 ** (k / 4) for k in range(-16, 5)]
cv = [(lam,) + loo(lam) for lam in LAMS]
for lam, a, b in cv:
    assert abs(a - b) < 1e-9, "the hat shortcut equals real refits"
best = min(cv, key=lambda r: r[1])
print("lambda  " + " ".join(f"{lam:7.4f}" for lam, _, _ in cv[8:]))
print("LOO-CV  " + " ".join(f"{a:7.4f}" for _, a, _ in cv[8:]))
lam = best[0]
g, pen = spline(X, Y, lam)
gg = grid_fit(lam)
dfof = lambda l: sum(spline(X, [1.0 if j == i else 0.0 for j in range(12)], l)[0][i] for i in range(12)); df = dfof(lam)
rss = sum((y - v) ** 2 for y, v in zip(Y, g))
print(f"chosen lambda {lam:.4f}: LOO-CV refits {best[1]:.4f}, hat shortcut {best[2]:.4f}; effective df {df:.2f}")
print("spline fit, Reinsch  " + " ".join(f"{v:.2f}" for v in g))
print("spline fit, grid     " + " ".join(f"{v:.2f}" for v in gg))
print(f"max gap Reinsch vs grid {max(abs(a - b) for a, b in zip(g, gg)):.4f}; RSS {rss:.4f} + lambda x penalty {lam * pen:.4f} = {rss + lam * pen:.4f}")
assert max(abs(a - b) for a, b in zip(g, gg)) < 2e-3, "two roads to the spline agree"
obj = lambda v: sum((y - u) ** 2 for y, u in zip(Y, v)) + lam * spline(X, v, 0.0)[1]
for i in range(12):                         # road 3: nudging any fitted value raises the objective
    for e in (0.01, -0.01):
        assert obj([u + (e if j == i else 0) for j, u in enumerate(g)]) > obj(g), "Reinsch fit is the minimiser"
nw_all = [nw(x, X, Y, H) for x in X]; ll_all = [loclin(x, X, Y, H)[0] for x in X]
print("chart, NW           " + " ".join(f"{v:.2f}" for v in nw_all))
print("chart, local-linear " + " ".join(f"{v:.2f}" for v in ll_all))
g0, _ = spline(X, Y, 1e-6); ginf, _ = spline(X, Y, 1e6)
mx, my = sum(X) / 12, sum(Y) / 12
b1 = sum((x - mx) * (y - my) for x, y in zip(X, Y)) / sum((x - mx) ** 2 for x in X)
assert abs(ginf[6] - (my + b1 * (X[6] - mx))) < 1e-3, "a huge lambda leaves the least-squares line"
print(f"lambda 0.000001: RSS {sum((y - v) ** 2 for y, v in zip(Y, g0)):.4f}, LOO-CV {loo(1e-6)[0]:.4f}, df {dfof(1e-6):.2f}")
print(f"lambda 1000000: 9:00 value {ginf[6]:.4f}, least-squares line at 9:00 {my + b1 * (X[6] - mx):.4f}, LOO-CV {loo(1e6)[0]:.4f}, df {dfof(1e6):.2f}")
print(f"bandwidth 30 read as hours: NW at 7:00 {nw(0.0, X, Y, 30.0):.4f}, mean of all waits {sum(Y) / 12:.4f}")
print("ALL CHECKS PASS")
