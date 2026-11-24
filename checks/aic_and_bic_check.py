# AIC and BIC -- the check behind the card.  Standard library only.
# Is a die fair?  600 rolls with counts 88, 97, 100, 104, 99, 112.
# Fair model: every face 1/6, no free parameter.  Free model: six shares summing to 1, five free.
from math import log, exp, sqrt, pi, ceil

def Phi(x):                                   # bell-curve area left of x, Taylor series of erf
    y = x / sqrt(2.0)
    t, s, n = y, 0.0, 0
    while abs(t) > 1e-17:
        s, n = s + t / (2 * n + 1), n + 1
        t *= -y * y / n
    return 0.5 + s / sqrt(pi)

def tail5(x):                                 # chance a chi-square with 5 degrees of freedom exceeds x
    return 2 * (1 - Phi(sqrt(x))) + sqrt(2 * x / pi) * exp(-x / 2) * (1 + x / 3)

def bisect(f, lo, hi):                        # root of f between lo and hi, f(lo) and f(hi) of opposite sign
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (f(lo) > 0) == (f(mid) > 0) else (lo, mid)
    return (lo + hi) / 2

def loglik(c, p): return sum(ci * log(pi_) for ci, pi_ in zip(c, p))
def lnfact(m): return sum(log(i) for i in range(2, m + 1))   # ln m!, summed log by log

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, (z ^ (z >> 31)) >> 11

def scores(c):                                # gain G, AIC margin and BIC margin (fair model's lead)
    n = sum(c)
    G = 2 * (loglik(c, [ci / n for ci in c]) - loglik(c, [1 / 6] * 6))
    return G, 10 - G, 5 * log(n) - G

c = [88, 97, 100, 104, 99, 112]; n = sum(c); k = 5
l0 = loglik(c, [1 / 6] * 6)                   # fair model: nothing to fit
lhat = loglik(c, [ci / n for ci in c])        # free model: best shares are the observed fractions
G = 2 * (lhat - l0)
cells = [2 * ci * log(ci / 100) for ci in c]  # road 2 for G: cell by cell, 2 O ln(O/E)
print("cells 2*O*ln(O/100):", " ".join(f"{v:.4f}" for v in cells))
print(f"loglik fair = {l0:.4f}; free = {lhat:.4f}; gain G = {G:.4f} (cells sum {sum(cells):.4f})")
X2 = sum((ci - 100) ** 2 / 100 for ci in c)
print(f"Pearson X^2 = {X2:.4f}; LRT p = {tail5(G):.4f}; 5% cutoff = {bisect(lambda x: tail5(x) - 0.05, 0.1, 50):.4f}")
s, best = 20261123, lhat                      # road 3: random nearby shares never beat the fractions
for _ in range(20000):
    q = []
    for ci in c:
        s, r = splitmix(s)
        q.append(ci / n * (1 + 0.02 * (r / 2 ** 53 - 0.5)))
    best = max(best, loglik(c, [qi / sum(q) for qi in q]))
