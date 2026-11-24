# Mixed-effects models -- the check behind the card.  Standard library only: the solver,
# the REML search and the random numbers (SplitMix64, Box-Muller) are written out here.
# Three schools: mean score, pupils; within-school variance 100, between-school 25.
from math import sqrt, log, cos, sin, pi
MEAN, SIZE = [70.0, 80.0, 75.0], [4, 25, 9]
S2, T2, k, N = 100.0, 25.0, 3, 38
def kept(t2, s2, n): return t2 / (t2 + s2 / n)  # share of the gap a school keeps
def centre(t2, s2, means, sizes):               # best overall mean: weights 1 / (t2 + s2/n)
    w = [1.0 / (t2 + s2 / n) for n in sizes]
    return sum(a * b for a, b in zip(w, means)) / sum(w), w
def shrink(t2, s2, means, sizes, mu):
    return [mu + kept(t2, s2, n) * (m - mu) for m, n in zip(means, sizes)]
def solve(M, r):                                # Gaussian elimination, partial pivoting
    n, A = len(r), [row[:] + [v] for row, v in zip(M, r)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(A[i][c])); A[c], A[p] = A[p], A[c]
        for i in range(c + 1, n):
            f = A[i][c] / A[c][c]
            A[i] = [a - f * b for a, b in zip(A[i], A[c])]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (A[i][n] - sum(A[i][j] * x[j] for j in range(i + 1, n))) / A[i][i]
    return x
lam = [kept(T2, S2, n) for n in SIZE]
mu, w = centre(T2, S2, MEAN, SIZE)
theta = shrink(T2, S2, MEAN, SIZE, mu)
vmu = 1.0 / sum(w)
print("school                     A        B        C")
print("pupils n             " + "".join(f"{n:>9d}" for n in SIZE))
print("noise of mean 100/n  " + "".join(f"{S2 / n:>9.3f}" for n in SIZE))
print("kept share           " + "".join(f"{v:>9.3f}" for v in lam))
print("weight 1/(25+100/n)  " + "".join(f"{v:>9.5f}" for v in w))
print(f"sum of weights {sum(w):.5f}, weighted sum of means {sum(a * b for a, b in zip(w, MEAN)):.4f}")
print(f"overall mean {mu:.2f}, its variance {vmu:.2f}, pupil-weighted mean {sum(m * n for m, n in zip(MEAN, SIZE)) / N:.2f}")
print("shrunken mean        " + "".join(f"{v:>9.2f}" for v in theta))
# road 2: Henderson's mixed-model equations, unknowns (mu, b_A, b_B, b_C)
M = [[sum(SIZE) / S2] + [n / S2 for n in SIZE]]
for j, n in enumerate(SIZE):
    M.append([n / S2] + [(n / S2 + 1.0 / T2) if i == j else 0.0 for i in range(k)])
rhs = [sum(m * n for m, n in zip(MEAN, SIZE)) / S2] + [m * n / S2 for m, n in zip(MEAN, SIZE)]
h = solve(M, rhs)
print("Henderson mu + b_j   " + "".join(f"{h[0] + b:>9.2f}" for b in h[1:]) + f"   mu {h[0]:.2f}")
pev = [l * S2 / n + (1 - l) ** 2 * vmu for l, n in zip(lam, SIZE)]
print("error var, raw mean  " + "".join(f"{S2 / n:>9.3f}" for n in SIZE))
print("error var, shrunken  " + "".join(f"{v:>9.3f}" for v in pev))
# estimating the variances from these schools: within SS 3500 over 35 degrees of freedom
SSW = 3500.0
ybar = sum(m * n for m, n in zip(MEAN, SIZE)) / N
msw = SSW / (N - k)
msb = sum(n * (m - ybar) ** 2 for m, n in zip(MEAN, SIZE)) / (k - 1)
n0 = (N - sum(n * n for n in SIZE) / N) / (k - 1)
t2mom = max(0.0, (msb - msw) / n0)
print(f"MSW {msw:.2f}, MSB {msb:.2f}, n0 {n0:.2f}, moment estimate of tau^2 {t2mom:.2f}")
def reml(t2, s2, means, sizes, ssw):            # REML log-likelihood from the summaries
    m, wt = centre(t2, s2, means, sizes)
    ll = -(sum(sizes) - len(sizes)) * log(s2) - ssw / s2 - log(sum(wt))
    for a, n, v in zip(means, sizes, wt):
        ll += log(v) - v * (a - m) ** 2 - log(n)
    return 0.5 * ll
def golden(f, a, b):
    g = (sqrt(5) - 1) / 2
    for _ in range(80):
        c, d = b - g * (b - a), a + g * (b - a)
        if f(c) > f(d): b = d
        else: a = c
    return (a + b) / 2
def fit_reml(means, sizes, ssw):
    best_s2 = lambda t: golden(lambda s: reml(t, s, means, sizes, ssw), 1.0, 1000.0)
    t = golden(lambda t: reml(t, best_s2(t), means, sizes, ssw), 0.0, 1000.0)
    return t, best_s2(t)
