# Decision trees and forests -- the check behind the card.  Standard library only.
# Ten hand-made orders show one split by hand; 25,000 synthetic orders, drawn by
# SplitMix64 (seed 2026) from the rule in order(), test pruning, bagging and out-of-bag error.
from math import log2, exp
M64 = (1 << 64) - 1
class Rng:                                       # SplitMix64, written out
    def __init__(self, seed): self.s = seed
    def u(self):                                 # uniform in [0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def k(self, n): return int(self.u() * n)     # whole number 0 .. n-1
def p_return(x):                                 # the synthetic rule: chance an order comes back
    s = (0.05 * (x[0] - 1) + 0.004 * (x[1] - 5) + 0.12 * x[6] - 0.01 * min(x[2], 15) + 0.0015 * x[3]
         + 0.003 * x[7] - 0.002 * x[9] + 0.004 * (x[11] - x[0]))
    p = 2.6 * s - 0.51 + (0.2 if x[4] == 1 and x[5] >= 21 else 0.0)   # late-night phone orders
    return max(0.02, min(0.95, p))
def order(g):  # items, avg price, past orders, days since last, phone, hour, code, km, weekend, months, newsletter, viewed
    x = [1 + g.k(8), 5 + g.k(56), g.k(31), g.k(91), int(g.u() < 0.6), g.k(24),
         int(g.u() < 0.3), 1 + g.k(50), int(g.u() < 0.3), g.k(61), int(g.u() < 0.4), 0]
    x[11] = x[0] + g.k(20)
    return x, int(g.u() < p_return(x))
def grow(X, Y, idx, m, g, T, size, depth=99):   # node: [feature, cut, left, right, returned, orders]
    n = len(idx); a = sum(Y[i] for i in idx); me = len(T); T.append([-1, 0, 0, 0, a, n])
    if a == 0 or a == n or depth == 0: return me
    feats = list(range(len(size)))
    if m < len(size):                            # random feature choice: m of them, partial shuffle
        for j in range(m):
            r = j + g.k(len(size) - j); feats[j], feats[r] = feats[r], feats[j]
    best, bf, bt = 2 * a * (n - a) / n, -1, 0    # n times the node's Gini; a split must beat it
    for f in feats[:m]:
        ret, tot = [0] * size[f], [0] * size[f]
        for i in idx: tot[X[i][f]] += 1; ret[X[i][f]] += Y[i]
        aL = nL = 0
        for t in range(size[f] - 1):             # every cut "value <= t" in one sweep
            aL += ret[t]; nL += tot[t]; nR = n - nL
            if tot[t] == 0 or nL == 0: continue
            if nR == 0: break
            s = 2 * aL * (nL - aL) / nL + 2 * (a - aL) * (nR - a + aL) / nR
            if s < best: best, bf, bt = s, f, t
    if bf < 0: return me
    T[me][0], T[me][1] = bf, bt
    T[me][2] = grow(X, Y, [i for i in idx if X[i][bf] <= bt], m, g, T, size, depth - 1)
    T[me][3] = grow(X, Y, [i for i in idx if X[i][bf] > bt], m, g, T, size, depth - 1)
    return me
def prune(T, alpha):                             # cheapest pruned tree for this alpha, one backward sweep
    cut, cost, leaves = [False] * len(T), [0.0] * len(T), [1] * len(T)
    for k in range(len(T) - 1, -1, -1):          # children sit after parents, so go backwards
        own = min(T[k][4], T[k][5] - T[k][4]) + alpha
        if T[k][0] < 0 or own <= cost[T[k][2]] + cost[T[k][3]]: cut[k], cost[k] = True, own
        else: cost[k], leaves[k] = cost[T[k][2]] + cost[T[k][3]], leaves[T[k][2]] + leaves[T[k][3]]
    return cut, cost[0], leaves[0]
def vote(T, x, cut=None):
    k = 0
    while T[k][0] >= 0 and not (cut and cut[k]): k = T[k][2] if x[T[k][0]] <= T[k][1] else T[k][3]
    return int(2 * T[k][4] > T[k][5])
def err(T, X, Y, rows, cut=None): return sum(vote(T, X[i], cut) != Y[i] for i in rows) / len(rows)
def gini(a, n): return 1 - (a / n) * (a / n) - ((n - a) / n) * ((n - a) / n) if n else 0.0
def ent(a, n): return -sum(c / n * log2(c / n) for c in (a, n - a) if c) if n else 0.0
def weighted(f, rows, mask):                     # impurity of a two-group split, groups weighted by size
    L = [r[2] for r, s in zip(rows, mask) if s]; R = [r[2] for r, s in zip(rows, mask) if not s]
    return (len(L) * f(sum(L), len(L)) + len(R) * f(sum(R), len(R))) / len(rows)
