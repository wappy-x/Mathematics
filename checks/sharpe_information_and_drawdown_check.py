# Sharpe ratio, information ratio, maximum drawdown and the Sharpe error bar -- the check
# behind the card.  Standard library only: the random numbers (splitmix64), the bell-curve
# draws (Box-Muller), the bootstrap and the simulation are all written out here.
from math import sqrt, log, cos, pi, exp

MASK = (1 << 64) - 1
class Rng:                                          # splitmix64: a known, portable generator
    def __init__(self, seed): self.x = seed
    def u(self):                                    # a uniform number strictly inside (0, 1)
        self.x = (self.x + 0x9E3779B97F4A7C15) & MASK
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
    def normal(self):                               # Box-Muller: two uniforms -> one bell-curve draw
        u1, u2 = self.u(), self.u()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def mean(xs): return sum(xs) / len(xs)
def sd(xs):                                         # road 1: two passes, n - 1 in the divisor
    m = mean(xs)
    return sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))
def ratio(xs): return mean(xs) / sd(xs)             # monthly Sharpe or information ratio
def ratio_from_sums(xs):                            # road 2: one pass, from the sum and the sum of squares
    n, s1, s2 = len(xs), 0.0, 0.0
    for x in xs: s1 += x; s2 += x * x
    return (s1 / n) / sqrt((s2 - s1 * s1 / n) / (n - 1))
def wealth(rs):                                     # $100 compounded month by month
    w = [100.0]
    for r in rs: w.append(w[-1] * (1.0 + r))
    return w
def drawdown_running(w):                            # road 1: track the best level so far
    pk, best, at = 0, 0.0, (0, 0)
    for t, v in enumerate(w):
        if v > w[pk]: pk = t
        if 1.0 - v / w[pk] > best: best, at = 1.0 - v / w[pk], (pk, t)
    return best, at
def drawdown_pairs(w):                              # road 2: every earlier-high, later-low pair
    return max(1.0 - w[j] / w[i] for i in range(len(w)) for j in range(i, len(w)))
def se_month(s, n): return sqrt((1.0 + s * s / 2.0) / n)   # the error-bar formula, one period
def skew_kurt(xs):
    m, n = mean(xs), len(xs)
    v = sum((x - m) ** 2 for x in xs) / n
    return (sum((x - m) ** 3 for x in xs) / n / v ** 1.5, sum((x - m) ** 4 for x in xs) / n / v ** 2)

# ---- the fund: ten years of monthly returns, simulated once from a fixed seed ----
N, CASH, A = 120, 0.002, sqrt(12.0)
def make_fund(seed):                                # benchmark: cash + 0.45% +- 2.2%; fund adds 0.2% +- 1.0%
    g, bench, fund = Rng(seed), [], []
    for t in range(N):
        b_ex, act = 0.0045 + 0.022 * g.normal(), 0.002 + 0.010 * g.normal()
        bench.append(CASH + b_ex); fund.append(CASH + b_ex + act)
    return bench, fund
bench, fund = make_fund(239)
x = [r - CASH for r in fund]                        # excess over cash
a = [r - b for r, b in zip(fund, bench)]            # active: over the benchmark
S_m, S_sums = ratio(x), ratio_from_sums(x)
S_A, IR_A = S_m * A, ratio(a) * A
w = wealth(fund)
mdd, (pk, tr) = drawdown_running(w)
mdd_pairs = drawdown_pairs(w)
rec = next((t for t in range(tr, N + 1) if w[t] >= w[pk]), None)

# ---- the error bar: three roads ----
se_formula = se_month(S_m, N) * A
gb, boot = Rng(7), []
for _ in range(5000):                               # road 2: resample the 120 months with replacement
    boot.append(ratio([x[int(gb.u() * N)] for _ in range(N)]) * A)
se_boot = sd(boot)
gm, sims, dds = Rng(11), [], []
mu_r, sd_r = mean(fund), sd(fund)
for _ in range(5000):                               # road 3: 5,000 fresh ten-year histories, true Sharpe = S_A
    xs = [S_m * 0.01 + 0.01 * gm.normal() for _ in range(N)]
    sims.append(ratio(xs) * A)
    dds.append(drawdown_running(wealth([mu_r + sd_r * gm.normal() for _ in range(N)]))[0])
se_sim = sd(sims)
gh = Rng(13)                                        # road 3 again at a monthly Sharpe of 1.0, where S^2/2 matters
se_hi = sd([ratio([1.0 + gh.normal() for _ in range(N)]) for _ in range(4000)])
inside = sum(1 for s in sims if abs(s - S_A) < se_formula) / len(sims)
sk, ku = skew_kurt(x)
se_tails = sqrt((1.0 + S_m ** 2 / 2.0 - sk * S_m + (ku - 3.0) / 4.0 * S_m ** 2) / N) * A
dds.sort()
smooth = [0.5 * (x[t] + x[t - 1]) for t in range(1, N)]
m_s = mean(smooth)
rho1 = sum((smooth[t] - m_s) * (smooth[t - 1] - m_s) for t in range(1, len(smooth))) / sum((v - m_s) ** 2 for v in smooth)

