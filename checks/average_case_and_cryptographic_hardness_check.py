# Average-case hardness -- the check behind the card.  Standard library only.
# Three parts: a rota search that is easy on average though its problem is
# NP-complete; random 2048-bit numbers, most of which split at once; and a
# discrete-log solver that is right on 1% of inputs, turned into one that is
# right on all of them.  Costs are counted steps, never a stopwatch.
from math import log, exp, sqrt, factorial

M64 = (1 << 64) - 1
state = 20261119                                  # SplitMix64, seed stated here
def rng():
    global state
    state = z = (state + 0x9E3779B97F4A7C15) & M64
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

# ---- part 1: the rota.  n staff, 3 shifts; a clash list says who may not share a shift ----
def formula(n, q):          # average search nodes: sum over partial rotas of Pr[no clash inside]
    total = 0.0
    for a in range(n + 1):
        for b in range(n + 1 - a):
            for c in range(n + 1 - a - b):
                ways = factorial(a + b + c) / (factorial(a) * factorial(b) * factorial(c))
                total += ways * (1.0 - q) ** (a * (a - 1) // 2 + b * (b - 1) // 2 + c * (c - 1) // 2)
    return total
def pairs(n):
    return [(i, j) for i in range(n) for j in range(i + 1, n)]
def search_nodes(n, clash):    # backtracking that lists every clash-free rota; counts nodes visited
    shift = [0] * n
    def go(k):
        nodes = 1
        for s in range(3 if k < n else 0):
            if all(not ((j, k) in clash and shift[j] == s) for j in range(k)):
                shift[k] = s
                nodes += go(k + 1)
        return nodes
    return go(0)

exhaustive = sum(search_nodes(5, {pr for b, pr in enumerate(pairs(5)) if mask >> b & 1})
                 for mask in range(1 << 10)) / (1 << 10)          # every clash list on 5 staff
runs = [search_nodes(30, {pr for pr in pairs(30) if rng() % 2 == 1}) for _ in range(2000)]
sim = sum(runs) / len(runs)
sd = sqrt(sum((x - sim) ** 2 for x in runs) / (len(runs) - 1))
print("part 1: the rota, 3 shifts, each pair of staff clashing with chance 0.5")
for n in (5, 10, 20, 30, 60):
    print(f"  staff {n:>2}: average search nodes {formula(n, 0.5):12.4f}   every rota tried 3^n = {3 ** n}")
print(f"  staff  5, all 1024 clash lists searched: average {exhaustive:.4f}")
print(f"  staff 30, 2000 random clash lists searched: average {sim:.2f}, largest {max(runs)}, sd {sd:.2f}")
print("  chart, staff:            " + " ".join(f"{n:>6}" for n in (5, 10, 20, 30, 40, 60)))
print("  chart, log10 of 3^n:     " + " ".join(f"{n * log(3) / log(10):6.2f}" for n in (5, 10, 20, 30, 40, 60)))
print("  chart, log10 of average: " + " ".join(f"{log(formula(n, 0.5)) / log(10):6.2f}" for n in (5, 10, 20, 30, 40, 60)))
sparse, falling = [formula(n, 0.1) for n in (30, 80, 120)], [formula(n, 4 / n) for n in (20, 40, 60)]
print("  break: clash chance 0.1, staff 30, 80, 120: average search nodes " + ", ".join(f"{x:.0f}" for x in sparse))
print("  break: clash chance 4/n, staff 20, 40, 60: average search nodes " + ", ".join(f"{x:.0f}" for x in falling))

# ---- part 2: factoring.  A random 2048-bit number against a product of two 1024-bit primes ----
LIMIT = 1000000
sieve = bytearray([1]) * LIMIT
sieve[0] = sieve[1] = 0
for i in range(2, 1001):
    if sieve[i]:
        for j in range(i * i, LIMIT, i):
            sieve[j] = 0
primes = [i for i in range(LIMIT) if sieve[i]]
GAMMA = 0.5772156649015329                        # Euler's constant, for Mertens' theorem
print("part 2: share of random numbers with a prime factor below B")
bars = {}
for b in (10, 100, 1000, 10000, 100000, 1000000):
    keep = 1.0                                    # share with no prime factor below b
    for p in primes:
        if p >= b:
            break
        keep *= 1.0 - 1.0 / p
    bars[b] = 1.0 - keep
for b in sorted(bars):
    print(f"  B = {b:>7}: by the product {100 * bars[b]:6.2f}%   by Mertens {100 * (1 - exp(-GAMMA) / log(b)):6.2f}%")
small = [p for p in primes if p < 10000]
hit, divisions = 0, 0
for _ in range(2000):
    limbs = [rng() for _ in range(32)]
    limbs[31] |= 1 << 63                          # top bit set: exactly 2048 bits
    N = sum(limb << (64 * i) for i, limb in enumerate(limbs))
    for p in small:
        divisions += 1
        if N % p == 0:
            hit += 1
            break
share = hit / 2000
se = sqrt(bars[10000] * (1 - bars[10000]) / 2000)
print(f"  2000 random 2048-bit numbers, {len(small)} trial divisions at most: {hit} split, {100 * share:.2f}%, "
      f"{divisions / 2000:.1f} divisions each on average")
print(f"  RSA product of two 1024-bit primes: smallest factor above 2^1023; primes below 2^1024 about 10^{1024 * log(2) / log(10) - log(1024 * log(2)) / log(10):.1f}")
lnN = 2048 * log(2)
print(f"  number field sieve, leading term for 2048 bits: about 2^{(64 / 9) ** (1 / 3) * lnN ** (1 / 3) * log(lnN) ** (2 / 3) / log(2):.1f}")
pp = 1 / (1024 * log(2))
print(f"  weak one-way: a random 1024-bit number is prime with chance about {pp:.6f}; both of two: 1 in {1 / pp ** 2:.0f}")

# ---- part 3: discrete log on the clock of 1,009, base 11 (from One-way streets) ----
P, G, ORD = 1009, 11, 1008
def power(a, k):                                  # square and multiply, written out
    out = 1
    while k:
        out, a, k = (out * a % P if k & 1 else out), a * a % P, k >> 1
    return out
walk, v = {}, 1                                   # road one: walk every power, the slow way
for k in range(ORD):
    walk[v] = k
    v = v * G % P
oracle = {}                                       # a solver that knows only 10 of the 1,008 answers
while len(oracle) < 10:
    e = rng() % ORD
    oracle[power(G, e)] = e
def self_reduce(y):                               # road two: shift y to a random spot, ask, shift back
    tries = 0
    while True:
        tries += 1
        r = rng() % ORD
        z = y * power(G, r) % P
        if z in oracle:
            return (oracle[z] - r) % ORD, tries
x956, t956 = self_reduce(956)
results = [self_reduce(y) for y in range(1, P)]
mean = sum(t for _, t in results) / ORD
print("part 3: discrete log on a clock of 1009, base 11; the solver alone knows 10 of 1008")
print(f"  the solver alone answers {len(oracle)} of {ORD} targets: {100 * len(oracle) / ORD:.2f}%")
print(f"  target 956: answer {x956} after {t956} random shifts; 11^{x956} on the clock = {power(G, x956)}")
print(f"  all 1008 targets: {sum(power(G, x) == y for (x, _), y in zip(results, range(1, P)))} verified, "
      f"{sum(walk[y] == x for (x, _), y in zip(results, range(1, P)))} match the walk")
print(f"  shifts per target: average {mean:.2f}, expected 1008 / 10 = {ORD / 10:.2f}")

assert abs(exhaustive - formula(5, 0.5)) < 1e-9                  # brute force over 1,024 lists vs closed form
assert abs(sim - formula(30, 0.5)) < 4 * sd / sqrt(len(runs))       # simulation vs closed form
assert abs(formula(60, 0.5) - 197.0954) < 1e-4 and abs(sparse[2] / sparse[1] - 1) < 1e-9   # levels off at 0.5 and at 0.1
assert falling[2] > 1000 * falling[1] > 10 ** 6 * falling[0]         # a clash chance falling as 4/n: no ceiling
assert abs(share - bars[10000]) < 4 * se                            # random 2048-bit numbers vs the product
assert abs(bars[1000000] - (1 - exp(-GAMMA) / log(1000000))) < 0.001  # product vs Mertens
assert all(power(G, x) == y and walk[y] == x for (x, _), y in zip(results, range(1, P)))
geo_se = sqrt(1 - 10 / ORD) / (10 / ORD) / sqrt(ORD)
assert abs(mean - ORD / 10) < 4 * geo_se and x956 == 613           # self-reduction cost vs geometric law
print("ALL CHECKS PASS")
