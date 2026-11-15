# Filtration and persistent homology -- the check behind the card.  Standard library only.
# Six three-day windows of a made-up return series that repeats every six days.
# Bars come from mod-2 column reduction of the filtered boundary matrix.  They are
# checked against Betti numbers recomputed from scratch at 13 scales, against
# Kruskal's spanning tree for the pieces, and by testing the loop itself for a filling.
from itertools import combinations
from math import sqrt

S = [1, 2, 1, -1, -2, -1]                     # daily returns in percent, repeating every 6 days

def windows(s, m):                            # m-day windows; the series repeats, so wrap round
    return [tuple(s[(t + j) % len(s)] for j in range(m)) for t in range(len(s))]

def d2(p, q):                                 # squared distance, an exact integer
    return sum((a - b) ** 2 for a, b in zip(p, q))

def filtration(pts, top=2):                   # simplices up to dimension top, entered at squared diameter D
    simp = []
    for k in range(top + 1):
        for c in combinations(range(len(pts)), k + 1):
            simp.append((max((d2(pts[a], pts[b]) for a, b in combinations(c, 2)), default=0), k, c))
    return sorted(simp)                       # ties: lower dimension first, then vertex order

def bars(simp, top=1):                        # mod-2 column reduction; bar = (dim, birth D, death D or None)
    index = {c: i for i, (_, _, c) in enumerate(simp)}
    pivot, killed, out = {}, set(), []
    for j, (D, k, c) in enumerate(simp):
        col = {index[f] for f in combinations(c, k)} if k else set()
        while col and max(col) in pivot:
            col ^= pivot[max(col)]
        if col:
            i = max(col)
            pivot[i] = col
            killed |= {i, j}
            if simp[i][0] != D:               # drop bars of length zero
                out.append((simp[i][1], simp[i][0], D))
    out += [(k, D, None) for j, (D, k, c) in enumerate(simp) if j not in killed]
    return sorted([b for b in out if b[0] <= top], key=lambda b: (b[0], b[1], b[2] is None, b[2] or 0))

def r(D):                                     # scale r = half the distance, so r = sqrt(D) / 2
    return "inf" if D is None else f"{sqrt(D) / 2:.4f}"

def show(bs):
    return " ".join(f"H{k}[{r(b)},{r(d)})" for k, b, d in bs)

def rank2(cols):                              # rank mod 2, columns as bitmasks
    piv = {}
    for c in cols:
        while c and c.bit_length() in piv:
            c ^= piv[c.bit_length()]
        if c:
            piv[c.bit_length()] = c
    return len(piv)

def betti_fresh(simp, Q, extra=None):         # the complex built from scratch: every simplex with 4 D <= Q
    K = [[c for D, k, c in simp if k == j and 4 * D <= Q] for j in range(3)]
    pos = [{c: i for i, c in enumerate(K[j])} for j in range(3)]
    d = [[sum(1 << pos[j - 1][f] for f in combinations(c, j)) for c in K[j]] for j in (1, 2)]
    r1, r2 = rank2(d[0]), rank2(d[1])
    if extra is not None:                     # is this edge chain a boundary here?  rank goes up if not
        z = sum(1 << pos[1][e] for e in extra) if all(e in pos[1] for e in extra) else None
        return z is not None and rank2(d[1] + [z]) == r2
    return len(K[0]) - r1, len(K[1]) - r1 - r2

def alive(bs, k, q, p=None):                  # bars of dimension k with b <= r and s < d, at r = q/4, s = p/4
    p = q if p is None else p
    return sum(1 for j, b, d in bs if j == k and 4 * b <= q * q and (d is None or p * p < 4 * d))

def kruskal(pts):                             # pieces merge along the shortest edges, by union-find
    parent, deaths = list(range(len(pts))), []
    def find(v):
        while parent[v] != v:
            v = parent[v]
        return v
    for D, a, b in sorted((d2(pts[a], pts[b]), a, b) for a, b in combinations(range(len(pts)), 2)):
        if find(a) != find(b):
            parent[find(a)] = find(b)
            deaths.append(D)
    return deaths

