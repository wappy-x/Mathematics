# CAPM and beta -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the linear solver, the random numbers,
# the bell-curve draws and the least-squares fits are all written out here.
from math import sqrt, log, cos, pi

vol = [0.30, 0.20, 0.25]                          # Kestrel, Oakridge, Pinecrest: yearly volatility
rho = [[1.0, 0.5, 0.6], [0.5, 1.0, 0.5], [0.6, 0.5, 1.0]]   # correlations between them
w_mkt = [0.2, 0.4, 0.4]                           # the market: share of all money in each
rf, prem = 0.04, 0.04                             # bank rate, and market premium E[R_M] - rf
C = [[rho[i][j] * vol[i] * vol[j] for j in range(3)] for i in range(3)]

def dot(a, b): return sum(x * y for x, y in zip(a, b))
def matvec(A, v): return [dot(row, v) for row in A]
def pct(x): return f"{100 * x:10.4f}"

# ---- road 1: beta = covariance with the market / variance of the market, then the SML ----
cov_iM = matvec(C, w_mkt)
var_M = dot(w_mkt, cov_iM)
beta = [c / var_M for c in cov_iM]
mu = [rf + b * prem for b in beta]                # the security market line
def left_over(i):                                 # variance of (share minus beta x market)
    a = [(1.0 if j == i else 0.0) - beta[i] * w_mkt[j] for j in range(3)]
    return sqrt(dot(a, matvec(C, a)))
resid = [left_over(i) for i in range(3)]

# ---- road 2: hand those returns to an optimiser; the best mix must be the market itself ----
def solve(A, b):                                  # Gaussian elimination with row swaps
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for k in range(n):
        p = max(range(k, n), key=lambda r: abs(M[r][k])); M[k], M[p] = M[p], M[k]
        for r in range(k + 1, n):
            f = M[r][k] / M[k][k]
            M[r] = [x - f * y for x, y in zip(M[r], M[k])]
    x = [0.0] * n
    for k in range(n - 1, -1, -1):
        x[k] = (M[k][n] - dot(M[k][k + 1:n], x[k + 1:])) / M[k][k]
    return x
def tangency(m):
    u = solve(C, [x - rf for x in m]); s = sum(u)
    return [x / s for x in u]
def sharpe(w, m): return (dot(w, m) - rf) / sqrt(dot(w, matvec(C, w)))
w_tan = tangency(mu)
# ---- road 3: no algebra at all, try every mix in 1% steps and keep the best Sharpe ratio ----
grid = [(a / 100, b / 100, (100 - a - b) / 100) for a in range(101) for b in range(101 - a)]
w_grid = max(grid, key=lambda w: sharpe(w, mu))
mu_bad = [0.10, mu[1], mu[2]]                     # Kestrel priced to earn 10%, not 8.8%
w_bad = tangency(mu_bad)
lam = [(mu[i] - rf) / cov_iM[i] for i in range(3)]   # tangency condition: equal for every share

# ---- least squares on excess returns: slope = beta, intercept = alpha ----
def fit(x, y):
    n = len(x); xb = sum(x) / n; yb = sum(y) / n
    sxx = sum((a - xb) ** 2 for a in x); sxy = sum((a - xb) * (b - yb) for a, b in zip(x, y))
    b = sxy / sxx; a = yb - b * xb
    s2 = sum((v - a - b * u) ** 2 for u, v in zip(x, y)) / (n - 2)
    return a, b, sqrt(s2 / sxx), sqrt(s2 * (1 / n + xb * xb / sxx)), sxx, sxy
qx = [-2.0, -1.0, 1.0, 2.0]                       # four quarters, market excess return, %
qy = [-0.9, -2.7, 3.7, 1.9]                       # Kestrel excess return, same quarters, %
qa, qb, _, _, sxx, sxy = fit(qx, qy)
def sse(b):                                       # second road: search the slope directly
    a = sum(qy) / 4 - b * sum(qx) / 4
    return sum((v - a - b * u) ** 2 for u, v in zip(qx, qy))
lo, hi = -5.0, 5.0
for _ in range(200):
    m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    if sse(m1) < sse(m2): hi = m2
    else: lo = m1
qb_search = (lo + hi) / 2
mixed = (sxy / 3) / (sxx / 4)                     # covariance over n-1, variance over n
ra, rb, _, _, _, _ = fit([v + 1 for v in qx], [v + 1 for v in qy])   # forgot the 1% bank rate

# ---- road 4: simulate 20 years of months from this market, estimate beta by regression ----
MASK = (1 << 64) - 1; state = 0x9E3779B97F4A7C15
def uniform():                                    # xorshift64*, top 53 bits
    global state
    state ^= state >> 12; state ^= (state << 25) & MASK; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & MASK) >> 11) / 2.0 ** 53
