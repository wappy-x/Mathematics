# First and second moments -- the check behind the card; only math is imported.
# A club of 100 members; each pair are friends with chance p, independently.
# X counts triangles: trios of members who are all friends with each other.
# Roads: the formulas for E[X] and Var(X); every friendship pattern of a
# 6-member club enumerated; a seeded simulation of 10,000 clubs per p.
import math

N, TRIALS, SEED = 100, 10000, 20260929
PS = [0.0025, 0.005, 0.01, 0.015, 0.02, 0.03, 0.04, 0.05]

def choose(n, k):                             # C(n, k), by the multiplicative rule
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def mean_f(n, p):                             # first moment: C(n,3) p^3
    return choose(n, 3) * p ** 3

def var_f(n, p):                              # own terms, then pairs sharing an edge
    t = choose(n, 3)
    return t * (p ** 3 - p ** 6) + t * 3 * (n - 3) * (p ** 5 - p ** 6)

def ratio_f(n, p):                            # Var/E^2 rewritten by hand, a second road
    return (1 - p ** 3) / mean_f(n, p) + 3 * (n - 3) * (1 - p) / (choose(n, 3) * p)

def splitmix64(s):                            # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return s, z ^ (z >> 31)

def row(label, v):
    print(f"{label:<50} {v:>12.6f}")

# ---- road 2: every friendship pattern of a 6-member club, 2^15 of them ----
pairs6 = [(i, j) for i in range(6) for j in range(i + 1, 6)]
bit = {pr: 1 << k for k, pr in enumerate(pairs6)}
trios6 = [bit[(a, b)] | bit[(a, c)] | bit[(b, c)]
          for a in range(6) for b in range(a + 1, 6) for c in range(b + 1, 6)]
tally = {}                                    # (friendships, triangles) -> patterns
for mask in range(1 << 15):
    key = (bin(mask).count("1"), sum(1 for t in trios6 if mask & t == t))
    tally[key] = tally.get(key, 0) + 1
def enum6(p):                                 # exact E[X], Var(X), P(X = 0) by counting
    w = {k: c * p ** k[0] * (1 - p) ** (15 - k[0]) for k, c in tally.items()}
    m = sum(v * k[1] for k, v in w.items())
    return m, sum(v * k[1] ** 2 for k, v in w.items()) - m * m, sum(v for k, v in w.items() if k[1] == 0)
share2 = sum(1 for s in trios6 for t in trios6 if bin(s & t).count("1") == 1)

print(f"club n = {N}: pairs {choose(N, 2)}, trios C(100,3) = {choose(N, 3)}")
split = [0, 0, 0, 0]                          # trios meeting trio {0,1,2} in 0..3 members
for a in range(N):
    for b in range(a + 1, N):
        for c in range(b + 1, N):
            split[(a < 3) + (b < 3) + (c < 3)] += 1
print(f"trios sharing 0 / 1 / 2 members with one trio: {split[0]} {split[1]} {split[2]}; 3(n-3) = {3 * (N - 3)}")
print(f"6 members: trio pairs sharing an edge, counted {share2}, formula C(6,3)*3*3 = {choose(6, 3) * 9}")
for p in (0.2, 0.6):
    m, v, z = enum6(p)
    print(f"6 members, p = {p}: E formula {mean_f(6, p):.6f} counted {m:.6f}; Var formula {var_f(6, p):.6f} counted {v:.6f}")
    print(f"6 members, p = {p}: P(X>=1) {1 - z:.6f} <= Markov {mean_f(6, p):.6f}; P(X=0) {z:.6f} <= Chebyshev {var_f(6, p) / mean_f(6, p) ** 2:.6f}")
worst6 = max([0.0] + [max(1 - z - m, z - v / (m * m)) for m, v, z in (enum6(k / 100) for k in range(1, 100))])

# ---- the worked numbers, n = 100 ----
for p in (0.005, 0.05):
    print(f"p = {p}: p^3 = {p ** 3:.9f}")
    row(f"p = {p}: E[X] = C(100,3) p^3", mean_f(N, p))
    row(f"p = {p}: Paley-Zygmund floor E^2/(E^2 + Var)", mean_f(N, p) ** 2 / (mean_f(N, p) ** 2 + var_f(N, p)))
p = 0.05
row("p = 0.05: own part C(100,3)(p^3 - p^6)", choose(N, 3) * (p ** 3 - p ** 6))
row("p = 0.05: shared-edge part 161700*291*(p^5 - p^6)", choose(N, 3) * 3 * (N - 3) * (p ** 5 - p ** 6))
row("p = 0.05: Var(X)", var_f(N, p))
row("p = 0.05: Chebyshev Var/E^2", var_f(N, p) / mean_f(N, p) ** 2)
row("p = 0.05: same, by the simplified ratio", ratio_f(N, p))

