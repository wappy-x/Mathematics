# Tail bounds and repeated trials: the check behind the card. Standard library only.
# Roads to each answer: a closed-form bound; an exact count (all 8 random lists, or
# a binomial sum term by term); a seeded SplitMix64 simulation of the real runs.
from math import log, exp, expm1, ceil, floor, log10, log1p

MISS = 0.5          # one-sided check: chance one run misses a wrong product
P_RIGHT = 0.75      # two-sided test: chance one run gives the right answer
DELTA = 1e-6        # failure chance allowed
USES = 10_000_000   # requests a day at the web service
EPS = 0.01          # error allowance on an estimated share
SEED, TRIALS, M64 = 2026, 100_000, (1 << 64) - 1

def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def sci(x):
    e = floor(log10(x)); m = x / 10.0 ** e
    if m >= 9.995: m, e = m / 10, e + 1
    return f"{m:.2f}e{e}"

def mul(X, Y): return [[sum(X[i][t] * Y[t][j] for t in range(3)) for j in range(3)] for i in range(3)]
def mv(X, v): return [sum(X[i][t] * v[t] for t in range(3)) for i in range(3)]
def bits(z): return [(z >> j) & 1 for j in range(3)]

A, B = [[2, 1, 0], [1, 3, 1], [0, 1, 2]], [[1, 2, 1], [0, 1, 3], [2, 0, 1]]
GOOD = mul(A, B)
BAD = [row[:] for row in GOOD]; BAD[1][2] += 1           # one entry off by one
def catches(C, x): return mv(A, mv(B, x)) != mv(C, x)   # Freivalds' check, one run

def tail(k, q):  # exact chance that a majority of k runs (k odd) are wrong, each wrong with chance q
    pmf = 1.0
    for _ in range(k): pmf *= 1 - q
    total = 0.0
    for w in range(k + 1):
        if 2 * w > k: total += pmf
        pmf *= (k - w) / (w + 1) * q / (1 - q)
    return total

