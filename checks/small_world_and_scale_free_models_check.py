# Small worlds and hubs -- the check behind the card.  Standard library only.
# Synthetic networks of 5,000 people with about 10 friends each, drawn from
# SplitMix64 written out below.  Roads: closed forms, exact counts, seeded runs.
from math import log, exp
MASK, N, H, M = (1 << 64) - 1, 5000, 5, 5     # people; ring neighbours each side; links per newcomer
GAMMA = 0.5772156649015329                    # Euler's constant, for the path-length formula
st = [0]
def rnd():                                    # SplitMix64: a uniform number in [0, 1)
    st[0] = (st[0] + 0x9E3779B97F4A7C15) & MASK
    z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def pick(n): return int(rnd() * n)            # a whole number from 0 to n - 1
def link(adj, a, b): adj[a].add(b); adj[b].add(a)

def ring(n, h):                               # everyone joined to the h nearest on each side
    adj = [set() for _ in range(n)]
    for i in range(n):
        for j in range(1, h + 1): link(adj, i, (i + j) % n)
    return adj
def watts_strogatz(n, h, beta, seed):         # ring, then each link's far end moved with chance beta
    st[0] = seed; adj = ring(n, h)
    for i in range(n):
        for j in range(1, h + 1):
            if rnd() < beta:
                t = pick(n)
                while t == i or t in adj[i]: t = pick(n)
                old = (i + j) % n
                adj[i].discard(old); adj[old].discard(i); link(adj, i, t)
    return adj
def erdos_renyi(n, m, seed):                  # exactly m links, each a uniformly random new pair
    st[0] = seed; adj = [set() for _ in range(n)]; made = 0
    while made < m:
        a, b = pick(n), pick(n)
        if a != b and b not in adj[a]: link(adj, a, b); made += 1
    return adj
def grow(n, m, seed, by_degree):              # newcomers bring m links each
    st[0] = seed; adj = [set() for _ in range(n)]; ends = []
    for a in range(m + 1):                    # start: m + 1 people, all friends
        for b in range(a): link(adj, a, b); ends += [a, b]
    for v in range(m + 1, n):
        chosen = []
        while len(chosen) < m:                # a random link end picks a person in proportion to degree
            t = ends[pick(len(ends))] if by_degree else pick(v)
            if t not in chosen: chosen.append(t)
        for t in chosen: link(adj, v, t); ends += [v, t]
    return adj

def clustering(adj):                          # average share of a person's friend pairs who are friends
    total = 0.0
    for v in range(len(adj)):
        k = len(adj[v])
        if k < 2: continue
        tri = sum(len(adj[u] & adj[v]) for u in adj[v]) // 2
        total += tri / (k * (k - 1) / 2)
    return total / len(adj)
def paths(adj, step=10):                      # breadth-first search from every 10th person
    tot = cnt = near = srcs = 0
    for s in range(0, len(adj), step):
        dist = [-1] * len(adj); dist[s] = 0; q = [s]; i = 0; srcs += 1
        while i < len(q):
            u = q[i]; i += 1
            for w in adj[u]:
                if dist[w] < 0: dist[w] = dist[u] + 1; q.append(w)
        for d in dist:
            if d > 0: tot += d; cnt += 1; near += d <= 6
    return tot / cnt, near / cnt, cnt / (srcs * (len(adj) - 1))
def measure(adj):
    deg = [len(a) for a in adj]
    L, six, reach = paths(adj)
    return dict(k=sum(deg) / len(deg), C=clustering(adj), L=L, six=six, reach=reach, mx=max(deg),
                k20=sum(d >= 20 for d in deg), k50=sum(d >= 50 for d in deg), deg=deg)

er, ba, un = measure(erdos_renyi(N, 25000, 1)), measure(grow(N, M, 2, True)), measure(grow(N, M, 2, False))
sweep = [0, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1.0]
ws = {b: measure(watts_strogatz(N, H, b, 3)) for b in sweep}
print("5,000 synthetic people; paths from every 10th person (500 searches)")
print(f"{'model':<24}{'mean k':>7}{'C':>8}{'L':>9}{'<=6':>8}{'max k':>6}{'k>=20':>6}{'k>=50':>6}")
for name, r in (("ER, 25,000 links", er), ("WS ring, beta = 0", ws[0]), ("WS beta = 0.01", ws[0.01]),
                ("WS beta = 0.1", ws[0.1]), ("BA, m = 5", ba), ("growth, no preference", un)):
    print(f"{name:<24}{r['k']:7.3f}{r['C']:8.4f}{r['L']:9.3f}{r['six']:8.4f}{r['mx']:6d}{r['k20']:6d}{r['k50']:6d}")

