# Persistence diagram and stability -- the check behind the card.  Standard library only.
# Sixteen daily closes of one share, in cents: an illustrative path, not real data.  A day
# joins the shape once the price level t reaches its close; two neighbouring days link once
# t reaches both.  Diagrams come two ways (column reduction mod 2, and union-find); distances
# between diagrams come two ways (an exact table over subsets, and every matching by brute force).
F = [9000, 9240, 9190, 9510, 9730, 9680, 10150, 10400,
     9920, 9600, 9870, 9810, 10190, 10360, 10320, 10500]
NOISE, SEED, DRAWS, M64 = 30, 10, 1000, (1 << 64) - 1     # every close off by 30 cents at most

def dgm_reduce(f):          # road 1: sort the cells, reduce each link's column mod 2
    cells = sorted([(f[i], 0, i) for i in range(len(f))] +
                   [(max(f[i], f[i + 1]), 1, i) for i in range(len(f) - 1)])
    pos = {(dim, i): k for k, (_, dim, i) in enumerate(cells)}
    low_of, pts = {}, []
    for t, dim, i in cells:
        if dim == 1:
            col = {pos[(0, i)], pos[(0, i + 1)]}
            while max(col) in low_of:
                col ^= low_of[max(col)]
            low_of[max(col)] = col
            if cells[max(col)][0] < t:                     # a bar of length zero is not drawn
                pts.append((cells[max(col)][0], t))
    ess = [(t, None) for k, (t, dim, i) in enumerate(cells) if dim == 0 and k not in low_of]
    return sorted(pts) + ess

def dgm_unionfind(f):       # road 2: add days lowest first; when two runs meet, the younger dies
    parent, pts = {}, []
    def root(i):
        while parent[i] != i:
            i = parent[i]
        return i
    for t, i in sorted((v, i) for i, v in enumerate(f)):
        parent[i] = i
        for j in (i - 1, i + 1):
            if j in parent and root(i) != root(j):
                old, young = sorted([root(i), root(j)], key=lambda r: (f[r], r))
                if f[young] < t:
                    pts.append((f[young], t))
                parent[young] = old
    return sorted(pts) + [(f[root(0)], None)]

def cost(x, y, line=False):  # half-cents: worst-case distance, or (line=True) straight-line squared
    if line:
        return 4 * ((x[0] - y[0]) ** 2 + (x[1] - y[1]) ** 2)
    return 2 * max(abs(x[0] - y[0]), abs(x[1] - y[1]))
def diag(x, line=False):    # to the diagonal: (d - b) / 2 worst-case, or (d - b) / root 2, squared
    return 2 * (x[1] - x[0]) ** 2 if line else x[1] - x[0]

def assign(A, B, op, line=False):  # road 1: the assignment problem, padded with diagonal copies,
    n, m, INF = len(A), len(B), float('inf')         # solved exactly by a table over subsets
    c = [[None] * (n + m) for _ in range(n + m)]
    for i in range(n):
        for j in range(m):
            c[i][j] = cost(A[i], B[j], line)
        c[i][m + i] = diag(A[i], line)
    for j in range(m):
        c[n + j][j] = diag(B[j], line)
        for i in range(n):
            c[n + j][m + i] = 0
    best = [0] + [INF] * ((1 << (n + m)) - 1)
    for mask in range(1 << (n + m)):
        r = bin(mask).count('1')
        for j in range(n + m):
            if r < n + m and best[mask] < INF and not mask >> j & 1 and c[r][j] is not None:
                best[mask | 1 << j] = min(best[mask | 1 << j], op(best[mask], c[r][j]))
    return best[-1]

def brute(A, B, used=(), k=0):   # road 2: every partial matching, as (worst, sum, sum of squares)
    if k == len(A):
        rest = [diag(y) for j, y in enumerate(B) if j not in used]
        return [(max(rest, default=0), sum(rest), sum(v * v for v in rest))]
    out = []
    for j in [None] + [j for j in range(len(B)) if j not in used]:
        v = diag(A[k]) if j is None else cost(A[k], B[j])
        for w, s, q in brute(A, B, used + ((j,) if j is not None else ()), k + 1):
            out.append((max(w, v), s + v, q + v * v))
    return out

def dist(D, E, op=max, line=False):  # the infinite bars are matched to each other, apart
    e = 2 * abs(D[-1][0] - E[-1][0])
    e, a = (e * e if line or op is sq else e), assign(D[:-1], E[:-1], op, line)
    return max(e, a) if op is max else e + a

add, sq = (lambda a, v: a + v), (lambda a, v: a + v * v)
def noisy(f, s):            # SplitMix64: each close moved by whole cents in [-NOISE, NOISE]
    g = []
    for v in f:
        s = (s + 0x9E3779B97F4A7C15) & M64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        g.append(v + (z ^ (z >> 31)) % (2 * NOISE + 1) - NOISE)
    return g, s