def normal(): return sqrt(-2.0 * log(1.0 - uniform())) * cos(2.0 * pi * uniform())
Cm = [[c / 12 for c in row] for row in C]         # one month's covariance
L = [[0.0] * 3 for _ in range(3)]                 # Cholesky: L times L-transpose = Cm
for i in range(3):
    for j in range(i + 1):
        s = Cm[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
        L[i][j] = sqrt(s) if i == j else s / L[j][j]
xs, ys = [], []
for t in range(240):
    z = [normal() for _ in range(3)]
    R = [mu[i] / 12 + dot(L[i], z) for i in range(3)]
    xs.append(dot(w_mkt, R) - rf / 12); ys.append(R[0] - rf / 12)
sa, sb, sb_se, sa_se, _, _ = fit(xs, ys)
windows = [fit(xs[k:k + 60], ys[k:k + 60])[1] for k in range(0, 240, 60)]

K3 = " (K, O, P)"
rows = [("covariances K-K, K-O, K-P, %^2", [1e4 * C[0][j] for j in range(3)]),
        ("covariances O-O, O-P, P-P, %^2", [1e4 * C[1][1], 1e4 * C[1][2], 1e4 * C[2][2]]),
        ("cov with market, %^2" + K3, [1e4 * c for c in cov_iM]),
        ("market variance %^2, volatility %", [1e4 * var_M, 100 * sqrt(var_M)]),
        ("beta" + K3, beta), ("SML expected return, %" + K3, [100 * m for m in mu]),
        ("Kestrel premium, market return, %", [100 * beta[0] * prem, 100 * dot(w_mkt, mu)]),
        ("Kestrel var split: market, private", [1e4 * beta[0] ** 2 * var_M, 1e4 * resid[0] ** 2]),
        ("Kestrel market-part vol, corr", [100 * beta[0] * sqrt(var_M), cov_iM[0] / (vol[0] * sqrt(var_M))]),
        ("private volatility, %" + K3, [100 * r for r in resid]),
        ("excess per unit vol" + K3, [(mu[i] - rf) / vol[i] for i in range(3)]),
        ("excess / cov with market" + K3, lam),
        ("tangency by solve, %" + K3, [100 * x for x in w_tan]),
        ("tangency by grid, %" + K3, [100 * x for x in w_grid]),
        ("market Sharpe ratio", [sharpe(w_mkt, mu)]),
        ("if Kestrel paid 10%, %" + K3, [100 * x for x in w_bad]),
        ("quarters: mean x, mean y", [sum(qx) / 4, sum(qy) / 4]), ("quarters: Sxx, Sxy", [sxx, sxy]),
        ("quarters: beta, formula and search", [qb, qb_search]), ("quarters: alpha per quarter, %", [qa]),
        ("wrong: CML, total vol for Kestrel, %", [100 * (rf + vol[0] / sqrt(var_M) * prem)]),
        ("wrong: correlation for beta, %", [100 * (rf + cov_iM[0] / (vol[0] * sqrt(var_M)) * prem)]),
        ("wrong: beta x market return, %", [100 * beta[0] * (rf + prem)]),
        ("wrong: cov over n-1, var over n", [mixed]), ("wrong: raw returns, alpha % and beta", [ra, rb]),
        ("sim 240 months: beta, std error", [sb, sb_se]),
        ("sim: alpha per year %, std error", [1200 * sa, 1200 * sa_se]),
        ("sim: beta by 5-year window", windows),
        ("try: premium 6%, Kestrel %", [100 * (rf + beta[0] * 0.06)]),
        ("try: rf 2%, market 8%, Kestrel %", [100 * (0.02 + beta[0] * 0.06)]),
        ("try: beta -0.5, %", [100 * (rf - 0.5 * prem)])]
for name, v in rows:
    print(f"{name:<40}" + "".join(f"{x:10.4f}" for x in v))
print("chart, SML at beta 0.0 to 1.6:" + "".join(f"{100 * (rf + b / 5 * prem):6.2f}" for b in range(9)))

assert abs(mu[0] - 0.088) < 1e-12, "Kestrel on the SML: 8.8%"
assert max(abs(a - b) for a, b in zip(w_tan, w_mkt)) < 1e-12, "solved tangency = market"
assert max(abs(a - b) for a, b in zip(w_grid, w_mkt)) < 1e-9, "grid search finds the market"
assert abs(qb - qb_search) < 1e-6, "two roads to the fitted slope"
assert max(lam) - min(lam) < 1e-12, "same reward per unit covariance for every share"
assert abs(ra - (qa + 1.0 * (1 - rb))) < 1e-12, "raw returns: intercept absorbs rf x (1 - beta)"
assert abs(sb - beta[0]) < 2 * sb_se, "simulated regression within 2 standard errors"
assert abs(C[0][0] - (beta[0] ** 2 * var_M + resid[0] ** 2)) < 1e-12, "variance split 900 = 576 + 324"
print("ALL CHECKS PASS")
