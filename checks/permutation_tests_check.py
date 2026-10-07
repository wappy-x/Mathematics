# Permutation tests -- the check behind the card.  Standard library only.
# A shop's pilot A/B test: 16 visitors, a lottery shows 8 the old product page and 8 the new one.
# Road 1: all 12,870 ways the lottery could have split them.  Road 2: a count of groups of 8 by
# their total, which never lists a split.  Road 3: 20,000 random shuffles from SplitMix64.
# Then the moments of the shuffle law by formula, the t-test, and what breaks.
from math import sqrt, pi, log, cos
from itertools import combinations
from bisect import bisect_left

OLD = [0, 8, 0, 12, 0, 8, 0, 8]             # dollars spent by each visitor on the old page
NEW = [22, 0, 95, 0, 22, 27, 0, 22]         # dollars spent by each visitor on the new page
POOL, N, n = OLD + NEW, 16, 8
TOTAL, EPS, R = sum(POOL), 1e-9, 20000
MASK, state = (1 << 64) - 1, 20260929

def splitmix():                             # SplitMix64: the one source of randomness
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def uniform(): return ((splitmix() >> 11) + 0.5) / 2.0 ** 53
def normal(): return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())   # Box-Muller
def gap(s, total=TOTAL, k=n, m=N - n): return s / k - (total - s) / m          # new mean - old mean

def Phi(x):                                 # standard normal area left of x, by its Taylor series
    term, s, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1
        term *= -x * x * (2 * k - 1) / (2 * k * (2 * k + 1))
        s += term
    return 0.5 + s / sqrt(2 * pi)

G = 0.5 * sqrt(pi)                          # Gamma(7.5) / Gamma(7): t law with 14 degrees of freedom
for j in range(1, 7): G *= (j + 0.5) / j
def t_area(t, steps=2000):                  # area under the t density from 0 to t, Simpson's rule
    f = lambda x: G / sqrt(14 * pi) * (1 + x * x / 14) ** -7.5
    h = t / steps
    return h / 3 * sum((1 if i in (0, steps) else 4 if i % 2 else 2) * f(i * h) for i in range(steps + 1))

def t_stat(s, q):                           # pooled t from the new group's sum s and sum of squares q
    ss = (q - s * s / n) + (SQ - q - (TOTAL - s) ** 2 / (N - n))
    return gap(s) / sqrt(ss / (N - 2) * (1 / n + 1 / (N - n)))

SQ = sum(x * x for x in POOL)
OBS = gap(sum(NEW))
print(f"old page mean {sum(OLD) / n:.2f}, new page mean {sum(NEW) / n:.2f}, observed gap {OBS:.2f}")
sd_o = sqrt(sum((x - sum(OLD) / n) ** 2 for x in OLD) / (n - 1))
sd_n = sqrt(sum((x - sum(NEW) / n) ** 2 for x in NEW) / (n - 1))
print(f"standard error of the gap {sqrt(sd_o ** 2 / n + sd_n ** 2 / n):.2f}")

# Road 1: every split
splits = [(sum(POOL[i] for i in c), sum(POOL[i] ** 2 for i in c)) for c in combinations(range(N), n)]
gaps = [gap(s) for s, _ in splits]
M = len(gaps)
two = sum(abs(g) >= OBS - EPS for g in gaps)
one = sum(g >= OBS - EPS for g in gaps)
strict = sum(abs(g) > OBS + EPS for g in gaps)
print(f"pooled total {TOTAL}; new-page total {sum(NEW)}; old-page total {sum(OLD)}")
print(f"road 1, all {M} splits: {one} at +{OBS:.2f} or more, {two - one} at -{OBS:.2f} or less, p = {two / M:.4f}")

# Road 2: ways[k][s] = number of groups of k visitors whose spending totals s dollars
ways = [[0] * (TOTAL + 1) for _ in range(n + 1)]
ways[0][0] = 1
for x in POOL:
    for k in range(n, 0, -1):
        for s in range(TOTAL - x, -1, -1):
            ways[k][s + x] += ways[k - 1][s]
two_dp = sum(ways[n][s] for s in range(TOTAL + 1) if abs(gap(s)) >= OBS - EPS)
print(f"road 2, groups of 8 counted by total: {sum(ways[n])} groups, {two_dp} as extreme, p = {two_dp / M:.4f}")

# Road 3: random shuffles, Fisher-Yates driven by SplitMix64
hits = 0
for _ in range(R):
    deck = POOL[:]
    for i in range(N - 1, 0, -1):
        j = splitmix() % (i + 1)
        deck[i], deck[j] = deck[j], deck[i]
    hits += abs(gap(sum(deck[:n]))) >= OBS - EPS
