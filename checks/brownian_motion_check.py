# Brownian motion: a grain's sideways position W_t, in micrometres (um), t seconds
# after it was first seen; its variance grows by 1 square um per second.
# Question: P(W_10 > 5), the chance it is more than 5 um right of its start at 10 s.
# Three roads: the Gaussian formula; the exact law of a walk with n steps a second,
# each +-1/sqrt(n) um; 100,000 seeded paths sampled every second.  Standard library only.
from math import sqrt, exp, log, cos, pi

T, A, M64 = 10, 5.0, (1 << 64) - 1

def phi(x):                                   # standard normal density
    return exp(-x * x / 2) / sqrt(2 * pi)
def Phi(x, m=2000):                           # its CDF: 1/2 plus Simpson's rule on [0, x]
    h = x / m
    s = phi(0.0) + phi(x) + sum((4 if i % 2 else 2) * phi(i * h) for i in range(1, m))
    return 0.5 + s * h / 3
def tail(a, var):                             # P(N(0, var) > a)
    return 1 - Phi(a / sqrt(var))
LF = [0.0]                                    # LF[k] = ln k!
for i in range(1, T * 10000 + 1):
    LF.append(LF[-1] + log(i))
def walk(N, kmin):                            # N fair +-1 steps, height k = 2j - N:
    w = [exp(LF[N] - LF[j] - LF[N - j] - N * log(2)) for j in range(N + 1)]
    p = sum(x for j, x in enumerate(w) if 2 * j - N >= kmin)
    return w, p, sum(x * (2 * j - N) ** 2 for j, x in enumerate(w))
def first_k(N, ok):                           # smallest height k > 0, parity of N, passing ok
    k = 1
    while (k - N) % 2 or not ok(k):
        k += 1
    return k
def persistent(N, r, kmin):                   # each step repeats the last with chance r
    w = [[0.0, 0.0] for _ in range(2 * N + 1)]        # w[k + N][d]: height k, last step d
    w[N + 1][1], w[N - 1][0] = 0.5, 0.5
    for _ in range(N - 1):
        new = [[0.0, 0.0] for _ in range(2 * N + 1)]
        for i in range(1, 2 * N):
            new[i + 1][1] += w[i][1] * r + w[i][0] * (1 - r)
            new[i - 1][0] += w[i][0] * r + w[i][1] * (1 - r)
        w = new
    tot = [a + b for a, b in w]
    return sum(x for i, x in enumerate(tot) if i - N >= kmin), sum(x * (i - N) ** 2 for i, x in enumerate(tot))
seed = 2026
def unif():                                   # SplitMix64, mapped into (0, 1]
    global seed
    seed = (seed + 0x9E3779B97F4A7C15) & M64
    z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0 ** 53
def normal():                                 # Box-Muller, cosine half only
    u, v = unif(), unif()
    return sqrt(-2 * log(u)) * cos(2 * pi * v)
def row(label, x, se=None):
    print(f"{label:<44}{x:>10.4f}" + ("" if se is None else f"   se {se:.4f}"))
def mean_se(xs):
    m = sum(xs) / len(xs)
    return m, sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))
print("== road one: the Gaussian formula ==")
exact = tail(A, T)
row("z = 5 / sqrt(10)", A / sqrt(T))
row("Phi(z)", Phi(A / sqrt(T)))
row("P(W_10 > 5) = 1 - Phi(z)", exact)
row("P(|W_10| <= sqrt(10))", 2 * Phi(1.0) - 1)
cond = tail(A - 2.0, T - 4)
row("P(W_10 > 5 | W_4 = 2) = P(N(0,6) > 3)", cond)
row("Cov(W_4, W_10) = min(4, 10)", 4.0)
row("correlation sqrt(4/10)", sqrt(4 / T))
print("== road two: exact law of the walk, n steps a second ==")
law1, p1, _ = walk(T, 6)                      # n = 1: one +-1 um step a second
row("n = 1, one 1 um step a second: P(S > 5)", p1)
errs = []
for n in (4, 16, 64, 256, 1024, 4096):
    N = T * n
    k = first_k(N, lambda k: k * k > 25 * n)          # k / sqrt(n) > 5
    _, p, m2 = walk(N, k)
    errs.append(p - exact)
    assert abs(m2 / n - T) < 1e-6, "walk variance is not 10"
    print(f"n = {n:>4}: P(S > 5) = {p:.6f}, error {p - exact:+.6f}, error x sqrt(n) {(p - exact) * sqrt(n):+.4f}")
