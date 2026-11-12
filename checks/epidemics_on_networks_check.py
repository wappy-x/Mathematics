# Epidemics on a network -- the check behind the card.  Standard library only.
# A synthetic town of 5,000 people: degrees drawn from p_k proportional to k^-2.5
# (k = 3 to 300), wired at random (configuration model), seed 2026.  Flu passes
# along each friendship with chance T = 0.10 over a whole illness.  Road one: the
# degree list's formula.  Road two: a count along every friendship.  Road three:
# seeded SIR outbreaks run on the network itself.
N, T, VAX, RUNS, BIG = 5000, 0.10, 50, 2000, 100
M64 = (1 << 64) - 1
class SplitMix64:                                  # the wing's generator, written out
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def uniform(self): return (self.next() >> 11) * 2.0 ** -53
    def below(self, m): return self.next() % m
rng = SplitMix64(2026)
weights = [k ** -2.5 for k in range(3, 301)]
total, cdf, run = 0.0, [], 0.0
for w in weights: total += w                       # plain left-to-right sums, as in Rust
for w in weights:
    run += w / total; cdf.append(run)
deg = []
for _ in range(N):                                 # draw each person's planned degree
    r, k = rng.uniform(), 0
    while k < len(cdf) - 1 and cdf[k] < r: k += 1
    deg.append(k + 3)
if sum(deg) % 2: deg[-1] += 1
stubs = [i for i in range(N) for _ in range(deg[i])]
for i in range(len(stubs) - 1, 0, -1):             # shuffle the friendship ends, pair them off
    j = rng.below(i + 1); stubs[i], stubs[j] = stubs[j], stubs[i]
adj, edges = [[] for _ in range(N)], 0
for a in range(0, len(stubs) - 1, 2):
    u, v = stubs[a], stubs[a + 1]
    if u == v or v in adj[u]: continue             # drop self-loops and repeats
    adj[u].append(v); adj[v].append(u); edges += 1
ring = [[(i + s) % N for s in (-3, -2, -1, 1, 2, 3)] for i in range(N)]   # what breaks: a ring
def degrees(nbrs, out):                            # degree of each person still in play
    return [sum(1 for v in nbrs[i] if v not in out) for i in range(N) if i not in out]
def moments(ds):                                   # <k>, <k^2> and kappa from the degree list
    n = len(ds); m1 = sum(ds) / n; m2 = sum(d * d for d in ds) / n
    return n, m1, m2, (m2 - m1) / m1
def formula(ds, t):                                # road one: moments and the fixed point
    n, m1, m2, kappa = moments(ds)
    hist = [0] * (max(ds) + 1)
    for d in ds: hist[d] += 1
    if t * kappa <= 1: return m1, m2, kappa, 0.0
    u = 0.0
    for _ in range(200000):                        # u = G1(1 - t + t u), from 0 upward
        x = 1 - t + t * u
        new = 0.0
        for d in range(1, len(hist)): new += hist[d] * d * x ** (d - 1)
        new /= m1 * n
        if abs(new - u) < 1e-14: u = new; break
        u = new
    x, g0 = 1 - t + t * u, 0.0
    for d in range(len(hist)): g0 += hist[d] * x ** d
    return m1, m2, kappa, 1 - g0 / n
def edge_walk(nbrs, out):                          # road two: friends of a friend, minus one
    ends = tot = 0
    for i in range(N):
        if i in out: continue
        for v in nbrs[i]:
            if v not in out: ends += 1; tot += sum(1 for w in nbrs[v] if w not in out) - 1
    return tot / ends
def outbreaks(nbrs, out, t, g):                    # road three: SIR, one generation per step
    sizes, gen1, gen2 = [], 0, 0
    for _ in range(RUNS):
        z = g.below(N)
        while z in out: z = g.below(N)
        state, wave, size, step = {z}, [z], 1, 0
        while wave:
            step += 1; nxt = []
            for u in wave:
                for v in nbrs[u]:
                    if v not in out and v not in state and g.uniform() < t:
                        state.add(v); nxt.append(v)
            if step == 1: gen1 += len(nxt)
            if step == 2: gen2 += len(nxt)
            size += len(nxt); wave = nxt
        sizes.append(size)
    big = [s for s in sizes if s > BIG]
    return len(big) / RUNS, (sum(big) / len(big) if big else 0.0), gen1 / RUNS, gen2 / max(gen1, 1)
