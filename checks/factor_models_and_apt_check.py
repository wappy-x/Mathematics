# Factor models and APT -- the check behind the card.  Standard library only.
# An invented eight-month record: each factor is up or down by a fixed step and
# every up/down combination appears once.  Returns: percent per month, over the bank.
from math import sqrt, log, cos, pi

LAM = (0.5, 0.2, 0.3)                 # average market, size, value returns in the record
STEP = (4.0, 2.0, 2.0)                # each factor sits this far above or below its average
TRUE = {"A": (0.2, 1.2, 0.4, -0.3), "B": (-0.1, 0.8, -0.2, 0.5)}   # alpha, bM, bS, bH
signs = [(m, s, h) for m in (1, -1) for s in (1, -1) for h in (1, -1)]
F = [[LAM[j] + STEP[j] * sg[j] for j in range(3)] for sg in signs]

def fund(key, t, shared=0.0):         # the funds' months: factor part plus a specific part
    a, bm, bs, bh = TRUE[key]
    m, s, h = signs[t]
    own = 1.0 * m * s if key == "A" else 0.5 * m * h + shared * m * s
    return a + bm * F[t][0] + bs * F[t][1] + bh * F[t][2] + own

def solve(A, b):                      # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        if abs(M[p][c]) < 1e-12: raise ValueError("factor columns not independent")
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                k = M[r][c] / M[c][c]
                M[r] = [x - k * z for x, z in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def ols(X, y):                        # road 1: normal equations  X'X theta = X'y
    k = len(X[0])
    XtX = [[sum(r[i] * r[j] for r in X) for j in range(k)] for i in range(k)]
    return solve(XtX, [sum(r[i] * v for r, v in zip(X, y)) for i in range(k)])

def mean(u): return sum(u) / len(u)
def z(x): return 0.0 if abs(x) < 5e-10 else x      # print a rounding-level -0.00 as 0.00
def cov(u, v):                        # divisor n: the eight months are the whole record
    mu, mv = mean(u), mean(v)
    return sum((a - mu) * (b - mv) for a, b in zip(u, v)) / len(u)

def halfdiff(y):                      # road 2: up-month average minus down-month average
    b = []
    for j in range(3):
        up = [t for t in range(8) if signs[t][j] > 0]; dn = [t for t in range(8) if signs[t][j] < 0]
        gap = mean([F[t][j] for t in up]) - mean([F[t][j] for t in dn])
        b.append((mean([y[t] for t in up]) - mean([y[t] for t in dn])) / gap)
    return [mean(y) - sum(b[j] * mean([F[t][j] for t in range(8)]) for j in range(3))] + b

yA, yB = [fund("A", t) for t in range(8)], [fund("B", t) for t in range(8)]
X = [[1.0] + F[t] for t in range(8)]
print("month   MKT    SMB    HML   fund A  fund B")
for t in range(8):
    print(f"{t + 1:>5} {F[t][0]:6.1f} {F[t][1]:6.1f} {F[t][2]:6.1f} {yA[t]:8.2f} {yB[t]:7.2f}")
cols = [[F[t][j] for t in range(8)] for j in range(3)]
fbar = [mean(c) for c in cols]
print(f"average   {fbar[0]:.2f}   {fbar[1]:.2f}   {fbar[2]:.2f} {mean(yA):8.2f} {mean(yB):7.2f}")
fit, res = {}, {}
for key, y in (("A", yA), ("B", yB)):
    r1, r2 = ols(X, y), halfdiff(y)
    fit[key] = r1
    res[key] = [y[t] - sum(r1[i] * X[t][i] for i in range(4)) for t in range(8)]
    print(f"fund {key} road 1 normal equations  alpha {r1[0]:6.3f}  bM {r1[1]:6.3f}  bS {r1[2]:6.3f}  bH {r1[3]:6.3f}")
    print(f"fund {key} road 2 up minus down     alpha {r2[0]:6.3f}  bM {r2[1]:6.3f}  bS {r2[2]:6.3f}  bH {r2[3]:6.3f}")
    assert all(abs(a - b) < 1e-9 for a, b in zip(r1, r2)), "two fitting roads disagree"
    assert all(abs(a - b) < 1e-9 for a, b in zip(r1, TRUE[key])), "fit misses the loadings that built the record"
    print(f"fund {key} month-1 residual {res[key][0]:6.3f}; each month's residual times each factor sums to "
          f"{max(abs(sum(res[key][t] * F[t][j] for t in range(8))) for j in range(3)):.3f}")

ud = [mean([yA[t] for t in range(8) if signs[t][j] * g > 0]) for j in range(3) for g in (1, -1)]
print("fund A up / down month averages: market {:.2f} / {:.2f}  size {:.2f} / {:.2f}  value {:.2f} / {:.2f}".format(*ud))
print("chart, fund A factor fit " + " ".join(f"{yA[t] - res['A'][t]:.2f}" for t in range(8)))
Om = [[cov(cols[i], cols[j]) for j in range(3)] for i in range(3)]
Bm = [fit["A"][1:], fit["B"][1:]]
def quad(u, M, v): return sum(u[i] * M[i][j] * v[j] for i in range(len(u)) for j in range(len(v)))
fac = [[quad(Bm[a], Om, Bm[b]) for b in range(2)] for a in range(2)]
D = [[cov(res[p], res[q]) for q in "AB"] for p in "AB"]
direct = [[cov(u, v) for v in (yA, yB)] for u in (yA, yB)]
print(f"factor covariance Omega diagonal {Om[0][0]:.2f} {Om[1][1]:.2f} {Om[2][2]:.2f}; off-diagonal {z(Om[0][1]):.2f}")
for lab, M in (("factor part B Omega B'", fac), ("specific part D", D), ("sum", [[fac[i][j] + D[i][j] for j in range(2)] for i in range(2)]), ("direct from the months", direct)):
    print(f"{lab:<24} {M[0][0]:7.2f} {z(M[0][1]):7.2f} {M[1][1]:7.2f}")
assert all(abs(fac[i][j] + D[i][j] - direct[i][j]) < 1e-9 for i in range(2) for j in range(2)), "decomposition fails"
assert abs(direct[0][0] - sum(TRUE["A"][1 + j] ** 2 * STEP[j] ** 2 for j in range(3)) - 1.0) < 1e-9, "A variance: loading^2 x step^2 + 1"
bA = fit["A"][1:]
print("fund A variance by source: market {:.2f}  size {:.2f}  value {:.2f}  specific {:.2f}".format(
    *[bA[j] ** 2 * Om[j][j] for j in range(3)], D[0][0]))
print(f"fund A R-squared {fac[0][0] / direct[0][0]:.4f}; fund B {fac[1][1] / direct[1][1]:.4f}; "
      f"correlation {direct[0][1] / sqrt(direct[0][0] * direct[1][1]):.4f}")
print(f"numbers to estimate for 500 funds: every covariance {500 * 501 // 2}; three-factor model {500 * 3 + 6 + 500}")
w = (0.5, 0.5); bP = [w[0] * Bm[0][j] + w[1] * Bm[1][j] for j in range(3)]
pv_fac = quad(bP, Om, bP) + quad(w, D, w); pv_dir = cov(*[[w[0] * a + w[1] * b for a, b in zip(yA, yB)]] * 2)
print(f"half-and-half portfolio loadings {bP[0]:.2f} {bP[1]:.2f} {bP[2]:.2f}; variance from 3 exposures {pv_fac:.4f}; from its own months {pv_dir:.4f}")
assert abs(pv_fac - pv_dir) < 1e-9, "portfolio variance by exposures disagrees with the direct series"

capm = ols([[1.0, F[t][0]] for t in range(8)], yA)
capm_res = cov(*[[yA[t] - capm[0] - capm[1] * F[t][0] for t in range(8)]] * 2)
print(f"wrong: market only  beta {capm[1]:.3f}  alpha {capm[0]:.3f}  'specific' variance {capm_res:.2f}  "
      f"A-B covariance {capm[1] * ols([[1.0, F[t][0]] for t in range(8)], yB)[1] * Om[0][0]:.2f}")
yB2 = [fund("B", t, shared=0.5) for t in range(8)]
fB2 = ols(X, yB2)
print(f"wrong: residuals assumed unrelated  model covariance {quad(bA, Om, fB2[1:]):.2f}  true {cov(yA, yB2):.2f}")
print(f"wrong: alpha read as average excess return  {mean(yA):.2f} instead of {fit['A'][0]:.2f}")

impl = {k: sum(fit[k][1 + j] * fbar[j] for j in range(3)) for k in "AB"}
for k, y in (("A", yA), ("B", yB)):
    print(f"APT fund {k}: premia-implied excess {impl[k]:.2f}; average excess {mean(y):.2f}; gap {mean(y) - impl[k]:.2f}")
    assert abs((mean(y) - impl[k]) - TRUE[k][0]) < 1e-9, "gap to APT line should equal the alpha that built the record"
Q = 0.80
pay = [(Q + sum(bA[j] * (F[t][j] - fbar[j]) for j in range(3))) - sum(bA[j] * F[t][j] for j in range(3)) for t in range(8)]
print(f"arbitrage: portfolio Q at {Q:.2f} long, factor copy short; monthly payoff min {min(pay):.4f} max {max(pay):.4f}; "
      f"price gap {Q - impl['A']:.4f}")
assert max(pay) - min(pay) < 1e-9, "a factor-neutral payoff must not move with the months"
assert abs(mean(pay) - (Q - sum(TRUE["A"][1 + j] * LAM[j] for j in range(3)))) < 1e-9, "payoff must be the price gap"

state = 0x9E3779B97F4A7C15
def uniform():                        # xorshift64: same bits in Python and Rust
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7; state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
def normal(): return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
print("specific volatility of an equal-weight basket of N funds, each 1.00 on its own")
for n in (1, 4, 16, 64, 400):
    draws = [mean([normal() for _ in range(n)]) for _ in range(2000)]
    sim = sqrt(sum(d * d for d in draws) / len(draws))
    print(f"  N = {n:>3}   formula 1/sqrt(N) {1 / sqrt(n):.3f}   simulated {sim:.3f}")
    assert abs(sim * sqrt(n) - 1.0) < 0.06, "diversification simulation off the 1/sqrt(N) law"
T = 600
Fl = [[LAM[j] + STEP[j] * normal() for j in range(3)] for _ in range(T)]
yl = [0.2 + 1.2 * f[0] + 0.4 * f[1] - 0.3 * f[2] + normal() for f in Fl]
el = ols([[1.0] + f for f in Fl], yl)
print(f"second case, 600 random months: alpha {el[0]:.3f}  bM {el[1]:.3f}  bS {el[2]:.3f}  bH {el[3]:.3f}")
assert all(abs(a - b) < 0.15 for a, b in zip(el, TRUE["A"])), "long random record should land near the true loadings"
print(f"try: fund A specific 2.00, R-squared {fac[0][0] / (fac[0][0] + 4.0):.4f}")
print(f"try: fund A value loading +0.3, A-B covariance {quad([1.2, 0.4, 0.3], Om, Bm[1]):.2f}")
print(f"try: fund A market loading 1.0, variance {quad([1.0, 0.4, -0.3], Om, [1.0, 0.4, -0.3]) + D[0][0]:.2f}")
print("ALL CHECKS PASS")