def f(label, v): print(f"{label:<44}{v:>12.4f}")
f("mean excess return, monthly (%)", mean(x) * 100); f("sd of excess return, monthly (%)", sd(x) * 100)
f("Sharpe, monthly, two passes", S_m); f("Sharpe, monthly, from the sums", S_sums)
f("sqrt 12, months to a year", A); f("Sharpe, annualised (x sqrt 12)", S_A)
f("mean active return, monthly (%)", mean(a) * 100); f("tracking error, monthly (%)", sd(a) * 100)
f("information ratio, monthly", ratio(a)); f("information ratio, annualised", IR_A)
f("max drawdown, running peak (%)", mdd * 100); f("max drawdown, every pair (%)", mdd_pairs * 100)
print(f"drawdown: peak month {pk}, trough month {tr}, back to peak month {rec}")
f("  wealth at peak ($)", w[pk]); f("  wealth at trough ($)", w[tr]); f("  wealth at month 120 ($)", w[N])
f("1 + S^2/2, monthly", 1.0 + S_m ** 2 / 2.0); f("SE of Sharpe, formula", se_formula); f("SE of Sharpe, bootstrap 5000", se_boot)
f("SE of Sharpe, simulation 5000", se_sim); f("share of simulations within 1 SE", inside)
f("monthly Sharpe 1.0: SE, simulation 4000", se_hi); f("monthly Sharpe 1.0: SE, formula", se_month(1.0, N))
f("sample skew", sk); f("sample kurtosis", ku); f("SE of Sharpe, with skew and kurtosis", se_tails)
f("SE of information ratio, formula", sqrt((1.0 + (IR_A / A) ** 2 / 2.0) / N) * A)
f("simulated drawdown, 5th percentile (%)", dds[249] * 100)
f("simulated drawdown, median (%)", dds[2499] * 100); f("simulated drawdown, 95th percentile (%)", dds[4749] * 100)
f("wrong: annualise with x12", S_m * 12); f("wrong: forget the cash", ratio(fund) * A)
f("wrong: monthly SE beside annual Sharpe", se_formula / A)
f("wrong: IR over the fund's own spread", mean(a) / sd(x) * A)
f("wrong: drawdown from the start only (%)", max(0.0, 1.0 - min(w) / w[0]) * 100)
f("wrong: smoothed prices, Sharpe", ratio(smooth) * A); f("  lag-one autocorrelation", rho1)
lev = [CASH + 2.0 * v for v in x]                  # twice the bet, the extra borrowed at cash
f("try: twice the bet, Sharpe", ratio([r - CASH for r in lev]) * A)
f("try: twice the bet, max drawdown (%)", drawdown_running(wealth(lev))[0] * 100)
b2, f2 = make_fund(185)
print(f"try: seed 185, Sharpe {ratio([r - CASH for r in f2]) * A:.4f}, information ratio "
      f"{ratio([r - b for r, b in zip(f2, b2)]) * A:.4f}, max drawdown {drawdown_running(wealth(f2))[0] * 100:.4f}%")
f("try: SE from 10 yearly observations", sqrt((1.0 + S_A ** 2 / 2.0) / 10))
for s in (0.9, 0.5): f(f"years for Sharpe {s} to reach 2 SE", 4.0 * (1.0 + s * s / 24.0) / (s * s))
print("SE by years:", " ".join(f"{y}y {sqrt((12.0 + S_A ** 2 / 2.0) / (12 * y)):.2f}" for y in (1, 2, 5, 10, 20, 40)))
edges = [-0.2 + 0.2 * k for k in range(12)]
print("hist, Sharpe from", " ".join(f"{e:.1f}" for e in edges[:-1]))
print("hist, histories  ", " ".join(str(sum(1 for s in sims if lo <= s < lo + 0.2)) for lo in edges[:-1]))
for lab, row in (("chart, wealth ($)", w), ("chart, peak ($)", [max(w[:t + 1]) for t in range(N + 1)])):
    q = [row[t] for t in range(0, N + 1, 3)]
    for k in range(0, 41, 14): print(f"{lab:<18}" + " ".join(f"{v:.2f}" for v in q[k:k + 14]))

assert abs(S_m - S_sums) < 1e-12, "two roads to the Sharpe ratio"
assert abs(w[N] / (100.0 * exp(sum(log(1.0 + r) for r in fund))) - 1.0) < 1e-12, "compounding vs summed logs"
assert abs(mdd - mdd_pairs) < 1e-12, "running peak vs every pair"
assert abs(se_boot / se_formula - 1.0) < 0.10, "bootstrap error bar vs the formula"
assert abs(se_sim / se_formula - 1.0) < 0.05, "simulated error bar vs the formula"
assert abs(se_hi / se_month(1.0, N) - 1.0) < 0.05, "the S^2/2 term, where it is large"
assert abs(inside - 0.6827) < 0.03, "about two histories in three land within one SE"
print("ALL CHECKS PASS")
