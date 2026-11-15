# Persistence in practice: sliding windows on daily returns, before and after a simulated crash.
# Standard library only. Returns are whole basis points (1 bp = 0.01%); squared distances are integers.
# Bars are Vietoris-Rips bars over Z mod 2, in ball radius r (an edge joins windows within 2r), in percent.
from math import sqrt, acos, pi
M64 = (1 << 64) - 1

class Rng:  # SplitMix64, written out so Rust draws the same numbers
    def __init__(s, seed): s.x = seed
    def next(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64
        z = ((s.x ^ (s.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def gauss(s, sd):  # sum of 12 uniforms minus 6: close to a bell curve, in whole bp
        tot = sum(s.next() >> 40 for _ in range(12)) - 6 * (1 << 24)
        return (sd * tot * 2 + (1 << 24)) // (1 << 25)
    def shuffle(s, v):
        for i in range(len(v) - 1, 0, -1):
            j = s.next() % (i + 1)
            v[i], v[j] = v[j], v[i]

def simulate(seed):  # calm: 1% a day, no memory; after: a damped six-day rebound cycle
    g = Rng(seed)
    before = [g.gauss(100) for _ in range(42)]
    a = b = 0
    after = []
    for _ in range(72):
        a, b = a - (95 * b) // 100 + g.gauss(60), a
        after.append(a)
    return g, before, after[30:]

def windows(x, m): return [x[i:i + m] for i in range(len(x) - m + 1)]
def d2(p, q): return sum((u - v) ** 2 for u, v in zip(p, q))
def rad(w): return sqrt(w) / 200  # squared distance in bp^2 -> ball radius in percent

def bars(P):  # H0 deaths by union-find; H1 bars [b, d) by column reduction of the triangles
    n = len(P)
    D = [[d2(p, q) for q in P] for p in P]
    enc = min(max(row) for row in D)  # past this scale the complex is a cone: every loop is dead
    E = sorted((D[i][j], i, j) for i in range(n) for j in range(i + 1, n))
    idx = {(i, j): k for k, (_, i, j) in enumerate(E)}
    par = list(range(n))
    def find(a):
        while par[a] != a: a = par[a]
        return a
    h0 = []
    for w, i, j in E:
        if find(i) != find(j): par[find(i)] = find(j); h0.append(w)
    T = sorted((max(D[i][j], D[i][k], D[j][k]), i, j, k) for i in range(n) for j in range(i + 1, n)
               for k in range(j + 1, n) if max(D[i][j], D[i][k], D[j][k]) <= enc)
    low, h1 = {}, []
    for w, i, j, k in T:
        col = {idx[(i, j)], idx[(i, k)], idx[(j, k)]}
        while col and max(col) in low: col ^= low[max(col)]
        if col:
            low[max(col)] = col
            if E[max(col)][0] < w: h1.append((E[max(col)][0], w))
    return h0, h1, D

def longest(h1): return max([rad(d) - rad(b) for b, d in h1] + [0.0])

def betti_at(D, w):  # second road: beta_0, beta_1 of the complex at squared diameter w, by fresh mod-2 ranks
    n = len(D)
    ed = [(i, j) for i in range(n) for j in range(i + 1, n) if D[i][j] <= w]
    ei = {e: k for k, e in enumerate(ed)}
    tr = [(ei[(i, j)], ei[(i, k)], ei[(j, k)]) for i, j in ed for k in range(j + 1, n)
          if (i, k) in ei and (j, k) in ei]
    def rank(cols):
        piv, r = {}, 0
        for c in cols:
            c = set(c)
            while c and min(c) in piv: c ^= piv[min(c)]
            if c: piv[min(c)] = c; r += 1
        return r
    r1, r2 = rank([{i, j} for i, j in ed]), rank([set(t) for t in tr])
    return n - r1, len(ed) - r1 - r2

def test(g, x, m, N):  # shuffle test: the longest loop bar against N reshuffled copies of the same returns
    L = longest(bars(windows(x, m))[1])
    null = []
    for _ in range(N):
        y = x[:]; g.shuffle(y); null.append(longest(bars(windows(y, m))[1]))
    return L, max(null), (1 + sum(v >= L for v in null)) / (N + 1)

f, yn = (lambda v: f"{v:.2f}"), (lambda b: "yes" if b else "no")
hexa = windows([200, 100, -100, -200, -100, 100, 200, 100], 3)  # a pure six-day cycle, in bp
_, hb, _ = bars(hexa)
print("hexagon windows (%):", " ".join("(" + ",".join(str(v // 100) for v in p) + ")" for p in hexa[:6]))
print("hexagon squared distances (%^2):", sorted({d2(hexa[0], q) // 10000 for q in hexa[1:6]}))
print(f"hexagon loop bar: [{rad(hb[0][0]):.4f}, {rad(hb[0][1]):.4f}), {len(hb)} loop")
assert len(hb) == 1 and abs(rad(hb[0][0]) - sqrt(6) / 2) < 1e-12 and abs(rad(hb[0][1]) - sqrt(18) / 2) < 1e-12

g, before, after = simulate(2000)
print("before (bp):", *before); print("crash day (bp): -900"); print("after (bp):", *after)
print(f"planted cycle after the fall: x_t = x_(t-1) - 0.95 x_(t-2) + noise, period {2 * pi / acos(0.5 / sqrt(0.95)):.2f} days")
vol = [sqrt(sum(v * v for v in x) / len(x)) / 100 for x in (before, after)]
print(f"realised daily vol (%): before {f(vol[0])}, after {f(vol[1])}, ratio {f(vol[1] / vol[0])}")
print(f"annualised vol (%): before {sqrt(252) * vol[0]:.1f}, after {sqrt(252) * vol[1]:.1f}")
res = {}
for name, x in (("before", before), ("after", after)):
    h0, h1, D = bars(windows(x, 3))
    top = sorted(h1, key=lambda q: rad(q[0]) - rad(q[1]))[:3]
    res[name] = (sum(rad(w) for w in h0), longest(h1))
    print(f"{name} m=3: {len(h0)} H0 deaths, total {f(res[name][0])}; {len(h1)} H1 bars, longest three:",
          ", ".join(f"[{f(rad(b))}, {f(rad(d))})" for b, d in top))
    mid = (top[0][0] + top[0][1]) // 2  # inside the longest bar: count bars alive, then recount by ranks
    alive = (sum(w > mid for w in h0) + 1, sum(b <= mid < d for b, d in h1))
    print(f"  at r = {rad(mid):.4f}: bars alive (H0, H1) = {alive}; fresh ranks give {betti_at(D, mid)}")
    assert alive == betti_at(D, mid)
print(f"ratio after/before: H0 total {f(res['after'][0] / res['before'][0])}, longest H1 bar {f(res['after'][1] / res['before'][1])}")

k, alpha = 4, 0.05
print(f"tests k = {k}, threshold alpha/k = {alpha / k}; chance of a false alarm uncorrected: {1 - (1 - alpha) ** k:.4f} if independent, at most {k * alpha:.2f} in any case")
band = {}
for name, x in (("before", before), ("after", after)):
    for m in (3, 4):
        L, band[(name, m)], p = test(g, x, m, 99)
        print(f"{name} m={m}: longest {f(L)}, band (max of 99 shuffles) {f(band[(name, m)])}, p = {p:.2f}, feature: {yn(p <= alpha / k)}")
        assert (p <= alpha / k) == (name == "after") and (name == "before" or (p == 0.01 and band[(name, m)] < L))  # after: (1 + 0) / (99 + 1)
L0, jit = res["after"][1], [v + g.next() % 21 - 10 for v in after]  # each return moves at most 10 bp
Lj = longest(bars(windows(jit, 3))[1])
print(f"noise: jitter 10 bp moves the longest bar {f(L0)} -> {f(Lj)}, bound {2 * sqrt(3) * 0.1:.4f}, above band: {yn(Lj > band[('after', 3)])}")
assert abs(Lj - L0) <= 2 * sqrt(3) * 0.1 + 1e-12
W, sub = windows(after, 3), []
for _ in range(20):
    ix = list(range(len(W))); g.shuffle(ix)
    sub.append(longest(bars([W[i] for i in sorted(ix[:32])])[1]))
print(f"resample: 20 draws of 32 of 40 windows: longest bar {f(min(sub))} to {f(max(sub))}, above band in {sum(v > band[('after', 3)] for v in sub)}/20")
found = [0, 0]
for seed in range(2001, 2011):
    g2, b2, a2 = simulate(seed)
    found[0] += test(g2, b2, 3, 19)[2] <= 0.05
    found[1] += test(g2, a2, 3, 19)[2] <= 0.05
print(f"10 fresh seeds, 19 shuffles each, at 0.05: calm stretches flagged {found[0]}/10, rebound stretches found {found[1]}/10")
dbl = [2 * v for v in before]
Ld, _, pd = test(Rng(7), dbl, 3, 99); Lb, _, pb = test(Rng(7), before, 3, 99)
print(f"breaks: calm returns doubled: longest bar {f(Ld)} vs {f(Lb)}, p = {pd:.2f} vs {pb:.2f}")
assert abs(Ld - 2 * Lb) < 1e-12 and pd == pb
print(f"breaks: diameter instead of radius: longest bar after reads {f(2 * L0)}")
print("ALL CHECKS PASS")
