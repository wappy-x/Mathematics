# Multiple regression and Gauss-Markov -- the check behind the card.  Standard library
# only: solver, Gram-Schmidt residuals and random numbers are written out here.  Twelve
# sales: price ($ thousand) from floor area (m2), age (years), distance to station (km).
from math import sqrt, floor
AREA = [62, 75, 80, 88, 95, 104, 110, 118, 125, 136, 148, 160]
AGE = [35, 12, 28, 5, 40, 18, 8, 30, 15, 22, 10, 3]
DIST = [0.5, 1.8, 0.6, 1.4, 0.9, 2.6, 1.0, 1.5, 3.0, 2.2, 2.4, 3.6]
PRICE = [124, 140, 172, 200, 180, 171, 260, 210, 226, 250, 301, 298]
n, p = 12, 4
X = [[1.0] * n, [float(a) for a in AREA], [float(g) for g in AGE], DIST]  # the columns of X
y = [float(v) for v in PRICE]
def dot(u, v):                           # plain running sum, same order as the Rust
    s = 0.0
    for a, b in zip(u, v):
        s += a * b
    return s
def solve(M, rhs):                       # Gaussian elimination with partial pivoting
    m = len(M)
    A = [row[:] + [r] for row, r in zip(M, rhs)]
    for k in range(m):
        piv = max(range(k, m), key=lambda i: abs(A[i][k]))
        A[k], A[piv] = A[piv], A[k]
        for i in range(k + 1, m):
            f = A[i][k] / A[k][k]
            for j in range(k, m + 1):
                A[i][j] -= f * A[k][j]
    x = [0.0] * m
    for k in range(m - 1, -1, -1):       # back substitution
        x[k] = (A[k][m] - dot(A[k][k + 1:m], x[k + 1:])) / A[k][k]
    return x
def weights(cols, wt):                   # rows of (X^T W X)^-1 X^T W, W = diag(wt)
    Xw = [[c[i] * wt[i] for i in range(n)] for c in cols]
    XtWX = [[dot(a, b) for b in cols] for a in Xw]
    G = [solve(XtWX, [1.0 * (i == j) for i in range(p)]) for j in range(p)]   # G is symmetric
    return [[dot(G[j], [c[i] for c in Xw]) for i in range(n)] for j in range(p)], G
def residual(v, others):                 # v minus its shadow on the others (Gram-Schmidt)
    basis = []
    for u in others + [v]:
        w = u[:]
        for q in basis:
            c = dot(w, q)
            w = [a - c * b for a, b in zip(w, q)]
        if u is v:
            return w
        basis.append([a / sqrt(dot(w, w)) for a in w])
row = lambda label, v, fmt="{:>12.6f}": print(f"{label:<36}" + "".join(fmt.format(x) for x in v))
spread = lambda e: sqrt(dot(e, e) / (n - p))   # s from the misses: divide by n - p, not n
# road 1: the normal equations X^T X b = X^T y, solved by elimination
XtX = [[dot(a, b) for b in X] for a in X]
beta = solve(XtX, [dot(a, y) for a in X])
L, G = weights(X, [1.0] * n)             # L = (X^T X)^-1 X^T, G = (X^T X)^-1
fit = [dot([c[i] for c in X], beta) for i in range(n)]
res = [a - b for a, b in zip(y, fit)]
rss, s_hat = dot(res, res), spread(res)
# road 2: partial out the other columns; each coefficient is then a one-column slope
rj = [residual(X[j], X[:j] + X[j + 1:]) for j in range(p)]
beta2 = [dot(r, y) / dot(r, r) for r in rj]
for j in range(p):
    row(f"X^T X row {j + 1}   | X^T y {dot(X[j], y):.0f}", XtX[j], "{:>12.2f}")
print(f"{'':<36}" + "".join(f"{s:>12}" for s in ("intercept", "area", "age", "distance")))
row("road 1, normal equations", beta)
row("road 2, partialling out", beta2)
row("standard error, from (X^T X)^-1", [s_hat * sqrt(G[j][j]) for j in range(p)])
row("standard error, from residual sizes", [s_hat / sqrt(dot(r, r)) for r in rj])
print(f"residual sum of squares {rss:.4f}; spread s = sqrt(RSS / {n - p}) = {s_hat:.6f}")
ra = residual(X[1], [X[0]])
alone = dot(ra, y) / dot(ra, ra)
house = [1.0, 100.0, 20.0, 1.5]          # holding the others fixed, and leaving them out
print(f"house 100 m2, 20 years, 1.5 km: {dot(house, beta):.4f}; at 110 m2: {dot(house, beta) + 10 * beta[1]:.4f}; 10 m2 alone: {10 * alone:.4f}")
drift = [dot(ra, X[k]) / dot(ra, ra) for k in (2, 3)]
rebuilt = beta[1] + beta[2] * drift[0] + beta[3] * drift[1]
print(f"area alone: slope {alone:.6f}; age drift {drift[0]:.6f}, distance drift {drift[1]:.6f}")
print(f"area alone, rebuilt from the full fit: {rebuilt:.6f}")
# Gauss-Markov: OLS weights L against A, the least-squares fit of the first 8 sales only
A, _ = weights(X, [1.0] * 8 + [0.0] * 4)
miss = max(abs(dot(M[j], X[k]) - (j == k)) for M in (L, A) for j in range(p) for k in range(p))
D = [a - b for a, b in zip(A[1], L[1])]
ll, aa = dot(L[1], L[1]), dot(A[1], A[1])
print(f"LX = I and AX = I to 1e-9: {'yes' if miss < 1e-9 else 'no'}; (X^T X)^-1 area entry {G[1][1]:.9f}")
print(f"area variance / sigma^2: OLS {ll:.9f}, first 8 {aa:.9f}, gap {aa - ll:.9f}, D D^T {dot(D, D):.9f}, ratio {aa / ll:.4f}")
state = 20260928                         # SplitMix64, seed 20260928
def draw():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
hat = [[dot([c[i] for c in X], [L[j][k] for j in range(p)]) for k in range(n)] for i in range(n)]  # H = X L
excess, bias = [], 0.0
for _ in range(200):                     # 200 random rivals L + M(I - H): unbiased by design
    M = [[0.02 * draw() - 0.01 for _ in range(n)] for _ in range(p)]
    R = [[L[j][k] + M[j][k] - dot(M[j], [hat[i][k] for i in range(n)]) for k in range(n)] for j in range(p)]
    bias = max([bias] + [abs(dot(R[j], X[k]) - (j == k)) for j in range(p) for k in range(p)])
    excess.append(dot(R[1], R[1]) - ll)
