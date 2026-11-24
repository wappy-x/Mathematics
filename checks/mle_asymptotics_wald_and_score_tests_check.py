# Large-sample likelihood -- the check behind the card.  Standard library only.
# Drug arm: 45 of 100 recovered.  Test p0 = 0.35 by the Wald, score and likelihood-ratio routes.
from math import log, exp, sqrt, pi

def Phi(x):                                   # bell-curve area left of x, Taylor series of erf
    if abs(x) > 8: return 0.0 if x < 0 else 1.0   # the series loses all precision this far out
    y = x / sqrt(2.0); t, s, k = y, 0.0, 0
    while abs(t) > 1e-17:
        s, k = s + t / (2 * k + 1), k + 1
        t *= -y * y / k
    return 0.5 + s / sqrt(pi)

def Phi_simpson(x, m=2000):                   # second road: Simpson's rule on the bell-curve height
    h, f = x / m, lambda u: exp(-u * u / 2) / sqrt(2 * pi)
    return 0.5 + (f(0) + f(x) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, m))) * h / 3

def p2(z): return 2 * (1 - Phi(abs(z)))       # two-sided p-value of a z statistic
def xlogy(a, b): return a * log(b) if a > 0 else 0.0
def ll(k, n, p): return xlogy(k, p) + xlogy(n - k, 1 - p)       # log-likelihood, k of n
def stats(k, n, p0):                          # closed forms: Wald z, score z, likelihood ratio W
    q = k / n
    zw = (q - p0) / sqrt(q * (1 - q) / n) if 0 < k < n else float("inf")
    zs = (q - p0) / sqrt(p0 * (1 - p0) / n)
    return zw, zs, 2 * (ll(k, n, q) - ll(k, n, p0))
def golden_max(f, a=1e-9, b=1 - 1e-9):        # golden-section search: no closed-form estimate used
    g = (sqrt(5) - 1) / 2
    for _ in range(200):
        c, d = b - g * (b - a), a + g * (b - a)
        a, b = (a, d) if f(c) > f(d) else (c, b)
    return (a + b) / 2
def bisect(f, a, b):                          # root of f between a and b, f changing sign
    for _ in range(200):
        m = (a + b) / 2
        a, b = (m, b) if (f(a) > 0) == (f(m) > 0) else (a, m)
    return (a + b) / 2
def log_pmf(n, p):                            # binomial log-chances by the ratio rule, no factorials
    out = [n * log(1 - p)]
    for k in range(n): out.append(out[-1] + log((n - k) / (k + 1)) + log(p / (1 - p)))
    return out
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return s, (z ^ (z >> 31)) >> 11

