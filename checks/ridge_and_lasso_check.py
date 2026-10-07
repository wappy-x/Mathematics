# Ridge and lasso -- the check behind the card; only math is imported.
# A used-car dealer prices cars from 20 intake measurements that move together
# (every pair correlated 0.8).  Truth: price = 15 + 4 x1 + 3 x2 + 2 x3, in
# $ thousand, plus noise of SD 3.  40 cars to fit, 100 more to validate.
import math

P, N, NV, RHO, SIG, A0, R = 20, 40, 100, 0.8, 3.0, 15.0, 2000
BETA = [4.0, 3.0, 2.0] + [0.0] * (P - 3)
LAMS = [0, 1, 2, 5, 10, 20, 50, 100, 200, 500]
M64, state = (1 << 64) - 1, 20260928

def uniform():                                # SplitMix64: a draw in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53

def normal():                                 # Box-Muller, cosine half only
    u = uniform()
    return math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * uniform())

def car():                                    # 20 readings sharing one factor
    f = normal()
    return [math.sqrt(RHO) * f + math.sqrt(1 - RHO) * normal() for _ in range(P)]

def dot(u, v): return sum(a * b for a, b in zip(u, v))

def solve(A, b):                              # Gaussian elimination, partial pivoting
    n = len(b)
    M = [A[i][:] + [b[i]] for i in range(n)]
    for k in range(n):
        p = max(range(k, n), key=lambda r: abs(M[r][k]))
        M[k], M[p] = M[p], M[k]
        for r in range(k + 1, n):
            f = M[r][k] / M[k][k]
            for c in range(k, n + 1):
                M[r][c] -= f * M[k][c]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][c] * x[c] for c in range(i + 1, n))) / M[i][i]
    return x

def ridge(G, c, lam):                         # road 1: solve (G + lam I) b = c
    return solve([[G[i][j] + (lam if i == j else 0.0) for j in range(len(c))]
                  for i in range(len(c))], c)

def descent(G, c, lam, lasso, sweeps=3000):   # road 2: one coefficient at a time
    b = [0.0] * len(c)
    for _ in range(sweeps):
        for j in range(len(c)):
            r = c[j] - sum(G[j][k] * b[k] for k in range(len(c)) if k != j)
            if lasso: b[j] = math.copysign(max(abs(r) - lam / 2, 0.0), r) / G[j][j] + 0.0
            else: b[j] = r / (G[j][j] + lam)
    return b

def snorm(v): return (1 - RHO) * dot(v, v) + RHO * sum(v) ** 2    # v' Sigma v

def risk(lam):                                # exact bias^2 and variance, fixed design
    Ai = [ridge(G, [float(i == k) for i in range(P)], lam) for k in range(P)]
    bias = [-lam * dot(Ai[i], BETA) for i in range(P)]
    AG = [[sum(Ai[i][m] * G[m][j] for m in range(P)) for j in range(P)] for i in range(P)]
    C = [[sum(AG[i][m] * Ai[m][j] for m in range(P)) for j in range(P)] for i in range(P)]
    return snorm(bias), SIG ** 2 * ((1 - RHO) * sum(C[i][i] for i in range(P)) + RHO * sum(map(sum, C)))

def fit(y, lam, lasso):                       # centred fit, intercept left unpenalised
    c = [dot(col, y) for col in Xc]
    b = descent(G, c, lam, True) if lasso else ridge(G, c, lam)
    return sum(y) / N - dot(mx, b), b

def errs(Xs, ys, a, b): return [(yy - a - dot(x, b)) ** 2 for x, yy in zip(Xs, ys)]
def mean_se(e): m = sum(e) / len(e); return m, math.sqrt(sum((t - m) ** 2 for t in e) / (len(e) - 1) / len(e))
def truth(a, b): return SIG ** 2 + (A0 - a) ** 2 + snorm([u - v for u, v in zip(BETA, b)])
def price(x): return A0 + dot(BETA, x) + SIG * normal()

X = [car() for _ in range(N)]; y = [price(x) for x in X]
Xv = [car() for _ in range(NV)]; yv = [price(x) for x in Xv]
mx = [sum(r[j] for r in X) / N for j in range(P)]
Xc = [[X[k][j] - mx[j] for k in range(N)] for j in range(P)]      # centred columns
G = [[dot(Xc[i], Xc[j]) for j in range(P)] for i in range(P)]
def unit(v): n = math.sqrt(dot(v, v)); return [t / n for t in v]
v, w = [1.0] * P, [1.0] + [0.0] * (P - 1)     # power and inverse iteration on G
for _ in range(300): v, w = unit([dot(g, v) for g in G]), unit(solve(G, w))
dmax, dmin = dot(v, [dot(g, v) for g in G]), dot(w, [dot(g, w) for g in G])
print("lambda  bias^2  variance  risk | ridge: val   true | lasso: val   true  kept")
rows = []
for lam in LAMS:
    b2, var = risk(lam)
    (ar, br), (al, bl) = fit(y, lam, False), fit(y, lam, True)
    vr, vl = mean_se(errs(Xv, yv, ar, br))[0], mean_se(errs(Xv, yv, al, bl))[0]
    rows.append((lam, b2 + var, vr, vl, ar, br, al, bl))
    print(f"{lam:>6} {b2:7.2f} {var:9.2f} {b2 + var:5.2f} | {vr:11.2f} {truth(ar, br):6.2f} |"
          f" {vl:11.2f} {truth(al, bl):6.2f} {sum(t != 0.0 for t in bl):5d}")
pr, pl, ols = min(rows, key=lambda r: r[2]), min(rows, key=lambda r: r[3]), rows[0]
print(f"G's strongest direction {dmax:.1f}, weakest {dmin:.2f}; slope variance along the weakest:"
      f" OLS {SIG**2 / dmin:.2f}, ridge {SIG**2 * dmin / (dmin + pr[0]) ** 2:.2f}")
