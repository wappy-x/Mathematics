# Randomised quicksort on an already-sorted log: the check behind the card.
# Standard library only.  No random, no sorted: the generator (SplitMix64) and
# the sort are written out, and the sort counts its own comparisons.
from math import log, log2, sqrt
M64 = (1 << 64) - 1

class SplitMix64:                               # a counter, then a scrambler
    def __init__(self, seed): self.s = seed
    def below(self, m):                         # a whole number from 0 to m - 1
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (z ^ (z >> 31)) % m

def quicksort(a, rng=None, seen=None):          # rng None: first element is the pivot
    comps, stack = 0, [(0, len(a) - 1)]
    while stack:
        lo, hi = stack.pop()
        if lo >= hi: continue
        if rng is not None:                     # the coin flip: a pivot position, uniform
            p = lo + rng.below(hi - lo + 1)
            a[lo], a[p] = a[p], a[lo]
        piv, s = a[lo], lo
        for j in range(lo + 1, hi + 1):
            comps += 1                          # one comparison: a[j] against the pivot
            if seen is not None: seen[min(piv, a[j]), max(piv, a[j])] += 1
            if a[j] < piv:
                s += 1
                a[s], a[j] = a[j], a[s]
        a[lo], a[s] = a[s], a[lo]
        stack += [(lo, s - 1), (s + 1, hi)]
    return comps

def is_sorted(a): return all(a[i] <= a[i + 1] for i in range(len(a) - 1))
def H(n): return sum(1.0 / k for k in range(1, n + 1))          # 1 + 1/2 + ... + 1/n
def formula(n): return 2 * (n + 1) * H(n) - 4 * n
def pair_sum(n, top=2):                         # road 2: one indicator per pair of ranks i < j
    return sum(top / (j - i + 1) for i in range(1, n + 1) for j in range(i + 1, n + 1))
def recurrence(n):                              # road 3: C(m) = m - 1 + (2/m)(C(0) + ... + C(m-1))
    c, run = [0.0], 0.0
    for m in range(1, n + 1):
        run += c[-1]
        c.append(m - 1 + 2.0 * run / m)
    return c[n]
def perms(xs):
    if not xs: yield []
    for i in range(len(xs)):
        for rest in perms(xs[:i] + xs[i + 1:]): yield [xs[i]] + rest
def sim(n, runs, rng):                          # road 4: seeded runs on the sorted log, counted
    counts = []
    for _ in range(runs):
        a = list(range(1, n + 1))
        counts.append(quicksort(a, rng))
        assert is_sorted(a), "Las Vegas: every run must come out sorted"
    mean = sum(counts) / runs
    se = sqrt(sum((c - mean) * (c - mean) for c in counts) / (runs - 1) / runs)
    return counts, mean, se
def spot_check(log_, k, rng):                   # Monte Carlo: k random adjacent pairs, fixed cost
    for _ in range(k):
        i = rng.below(len(log_) - 1)
        if log_[i] > log_[i + 1]: return "out of order"
    return "looks sorted"

# ---- road 1 against exhaustion: n = 8, all 40320 orders, first-element pivot ----
seen, total, orders = {(i, j): 0 for i in range(1, 9) for j in range(i + 1, 9)}, 0, 0
for p in perms(list(range(1, 9))):
    total += quicksort(p, None, seen); orders += 1
fact = 40320
exact = 2 * 9 * sum(fact // k for k in range(1, 9)) - 4 * 8 * fact   # 8! (2(n+1)H_n - 4n), in whole numbers
print(f"n=8 orders {orders}, comparisons over all orders {total}, formula times 8! {exact}")
print(f"n=8 expected {total / orders:.6f}, formula {formula(8):.6f}, sorted order first pivot {quicksort(list(range(1, 9)))}")
print(f"n=8 orders comparing ranks 1&8 {seen[1, 8]}, 3&5 {seen[3, 5]}, 4&5 {seen[4, 5]}")

# ---- the sorted log, n = 1000 ----
n, rng = 1000, SplitMix64(20261111)
E, first = formula(n), quicksort(list(range(1, n + 1)))
counts, mean, se = sim(n, 400, rng)
above = sum(c > E for c in counts)
print(f"n=1000 H_n {H(n):.4f}, formula {E:.4f}, pair sum {pair_sum(n):.4f}, recurrence {recurrence(n):.4f}")
print(f"n=1000 first pivot counted {first}, n(n-1)/2 {n * (n - 1) // 2}")
print(f"n=1000 random pivot 400 runs: mean {mean:.1f}, se {se:.1f}, min {min(counts)}, max {max(counts)}, above E {above}")
eq = [7] * n
print(f"wrong: 1/(gap+1) {pair_sum(n, 1):.1f}; 2n log2 n {2 * n * log2(n):.1f}; 2n ln n {2 * n * log(n):.1f}; "
      f"all-equal keys counted {quicksort(eq, rng)}")
for m in (250, 500, 1000, 2000):                # growth, counted at several sizes
    _, mm, ms = sim(m, 100, rng)
    print(f"growth n={m} formula {formula(m):.1f} simulated {mm:.1f} se {ms:.1f} first pivot {m * (m - 1) // 2}")

# ---- the house example: a day of 10,000,000 requests ----
N = 10_000_000
EN = formula(N)
print(f"n=10^7 H_n {H(N):.4f}, random pivot expected {EN:.0f}, first pivot {N * (N - 1) // 2}, ratio {N * (N - 1) / 2 / EN:.0f}")
print(f"try: n=10^8 expected {formula(10 * N):.0f}, growth {formula(10 * N) / EN:.2f} times")

# ---- Monte Carlo: spot-check a log for order, k = 60 checks ----
glitch = list(range(1, n + 1))
for p in range(10, 1000, 20): glitch[p], glitch[p + 1] = glitch[p + 1], glitch[p]
bad = sum(glitch[i] > glitch[i + 1] for i in range(n - 1))
trials, k = 20000, 60
miss_f = (1 - bad / (n - 1)) ** k
miss = sum(spot_check(glitch, k, rng) == "looks sorted" for _ in range(trials)) / trials
miss_se = sqrt(miss_f * (1 - miss_f) / trials)
wrong_on_sorted = sum(spot_check(list(range(1, n + 1)), k, rng) == "out of order" for _ in range(1000))
print(f"spot check: bad pairs {bad} of {n - 1}, k {k}, miss formula {miss_f:.4f}, simulated {miss:.4f}, se {miss_se:.4f}")
print(f"spot check: one bad pair miss {(1 - 1 / (n - 1)) ** k:.4f}; sorted log called out of order {wrong_on_sorted} of 1000")
print(f"try: k=120 miss {(1 - bad / (n - 1)) ** 120:.4f}")

assert total == exact, "exhaustive count over all 8! orders must equal the closed form"
assert seen[1, 8] == fact * 2 // 8 and seen[3, 5] == fact * 2 // 3, "pair chance 2/(j-i+1)"
assert abs(pair_sum(n) - E) < 1e-6, "pair-by-pair indicator sum equals the closed form"
assert abs(recurrence(n) - E) < 1e-6, "recurrence equals the closed form"
assert first == n * (n - 1) // 2, "first pivot on sorted input: every pair compared"
assert abs(mean - E) < 4 * se, "simulated mean within 4 standard errors of the formula"
assert abs(miss - miss_f) < 4 * miss_se, "Monte Carlo miss rate within 4 standard errors"
assert wrong_on_sorted == 0, "one-sided: a sorted log is never called out of order"
print("ALL CHECKS PASS")
