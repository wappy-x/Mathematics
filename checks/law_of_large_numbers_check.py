# Law of large numbers -- the check behind the card; only math is imported.
# A fair die rolled 1,000 times.  Chebyshev promises the average lands within
# 0.1 of 3.5 with chance at least 0.7.  Three roads to that chance: the bound
# from the variance alone, the exact law of the sum of 1,000 dice, and a seeded
# simulation of 4,000 runs of 1,000 rolls.  Then the rate, and what breaks.
import math

FACES, N, EPS, RUNS, CRUNS, SEED = range(1, 7), 1000, 0.1, 4000, 2000, 20260928
M64 = 0xFFFFFFFFFFFFFFFF

def splitmix64(s):                     # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def add_one_die(p):                    # p[t] = chance the sum is n + t; roll once more
    pre = [0.0]
    for q in p:
        pre.append(pre[-1] + q)
    L = len(p)
    return [(pre[min(t + 1, L)] - pre[max(t - 5, 0)]) / 6 for t in range(L + 5)]

def misses(n, s):                      # |s/n - 3.5| >= 0.1, tested in whole numbers
    return 5 * abs(2 * s - 7 * n) >= n

def miss_chance(n, p):                 # exact chance the average misses by 0.1 or more
    lo, hi = max(int(2.4 * n) - 3, 0), min(int(2.6 * n) + 3, len(p) - 1)
    return 1 - sum(p[t] for t in range(lo, hi + 1) if not misses(n, n + t))

def row(label, v):
    print(f"{label:<54} {v:>11.6f}")

mu = sum(FACES) / 6                                  # one roll, by counting its faces
var = sum(x * x for x in FACES) / 6 - mu * mu
bound = var / (N * EPS * EPS)                        # road 1: Chebyshev, variance alone

p, exact, first_ok, last_bad = [1.0], {}, None, 0    # road 2: the exact law of the sum
for n in range(1, 1201):
    p = add_one_die(p)
    exact[n] = miss_chance(n, p)
    if exact[n] <= 0.05:
        first_ok = first_ok or n
    else:
        last_bad = n
    if n == N:
        pN = p
mean_avg = sum((N + t) * q for t, q in enumerate(pN)) / N
var_avg = sum(((N + t) / N - mean_avg) * ((N + t) / N - mean_avg) * q for t, q in enumerate(pN))

state, hits, s1, s2, path = SEED, 0, 0.0, 0.0, []    # road 3: 4,000 runs of 1,000 rolls
for r in range(RUNS):
    total = 0
    for i in range(1, N + 1):
        state, z = splitmix64(state)
        total += z % 6 + 1
        if r == 0 and i in (1, 10, 50, 100, 200, 400, 600, 800, 1000):
            path.append(total / i)
    hits += not misses(N, total)
    s1 += total / N
    s2 += (total / N) * (total / N)
sim_hit = hits / RUNS
sim_se = math.sqrt(sim_hit * (1 - sim_hit) / RUNS)
sim_var = s2 / RUNS - (s1 / RUNS) * (s1 / RUNS)

c_one = c_avg = 0                                    # Cauchy draws: no mean to settle on
for r in range(CRUNS):
    total = 0.0
    for i in range(N):
        state, z = splitmix64(state)
        x = math.tan(math.pi * ((z >> 11) * 2.0 ** -53 - 0.5))
        c_one += i == 0 and abs(x) >= 1
        total += x
    c_avg += abs(total / N) >= 1
c_se = math.sqrt(0.25 / CRUNS)

n95 = (35 * 20 * 100 + 11) // 12                    # 5% miss: n >= 35/12 / (0.05 * 0.01)

