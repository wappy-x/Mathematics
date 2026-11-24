# Robustness -- the check behind the card.  Standard library only.  Three synthetic networks of
# 5,000 people wired at random: Poisson, mean 4, seed 4; the epidemics card's town, p_k ~ k^-2.5,
# k = 3..300, seed 2026; the thin town, the same rule from k = 1.  Roads: formula, recount, search.
import math
N, RUNS, ORDERS = 5000, 5, 40
M64 = (1 << 64) - 1
class SplitMix64:                                  # the wing's generator, written out
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64; z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def uniform(self): return (self.next() >> 11) * 2.0 ** -53
    def below(self, m): return self.next() % m
def shuffle(o, g):                                 # Fisher-Yates with the generator
    for i in range(len(o) - 1, 0, -1):
        j = g.below(i + 1); o[i], o[j] = o[j], o[i]
    return o
def wire(deg, rng):                                # configuration model: pair shuffled ends
    if sum(deg) % 2: deg[-1] += 1
    stubs, adj = shuffle([i for i in range(len(deg)) for _ in range(deg[i])], rng), [[] for _ in deg]
    for a in range(0, len(stubs) - 1, 2):
        u, v = stubs[a], stubs[a + 1]
        if u == v or v in adj[u]: continue         # drop self-loops and repeats
        adj[u].append(v); adj[v].append(u)
    return adj
def poisson(c, seed):                              # degrees by inversion of the Poisson law
    rng, deg = SplitMix64(seed), []
    for _ in range(N):
        r, k, p = rng.uniform(), 0, math.exp(-c); cum = p
        while r > cum and k < 60: k += 1; p *= c / k; cum += p
        deg.append(k)
    return wire(deg, rng)
def power(kmin, seed):                             # p_k proportional to k^-2.5, kmin to 300
    rng, w, total, cdf, run, deg = SplitMix64(seed), [k ** -2.5 for k in range(kmin, 301)], 0.0, [], 0.0, []
    for x in w: total += x
    for x in w: run += x / total; cdf.append(run)
    for _ in range(N):
        r, k = rng.uniform(), 0
        while k < len(cdf) - 1 and cdf[k] < r: k += 1
        deg.append(k + kmin)
    return wire(deg, rng)
def largest(adj, alive):                           # road three: biggest component, by search
    seen, best = [False] * N, 0
    for s in range(N):
        if not alive[s] or seen[s]: continue
        seen[s], stack, size = True, [s], 0
        while stack:
            u = stack.pop(); size += 1
            for v in adj[u]:
                if alive[v] and not seen[v]: seen[v] = True; stack.append(v)
        best = max(best, size)
    return best
def removed(adj, order, m):                        # delete the first m people of the order
    alive = [True] * N
    for v in order[:m]: alive[v] = False
    return largest(adj, alive)
def hist_of(ds): return [sum(1 for d in ds if d == k) for k in range(max(ds) + 1)]
def slope(h, keep):                                # F1'(1): the giant needs this above 1
    ends, s = sum(k * h[k] for k in range(len(h))), 0.0
    for k in range(2, len(h)): s += k * (k - 1) * h[k] * keep[k] / ends
    return s
def giant(h, keep):                                # road one: u = 1 - F1(1) + F1(u), S = F0(1) - F0(u)
    if slope(h, keep) <= 1: return 0.0
    ends, f11, u = sum(k * h[k] for k in range(len(h))), 0.0, 0.0
    for k in range(1, len(h)): f11 += k * h[k] * keep[k] / ends
    for _ in range(100000):
        new = 1 - f11
        for k in range(1, len(h)): new += k * h[k] * keep[k] * u ** (k - 1) / ends
        if abs(new - u) < 1e-14: u = new; break
        u = new
    s = 0.0
    for k in range(len(h)): s += h[k] * keep[k] * (1 - u ** k) / N
    return s
def keep_random(h, f): return [1 - f] * len(h)
def keep_attack(h, m):                             # the m highest degrees are gone
    keep = [0.0] * len(h)
    for k in range(len(h) - 1, -1, -1):
        take = min(m, h[k]); m -= take
        if h[k]: keep[k] = (h[k] - take) / h[k]
    return keep
def molloy_reed(adj, order):                       # road two: remove in order, recount, stop at sum k(k-2) <= 0
    d, alive = [len(a) for a in adj], [True] * N; s1, s2 = sum(d), sum(x * x for x in d)
    for m, v in enumerate(order):
        if s2 - 2 * s1 <= 0: return m
        s1 -= d[v]; s2 -= d[v] * d[v]; alive[v] = False
        for w in adj[v]:
            if alive[w]: s1 -= 1; s2 -= 2 * d[w] - 1; d[w] -= 1
    return N
