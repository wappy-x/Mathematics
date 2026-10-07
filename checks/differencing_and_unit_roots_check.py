# Unit roots and differencing -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Random draws come from SplitMix64
# written out below, so the Rust check draws the same numbers; least squares is solved
# two ways by hand; the normal area is Simpson's rule; nothing imported knows the answer.
from math import log, exp, sqrt, cos, pi
M64 = (1 << 64) - 1
class Rng:                                     # SplitMix64 with a stated seed
    def __init__(s, seed): s.x = seed
    def u64(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64
        z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(s): return ((s.u64() >> 11) + 0.5) / 9007199254740992.0
    def normal(s):                             # Box-Muller, cosine half only
        u1 = s.unif(); u2 = s.unif()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
def reg1(x, v):     # road 1: least squares of v on a constant and x, from sums
    n = len(x); mx = sum(x) / n; mv = sum(v) / n
    sxx = sum((a - mx) ** 2 for a in x); sxv = sum((a - mx) * (b - mv) for a, b in zip(x, v))
    svv = sum((b - mv) ** 2 for b in v); g = sxv / sxx
    return g, sqrt((svv - g * sxv) / (n - 2) / sxx), (n, mx, mv, sxx, sxv, svv)
def df0(y):         # Dickey-Fuller with no lags: today's change on a constant and yesterday's level
    return reg1(y[:-1], [y[t + 1] - y[t] for t in range(len(y) - 1)])
def ols(X, v):      # road 2: normal equations by Gauss-Jordan; also returns standard errors
    k = len(X[0])
    A = [[sum(r[i] * r[j] for r in X) for j in range(k)] + [sum(r[i] * b for r, b in zip(X, v))]
         + [1.0 if i == j else 0.0 for j in range(k)] for i in range(k)]
    for c in range(k):
        p = c
        for i in range(c + 1, k):
            if abs(A[i][c]) > abs(A[p][c]): p = i
        A[c], A[p] = A[p], A[c]
        piv = A[c][c]; A[c] = [a / piv for a in A[c]]
        for i in range(k):
            if i != c:
                f = A[i][c]; A[i] = [a - f * b for a, b in zip(A[i], A[c])]
    b = [A[i][k] for i in range(k)]
    rss = sum((u - sum(bi * xi for bi, xi in zip(b, r))) ** 2 for r, u in zip(X, v))
    return b, [sqrt(rss / (len(v) - k) * A[i][k + 1 + i]) for i in range(k)]
def adf(y, p):      # augmented Dickey-Fuller: add p lagged changes to the regression
    d = [0.0] + [y[t] - y[t - 1] for t in range(1, len(y))]
    X = [[1.0, y[t - 1]] + [d[t - j] for j in range(1, p + 1)] for t in range(p + 1, len(y))]
    b, se = ols(X, d[p + 1:])
    return b, se, b[1] / se[1]
def adf1_fwl(y):    # road 3 for p = 1: partial the constant and lagged change out of both sides
    d = [0.0] + [y[t] - y[t - 1] for t in range(1, len(y))]; z = d[1:-1]
    def resid(v):
        g, _, (n, mz, mv, *_r) = reg1(z, v)
        return [b - mv - g * (a - mz) for a, b in zip(z, v)]
    ex = resid(y[1:-1]); ed = resid(d[2:])
    sxx = sum(a * a for a in ex); g = sum(a * b for a, b in zip(ex, ed)) / sxx
    rss = sum((b - g * a) ** 2 for a, b in zip(ex, ed))
    return g, g / sqrt(rss / (len(z) - 3) / sxx)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def Phi_left(c, n=2000):                       # normal area left of c < 0, by Simpson on [c, 0]
    h = -c / n
    s = phi(c) + phi(0.0) + sum((4 if i % 2 else 2) * phi(c + i * h) for i in range(1, n))
    return 0.5 - s * h / 3.0
def cv5(T): return -2.86154 - 2.8903 / T - 4.234 / T ** 2 - 40.040 / T ** 3   # MacKinnon 2010
def pr(label, v, f=6): print(f"{label:<44} {v:>12.{f}f}")
# ---- the share: $100, 250 trading days, daily log-return shocks of 1% ----
g = Rng(7); N = 250; e = [g.normal() for _ in range(N)]
y = [log(100.0)]; u = [0.0]
for z in e: y.append(y[-1] + 0.01 * z); u.append(0.9 * u[-1] + 0.01 * z)
price = [exp(v) for v in y]; ret = [y[t] - y[t - 1] for t in range(1, N + 1)]
gam, se0, (n, mx, md, sxx, sxd, sdd) = df0(y)
b0, s0, tau0g = adf(y, 0)
b1, s1, tau1 = adf(y, 1); gam_f, tau1f = adf1_fwl(y)
_, _, taur = adf(ret, 1)
dr = [ret[t] - ret[t - 1] for t in range(1, N)]; m = sum(dr) / len(dr)
ac1 = sum((dr[t] - m) * (dr[t - 1] - m) for t in range(1, len(dr))) / sum((a - m) ** 2 for a in dr)
pr("price on day 0 ($)", price[0], 2); pr("price on day 250 ($)", price[N], 2)
pr("  lowest ($)", min(price), 2); pr("  highest ($)", max(price), 2)
pr("DF by hand: n", n, 0); pr("  mean level x-bar", mx); pr("  mean change d-bar", md, 8)
pr("  Sxx", sxx); pr("  Sxd", sxd, 8); pr("  Sdd", sdd, 8)
pr("  gamma-hat = Sxd/Sxx", gam); pr("  rho-hat = 1 + gamma-hat", 1 + gam)
pr("  RSS = Sdd - gamma-hat Sxd", sdd - gam * sxd, 8); pr("  s^2 = RSS/(n-2)", (sdd - gam * sxd) / (n - 2), 8)
pr("  se(gamma-hat) = sqrt(s^2/Sxx)", se0)
pr("  tau = gamma-hat / se  (road 1, sums)", gam / se0, 4); pr("  tau  (road 2, Gauss-Jordan)", tau0g, 4)
pr("ADF p=1 on log price: gamma-hat", b1[1]); pr("  lag coefficient delta-hat", b1[2], 4)
pr("  se(delta-hat)", s1[2], 4); pr("  tau  (road 2, Gauss-Jordan)", tau1, 4); pr("  tau  (road 3, partialling out)", tau1f, 4)
pr("ADF p=1 on daily returns: tau", taur, 4)
pr("5% cutoff, MacKinnon, T = 250", cv5(250), 4)
pr("  normal area left of -1.645 (Simpson)", Phi_left(-1.645))
pr("half-life if rho-hat were real (days)", log(0.5) / log(1 + gam), 1)
pr("over-differenced returns: lag-1 autocorr", ac1, 4); pr("  exact for white-noise returns", -0.5, 4)
pr("  its standard error sqrt(0.5/n)", sqrt(0.5 / len(dr)), 4)
print("figure, price every 10 days: " + ", ".join(f"{price[t]:.2f}" for t in range(0, N + 1, 10)))
# ---- 10,000 simulated random walks of 250 days, and AR(0.95) paths driven by the same shocks ----
R, RHO = 10000, 0.95; g = Rng(2029); cut = cv5(250)
ssw = [0.0] * 11; ssa = [0.0] * 11; bins = [0] * 16; taus = []
rej = naive = power = sp_lvl = sp_ret = 0; pw = pe = None
for k in range(R):
    w = [0.0]; a = [0.0]; e = []
    for t in range(N):
        z = g.normal(); e.append(z); w.append(w[-1] + z); a.append(RHO * a[-1] + z)
    for i in range(11): ssw[i] += w[25 * i] ** 2; ssa[i] += a[25 * i] ** 2
    tau = df0(w); tau = tau[0] / tau[1]; taus.append(tau)
    rej += tau < cut; naive += tau < -1.645
    ta = df0(a); power += ta[0] / ta[1] < cut
    j = int((tau + 5.0) // 0.5)
    if 0 <= j < 16: bins[j] += 1
    if k % 2:
        s = reg1(pw, w); sp_lvl += abs(s[0] / s[1]) > 1.96
        s = reg1(pe, e); sp_ret += abs(s[0] / s[1]) > 1.96
    pw, pe = w, e
taus.sort(); P = R // 2
se = lambda p, n: sqrt(p * (1 - p) / n)
pr("sim: walks rejected at MacKinnon cutoff", rej / R, 4); pr("  standard error", se(0.05, R), 4)
pr("sim: 5% quantile of tau", taus[R // 20 - 1], 4); pr("sim: mean of tau", sum(taus) / R, 4)
pr("sim: walks rejected at normal cutoff", naive / R, 4); pr("  standard error", se(naive / R, R), 4)
pr("sim: AR(0.95) rejected (power)", power / R, 4); pr("  standard error", se(power / R, R), 4)
pr("sim: walk-on-walk |t| > 1.96 (spurious)", sp_lvl / P, 4); pr("  standard error", se(sp_lvl / P, P), 4)
pr("try: returns-on-returns |t| > 1.96", sp_ret / P, 4); pr("  standard error", se(sp_ret / P, P), 4)
v250 = ssw[10] / R
pr("sim: variance of walk at day 250", v250, 2); pr("  exact t sigma^2", 250.0, 2); pr("  standard error", 250 * sqrt(2 / R), 2)
print("figure, walk sd exact: " + ", ".join(f"{sqrt(25 * i):.2f}" for i in range(11)))
print("figure, walk sd sim:   " + ", ".join(f"{sqrt(ssw[i] / R):.2f}" for i in range(11)))
print("figure, AR sd exact:   " + ", ".join(f"{sqrt((1 - RHO ** (50 * i)) / (1 - RHO ** 2)):.2f}" for i in range(11)))
print("figure, AR sd sim:     " + ", ".join(f"{sqrt(ssa[i] / R):.2f}" for i in range(11)))
print("figure, tau density:    " + ", ".join(f"{c / (R * 0.5):.2f}" for c in bins))
print("figure, normal density: " + ", ".join(f"{phi(-4.75 + 0.5 * i):.2f}" for i in range(16)))
_, _, tau9 = adf(u, 1)
pr("try: rho = 0.9 share, ADF p=1 tau", tau9, 4); pr("try: 5% cutoff, MacKinnon, T = 1000", cv5(1000), 4)
# ---- asserts: each compares two independent computations ----
assert abs(gam / se0 - tau0g) < 1e-8, "sums and Gauss-Jordan disagree"
assert abs(tau1 - tau1f) < 1e-8, "Gauss-Jordan and partialling out disagree"
assert abs(rej / R - 0.05) < 4 * se(0.05, R), "simulation does not match MacKinnon's cutoff"
assert abs(v250 - 250.0) < 4 * 250 * sqrt(2 / R), "random-walk variance is not t sigma^2"
assert abs(ac1 + 0.5) < 4 * sqrt(0.5 / len(dr)), "over-differencing did not give -0.5"
assert naive / R > Phi_left(-1.645) + 10 * se(naive / R, R), "normal cutoff was not too lenient"
print("all checks passed")