x, n, p0, c = 45, 100, 0.35, 1.959964
ph = x / n
# ---- road 1: closed forms ----
zw, zs, W = stats(x, n, p0)
print(f"spread at p-hat {sqrt(ph * (1 - ph) / n):.5f}; spread at p0 {sqrt(p0 * (1 - p0) / n):.5f}")
print(f"Wald z = {zw:.4f}  score z = {zs:.4f}  W = {W:.4f}  sqrt W = {sqrt(W):.4f}")
print(f"cutoff c = {c}, c^2 = {c * c:.4f}; score z / Wald z = spread ratio {zs / zw:.4f}")
print(f"p-values: Wald {p2(zw):.4f}  score {p2(zs):.4f}  LR {p2(sqrt(W)):.4f}")
rb = (x + 35) / (2 * n); sb = sqrt(2 * rb * (1 - rb) / n)   # Hypothesis tests: 35 of 100 on a placebo arm, pooled
print(f"two arms, 35 of 100 on placebo: pooled spread of the gap {sb:.4f}, p {p2((ph - p0) / sb):.3f}")
print(f"Phi(1.96): series {Phi(1.96):.10f}  Simpson {Phi_simpson(1.96):.10f}")
assert abs(Phi(1.96) - Phi_simpson(1.96)) < 1e-10
assert abs(p2(c) - 0.05) < 1e-6                # the cutoff leaves 5% in the two tails
# ---- road 2: the same three numbers from the curve itself, by search and finite differences ----
f = lambda p: ll(x, n, p)
q = golden_max(f); h = 1e-4
U = (f(p0 + h) - f(p0 - h)) / (2 * h)                       # score: slope at p0
J = -(f(q + h) - 2 * f(q) + f(q - h)) / h ** 2              # observed information: curvature at the peak
lp = log_pmf(n, p0)                                          # expected information: average squared score
I0 = sum(exp(lp[k]) * ((ll(k, n, p0 + h) - ll(k, n, p0 - h)) / (2 * h)) ** 2 for k in range(n + 1))
print(f"search: p-hat {q:.6f}; score at p0 {U:.4f}; curvature at p-hat {J:.4f}; E[score^2] at p0 {I0:.4f}, root {sqrt(I0):.4f}")
print(f"per patient: I(p-hat) = {J / n:.4f}  I(p0) = {I0 / n:.4f}; drop in log-lik {f(q) - f(p0):.4f}")
zw2, zs2, W2 = (q - p0) * sqrt(J), U / sqrt(I0), 2 * (f(q) - f(p0))
print(f"search: Wald z = {zw2:.4f}  score z = {zs2:.4f}  W = {W2:.4f}")
assert abs(zw - zw2) < 1e-5 and abs(zs - zs2) < 1e-5 and abs(W - W2) < 1e-8
# ---- intervals: keep every p0 each test does not reject ----
ints = {}
for i, name in enumerate(("Wald", "score", "LR")):
    g = lambda p: (stats(x, n, p)[i] ** 2 if i < 2 else stats(x, n, p)[2]) - c * c
    ints[name] = (bisect(g, 0.2, ph), bisect(g, ph, 0.8))
    print(f"{name} interval {ints[name][0]:.4f} to {ints[name][1]:.4f}")
se = sqrt(ph * (1 - ph) / n); mid = (ph + c * c / (2 * n)) / (1 + c * c / n)
hw = c * sqrt(ph * (1 - ph) / n + c * c / (4 * n * n)) / (1 + c * c / n)
assert abs(ints["Wald"][0] - (ph - c * se)) < 1e-9 and abs(ints["score"][1] - (mid + hw)) < 1e-9
# ---- road 3: exact enumeration under p0 = 0.35 ----
pm, dp = [exp(v) for v in lp], [1.0]          # second road to the law: add one patient at a time
for _ in range(n): dp = [a * (1 - p0) + b * p0 for a, b in zip(dp + [0.0], [0.0] + dp)]
A, B, s = 1 + c * c / n, 2 * p0 + c * c / n, c * sqrt(n * p0 * (1 - p0))   # cutoffs on the count, in closed form
r = n * sqrt(B * B - 4 * A * p0 * p0) / (2 * A)                             # Wald: n (q - p0)^2 = c^2 q (1 - q)
cut = ((n * B / (2 * A) - r, n * B / (2 * A) + r), (n * p0 - s, n * p0 + s), (n * p0 - s, n * p0 + s))  # LR: the score's
for i, name in enumerate(("Wald", "score", "LR")):
    rej = [k for k in range(n + 1) if (abs(stats(k, n, p0)[i]) >= c if i < 2 else stats(k, n, p0)[2] >= c * c)]
    size = sum(pm[k] for k in rej)
    print(f"exact size of 5% {name} test at p0: {size:.4f}  (rejects counts <= {max(k for k in rej if k < 35)}, >= {min(k for k in rej if k > 35)})")
    assert abs(size - sum(dp[k] for k in range(n + 1) if not cut[i][0] < k < cut[i][1])) < 1e-12
