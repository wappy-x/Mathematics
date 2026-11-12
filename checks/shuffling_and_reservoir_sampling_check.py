# Fair choices from a list you cannot hold -- the check behind the card.
# Standard library only, no random module: SplitMix64 is written out here.
# Roads: every possible sequence of draws listed on small cases; the closed
# forms k/n, n! and k times a sum of 1/t; a seeded run over a synthetic day of
# 10,000,000 requests that counts its own writes; and the identity that a
# reservoir is the first k slots of an inside-out Fisher-Yates shuffle.
from itertools import product, permutations
import math
M64, N, K, SEED = 2**64 - 1, 10_000_000, 10, 20261111

class Gen:                                       # SplitMix64 from a stated seed
    def __init__(self, seed): self.s = seed
    def below(self, m):                          # a whole number 0..m-1, all equally likely
        top = 2**64 - 2**64 % m                  # reject the uneven top so no value is favoured
        while True:
            self.s = (self.s + 0x9E3779B97F4A7C15) & M64
            z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
            z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
            z ^= z >> 31
            if z < top: return z % m

def size(kind, n, i): return {'fy': i + 1, 'naive': n, 'sattolo': i}[kind]   # j is drawn from 0..size-1
def steps(kind, n): return range(n) if kind == 'naive' else range(n - 1, 0, -1)

def shuffle(n, draw, kind):                      # 'fy' Fisher-Yates, 'naive', 'sattolo' (j < i)
    a = list(range(1, n + 1))
    for i in steps(kind, n):
        j = draw(size(kind, n, i))
        a[i], a[j] = a[j], a[i]
    return ''.join(map(str, a))

def every_run(n, kind):                          # tally the orders over every sequence of draws
    tally = {}
    for seq in product(*[range(size(kind, n, i)) for i in steps(kind, n)]):
        it = iter(seq)
        o = shuffle(n, lambda m: next(it), kind)
        tally[o] = tally.get(o, 0) + 1
    every = map(''.join, permutations(''.join(map(str, range(1, n + 1)))))
    return {o: tally[o] for o in every if o in tally}   # orders listed in dictionary order

def reservoir(stream, k, draw):                  # Algorithm R: slots and the count of writes
    slots, writes = [], 0
    for t, item in enumerate(stream, 1):
        j = draw(t)                              # a slot from 0 to t-1
        if t <= k:                               # filling up: inside-out shuffle of the first k
            slots.append(item)
            slots[t - 1], slots[j] = slots[j], slots[t - 1]
        elif j < k:
            slots[j], writes = item, writes + 1
    return slots, writes

def inside_out(n, draw):                         # Fisher-Yates run forwards, item t goes to slot j
    a = []
    for t in range(1, n + 1):
        j = draw(t)
        a.append(a[j] if j < t - 1 else None)
        a[j] = t
    return a

fy, naive, satt = every_run(4, 'fy'), every_run(3, 'naive'), every_run(3, 'sattolo')
show = lambda d: ' '.join(f'{o}:{c}' for o, c in d.items())
print(f"fisher-yates, 4 items: {sum(fy.values())} draw sequences, {len(fy)} orders, each {set(fy.values())}")
print(f"4! = {math.factorial(4)}; 10! = {math.factorial(10)}")
print(f"naive (swap with anyone), 3 items: {sum(naive.values())} sequences over 6 orders: {show(naive)}")
print(f"  most likely order {max(naive.values())}/27 = {max(naive.values()) / 27:.3f}, fair 1/6 = {1 / 6:.3f}; 10 items: 10^10 mod 10! = {10**10 % math.factorial(10)}")
print(f"sattolo slip (j below i), 3 items: {sum(satt.values())} sequences reach {len(satt)} orders: {show(satt)}")
print(f"  10 items: it reaches 9! = {math.factorial(9)} of {math.factorial(10)} orders")
print(f"a 52-card deck: 52! is about 2^{sum(math.log2(x) for x in range(2, 53)):.1f}; a 64-bit seed picks 1 of 2^64 starts; {K} of {N} requests: about 2^{sum(math.log2((N - i) / (i + 1)) for i in range(K)):.1f} sets")
a, trace = list('1234'), ['1234']                # one run by hand, draws chosen in advance
for i, j in zip((3, 2, 1), (1, 2, 0)):
    a[i], a[j] = a[j], a[i]
    trace.append(''.join(a))
print(f"fisher-yates by hand, draws j = 1, 2, 0 at i = 3, 2, 1: {' -> '.join(trace)}")
pairs, per_item = {}, [0] * 6                    # every draw sequence for 6 items, keep 2
for seq in product(*[range(t) for t in range(1, 7)]):
    it = iter(seq)
    s, _ = reservoir(range(1, 7), 2, lambda m: next(it))
    key = tuple(x for x in range(1, 7) if x in s)
    pairs[key] = pairs.get(key, 0) + 1
    for x in s: per_item[x - 1] += 1
