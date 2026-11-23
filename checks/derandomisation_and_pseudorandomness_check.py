# Pseudorandomness and derandomisation -- the check behind the card.  Standard
# library only.  Twelve staff split into an early and a late shift; 20 cover
# pairs should land on different shifts.  Coin i puts staff member i on lates.
STAFF, MASK = 12, (1 << 64) - 1
PAIRS = [(i, i % 12 + 1) for i in range(1, 13)] + [(i, i + 6) for i in range(1, 7)] + [(1, 4), (7, 10)]

def coin(x, i):                          # coin i of a 12-coin string x, 0 or 1
    return (x >> (i - 1)) & 1

def separated(x):                        # cover pairs split across the two shifts
    return sum(coin(x, a) ^ coin(x, b) for a, b in PAIRS)

def parity(v):                           # 1 if v has an odd number of 1 bits
    p = 0
    while v:
        p ^= v & 1
        v >>= 1
    return p

def fake(seed):                          # the generator: coin i = parity of (seed AND i)
    return sum(parity(seed & i) << (i - 1) for i in range(1, STAFF + 1))

def late(x):
    return [i for i in range(1, STAFF + 1) if coin(x, i)]

class SplitMix64:                        # small seeded generator, written out
    def __init__(self, seed):
        self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

ALL = 1 << STAFF
scores = [separated(x) for x in range(ALL)]
bad = [s < 10 for s in scores]           # a split fails if it keeps fewer than 10 apart
mu = sum(bad) / ALL
print(f"rota: {STAFF} staff, {len(PAIRS)} cover pairs, goal at least 10 pairs on different shifts")
print(f"real coins: {ALL} strings, average kept apart {sum(scores) / ALL:.4f}, best {max(scores)}")
print(f"real coins: {sum(bad)} of {ALL} strings miss the goal, share {mu:.5f}")
print(f"by pairs: each pair split with chance 0.5, so {len(PAIRS)} x 0.5 = {len(PAIRS) * 0.5:.4f}")
fs = [separated(fake(s)) for s in range(16)]
best = max(range(16), key=lambda s: fs[s])
print(f"fake coins, kept apart for seeds 0 to 15: {fs}")
print(f"fake coins: average {sum(fs) / 16:.4f}; best seed {best}, late shift {late(fake(best))}, kept apart {fs[best]}")
groups = [sum(coin(fake(best), a) ^ coin(fake(best), b) for a, b in g) for g in (PAIRS[:12], PAIRS[12:18], PAIRS[18:])]
print(f"seed {best} by group: ring of 12 {groups[0]}, six across {groups[1]}, two extra {groups[2]}")
counts = {(i, j): [0, 0, 0, 0] for i in range(1, 13) for j in range(i + 1, 13)}
for s in range(16):
    for (i, j), c in counts.items():
        c[2 * coin(fake(s), i) + coin(fake(s), j)] += 1
even = all(c == [4, 4, 4, 4] for c in counts.values())
print(f"every one of {len(counts)} coin pairs shows 00, 01, 10, 11 four times each in 16 seeds: {'yes' if even else 'no'}")
gap2 = max(abs(c[k] / 16 - 0.25) for c in counts.values() for k in range(4))
print(f"largest gap on any two-coin pattern, fake against real: {gap2:.4f}")
pf = sum(parity(fake(s) & 7) == 0 for s in range(16)) / 16
pr = sum(parity(x & 7) == 0 for x in range(ALL)) / ALL
print(f"three-coin test, staff 1, 2, 3 put an even number on lates: fake {pf:.4f}, real {pr:.4f}, gap {pf - pr:.4f}")
miss = sum(f < 10 for f in fs)                 # the yes-or-no goal test reads all 12 coins
print(f"goal test, at least 10 apart: fake coins miss on {miss} of 16 seeds, share {miss / 16:.5f}; real coins {mu:.5f}")
night, stored = fake(13), format(13, "04b")    # last night's seed, kept as 4 bits of text
again = [i for i in range(1, STAFF + 1) if sum(int(stored[3 - k]) * ((i >> k) & 1) for k in range(4)) % 2]
print(f"last night, seed 13: late shift {late(night)}, kept apart {separated(night)}; replayed from stored bits {stored}: {'same' if again == late(night) else 'different'}")
for n in (12, 100, 1000):
    s = (n).bit_length()
    print(f"cost, {n} coins: try every coin string 2^{n}; try every seed {s} bits, {1 << s} runs")
