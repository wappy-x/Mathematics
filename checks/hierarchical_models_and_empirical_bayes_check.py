# Hierarchical models and empirical Bayes -- the check behind the card.  Standard library only.
# Five shops' conversion rates, each with known sampling variance.  The between-shop variance is
# found two ways (moments, and a search of the marginal likelihood).  Full Bayes with a flat prior
# on the between-shop spread is done two ways (Simpson's rule over tau, and a Gibbs sampler).
# A simulation of many five-shop worlds checks the average total squared miss of each rule.
import math
Y = [0.10, 0.14, 0.08, 0.12, 0.16]
S2, K = 0.0004, 5                                   # sampling variance of each rate; number of shops
MASK = (1 << 64) - 1
ybar = sum(Y) / K
S = sum((v - ybar) ** 2 for v in Y)                 # sum of squared gaps from the mean
spread = S / (K - 1)
tau2 = max(0.0, spread - S2)                        # moment estimate of the between-shop variance
keep = tau2 / (tau2 + S2)
keep_js = 1 - (K - 3) * S2 / S                      # James-Stein toward the mean

def loglik(t2, s=S):                                # log marginal likelihood, mean integrated out
    v = S2 + t2
    return -(K - 1) / 2 * math.log(v) - s / (2 * v)
lo, hi = 0.0, 0.01                                  # golden-section search for its peak
for _ in range(100):
    a, b = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    lo, hi = (lo, b) if loglik(a) > loglik(b) else (a, hi)
t2_ml = (lo + hi) / 2

def simpson(g, a, b, n):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3
def post(t, s=S):                                   # posterior of tau, flat prior, scaled to peak 1
    return math.exp(loglik(t * t, s) - loglik(max(0.0, s / (K - 1) - S2), s))
def bayes(s, n=2000, top=5.0):                      # flat prior on tau: E[share], E[share^2], E[tau], E[var]
    z = simpson(lambda t: post(t, s), 0, top, n)
    m1 = simpson(lambda t: post(t, s) * t * t / (S2 + t * t), 0, top, n) / z
    m2 = simpson(lambda t: post(t, s) * (t * t / (S2 + t * t)) ** 2, 0, top, n) / z
    mt = simpson(lambda t: post(t, s) * t, 0, top, n) / z
    ev = simpson(lambda t: post(t, s) * (t * t / (S2 + t * t) * S2
                                         + (S2 / (S2 + t * t)) ** 2 * (S2 + t * t) / K), 0, top, n) / z
    return m1, m2, mt, ev
fb_keep, fb_keep2, fb_tau, fb_ev = bayes(S, 20000)
d5 = Y[4] - ybar
fb5 = ybar + fb_keep * d5
fb5_sd = math.sqrt(fb_ev + (fb_keep2 - fb_keep ** 2) * d5 * d5)
eb5_sd = math.sqrt(keep * S2 + (1 - keep) ** 2 * (S2 + tau2) / K)

state = 20261123                                    # SplitMix64, then Box-Muller for normal draws
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def normal():
    return math.sqrt(-2 * math.log(uniform())) * math.cos(2 * math.pi * uniform())