ph = hits / R
print(f"road 3, {R} shuffles: {hits} as extreme, p = {ph:.4f}, standard error {sqrt(ph * (1 - ph) / R):.4f}")
print(f"  shuffles with the observed split counted in: (hits + 1) / (R + 1) = {(hits + 1) / (R + 1):.4f}")

# The shuffle law's centre and spread, by enumeration and by formula
mean_g = sum(gaps) / M
var_g = sum((g - mean_g) ** 2 for g in gaps) / M
S2 = (SQ - TOTAL ** 2 / N) / (N - 1)
var_f = S2 * (1 / n + 1 / (N - n))
print(f"shuffle law: mean {mean_g:.4f}, sd by enumeration {sqrt(var_g):.4f}, sd by formula {sqrt(var_f):.4f} from S^2 {S2:.4f} about the mean {TOTAL / N:.4f}")
p_norm = 2 * (1 - Phi(OBS / sqrt(var_f)))
print(f"bell curve laid over the shuffle law: z = {OBS / sqrt(var_f):.4f}, p = {p_norm:.4f}")

# The t-test on the same data, and its real rate of false alarms on this data
t_obs = t_stat(sum(NEW), sum(x * x for x in NEW))
p_t = 1 - 2 * t_area(t_obs)
lo, hi = 0.0, 10.0
for _ in range(60):                         # bisection for the 5% two-sided critical value
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if t_area(mid) < 0.475 else (lo, mid)
t_rej = sum(abs(t_stat(s, q)) >= lo for s, q in splits)
print(f"t-test: t = {t_obs:.4f}, p = {p_t:.4f}; 5% cut-off {lo:.4f}")
absg = sorted(abs(g) for g in gaps)
perm_rej = sum((M - bisect_left(absg, abs(g) - EPS)) / M <= 0.05 for g in gaps)
print(f"false alarms over all {M} splits at 5%: shuffle test {perm_rej} = {perm_rej / M:.4f}, "
      f"t-test {t_rej} = {t_rej / M:.4f}")

# Chart: the shuffle law in bars of $5, centred on multiples of 5; an edge value goes to the inner bar
bars = [0] * 11
for g in gaps:
    k = 0 if abs(g) <= 2.5 + EPS else int((abs(g) - 2.5 - EPS) // 5) + 1
    bars[5 + (k if g > 0 else -k)] += 1
print("chart, gap centre ($) " + " ".join(f"{5 * (i - 5):5d}" for i in range(11)))
print("chart, splits         " + " ".join(f"{b:5d}" for b in bars))

# What breaks
strict_rej = sum((M - bisect_left(absg, abs(g) + EPS)) / M <= 0.05 for g in gaps)   # ties dropped
print(f"wrong: strictly larger only, {strict} splits, p = {strict / M:.4f}; "
      f"as a 5% test it fires on {strict_rej} = {strict_rej / M:.4f}")
print(f"wrong: one side reported as the two-sided answer, p = {one / M:.4f}")
REPS, C4, rej = 2000, list(combinations(range(N), 4)), 0
for _ in range(REPS):                       # equal means, 4 visitors spread 4x, 12 visitors spread 1x
    x = [4.0 * normal() for _ in range(4)] + [normal() for _ in range(12)]
    tot = sum(x)
    o = abs(gap(sum(x[:4]), tot, 4, 12))
    c = sum(abs(gap(x[a] + x[b] + x[e] + x[f], tot, 4, 12)) >= o - EPS for a, b, e, f in C4)
    rej += c / len(C4) <= 0.05
pr = rej / REPS
print(f"wrong: shuffling groups of unequal spread, equal means: rejects {rej} of {REPS} "
      f"= {pr:.4f}, standard error {sqrt(pr * (1 - pr) / REPS):.4f}")

assert two == two_dp and M == sum(ways[n]) == 12870          # enumeration against the sum count
assert abs(ph - two / M) < 4 * sqrt(ph * (1 - ph) / R)       # shuffles within 4 standard errors
assert abs(var_g - var_f) < 1e-9 and abs(mean_g) < 1e-9     # shuffle law's spread by formula
assert perm_rej / M <= 0.05 < strict_rej / M and pr > 0.05 + 4 * sqrt(pr * (1 - pr) / REPS)
assert abs(Phi(1.959963984540054) - 0.975) < 1e-12 and abs(lo - 2.1447866879) < 1e-6  # published tables
print("ALL CHECKS PASS")
