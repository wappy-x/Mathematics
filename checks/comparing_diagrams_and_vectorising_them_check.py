# Comparing persistence diagrams -- the check behind the card.  Nothing is
# imported but math.  Two SIMULATED months of daily returns (basis points,
# SplitMix64 seed 36) become clouds of three-day windows under the largest-
# single-day-gap distance.  Their H1 bars (Rips, scale r = ball radius, over Z
# mod 2) are compared by bottleneck distance two ways (threshold + matching,
# and every permutation), turned into landscapes and images, and given a
# bootstrap noise band.  Scales are held as integers in quarter basis points.
import math
M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(s, seed): s.x = seed
    def below(s, n):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64; z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (z ^ (z >> 31)) % n
def month(g, s): return [sum(g.below(2 * s + 1) - s for _ in range(4)) for _ in range(21)]
def windows(r): return [tuple(r[i:i + 3]) for i in range(len(r) - 2)]
def gap(p, q): return max(abs(a - b) for a, b in zip(p, q))
def pct(q): return "%s%d.%04d" % ("-" if q < 0 else "", abs(q) * 25 // 10000, abs(q) * 25 % 10000)
def h1_bars(X):  # an edge joins windows within 2r; bars kept as 4r in bp = 2 * gap
    n = len(X); E = sorted((gap(X[i], X[j]), i, j) for i in range(n) for j in range(i + 1, n))
    eid = {(i, j): k for k, (_, i, j) in enumerate(E)}
    T = sorted((max(E[e][0] for e in es), i, j, k, sorted(es)) for i in range(n)
               for j in range(i + 1, n) for k in range(j + 1, n)
               for es in [[eid[(i, j)], eid[(i, k)], eid[(j, k)]]])
    low, bars = {}, []
    for v, i, j, k, col in T:   # reduce each triangle's column of edges over Z mod 2
        while col and col[-1] in low: col = sorted(set(col) ^ set(low[col[-1]]))
        if col:
            low[col[-1]] = col
            if E[col[-1]][0] < v: bars.append((2 * E[col[-1]][0], 2 * v))
    return sorted(bars)
def augmented(P, Q):  # P's points + diagonal slots against Q's points + diagonal slots
    n, m = len(P), len(Q); C = [[0] * (n + m) for _ in range(n + m)]
    for i in range(n + m):
        for j in range(n + m):
            if i < n and j < m: C[i][j] = max(abs(P[i][0] - Q[j][0]), abs(P[i][1] - Q[j][1]))
            elif i < n: C[i][j] = (P[i][1] - P[i][0]) // 2
            elif j < m: C[i][j] = (Q[j][1] - Q[j][0]) // 2
    return C
def bottleneck(P, Q):  # road 1: smallest threshold that admits a perfect matching
    C = augmented(P, Q); k = len(C)
    for eps in sorted(set(v for row in C for v in row)):
        mate = [-1] * k
        def grow(i, seen):
            for j in range(k):
                if C[i][j] <= eps and j not in seen:
                    seen.add(j)
                    if mate[j] < 0 or grow(mate[j], seen): mate[j] = i; return True
            return False
        if all(grow(i, set()) for i in range(k)): return eps
def every_matching(C, i=0, used=(), worst=0, total=0, best=None):  # road 2: all n! pairings
    best = best if best is not None else [None, None, None]
    if i == len(C):
        if best[0] is None or worst < best[0]: best[0], best[2] = worst, used
        if best[1] is None or total < best[1]: best[1] = total
        return best
    for j in range(len(C)):
        if j not in used: every_matching(C, i + 1, used + (j,), max(worst, C[i][j]), total + C[i][j], best)
    return best
def betti1(X, D2):  # road 2 for the bars: loops alive at a diameter D2, by a fresh mod-2 rank
    n = len(X); E = [(i, j) for i in range(n) for j in range(i + 1, n) if gap(X[i], X[j]) <= D2]
    parent = list(range(n))
    def root(a): return a if parent[a] == a else root(parent[a])
    for i, j in E: parent[root(i)] = root(j)
    bit = {e: 1 << k for k, e in enumerate(E)}; basis = {}
    for i, j, k in ((i, j, k) for i in range(n) for j in range(i + 1, n) for k in range(j + 1, n)):
        if (i, k) in bit and (j, k) in bit and (i, j) in bit:
            v = bit[(i, j)] | bit[(i, k)] | bit[(j, k)]
            while v and v.bit_length() in basis: v ^= basis[v.bit_length()]
            if v: basis[v.bit_length()] = v
    return len(E) - n + sum(1 for a in range(n) if root(a) == a) - len(basis)
def landscape(D, k, t): return sorted([max(0, min(t - b, d - t)) for b, d in D] + [0, 0], reverse=True)[k - 1]
def image(D, two_var=0.02):  # 12 x 3 pixels of 0.1 percent; bump sd 0.1 percent; weight = persistence / 0.2, capped at 1
    px = []
    for row in range(3):
        for col in range(12):
            x, y = 0.05 + 0.1 * col, 0.05 + 0.1 * row
            px.append(sum(min((d - b) / 80, 1) * math.exp(-((x - b / 400) ** 2 + (y - (d - b) / 400) ** 2) / two_var) for b, d in D))
    return px

g = SplitMix64(36)
calm, storm = month(g, 50), month(g, 170)
Xa, Xb = windows(calm), windows(storm)
Da, Db = h1_bars(Xa), h1_bars(Xb)
for name, r, D in (("calm", calm, Da), ("storm", storm, Db)):
    sd = math.sqrt(sum(x * x for x in r) / len(r) - (sum(r) / len(r)) ** 2) / 100
    print("%-5s returns (bp): %s" % (name, " ".join(map(str, r))))
    print("%-5s daily sd %.2f%%, H1 bars (r, %%): %s" % (name, sd, "  ".join("[%s, %s)" % (pct(b), pct(d)) for b, d in D)))
for X, D in ((Xa, Da), (Xb, Db)):  # check the bars against a fresh count at every bar end
    for D2 in sorted({v // 2 for bar in D for v in bar} | {v // 2 - 1 for bar in D for v in bar}):
        assert betti1(X, D2) == sum(1 for b, d in D if b <= 2 * D2 < d), D2
C = augmented(Da, Db)
dB = bottleneck(Da, Db); worst, total, plan = every_matching(C)
print("half-lifetimes calm:", " ".join(pct(C[i][len(Db)]) for i in range(len(Da))), " storm:", " ".join(pct(C[len(Da)][j]) for j in range(len(Db))))
for i in range(len(Da)): print("cost A%d to B0 B1 B2: %s" % (i, " ".join(pct(C[i][j]) for j in range(len(Db)))))
print("bottleneck d_B: threshold road %s%%, all %d matchings %s%%" % (pct(dB), math.factorial(len(C)), pct(worst)))
print("best plan:", ", ".join("%s->%s cost %s" % ("A%d" % i if i < len(Da) else "diag", "B%d" % j if j < len(Db) else "diag", pct(C[i][j])) for i, j in enumerate(plan) if i < len(Da) or j < len(Db)))
print("Wasserstein W_1 (sum of costs) %s%%" % pct(total))
assert dB == worst == 40  # two roads, and the hand answer of 0.1000 percent
assert total == 111  # the hand W_1 of 0.2775 percent: pins every half-lifetime cost
no_diag = every_matching([[C[i][j] for j in range(len(Db))] for i in range(len(Da))])[0]
print("breaks, no diagonal %s%%; diameter scale %s%%; bar counts %d and %d" % (pct(no_diag), pct(2 * dB), len(Da), len(Db)))
grid = [10 * k for k in range(51)]
for name, D in (("calm", Da), ("storm", Db)):
    for k in (1, 2):
        print("chart, lambda%d %-5s %s" % (k, name, " ".join(pct(landscape(D, k, t)) for t in grid)))
sup = [max(abs(landscape(Da, k, t) - landscape(Db, k, t)) for t in grid) for k in (1, 2)]
print("landscape vector length %d; sup gaps lambda1 %s%%, lambda2 %s%% (both <= d_B)" % (2 * len(grid), pct(sup[0]), pct(sup[1])))
assert sup[0] <= dB and sup[1] <= dB
Ia, Ib = image(Da), image(Db)
for name, I in (("calm", Ia), ("storm", Ib)):
    for row in range(3): print("image %-5s row %d: %s" % (name, row, " ".join("%.3f" % v for v in I[12 * row:12 * row + 12])))
print("image vector length %d; distance between months %.4f" % (len(Ia), math.sqrt(sum((a - b) ** 2 for a, b in zip(Ia, Ib)))))
B, bands, checked, ratio = 1000, {}, 0, 0.0
for name, X, D in (("calm", Xa, Da), ("storm", Xb, Db)):
    ds = []
    for _ in range(B):
        Y = [X[i] for i in sorted(set(g.below(len(X)) for _ in range(len(X))))]
        ds.append(bottleneck(D, h1_bars(Y)))
        dH = max(min(gap(x, y) for y in Y) for x in X)
        assert ds[-1] <= 4 * dH; checked += 1; ratio = max(ratio, ds[-1] / (4 * dH or 1))  # stability: d_B <= d_H, both in r
    ds.sort(); bands[name] = (ds[949], ds[974], ds[989])
    feats = sum(1 for b, d in D if (d - b) // 2 > ds[949])
    loose = sum(1 for b, d in D if d - b > ds[949])
    print("%-5s band c at 95%% %s%%, at 97.5%% %s%%; features (lifetime > 2c) %d; with lifetime > c %d" % (name, pct(ds[949]), pct(ds[974]), feats, loose))
both = bands["calm"][1] + bands["storm"][1]
print("compare: d_B %s%% against c_calm + c_storm at 97.5%% = %s%% -> %s" % (pct(dB), pct(both), "differ" if dB > both else "not separated from noise"))
print("stability d_B <= d_H checked on %d resamples; largest d_B / d_H %.3f" % (checked, ratio))
blk = [sorted(bottleneck(D, h1_bars(sorted(set(windows(sum((r[s:s + 3] for s in [g.below(19) for _ in range(7)]), []))))))
              for _ in range(B))[949] for r, D in ((calm, Da), (storm, Db))]  # trap: resample 3-day blocks of days
print("trap, resampling 3-day blocks of days: band at 95%% calm %s%%, storm %s%%" % (pct(blk[0]), pct(blk[1])))
d3 = bottleneck([(3 * b, 3 * d) for b, d in Da], Db); both3 = 3 * bands["calm"][1] + bands["storm"][1]
print("try, calm x3: d_B %s%% against %s%%" % (pct(d3), pct(both3)))
print("try, 99%% bands: calm %s%%, storm %s%%" % (pct(bands["calm"][2]), pct(bands["storm"][2])))
print("try, image sd 0.05: distance %.4f" % math.sqrt(sum((a - b) ** 2 for a, b in zip(image(Da, 0.005), image(Db, 0.005)))))
print("figure, points (b, d) %%: %s" % " ".join("(%s, %s)" % (pct(b), pct(d)) for b, d in Da + Db))
print("figure, band lines d = b + 2c: 2c = %s%% and %s%%" % (pct(2 * bands["calm"][0]), pct(2 * bands["storm"][0])))
print("ALL CHECKS PASS")
