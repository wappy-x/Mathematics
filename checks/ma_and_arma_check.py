# Moving average and ARMA -- the check behind the card.  Standard library only.
# Monthly sales after an advert: X_t = 500 + e_t + 0.6 e_(t-1) + 0.3 e_(t-2), surprises of sd 40.
# Every random draw comes from SplitMix64 (seed stated), turned normal by Box-Muller.
from math import sqrt, log, cos, pi
M64 = (1 << 64) - 1
class Rng:
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def normal(self):
        u1 = 1.0 - self.u()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * self.u())

MU, SIG, TH = 500.0, 40.0, [1.0, 0.6, 0.3]
PHI, TA = 0.5, 0.3                                    # ARMA(1,1): loyalty carries half of last month
def acov_formula(th, h, s2):                          # road 1: count the shocks two months share
    return s2 * sum(th[j] * th[j + h] for j in range(len(th) - h)) if h < len(th) else 0.0
def acov_enum(th, h, s):                              # road 2: every surprise is +s or -s; list all
    w = len(th) + h; tot = 0.0
    for word in range(1 << w):
        e = [s if (word >> i) & 1 else -s for i in range(w)]     # e[i] = surprise i months ago
        tot += sum(th[j] * e[j] for j in range(len(th))) * sum(th[j] * e[j + h] for j in range(len(th)))
    return tot / (1 << w)
def arma_rho(h): return 1.0 if h == 0 else (1 + PHI * TA) * (PHI + TA) / (1 + 2 * PHI * TA + TA * TA) * PHI ** (h - 1)
def arma_psi_acov(h, n=400):                          # road 2 for ARMA: weights on past surprises
    psi = [1.0] + [PHI ** (j - 1) * (PHI + TA) for j in range(1, n + h)]
    return SIG * SIG * sum(psi[j] * psi[j + h] for j in range(n))
def pacf(rho, H):                                     # Durbin-Levinson: last coefficient of best AR(k)
    out, a = [], []
    for k in range(1, H + 1):
        kk = (rho[k] - sum(a[j] * rho[k - 1 - j] for j in range(k - 1))) / (1 - sum(a[j] * rho[j + 1] for j in range(k - 1)))
        a = [a[j] - kk * a[k - 2 - j] for j in range(k - 1)] + [kk]; out.append(kk)
    return out
def yw_last(rho, k):                                  # road 2 for the PACF: the k-by-k Yule-Walker system, by elimination
    A = [[rho[abs(i - j)] for j in range(k)] + [rho[i + 1]] for i in range(k)]
    for c in range(k):
        for i in range(c + 1, k):
            f = A[i][c] / A[c][c]; A[i] = [p - f * q for p, q in zip(A[i], A[c])]
    return A[k - 1][k] / A[k - 1][k - 1]              # the last unknown: the partial autocorrelation at lag k
def sample_acf(x, H):
    m = sum(x) / len(x); d = [v - m for v in x]; c0 = sum(v * v for v in d)
    return [1.0] + [sum(d[t] * d[t + h] for t in range(len(d) - h)) / c0 for h in range(1, H + 1)]
def ma2_path(rng, n, th):
    e = [SIG * rng.normal() for _ in range(n + 2)]
    return [MU + e[t + 2] + th[1] * e[t + 1] + th[2] * e[t] for t in range(n)], e[2:]
def resid(x, t1, t2, m):                              # recover surprises month by month, start from 0
    e, a, b = [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]
    for v in x:
        a.append(-e[-1] - t1 * a[-1] - t2 * a[-2]); b.append(-e[-2] - t1 * b[-1] - t2 * b[-2])
        e.append(v - m - t1 * e[-1] - t2 * e[-2])
    return e[2:], a[2:], b[2:]
