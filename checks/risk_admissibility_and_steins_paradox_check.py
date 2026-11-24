# Risk, minimax, admissibility and Stein's paradox -- the check behind the card.  Standard library only.
# Part 1: a coin flipped 16 times.  Each rule's risk (average squared miss) is computed two ways:
# a closed form, and an exact sum over all 17 possible head counts.  Minimax is found a third way,
# by searching the shrink rules (X + a)/(16 + 2a) for the smallest worst-case risk.
# Part 2: five means, each seen once with unit normal noise.  James-Stein risk comes from a
# Poisson series, from a seeded simulation of the actual loss, and from Stein's unbiased
# risk estimate averaged over the same draws.  Quadrature checks two more simulated risks.
import math
N, P = 16, 5
MASK = (1 << 64) - 1

def choose(n, k):
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def risk_sum(rule, p, n=N):                       # exact: sum over every head count x
    return sum(choose(n, x) * p ** x * (1 - p) ** (n - x) * (rule(x) - p) ** 2 for x in range(n + 1))

def plain(x): return x / N
def minimax(x): return (x + 2) / (N + 4)
def half(x): return x / 8                          # uses only the first 8 flips: x counts their heads

def simpson(g, lo, hi, n=2000):
    h = (hi - lo) / n
    return (g(lo) + g(hi) + sum((4 if i % 2 else 2) * g(lo + i * h) for i in range(1, n))) * h / 3

def beta22(p): return 6 * p * (1 - p)              # the Beta(2, 2) prior density
def worst(a, n=N):                                 # largest risk of (X + a)/(n + 2a) over a fine grid of p
    return max(risk_sum(lambda x: (x + a) / (n + 2 * a), i / 400, n) for i in range(401))
lo, hi = 0.0, 5.0
for _ in range(50):                                # ternary search for the a with the smallest worst risk
    m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    lo, hi = (lo, m2) if worst(m1) < worst(m2) else (m1, hi)
a_best = (lo + hi) / 2
grid = [i / 20 for i in range(21)]
r_plain = [risk_sum(plain, p) for p in grid]
r_mm = [risk_sum(minimax, p) for p in grid]
r_half = [risk_sum(half, p, 8) for p in grid]
bayes_plain = simpson(lambda p: beta22(p) * risk_sum(plain, p), 0, 1, 400)
bayes_mm = simpson(lambda p: beta22(p) * risk_sum(minimax, p), 0, 1, 400)
a10 = math.sqrt(10) / 2

def einv(lam, p=P):                                # E[1/S], S noncentral chi-square: Poisson mixture
    s, w = 0.0, math.exp(-lam / 2)
    for k in range(400):
        s += w / (p - 2 + 2 * k)
        w *= lam / 2 / (k + 1)
    return s
def js_risk(lam, c=P - 2, p=P): return p - c * (2 * (p - 2) - c) * einv(lam, p)

X = [1.2, -0.4, 2.0, 0.3, -1.1]
S = sum(v * v for v in X)
share = 1 - (P - 2) / S

state = 20261123                                   # SplitMix64, then Box-Muller for normal draws
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def normal():
    return math.sqrt(-2 * math.log(uniform())) * math.cos(2 * math.pi * uniform())
def simulate(theta, reps=100000):                  # mean and standard error of each loss
    acc = [[0.0, 0.0] for _ in range(5)]
    for _ in range(reps):
        x = [t + normal() for t in theta]
        s = sum(v * v for v in x)
        c, cp = 1 - (P - 2) / s, max(0.0, 1 - (P - 2) / s)
        losses = [sum((v - t) ** 2 for v, t in zip(x, theta)),
                  sum((c * v - t) ** 2 for v, t in zip(x, theta)),
                  P - (P - 2) ** 2 / s,            # Stein's unbiased risk estimate
                  sum((cp * v - t) ** 2 for v, t in zip(x, theta)),
                  (c * x[0] - theta[0]) ** 2]      # the first mean's own squared miss
        for j, l in enumerate(losses):
            acc[j][0] += l
            acc[j][1] += l * l
    return [(s1 / reps, math.sqrt((s2 / reps - (s1 / reps) ** 2) / reps)) for s1, s2 in acc]
sim_obs = simulate(X)
sim_zero = simulate([0.0] * 5)
sim_one = simulate([3.0, 0, 0, 0, 0])
lams = [5 * i for i in range(11)]
def first_mean(h=0.02):                            # exact: the first mean's own risk at theta = (3,0,0,0,0)
    xs, us = [-5 + (i + 0.5) * h for i in range(800)], [(j + 0.5) * h for j in range(500)]  # X1 ~ N(3,1); u = sqrt(R)
    return sum(math.exp(-(x - 3) ** 2 / 2) * ((1 - 3 / (x * x + u * u)) * x - 3) ** 2 * u ** 3 * math.exp(-u * u / 2)
               for x in xs for u in us) * h * h / (2 * math.sqrt(2 * math.pi))   # midpoint rule; R ~ chi-square(4)
first = first_mean()
jsp0 = simpson(lambda s: (s - 6 + 9 / s) * s ** 1.5 * math.exp(-s / 2) / (3 * math.sqrt(2 * math.pi)), 3, 80, 2000)  # JS+ at 0

