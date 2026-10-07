# Simple random walk: $1 a round on a fair toss; S_n is the net after n rounds.
# Three roads: the formulas; the exact law of S_n, built from the law one round
# earlier; 20,000 runs from SplitMix64, seed 2026.  Standard library only.
from math import sqrt, pi

N, RUNS, SEED, M64 = 100, 20000, 2026, (1 << 64) - 1

def splitmix(s):                            # SplitMix64: a counter, then a scrambler
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def choose(n, k):                           # road one: C(n, k), multiplied out
    c = 1
    for i in range(1, k + 1):
        c = c * (n - k + i) // i
    return c
def counts(n):                              # road two: c[j] = paths with j wins, height 2j - t;
    c, zeros = [1], {}                      # each count comes from the round before
    for t in range(1, n + 1):
        c = [(c[j - 1] if j > 0 else 0) + (c[j] if j < t else 0) for j in range(t + 1)]
        if t % 2 == 0: zeros[t] = c[t // 2]     # paths standing at 0 after round t
    return c, zeros
def law(n, p, keep=()):                     # the same recursion, weighted p and 1 - p
    w, out = [1.0], {}
    for t in range(1, n + 1):
        w = [(w[j - 1] * p if j > 0 else 0.0) + (w[j] * (1 - p) if j < t else 0.0) for j in range(t + 1)]
        if t in keep: out[t] = w
    return w, out
def moments(w, t):                          # mean and variance of the height 2j - t
    m = sum(x * (2 * j - t) for j, x in enumerate(w))
    return m, sum(x * (2 * j - t - m) ** 2 for j, x in enumerate(w))
def persistent(n, r):                       # each step repeats the last with chance r
    w = [[0.0, 0.0] for _ in range(2 * n + 1)]          # w[h + n][d]: height h, last step d
    w[n + 1][1], w[n - 1][0] = 0.5, 0.5
    for _ in range(n - 1):
        new = [[0.0, 0.0] for _ in range(2 * n + 1)]
        for i in range(1, 2 * n):
            new[i + 1][1] += w[i][1] * r + w[i][0] * (1 - r)
            new[i - 1][0] += w[i][0] * r + w[i][1] * (1 - r)
        w = new
    m = sum((i - n) * (w[i][0] + w[i][1]) for i in range(2 * n + 1))
    return sum((i - n - m) ** 2 * (w[i][0] + w[i][1]) for i in range(2 * n + 1))
def row(label, x, se=None):
    print(f"{label:<46}{x:>11.4f}" + ("" if se is None else f"   se {se:.4f}"))
def mean_se(xs):
    m = sum(xs) / len(xs)
    return m, sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))
# ---- road three: 20,000 runs of 100 rounds, a win when the top bit is 1
s, S50, S100, visits, path = SEED, [], [], [], [0]
for run in range(RUNS):
    h = v = 0
    for t in range(1, N + 1):
        s, z = splitmix(s)
        h += 1 if z >> 63 else -1
        v += h == 0
        if t == 50: S50.append(h)
        if run == 0 and t % 5 == 0: path.append(h)
    S100.append(h); visits.append(v)
tot, (c, zeros) = 2 ** N, counts(N)
hts = [2 * j - N for j in range(N + 1)]
s1 = sum(k * x for k, x in zip(hts, c))
s2 = sum(k * k * x for k, x in zip(hts, c))
assert all(x == choose(N, j) for j, x in enumerate(c)), "recursion disagrees with C(n, k)"
assert s1 == 0, "exact law disagrees with mean 0"
assert s2 == N * tot, "exact law disagrees with variance n"
print("== fair game, $1 a round, 100 rounds ==")
row("mean, formula n(2p - 1)", N * (2 * 0.5 - 1))
row("mean, exact law", s1 / tot)
sm, sm_se = mean_se(S100)
row("mean, simulated 20000 runs", sm, sm_se)
row("variance, formula 4np(1 - p)", 4 * N * 0.5 * 0.5)
row("variance, exact law", s2 / tot - (s1 / tot) ** 2)
sv = sum((x - sm) ** 2 for x in S100) / (RUNS - 1)
m4 = sum((x - sm) ** 4 for x in S100) / RUNS
row("variance, simulated", sv, sqrt((m4 - sv * sv) / RUNS))
assert abs(sm) < 4 * sm_se, "simulated mean too far from 0"
assert abs(sv - 100) < 4 * sqrt((m4 - sv * sv) / RUNS), "simulated variance too far from 100"
row("P(S_100 = 0), formula C(100,50)/2^100", choose(N, 50) / tot)
row("P(S_100 = 0), exact law", c[50] / tot)
row("P(S_100 = 0), simulated", *mean_se([1.0 if x == 0 else 0.0 for x in S100]))
row("P(S_100 = 0), Stirling 1/sqrt(pi 50)", 1 / sqrt(pi * 50))
within = sum(c[45:56]) / tot
row("P(-10 <= S_100 <= 10), exact law", within)
row("P(-10 <= S_100 <= 10), simulated", *mean_se([1.0 if abs(x) <= 10 else 0.0 for x in S100]))
row("P(S_100 <= -10), exact law", sum(c[:46]) / tot)
row("P(S_100 <= -10), simulated", *mean_se([1.0 if x <= -10 else 0.0 for x in S100]))
print("== spread against rounds, exact law ==")
_, keep = law(1600, 0.5, keep=(25, 100, 400, 1600))
for t in (25, 100, 400, 1600):
    sd = sqrt(moments(keep[t], t)[1])
    assert abs(sd - sqrt(t)) < 1e-9
    row(f"spread after {t} rounds (sqrt {t} = {sqrt(t):.0f})", sd)
