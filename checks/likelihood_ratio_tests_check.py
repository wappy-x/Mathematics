# Likelihood ratio tests -- the check behind the card.  Standard library only.
# Drug trial: 45 of 100 recover on the drug, 35 of 100 on placebo.
# One shared recovery rate (1 parameter) against one rate per arm (2 parameters).
from math import log, exp, sqrt, pi

def Phi(x):                                   # bell-curve area left of x, Taylor series of erf
    t, s, n, y = x / sqrt(2.0), 0.0, 0, x / sqrt(2.0)
    while abs(t) > 1e-17:
        s, n = s + t / (2 * n + 1), n + 1
        t *= -y * y / n
    return 0.5 + s / sqrt(pi)

def Phi_simpson(x, m=2000):                   # second road: Simpson's rule on the bell-curve height
    h = x / m
    f = lambda u: exp(-u * u / 2) / sqrt(2 * pi)
    s = f(0) + f(x) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, m))
    return 0.5 + s * h / 3

def tail1(w):                                 # chance a chi-square with 1 degree of freedom exceeds w
    return 2.0 * (1.0 - Phi(sqrt(w))) if w > 0 else 1.0

def xlogy(x, y): return x * log(y) if x > 0 else 0.0
def loglik(x, n, p): return xlogy(x, p) + xlogy(n - x, 1 - p)

def W_formula(x1, x2, n1, n2):                # 2 * sum O ln(O/E) over the four cells
    pool = (x1 + x2) / (n1 + n2)
    cells = [(x1, n1 * pool), (n1 - x1, n1 * (1 - pool)), (x2, n2 * pool), (n2 - x2, n2 * (1 - pool))]
    return 2 * sum(o * log(o / e) for o, e in cells if o > 0)

def golden_max(f, lo=1e-12, hi=1 - 1e-12):   # golden-section search: no closed-form estimate used
    g = (sqrt(5) - 1) / 2
    a, b = lo, hi
    for _ in range(200):
        c, d = b - g * (b - a), a + g * (b - a)
        a, b = (a, d) if f(c) > f(d) else (c, b)
    return (a + b) / 2

def binom_pmf(n, p):                          # all binomial chances, by the ratio rule
    out = [(1 - p) ** n]
    for k in range(n):
        out.append(out[-1] * (n - k) / (k + 1) * p / (1 - p))
    return out

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, (z ^ (z >> 31)) >> 11

x1, n1, x2, n2 = 45, 100, 35, 100
pool = (x1 + x2) / (n1 + n2)
# ---- road 1: the closed form ----
W = W_formula(x1, x2, n1, n2)
for o, e in ((45, 40), (55, 60), (35, 40), (65, 60)):
    print(f"cell O={o} E={e}: ln(O/E)={log(o / e):.6f}  O*ln(O/E)={o * log(o / e):.6f}")
print(f"W (closed form) = {W:.6f};  W/2 = {W / 2:.6f};  Lambda = exp(-W/2) = {exp(-W / 2):.6f}")
se = lambda p, n: sqrt(p * (1 - p) / n)
print(f"estimates: drug {x1 / n1:.2f} (se {se(x1 / n1, n1):.4f}), placebo {x2 / n2:.2f} (se {se(x2 / n2, n2):.4f}), difference {x1 / n1 - x2 / n2:.2f} (se {sqrt(se(x1 / n1, n1) ** 2 + se(x2 / n2, n2) ** 2):.4f})")
# ---- road 2: maximise each log-likelihood numerically ----
q1 = golden_max(lambda p: loglik(x1, n1, p)); q2 = golden_max(lambda p: loglik(x2, n2, p))
q0 = golden_max(lambda p: loglik(x1, n1, p) + loglik(x2, n2, p))
l_full, l_null = loglik(x1, n1, q1) + loglik(x2, n2, q2), loglik(x1, n1, q0) + loglik(x2, n2, q0)
W_num = 2 * (l_full - l_null)
print(f"golden search: p_drug={q1:.6f} p_placebo={q2:.6f} p_shared={q0:.6f}")
print(f"log-lik two rates={l_full:.6f} one rate={l_null:.6f}  W (search) = {W_num:.6f}")
assert abs(W - W_num) < 1e-8
# ---- the quadratic approximation: Pearson's X^2 = z^2 ----
z = (x1 / n1 - x2 / n2) / sqrt(pool * (1 - pool) * (1 / n1 + 1 / n2))
print(f"two-proportion z = {z:.6f};  z^2 = Pearson X^2 = {z * z:.6f};  W - X^2 = {W - z * z:.6f}")
assert abs(W - z * z) < 0.01
# ---- Wilks: chi-square tail with 1 degree of freedom; Phi two ways ----
print(f"Phi(1.96): series {Phi(1.96):.10f}  Simpson {Phi_simpson(1.96):.10f}")
assert abs(Phi(1.96) - Phi_simpson(1.96)) < 1e-10
lo, hi = 0.0, 20.0
for _ in range(100):
    mid = (lo + hi) / 2
    if tail1(mid) > 0.05: lo = mid
    else: hi = mid