print(f"reservoir, 6 items keep 2: {sum(pairs.values())} sequences, {len(pairs)} pairs, each {set(pairs.values())} times")
print(f"  each item kept in {set(per_item)} sequences = 720 x 2/6 = {720 * 2 // 6}")
g, slots, writes, t_next, hours = Gen(SEED), [], 0, 1, [h * N // 24 for h in range(25)]
seen, exp_w, var_w, exp_h = [0], 0.0, 0.0, [0.0]  # writes so far, and expected, at each whole hour
for t in range(1, N + 1):                        # the day: request t arrives, t = 1 .. N
    j = g.below(t)
    if t <= K:
        slots.append(t)
        slots[t - 1], slots[j] = slots[j], slots[t - 1]
    else:
        p = K / t
        exp_w, var_w = exp_w + p, var_w + p * (1 - p)
        if j < K: slots[j], writes = t, writes + 1
    while t_next < 25 and hours[t_next] == t:
        seen.append(writes); exp_h.append(exp_w); t_next += 1
asym = K * math.log(N / K)
print(f"day: n = {N} requests ({N / 86400:.1f} a second), k = {K} slots, chance each is kept 1 in {N // K}")
print(f"  expected writes after the first {K}: sum of k/t {exp_w:.3f}; k ln(n/k) {asym:.3f}; sd {var_w ** 0.5:.1f}")
kept_at = []
for t in (11, N // 2):                           # enter, then survive every later request
    survive = 1.0
    for s_ in range(t + 1, N + 1): survive *= 1 - 1 / s_
    kept_at.append(K / t * survive)
    print(f"  request {t}: enters {K / t:.10f}, survives {survive:.10f}, kept {K / t * survive:.10f}")
print(f"  this run, seed {SEED}: {writes} writes; kept {slots}")
print(f"  kept from after noon: {sum(x > N // 2 for x in slots)} of {K}, expected {K / 2:g}, sd {(K * 0.25) ** 0.5:.1f}")
print(f"  expected writes by 1 a.m. {exp_h[1]:.1f}, by noon {exp_h[12]:.1f}, all day {exp_h[24]:.1f}")
print("hour       " + ' '.join(f'{h:>5}' for h in range(25)))
print("expected   " + ' '.join(f'{e:5.1f}' for e in exp_h))
print("this run   " + ' '.join(f'{w:5d}' for w in seen))
same = reservoir(range(1, 1001), K, Gen(SEED).below)[0] == inside_out(1000, Gen(SEED).below)[:K]
print(f"1000 requests, same seed: reservoir equals first {K} slots of inside-out shuffle: {'yes' if same else 'no'}")
runs, counts, g2 = 20000, [0] * 100, Gen(SEED + 1)
for _ in range(runs):
    for x in reservoir(range(100), K, g2.below)[0]: counts[x] += 1
mean, sd = runs * K / 100, (runs * K / 100 * (1 - K / 100)) ** 0.5
chi = sum((c - mean) ** 2 / mean for c in counts)
chi_m, chi_sd = 100 - K, (100 - K) / 99 * 198 ** 0.5    # 99 df, shrunk: each run keeps K different items
print(f"{runs} runs, 100 items, keep {K}: counts {min(counts)} to {max(counts)}, expected {mean:.0f} sd {sd:.1f}")
print(f"  chi-square {chi:.1f}; a fair method gives about {chi_m:.1f}, sd {chi_sd:.1f}")
late, keep = 0.0, 1.0                            # mistake: replace with chance 1/t, as if k were 1
for t in range(N, 0, -1):
    if t > N // 2: late += keep / t
    keep *= 1 - 1 / (t * K)
print(f"mistake, replace with chance 1/t: kept from after noon {late:.3f} (estimate {K * (1 - 0.5 ** (1 / K)):.3f}), right answer {K / 2:g}")
print(f"mistake, keep the first {K}: all from requests 1 to {K}, the first {K / (N / 86400):.3f} seconds after midnight")
r = 2**32 % N
print(f"32-bit draw mod {N}: 2^32 mod n = {r}; values below it come up {2**32 // N + 1} ways, the rest {2**32 // N}")
print(f"  extra weight {100 / (2**32 // N):.3f}%; rejection throws away {100 * r / 2**32:.3f}% of draws")
print(f"try k = 1: expected writes {sum(1 / t for t in range(2, N + 1)):.3f}; k = 100: {sum(100 / t for t in range(101, N + 1)):.1f}")
assert len(fy) == math.factorial(4) and set(fy.values()) == {1}        # exhaustive against 4!
assert naive == {'123': 4, '132': 5, '213': 5, '231': 5, '312': 4, '321': 4}
assert len(pairs) == math.comb(6, 2) and set(pairs.values()) == {720 // 15} and set(per_item) == {240}
assert abs(exp_w - asym) < 0.6 and abs(writes - exp_w) < 4 * var_w ** 0.5   # closed form, run
assert same and (slots, writes) == reservoir(range(1, N + 1), K, Gen(SEED).below)   # two algorithms, one answer
assert all(abs(c - mean) < 5 * sd for c in counts) and abs(chi - chi_m) < 5 * chi_sd
assert all(abs(p - K / N) < 1e-12 for p in kept_at)                  # product against k/n
assert abs(late - K * (1 - 0.5 ** (1 / K))) < 0.01
print("ALL CHECKS PASS")