rng = SplitMix64(1)
GENS = [rng.next() >> 52 for _ in range(64)]   # 64 fixed 12-bit steps: 6 random bits per step
lams = [(abs(sum(1 - 2 * parity(a & g) for g in GENS)) / 64, a) for a in range(1, ALL)]
lam, worst = max(lams)
chi = [1 - 2 * parity(worst & x) for x in range(ALL)]
walked = [sum(chi[x ^ g] for g in GENS) / 64 for x in range(ALL)]
sign = 1 if sum(1 - 2 * parity(worst & g) for g in GENS) > 0 else -1
eig = all(abs(walked[x] - sign * lam * chi[x]) < 1e-12 for x in range(ALL))
print(f"walk graph: {ALL} coin strings, 64 steps each, second eigenvalue {lam:.4f} (pattern {worst}); eigenvector check: {'yes' if eig else 'no'}")
dist = [1 / ALL if bad[x] else 0.0 for x in range(ALL)]
walk = [sum(dist)]
for k in range(2, 9):
    new = [0.0] * ALL
    for x in range(ALL):
        if dist[x]:
            for g in GENS:
                new[x ^ g] += dist[x] / 64
    dist = [new[x] if bad[x] else 0.0 for x in range(ALL)]
    walk.append(sum(dist))
print("tries | bits, fresh | bits, walk | all fail, fresh | all fail, walk | bound mu(mu+lam)^(k-1)")
bounds = []
for k in range(1, 9):
    bounds.append(mu * (mu + lam) ** (k - 1))
    print(f"{k} | {12 * k} | {12 + 6 * (k - 1)} | {mu ** k:.6f} | {walk[k - 1]:.6f} | {bounds[-1]:.6f}")
sim, hits, runs = SplitMix64(2026), 0, 20000
for _ in range(runs):
    x = sim.next() >> 52
    fails = bad[x]
    for _ in range(3):
        x ^= GENS[sim.next() >> 58]
        fails = fails and bad[x]
    hits += fails
se = (walk[3] * (1 - walk[3]) / runs) ** 0.5
print(f"simulated walks of 4 tries: {hits} of {runs} all fail, share {hits / runs:.5f}, exact {walk[3]:.5f}, standard error {se:.5f}")
print(f"mistake, seed 0 alone: late shift {late(fake(0))}, kept apart {fs[0]}")
print(f"mistake, one coin string reused 4 times: all fail with chance {mu:.6f}, not {mu ** 4:.6f}")
print("figure, all fail, fresh: " + ", ".join(f"{mu ** k:.4f}" for k in range(1, 9)))
print("figure, all fail, walk: " + ", ".join(f"{w:.4f}" for w in walk))
print("figure, bound: " + ", ".join(f"{b:.4f}" for b in bounds))
assert abs(sum(scores) / ALL - len(PAIRS) * 0.5) < 1e-12       # brute force against linearity
assert sum(fs) == 16 * 10 and even and gap2 == 0               # pairwise independence, two roads
assert pf == 1.0 and pr == 0.5                                 # a three-coin test sees through it
assert again == late(night)                                    # replay from the stored bits, a second route
assert eig and lam < 0.5                                       # characters are eigenvectors
assert all(walk[k] <= bounds[k] + 1e-12 for k in range(8))     # exact walk under the proved bound
assert abs(hits / runs - walk[3]) < 4 * se                     # simulation against exact
print("ALL CHECKS PASS")