def fit(x):                                           # least squares on recovered surprises, Gauss-Newton
    m, t1, t2 = sum(x) / len(x), 0.0, 0.0
    for _ in range(30):
        e, a, b = resid(x, t1, t2, m)
        saa, sab, sbb = sum(v * v for v in a), sum(p * q for p, q in zip(a, b)), sum(v * v for v in b)
        sae, sbe = sum(p * q for p, q in zip(a, e)), sum(p * q for p, q in zip(b, e))
        det, sse, step = saa * sbb - sab * sab, sum(v * v for v in e), 1.0
        d1, d2 = (sbb * sae - sab * sbe) / det, (saa * sbe - sab * sae) / det
        while step > 1e-6 and sum(v * v for v in resid(x, t1 - step * d1, t2 - step * d2, m)[0]) > sse: step /= 2
        t1, t2 = t1 - step * d1, t2 - step * d2       # halve the step until the squares shrink
    e, a, b = resid(x, t1, t2, m)
    s2 = sum(v * v for v in e) / (len(x) - 3)
    saa, sab, sbb = sum(v * v for v in a), sum(p * q for p, q in zip(a, b)), sum(v * v for v in b)
    det = saa * sbb - sab * sab
    return m, t1, t2, sqrt(s2 * sbb / det), sqrt(s2 * saa / det), s2, e

g = [acov_formula(TH, h, SIG * SIG) for h in range(7)]; rho = [v / g[0] for v in g]
print("MA(2) sales: mean 500, surprise sd 40, echo weights 1, 0.6, 0.3")
print("lag  gamma by formula  gamma by enumeration     rho")
for h in range(4):
    ge = acov_enum(TH, h, SIG); print(f"{h:>3} {g[h]:>17.4f} {ge:>21.4f} {rho[h]:>7.4f}")
    assert abs(ge - g[h]) < 1e-9
print(f"variance {g[0]:.4f}, sd {sqrt(g[0]):.4f}")
ga0 = SIG * SIG * (1 + 2 * PHI * TA + TA * TA) / (1 - PHI * PHI); arho = [arma_rho(h) for h in range(7)]
print(f"ARMA(1,1) phi 0.5 theta 0.3: gamma0 closed form {ga0:.4f}, by weights {arma_psi_acov(0):.4f}")
for h in (1, 2, 3):
    pr = arma_psi_acov(h) / arma_psi_acov(0); print(f"  lag {h}: rho closed form {arho[h]:.4f}, by weights {pr:.4f}")
    assert abs(pr - arho[h]) < 1e-9
print("chart, echo of a +100 surprise, MA(2)  " + " ".join(f"{100 * (TH[j] if j < 3 else 0):.2f}" for j in range(6)))
print("chart, echo of a +100 surprise, ARMA   " + " ".join(f"{100 * (1 if j == 0 else PHI ** (j - 1) * (PHI + TA)):.2f}" for j in range(6)))
ar1 = [PHI ** h for h in range(7)]; P = {"AR(1)": pacf(ar1, 6), "MA(2)": pacf(rho, 6), "ARMA": pacf(arho, 6)}
assert max(abs(v) for v in P["AR(1)"][1:]) < 1e-12 and all(abs(P[k][1] - (r[2] - r[1] ** 2) / (1 - r[1] ** 2)) < 1e-12 for k, r in (("MA(2)", rho), ("ARMA", arho)))
for name, r in (("AR(1)", ar1), ("MA(2)", rho), ("ARMA", arho)):
    print(f"chart, ACF  {name:<6}" + " ".join(f"{v:.2f}" for v in r[1:]))
    print(f"chart, PACF {name:<6}" + " ".join(f"{v:.2f}" for v in P[name]))
# road 3: a long simulated run, autocorrelations in 60 batches of 2,000 months
rng = Rng(20260929); xs, _ = ma2_path(rng, 120000, TH)
y, prev, ep = [], 0.0, SIG * rng.normal()
for t in range(120100):
    en = SIG * rng.normal(); prev = PHI * prev + en + TA * ep; ep = en
    if t >= 100: y.append(MU + prev)
print("simulated 120000 months, 60 batches: lag, MA(2) sim (se) theory, ARMA sim (se) theory")
for h in (1, 2, 3):
    row = []
    for s, th in ((xs, rho[h]), (y, arho[h])):
        b = [sample_acf(s[i * 2000:(i + 1) * 2000], h)[h] for i in range(60)]
        mb = sum(b) / 60; se = sqrt(sum((v - mb) ** 2 for v in b) / 59 / 60)
        assert abs(mb - th) < 4 * se; row.append(f"{mb:.4f} ({se:.4f}) {th:.4f}")
    print(f"  lag {h}: " + "   ".join(row))
