# Mayer-Vietoris and exact sequences -- the check behind the card.  Standard library only.
# A sphere's homology is found twice: from its own boundary ranks, and from two caps
# and their overlap through the Mayer-Vietoris sequence, whose maps i, j and d are
# built on actual cycles and ranked.  The dimension equations of exactness are tested
# at every spot, with Euler counts, and relative homology is checked against excision.
from functools import reduce
from itertools import combinations
from math import gcd

def echelon(rows, m):                       # exact integer elimination on the first m entries
    A, r = [row[:] for row in rows], 0
    for c in range(m):
        p = next((i for i in range(r, len(A)) if A[i][c]), None)
        if p is None:
            continue
        A[r], A[p] = A[p], A[r]
        for i in range(r + 1, len(A)):
            if A[i][c]:
                new = [A[r][c] * y - A[i][c] * x for x, y in zip(A[r], A[i])]
                g = reduce(gcd, new, 0)
                A[i] = [v // g for v in new] if g else new
        r += 1
    return A, r

def rank(vs):                               # the number of independent vectors
    return echelon(vs, len(vs[0]))[1] if vs else 0

def closure(tris):                          # every face of every panel
    return {f for t in tris for k in (1, 2, 3) for f in combinations(sorted(t), k)}

def levels(S):                              # the simplices by dimension, sorted
    return {k: sorted(s for s in S if len(s) == k + 1) for k in range(4)}

def bdry(X, s, Q):                          # boundary of one simplex, faces in Q erased
    k = len(s) - 1
    v = [0] * (len(X[k - 1]) if k else 1)
    for i in range(k + 1 if k else 0):
        if s[:i] + s[i + 1:] not in Q:
            v[X[k - 1].index(s[:i] + s[i + 1:])] += (-1) ** i
    return v

def cyc_bnd(X, S, Q, k):                    # a basis of k-cycles, and the k-boundaries, of chains on S mod Q
    cols, m = [s for s in X[k] if s in S and s not in Q], len(X[k - 1]) if k else 1
    A, r = echelon([bdry(X, s, Q) + [int(t == s) for t in X[k]] for s in cols], m)
    return [row[m:] for row in A[r:]], [bdry(X, s, Q) for s in X[k + 1] if s in S and s not in Q]

def betti(X, S, Q=frozenset()):             # over the rationals: independent cycles minus boundaries
    return [len(Z) - rank(B) for Z, B in (cyc_bnd(X, S, Q, k) for k in range(3))]

def chain_bd(X, z, k):                      # boundary of a k-chain written over X[k]
    out = [0] * len(X[k - 1])
    for c, s in zip(z, X[k]):
        out = [o + c * b for o, b in zip(out, bdry(X, s, ()))] if c else out
    return out

def lift_bd(X, z, k, V):                    # split z = a + b with a off V, b in V; return the boundary of a
    return chain_bd(X, [c if s not in V else 0 for c, s in zip(z, X[k])], k)

def mayer_vietoris(X, U, V):                # ranks of i, j and the connecting map d, degrees 0 to 2
    W, S, out = U & V, U | V, []
    for k in range(3):
        (ZW, _), (ZU, BU), (ZV, BV), (ZS, BS) = (cyc_bnd(X, A, (), k) for A in (W, U, V, S))
        pad = [0] * len(X[k])
        BUV = [b + pad for b in BU] + [pad + b for b in BV]
        ri = rank([z + [-x for x in z] for z in ZW] + BUV) - rank(BUV)      # i(c) = (c, -c)
        rj = rank(ZU + ZV + BS) - rank(BS)                                   # j(a, b) = a + b
        rd = 0
        if k:
            lifts, BW = [lift_bd(X, z, k, V) for z in ZS], cyc_bnd(X, W, (), k - 1)[1]
            assert all(not c or s in W for v in lifts for c, s in zip(v, X[k - 1]))   # d lands in the overlap
            rd = rank(lifts + BW) - rank(BW)
        out.append((ri, rj, rd))
    return out

def run(name, U, V):
    X, W, S = levels(U | V), U & V, U | V
    bW, bU, bV, bS = (betti(X, A) for A in (W, U, V, S))
    R = mayer_vietoris(X, U, V)
    n = lambda A: [len(levels(A)[k]) for k in range(3)]
    chi = lambda A: n(A)[0] - n(A)[1] + n(A)[2]
    print(f"{name}: overlap V E F {n(W)}, caps {n(U)} and {n(V)}, whole {n(S)}; "
          f"chi {chi(U)} + {chi(V)} - {chi(W)} = {chi(S)}")
    pred = []
    for k in range(3):
        ri, rj, rd = R[k]
        pred.append(bU[k] + bV[k] - ri + (bW[k - 1] - R[k - 1][0] if k else 0))
        print(f"  k={k}: b overlap {bW[k]}, b caps {bU[k]}+{bV[k]} | rank i {ri}, j {rj}, d {rd} | "
              f"b whole {bS[k]} direct, {pred[k]} from the pieces")
        assert bU[k] + bV[k] == ri + rj and bS[k] == rj + rd               # exact at two spots
        assert k == 0 or bW[k - 1] == rd + R[k - 1][0]                       # exact at the third
    assert bS == pred and chi(S) == chi(U) + chi(V) - chi(W) == bS[0] - bS[1] + bS[2]
    return X, bW, bU, bV, bS, R

# the small sphere: upper ring 0 1 2, lower ring 3 4 5, north pole 6, south pole 7
band = [(i, (i + 1) % 3, 3 + i) for i in range(3)] + [((i + 1) % 3, 3 + i, 3 + (i + 1) % 3) for i in range(3)]
north, south = [(i, (i + 1) % 3, 6) for i in range(3)], [(3 + i, 3 + (i + 1) % 3, 7) for i in range(3)]
U, V = closure(north + band), closure(band + south)
print("figure, schematic sphere: centre (210,160) radius 120; band from y=130 to y=190")
X, bW, bU, bV, bS, R = run("small sphere", U, V)

# the dome: an icosahedron, every face cut into 4 panels -> 42 joints, 120 struts, 80 panels
Up, Lo, rows = [1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [[], [], [], []]
for i in range(5):
    j = (i + 1) % 5
    for r, t in enumerate([(0, Up[i], Up[j]), (Up[i], Up[j], Lo[i]), (Up[j], Lo[i], Lo[j]), (11, Lo[i], Lo[j])]):
        rows[r].append(t)
mid = {e: 12 + n for n, e in enumerate(sorted(e for e in closure(sum(rows, [])) if len(e) == 2))}
cut = lambda t: [(a, mid[tuple(sorted((a, b)))], mid[tuple(sorted((a, c)))]) for a, b, c in
                 [t, (t[1], t[2], t[0]), (t[2], t[0], t[1])]] + [tuple(mid[tuple(sorted(e))] for e in combinations(t, 2))]
dome = [[p for t in row for p in cut(t)] for row in rows]
DN, DS = dome[0] + dome[1] + dome[2], dome[1] + dome[2] + dome[3]
run("dome", closure(DN), closure(DS))
run("dome, one north panel out", closure(DN[:3] + DN[4:]), closure(DS))

z = cyc_bnd(X, U | V, (), 2)[0][0]
z = z if z[X[2].index((0, 1, 6))] == 1 else [-c for c in z]
loop = lift_bd(X, z, 2, V)
print("sphere 2-cycle, panel coefficients:", " ".join(f"{''.join(map(str, s))}:{c:+d}" for s, c in zip(X[2], z)))
print("d sends it to the boundary of its north fan:", " ".join(f"{c:+d}*{a}{b}" for (a, b), c in zip(X[1], loop) if c))
missing = run("missing panel, V without 347", U, closure(band + south[1:]))[4]

rim = closure([(3, 4), (4, 5), (3, 5)])
rel = {"sphere rel south cap": betti(X, U | V, V), "north cap rel band": betti(X, U, U & V),
       "north cap rel its rim": betti(X, U, rim)}
print("relative b0 b1 b2: " + "; ".join(f"{name} {b}" for name, b in rel.items()))
print(f"mistake 1, Betti numbers by inclusion-exclusion: {[bU[k] + bV[k] - bW[k] for k in range(3)]}, true {bS}")
print(f"mistake 2, drop the connecting map: {[bU[k] + bV[k] - R[k][0] for k in range(3)]}")
print(f"mistake 3, pieces miss a panel: Mayer-Vietoris gives {missing}, the sphere is {bS}")
print(f"mistake 4, relative as subtraction: {[a - b for a, b in zip(bU, betti(X, rim))]}, "
      f"true {rel['north cap rel its rim']}")

assert bS == [1, 0, 1] and bU == bV == [1, 0, 0] and bW == [1, 1, 0] and R[2] == (0, 0, 1)
assert all(abs(c) == 1 for c in z) and not any(chain_bd(X, z, 2))                 # z: a 2-cycle, each panel +1 or -1
assert {s: c for s, c in zip(X[1], loop) if c} == {(0, 1): 1, (0, 2): -1, (1, 2): 1}   # d of it: the upper rim, signed
assert rel["sphere rel south cap"] == rel["north cap rel band"] == [0, 0, 1]    # excision, two ways
assert sum((-1) ** k * b for k, b in enumerate(rel["sphere rel south cap"])) == 2 - 1   # chi(X) - chi(A)
assert missing == [1, 0, 0] and missing != bS
print("ALL CHECKS PASS")
