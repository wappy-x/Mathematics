# Cox regression in outline -- the check behind the card.  Standard library only.  One covariate,
# x = 1 for a smoker, 0 for a non-smoker.  The fit on ten men is reached three ways: by hand (the score
# is zero at hazard ratio 2), Newton's method on risk-set counts, and a golden-section climb on the raw
# partial-likelihood product.  Simulated cohorts use SplitMix64, seed 20260929, the same draws as Rust.
from math import exp, log, sqrt
M64 = (1 << 64) - 1
state = [20260929]
def unif():                                   # SplitMix64: a uniform number in [0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
# the ten men: (years followed, 1 = died / 0 = left the study alive, 1 = smoker / 0 = non-smoker)
MEN = [(1, 1, 1), (2, 0, 0), (3, 1, 1), (4, 1, 1), (5, 1, 0),
       (6, 0, 1), (7, 1, 0), (8, 1, 0), (9, 1, 1), (10, 0, 0)]
def score(b, rows):                           # road 1: risk sets counted from the latest time back
    r, n0, n1, U, I, i = exp(b), 0, 0, 0.0, 0.0, 0
    while i < len(rows):                      # men with equal times join the risk set together
        j = i
        while j < len(rows) and rows[j][0] == rows[i][0]:
            n1 += rows[j][2]; n0 += 1 - rows[j][2]; j += 1
        m = n1 * r / (n0 + n1 * r)            # expected smoker share of a death at this time
        for t, d, x in rows[i:j]:
            if d: U += x - m; I += m * (1.0 - m)
        i = j
    return U, I
def fit(data):                                # Newton's method: step = score / information
    rows, b = sorted(data, key=lambda r: -r[0]), 0.0
    for _ in range(60):
        U, I = score(b, rows)
        b += U / I
        if abs(U) < 1e-12: break
    return b, 1.0 / sqrt(I)
def logpl(b, data):                           # road 2: the partial likelihood as a raw product
    s = 0.0
    for t, d, x in data:
        if d:
            den = 0.0
            for tk, dk, xk in data:
                if tk >= t: den += exp(b * xk)
            s += log(exp(b * x) / den)
    return s
def golden(f, lo, hi):                        # climb to the top without any slope formula
    g = (sqrt(5.0) - 1.0) / 2.0
    for _ in range(200):
        a, c = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) > f(c): hi = c
        else: lo = a
    return (lo + hi) / 2.0
def show(label, *v): print(label.ljust(44) + "".join(f"{x:>11.4f}" for x in v))
print("event year, smokers at risk, non-smokers at risk, died a smoker?, at HR 2: smoker share m, m(1-m)")
tot = inf = 0.0
for t, d, x in MEN:
    if d:
        n1 = sum(1 for tk, dk, xk in MEN if tk >= t and xk == 1)
        n0 = sum(1 for tk, dk, xk in MEN if tk >= t and xk == 0)
        m = 2 * n1 / (2 * n1 + n0); tot += m; inf += m * (1 - m)
        print(f"  {t:>2} {n1:>3} {n0:>3} {x:>3}", f"{m:>9.4f}{m * (1 - m):>9.4f}")
show("hand: expected, observed smoker deaths; info", tot, sum(d * x for t, d, x in MEN), inf)
b1, se1 = fit(MEN)
show("1 Newton: beta, HR, SE of beta", b1, exp(b1), se1)
b2 = golden(lambda b: logpl(b, MEN), -3.0, 3.0)
h = 1e-3
se2 = 1.0 / sqrt(-(logpl(b2 + h, MEN) - 2 * logpl(b2, MEN) + logpl(b2 - h, MEN)) / (h * h))
show("2 golden climb: beta, HR, SE by curvature", b2, exp(b2), se2)
show("hand: ln 2", log(2.0))
show("95% interval for the HR", exp(b1 - 1.96 * se1), exp(b1 + 1.96 * se1))
show("log partial likelihood at beta = 0, at fit", logpl(0.0, MEN), logpl(b1, MEN))
U0, I0 = score(0.0, sorted(MEN, key=lambda r: -r[0]))
show("score test at HR 1 (log-rank): z", U0 / sqrt(I0))
assert abs(b1 - log(2.0)) < 1e-10
assert abs(b2 - b1) < 1e-7
assert abs(se2 - se1) < 1e-5
def H0(t, k): return 0.25 * (t / 10.0) ** k   # baseline cumulative hazard: 0.25 by year 10
def draw_time(x, k, early):                   # invert the survival curve: S(T) = a uniform draw
    E = -log(1.0 - unif())
    H5 = H0(5.0, k)
    if x and early: H = E / 4.0 if E < 4.0 * H5 else E - 3.0 * H5
    else: H = E / (2.0 if x else 1.0)
    return 10.0 * (H / 0.25) ** (1.0 / k)
