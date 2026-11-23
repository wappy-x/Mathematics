# Erdos problems, three selected -- the check behind the card.  Nothing is
# imported but math.log.  It reads the database's quoted tallies, then works
# the small and million-point cases of distinct distances, unit distances
# and sunflowers, each by two roads.
from math import log

def c(x): return f"{x:,}"

# 1. The database, quoted from its data file as of 2026-11-22.
states = [("open", 570), ("proved", 339), ("disproved", 144), ("solved", 104),
          ("falsifiable", 29), ("verifiable", 9), ("decidable", 8),
          ("not disprovable", 9), ("not provable", 5), ("independent", 4)]
total, prized, prized_open = 1221, 114, 48
print("database: " + ", ".join(f"{s} {n}" for s, n in states))
finite = sum(n for s, n in states if s in ("falsifiable", "verifiable", "decidable"))
print(f"states sum to {c(sum(n for _, n in states))} of {c(total)}; a finite computation could settle {finite}")
axioms = sum(n for s, n in states if s in ("not disprovable", "not provable", "independent"))
print(f"tied to the axioms: {axioms}; with a prize: {prized}, of them open {prized_open}; statements in Lean: 1,021")
print("chosen: #89 $500 open, #90 $500 disproved (Lean), #20 $1000 open")

# 2. Distinct distances.  In a k-by-k grid every squared distance is a*a + b*b.
spf = list(range(1_000_001))                 # smallest prime factor, sieved
for p in range(2, 1001):
    if spf[p] == p:
        for q in range(p * p, 1_000_001, p):
            if spf[q] == q: spf[q] = p
primes = [p for p in range(2, 1_000_000) if spf[p] == p]

def two_squares(m):                          # road 2: Fermat's test on the factors
    while m > 1:
        p, e = spf[m], 0
        while m % p == 0: m //= p; e += 1
        if p % 4 == 3 and e % 2: return False
    return True

print(f"primes below 1,000,000: {c(len(primes))}; of them 3 mod 4: {c(sum(p % 4 == 3 for p in primes))}; "
      f"Fermat's test: 45 {'yes' if two_squares(45) else 'no'}, 21 {'yes' if two_squares(21) else 'no'}")

def easy_bound(n):                           # least t with 2t^2 + t >= n - 1
    t = 0
    while 2 * t * t + t < n - 1: t += 1
    return t

for k in (3, 10, 100, 1000):
    n = k * k
    D = {a * a + b * b for a in range(k) for b in range(a, k)} - {0}
    low = sum(1 for m in D if m <= (k - 1) ** 2)
    sieve = sum(1 for m in range(1, (k - 1) ** 2 + 1) if two_squares(m))
    assert low == sieve                      # two roads to the distances below k - 1
    print(f"grid {k}x{k}, n = {c(n)}: distinct distances {c(len(D))}; up to {k - 1}: grid {c(low)}, "
          f"sieve {c(sieve)}")
    if k >= 10:
        ln = log(n)
        print(f"  log n {ln:.4f}; sqrt(log n) {ln ** 0.5:.3f}; easy bound {easy_bound(n)}; n/log n {c(round(n / ln))}; n/sqrt(log n) "
              f"{c(round(n / ln ** 0.5))}")
        print(f"  grid over n/log n {len(D) * ln / n:.3f}; grid over n/sqrt(log n) {len(D) * ln ** 0.5 / n:.3f}")
    if k == 1000: D6 = len(D)
t = easy_bound(10 ** 6)
print(f"easy bound check: 2 x {t}^2 + {t} = {c(2 * t * t + t)}; 2 x {t - 1}^2 + {t - 1} = "
      f"{c(2 * (t - 1) ** 2 + t - 1)}; pairs among 1,000,000 points {c(10 ** 6 * (10 ** 6 - 1) // 2)}")

# 3. Unit distances: the most repeated distance, rescaled to 1.
def pair_counts(k):                          # pairs of grid points at each squared distance
    h = {}
    for dx in range(k):
        for dy in range(-k + 1, k):
            if dx > 0 or dy > 0:
                m = dx * dx + dy * dy
                h[m] = h.get(m, 0) + (k - dx) * (k - abs(dy))
    return h

def brute(pts, norm):                        # road 2: every pair, compared directly
    d = [norm(p, q) for i, p in enumerate(pts) for q in pts[i + 1:]]
    return len(set(d)), max(d.count(m) for m in set(d)), d.count(min(d))