crit = (lo + hi) / 2
p_chi = tail1(W)
print(f"5% cutoff (bisection) = {crit:.4f};  p-value by chi-square(1) = {p_chi:.4f}")
# ---- road 3: exact enumeration of W over all 101 x 101 outcomes, both arms at the shared rate ----
pm1, pm2 = binom_pmf(n1, pool), binom_pmf(n2, pool)
Ws, Wone = [], []
for a in range(n1 + 1):
    for b in range(n2 + 1):
        w, pr = W_formula(a, b, n1, n2), pm1[a] * pm2[b]
        Ws.append((w, pr)); Wone.append((w if a * n2 >= b * n1 else 0.0, pr))
ex_tail = lambda L, w: sum(pr for v, pr in L if v >= w - 1e-12)
p_exact = ex_tail(Ws, W)
size_exact, size_one = ex_tail(Ws, crit), ex_tail(Wone, crit)
print(f"exact at rate {pool:.2f}: P(W >= {W:.4f}) = {p_exact:.4f};  mean W = {sum(v * pr for v, pr in Ws):.4f}")
print(f"exact size of 'reject if W >= {crit:.4f}': two-rate model {size_exact:.4f}")
assert abs(p_chi - p_exact) < 0.01
# ---- road 4: simulation, SplitMix64 seed 20260928 ----
st, R, hitp, hit5 = 20260928, 20000, 0, 0
for _ in range(R):
    c = [0, 0]
    for arm, n in ((0, n1), (1, n2)):
        for _ in range(n):
            st, u = splitmix(st)
            c[arm] += u < pool * 2 ** 53
    w = W_formula(c[0], c[1], n1, n2)
    hitp += w >= W - 1e-12; hit5 += w >= crit
fp, f5 = hitp / R, hit5 / R
sp, s5 = sqrt(fp * (1 - fp) / R), sqrt(f5 * (1 - f5) / R)
print(f"simulated {R} trials: P(W >= {W:.4f}) = {fp:.4f} (se {sp:.4f});  size at cutoff = {f5:.4f} (se {s5:.4f})")
assert abs(fp - p_exact) < 4 * sp and abs(f5 - size_exact) < 4 * s5
# ---- the chart: exact tail against Wilks' chi-square tail, in percent ----
grid = [0.5 * i for i in range(1, 13)]
print("chart, w:", ", ".join(f"{w:.1f}" for w in grid))
print("chart, chi-square(1) %:", ", ".join(f"{100 * tail1(w):.2f}" for w in grid))
print("chart, exact two-rate %:", ", ".join(f"{100 * ex_tail(Ws, w):.2f}" for w in grid))
print("chart, half chi-square(1) %:", ", ".join(f"{50 * tail1(w):.2f}" for w in grid))
print("chart, exact one-sided %:", ", ".join(f"{100 * ex_tail(Wone, w):.2f}" for w in grid))
# ---- what breaks ----
print(f"breaks: size of one-sided model at {crit:.4f} = {size_one:.4f} (half of two-rate: {size_exact / 2:.4f})")
assert abs(size_one - size_exact / 2) < 0.005
print(f"breaks: drop the 2 -> p = {tail1(W / 2):.4f};  2 degrees of freedom -> p = {exp(-W / 2):.4f}")
# ---- Neyman-Pearson: drug arm alone, rate 0.35 against rate 0.45 ----
for n, alpha in ((100, 0.05), (10, 0.05)):
    f0, f1 = binom_pmf(n, 0.35), binom_pmf(n, 0.45)
    c = next(k for k in range(n + 1) if sum(f0[k:]) <= alpha)
    size, power = sum(f0[c:]), sum(f1[c:])
    print(f"NP n={n}: reject if count >= {c}; size {size:.4f}; power {power:.4f}; ratio at cutoff {f1[c] / f0[c]:.4f}")
    if n == 100: print(f"NP n=100: two-sided rule |count-35| >= 10 has size {sum(f0[:26]) + sum(f0[45:]):.4f}, power {sum(f1[:26]) + sum(f1[45:]):.4f}")
best = max(sum(f1[k] for k in range(11) if m >> k & 1)
           for m in range(2 ** 11) if sum(f0[k] for k in range(11) if m >> k & 1) <= size + 1e-15)
print(f"NP n=10: best power over all 2048 rejection sets of size <= {size:.4f}: {best:.4f}")
assert abs(best - power) < 1e-12
# ---- try changing ----
for (a, na, b, nb) in ((90, 200, 70, 200), (45, 100, 25, 100), (45, 100, 42, 100)):
    w = W_formula(a, b, na, nb)
    print(f"try: {a}/{na} vs {b}/{nb}: W = {w:.4f}, p = {tail1(w):.4f}")
print("all checks passed")