d = degrees(adj, set())
hubs = set(sorted(range(N), key=lambda i: (-d[i], i))[:VAX])
rand = set()
while len(rand) < VAX: rand.add(rng.below(N))
print(f"network: {N} people, {edges} friendships, busiest has {max(d)} friends")
print(f"the {VAX} busiest hold {sum(d[i] for i in hubs)} of {sum(d)} friendship ends: {100 * sum(d[i] for i in hubs) / sum(d):.1f}%")
res = {}
for name, out in (("nobody", set()), ("50 busiest", hubs), ("50 at random", rand)):
    ds = degrees(adj, out); m1, m2, kappa, zf = formula(ds, T)
    walk = edge_walk(adj, out); p_big, s_big, g1, ratio = outbreaks(adj, out, T, SplitMix64(7))
    res[name] = (m1, m2, kappa, zf, walk, p_big, s_big, g1, ratio, len(ds))
    print(f"vaccinate {name}: <k> {m1:.4f}  <k^2> {m2:.4f}  kappa {kappa:.4f}  edge walk {walk:.4f}")
    print(f"  T<k> {T * m1:.4f}  R0 = T kappa {T * kappa:.4f}  threshold T_c {1 / kappa:.4f}  formula share {zf:.4f} = {zf * len(ds):.0f} people")
    print(f"  simulated: big share {p_big:.4f}  big size {s_big:.1f} = {s_big / len(ds):.4f}  gen1 {g1:.4f}  gen2/gen1 {ratio:.4f}")
rd = degrees(ring, set()); rm1, rm2, rk, rz = formula(rd, 0.30)
rp, rs, _, _ = outbreaks(ring, set(), 0.30, SplitMix64(11))
print(f"ring of 6 neighbours, T = 0.30: kappa {rk:.4f}  formula share {rz:.4f}  simulated big share {rp:.4f}  big size {rs:.1f}")
m1, m2, kappa = res["nobody"][:3]
need, g, r0s = 1 - 1 / (T * kappa), SplitMix64(13), []
for _ in range(40):                                # 40 random draws of that many doses
    many = set()
    while len(many) < round(need * N): many.add(g.below(N))
    r0s.append(T * moments(degrees(adj, many))[3])
km = 0.0
for r in r0s: km += r / 40
print(f"random doses to reach threshold: 1 - 1/(T kappa) = {need:.4f} = {len(many)} people")
print(f"  R0 after them, 40 draws: mean {km:.4f}  lowest {min(r0s):.4f}  highest {max(r0s):.4f}")
print(f"wrong: R0 from mean degree T<k> = {T * m1:.4f}; from <k^2>/<k> without the -1: {T * m2 / m1:.4f}")
print("chart T:", " ".join(f"{t / 100:.2f}" for t in range(0, 31, 2)))
for name, out in (("nobody", set()), ("50 busiest", hubs), ("50 at random", rand)):
    ds = degrees(adj, out)
    print(f"chart % ill, {name}:", " ".join(f"{100 * formula(ds, t / 100)[3]:.1f}" for t in range(0, 31, 2)))
for t in (0.15, 0.20):
    print(f"try: T = {t:.2f}, 50 busiest vaccinated: formula share {formula(degrees(adj, hubs), t)[3]:.4f}")
a, b, c = res["nobody"], res["50 busiest"], res["50 at random"]
assert abs(a[4] - a[2]) < 1e-9, "edge walk must equal (<k^2>-<k>)/<k>"
assert abs(a[5] - a[3]) < 3 * (a[3] * (1 - a[3]) / RUNS) ** 0.5, "share of big outbreaks vs formula"
assert abs(a[6] / a[9] - a[3]) < 0.006, "size of a big outbreak vs formula"
assert abs(a[7] - T * a[0]) < 0.1, "first generation vs T<k>"
assert abs(a[8] - T * a[2]) < 0.45, "later generations vs T kappa"
assert b[5] < 0.02, "hub vaccination puts the town below threshold"
assert abs(km - 1) < 0.1, "random doses at 1 - 1/R0 land on the threshold"
assert abs(c[5] - c[3]) < 3 * (c[3] * (1 - c[3]) / RUNS) ** 0.5, "random vaccination vs formula"
assert rz > 0.3, "ring: the random-wiring formula predicts a big outbreak"
assert rp < 0.05, "ring: the outbreaks stay small"
print("ALL CHECKS PASS")