c0 = 3 * (H - 1) / (2 * (2 * H - 1))                              # ring clustering, by counting triangles
l0 = sum((min(d, N - d) + H - 1) // H for d in range(1, N)) / (N - 1)   # ring path length, every offset
p = 2 * 25000 / (N * (N - 1))                                       # ER: chance a given pair is linked
kbar = 2 * 25000 / N
l_er = (log(N) - GAMMA) / log(kbar) + 0.5                          # ER path-length formula
pois, term = 0.0, exp(-kbar)                                       # Poisson(10): chance of under 20
for k in range(20): pois += term; term *= kbar / (k + 1)
tail = lambda k: M * (M + 1) / (k * (k + 1))                       # BA: share with k or more friends
fr = lambda r: sum(d * d for d in r['deg']) / sum(r['deg'])         # average friend's friend count
rows = [("by hand: links n<k>/2", N * kbar / 2), ("by hand: ln n", log(N)), ("by hand: ln<k>", log(kbar)), ("by hand: gamma", GAMMA),
        ("ring linked friend pairs", 3 * H * (H - 1) / 2), ("ring friend pairs h(2h-1)", H * (2 * H - 1)),
        ("shortcuts n h beta, 0.01", N * H * 0.01), ("shortcuts n h beta, 0.1", N * H * 0.1), ("(1-beta)^3 at 0.1", 0.9 ** 3),
        ("ring C, counted", ws[0]['C']), ("  3(h-1)/(2(2h-1))", c0),
        ("ring L, by search", ws[0]['L']), ("  exact sum over offsets", l0), ("  rough n/(4h)", N / (4 * H)),
        ("WS 0.01 C", ws[0.01]['C']), ("  C0 (1-beta)^3", c0 * 0.99 ** 3),
        ("WS 0.1 C", ws[0.1]['C']), ("  C0 (1-beta)^3", c0 * 0.9 ** 3),
        ("ER C", er['C']), ("  p = <k>/(n-1)", p),
        ("ER L", er['L']), ("  (ln n - gamma)/ln<k> + 1/2", l_er), ("  wrong: ln n / ln<k>", log(N) / log(kbar)),
        ("ER people with k>=20", er['k20']), ("  Poisson(10) expects", N * (1 - pois)),
        ("BA share k>=20", ba['k20'] / N), ("  m(m+1)/(k(k+1))", tail(20)), ("  n m(m+1)/(k(k+1))", N * tail(20)),
        ("BA people with k>=50", ba['k50']), ("  n m(m+1)/(k(k+1))", N * tail(50)),
        ("no-preference people k>=20", un['k20']), ("  long run n (m/(m+1))^15", N * (M / (M + 1)) ** 15),
        ("no-preference people k>=50", un['k50']), ("  oldest expects m + sum m/v", M + sum(M / v for v in range(M + 1, N))),
        ("BA average friend's k", fr(ba)), ("ER average friend's k", fr(er)),
        ("wrong: BA mean k taken as m", M)]
for name, v in rows: print(f"{name:<32}{v:12.4f}")
print("chart, beta      " + " ".join(f"{b:>6}" for b in sweep))
print("chart, C/C0      " + " ".join(f"{ws[b]['C'] / ws[0]['C']:6.3f}" for b in sweep))
print("chart, L/L0      " + " ".join(f"{ws[b]['L'] / ws[0]['L']:6.3f}" for b in sweep))
print("chart, L         " + " ".join(f"{ws[b]['L']:6.2f}" for b in sweep))
t1, t2, t3 = measure(erdos_renyi(N, 10000, 4)), measure(grow(N, 2, 5, True)), measure(watts_strogatz(N, 2, 0.01, 6))
print(f"try: ER 10,000 links   L {t1['L']:.3f}  formula {(log(N) - GAMMA) / log(4) + 0.5:.3f}  reached {t1['reach']:.4f}")
print(f"try: BA m = 2          L {t2['L']:.3f}  max k {t2['mx']}  k>=50 {t2['k50']}")
print(f"try: WS h = 2, 0.01    L {t3['L']:.3f}  C {t3['C']:.4f}  <=6 {t3['six']:.4f}")

assert abs(ws[0]['C'] - 2 / 3) < 1e-12, "ring clustering must be exactly 2/3"
assert abs(ws[0]['L'] - l0) < 1e-9, "ring search must equal the exact offset sum"
assert abs(ws[0.1]['C'] - c0 * 0.9 ** 3) < 0.02, "rewired clustering vs triangles surviving"
assert abs(er['C'] - p) < 0.0005, "ER clustering vs p"
assert abs(er['L'] - l_er) < 0.1, "ER path length vs formula"
assert abs(ba['k20'] / N - tail(20)) < 0.015, "BA degree tail vs m(m+1)/(k(k+1))"
assert abs(ba['k50'] - N * tail(50)) < 20, "BA hub count vs the tail formula"
assert ws[0.1]['C'] > 100 * er['C'] and ws[0.1]['L'] < 1.5 * er['L'], "small world: clustered and short"
assert er['reach'] == 1.0 and ba['reach'] == 1.0, "networks must be in one piece"
print("ALL CHECKS PASS")