half_atom = -phi(A / sqrt(T)) / sqrt(T)               # minus half the lattice step 2/sqrt(n) times the density at 5
row("predicted error x sqrt(n): -phi(z)/sqrt(10)", half_atom)
assert all(abs(e * sqrt(n) - half_atom) < 0.004 for e, n in zip(errs[1:], (16, 64, 256, 1024, 4096))), "error is not half an atom"
print("== road three: 100,000 paths sampled every second ==")
path = [0.0]
for _ in range(20):                           # chart path: steps of 0.5 s, sd sqrt(0.5)
    path.append(path[-1] + sqrt(0.5) * normal())
W4, W10 = [], []
for _ in range(100000):
    w = 0.0
    for t in range(1, T + 1):
        w += normal()                         # W_t - W_(t-1) ~ N(0, 1)
        if t == 4: W4.append(w)
    W10.append(w)
R = len(W10)
m, se = mean_se(W10)
row("mean of W_10", m, se)
v = sum((x - m) ** 2 for x in W10) / (R - 1)
vse = sqrt((sum((x - m) ** 4 for x in W10) / R - v * v) / R)
row("variance of W_10", v, vse)
assert abs(v - T) < 4 * vse, "simulated variance is not 10"
ps, pse = mean_se([1.0 if x > A else 0.0 for x in W10])
row("P(W_10 > 5)", ps, pse)
assert abs(ps - exact) < 4 * pse, "simulation disagrees with the formula"
row("P(|W_10| <= sqrt(10))", *mean_se([1.0 if abs(x) <= sqrt(T) else 0.0 for x in W10]))
m4 = sum(W4) / R
cv, cse = mean_se([(a - m4) * (b - m) for a, b in zip(W4, W10)])
row("Cov(W_4, W_10)", cv, cse)
assert abs(cv - 4) < 4 * cse, "simulated covariance is not 4"
row("Cov(W_4, W_10 - W_4)", *mean_se([(a - m4) * (b - a) for a, b in zip(W4, W10)]))
near = [b for a, b in zip(W4, W10) if 1.9 <= a <= 2.1]
pc, pcse = mean_se([1.0 if b > A else 0.0 for b in near])
print(f"paths with 1.9 <= W_4 <= 2.1: {len(near)}")
row("P(W_10 > 5 | W_4 near 2)", pc, pcse)
assert abs(pc - cond) < 4 * pcse, "fresh-start rule fails"
print("== what breaks ==")
_, p, m2 = walk(1000, first_k(1000, lambda k: k > 500))      # steps 1/100 um, 100 a second
row("steps 1/n: n = 100, variance", m2 / 100 ** 2)
row("steps 1/n: n = 100, P(S > 5)", p)
_, p, m2 = walk(1000, first_k(1000, lambda k: k > 5))        # steps 1 um, 100 a second
row("steps 1 um: n = 100, variance", m2)
row("steps 1 um: n = 100, P(S > 5)", p)
row("spread taken as t: P(N(0, 100) > 5)", tail(A, 100.0))
row("W_4 = 2 ignored: P(W_10 > 5)", exact)
pp, pv = persistent(1000, 0.75, first_k(1000, lambda k: k * k > 2500))
pf = 1000 + 2 * sum((1000 - k) * 0.5 ** k for k in range(1, 1000))
assert abs(pv - pf) < 1e-6, "persistent walk: exact law disagrees with the sum"
row("repeating steps: variance, exact law", pv / 100)
row("repeating steps: variance, sum of covariances", pf / 100)
row("repeating steps: P(S > 5), exact law", pp)
row("repeating steps: limit P(N(0, 30) > 5)", tail(A, 30.0))
print("== charts ==")
print("chart, t (s)       " + " ".join(f"{0.5 * i:g}" for i in range(21)))
print("chart, path (um)   " + " ".join(f"{x:.2f}" for x in path))
print("chart, +sqrt(t)    " + " ".join(f"{sqrt(0.5 * i):.2f}" for i in range(21)))
print("chart, -sqrt(t)    " + " ".join(f"{-sqrt(0.5 * i) + 0.0:.2f}" for i in range(21)))
print("chart, k (um)      " + " ".join(str(2 * j - 10) for j in range(11)))
print("chart, walk law (%)    " + " ".join(f"{100 * x:.2f}" for x in law1))
print("chart, 2 x density (%) " + " ".join(f"{200 * phi((2 * j - 10) / sqrt(T)) / sqrt(T):.2f}" for j in range(11)))
print("ALL CHECKS PASS")