def plain(rows, mask):                           # the mistake: the two groups' Gini, not weighted
    L = [r[2] for r, s in zip(rows, mask) if s]; R = [r[2] for r, s in zip(rows, mask) if not s]
    return (gini(sum(L), len(L)) + gini(sum(R), len(R))) / 2
# ---- ten orders: (basket in pounds, items, 1 = returned) ----
ten = [(62, 3, 1), (75, 4, 1), (88, 2, 1), (120, 5, 1), (45, 3, 1), (28, 4, 1),
       (22, 1, 0), (33, 1, 0), (40, 2, 0), (48, 3, 0)]
cuts = [(f, t) for f in (0, 1) for t in sorted({r[f] for r in ten})[:-1]]
masks = {c: [r[c[0]] > c[1] for r in ten] for c in cuts}
name = lambda c: f"{'basket' if c[0] == 0 else 'items'} > {c[1]}"
bg = min(cuts, key=lambda c: weighted(gini, ten, masks[c]))
be = min(cuts, key=lambda c: weighted(ent, ten, masks[c]))
bp = min(cuts, key=lambda c: plain(ten, masks[c]))
G0, H0, Gs, Hs = gini(6, 10), ent(6, 10), weighted(gini, ten, masks[bg]), weighted(ent, ten, masks[bg])
HS, HYS = ent(4, 10), -sum(q * log2(q) for q in (0.4, 0.2, 0.4))   # H(S) and H(Y, S)
allsplits = [[(b >> j) & 1 for j in range(10)] for b in range(1, 1023)]
print(f"ten orders: Gini {G0:.4f}, entropy {H0:.4f} bits")
print(f"best of {len(cuts)} cuts by Gini: {name(bg)}, weighted Gini {Gs:.4f}; by entropy: {name(be)}, {Hs:.4f} bits")
print(f"group 2:4: Gini {gini(2, 6):.4f}, entropy {ent(2, 6):.4f}; Gini drop {G0 - Gs:.4f}")
print(f"information gain {H0 - Hs:.4f} bits = H(Y) + H(S) - H(Y,S) = {H0 + HS - HYS:.4f}")
print(f"worst of all 1,022 yes/no labellings (511 splits): Gini {max(weighted(gini, ten, s) for s in allsplits):.4f}, "
      f"entropy {max(weighted(ent, ten, s) for s in allsplits):.4f}")
print(f"mistake, plain average: picks {name(bp)} at {plain(ten, masks[bp]):.4f} (basket cut "
      f"{plain(ten, masks[bg]):.4f}); its weighted Gini {weighted(gini, ten, masks[bp]):.4f}")
small = []; grow([r[:2] for r in ten], [r[2] for r in ten], list(range(10)), 2, None, small, [121, 6])
print("tree: " + "; ".join(f"node {k}: {'basket' if t[0] == 0 else 'items'} <= {t[1]}" if t[0] >= 0
      else f"node {k}: leaf {t[4]}:{t[5] - t[4]}" for k, t in enumerate(small)))
for alpha in (0.5, 1.5, 2.5): print(f"alpha {alpha}: leaves kept {prune(small, alpha)[2]}, cost {prune(small, alpha)[1]:.1f}")
def options(k):                                  # brute force: every pruned version as (errors, leaves)
    t = small[k]; mine = [(min(t[4], t[5] - t[4]), 1)]
    if t[0] < 0: return mine
    return mine + [(a + c, b + d) for a, b in options(t[2]) for c, d in options(t[3])]
brute = {al: min(e + al * l for e, l in options(0)) for al in (0.5, 1.5, 2.5)}
print("every pruned version, errors + 1.5 x leaves: " + ", ".join(f"leaves {l}: {e} + {1.5 * l:.1f} = {e + 1.5 * l:.1f}" for e, l in options(0)))
# ---- 25,000 synthetic orders: 16,000 grow, 4,000 choose alpha, 5,000 test ----
g = Rng(2026); data = [order(g) for _ in range(25000)]; X, Y = [d[0] for d in data], [d[1] for d in data]
SIZE, N, test = [9, 61, 31, 91, 2, 24, 2, 51, 2, 61, 2, 28], 20000, range(20000, 25000)
print(f"orders returned: {sum(Y[:N])} of {N}; best possible test error (rule known) "
      f"{sum(min(p_return(X[i]), 1 - p_return(X[i])) for i in test) / 5000:.4f}")