rt, rs = fit_reml(MEAN, SIZE, SSW)
print(f"REML estimates: tau^2 {rt:.2f}, sigma^2 {rs:.2f}")
state = 20261123                                # SplitMix64, seed 20261123
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2.0**53
def normal():                                   # Box-Muller, cosine half
    return sqrt(-2.0 * log(1.0 - unif())) * cos(2.0 * pi * unif())
def district(sizes, mu0=75.0):                  # true school means, raw means, within SS
    true, means, ssw = [], [], 0.0
    for n in sizes:
        t = mu0 + sqrt(T2) * normal()
        ys = [t + sqrt(S2) * normal() for _ in range(n)]
        m = sum(ys) / n
        true.append(t); means.append(m); ssw += sum((v - m) ** 2 for v in ys)
    return true, means, ssw
def moments(means, sizes, ssw):                 # unclipped moment estimates (tau^2, sigma^2)
    n_, k_ = sum(sizes), len(sizes)
    yb = sum(m * n for m, n in zip(means, sizes)) / n_
    mw = ssw / (n_ - k_)
    mb = sum(n * (m - yb) ** 2 for m, n in zip(means, sizes)) / (k_ - 1)
    return (mb - mw) / ((n_ - sum(n * n for n in sizes) / n_) / (k_ - 1)), mw
reps, raw_se, shr_se, t2s, s2s = 20000, [0.0] * k, [0.0] * k, [], []
for _ in range(reps):
    true, means, ssw = district(SIZE)
    m, _ = centre(T2, S2, means, SIZE)
    sh = shrink(T2, S2, means, SIZE, m)
    for j in range(k):
        raw_se[j] += (means[j] - true[j]) ** 2 / reps
        shr_se[j] += (sh[j] - true[j]) ** 2 / reps
    a, b = moments(means, SIZE, ssw); t2s.append(a); s2s.append(b)
avg = lambda v: sum(v) / len(v)
sd = lambda v: sqrt(avg([x * x for x in v]) - avg(v) ** 2)
print("simulated, raw       " + "".join(f"{v:>9.3f}" for v in raw_se))
print("simulated, shrunken  " + "".join(f"{v:>9.3f}" for v in shr_se))
neg = sum(1 for v in t2s if v < 0) / reps
print(f"3 schools x {reps}: tau^2 estimate mean {avg(t2s):.2f}, sd {sd(t2s):.2f}, below zero {100 * neg:.1f}%; sigma^2 mean {avg(s2s):.2f}")
big = SIZE * 10                                 # a district of 30 schools
t30 = [moments(d[1], big, d[2])[0] for d in (district(big) for _ in range(2000))]
print(f"30 schools x 2000: tau^2 estimate mean {avg(t30):.2f}, sd {sd(t30):.2f}")
# what breaks
cov = [wj * T2 * vmu for wj in w]               # Cov(overall mean, b_j)
pool = [vmu + T2 - 2 * c for c in cov]
print("error var, all at mu " + "".join(f"{v:>9.3f}" for v in pool))
same = [mu + kept(T2, S2, 1) * (m - mu) for m in MEAN]
print(f"one share {kept(T2, S2, 1):.3f} for all " + "".join(f"{v:>9.2f}" for v in same))
print("centred at 77.76     " + "".join(f"{v:>9.2f}" for v in shrink(T2, S2, MEAN, SIZE, ybar)))
print("shares with tau^2 = 12.36 " + " ".join(f"{kept(t2mom, S2, n):.3f}" for n in SIZE))
print("chart, n " + " ".join(str(n) for n in range(2, 41, 2)))
for t in (T2, t2mom):
    print(f"chart, tau^2 {t:.2f} " + " ".join(f"{kept(t, S2, n):.3f}" for n in range(2, 41, 2)))
for lab, m, s in zip("ABC", MEAN, theta):        # bars: gap from the overall mean
    print(f"bars, {lab} raw gap {'#' * round(abs(m - mu) * 4):<24} {m - mu:6.2f}")
    print(f"bars, {lab} kept    {'#' * round(abs(s - mu) * 4):<24} {s - mu:6.2f}")
assert max(abs(a - (h[0] + b)) for a, b in zip(theta, h[1:])) < 1e-9   # two roads agree
assert abs(h[0] - mu) < 1e-9                                           # same overall mean
assert [round(v, 3) for v in lam] == [0.5, 0.862, 0.692]               # the spec's shares
assert abs(rt - t2mom) < 0.05 and abs(rs - msw) < 1.0                  # REML near moments
for j in range(k):                                                     # simulation, 4 SE
    assert abs(raw_se[j] - S2 / SIZE[j]) < 4 * sqrt(2 / reps) * S2 / SIZE[j]
    assert abs(shr_se[j] - pev[j]) < 4 * sqrt(2 / reps) * pev[j]
    assert pev[j] < min(S2 / SIZE[j], pool[j])                          # partial pooling wins
assert abs(avg(t2s) - T2) < 4 * sd(t2s) / sqrt(reps)                   # unbiased on average
assert abs(avg(s2s) - S2) < 4 * sd(s2s) / sqrt(reps)
assert sd(t30) < sd(t2s) / 2                                           # more schools, firmer
print("ALL CHECKS PASS")
