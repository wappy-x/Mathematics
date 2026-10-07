# The probabilistic method -- the check behind the card.  Standard library only;
# math supplies logarithms and square roots, nothing else.  A string-art board
# has 21 nails, every pair joined by a red or a blue thread.  Colour each thread
# by a fair coin; X counts the 6-nail sets whose 15 threads are all one colour.
# E[X] is reached three ways: the formula, an average over every colouring of a
# small board, and a seeded simulation.  Then a deletion certificate, a table of
# bounds, and the office split (a large cut) on 10 staff with 15 clashes.
import math
M64 = (1 << 64) - 1
class SplitMix64:                               # the random numbers, written out here
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
def choose(n, k):                               # falling product over k!, exact
    out = 1
    for i in range(k): out = out * (n - i) // (i + 1)
    return out
def expect(n, k): return choose(n, k) * 2 / 2 ** choose(k, 2)   # road one: the formula
def log_expect(n, k):                           # the same in logarithms, for huge boards
    return math.log(2) * (1 - k * (k - 1) / 2) + sum(math.log(n - i) - math.log(i + 1) for i in range(k))
def colouring(rng, n):                          # adj[c][v]: nails joined to v in colour c
    adj = [[0] * n, [0] * n]
    for i in range(n):
        for j in range(i + 1, n):
            c = rng.next() >> 63
            adj[c][i] |= 1 << j; adj[c][j] |= 1 << i
    return adj
def cliques(adj, k, cand, size=0, found=None, path=()):   # grow one-colour sets nail by nail
    if size == k: found.append(path); return
    while cand:
        v = cand.bit_length() - 1; cand &= ~(1 << v)
        cliques(adj, k, cand & adj[v], size + 1, found, path + (v,))
def bad_sets(adj, n, k):
    found = []
    for c in (0, 1): cliques(adj[c], k, (1 << n) - 1, 0, found)
    return found
def brute_bad(adj, nails, k):                   # road two: test every k-subset directly
    bad = 0
    for s in range(1 << len(nails)):
        if bin(s).count("1") != k: continue
        mask = sum(1 << nails[i] for i in range(len(nails)) if s >> i & 1)
        bad += any(all((adj[c][v] | 1 << v) & mask == mask for v in nails if mask >> v & 1) for c in (0, 1))
    return bad
def every_colouring(n, ks):                     # every colouring of K(n): counts of one-colour k-sets
    pairs = [(i, j) for i in range(n) for j in range(i + 1, n)]
    masks = {k: [sum(1 << e for e, (i, j) in enumerate(pairs) if s >> i & 1 and s >> j & 1)
                 for s in range(1 << n) if bin(s).count("1") == k] for k in ks}
    return [[sum(1 for m in masks[k] if c & m in (0, m)) for c in range(1 << len(pairs))] for k in ks]

N, K, RUNS = 21, 6, 20000
e21 = expect(N, K)
print(f"board: {N} nails, {choose(N, 2)} threads, {choose(N, K)} six-sets, {choose(K, 2)} threads each")
print(f"E[X] = {choose(N, K)} x 2 / 2^{choose(K, 2)} = {e21:.4f}; in logs {math.exp(log_expect(N, K)):.4f}")
x3, x4 = every_colouring(6, (3, 4))             # the small board K(6), all 32768 colourings
print(f"K(6), k = 4, every colouring: average {sum(x4) / len(x4):.5f}, formula {expect(6, 4):.5f}, "
      f"{x4.count(0)} of {len(x4)} have none")
print(f"K(6), k = 3, every colouring: average {sum(x3) / len(x3):.2f}, formula {expect(6, 3):.2f}, fewest {min(x3)}")
rng, tot, tot2, hist, first, top = SplitMix64(2026), 0, 0, [0] * 11, None, 0
for r in range(RUNS):                           # road three: seeded simulation
    adj = colouring(rng, N)
    found = bad_sets(adj, N, K)
    x = len(found); tot += x; tot2 += x * x; hist[min(x, 10)] += 1; top = max(top, x)
    if first is None and x == int(e21): first = (r, adj, found)   # the worst the average allows