usd, hc = (lambda c: f"{c // 100}.{c % 100:02d}"), (lambda h: f"{h * 5 // 1000}.{h * 5 % 1000:03d}")
show = lambda D: " ".join(f"({usd(b)}, {'inf' if d is None else usd(d)})" for b, d in D)
gap = lambda f, g: max(abs(a - b) for a, b in zip(f, g))
D, (g, s) = dgm_reduce(F), noisy(F, SEED)
E = dgm_reduce(g)
print("feed 1 closes", " ".join(usd(v) for v in F))
print("feed 1 diagram", show(D))
for b, d in D[:-1]:              # hc turns half-cents into dollars
    print(f"  ({usd(b)}, {usd(d)}) lasts {usd(d - b)}, from the diagonal {hc(diag((b, d)))},"
          f" nearest feed 2 point {hc(min(cost((b, d), q) for q in E[:-1]))}")
print("bars longer than 0.30:", sum(d - b > NOISE for b, d in D[:-1]),
      " longer than 0.60:", sum(d - b > 2 * NOISE for b, d in D[:-1]))
print("feed 2 closes", " ".join(usd(v) for v in g))
print("feed 2 diagram", show(E))
print("feed 2 from the diagonal", " ".join(hc(diag(q)) for q in E[:-1]), " infinite bars", usd(E[-1][0] - D[-1][0]), "apart")
print("largest gap between the feeds", usd(gap(F, g)))
bf, ee = brute(D[:-1], E[:-1]), 2 * abs(D[-1][0] - E[-1][0])    # ee: the infinite bars' cost
dB, W1, W2 = dist(D, E), dist(D, E, add), dist(D, E, sq)
print("d_B  table", hc(dB), " brute force", hc(max(ee, min(w for w, _, _ in bf))))
print("W_1  table", hc(W1), " brute force", hc(ee + min(t for _, t, _ in bf)))
print(f"W_2  table {W2 ** 0.5 / 200:.3f}  matchings tried by brute force {len(bf)}")
line = dist(D, E, max, True)
print(f"wrong: straight-line d_B {line ** 0.5 / 200:.3f}, above the 0.30 bound")
worst, moved = 0.0, 0
for _ in range(DRAWS):                       # the theorem, checked on DRAWS noisy feeds
    h, s = noisy(F, s)
    Dh = dgm_reduce(h)
    assert Dh == dgm_unionfind(h) and dist(D, Dh) <= 2 * gap(F, h)
    worst, moved = max(worst, dist(D, Dh) / (2 * gap(F, h))), moved + (len(Dh) != len(D))
print(f"{DRAWS} feeds: worst d_B / gap {worst:.3f}, diagrams with a changed point count {moved}")
Da = dgm_reduce(F[:10] + [F[10] - 30, F[11] + 30] + F[12:])   # 30 cents down on day 10, up on day 11
print("nudged feed diagram", show(Da), " d_B", hc(dist(D, Da)))
print("wrong: no diagonal, so counts must match:", len(D) - 1, "points against", len(Da) - 1)
bad = F[:4] + [F[4] - 600] + F[5:]                 # one close recorded $6 low
Db = dgm_reduce(bad)
print("bad-tick diagram", show(Db), " d_B", hc(dist(D, Db)), " gap", usd(gap(F, bad)))
px = lambda D: " ".join(f"({(600 + 2 * (b - 8900)) / 10:.1f},{35 if d is None else (4000 - 2 * (d - 8900)) / 10:.1f})" for b, d in D)
print("figure, feed 1 at", px(D))
print("figure, feed 2 at", px(E))
assert D == dgm_unionfind(F) and E == dgm_unionfind(g)                 # two roads to each diagram
assert D[1] == (9600, 10400) and D[-1] == (9000, None) and len(D) == 6   # read off the path by hand
assert dB == max(ee, min(w for w, _, _ in bf)) == 52 and dB <= 2 * gap(F, g)  # 0.26 by hand, under 0.30
assert W1 == ee + min(t for _, t, _ in bf) and W2 == ee * ee + min(q for _, _, q in bf)  # table = brute
assert dist(D, Da) == 2 * NOISE and len(Da) == len(D) - 1                # the bound is reached exactly
assert line > (2 * gap(F, g)) ** 2 and W1 > 2 * gap(F, g)                # the two wrong readings exceed it
assert diag(Db[0]) > 2 * NOISE and dist(D, Db) <= 2 * gap(F, bad)        # a fake dip, yet within 6.00
print("ALL CHECKS PASS")