a1 = sample_acf(xs, 1)[1]; mx = sum(xs) / len(xs)
r1 = [xs[t] - mx - a1 * (xs[t - 1] - mx) for t in range(1, len(xs))]
v_th = g[0] * (1 - rho[1] ** 2); v_sim = sum(v * v for v in r1) / len(r1)
print(f"wrong order, AR(1) on MA(2): error variance theory {v_th:.4f}, long run {v_sim:.4f}, true 1600.0000")
assert abs(v_sim - v_th) < 0.02 * v_th and abs(v_sim - 1600) > 0.02 * 1600
# identification and fit on one 240-month record
rec, true_e = ma2_path(Rng(26), 240, TH); ra = sample_acf(rec, 6); rp = pacf(ra, 6)
print(f"record of 240 months, band 2/sqrt(240) = {2 / sqrt(240):.4f}; beyond lag 2, Bartlett widens it by {sqrt(1 + 2 * (rho[1] ** 2 + rho[2] ** 2)):.4f}")
assert all(abs(p[k - 1] - yw_last(r, k)) < 1e-9 for p, r in ((P["MA(2)"], rho), (P["ARMA"], arho), (rp, ra)) for k in range(1, 7))   # two roads to every PACF
print("  sample ACF  " + " ".join(f"{v:.4f}" for v in ra[1:])); print("  sample PACF " + " ".join(f"{v:.4f}" for v in rp))
print("  first months " + " ".join(f"{v:.2f}" for v in rec[:4]))
m, t1, t2, se1, se2, s2, e = fit(rec)
print(f"fit: mean {m:.4f} (se {sqrt(s2) * (1 + t1 + t2) / sqrt(240):.4f}), theta1 {t1:.4f} (se {se1:.4f}), theta2 {t2:.4f} (se {se2:.4f}), surprise sd {sqrt(s2):.4f}")
print(f"textbook se sqrt((1 - theta2^2)/n) = {sqrt((1 - TH[2] ** 2) / 240):.4f}")
assert abs(t1 - 0.6) < 3 * se1 and abs(t2 - 0.3) < 3 * se2
print("  residual ACF lags 1-3 " + " ".join(f"{v:.4f}" for v in sample_acf(e, 3)[1:]))
mc = Rng(11); f1, f2 = [], []
for _ in range(200):
    _, a, b, *_ = fit(ma2_path(mc, 240, TH)[0]); f1.append(a); f2.append(b)
sd = lambda v: sqrt(sum((w - sum(v) / len(v)) ** 2 for w in v) / (len(v) - 1))
print(f"200 simulated records: theta1 mean {sum(f1) / 200:.4f} sd {sd(f1):.4f}, theta2 mean {sum(f2) / 200:.4f} sd {sd(f2):.4f}")
assert abs(sd(f1) / sqrt(0.91 / 240) - 1) < 0.25 and abs(sd(f2) / sqrt(0.91 / 240) - 1) < 0.25
# invertibility: the twin with echo weights 2 and 3.33 and surprises of sd 12 has the same correlogram
tw = [1.0, TH[1] / TH[2], 1 / TH[2]]
print(f"twin: weights 1, {tw[1]:.4f}, {tw[2]:.4f}, sd {SIG * TH[2]:.4f}; root size {sqrt(1 / TH[2]):.4f} vs {sqrt(1 / tw[2]):.4f}")
for h in (0, 1, 2):
    gt = acov_enum(tw, h, SIG * TH[2]); print(f"  lag {h}: twin gamma {gt:.4f}, sales gamma {g[h]:.4f}"); assert abs(gt - g[h]) < 1e-9
ok, _, _ = resid(rec, 0.6, 0.3, MU); bad, _, _ = resid(rec, tw[1], tw[2], MU)
for t in (1, 2, 3, 6, 12, 24):
    print(f"  month {t:>2}: true surprise {true_e[t - 1]:>8.2f}, recovered {ok[t - 1]:>8.2f}, twin recursion {bad[t - 1]:>12.2f}")
assert abs(ok[23] - true_e[23]) < 0.01 and abs(bad[23]) > 1e6
c = [1.0, 1.1, 0.6, 0.15]                             # surprises sharing part of last month's: u = e + 0.5 e(-1)
r3f, r3e = acov_formula(c, 3, 1) / acov_formula(c, 0, 1), acov_enum(c, 3, 1) / acov_enum(c, 0, 1); assert abs(r3f - r3e) < 1e-12 and r3f > 0.05
print(f"correlated surprises: rho3 formula {r3f:.4f}, enumerated {r3e:.4f}, independent 0.0000")
