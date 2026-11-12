# Centrality and PageRank -- the check behind the card.  Standard library only.
# Ten bike stations (synthetic; the standard kite test network).  Four ideas of "hub",
# each reached by two roads; PageRank by three.  Nothing imported knows the answer.
NAMES = ["Arcade", "Bus Station", "Cathedral", "Market", "East Gate",
         "Fountain", "Guildhall", "Hill Top", "Riverside", "Quay"]
LINKS = "AB AC AM AF BM BE BG CM CF ME MF MG EG FG FH GH HR RQ".split()
ONE_WAY = ["HR"]                        # riders go down the hill, never up it
KEY = "ABCMEFGHRQ"
n, m = len(KEY), len(LINKS); pairs = [(KEY.index(l[0]), KEY.index(l[1])) for l in LINKS]
nbr = [[] for _ in range(n)]
for i, j in pairs:
    nbr[i].append(j); nbr[j].append(i)
f3 = lambda xs: " ".join(f"{x:6}" if type(x) is int else f"{x:6.3f}" for x in xs)
def row(label, xs): print(f"{label:<21}" + f3(xs))

def splitmix(state):                    # SplitMix64, seed 2026
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & (2**64 - 1)
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return z ^ (z >> 31)

def trips(oneway):                      # where a bike can go next, by the trip logs
    out = [[] for _ in range(n)]
    for (i, j), l in zip(pairs, LINKS):
        out[i].append(j); out[j] += [] if l in oneway else [i]
    return out

def pagerank_iter(out, alpha, steps=200):
    p = [1 / n] * n
    for _ in range(steps):
        q = [(1 - alpha) / n] * n
        for i in range(n):
            for j in out[i]: q[j] += alpha * p[i] / len(out[i])
        p = q
    return p

