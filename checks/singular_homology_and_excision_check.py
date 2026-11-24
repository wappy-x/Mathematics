# Singular homology and excision -- the check behind the card.  Standard library only.
# Road 1: barycentric subdivision done exactly on a dome panel (an equilateral
#         triangle of side 1 m), every small triangle measured, against the bound.
# Road 2: every small triangle tested against a cover of 11 strips whose
#         Lebesgue number is 0.1 m; the bound predicts the round that is enough.
# Road 3: local homology by exact ranks over Q, two ways: the whole space against
#         the excised piece, and both against the exact sequence (reduced counts).
from fractions import Fraction
from itertools import combinations, permutations
from math import sqrt

S = 12 ** 6          # barycentric weights scaled by S stay whole numbers for 6 rounds

def corners(n):      # the n-simplex's corners, as scaled weight vectors
    return tuple(tuple(S if i == j else 0 for i in range(n + 1)) for j in range(n + 1))

def bary(pts):       # the barycentre (average) of some points, exactly
    tot = [sum(col) for col in zip(*pts)]
    assert all(t % len(pts) == 0 for t in tot)
    return tuple(t // len(pts) for t in tot)

def subdivide(s):    # one small simplex per ordering of the corners: corner, edge middle, ...
    return [tuple(bary([s[i] for i in order[:m + 1]]) for m in range(len(s)))
            for order in permutations(range(len(s)))]

def diam2(s):        # squared diameter in the regular simplex of side 1 m: sum of d_i^2, halved
    return max(Fraction(sum((a - b) ** 2 for a, b in zip(p, q)), 2 * S * S)
               for p, q in combinations(s, 2))

def rounds(n, r):    # every level of subdivision, checking each child against its parent
    levels, f = [[corners(n)]], Fraction(n, n + 1) ** 2
    for _ in range(r):
        nxt = []
        for s in levels[-1]:
            kids = subdivide(s)
            assert all(diam2(c) <= f * diam2(s) for c in kids)   # the one-round bound
            nxt += kids
        levels.append(nxt)
    return levels

def misfits(level):  # small triangles lying in no open strip (0.1(j-1), 0.1(j+1)) m, j = 0..10
    bad = 0
    for s in level:
        xs = [20 * w[1] + 10 * w[2] for w in s]            # 20 S times the x-coordinate
        bad += not any(2 * S * (j - 1) < min(xs) and max(xs) < 2 * S * (j + 1) for j in range(11))
    return bad

tri = rounds(2, 6)
c = bary(tri[0][0])
print(f"figure, panel corners (0,0) (1,0) (0.5,{sqrt(3) / 2:.4f}); centroid "
      f"({(c[1] + c[2] / 2) / S:.4f},{c[2] * sqrt(3) / 2 / S:.4f}) m")
big = [max(diam2(s) for s in lev) for lev in tri]
bad = [misfits(lev) for lev in tri]
for r, lev in enumerate(tri):
    print(f"round {r}: {len(lev)} triangles, largest diameter {sqrt(big[r]):.4f} m "
          f"(squared {big[r]}), bound (2/3)^{r} = {float(Fraction(2, 3) ** r):.4f}, in no strip {bad[r]}")
need = next(r for r in range(20) if Fraction(2, 3) ** r < Fraction(1, 10))
half = next(r for r in range(20) if Fraction(1, 2) ** r < Fraction(1, 10))
print(f"bound first below 0.1 m at round {need}; first round with every triangle in a strip "
      f"{bad.index(0)}")
assert all(big[r] <= Fraction(4, 9) ** r for r in range(7))  # road 1: measured within proved
assert big[1] == Fraction(1, 3)                               # corner to centre, 1/sqrt(3), by hand
assert (need, half) == (6, 4)                                 # by hand: (2/3)^5 > 0.1 > (2/3)^6; (1/2)^3 > 0.1 > (1/2)^4
assert bad[need] == 0 and bad[0] == 1                         # road 2: the bound's round suffices
for n, r in ((1, 4), (3, 3)):
    ds = [max(diam2(s) for s in lev) for lev in rounds(n, r)]
    assert all(d <= Fraction(n, n + 1) ** (2 * k) for k, d in enumerate(ds))
    print(f"{n}-simplex, {r} rounds: largest diameters " + ", ".join(f"{sqrt(d):.4f}" for d in ds)
          + f" m; bound ratio {n}/{n + 1}")

# ---- homology: chains, relative boundaries, ranks over Q ----
def rank(rows):
    m, rk = [[Fraction(x) for x in row] for row in rows], 0
    for col in range(len(m[0]) if m else 0):
        p = next((i for i in range(rk, len(m)) if m[i][col]), None)
        if p is None:
            continue
        m[rk], m[p] = m[p], m[rk]
        for i in range(rk + 1, len(m)):
            f = m[i][col] / m[rk][col]
            m[i] = [a - f * b for a, b in zip(m[i], m[rk])]
        rk += 1
    return rk

def closure(tops):   # every face of every listed simplex
    return {f for t in tops for k in range(1, len(t) + 1) for f in combinations(sorted(t), k)}

def betti(X, A=frozenset()):     # Betti numbers of X relative to A, over Q
    rel = {k: sorted(s for s in X - A if len(s) == k + 1) for k in range(6)}
    def bd(k):       # boundary from relative k-chains to relative (k-1)-chains, signs (-1)^i
        if k == 0 or not rel[k] or not rel[k - 1]:
            return 0
        row = {s: i for i, s in enumerate(rel[k - 1])}
        mat = [[0] * len(rel[k]) for _ in rel[k - 1]]
        for j, s in enumerate(rel[k]):
            for i in range(len(s)):
                if s[:i] + s[i + 1:] in row:
                    mat[row[s[:i] + s[i + 1:]]][j] = (-1) ** i
        return rank(mat)
    top = max([k for k in rel if rel[k]], default=0)
    return [len(rel[k]) - bd(k) - bd(k + 1) for k in range(top + 1)]

def reduced(b):      # reduced counts: one fewer piece, so a point reads all zeros
    return [b[0] - 1] + b[1:]

nb = lambda i: 1 + (i + 1) % 5   # icosahedron: top 0, upper ring 1-5, lower ring 6-10, bottom 11
ico = [f for i in range(5) for f in ((0, 1 + i, nb(i)), (11, 6 + i, 5 + nb(i)),
       (1 + i, nb(i), 6 + i), (nb(i), 6 + i, 5 + nb(i)))]
edges = sorted({e for f in ico for e in combinations(sorted(f), 2)})
mid = {e: 12 + k for k, e in enumerate(edges)} | {e[::-1]: 12 + k for k, e in enumerate(edges)}
panels = [p for a, b, c in ico for p in ((a, mid[a, b], mid[c, a]), (b, mid[a, b], mid[b, c]),
          (c, mid[b, c], mid[c, a]), (mid[a, b], mid[b, c], mid[c, a]))]
dome, P = closure(panels), panels[0]
star = [p for p in panels if 0 in p]
rim = closure(combinations(P, 2))
counts = [sum(len(s) == k + 1 for s in dome) for k in range(3)]
print(f"dome: simplices {counts}, Betti {betti(dome)}; joint 0 has {len(star)} panels")
pairs = {"dome rel dome minus one open panel": betti(dome, closure(panels[1:])),
         "one panel rel its rim": betti(closure([P]), rim),
         "dome rel dome minus open star of joint 0": betti(dome, closure([p for p in panels if 0 not in p])),
         "star of joint 0 rel its link": betti(closure(star), closure([e for p in star for e in combinations(p, 2) if 0 not in e]))}
for name, b in pairs.items():
    print(f"local, {name}: {b}")
print(f"local, the rim's reduced counts shifted up one: {[0] + reduced(betti(rim))}")
assert counts == [42, 120, 80] and betti(dome) == [1, 0, 1]
assert all(b == [0, 0, 1] == [0] + reduced(betti(rim)) for b in pairs.values())  # road 3
for n in range(1, 5):
    simplex = closure([tuple(range(n + 1))])
    edge = {s for s in simplex if len(s) <= n}
    rel, les = betti(simplex, edge), [0] + reduced(betti(edge))
    assert rel == les == [0] * n + [1]                      # Z only in degree n, two ways
    print(f"n = {n}: simplex rel rim {rel}; S^{n - 1} reduced, shifted {les}")
bds = [0] + [k % 2 == 0 for k in range(1, 7)]              # a point: one singular simplex per degree
print(f"point, singular chains to degree 5: Betti {[1 - bds[k] - bds[k + 1] for k in range(6)]}")
print(f"mistake, shrink factor 1/2: bound below 0.1 m at round {half}; round {half} truly "
      f"{sqrt(big[half]):.4f} m, {bad[half]} triangles in no strip")
print(f"mistake, unreduced rim shifted: {[0] + betti(rim)}, true {pairs['one panel rel its rim']}")
print(f"mistake, excise the whole rim: panel alone {betti(closure([P]))}, true {pairs['one panel rel its rim']}")
assert bad[half] > 0 and [0] + betti(rim) != pairs["one panel rel its rim"]
print("ALL CHECKS PASS")
