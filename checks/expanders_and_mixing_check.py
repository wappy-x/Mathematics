# Expanders: a 10-station pilot (every cut checked) and two synthetic 1,200-station networks with 3 links
# per station: a random one (SplitMix64, seed 2026) and a ladder (two loops of 600 joined by rungs).
import math, functools
M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = ((self.x ^ (self.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def below(self, k): return self.next() % k
tot = lambda xs: functools.reduce(lambda a, b: a + b, xs, 0.0)   # plain left-to-right sum, as in the Rust
def ball(adj, start, k):                      # first k stations met by breadth-first search
    seen, order, i = {start}, [start], 0
    while i < len(order) and len(order) < k:
        for w in adj[order[i]]:
            if w not in seen and len(order) < k: seen.add(w); order.append(w)
        i += 1
    return order
def random_cubic(n, rng):                     # pair up 3n link-ends at random; retry until simple, connected
    while True:
        ends = [v for v in range(n) for _ in range(3)]
        for i in range(len(ends) - 1, 0, -1):
            j = rng.below(i + 1); ends[i], ends[j] = ends[j], ends[i]
        adj, ok = [[] for _ in range(n)], True
        for k in range(0, 3 * n, 2):
            a, b = ends[k], ends[k + 1]
            if a == b or b in adj[a]: ok = False; break
            adj[a].append(b); adj[b].append(a)
        if ok and len(ball(adj, 0, n)) == n: return adj
def ladder(n):
    m = n // 2
    return [[(i + 1) % m + r * m, (i - 1) % m + r * m, i + (1 - r) * m] for r in (0, 1) for i in range(m)]
def boundary(adj, inS): return sum(1 for v in range(len(adj)) if inS[v] for w in adj[v] if not inS[w])
def rayleigh(adj, f):                         # sum over links of (f_i - f_j)^2, over sum of f_i^2
    return tot((f[i] - f[j]) ** 2 for i in range(len(adj)) for j in adj[i] if i < j) / tot(x * x for x in f)
def lam2(adj, iters):                         # power iteration on 6I - L = 3I + A, at right angles to all-ones
    n, rng = len(adj), SplitMix64(7)
    f = [(rng.next() >> 11) / 2.0 ** 53 - 0.5 for _ in range(n)]
    for it in range(iters + 1):
        mean = tot(f) / n; f = [x - mean for x in f]
        if it == iters: return rayleigh(adj, f), f
        g = [3.0 * f[i] + f[adj[i][0]] + f[adj[i][1]] + f[adj[i][2]] for i in range(n)]
        s = math.sqrt(tot(x * x for x in g)); f = [x / s for x in g]
def sweep(adj, f):                            # best cut among "the k stations with smallest f", k <= n/2
    n = len(adj); order = sorted(range(n), key=lambda i: f[i]); inS = [False] * n
    cut, best = 0, (9, 1)
    for k, v in enumerate(order[: n // 2]):
        inS[v] = True; cut += sum(-1 if inS[w] else 1 for w in adj[v])
        if cut * best[1] < best[0] * (k + 1): best = (cut, k + 1)
    return best
def tv_trace(adj, steps, lazy=True, start=0, stop=-1.0):   # exact spread of the walk from start; distance from even
    n = len(adj); p = [0.0] * n; p[start] = 1.0; out = []
    while len(out) <= steps and (not out or out[-1] > stop):   # ends early once the distance is down to stop
        out.append(0.5 * tot(abs(x - 1.0 / n) for x in p))
        nb = [p[adj[i][0]] + p[adj[i][1]] + p[adj[i][2]] for i in range(n)]
        p = [0.5 * p[i] + nb[i] / 6.0 for i in range(n)] if lazy else [x / 3.0 for x in nb]
    return out
def walk_share(adj, inS, steps, rng):         # lazy walk from a random station; share of steps inside S
    v, hits = rng.below(len(adj)), 0
    for _ in range(steps):
        if rng.below(2) == 1: v = adj[v][rng.below(3)]
        hits += inS[v]
    return hits / steps
def spread(xs):
    m = tot(xs) / len(xs); return m, math.sqrt(tot((x - m) ** 2 for x in xs) / (len(xs) - 1))
# ---- the pilot: outer ring of 5, inner star of 5, 5 spokes (the Petersen network) ----
P = [[(i + 1) % 5, (i + 4) % 5, i + 5] for i in range(5)] + [[5 + (i + 2) % 5, 5 + (i + 3) % 5, i] for i in range(5)]
best, nbest, cuts = 9.0, 0, 0
for mask in range(1, 1 << 10):
    S = [(mask >> v) & 1 == 1 for v in range(10)]
    if sum(S) > 5: continue
    cuts += 1; r = boundary(P, S) / sum(S)
    if r < best - 1e-12: best, nbest = r, 0
    if abs(r - best) < 1e-12: nbest += 1
A2 = [[sum(1 for k in range(10) if i in P[k] and j in P[k]) for j in range(10)] for i in range(10)]
identity = all(A2[i][j] + (j in P[i]) - 2 * (i == j) == 1 for i in range(10) for j in range(10))
lp = lam2(P, 200)[0]
print(f"pilot: sets of 1-5 stations checked {cuts}; edge expansion h {best:.6f}, reached by {nbest} sets")
print(f"pilot: A^2 + A - 2I = J at every entry: {identity}; gap by power iteration {lp:.6f}")
print(f"pilot: lam2/2 {lp / 2:.6f} <= h {best:.6f} <= sqrt(2 d lam2) {math.sqrt(6 * lp):.6f}; mixes within {math.ceil(6 / lp * math.log(2 * math.sqrt(10)))} steps")
# ---- 1,200 stations, 1,800 links: random against ladder ----
rng = SplitMix64(2026)
E120, E, L = random_cubic(120, rng), random_cubic(1200, rng), ladder(1200)
lad = lambda n: 2.0 - 2.0 * math.cos(2.0 * math.pi / (n // 2))
(le, fe), le_half, l120 = lam2(E, 3000), lam2(E, 1500)[0], lam2(E120, 3000)[0]
ll, ll_rq, ll120 = lad(1200), rayleigh(L, [math.cos(2.0 * math.pi * (i % 600) / 600) for i in range(1200)]), lam2(ladder(120), 3000)[0]
cut, size = min(sweep(E, fe), sweep(E, [-x for x in fe]), key=lambda c: c[0] / c[1])   # sweep from both ends
print(f"gap, random  n=120, 1200:   {l120:.6f} {le:.6f}   (1500 iterations: {le_half:.6f})")
print(f"gap, ladder  n=120, 1200:   {lad(120):.6f} {ll:.6f}   (closed form; power iteration n=120: {ll120:.6f}; Rayleigh check: {ll_rq:.6f})")
print(f"large-network limit 3 - 2 sqrt 2:             {3 - 2 * math.sqrt(2):.6f}")
print(f"random: h >= lam2/2 = {le / 2:.4f}; sweep cut {cut} links / {size} stations = {cut / size:.4f}; h <= {math.sqrt(6 * le):.4f}")
print(f"ladder: h >= lam2/2 = {ll / 2:.7f}; half cut 4 links / 600 stations = {4 / 600:.4f}; h <= {math.sqrt(6 * ll):.4f}")
lnn = math.log(2 * math.sqrt(1200))
tb_e, tb_l = math.ceil(6 / le * lnn), math.ceil(6 / ll * lnn)
print(f"guaranteed mixing, (2d/lam2) ln(2 sqrt n): random {tb_e} steps, ladder {tb_l} steps")
te, tl = tv_trace(E, 150), tv_trace(L, 1000)
bound = lambda lam, t: 0.5 * (1 - lam / 6) ** t * math.sqrt(1199)
tmix = next(t for t, d in enumerate(te) if d <= 0.25)
tmix_w = max(len(tv_trace(E, 400, start=s, stop=0.25)) - 1 for s in range(1200))   # every start; t_mix is the worst
print("step   distance: random  ladder   random's guarantee")
for t in range(0, 151, 15): print(f"{t:4d}            {te[t]:.4f}  {tl[t]:.4f}   {min(1.0, bound(le, t)):.4f}")
print(f"random: first step with distance <= 1/4: {tmix} from station 0, {tmix_w} from the worst start;  ladder at step 1000: {tl[1000]:.4f}")
# ---- sampling: share of stations in a 240-station district around station 0 (truth 0.2) ----
res, dist = {}, {}
for name, g in (("random", E), ("ladder", L)):
    inS = [False] * 1200
    for v in ball(g, 0, 240): inS[v] = True
    b, dist[name] = boundary(g, inS), inS
    res[name] = [walk_share(g, inS, 1000, SplitMix64(s + 1)) for s in range(200)]
    lam = le if name == "random" else ll
    print(f"district on {name}: {b} links out (at least {lam * 240 * 960 / 1200:.2f}); a lazy step leaves with chance {b / 1440:.4f}")
indep = []
for s in range(200):
    r = SplitMix64(10_000 + s); indep.append(sum(1 for _ in range(1000) if r.below(1200) < 240) / 1000)
(m_i, s_i), (m_e, s_e), (m_l, s_l) = spread(indep), spread(res["random"]), spread(res["ladder"])
for name, m, sd in (("independent picks", m_i, s_i), ("walk, random", m_e, s_e), ("walk, ladder", m_l, s_l)): print(f"200 runs x 1000 picks, {name:<17} mean {m:.4f}  spread {sd:.4f}")
s_th, ls = math.sqrt(0.16 / 1000), 1 - le / 6
s_g = s_th * math.sqrt((1 + ls) / (1 - ls))
print(f"theory: independent spread sqrt(0.2 x 0.8 / 1000) = {s_th:.4f}; walk guarantee x {s_g / s_th:.2f} = {s_g:.4f}")
print(f"random bits per run: independent {1000 * math.log2(1200):.0f}, walk {math.log2(1200) + 1000 * (1 + math.log2(3)):.0f}")
s_short = spread([walk_share(E, dist["random"], 250, SplitMix64(500 + s)) for s in range(200)])[1]
print(f"try: walk of 250 steps on random network, spread {s_short:.4f}")
# ---- what breaks: the cube (8 stations, 3 links, two colours) walked without waiting ----
Q = [[i ^ 1, i ^ 2, i ^ 4] for i in range(8)]
qn, ql = tv_trace(Q, 61, lazy=False), tv_trace(Q, 61)
print(f"cube: gap {lam2(Q, 200)[0]:.6f}; plain walk distance at 60, 61: {qn[60]:.4f} {qn[61]:.4f}; lazy: {ql[60]:.4f}")
pts = [(180 + rad * math.cos(math.radians(-90 + 72 * k)), 125 + rad * math.sin(math.radians(-90 + 72 * k))) for rad in (95, 45) for k in range(5)]
print("figure, " + " ".join(f"{x:.1f},{y:.1f}" for x, y in pts))
assert abs(best - 1.0) < 1e-12 and nbest == 12, "pilot: every set checked, cheapest is 5 links for 5 stations"
assert identity and abs(lp - 2.0) < 1e-9, "pilot: power iteration lands on the gap the identity forces"
assert abs(ll - ll_rq) < 1e-12 and abs(ll120 - lad(120)) < 1e-9, "ladder: closed form vs its cosine pattern, and vs power iteration at 120"
assert le / 2 <= cut / size <= math.sqrt(6 * le) and abs(le - le_half) < 1e-6, "random: sweep cut inside Cheeger"
assert all(te[t] <= bound(le, t) for t in range(151)) and all(tl[t] <= bound(ll, t) for t in range(1001)), "gap bound"
assert tmix <= tmix_w <= tb_e and tl[1000] > 0.5, "random mixes inside its guarantee from every start; ladder is still far off"
assert abs(s_i / s_th - 1) < 0.2 and abs(m_e - 0.2) < 4 * s_e / math.sqrt(200) and s_e <= s_g, "samplers"
assert s_l > 5 * s_e, "ladder walk's estimate swings far more than the random network's"
assert abs(qn[60] - 0.5) < 1e-12 and abs(qn[61] - 0.5) < 1e-12 and ql[60] < 1e-6, "two-colour trap"
print("ALL CHECKS PASS")