mean = tot / RUNS; se = math.sqrt((tot2 / RUNS - mean ** 2) / RUNS)
print(f"simulated, {RUNS} colourings, seed 2026: mean X = {mean:.4f}, standard error {se:.4f}")
print(f"histogram of X (0 to 9, then 10 or more): {hist}")
p0 = hist[0] / RUNS; p3 = sum(hist[:4]) / RUNS
print(f"share with X = 0: {p0:.4f} (se {math.sqrt(p0 * (1 - p0) / RUNS):.4f}); share with X <= 3: {p3:.4f}")
print(f"mistake, independence product (1 - 2^-14)^{choose(N, K)} = {(1 - 2 ** -14) ** choose(N, K):.4f}; largest X seen {top}")
r, adj, found = first
gone = sorted({max(s) for s in found})
left = [v for v in range(N) if v not in gone]
print(f"colouring no. {r + 1} has X = {len(found)}: {[sorted(s) for s in found]}")
print(f"delete nails {gone}: {len(left)} nails left, one-colour six-sets among them by brute force: {brute_bad(adj, left, K)}")
dl = [(n - math.floor(expect(n, K)), n) for n in range(K, 30)]
print(f"n - floor(E[X]) for n = 17 to 23: {[d for d, n in dl if 17 <= n <= 23]}")
def plain(k):                                   # largest n with E[X] < 1, by halving an interval
    lo, hi = k, 2 * k
    while log_expect(hi, k) < 0: hi *= 2
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if log_expect(mid, k) < 0: lo = mid
        else: hi = mid
    return lo
def deletion(k):                                # max of n - floor(E[X]); E grows faster, so one peak
    lo, hi = k, 2 * k
    while math.exp(log_expect(hi + 1, k)) - math.exp(log_expect(hi, k)) < 1: hi *= 2
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if math.exp(log_expect(mid + 1, k)) - math.exp(log_expect(mid, k)) < 1: lo = mid
        else: hi = mid
    return max(n - math.floor(math.exp(log_expect(n, k))) for n in range(max(k, lo - 3), lo + 4))
print("k, plain (E < 1), deletion, deletion / plain, plain / (k 2^(k/2)), deletion / (k 2^(k/2)):")
table = []
for k in (6, 8, 10, 12, 16, 20, 30, 40):
    p, d = plain(k), deletion(k); s = k * 2 ** (k / 2); table.append((k, p, d))
    print(f"  {k:>2} {p:>9} {d:>9}   {d / p:.4f}   {p / s:.4f}   {d / s:.4f}")
print(f"limits: 1/(e sqrt 2) = {1 / (math.e * math.sqrt(2)):.4f}, 1/e = {1 / math.e:.4f}, sqrt 2 = {math.sqrt(2):.4f}")
# the office split: 10 staff, 15 clashing pairs (the Petersen graph), two rooms
EDGES = [(i, (i + 1) % 5) for i in range(5)] + [(i, i + 5) for i in range(5)] + [(5 + i, 5 + (i + 2) % 5) for i in range(5)]
cut = [sum(1 for a, b in EDGES if (s >> a ^ s >> b) & 1) for s in range(1 << 10)]
dist = [cut.count(c) for c in range(16)]
print(f"office: 10 staff, {len(EDGES)} clashes, formula E[cut] = {len(EDGES) / 2:.2f}")
print(f"every one of 1024 splits: average {sum(cut) / 1024:.2f}, best {max(cut)}, worst {min(cut)}")
print(f"splits separating c clashes, c = 0 to 15: {dist}")
print(f"splits at 8 or more: {sum(dist[8:])}; below the average: {sum(dist[:8])}")
rng2, t, t2, R2 = SplitMix64(7), 0, 0, 100000
for _ in range(R2):
    s = rng2.next() >> 54                      # ten fair coins, one per person
    c = sum(1 for a, b in EDGES if (s >> a ^ s >> b) & 1); t += c; t2 += c * c
m2 = t / R2; se2 = math.sqrt((t2 / R2 - m2 ** 2) / R2)
print(f"simulated, {R2} random splits, seed 7: mean {m2:.4f}, standard error {se2:.4f}")
assert abs(math.exp(log_expect(N, K)) - e21) < 1e-9
assert abs(sum(x4) / len(x4) - expect(6, 4)) < 1e-12 and abs(sum(x3) / len(x3) - expect(6, 3)) < 1e-12
assert abs(mean - e21) < 4 * se and abs(m2 - len(EDGES) / 2) < 4 * se2
assert len(left) >= 18 and brute_bad(adj, left, K) == 0
assert min(x3) > 0 and x4.count(0) > 0 and max(cut) >= 8 and sum(cut) * 2 == len(EDGES) * 1024
assert [p for k, p, d in table if k == 10] == [100] and all(d > p for k, p, d in table if k >= 8)
print("ALL CHECKS PASS")