def tail_dp(k, q):  # second road: the law of the wrong count, built up one run at a time
    dist = [1.0]
    for _ in range(k): dist = [a * (1 - q) + b * q for a, b in zip(dist + [0.0], [0.0] + dist)]
    return sum(dist[(k + 1) // 2:])
def kl(a, b): return a * log(a / b) + (1 - a) * log((1 - a) / (1 - b))
def runs_formula(n_uses, delta, rate): return ceil(log(n_uses / delta) / rate)
def runs_exact(q, target):
    k = 1
    while tail(k, q) > target: k += 2
    return k
def runs_one_sided(miss, target):          # brute force: double the doubt down run by run
    k, left = 0, 1.0
    while left > target: k, left = k + 1, left * miss
    return k

# ---- one-sided: the check itself, every random list, and the cost ----
caught = sum(catches(BAD, bits(v)) for v in range(8))
false_alarm = sum(catches(GOOD, bits(v)) for v in range(8))
print(f"wrong product caught by {caught} of 8 lists; right product flagged by {false_alarm} of 8")
size = 1000
rate1 = log(1 / MISS)
for k in (1, 2, 10, 20, 44):
    print(f"one-sided, {k:2d} runs: miss chance {sci(MISS ** k)}, about 1 in {round(MISS ** -k):,}")
k1, kday = runs_formula(1, DELTA, rate1), runs_formula(USES, DELTA, rate1)
print(f"one-sided runs for 1 in a million: per request {log(1 / DELTA):.2f} / {rate1:.4f} = {log(1 / DELTA) / rate1:.2f} -> {k1}, "
      f"whole day {log(USES / DELTA):.2f} / {rate1:.4f} = {log(USES / DELTA) / rate1:.2f} -> {kday}, {kday - k1} more")
print(f"cost on {size}x{size}: one check {3*size*size:,}, redo {size**3:,}; {k1} checks {100 * 3 * k1 / size:.1f}% of a redo, {kday} checks {100 * 3 * kday / size:.1f}%")
print(f"one-sided runs at miss chance 0.25 per run: {runs_formula(1, DELTA, log(4))}")

# ---- seeded simulation of the real check: fresh list each run, then one list reused ----
s, fresh, reused = SEED, 0, 0
for _ in range(TRIALS):
    hit = False
    for _ in range(4):
        s, z = splitmix(s); hit = hit or catches(BAD, bits(z))
    fresh += not hit
    s, z = splitmix(s); reused += not catches(BAD, bits(z))   # same list, 4 times: one answer
print(f"simulated, 4 runs, fresh lists: miss {fresh / TRIALS:.4f} (exact {MISS ** 4:.4f})")
print(f"simulated, 4 runs, one list reused: miss {reused / TRIALS:.4f}")

# ---- two-sided: majority vote, exact against every bound ----
q, gap = 1 - P_RIGHT, P_RIGHT - 0.5
D = kl(0.5, q)
cheb = lambda k: min(1.0, P_RIGHT * q / (k * gap * gap))   # Chebyshev: variance k p q over distance (k eps)^2
print(f"two-sided, right {P_RIGHT} per run: Chernoff rate D = {D:.4f}, Hoeffding rate 2 eps^2 = {2*gap*gap:.4f}")
print(f"Markov on the count of wrong votes: {q / 0.5:.2f} at every number of runs")
print(" runs   exact      Chernoff   Hoeffding  Chebyshev")
for k in (1, 9, 21, 41, 81, 121):
    ex, ch, ho, cb = tail(k, q), exp(-k * D), exp(-2 * k * gap * gap), cheb(k)
    print(f"{k:5d}   {sci(ex):9}  {sci(ch):9}  {sci(ho):9}  {sci(cb)}")
    assert ex <= ch <= ho and ex <= cb and abs(tail_dp(k, q) / ex - 1) < 1e-9   # every bound bounds; two roads agree
kc, kh, ke, kcheb = runs_formula(1, DELTA, D), runs_formula(1, DELTA, 2 * gap * gap), runs_exact(q, DELTA), ceil(P_RIGHT * q / (gap * gap * DELTA))
print(f"runs for 1 in a million: Chebyshev {kcheb:,}, Hoeffding {kh}, Chernoff {kc}, exact {ke}")
print(f"exact at {ke - 2} runs {sci(tail(ke - 2, q))}, at {ke} runs {sci(tail(ke, q))}, at {kc} runs {sci(tail(kc, q))}")
print(f"Chernoff quotients {log(1 / DELTA) / D:.2f} and {log(USES / DELTA) / D:.2f}; whole day: Chernoff {runs_formula(USES, DELTA, D)}, exact {runs_exact(q, DELTA / USES)}")
D3 = kl(0.5, 1 / 3)
print(f"at right 2/3 per run: Chernoff {runs_formula(1, DELTA, D3)}, exact {runs_exact(1 / 3, DELTA)}")

s, wrong = SEED, 0
for _ in range(TRIALS):
    bad_votes = 0
    for _ in range(9):
        s, z = splitmix(s); bad_votes += (z >> 62) == 0          # wrong with chance 1/4
    wrong += bad_votes >= 5
print(f"simulated majority of 9: wrong {wrong / TRIALS:.4f} (exact {tail(9, q):.4f})")

# ---- many uses: the union bound ----
d20 = MISS ** 20
p_any = -expm1(USES * log1p(-d20))             # 1 - (1 - d20)^USES, exactly
print(f"20 runs, {USES:,} requests: union bound {USES * d20:.2f}, chance of at least one miss {p_any:.5f}")
print(f"{kday} runs, {USES:,} requests: union bound {sci(USES * MISS ** kday)}")

# ---- the same recipe for an estimate ----
n_est = ceil(log(2 / DELTA) / (2 * EPS * EPS))
print(f"samples to know a share within {EPS} except 1 in a million: {n_est:,}; at eps 0.001: {ceil(log(2 / DELTA) / 2e-6):,}")

# ---- what breaks ----
print(f"what breaks: any-alarm rule on the two-sided test, 20 runs: false alarm {1 - P_RIGHT ** 20:.4f}")
print(f"what breaks: no margin, right 0.5 per run, majority of 101: wrong {tail(101, 0.5):.4f}")

# ---- chart: digits of safety, -log10 of the failure chance ----
ks = [1, 21, 41, 61, 81, 101, 121]
print("figure,runs," + ",".join(str(k) for k in ks))
print("figure,one-sided," + ",".join(f"{k * log10(1 / MISS):.2f}" for k in ks))
print("figure,majority exact," + ",".join(f"{-log10(tail(k, q)):.2f}" for k in ks))
print("figure,majority Chernoff," + ",".join(f"{k * D / log(10):.2f}" for k in ks))
print("figure,majority Chebyshev," + ",".join(f"{log10(1 / cheb(k)):.2f}" for k in ks))

assert caught == 4 and false_alarm == 0 and 1 - caught / 8 == MISS    # exhaustive count = stated rate
assert k1 == runs_one_sided(MISS, DELTA) and kday == runs_one_sided(MISS, DELTA / USES)
assert abs(fresh / TRIALS - MISS ** 4) < 4 * (MISS ** 4 * (1 - MISS ** 4) / TRIALS) ** 0.5
assert abs(reused / TRIALS - MISS) < 4 * (0.25 / TRIALS) ** 0.5
assert abs(wrong / TRIALS - tail(9, q)) < 4 * (tail(9, q) * (1 - tail(9, q)) / TRIALS) ** 0.5
assert tail(kc, q) <= DELTA and tail_dp(ke, q) <= DELTA < tail_dp(ke - 2, q) and ke < kc < kh
assert kcheb == round(3 / DELTA) and all(abs(cheb(k) - 3 / k) < 1e-12 for k in ks[1:])   # Chebyshev is 3/k
assert abs(p_any - (1 - exp(-USES * d20))) < 1e-9 and USES * MISS ** kday <= DELTA      # against the Poisson form
assert 2 * exp(-2 * n_est * EPS * EPS) <= DELTA < 2 * exp(-2 * (n_est - 1) * EPS * EPS)
assert abs(tail(101, 0.5) - 0.5) < 1e-12                                 # symmetry: a fair vote
print("ALL CHECKS PASS")