print(f"ridge picked lambda {pr[0]}: validation {pr[2]:.2f} +- {mean_se(errs(Xv, yv, pr[4], pr[5]))[1]:.2f}")
print(f"lasso picked lambda {pl[0]}: validation {pl[3]:.2f} +- {mean_se(errs(Xv, yv, pl[6], pl[7]))[1]:.2f}")
print(f"true error per new car: OLS {truth(ols[4], ols[5]):.2f}, ridge {truth(pr[4], pr[5]):.2f},"
      f" lasso {truth(pl[6], pl[7]):.2f}, floor {SIG**2:.2f}")
Xn = [car() for _ in range(20000)]; yn = [price(x) for x in Xn]; sim = mean_se(errs(Xn, yn, pr[4], pr[5]))
print(f"ridge pick on 20000 fresh cars: {sim[0]:.2f} +- {sim[1]:.2f}")
for name, b in (("OLS  ", ols[5]), ("ridge", pr[5]), ("lasso", pl[7])):
    print(name, "b1..b6:", " ".join(f"{t:6.2f}" for t in b[:6]), f"| sum of all 20: {sum(b):.2f}")
print("lasso keeps:", ", ".join(f"x{j + 1} {t:.2f}" for j, t in enumerate(pl[7]) if t != 0.0))
kkt = max(abs(r - lam_s) if t != 0.0 else max(abs(r) - pl[0] / 2, 0.0) for t, r, lam_s in
          [(t, dot(col, y) - dot(g, pl[7]), math.copysign(pl[0] / 2, t)) for t, col, g in zip(pl[7], Xc, G)])
print(f"lasso optimality conditions, worst violation: {kkt:.9f}")
cd_gap = max(abs(a - b) for a, b in zip(pr[5], descent(G, [dot(col, y) for col in Xc], pr[0], False)))
print(f"ridge by elimination vs by descent, largest gap: {cd_gap:.9f}")
sims = []
for lam in (0, pr[0]):
    sims.append(mean_se([snorm([u - t for u, t in zip(BETA, fit([price(x) for x in X], lam, False)[1])])
                         for _ in range(R)]))
    print(f"risk at lambda {lam}: exact {rows[LAMS.index(lam)][1]:.2f}, {R} redrawn noises {sims[-1][0]:.2f} +- {sims[-1][1]:.2f}")
tw_r, tw_l = ridge([[2.0, 2.0], [2.0, 2.0]], [4.0, 4.0], 2.0), descent([[2.0, 2.0], [2.0, 2.0]], [4.0, 4.0], 2.0, True)
tw_cost = lambda b: 2 * (2 - b[0] - b[1]) ** 2 + 2 * (abs(b[0]) + abs(b[1]))
print(f"twins: ridge {tw_r[0]:.4f} {tw_r[1]:.4f}, fit error {2 * (2 - sum(tw_r)) ** 2:.4f}, penalty {2 * dot(tw_r, tw_r):.4f}; lasso {tw_l[0]:.4f} {tw_l[1]:.4f}, cost {tw_cost(tw_l):.4f}; split 0.75 0.75 costs {tw_cost([0.75, 0.75]):.4f}")
zs = [0.5 * k for k in range(7)]
sr = [ridge([[40.0]], [40.0 * z], 40.0)[0] for z in zs]
sl = [descent([[40.0]], [40.0 * z], 40.0, True, 5)[0] for z in zs]
print("chart, OLS slope ", " ".join(f"{z:5.2f}" for z in zs))
print("chart, ridge     ", " ".join(f"{t:5.2f}" for t in sr))
print("chart, lasso     ", " ".join(f"{t:5.2f}" for t in sl))
by_train = min(LAMS, key=lambda lam: mean_se(errs(X, y, *fit(y, lam, False)))[0])
Zt = [[1.0] * N] + [[r[j] for r in X] for j in range(P)]        # raw columns plus a column of ones
pen = ridge([[dot(u, v) for v in Zt] for u in Zt], [dot(u, y) for u in Zt], pr[0])   # charge on a too
Xc[0] = [t * 0.1 for t in Xc[0]]; G = [[dot(Xc[i], Xc[j]) for j in range(P)] for i in range(P)]
mx[0] *= 0.1; a_sc, b_sc = fit(y, pr[0], False); b_sc[0] *= 0.1
print(f"mistake, lambda by training error: picks {by_train}, true error {truth(ols[4], ols[5]):.2f}")
print(f"mistake, penalised intercept: {pen[0]:.2f} not {pr[4]:.2f}, true error {truth(pen[0], pen[1:]):.2f}")
print(f"mistake, x1 recorded divided by 10: b1 {b_sc[0]:.2f}, true error {truth(a_sc, b_sc):.2f}")
assert abs(sim[0] - truth(pr[4], pr[5])) < 4 * sim[1]              # formula vs fresh cars
sp = mean_se(errs(Xn, yn, pen[0], pen[1:])); assert abs(sp[0] - truth(pen[0], pen[1:])) < 4 * sp[1]  # intercept part
assert all(abs(s[0] - rows[LAMS.index(l)][1]) < 4 * s[1] for s, l in zip(sims, (0, pr[0])))
assert kkt < 1e-6 and cd_gap < 1e-9                                   # lasso certified; two ridge roads
assert abs(tw_r[0] - 2 / 3) < 1e-12 and abs(tw_l[0] + tw_l[1] - 1.5) < 1e-12
assert all(abs(a - z / 2) < 1e-12 and abs(b - max(z - 0.5, 0)) < 1e-12 for z, a, b in zip(zs, sr, sl))
print("ALL CHECKS PASS")