def cohort(n, k, early=False):                # 10-year study, people also drop out at 3% a year
    out = []
    for i in range(n):
        x = i % 2
        t = draw_time(x, k, early)
        c = min(-log(1.0 - unif()) / 0.03, 10.0)
        out.append((min(t, c), 1 if t <= c else 0, x))
    return out
n, s, k = 200000, 0, 0.5                      # race of two, falling baseline: who dies first?
for _ in range(n):
    s += 1 if draw_time(1, k, False) < draw_time(0, k, False) else 0
p = s / n
N, a, bb, tot = 20000, 0.0, 8.0, 0.0          # the same race by Simpson's rule, rising baseline:
for i in range(N + 1):                        # smoker's hazard 2 h0(t) times both alive, t = 10 u^2
    u = a + i * (bb - a) / N
    t = 10.0 * u * u
    f = 2.0 * 0.0375 * u * exp(-3.0 * H0(t, 1.5)) * 20.0 * u
    tot += f * (1 if i in (0, N) else (4 if i % 2 else 2))
integ = tot * (bb - a) / N / 3.0
show("race: exact 2/3, Simpson (rising h0)", 2.0 / 3.0, integ)
show("race: simulated (falling h0), SE", p, sqrt(p * (1 - p) / n))
assert abs(integ - 2.0 / 3.0) < 1e-9
assert abs(p - 2.0 / 3.0) < 4 * sqrt(p * (1 - p) / n)
big = cohort(1000, 1.5)
bB, seB = fit(big)
print(f"1,000 men: {sum(d for t, d, x in big)} deaths".ljust(44) + f"{bB:>11.4f}{seB:>11.4f}")
show("1,000 men: HR and its 95% interval", exp(bB), exp(bB - 1.96 * seB), exp(bB + 1.96 * seB))
for k in (1.5, 0.5):
    bs, ses = [], []
    for _ in range(400):
        bk, sk = fit(cohort(200, k)); bs.append(bk); ses.append(sk)
    mb = sum(bs) / 400; sd = sqrt(sum((v - mb) ** 2 for v in bs) / 399)
    show(f"400 cohorts of 200, k={k}: mean beta, SE", mb, sd / 20.0)
    show(f"  spread of beta, average reported SE", sd, sum(ses) / 400)
    assert abs(mb - log(2.0)) < 4 * sd / 20.0
    assert abs(sum(ses) / 400 - sd) < 0.15 * sd
wrong1 = fit([(t, 1, x) for t, d, x in MEN])
wrong2 = fit([(t, d, x) for t, d, x in MEN if d])
show("wrong: count leavers as deaths, HR", exp(wrong1[0]))
show("wrong: drop the leavers, HR", exp(wrong2[0]))
show("doctors: risk 0.24; doubled; rate doubled", 0.24, 2 * 0.24, 1 - (1 - 0.24) * (1 - 0.24))
show("10-year risk: non-smoker, smoker, ratio", 1 - exp(-0.25), 1 - exp(-0.5), (1 - exp(-0.5)) / (1 - exp(-0.25)))
cr = cohort(2000, 1.5, early=True)
show("crossing: fitted HR overall", exp(fit(cr)[0]))
show("  first 5 years, after year 5", exp(fit([(min(t, 5.0), d if t <= 5.0 else 0, x) for t, d, x in cr])[0]),
     exp(fit([(t, d if t > 5.0 else 0, x) for t, d, x in cr])[0]))
print("chart hazard per 1,000 a year, years 1..10:")
for c in (1.0, 2.0):
    print("  " + ", ".join(f"{c * 1000 * 0.375 * (t / 10.0) ** 0.5 / 10.0:.2f}" for t in range(1, 11)))
print("chart survival, years 0..10:")
for c in (1.0, 2.0):
    print("  " + ", ".join(f"{exp(-c * H0(float(t), 1.5)):.2f}" for t in range(0, 11)))
print("figure, line ends x = 60 + 28 t:", ", ".join(str(60 + 28 * t) for t, d, x in MEN))
print("figure, rows y = 20 + 20 i:", ", ".join(str(20 + 20 * i) for i in range(10)))
show("try: F dies at 6 instead of leaving, HR", exp(fit([(t, 1 if t == 6 else d, x) for t, d, x in MEN])[0]))
bD, seD = fit(MEN + MEN)
show("try: every man counted twice, HR, SE", exp(bD), seD)
bN = fit([(t, d, 1 - x) for t, d, x in MEN])[0]; show("try: code non-smokers as 1, beta, HR", bN, exp(bN))
print("ALL CHECKS PASS")