print("== shared rounds and returns ==")
c50, _ = counts(50)
h50 = [2 * j - 50 for j in range(51)]
cov = sum(x * y * a * (a + b) for a, x in zip(h50, c50) for b, y in zip(h50, c50))
assert cov == 50 * 4 ** 50, "exact covariance disagrees with min(a, b)"
row("Cov(S_50, S_100), formula min(50, 100)", 50.0)
row("Cov(S_50, S_100), exact law", cov / 4 ** 50)
m50 = sum(S50) / RUNS
cm, cse = mean_se([(a - m50) * (b - sm) for a, b in zip(S50, S100)])
row("Cov(S_50, S_100), simulated", cm * RUNS / (RUNS - 1), cse)
assert abs(cm - 50) < 4 * cse
row("correlation, 50 / sqrt(50 x 100)", 50 / sqrt(50 * 100))
ret_f = 101 * choose(N, 50) - tot           # (2m + 1) C(2m, m)/4^m - 1, times 2^100
ret_e = sum(zeros[t] * 2 ** (N - t) for t in zeros)
assert ret_f == ret_e, "return-count identity fails"
row("visits to 0 in 100 rounds, formula", ret_f / tot)
row("visits to 0 in 100 rounds, exact law", ret_e / tot)
vm, vse = mean_se(visits)
assert abs(vm - ret_f / tot) < 4 * vse
row("visits to 0 in 100 rounds, simulated", vm, vse)
print("== red at roulette, p = 18/37 ==")
p = 18 / 37
rm, rv = moments(law(N, p)[0], N)
assert abs(rm - N * (2 * p - 1)) < 1e-9, "roulette mean: exact law disagrees with formula"
assert abs(rv - 4 * N * p * (1 - p)) < 1e-9, "roulette variance: exact law disagrees with formula"
row("mean after 100, formula", N * (2 * p - 1))
row("mean after 100, exact law", rm)
row("spread after 100, formula", sqrt(4 * N * p * (1 - p)))
row("spread after 100, exact law", sqrt(rv))
row("mean after 10000, 100 blocks of the exact law", 100 * rm)
row("spread after 10000, 100 blocks", sqrt(100 * rv))
print("== what breaks ==")
row("wrong: spreads added, 100 x $1", N * 1.0)
pv = persistent(N, 0.75)
pf = N + 2 * sum((N - k) * 0.5 ** k for k in range(1, N))
assert abs(pv - pf) < 1e-9, "persistent walk: exact law disagrees with the sum"
row("steps repeat w.p. 0.75: variance, exact law", pv)
row("steps repeat w.p. 0.75: variance, formula", pf)
row("steps repeat w.p. 0.75: spread", sqrt(pv))
row("P(|S_100| > 10), exact law", 1 - within)
print("== charts ==")
print("chart, round       " + " ".join(str(5 * i) for i in range(21)))
print("chart, run 1       " + " ".join(str(x) for x in path))
for sg in (1, -1): print(f"chart, {'+-'[sg < 0]}sqrt(n)    " + " ".join(f"{sg * sqrt(5 * i) + 0.0:.2f}" for i in range(21)))
print("chart, height      " + " ".join(str(k) for k in range(-30, 31, 2)))
print("chart, P(S_100=k)  " + " ".join(f"{c[(k + N) // 2] / tot:.4f}" for k in range(-30, 31, 2)))
print("ALL CHECKS PASS")