FS = [0, 1, 2, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 96]; print("chart % removed:", " ".join(str(f) for f in FS))
res = {}
for name, adj in (("Poisson", poisson(4.0, 4)), ("town", power(3, 2026)), ("thin town", power(1, 2026))):
    ds = [len(a) for a in adj]; h = hist_of(ds)
    m1 = sum(ds) / N; m2 = sum(d * d for d in ds) / N; kappa = (m2 - m1) / m1
    print(f"{name}: {sum(ds) // 2} links, <k> {m1:.4f}, <k^2> {m2:.4f}, degrees {min(ds)} to {max(ds)}, kappa {kappa:.4f}")
    print(f"  Molloy-Reed <k^2> - 2<k> = {m2 - 2 * m1:.4f}; intact giant: formula {giant(h, keep_random(h, 0)):.4f}, run {largest(adj, [True] * N) / N:.4f}")
    g = SplitMix64(7); orders = [shuffle(list(range(N)), g) for _ in range(ORDERS)]
    att = sorted(range(N), key=lambda i: (-ds[i], i))
    mr = [molloy_reed(adj, o) for o in orders]; mean, var = sum(mr) / N / ORDERS, 0.0
    for x in mr: var += (x / N - mean) ** 2 / (ORDERS - 1)
    ma = next(m for m in range(N) if slope(h, keep_attack(h, m)) <= 1); mra = molloy_reed(adj, att)
    print(f"  random failure threshold: 1 - 1/kappa {1 - 1 / kappa:.4f}; recounted, {ORDERS} orders: mean {mean:.4f} (se {(var / ORDERS) ** 0.5:.4f}), {min(mr) / N:.4f} to {max(mr) / N:.4f}")
    print(f"  attack threshold: formula {ma / N:.4f} ({ma} people); recounted {mra / N:.4f} ({mra} people)")
    rf = [giant(h, keep_random(h, f / 100)) for f in FS]
    rr = [sum(removed(adj, o, round(f * N / 100)) for o in orders[:RUNS]) / N / RUNS for f in FS]
    af = [giant(h, keep_attack(h, round(f * N / 100))) for f in FS]
    ar = [removed(adj, att, round(f * N / 100)) / N for f in FS]
    for lab, xs in (("random, formula", rf), ("random, run", rr), ("attack, formula", af), ("attack, run", ar)):
        print(f"  {lab} %:", " ".join(f"{100 * x:.1f}" for x in xs))
    res[name] = (m1, kappa, mean, var, ma, mra, rf, rr, af, ar, h, adj)
p, t, th = res["Poisson"], res["town"], res["thin town"]; s = s4 = 0.5  # Poisson by hand: S = 1 - e^(-4S); half removed s = 1 - e^(-2s)
for _ in range(200): s, s4 = 1 - math.exp(-2.0 * s), 1 - math.exp(-4.0 * s4)
print(f"by hand: Poisson c = 4: <k^2> = c + c^2 = {4 + 4 ** 2}, <k^2> - 2<k> = {4 + 4 ** 2 - 2 * 4}, kappa = {(4 + 4 ** 2 - 4) // 4}; intact S = 1 - e^(-4S) = {s4:.4f}")
print(f"  half removed: survivors' mean c phi = {4 * 0.5:.1f}, s = 1 - e^(-2s) = {s:.4f}, S = phi s = {0.5 * s:.4f}")
ring, g, rr = [[(i + j) % N for j in (-3, -2, -1, 1, 2, 3)] for i in range(N)], SplitMix64(11), [0, 0]
for i, f in enumerate((0.2, 0.5)):
    for _ in range(RUNS): rr[i] += removed(ring, shuffle(list(range(N)), g), round(f * N))
rr = [x / N / RUNS for x in rr]
rh = hist_of([6] * N); rf = [giant(rh, keep_random(rh, f)) for f in (0.2, 0.5)]
print(f"ring of 6 neighbours: formula 20% {rf[0]:.4f} 50% {rf[1]:.4f}; run 20% {rr[0]:.4f} 50% {rr[1]:.4f}")
skew = wire([3 if i % 10 == 0 else 1 for i in range(N)], SplitMix64(5))
sd = [len(a) for a in skew]; sm1 = sum(sd) / N; sm2 = sum(d * d for d in sd) / N
print(f"mean-degree rule: 90% with 1 friend, 10% with 3: <k> {sm1:.4f} > 1 but <k^2> - 2<k> = {sm2 - 2 * sm1:.4f}; largest {largest(skew, [True] * N)} people")
print(f"wrong: town threshold from its mean degree, 1 - 1/<k> = {1 - 1 / t[0]:.4f}; drop phi at half removed: {s:.4f}")
for c in (2.0, 4.0, 8.0): print(f"try: Poisson mean {c:.0f}: random threshold 1 - 1/c = {1 - 1 / c:.4f}")
print(f"try: the 50 busiest removed: town giant {giant(t[10], keep_attack(t[10], 50)):.4f}, thin town giant {giant(th[10], keep_attack(th[10], 50)):.4f}")
assert abs(1 - 1 / p[1] - 0.75) < 0.01 and abs(p[6][0] - s4) < 0.005, "Poisson: kappa close to c = 4, threshold close to 1 - 1/4"
assert abs(p[2] - (1 - 1 / p[1])) < 3 * (p[3] / ORDERS) ** 0.5, "Poisson: recounted random threshold within 3 se of 1 - 1/kappa"
assert 0 < 1 - 1 / t[1] - t[2] < 6 * (t[3] / ORDERS) ** 0.5, "town: recount lands below 1 - 1/kappa (hubs go early), within 6 se"
for r in (p, t, th): assert abs(r[4] - r[5]) < 0.1 * r[5] + 5, "attack threshold: formula against recount"
assert th[4] / N < 0.03, "thin town: removing under 3% of people, the busiest, ends the giant"
assert t[4] / N < 0.5 * (1 - 1 / t[1]), "town: an attack needs under half the random-failure share"
for r in (p, t):
    for i in (1, 4, 5, 7, 9): assert abs(r[6][i] - r[7][i]) < 0.02, f"random removal {FS[i]}%: formula vs run"
    for i in (1, 2, 3, 4): assert abs(r[8][i] - r[9][i]) < 0.03, f"attack {FS[i]}%: formula vs run"
assert abs(p[6][8] - 0.5 * s) < 0.005, "Poisson half removed: generating function vs closed form"
assert rr[0] < 0.2 * rf[0], "ring: the random-wiring formula overstates robustness"
assert largest(skew, [True] * N) < 0.02 * N, "mean degree above 1 yet no giant"
print("ALL CHECKS PASS")