ROUNDS, BATCH = 200000, 2000                        # Gibbs: theta, then mu, then tau^2, in turn
mu, t2 = ybar, spread                               # start at the raw spread, never zero
draws = [[0.0] * 4 for _ in range(ROUNDS // BATCH)]  # batch sums: share, tau, theta5, theta5^2
for r in range(ROUNDS + 1000):
    prec = 1 / S2 + 1 / t2
    theta = [(y / S2 + mu / t2) / prec + normal() / math.sqrt(prec) for y in Y]
    mu = sum(theta) / K + normal() * math.sqrt(t2 / K)
    ss = sum((th - mu) ** 2 for th in theta)
    t2 = ss / 2 / (-math.log(uniform() * uniform()))  # inverse gamma, shape (K-1)/2 = 2
    if r >= 1000:
        b = draws[(r - 1000) // BATCH]
        for j, v in enumerate((t2 / (S2 + t2), math.sqrt(t2), theta[4], theta[4] ** 2)):
            b[j] += v / BATCH
def batch_mean(j):
    m = [b[j] for b in draws]
    avg = sum(m) / len(m)
    return avg, math.sqrt(sum((x - avg) ** 2 for x in m) / (len(m) - 1) / len(m))
g_keep, g_tau, g5, g52 = (batch_mean(j) for j in range(4))
g5_sd = math.sqrt(g52[0] - g5[0] ** 2)

WORLDS, TRUE_MU = 20000, 0.12                       # worlds drawn with the estimated tau^2
names = ["raw", "known tau^2", "plug-in EB", "plug-in, no floor", "James-Stein", "full Bayes", "complete pooling"]
acc, below = [[0.0, 0.0] for _ in names], 0
for _ in range(WORLDS):
    th = [TRUE_MU + math.sqrt(tau2) * normal() for _ in range(K)]
    y = [t + math.sqrt(S2) * normal() for t in th]
    m = sum(y) / K
    s = sum((v - m) ** 2 for v in y)
    below += s / (K - 1) < S2
    shares = [1.0, keep, max(0.0, 1 - (K - 1) * S2 / s), 1 - (K - 1) * S2 / s, 1 - (K - 3) * S2 / s,
              bayes(s, 200, 0.5)[0], 0.0]
    for j, c in enumerate(shares):
        loss = sum((m + c * (v - m) - t) ** 2 for v, t in zip(y, th))
        if j in (3, 4):                             # no floor: swap the c^2 sigma^4/S tail for its exact average
            loss -= ((K - 1, K - 3)[j - 3] * S2) ** 2 * (1 / s - 1 / ((K - 3) * (S2 + tau2)))
        acc[j][0] += loss / WORLDS
        acc[j][1] += loss * loss / WORLDS
risk = [(a, math.sqrt((b - a * a) / WORLDS)) for a, b in acc]
B = S2 / (S2 + tau2)
exact = {0: K * S2, 1: K * (1 - B) * S2 + B * B * (S2 + tau2), 3: K * S2,
         4: K * S2 - (K - 3) * S2 * B, 6: (K - 1) * tau2 + S2}
p_below = 1 - math.exp(-0.8) * 1.8                  # chi-square, 4 degrees: P(below 1.6)
grid = [i / 100 for i in range(11)]
dens = [post(t) / simpson(post, 0, 5.0, 20000) for t in grid]

def f(v, d=4): return f"{v:.{d}f}"
def row(c): return " ".join(f(ybar + c * (v - ybar), 4) for v in Y)
print("five shops, rates", " ".join(f(v, 2) for v in Y), "sampling variance", S2)
print("visitors per shop that give variance 0.0004 at rate 0.12:", round(0.12 * 0.88 / S2))
print("mean", f(ybar), "sum of squares S", f(S, 6), "spread S/(k-1)", f(spread, 6))
print("gaps", " ".join(f(v - ybar) for v in Y), "squared", " ".join(f((v - ybar) ** 2) for v in Y))
print("tau^2 = spread - 0.0004:", f(tau2, 6), "tau", f(math.sqrt(tau2)))
print("marginal likelihood search: best tau^2", f(t2_ml, 6))
print("kept share tau^2/(tau^2+sigma^2)", f(keep), "pulled share", f(1 - keep))
print("precisions 1/tau^2, 1/sigma^2", f(1 / tau2, 1), f(1 / S2, 1), "share", f((1 / S2) / (1 / S2 + 1 / tau2)))
print("empirical Bayes estimates", row(keep))
print("  variance given tau^2: mu known", f(keep * S2, 6), "| mu estimated", f(eb5_sd ** 2, 6))
print("James-Stein share 1-(k-3)sigma^2/S", f(keep_js), "estimates", row(keep_js))
print("full Bayes, flat prior on tau, Simpson over tau")
print("  mean kept share", f(fb_keep), "mean tau", f(fb_tau), "estimates", row(fb_keep))
print("  shop 5: mean", f(fb5), "sd", f(fb5_sd), "| plug-in sd", f(eb5_sd), "| raw sd", f(math.sqrt(S2)))
print("Gibbs sampler,", ROUNDS, "rounds, batch-means standard errors")
print("  mean kept share", f"{g_keep[0]:.4f}+-{g_keep[1]:.4f}", "mean tau", f"{g_tau[0]:.4f}+-{g_tau[1]:.4f}")
print("  shop 5: mean", f"{g5[0]:.4f}+-{g5[1]:.4f}", "sd", f(g5_sd))
print("what breaks")
print("  forget to subtract sigma^2: share", f(spread / (spread + S2)), "shop 5", f(ybar + spread / (spread + S2) * d5))
print("  divide S by k: tau^2", f(S / K - S2, 6), "share", f((S / K - S2) / (S / K)), "shop 5", f(ybar + (S / K - S2) / (S / K) * d5))
print("  complete pooling: shop 5", f(ybar), "| no pooling: shop 5", f(Y[4]))
print("simulated worlds:", WORLDS, "with mean 0.12, tau^2 0.0006; total squared miss over 5 shops (x 1e-4)")
for j, n in enumerate(names):
    ex = f"   exact {exact[j] * 1e4:.3f}" if j in exact else ""
    print(f"  {n:<18}{risk[j][0] * 1e4:.3f}+-{risk[j][1] * 1e4:.3f}{ex}")
print("share of worlds with tau^2 estimate below zero (chi-square, 4 degrees, below 1.6)", f(below / WORLDS), "exact", f(p_below))
print("figure, posterior density of tau at 0, 0.01, .., 0.10: " + ", ".join(f(v, 2) for v in dens))
assert abs(t2_ml - tau2) < 1e-9                                       # search against moment formula
assert abs(keep - 0.6) < 1e-12 and abs(ybar + keep * d5 - 0.144) < 1e-12  # the spec's numbers
for (gm, se), exact_v in ((g_keep, fb_keep), (g_tau, fb_tau), (g5, fb5)):
    assert abs(gm - exact_v) < 4 * se                                 # Gibbs against Simpson
assert abs(g5_sd - fb5_sd) < 0.0005                                   # posterior spread, two roads
for j, ex in exact.items():
    assert abs(risk[j][0] - ex) < 4 * risk[j][1]                      # simulation against closed forms
assert abs(below / WORLDS - p_below) < 4 * math.sqrt(p_below * (1 - p_below) / WORLDS)
assert risk[5][0] < risk[4][0] < risk[0][0] and risk[2][0] < risk[0][0]  # pooling beats no pooling
print("ALL CHECKS PASS")