row("one roll: mean, by counting the faces", mu)
row("one roll: mean square, by counting the faces", sum(x * x for x in FACES) / 6)
row("one roll: variance, by counting the faces", var)
row("one roll: variance, formula (6^2 - 1)/12", (6 ** 2 - 1) / 12)
row("1 Chebyshev: variance of the average, var/n", var / N)
row("1 Chebyshev: spread of the average", math.sqrt(var / N))
row("1 Chebyshev: miss bound var/(n eps^2)", bound)
row("1 Chebyshev: guaranteed hit, 1 - bound", 1 - bound)
row("2 exact law of the sum: mean of the average", mean_avg)
row("2 exact: variance of the average", var_avg)
row("2 exact: miss chance, |avg - 3.5| >= 0.1", exact[N])
row("2 exact: hit chance", 1 - exact[N])
row("3 simulated, 4,000 runs: hit share", sim_hit)
row("3   its standard error", sim_se)
row("3 simulated: variance of the average", sim_var)
row("3   its standard error", (var / N) * math.sqrt(2 / RUNS))
print("chart, one run's running average at n = 1 10 50 100 200 400 600 800 1000:")
print("chart,", " ".join(f"{a:.3f}" for a in path), "| band 3.40 to 3.60")
print("chart,    n   Chebyshev bound   exact miss")
for n in range(100, 1001, 100):
    print(f"chart, {n:>4}   {min(1.0, var / (n * EPS * EPS)):>15.2f}   {exact[n]:>10.2f}")
for n in (250, 1000, 4000):
    row(f"rate: spread of the average at n = {n}", math.sqrt(var / n))
print(f"95% by Chebyshev: n = {n95}; exact law first reaches miss <= 0.05 at n = {first_ok},"
      f" last above 0.05 at n = {last_bad} (checked to 1,200)")
row(f"Chebyshev bound at n = {n95}", var / (n95 * EPS * EPS))
row(f"Chebyshev bound at n = {n95 - 1}", var / ((n95 - 1) * EPS * EPS))
row(f"exact miss chance at n = {first_ok}", exact[first_ok])
cmiss = [sum(misses(n, n * f) for f in FACES) / 6 for n in range(1, 1201)]  # copies: total is n x roll 1
cvar = sum((N * f / N - mu) * (N * f / N - mu) for f in FACES) / 6          # the copied average's variance
row("broken 1, one roll copied 1,000 times: miss chance", cmiss[N - 1])
row("broken 1: variance of the average", cvar)
row("broken 2, Cauchy: share with |draw| >= 1, n = 1", c_one / CRUNS)
row("broken 2, Cauchy: share with |average| >= 1, n = 1000", c_avg / CRUNS)
row("broken 2:   standard error of each share", c_se)
row("broken 3, variance of the average as var/n^2: 'bound'", var / (N * N * EPS * EPS))
row("broken 3: the exact miss chance it undercuts", exact[N])
for n in (100, 1000, 10000):
    row(f"the sum drifts: spread of S - 3.5n at n = {n}", math.sqrt(n * var))

assert abs(var - (6 ** 2 - 1) / 12) < 1e-12, "counting vs the closed form"
assert abs(mean_avg - mu) < 1e-9, "exact law: mean of the average"
assert abs(var_avg - var / N) < 1e-9, "exact law vs var/n"
assert all(exact[n] <= var / (n * EPS * EPS) for n in range(1, 1201)), "exact under Chebyshev"
assert abs(sim_hit - (1 - exact[N])) < 4 * sim_se, "simulation vs exact law"
assert abs(sim_var - var / N) < 4 * (var / N) * math.sqrt(2 / RUNS), "simulated spread"
assert abs(c_avg / CRUNS - 0.5) < 4 * c_se, "Cauchy averages stay as wild as one draw"
assert var / (n95 * EPS * EPS) <= 0.05 < var / ((n95 - 1) * EPS * EPS), "whole-number n95"
assert min(cmiss) == 1, "copied rolls miss at every n up to 1,200"
assert abs(cvar - var) < 1e-12, "a copied average keeps one roll's variance"
assert var / (N * N * EPS * EPS) < exact[N], "var/n^2 promises less than the truth"
print("ALL CHECKS PASS")