print(f"200 random rivals, all unbiased to 1e-9: {'yes' if bias < 1e-9 else 'no'}; area-variance excess {min(excess):.9f} to {max(excess):.9f}")
sigma, reps, est, s2 = 7.6, 20000, [[], []], []
for _ in range(reps):                    # truth = the fit above; uniform noise, not normal
    ys = [f + (2.0 * draw() - 1.0) * sigma * sqrt(3.0) for f in fit]
    est[0].append(dot(L[1], ys))
    est[1].append(dot(A[1], ys))
    s2.append(spread([a - dot(r, ys) for a, r in zip(ys, hat)]) ** 2)   # s^2 of this market
sim, bins = [], [[], []]                 # sample mean and sd of each rule's area coefficient
for k, (lab, v) in enumerate((("OLS", ll), ("first 8", aa))):
    mean = dot(est[k], [1.0] * reps) / reps
    sd = sqrt(dot(est[k], est[k]) / reps - mean * mean)
    sim.append((mean, sd, sigma * sqrt(v)))
    bins[k] = [sum(1 for e in est[k] if floor((e - 1.8) / 0.1) == b) for b in range(10)]
    print(f"simulated {lab:<8} mean {mean:.6f} +/- {sd / sqrt(reps):.6f}, sd {sd:.6f}, exact sd {sigma * sqrt(v):.6f}")
v2 = dot(s2, [1.0] * reps) / reps
e2 = sqrt(dot(s2, s2) / reps - v2 * v2) / sqrt(reps)
print(f"simulated s^2 mean {v2:.4f} +/- {e2:.4f}; sigma^2 {sigma * sigma:.4f}")
print("chart, bin centres " + " ".join(f"{1.85 + 0.1 * b:.2f}" for b in range(10)))
print("chart, OLS counts " + " ".join(str(c) for c in bins[0]))
print("chart, first 8 counts " + " ".join(str(c) for c in bins[1]))
sp2 = [(4.0 * d) * (4.0 * d) for d in DIST]  # what breaks: spread 4 x distance ($ thousand)
W, Gw = weights(X, [1.0 / s for s in sp2])
ols_var, gls_var = dot([v * v for v in L[1]], sp2), dot([w * w for w in W[1]], sp2)
print(f"unequal spreads, area sd: OLS {sqrt(ols_var):.6f}, weighted {sqrt(gls_var):.6f}, from inverse {sqrt(Gw[1][1]):.6f}")
rw = residual([12.0 * d for d in DIST], X)
print(f"walking minutes = 12 x km: length left after the other columns {sqrt(dot(rw, rw)):.6f}")
px = lambda a: 50 + (a - 60) * 2.9      # figure: area 60..160 -> x 50..340
py = lambda v: 200 - (v - 100) * 0.8     # price 100..320 -> y 200..24
print("figure, points " + " ".join(f"{px(a):.1f},{py(v):.1f}" for a, v in zip(AREA, PRICE)))
ma, my = dot(X[0], X[1]) / n, dot(X[0], y) / n
held = beta[0] + beta[2] * dot(X[0], X[2]) / n + beta[3] * dot(X[0], X[3]) / n
print(f"figure, area alone {py(my + (60 - ma) * alone):.1f} to {py(my + (160 - ma) * alone):.1f}; held fixed "
      f"{py(held + 60 * beta[1]):.1f} to {py(held + 160 * beta[1]):.1f}; centre {px(ma):.1f},{py(my):.1f}")
assert max(abs(a - b) for a, b in zip(beta, beta2)) < 1e-9          # two roads, one fit
assert abs(alone - rebuilt) < 1e-9                                   # the left-out-column identity
assert abs(ll - G[1][1]) < 1e-12                                     # L L^T = (X^T X)^-1
assert abs((aa - ll) - dot(D, D)) < 1e-12                            # cross terms vanish
assert miss < 1e-9 and bias < 1e-9                                 # L and every rival unbiased
assert min(excess) > 0                                               # every rival loses
for mean, sd, exact in sim:                                          # simulation within 4 SE
    assert abs(mean - beta[1]) < 4 * sd / sqrt(reps)                 # unbiased
    assert abs(sd - exact) < 4 * exact / sqrt(2 * reps)              # spread as the formula says
assert abs(v2 - sigma * sigma) < 4 * e2                              # s^2 right on average
assert abs(gls_var - Gw[1][1]) < 1e-12                               # two roads, weighted sd
assert gls_var < ols_var                                             # the theorem fails here
print("ALL CHECKS PASS")
