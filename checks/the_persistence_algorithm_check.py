# The persistence algorithm -- the check behind the card.  Standard library only.
# Boundary matrices are reduced mod 2, column by column; each lowest 1 pairs a birth
# with a death.  Roads: a rectangle by hand and by corner ranks; Kruskal; a fresh rank
# at four scales; clearing; a scale cap; a noise-free cloud and landmarks vs stability.
from itertools import combinations
from math import sqrt
RECT, NAMES = [(0, 0), (4, 0), (4, 3), (0, 3)], "ABCD"
CYCLE = [200, 162, 62, -62, -162, -200, -162, -62, 62, 162]  # 200 cos(36k deg), in bp
NOISE, SEED, CAP, M64 = 20, 7, 340, (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def windows(noise):                          # 32 simulated days -> 30 three-day windows
    s, x = SEED, []
    for t in range(32):
        s, z = splitmix(s)
        x.append(CYCLE[t % 10] + z % (2 * noise + 1) - noise)
    return [tuple(x[t:t + 3]) for t in range(30)]
sq = lambda p, q: sum((a - b) ** 2 for a, b in zip(p, q))
def rips(pts, by_dim=True):                  # (squared scale, dim, vertices), in filtration order
    out = [(max([sq(pts[a], pts[b]) for a, b in combinations(c, 2)], default=0), k - 1, c)
           for k in (1, 2, 3) for c in combinations(range(len(pts)), k)]
    return sorted(out) if by_dim else sorted(out, key=lambda s: (s[0], -s[1], s[2]))
def columns(simp):                           # boundary matrix mod 2: the rows of each face
    at = {c: i for i, (_, _, c) in enumerate(simp)}
    return [sorted(at[f] for f in combinations(c, k)) if k else [] for _, k, c in simp]
def reduce(simp, clear=False, log=None):     # owner {low row: column}, R, additions, skipped
    R, owner, adds, skipped = [set(c) for c in columns(simp)], {}, 0, 0
    order = sorted(range(len(R)), key=lambda j: -simp[j][1]) if clear else range(len(R))
    for j in order:
        if clear and simp[j][1] and j in owner:   # already a later column's low: it is zero
            R[j], skipped = set(), skipped + 1
            continue
        steps = []
        while R[j] and max(R[j]) in owner:   # same low as an earlier column: add that column
            steps.append(owner[max(R[j])])
            R[j] ^= R[steps[-1]]
        adds += len(steps)
        if R[j]: owner[max(R[j])] = j
        if log is not None: log.append((j, steps, max(R[j]) if R[j] else None))
    return owner, R, adds, skipped
def bars(simp, owner, R, dim):               # half-open [b, d) in squared scale; None = never dies
    out = [(simp[i][0], simp[j][0]) for i, j in owner.items() if simp[i][1] == dim]
    out += [(s[0], None) for i, s in enumerate(simp) if s[1] == dim and not R[i] and i not in owner]
    return sorted((b for b in out if b[0] != b[1]), key=lambda b: (b[1] is None, b[1] or 0, b[0]))
def rad(s, unit=200):                        # squared distance in bp -> radius in percent
    return "inf" if s is None else f"{sqrt(s) / unit:.3f}"
def show(bs, unit=200):
    return ", ".join(f"[{rad(b, unit)}, {rad(d, unit)})" for b, d in bs) or "none"
def kruskal(pts):                            # union-find: the cheapest skeleton's edges
    parent, out = list(range(len(pts))), []
    def find(a):
        while parent[a] != a:
            a = parent[a]
        return a
    for d, a, b in sorted((sq(pts[a], pts[b]), a, b) for a, b in combinations(range(len(pts)), 2)):
        if find(a) != find(b):
            parent[find(a)] = find(b)
            out.append(d)
    return out
def rank2(masks):                            # rank mod 2 of columns written as bit masks
    basis = {}
    for v in masks:
        while v and v.bit_length() in basis:
            v ^= basis[v.bit_length()]
        if v: basis[v.bit_length()] = v
    return len(basis)
def fresh(pts, s):                           # beta_0, beta_1 at squared scale s, from scratch
    simp = [x for x in rips(pts) if x[0] <= s]
    n, cols = [sum(1 for x in simp if x[1] == k) for k in range(3)], columns(simp)
    r = [rank2([sum(1 << i for i in cols[j]) for j in range(len(simp)) if simp[j][1] == k]) for k in (1, 2)]
    return n[0] - r[0], n[1] - r[0] - r[1]
alive = lambda bs, s: sum(1 for b, d in bs if b <= s and (d is None or s < d))
def landmarks(pts, m):                       # farthest-point sample; cover = squared Hausdorff
    L = [0]
    while len(L) < m:
        L.append(max(range(len(pts)), key=lambda i: (min(sq(pts[i], pts[l]) for l in L), -i)))
    return [pts[l] for l in L], max(min(sq(p, pts[l]) for l in L) for p in pts)
def run(simp):
    owner, R, adds, _ = reduce(simp)
    return owner, adds, bars(simp, owner, R, 0), bars(simp, owner, R, 1)
simp, log = rips(RECT), []
name = lambda j: "".join(NAMES[v] for v in simp[j][2])
owner, R, adds, _ = reduce(simp, log=log)
print(f"rectangle 4 x 3: {len(simp)} columns, order {' '.join(name(j) for j in range(len(simp)))}")
for j, steps, low in log[4:]:
    tail = f"low {name(low)}: pair ({name(low)}, {name(j)})" if low is not None else "zero: a birth"
    print(f"  {name(j)} at r = {sqrt(simp[j][0]) / 2:.1f}: faces {' '.join(name(i) for i in columns(simp)[j])}"
          + "".join(f" + {name(k)}" for k in steps) + f" -> {tail}")
rb0, rb1 = bars(simp, owner, R, 0), bars(simp, owner, R, 1)
print(f"rectangle bars: H0 {show(rb0, 2)}; H1 {show(rb1, 2)}; additions {adds}")
cols = columns(simp); rk = lambda i, j: rank2([sum(1 << r for r in cols[c] if r >= i) for c in range(j + 1)])
by_rank = {(i, j) for i in range(14) for j in range(i + 1, 14)
           if rk(i, j) - rk(i + 1, j) - rk(i, j - 1) + rk(i + 1, j - 1) == 1}
print(f"pairs from corner ranks of the unreduced matrix: {len(by_rank)}, same as reduction: {by_rank == set(owner.items())}")
assert rb1 == [(16, 25)] and [d for _, d in rb0] == [9, 9, 16, None] and by_rank == set(owner.items())
pts, clean = windows(NOISE), windows(0)
simp = rips(pts)
lg = []; owner, R, adds, _ = reduce(simp, log=lg); b0, b1 = bars(simp, owner, R, 0), bars(simp, owner, R, 1)
owner_c, _, adds_c, skipped = reduce(simp, clear=True)
zero = sum(1 for i, j in owner.items() if simp[i][0] == simp[j][0])
print(f"cloud: 30 windows, first {pts[0]} bp; {sum(1 for s in simp if s[1] == 1)} edges, "
      f"{sum(1 for s in simp if s[1] == 2)} triangles, {len(simp)} columns")
print(f"left to right: {adds} additions, {len(owner)} pairs, {zero} of zero length; triangles reducing to zero: "
      f"{sum(1 for j, _, low in lg if low is None and simp[j][1] == 2)}, using {sum(len(st) for j, st, low in lg if low is None and simp[j][1] == 2)} additions")
print(f"clearing: {adds_c} additions, {skipped} edge columns skipped, same pairs: {owner_c == owner}")
mst = kruskal(pts)
print(f"H0: {len(b0)} bars; finite deaths equal Kruskal's 29 edges: {[d for _, d in b0[:-1]] == mst}; "
      f"longest finite [0.000, {rad(mst[-1])})")
print(f"H1 bars (r in percent): {show(b1)}")
ring = max(b1, key=lambda b: b[1] - b[0])
delta = max(sq(p, q) for p, q in zip(pts, clean))
cring = run(rips(clean))[3]
print(f"noise: each window moved at most {rad(4 * delta)}%, so bars under {rad(16 * delta)}% may be noise; "
      f"noise-free ring {show(cring)}")
for d in (79, 160, 240, 320):
    print(f"r = {d / 200:.3f}%: bars alive H0 {alive(b0, d * d)}, H1 {alive(b1, d * d)}; fresh rank {fresh(pts, d * d)}")
    assert fresh(pts, d * d) == (alive(b0, d * d), alive(b1, d * d))
capped = run([s for s in simp if s[0] <= CAP * CAP])
print(f"cap at r = {CAP / 200:.3f}%: {sum(1 for s in simp if s[0] <= CAP * CAP)} columns, {capped[1]} additions, H1 {show(capped[3])}")
for m in (12, 4):
    lp, cover = landmarks(pts, m)
    lo, ladds, _, lb1 = run(rips(lp))
    print(f"{m} landmarks: Hausdorff {rad(4 * cover)}%, {len(rips(lp))} columns, {ladds} additions, H1 {show(lb1)}")
    if m == 12:
        land = max(lb1, key=lambda b: b[1] - b[0])
        assert all(abs(sqrt(x) - sqrt(y)) <= 2 * sqrt(cover) for x, y in zip(land, ring))
bo = reduce(rips(RECT, by_dim=False))[0]
print(f"mistake, matrix not reduced: beta_0 at r = 2.5 read as 4 - 6 = {4 - sum(1 for c in cols if len(c) == 2)}")
print(f"mistake, ties broken against dimension: {sum(1 for i, j in bo.items() if j < i)} pairs die before birth")
print(f"mistake, diameter read as radius: ring [{rad(ring[0], 100)}, {rad(ring[1], 100)})")
print("barcode, r from 0 to 2% in steps of 0.05%:")
for label, (b, d) in (("H0 forever", b0[-1]), ("H0 longest", b0[-2]), ("H1 ring", ring)):
    print(f"  {label:<11}" + "".join("#" if b <= (10 * k + 5) ** 2 and (d is None or (10 * k + 5) ** 2 < d)
                                     else "." for k in range(40)) + f" [{rad(b)}, {rad(d)})")
assert [d for _, d in b0[:-1]] == mst and owner_c == owner and adds_c < adds and capped[3] == b1
assert len(b1) == 2 and sqrt(ring[1]) - sqrt(ring[0]) > 4 * sqrt(delta) and all(abs(sqrt(x) - sqrt(y)) <= 2 * sqrt(delta) for x, y in zip(ring, cring[0]))
print("ALL CHECKS PASS")
