# Graph algorithms as code -- the check behind the card.  Standard library only: no heapq, no sorted.
# A synthetic city: 1,200 bike-share stations on a 40 x 30 grid, a street per neighbouring pair; SplitMix64
# (seed 2026) gives each street 60-120 s of riding, 100-600 bikes an hour of room, a 40% chance of one-way.
import sys, math
sys.setrecursionlimit(20000); M64, BIG = (1 << 64) - 1, 10 ** 9
def splitmix(s):
    while True:
        s = (s + 0x9E3779B97F4A7C15) & M64; z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64; yield z ^ (z >> 31)
def city(W, H):                                            # street: (u, v, seconds, bikes an hour, one-way?)
    r, st, adj = splitmix(2026), [], [[] for _ in range(W * H)]
    for i in range(W * H):
        for j, ok in ((i + 1, i % W + 1 < W), (i + W, i // W + 1 < H)):
            if ok: st.append((i, j, 60 + next(r) % 61, 100 * (1 + next(r) % 6), next(r) % 100 < 40))
    for u, v, w, c, o in st: adj[u].append((v, w)); adj[v].append((u, w))
    return st, adj
def push(h, x, c):                                         # binary heap in a list: slot i's parent is (i-1)//2
    h.append(x); i = len(h) - 1
    while i and h[(i - 1) // 2] > h[i]: h[i], h[(i - 1) // 2] = h[(i - 1) // 2], h[i]; i = (i - 1) // 2; c[0] += 1
def pop(h, c):                                             # take the root, sift the last entry down
    top, last = h[0], h.pop(); i = 0
    if h: h[0] = last
    while True:
        m = min((k for k in (i, 2 * i + 1, 2 * i + 2) if k < len(h)), key=lambda k: h[k], default=i)
        if m == i: return top
        h[i], h[m] = h[m], h[i]; i = m; c[0] += 1
def bfs(adj, s):                                           # the queue is a list read from the front
    d, back, q, looks = [-1] * len(adj), [-1] * len(adj), [s], 0; d[s] = 0
    for u in q:
        for v, w in adj[u]:
            looks += 1
            if d[v] < 0: d[v], back[v] = d[u] + 1, u; q.append(v)
    return d, back, looks
def astar(adj, s, t, h):                                   # h = 0 everywhere is Dijkstra with a heap
    d, done, hp, c, n = [BIG] * len(adj), [False] * len(adj), [], [0], [1, 0]; d[s] = 0; push(hp, (h(s), s), c)
    while hp:
        k, u = pop(hp, c)
        if done[u]: continue                               # stale entry: u was pushed again, cheaper
        done[u] = True; n[1] += 1
        if u == t: break
        for v, w in adj[u]:
            if d[u] + w < d[v]: d[v] = d[u] + w; push(hp, (d[v] + h(v), v), c); n[0] += 1
    return d, n[1], n[0], c[0]                             # seconds, settled, pushes, heap swaps
def bellman(adj, s):                                       # second road: relax every street, V - 1 rounds
    d = [BIG] * len(adj); d[s] = 0
    for _ in range(len(adj) - 1):
        for u in range(len(adj)):
            for v, w in adj[u]: d[v] = min(d[v], d[u] + w)
    return d
def kruskal(V, st, smart):                                 # heap-sort the streets; union-find the pieces
    par, rank, steps, hp, c, total = list(range(V)), [0] * V, [0, 0], [], [0], 0
    def find(x, k=0):                                      # steps: total parent steps, longest single lookup
        r = x
        while par[r] != r: r = par[r]; steps[0] += 1; k += 1; steps[1] = max(steps[1], k)
        while smart and par[x] != r: par[x], x = r, par[x]  # path compression: point straight at the root
        return r
    for i, e in enumerate(st): push(hp, (e[2], i), c)
    while hp:
        w, i = pop(hp, c); a, b = find(st[i][0]), find(st[i][1])
        if a == b: continue                                # same piece already: this street closes a loop
        if smart and rank[a] < rank[b]: a, b = b, a        # union by rank: short tree hangs under tall
        par[b] = a; total += w; rank[a] += smart and rank[a] == rank[b]
    return total, steps[0], c[0], steps[1], max(rank), all(find(v) == par[v] for v in range(V))  # last: compression flattens
def prim(adj):                                             # second road: grow one piece, no heap, no sort
    best, inn, total = [BIG] * len(adj), [False] * len(adj), 0; best[0] = 0
    for _ in adj:
        u = min((best[v], v) for v in range(len(adj)) if not inn[v])[1]; inn[u] = True; total += best[u]
        for v, w in adj[u]:
            if not inn[v] and w < best[v]: best[v] = w
    return total
def tarjan(out):                                           # one depth-first pass with low-link numbers
    n = len(out); num, low, on, stack, comps, cnt = [-1] * n, [0] * n, [False] * n, [], [], [0]
    def dfs(v):
        num[v] = low[v] = cnt[0]; cnt[0] += 1; stack.append(v); on[v] = True
        for u, _ in out[v]:
            if num[u] < 0: dfs(u); low[v] = min(low[v], low[u])
            elif on[u]: low[v] = min(low[v], num[u])
        if low[v] == num[v]:                               # v was reached first in its piece: pop the piece
            comps.append([])
            while not comps[-1] or comps[-1][-1] != v: u = stack.pop(); on[u] = False; comps[-1].append(u)
    [dfs(v) for v in range(n) if num[v] < 0]
    return comps
def dinic(n, arcs, s, t, undo, one_path=False):           # level graph, then a blocking flow, then again
    to, cap, g = [], [], [[] for _ in range(n)]
    for u, v, c in arcs: g[u] += [len(to)]; g[v] += [len(to) + 1]; to += [v, u]; cap += [c, c]
    total, phases = 0, 0
    while True:
        lev, q = [-1] * n, [s]; lev[s] = 0
        for u in q:
            for a in g[u]:
                if cap[a] > 0 and lev[to[a]] < 0: lev[to[a]] = lev[u] + 1; q.append(to[a])
        if lev[t] < 0: return total, phases, [x >= 0 for x in lev]
        phases += 1; it = [0] * n
        def dfs(u, f):                                     # walk only level k -> k+1; it[u] skips dead arcs
            if u == t: return f
            while it[u] < len(g[u]):
                a = g[u][it[u]]
                if cap[a] > 0 and lev[to[a]] == lev[u] + 1:
                    got = dfs(to[a], min(f, cap[a]))
                    if got: cap[a] -= got; cap[a ^ 1] += got * undo; return got
                it[u] += 1
            return 0
        while (f := dfs(s, BIG)):
            total += f
            if one_path: break                             # one shortest path per round: Edmonds-Karp
W, H = 40, 30; V = W * H; st, adj = city(W, H); E = len(st); s, t = 20 * W + 8, 10 * W + 26
blocks = lambda a, b: abs(a % W - b % W) + abs(a // W - b // W)
print(f"city,{V} stations,{E} streets,{sum(e[4] for e in st)} one-way,trip ({s % W},{s // W}) to ({t % W},{t // W}),{blocks(s, t)} blocks")
d0, _, looks = bfs(adj, 0); db, back, _ = bfs(adj, s); x, sec = t, 0
while x != s: sec += min(w for v, w in adj[back[x]] if v == x); x = back[x]
print(f"bfs,arc looks {looks} = 2 x {E},pops {V},V + 2E {V + 2 * E},fewest streets equals blocks for all {V},{all(d0[v] == blocks(0, v) for v in range(V))}")
dk, sk, pk, ck = astar(adj, s, t, lambda v: 0); dall, _, pall, call = astar(adj, s, -1, lambda v: 0); bf = bellman(adj, s)
da, sa, pa, ca = astar(adj, s, t, lambda v: 60 * blocks(v, t)); dx, sx, _, _ = astar(adj, s, t, lambda v: 180 * blocks(v, t))
print(f"dijkstra,trip {dk[t]} s = {dk[t] / 60:.1f} min,settled {sk},pushes {pk},swaps {ck}\ndijkstra all {V},pushes {pall},swaps {call},equals bellman-ford on all {V},{dall == bf}")
print(f"astar h = 60 x blocks,trip {da[t]} s,settled {sa},pushes {pa},swaps {ca},settles {sk / sa:.1f} times fewer")
print(f"mistake,fewest streets,{db[t]} streets,{sec} s = {sec / 60:.1f} min\nmistake,astar h = 180 x blocks,trip {dx[t]} s = {dx[t] / 60:.1f} min,settled {sx}")
k1, f1, c1, deep, top, flat = kruskal(V, st, True); k0, f0 = kruskal(V, st, False)[:2]; pr = prim(adj)
print(f"kruskal,{V - 1} streets,{k1} riding s = {k1 * 5 / 1000:.1f} km at 5 m/s,heap swaps {c1},find steps {f1},longest find {deep},top rank {top},prim {pr}\nmistake,union-find plain links,{k0} riding s,find steps {f0},{f0 / f1:.1f} times more")
out, inn = [[] for _ in range(V)], [[] for _ in range(V)]
for u, v, w, c, o in st:
    out[u].append((v, 0)); inn[v].append((u, 0))
    if not o: out[v].append((u, 0)); inn[u].append((v, 0))
comps, lab = tarjan(out), [-1] * V; big = max(len(c) for c in comps)
for v in range(V):
    if lab[v] < 0:                                         # second road: reached forwards and backwards
        fw, bw = bfs(out, v)[0], bfs(inn, v)[0]; lab = [v if fw[u] >= 0 <= bw[u] else lab[u] for u in range(V)]
lab2 = {u: min(c) for c in comps for u in c}
print(f"tarjan,arcs {sum(len(a) for a in out)},pieces {len(comps)},largest {big},sizes outside it {[len(c) for c in comps if len(c) < big]}")
arcs = [(u, v, c) for u, v, w, c, o in st] + [a for y in range(H) for a in ((V, y * W, BIG), (y * W + W - 1, V + 1, BIG))]
F, ph, side = dinic(V + 2, arcs, V, V + 1, 1); Fek, aug, _ = dinic(V + 2, arcs, V, V + 1, 1, True)
Fno, _, _ = dinic(V + 2, arcs, V, V + 1, 0); cut = sum(c for u, v, c in arcs if side[u] != side[v])
print(f"dinic,west edge to east edge {F} bikes/h,phases {ph},edmonds-karp {Fek} in {aug} paths,cut {cut}\nmistake,no undo,{Fno} bikes/h")
for w2, h2 in ((20, 15), (40, 30), (80, 60)):
    st2, adj2 = city(w2, h2); V2, E2 = w2 * h2, len(st2); _, _, lk = bfs(adj2, 0); _, _, p2, c2 = astar(adj2, 0, -1, lambda v: 0)
    print(f"growth,V {V2},E {E2},bfs looks {lk},heap work {2 * p2 + c2},(V+E) log2 V {(V2 + E2) * math.log2(V2):.0f},per (V+E) log2 V {(2 * p2 + c2) / ((V2 + E2) * math.log2(V2)):.3f}")
assert all(d0[v] == blocks(0, v) for v in range(V)) and looks == 2 * E   # queue against the block count
assert sk == 1 + sum((bf[v], v) < (bf[t], t) for v in range(V)) and dall == bf and da[t] == bf[t] and sa < sk and dx[t] > bf[t] and sec > bf[t]   # heap against Bellman-Ford
assert k1 == pr and f0 > 10 * f1 and deep <= top <= math.log2(V) and flat and lab == [lab2[u] for u in range(V)]  # Kruskal against Prim; union-find's rules; Tarjan against two-way reach
assert F == Fek == cut and Fno < F                         # a flow equal to a cut is a maximum flow
print("ALL CHECKS PASS")