def pagerank_solve(out, alpha):         # (I - alpha P^T) pi = (1-alpha)/n, last row: sum = 1
    M = [[(1.0 if i == j else 0.0) - (alpha / len(out[j]) if i in out[j] else 0.0)
          for j in range(n)] + [(1 - alpha) / n] for i in range(n)]
    M[n - 1] = [1.0] * n + [1.0]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                k = M[r][c] / M[c][c]; M[r] = [a - k * b for a, b in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

print(f"{'station':<21}" + "".join(f"{c:>7}" for c in KEY))
# ---- degree: row sums of A, and a count down the link list ----
A = [[1 if j in nbr[i] else 0 for j in range(n)] for i in range(n)]; deg = [sum(r) for r in A]
assert deg == [sum(l.count(c) for l in LINKS) for c in KEY] and sum(deg) == 2 * m
row("degree", deg); row("degree / (n-1)", [d / (n - 1) for d in deg])

# ---- distances: breadth-first search, and powers of A ----
def bfs(s):
    d, order, sig, pred = [-1] * n, [s], [0] * n, [[] for _ in range(n)]; d[s], sig[s] = 0, 1
    for u in order:
        for v in nbr[u]:
            work[0] += 1
            if d[v] < 0: d[v] = d[u] + 1; order.append(v)
            if d[v] == d[u] + 1: sig[v] += sig[u]; pred[v].append(u)
    return d, order, sig, pred
work = [0]; dist = [bfs(s)[0] for s in range(n)]
dpow, Ak = [[0 if i == j else -1 for j in range(n)] for i in range(n)], A
for k in range(1, n):
    for i in range(n):
        for j in range(n):
            if dpow[i][j] < 0 and Ak[i][j] > 0: dpow[i][j] = k
    Ak = [[sum(Ak[i][t] * A[t][j] for t in range(n)) for j in range(n)] for i in range(n)]
assert dpow == dist
far = [sum(r) for r in dist]; clo = [(n - 1) / f for f in far]
row("distance sum", far); row("closeness", clo); print("distance from F:", " ".join(map(str, dist[5])), "; sigma M-H", bfs(3)[2][7])

# ---- betweenness: the backward pass, and every shortest route listed ----
def backward_pass():                          # each route's credit, passed back from its far end
    b = [0.0] * n
    for s in range(n):
        d, order, sig, pred = bfs(s); delta = [0.0] * n
        for w in reversed(order):
            for v in pred[w]: delta[v] += sig[v] / sig[w] * (1 + delta[w])
            if w != s: b[w] += delta[w] / 2
    return b
work[0] = 0; bet = backward_pass()
assert work[0] == n * 2 * m
def routes(s, t):                       # every shortest route s -> t, walked by distance
    if s == t: return [[t]]
    return [[s] + r for v in nbr[s] if dist[v][t] == dist[s][t] - 1 for r in routes(v, t)]
brute, first, listed, fparts = [0.0] * n, [0] * n, 0, []
for s in range(n):
    for t in range(s + 1, n):
        rs = routes(s, t); listed += len(rs)
        for v in range(n):
            x = sum(v in r[1:-1] for r in rs) / len(rs); brute[v] += x
            first[v] += v in rs[0][1:-1]
            if v == 5 and x: fparts.append(f"{KEY[s]}{KEY[t]} {x:.3f}")
assert max(abs(a - b) for a, b in zip(bet, brute)) < 1e-12
row("betweenness", bet); print("Fountain's pairs:", " ".join(fparts))
print("backward-pass route checks", work[0], "= n * 2m; shortest routes listed", listed)
print("n", n, "m", m, "n-1", n - 1, "2m", 2 * m, "pairs", n * (n - 1) // 2, "; without Hill Top", (n - 1) * (n - 2) // 2, "; town x river", 7 * 2)

# ---- PageRank: iterate, solve, and follow 20,000 bikes ----
out = trips(ONE_WAY); pr, prs = pagerank_iter(out, 0.85), pagerank_solve(out, 0.85)
assert max(abs(a - b) for a, b in zip(pr, prs)) < 1e-12 and abs(sum(pr) - 1) < 1e-12
st, count, bikes = [2026], [0] * n, 20000
for b in range(bikes):
    i = splitmix(st) % n
    for _ in range(50):
        if (splitmix(st) >> 11) / 2**53 < 0.85: i = out[i][splitmix(st) % len(out[i])]
        else: i = splitmix(st) % n
    count[i] += 1
sim = [c / bikes for c in count]
assert all(abs(s - p) < 4 * (p * (1 - p) / bikes) ** 0.5 for s, p in zip(sim, pr))
row("PageRank, one-way", pr); row("simulated bikes", sim)
h3, back = pr[7] / 3, 0.015 + 0.85 * (pr[7] / 3 + pr[9]); assert abs(back - pr[8]) < 1e-12
print(f"Riverside in: {pr[7]:.6f} / 3 = {h3:.6f}; 0.015 + 0.85 * ({h3:.6f} + {pr[9]:.6f})"
      f" = 0.015 + 0.85 * {h3 + pr[9]:.6f} = 0.015 + {0.85 * (h3 + pr[9]):.6f} = {back:.6f}")
two = pagerank_iter(trips([]), 0.85); row("PageRank, two-way", two); row("degree / 2m", [d / (2 * m) for d in deg])
assert max(range(n), key=lambda i: two[i]) == max(range(n), key=lambda i: deg[i])
win = lambda xs: " ".join(NAMES[i] for i in range(n) if abs(xs[i] - max(xs)) < 1e-9)
for lab, xs in [("degree", deg), ("closeness", clo), ("betweenness", bet), ("PageRank", pr)]:
    print(f"winner by {lab}: {win(xs)}")
assert win(deg) == "Market" and win(bet) == "Hill Top" and win(pr) == "Riverside"
assert win(clo) == "Fountain Guildhall" and abs(bet[7] - 14) < 1e-12

# ---- what breaks ----
row("one route per pair", first)
print("biggest distance sum:", win(far))
nod = pagerank_solve(out, 1.0); row("no jumps (0.85 -> 1)", nod)
assert abs(nod[8] - 0.5) < 1e-12 and max(nod[:8]) < 1e-12

# ---- try changing ----
LINKS.append("FR"); pairs.append((5, 8)); nbr[5].append(8); nbr[8].append(5)
row("betweenness + F-R", backward_pass())
row("PageRank + F-R", pagerank_iter(trips(ONE_WAY), 0.85))
LINKS.pop(); pairs.pop(); nbr[5].pop(); nbr[8].pop()
row("PageRank, 0.5", pagerank_iter(out, 0.5))
print("figure, A 60 40, B 150 40, C 25 110, M 105 110, E 190 110, F 60 170, "
      "G 150 170, H 105 220, R 215 220, Q 320 220")
print("ALL CHECKS PASS")
