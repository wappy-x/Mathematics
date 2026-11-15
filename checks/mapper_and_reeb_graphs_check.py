# Mapper on twenty simulated years of three-day windows: build it, read it as a Reeb graph.
from collections import deque
from math import sqrt
M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def draw(self, a): return self.next() % (2 * a + 1) - a   # whole number in [-a, a]

# Daily returns in tenths of a percent. Calm days: sum of three draws in [-7, 7].
# Days 2400-2447: selling builds for 24 days, then a rebound starts at full strength and fades.
DRIFT = [-3, -6, -9, -12, -15, -18, -21, -24, 24, 21, 18, 15, 12, 9, 6, 3]
N = 1680
KIND = ["fall" if 800 <= w < 808 else "rebound" if 808 <= w < 816 else "calm" for w in range(N)]
def cloud(seed):
    rng, days = SplitMix64(seed), []
    for t in range(5040):
        days.append(DRIFT[(t - 2400) // 3] + rng.draw(3) if 2400 <= t < 2448 else rng.draw(7) + rng.draw(7) + rng.draw(7))
    W = [tuple(days[3 * w:3 * w + 3]) for w in range(N)]
    return days, W, [x * x + y * y + z * z for x, y, z in W], [x + y + z for x, y, z in W]   # squared size, net move
def D2(W, a, b): return (W[a][0] - W[b][0]) ** 2 + (W[a][1] - W[b][1]) ** 2 + (W[a][2] - W[b][2]) ** 2
def near_pairs(W, eps):  # every pair of windows within eps tenths of a percent
    return [(a, b) for a in range(N) for b in range(a + 1, N) if D2(W, a, b) <= eps * eps]

def find(parent, x):
    while parent[x] != x: parent[x] = parent[parent[x]]; x = parent[x]
    return x

def mapper(inband, bands, pairs):
    nodes = []
    for lo, hi in bands:                                # cluster each band's windows
        parent = {w: w for w in range(N) if inband(w, lo, hi)}
        for a, b in pairs:
            if a in parent and b in parent: parent[find(parent, a)] = find(parent, b)
        groups = {}
        for w in parent: groups.setdefault(find(parent, w), []).append(w)
        nodes += [((lo, hi), g) for g in sorted(groups.values())]
    edges = [(i, j, len(set(nodes[i][1]) & set(nodes[j][1]))) for i in range(len(nodes)) for j in range(i + 1, len(nodes))]
    return nodes, [e for e in edges if e[2] > 0]       # an edge wherever two clusters share windows

def pieces(n, links):  # breadth-first search: a piece label for every vertex
    adj, label = [[] for _ in range(n)], [-1] * n
    for e in links: adj[e[0]].append(e[1]); adj[e[1]].append(e[0])
    for s in range(n):
        if label[s] >= 0: continue
        label[s] = max(label) + 1; q = deque([s])
        while q:
            for v in adj[q.popleft()]:
                if label[v] < 0: label[v] = label[s]; q.append(v)
    return label

def loops_by_union_find(n, edges):  # count edges that close a cycle
    parent, extra = list(range(n)), 0
    for i, j, _ in edges:
        if find(parent, i) == find(parent, j): extra += 1
        else: parent[find(parent, i)] = find(parent, j)
    return extra

cover = lambda L, O, lo=0, top=60: [(a, a + L) for a in range(lo, top, L - O)]   # half-open bands [a, a + L)
mix = lambda g: {k: sum(1 for w in g if KIND[w] == k) for k in ("calm", "fall", "rebound")}
pct = lambda v: f"{v / 10:.2f}"

def report(name, inband, bands, pairs, show=False):
    nodes, edges = mapper(inband, bands, pairs)
    deg = [0] * len(nodes)
    for i, j, _ in edges: deg[i] += 1; deg[j] += 1
    for i, ((lo, hi), g) in enumerate(nodes if show else []):
        c = mix(g)
        print(f"  node {i}: band [{pct(lo)}, {pct(hi)}), {len(g)} windows: {c['calm']} calm, {c['fall']} fall, {c['rebound']} rebound")
    if show: print("  edges, with shared windows: " + ", ".join(f"{i}-{j}: {s}" for i, j, s in edges))
    p = max(pieces(len(nodes), edges)) + 1
    print(f"{name}: {len(nodes)} nodes, {len(edges)} edges, {p} piece(s), loops {len(edges) - len(nodes) + p}, "
          f"ends {deg.count(1)}, branch points {sum(1 for d in deg if d >= 3)}")
    assert len(edges) - len(nodes) + p == loops_by_union_find(len(nodes), edges)
    return nodes, edges, p, deg

assert loops_by_union_find(4, [(0, 1, 1), (1, 2, 1), (0, 2, 1), (2, 3, 1)]) == 1   # road 3 can see a loop: a triangle with a tail
days, W, S2, NET = cloud(2026)
by_size = lambda w, lo, hi: lo * lo <= S2[w] < hi * hi
by_net = lambda w, lo, hi: lo <= NET[w] < hi
size = lambda w: pct(sqrt(S2[w]))
calm_max = max(S2[w] for w in range(N) if KIND[w] == "calm")
tip = {k: max((S2[w], w) for w in range(N) if KIND[w] == k)[1] for k in ("fall", "rebound")}
print(f"cloud: 5040 days, {N} windows; calm daily spread {pct(sqrt(56))}% (model)")
print(f"crisis: days 2400-2447, windows 800-815; 24 days of falls add to {sum(days[2400:2424]) / 10:.1f}%, 24 of rebound to {sum(days[2424:2448]) / 10:.1f}%")
print(f"largest calm window {pct(sqrt(calm_max))}%; fall tip {size(tip['fall'])}%; rebound tip {size(tip['rebound'])}%")
assert all(abs(sqrt(S2[a]) - sqrt(S2[b])) <= sqrt(D2(W, a, b)) + 1e-9 for a in range(0, N, 7) for b in range(0, N, 11))  # 1-Lipschitz
P10, P12, P6 = near_pairs(W, 10), near_pairs(W, 12), near_pairs(W, 6)
cloud_pieces = max(pieces(N, P10)) + 1
print(f"link 1.00%: {len(P10)} close pairs; whole cloud in {cloud_pieces} piece(s) by breadth-first search")
print("fall windows by hand: returns in %, squared size, size, distance to the window before")
for w in range(800, 808):
    print(f"  window {w}: ({', '.join(f'{v / 10:.1f}' for v in W[w])}), {S2[w]}, {size(w)}%, {pct(sqrt(D2(W, w, w - 1)))}%")
nodes, edges, pA, degA = report("cover A, bands 2.00% wide, overlap 1.00%, link 1.00%", by_size, cover(20, 10), P10, True)
assert pA == cloud_pieces == 1                       # overlap >= link: Mapper's pieces = the cloud's pieces
assert degA.count(1) == 3 and sum(1 for d in degA if d >= 3) == 1     # a Y: one branch point, three ends
for (lo, hi), g in nodes:                            # beyond the calm windows, each node is pure crisis
    if lo * lo > calm_max: assert len({KIND[w] for w in g}) == 1 and KIND[g[0]] != "calm"
print(f"  windows on edge 2-3: {sorted(set(nodes[2][1]) & set(nodes[3][1]))}")
_, _, pB, degB = report("cover B, bands 1.50% wide, overlap 0.50%, link 1.20%", by_size, cover(15, 5), P12)
assert pB == 1 and degB.count(1) == 3 and sum(1 for d in degB if d >= 3) == 1
print(f"Reeb graph of the ideal shape: trunk 0.00% to {pct(sqrt(calm_max))}%, branches to {size(tip['fall'])}% and {size(tip['rebound'])}%")
mean = [sum(p[i] for p in W) / N for i in range(3)]
C = [[sum((p[i] - mean[i]) * (p[j] - mean[j]) for p in W) / N for j in range(3)] for i in range(3)]
v = [1.0, 0.0, 0.0]
for _ in range(500):                                 # power iteration for the first principal component
    u = [sum(C[i][j] * v[j] for j in range(3)) for i in range(3)]
    v = [x / sqrt(sum(y * y for y in u)) for x in u]
print(f"first principal component vs the all-equal diagonal: cosine {abs(sum(v)) / sqrt(3):.3f}")
print("what breaks:")
_, _, pT, _ = report("  overlap 0.20% < link 1.00%", by_size, cover(10, 2), P10)
assert pT > cloud_pieces
_, _, _, degS = report("  link 0.60%", by_size, cover(20, 10), P6)
assert degS.count(1) > 3
nN, eN, _, degN = report("  lens = net move, bands 2.00% wide, overlap 1.00%", by_net, cover(20, 10, -100, 100), P10)
assert sum(1 for d in degN if d >= 3) == 0 and degN.count(1) == 2
ends = [mix(nN[i][1]) for i in range(len(nN)) if degN[i] == 1]
print(f"  net-move path ends: {ends[0]['fall']} fall + {ends[0]['calm']} calm, {ends[1]['rebound']} rebound + {ends[1]['calm']} calm")
both = specky = 0
for seed in range(1, 21):                            # the same recipe on twenty other simulated histories
    _, W2, S, _ = cloud(seed)
    nd, ed = mapper(lambda w, lo, hi: lo * lo <= S[w] < hi * hi, cover(20, 10), near_pairs(W2, 10))
    lab = pieces(len(nd), ed); main = lab[max(range(len(nd)), key=lambda i: len(nd[i][1]))]
    both += all(any(lab[i] == main and {KIND[w] for w in nd[i][1]} == {k} for i in range(len(nd))) for k in ("fall", "rebound"))
    specky += any({KIND[w] for w in g} == {"calm"} and len(g) <= 2 for _, g in nd)
print(f"seeds 1-20, cover A: both flares hang off the main piece in {both} of 20; specks of 1-2 calm windows in {specky} of 20")
assert (both, specky) == (17, 12)                    # as found by an earlier, separate sweep script
fx = lambda w: 240 + 50 * NET[w] / 10 / sqrt(3)
fy = lambda w: 220 - 50 * sqrt(max(S2[w] - NET[w] ** 2 / 3, 0)) / 10
print(f"figure, 50 px per 1%, centre (240,220); fall tip ({fx(tip['fall']):.1f},{fy(tip['fall']):.1f}); "
      f"rebound tip ({fx(tip['rebound']):.1f},{fy(tip['rebound']):.1f})")
print("ALL CHECKS PASS")