full = []; grow(X, Y, list(range(16000)), 12, g, full, SIZE)
tr_full, te_full = err(full, X, Y, range(16000)), err(full, X, Y, test)
print(f"full tree: {sum(t[0] < 0 for t in full)} leaves, training error {tr_full:.4f}, test error {te_full:.4f}")
val = {a: err(full, X, Y, range(16000, 20000), prune(full, a)[0]) for a in (0, 1, 2, 4, 8, 16, 32)}
ab = min(val, key=val.get); pc, _, pl = prune(full, ab); te_pruned = err(full, X, Y, test, pc)
print("pruning, held-out error by alpha: " + ", ".join(f"{a}: {v:.4f}" for a, v in val.items()))
print(f"pruned at alpha {ab}: {pl} leaves, test error {te_pruned:.4f}")
def forest(m, B, depth=99, show=()):
    tv, ov, on, tr, left = [0] * 25000, [0] * N, [0] * N, [0] * N, 0
    for b in range(1, B + 1):
        idx = [g.k(N) for _ in range(N)]; inbag = [0] * N
        for i in idx: inbag[i] = 1
        T = []; grow(X, Y, idx, m, g, T, SIZE, depth); left += N - sum(inbag)
        for i in range(N):
            v = vote(T, X[i]); tr[i] += v
            if not inbag[i]: ov[i] += v; on[i] += 1
        for i in test: tv[i] += vote(T, X[i])
        seen = [i for i in range(N) if on[i]]
        oob = sum((2 * ov[i] > on[i]) != Y[i] for i in seen) / len(seen)
        te = sum((2 * tv[i] > b) != Y[i] for i in test) / 5000
        if b in show: print(f"  {b} trees: out-of-bag error {oob:.4f}, test error {te:.4f}")
    q, c = sum(tv) / (5000 * B), sum(t * (t - 1) for t in tv) / (5000 * B * max(B - 1, 1))   # rho: pairs of trees, test orders
    return oob, te, sum((2 * tr[i] > B) != Y[i] for i in range(N)) / N, left / (B * N), (c - q * q) / (q - q * q)
print("random forest, 3 of 12 numbers per question:"); oob, te, tr_forest, share, rho = forest(3, 51, show=(1, 5, 11, 21, 31, 41, 51))
print(f"share of orders left out per tree {share:.4f}, so {share * 5:.1f} of 5 and {share * 51:.1f} of 51 trees per order; (1-1/n)^n = {(1 - 1 / N) ** N:.6f}, "
      f"1/e = {exp(-1):.6f}; n = 10: {0.9 ** 10:.4f}")
print(f"out-of-bag minus test, whole forest, {oob - te:.4f}; standard error of a 5,000-order test error {(te * (1 - te) / 5000) ** 0.5:.4f}")
print(f"mistake, forest scored on its own training orders: {tr_forest:.4f}")
bag = forest(12, 51); print(f"bagging alone, all 12 numbers: out-of-bag {bag[0]:.4f}, test {bag[1]:.4f}")
print(f"correlation of two trees' votes over the test orders: all 12 numbers {bag[4]:.2f}, 3 numbers {rho:.2f}")
stump1, stumps = forest(12, 1, 1)[1], forest(12, 51, 1)[1]; print(f"mistake, bagging one-question trees: 1 tree {stump1:.4f}, 51 trees {stumps:.4f}")
assert abs(G0 - 2 * 6 * 4 / 100) < 1e-12 and abs(Gs - 4 / 15) < 1e-12 and bg == (0, 48) == tuple(small[0][:2])
assert abs((H0 - Hs) - (H0 + HS - HYS)) < 1e-12 and be == bg and bp == (1, 1)
assert max(weighted(gini, ten, s) for s in allsplits) <= G0 + 1e-12 and max(weighted(ent, ten, s) for s in allsplits) <= H0 + 1e-12
assert all(abs(prune(small, a)[1] - brute[a]) < 1e-12 for a in brute)
assert abs(share - (1 - 1 / N) ** N) < 0.002 and abs(share - exp(-1)) < 0.002 and rho < bag[4] - 0.02
assert te < te_full - 0.04 and te < te_pruned and abs(oob - te) < 0.025 and te_pruned < te_full and tr_full < 0.01
print("ALL CHECKS PASS")