up = sum(pm[x:])
print(f"exact binomial at p0: P(count >= 45) = {up:.4f}; two-sided p = {2 * up:.4f}")
assert abs(up - sum(dp[x:])) < 1e-12
# ---- consistency and normality: truth 0.45, growing n ----
K = lambda t: 0.45 * log(t) + 0.55 * log(1 - t)
print(f"average log-lik limit K: K(0.40) = {K(0.40):.6f}  K(0.45) = {K(0.45):.6f}  K(0.50) = {K(0.50):.6f}")
assert K(0.45) > K(0.40) and K(0.45) > K(0.50)
for m in (10, 100, 1000, 10000):
    pmf = [exp(v) for v in log_pmf(m, 0.45)]; sd = sqrt(0.45 * 0.55 / m)
    off = sum(pmf[k] for k in range(m + 1) if abs(k / m - 0.45) > 0.05 + 1e-12)
    cov = sum(pmf[k] for k in range(m + 1) if abs(k / m - 0.45) <= c * sd + 1e-12)
    cdf, gap = 0.0, 0.0
    for k in range(m + 1):
        z = (k / m - 0.45) / sd
        gap = max(gap, abs(cdf - Phi(z)), abs(cdf + pmf[k] - Phi(z))); cdf += pmf[k]
    print(f"n={m}: sd {sd:.5f}; P(off by > 0.05) {off:.4f}; P(within 1.96 sd) {cov:.4f}; max gap to bell {gap:.4f}")
    assert gap < 1.0 / sqrt(m) and abs(cov - 0.95) < 0.01
# ---- road 4: where it fails -- uniform on (0, theta), MLE = largest draw, simulated ----
th, m, R, st, S, S2, below = 2.0, 100, 20000, 20261123, 0.0, 0.0, 0
for _ in range(R):
    mx = 0.0
    for _ in range(m):
        st, u = splitmix(st); mx = max(mx, th * u / 2 ** 53)
    S, S2, below = S + mx, S2 + mx * mx, below + (mx < th)
mean, sdv = S / R, sqrt(S2 / R - (S / R) ** 2)
ex_mean, ex_sd = m * th / (m + 1), th * sqrt(m / ((m + 1) ** 2 * (m + 2)))
print(f"uniform, theta 2, n 100: mean {mean:.4f} (exact {ex_mean:.4f}); sd {sdv:.4f} (exact {ex_sd:.4f}); below theta {below / R:.4f}")
print(f"uniform: the bell rule's sd theta/sqrt(n) = {th / sqrt(m):.4f}")
assert abs(mean - ex_mean) < 4 * ex_sd / sqrt(R) and abs(sdv - ex_sd) < 0.05 * ex_sd
# ---- what breaks ----
lg = lambda p: log(p / (1 - p))
fe = lambda e: f(1 / (1 + exp(-e)))                                # the same log-likelihood, read on the log-odds scale
zl, zsl = (lg(ph) - lg(p0)) * sqrt(n * ph * (1 - ph)), (fe(lg(p0) + h) - fe(lg(p0) - h)) / (2 * h) / sqrt(n * p0 * (1 - p0))
Jl = -(fe(lg(q) + h) - 2 * fe(lg(q)) + fe(lg(q) - h)) / h ** 2    # curvature on log-odds, at the searched peak
print(f"breaks: Wald on log-odds {zl:.4f} (p {p2(zl):.4f}); score on log-odds {zsl:.4f}")
assert abs(zl - (lg(q) - lg(p0)) * sqrt(Jl)) < 1e-5 and abs(zsl - zs) < 1e-5
print(f"breaks: one patient's information z = {(ph - p0) / sqrt(ph * (1 - ph)):.4f} (p {p2((ph - p0) / sqrt(ph * (1 - ph))):.4f}); W read as z, p = {p2(W):.6f}")
zw0, zs0, W0 = stats(0, 100, 0.02)
print(f"breaks: 0 of 100, test 0.02: Wald z {zw0}; score z {zs0:.4f} (p {p2(zs0):.4f}); W {W0:.4f} (p {p2(sqrt(W0)):.4f}); P(0 of 100 at 0.02) {exp(log_pmf(100, 0.02)[0]):.4f}")
# ---- the chart: each statistic, squared, against the candidate p ----
grid = [0.30 + 0.025 * i for i in range(13)]
print("chart, p:", ", ".join(f"{p:.3f}" for p in grid))
for i, name in enumerate(("Wald z^2", "score z^2", "W")):
    print(f"chart, {name}:", ", ".join(f"{stats(x, n, p)[i] ** (2 if i < 2 else 1):.2f}" for p in grid))
# ---- try changing ----
for k, nn, t in ((90, 200, 0.35), (40, 100, 0.35), (45, 100, 0.25)):
    a, b, w = stats(k, nn, t)
    print(f"try {k}/{nn} vs {t}: Wald {a:.4f}  score {b:.4f}  root W {sqrt(w):.4f}")
print("ALL CHECKS PASS")