W = windows(S, 3)
F = filtration(W)
B = bars(F)
print("windows (percent):", " ".join(f"w{t}=({','.join(map(str, w))})" for t, w in enumerate(W)))
dist = sorted({D for D, k, c in F if k == 1})
for D in dist:
    edges = [c for E, k, c in F if k == 1 and E == D]
    print(f"squared distance {D}: {len(edges)} edges, r = sqrt({D})/2 = {r(D)}")
print("bars over Z mod 2:", show(B))
print("figure, barcode x = 40 + 120 r:", " ".join(f"H{k} {40 + 120 * sqrt(b) / 2:.2f}-"
      + ("400" if d is None else f"{40 + 120 * sqrt(d) / 2:.2f}") for k, b, d in B))
print("r     b0 b1 | bars alive b0 b1")
curve = []
for q in range(13):
    f0, f1 = betti_fresh(F, q * q)          # r = q/4, so 4 D <= q^2
    a0, a1 = alive(B, 0, q), alive(B, 1, q)
    curve.append((f0, f1))
    print(f"{q / 4:.2f}  {f0:2d} {f1:2d} | {a0:2d} {a1:2d}")
    assert (f0, f1) == (a0, a1)               # road 2: fresh ranks agree with the bars at every scale
H0 = [b for b in B if b[0] == 0]
print("H0 deaths from bars:", [d for k, b, d in H0 if d], "Kruskal merges:", kruskal(W))
assert [d for k, b, d in H0 if d] == kruskal(W)       # road 3: Kruskal's spanning tree
hexagon = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (0, 5)]
filled = [D for D in dist if betti_fresh(F, 4 * D, hexagon)]
print("hexagon loop is a boundary first at squared distance", filled[0], "r =", r(filled[0]))
loop = [b for b in B if b[0] == 1]
assert betti_fresh(F, 4 * filled[0] - 1, hexagon) is False
assert len(loop) == 1 and loop[0][1:] == (6, filled[0])  # road 4: the loop itself, filled at its death
print(f"loop bar length: {(sqrt(loop[0][2]) - sqrt(loop[0][1])) / 2:.4f}")
p2, p5 = alive(B, 1, 6, 8), alive(B, 1, 6, 10)    # the formula with r < s: from r = 1.50 to 2.00 and 2.50
print(f"persistent b1 from r = 1.50: to 2.00 = {p2}, to 2.50 = {p5}")
assert (p2, p5) == (int(not betti_fresh(F, 64, hexagon)), int(not betti_fresh(F, 100, hexagon)))

G = bars(filtration(W, 1))                    # mistake 1: edges only, no triangles to fill anything
G1 = [b for b in G if b[0] == 1]
print("mistake 1, edges only:", len(G1), "loop bars, all endless:", show(G1[:1]), "and", len(G1) - 1, "more")
print(f"mistake 2, scale read as diameter: H1[{sqrt(loop[0][1]):.4f},{sqrt(loop[0][2]):.4f})")
print(f"mistake 3, one scale only: loops at r = 1.00: {curve[4][1]}, at r = 2.50: {curve[10][1]}")
lo = {c: D for D, k, c in F if k == 1}       # mistake 4: a triangle entered at its SHORTEST edge
X = bars(sorted((min(lo[e] for e in combinations(c, 2)) if k == 2 else D, k, c) for D, k, c in F))
back = [b for b in X if b[2] is not None and b[2] < b[1]]
print("mistake 4, triangles before their edges:", len(back), "bars die before birth, e.g.", show(back[:1]))
W2 = windows(S, 2)
print("second choice, two-day windows:", " ".join(f"({','.join(map(str, w))})" for w in W2))
B2 = bars(filtration(W2))
L2 = [b for b in B2 if b[0] == 1]
print("  loop bars:", show(L2), "lengths", " ".join(f"{(sqrt(d) - sqrt(b)) / 2:.4f}" for k, b, d in L2))
assert len(G1) == len(lo) - len(W) + 1 and all(d is None for k, b, d in G1)   # edges - corners + 1
assert len(back) == sum(D > dist[0] for D in lo.values())       # mistake 4: one per edge longer than a side
assert L2 == [(1, 5, 9), (1, 8, 9)] and dist == [6, 18, 24]  # worked by hand on the card
print("ALL CHECKS PASS")