sq = lambda p, q: (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2
tri = lambda p, q: (p[0] - q[0]) ** 2 + (p[0] - q[0]) * (p[1] - q[1]) + (p[1] - q[1]) ** 2
g3 = brute([(x, y) for x in range(3) for y in range(3)], sq)
hexa = brute([(0, 0), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)], tri)
h3 = pair_counts(3)
print(f"3x3 grid: distinct {g3[0]}, unit pairs {g3[2]} (formula {h3[1]}); best known for 9 points: 4 and 18")
print(f"hexagon and centre, 7 points: distinct {hexa[0]}, unit pairs {hexa[2]}; best known for 7: 3 and 12")
h = pair_counts(1000)
best = max(h, key=lambda m: (h[m], -m))
f = [p for p in primes[:20] if best % p == 0]
def r2(m): return 4 * sum((d % 4 == 1) - (d % 4 == 3) for d in range(1, m + 1, 2) if m % d == 0)
small = all(r2(m) == sum(1 for x in range(-45, 46) for y in range(-45, 46) if x * x + y * y == m)
            for m in range(1, 2001))
h2, vec = {}, 0                              # road 2: every step in the full plane, so each pair twice
for x in range(-999, 1000):
    for y in range(-999, 1000):
        m = x * x + y * y
        if m: h2[m] = h2.get(m, 0) + (1000 - abs(x)) * (1000 - abs(y)); vec += m == best
best2 = max(h2, key=lambda m: (h2[m], -m))
print(f"grid 1000x1000: most repeated squared distance {c(best)}, prime factors {f}, {c(h[best])} pairs")
print(f"  lattice vectors of that length: divisor formula {r2(best)}, direct count {vec}")
print(f"  second histogram, full plane of steps: {c(len(h2))} distances, most repeated {c(best2)}, {c(h2[best2] // 2)} pairs")
print(f"  divisor formula against direct count, every m up to 2,000: {'agree' if small else 'differ'}")
print(f"  pairs per point {h[best] / 1e6:.2f}; partners per point {2 * h[best] / 1e6:.2f}; "
      f"exponent log(pairs)/log(n) {log(h[best]) / log(1e6):.4f}")
print(f"  n^(4/3) = {c(round(1e6 ** (4 / 3)))}; "
      f"n^1.014 = {c(round(1e6 ** 1.014))}")

# 4. Sunflowers of 2-sets (edges): three edges, all pairs meeting in one core.
def flower(a, b, d): return a & b == a & d == b & d
def free(fam, e): return all(not flower(a, b, e) for i, a in enumerate(fam) for b in fam[i + 1:])

def brute_force(v):                          # road 1: every family of edges on v points
    E = [frozenset((i, j)) for i in range(v) for j in range(i + 1, v)]
    best, ways = 0, 0
    for mask in range(1 << len(E)):
        fam = [E[i] for i in range(len(E)) if mask >> i & 1]
        if len(fam) >= best and all(free(fam[:i], fam[i]) for i in range(len(fam))):
            best, ways = (len(fam), 1) if len(fam) > best else (best, ways + 1)
    return best, ways

def grow(E, fam, start, ok):                 # road 2: backtrack, pruning at once
    out = len(fam)
    for i in range(start, len(E)):
        if ok(fam, E[i]): out = max(out, grow(E, fam + [E[i]], i + 1, ok))
    return out

E8 = [frozenset((i, j)) for i in range(8) for j in range(i + 1, 8)]
b6 = brute_force(6)
b8 = grow(E8, [], 0, free)
stars = grow(E8, [], 0, lambda fam, e: all(not (a & b & e and flower(a, b, e))
                                           for i, a in enumerate(fam) for b in fam[i + 1:]))
print(f"edges, no 3-petal sunflower: 6 points max {b6[0]} ({b6[1]} families), 8 points max {b8}")
print(f"Erdos-Rado allows up to 2! x 2^2 = {2 * 2 ** 2}; forbidding only stars, 8 points hold {stars}")
print(f"mistakes: ordered pairs {2 * g3[2]}; n/log n read as the truth, {c(D6)} against "
      f"{c(round(1e6 / log(1e6)))}; the 3x3 grid as best, 5 and 12 against 4 and 18")
assert len(primes) == 78498
assert g3 == (5, 12, 12) and h3[1] == 12 and hexa == (3, 12, 12)
assert r2(best) == vec and small and best <= 999 ** 2
assert sum(h3.values()) == 9 * 8 // 2 and sum(h.values()) == 10 ** 6 * (10 ** 6 - 1) // 2
assert h2 == {m: 2 * v for m, v in h.items()}            # the two histograms agree at every distance
assert len(h2) == D6 and best2 == best                   # two roads to 299,230 and to 160,225
assert b6 == (6, 10) and b8 == 6 and stars == 8
print("ALL CHECKS PASS")