# ---- road 3: 10,000 simulated clubs per p, friendships by geometric skips ----
pairs = [(i, j) for i in range(N) for j in range(i + 1, N)]
state, sims = SEED, []
for p in PS:
    lq, zero, s1, s2, s3, s4 = math.log(1 - p), 0, 0, 0, 0, 0
    for _ in range(TRIALS):
        adj, pos, edges = [0] * N, -1, []
        while True:                           # jump straight to the next friendship
            state, z = splitmix64(state)
            pos += 1 + math.floor(math.log(((z >> 11) + 1) * 2.0 ** -53) / lq)
            if pos >= len(pairs):
                break
            i, j = pairs[pos]
            edges.append((i, j))
            adj[i] |= 1 << j
            adj[j] |= 1 << i
        x = sum(((adj[i] & adj[j]) >> (j + 1)).bit_count() for i, j in edges)
        zero += x == 0
        s1, s2, s3, s4 = s1 + x, s2 + x * x, s3 + x ** 3, s4 + x ** 4
    q, m = 1 - zero / TRIALS, s1 / TRIALS
    v = (s2 - s1 * s1 / TRIALS) / (TRIALS - 1)
    m4 = (s4 - 4 * m * s3 + 6 * m * m * s2) / TRIALS - 3 * m ** 4
    sims.append((p, q, math.sqrt(q * (1 - q) / TRIALS), m, math.sqrt(v / TRIALS), v, math.sqrt(max(m4 - v * v, 0) / TRIALS)))

print("exact,      p  c = np      E[X]     Var(X)  Var/E^2  Markov cap  Chebyshev floor  1-exp(-E)")
for p in PS:
    e, v = mean_f(N, p), var_f(N, p)
    print(f"exact, {p:>6} {N * p:>7.4f} {e:>10.4f} {v:>10.4f} {v / e / e:>8.4f} {min(1, e):>11.4f} {max(0, 1 - v / e / e):>16.4f} {1 - math.exp(-e):>10.4f}")
print("sim,        p  P(X>=1)     s.e.   mean X    s.e.   var X    s.e.")
for p, q, sq, m, sm, v, sv in sims:
    print(f"sim,   {p:>6}  {q:>7.4f}  {sq:>7.4f} {m:>8.4f} {sm:>7.4f} {v:>7.4f} {sv:>7.4f}")
print("chart, Markov cap:      " + " ".join(f"{min(1, mean_f(N, p)):.2f}" for p in PS))
print("chart, simulated:       " + " ".join(f"{s[1]:.2f}" for s in sims))
print("chart, Chebyshev floor: " + " ".join(f"{max(0, 1 - var_f(N, p) / mean_f(N, p) ** 2):.2f}" for p in PS))

# ---- what breaks ----
row("wrong: Markov read backwards, E[X] at p = 0.02", mean_f(N, 0.02))
row("wrong:   simulated P(X>=1) at p = 0.02", sims[4][1])
p = 0.05
indep = choose(N, 3) * (p ** 3 - p ** 6)
row("wrong: shared edges ignored, Var at p = 0.05", indep)
row("wrong:   its 'bound' Var/E^2", indep / mean_f(N, p) ** 2)
full = [((1 << N) - 1) ^ (1 << i) for i in range(N)]   # all-or-nothing club: with chance 0.1
tfull = sum(((full[i] & full[j]) >> (j + 1)).bit_count() for i, j in pairs)   # all are friends
ea, e2a = 0.1 * tfull, 0.1 * tfull * tfull
row("wrong: all-or-nothing club, E[X]", ea)
row("wrong:   its P(X = 0)", 1 - 0.1 * (tfull > 0))   # the empty club, chance 0.9, has none
row("wrong:   its Chebyshev Var/E^2", (e2a - ea * ea) / (ea * ea))
row("6 members, 99 values of p: worst bound overshoot", worst6)
row("house example, n = 1000, p = 0.001: E[X]", mean_f(1000, 0.001))
print(f"figure, A (60,190) B (180,190) C (120,{190 - 60 * math.sqrt(3):.0f}) D (240,{190 - 60 * math.sqrt(3):.0f}), sides 120")

assert split == [choose(N - 3, 3), 3 * choose(N - 3, 2), 3 * (N - 3), 1] and share2 == choose(6, 3) * 9, "shared-member counts"
for p in (0.2, 0.6):
    m, v, z = enum6(p)
    assert abs(m - mean_f(6, p)) + abs(v - var_f(6, p)) < 1e-12, "formula vs every pattern"
assert worst6 <= 1e-12, "Markov and Chebyshev hold on every enumerated club"
assert all(abs(var_f(N, p) / mean_f(N, p) ** 2 - ratio_f(N, p)) < 1e-12 for p in PS), "two algebra roads"
for p, q, sq, m, sm, v, sv in sims:
    assert abs(m - mean_f(N, p)) < 4 * sm and abs(v - var_f(N, p)) < 4 * sv, "simulation vs formulas"
    assert q <= mean_f(N, p) + 4 * sq and 1 - q <= var_f(N, p) / mean_f(N, p) ** 2 + 4 * sq, "simulation under both bounds"
assert tfull == choose(N, 3), "every trio of the full club counted as a triangle"
print("ALL CHECKS PASS")