def f(v, d=4): return f"{v:.{d}f}"
print("coin, n = 16")
print("plain X/16: risk at theta = 0.5, 0.2, 0.1", f(r_plain[10], 6), f(r_plain[4], 6), f(r_plain[2], 6))
print("  closed form theta(1-theta)/16 at 0.5, 0.1", f(0.25 / 16, 6), f(0.09 / 16, 6))
print("(X+2)/20: risk min and max over theta", f(min(r_mm), 6), f(max(r_mm), 6))
print("first 8 flips only: risk at 0.5, 0.1", f(r_half[10], 6), f(r_half[2], 6))
print("risks cross where theta(1-theta) = 0.16, theta =", f(0.5 - math.sqrt(0.25 - 0.16), 2), f(0.5 + math.sqrt(0.25 - 0.16), 2))
print("constant guess 0.5: risk at 0.5, 0.1", f(risk_sum(lambda x: 0.5, 0.5), 6), f(risk_sum(lambda x: 0.5, 0.1), 6))
print("Bayes risk under Beta(2,2): plain, (X+2)/20", f(bayes_plain, 6), f(bayes_mm, 6))
print("  closed form (1/5)/16", f(0.2 / 16, 6))
print("search: best a in (X+a)/(16+2a), worst risk", f(a_best), f(worst(a_best), 6))
print("  sqrt(16)/2, 1/(4(sqrt(16)+1)^2)", f(math.sqrt(16) / 2), f(1 / (4 * 25), 6))
print("(X+1)/18: worst risk", f(worst(1), 6))
print("11 heads of 16: plain, minimax", f(11 / 16), f(13 / 20))
print("house coin n = 10: minimax a, worst risk, plain worst", f(a10), f(1 / (4 * (math.sqrt(10) + 1) ** 2), 6), f(0.025, 6))
print("  7 of 10: plain, minimax, Beta(2,2) mean", f(0.7), f((7 + a10) / (10 + 2 * a10)), f(9 / 14))
print("five means, unit noise")
print("seen", " ".join(f(v, 1) for v in X), "sum of squares", f(S, 2))
print("share kept 1 - 3/S", f(share))
print("James-Stein estimates", " ".join(f(share * v, 3) for v in X))
print("risk at |theta|^2 = 0: series, 5 - 9/3", f(js_risk(0)), f(5 - 9 / 3))
print("risk at |theta|^2 = 6.9 (theta = the data)", f(js_risk(S)))
for name, sim in (("theta = data", sim_obs), ("theta = 0", sim_zero), ("theta = (3,0,0,0,0)", sim_one)):
    print(f"sim {name}: plain, JS, SURE, JS+, first mean")
    print("  " + "  ".join(f"{m:.4f}+-{se:.4f}" for m, se in sim))
print("exact at theta = (3,0,0,0,0): JS total, first mean by quadrature", f(js_risk(9)), f(first))
print("exact JS+ risk at theta = 0, by Simpson over S ~ chi-square(5)", f(jsp0))
print("constant c at theta = 0: c = 3, 5, 6, 7", " ".join(f(js_risk(0, c)) for c in (3, 5, 6, 7)))
print("risk at 0 for k = 3, 10, 100", " ".join(f(js_risk(0, p - 2, p)) for p in (3, 10, 100)))
print("figure, coin plain risk x1000 at theta = 0, 0.05, .., 1: " + ", ".join(f(1000 * r, 1) for r in r_plain))
print("figure, JS risk at |theta|^2 = 0, 5, .., 50: " + ", ".join(f(js_risk(l), 2) for l in lams))
assert all(abs(r - p * (1 - p) / 16) < 1e-12 for r, p in zip(r_plain, grid))     # sum against closed form
assert abs(max(r_mm) - 0.01) < 1e-12 and abs(min(r_mm) - 0.01) < 1e-12         # constant risk, by summing
assert abs(bayes_plain - 0.2 / 16) < 1e-9 and abs(bayes_mm - 0.01) < 1e-9        # Simpson against Beta moments
assert abs(a_best - 2) < 1e-3                                                   # search finds sqrt(n)/2
assert all(h > r for h, r in zip(r_half[1:-1], r_plain[1:-1]))                   # throwing flips away is dominated
assert abs(js_risk(0) - 2) < 1e-12 and max(js_risk(l) for l in lams) < 5       # series against chi-square mean
for sim, lam in ((sim_obs, S), (sim_zero, 0), (sim_one, 9)):
    assert abs(sim[1][0] - js_risk(lam)) < 4 * sim[1][1]                        # simulated loss against series
    assert abs(sim[2][0] - js_risk(lam)) < 4 * sim[2][1]                        # unbiased risk estimate too
    assert abs(sim[0][0] - 5) < 4 * sim[0][1]                                   # plain averages: risk 5
assert abs(sim_one[4][0] - first) < 4 * sim_one[4][1]                           # first mean: simulation against quadrature
assert abs(sim_zero[3][0] - jsp0) < 4 * sim_zero[3][1]                          # positive part: simulation against Simpson
print("ALL CHECKS PASS")