assert best == lhat and abs(G - sum(cells)) < 1e-9 and abs(G - X2) < 0.02
aic0, aic1 = -2 * l0, -2 * lhat + 2 * k
bic0, bic1 = -2 * l0, -2 * lhat + k * log(n)
print(f"AIC fair = {aic0:.3f}; AIC free = {aic1:.3f}; difference = {aic1 - aic0:.3f}")
print(f"BIC fair = {bic0:.3f}; BIC free = {bic1:.3f}; difference = {bic1 - bic0:.3f}; 5 ln 600 = {k * log(n):.3f}")
print(f"AIC as fresh loglik: fair {l0:.3f}, free {lhat - k:.3f}; Akaike weight of free = {1 / (1 + exp((aic1 - aic0) / 2)):.4f}")
print(f"AICc extra penalty 2k(k+1)/(n-k-1) = {2 * k * (k + 1) / (n - k - 1):.4f}")
assert abs(aic1 - aic0 - 6.854) < 5e-4
assert abs(bic1 - bic0 - 28.839) < 5e-4
# ---- BIC road: exact log marginal likelihood, uniform prior on the shares (Dirichlet(1,...,1)) ----
lm_exact = lnfact(5) + sum(lnfact(ci) for ci in c) - lnfact(n + 5)
lm_laplace = lhat + log(120) + 2.5 * log(2 * pi) - 2.5 * log(n) + 0.5 * sum(log(ci / n) for ci in c)
lm_bic = lhat - 2.5 * log(n)
print(f"ln marginal lik, free: exact {lm_exact:.4f}; Laplace {lm_laplace:.4f}; BIC form {lm_bic:.4f}")
print(f"ln Bayes factor fair:free: exact {l0 - lm_exact:.4f}; Laplace {l0 - lm_laplace:.4f}; BIC/2 {(bic1 - bic0) / 2:.4f}")
print(f"chance free model is right, even prior odds: exact {1 / (1 + exp(l0 - lm_exact)):.3e}; BIC {1 / (1 + exp((bic1 - bic0) / 2)):.3e}")
c10 = [10 * ci for ci in c]                   # ten times the rolls: BIC's dropped constant stays put
gap10 = lnfact(5) + sum(lnfact(ci) for ci in c10) - lnfact(10 * n + 5) - (loglik(c10, [ci / n for ci in c]) - 2.5 * log(10 * n))
print(f"exact minus BIC form: {lm_exact - lm_bic:.4f} at 600 rolls, {gap10:.4f} at 6000 rolls")
assert abs(lm_exact - lm_laplace) < 0.05
assert abs(gap10 - (lm_exact - lm_bic)) < 0.05
# ---- AIC road: simulate the optimism, training loglik minus expected fresh loglik ----
def simulate(p, reps, s):
    opt, pick_a, pick_b, cum = [], 0, 0, [sum(p[:j + 1]) for j in range(5)] + [1.0]
    for _ in range(reps):
        cnt = [0] * 6
        for _ in range(n):
            s, r = splitmix(s)
            u = r / 2 ** 53
            cnt[next(j for j in range(6) if u < cum[j])] += 1
        if min(cnt) == 0: continue
        th = [x / n for x in cnt]
        opt.append(loglik(cnt, th) - n * sum(pj * log(t) for pj, t in zip(p, th)))
        g = scores(cnt)[0]
        pick_a, pick_b = pick_a + (g > 10), pick_b + (g > 5 * log(n))
    m = sum(opt) / len(opt)
    se = sqrt(sum((o - m) ** 2 for o in opt) / (len(opt) - 1) / len(opt))
    return m, se, pick_a / reps, pick_b / reps
mf, sef, af, bf = simulate([1 / 6] * 6, 6000, 7)
ml, sel, al, bl = simulate([ci / n for ci in c], 3000, 11)
print(f"optimism, fair die: {mf:.3f} (se {sef:.3f}); die loaded like the data: {ml:.3f} (se {sel:.3f}); theory k = 5")
print(f"fair die, share choosing free: AIC {af:.4f} (theory {tail5(10):.4f}); BIC {bf:.4f} (theory {tail5(5 * log(n)):.3e})")
assert abs(mf - 5) < 3 * sef + 0.1 and abs(ml - 5) < 3 * sel + 0.1 and abs(af - tail5(10)) < 0.01
# ---- the chart: same shares, more rolls; G grows in step with n, the penalties do not ----
gpr = G / n
print("chart n:", " ".join(str(m) for m in range(1000, 12001, 1000)))
print("chart G:", " ".join(f"{gpr * m:.2f}" for m in range(1000, 12001, 1000)))
print("chart AIC penalty:", " ".join(f"{2 * k:.2f}" for m in range(1000, 12001, 1000)))
print("chart BIC penalty:", " ".join(f"{5 * log(m):.2f}" for m in range(1000, 12001, 1000)))
na, nb = ceil(10 / gpr), bisect(lambda m: gpr * m - 5 * log(m), 1000, 100000)   # first whole n past AIC's price; BIC's crossing
print(f"AIC switches to free at n = {na}; BIC switches at n = {ceil(nb)}; ln n passes 2 at n = {exp(2):.3f}")
scaled = lambda m: scores([ci * m / n for ci in c])   # road 2: G recomputed from the counts scaled to m rolls
assert scaled(na)[1] < 0 < scaled(na - 1)[1] and abs(scaled(nb)[2]) < 1e-6 and abs(scaled(6000)[0] - gpr * 6000) < 1e-9
# ---- what breaks ----
print(f"count 6 parameters: AIC margin {12 - G:.3f}, BIC margin {6 * log(n) - G:.3f}")
print(f"BIC with n = 6 faces: penalty {5 * log(6):.3f}, margin {5 * log(6) - G:.3f}")
print(f"BIC with log10: penalty {5 * log(n) / log(10):.3f}, margin {5 * log(n) / log(10) - G:.3f}")
print(f"drop the 2 on the loglik: {G / 2:.3f} against 10, margin {10 - G / 2:.3f}")
# ---- try changing ----
for name, t in [("x4 rolls", [4 * ci for ci in c]), ("x10 rolls", [10 * ci for ci in c]),
                ("heavier six", [85, 90, 95, 100, 100, 130])]:
    g, a, b = scores(t)
    print(f"try {name} (n = {sum(t)}): G = {g:.3f}, AIC margin {a:.3f}, BIC margin {b:.3f}, LRT p {tail5(g):.4f}")
print("ALL CHECKS PASS")
