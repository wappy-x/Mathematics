# Cellular homology -- the check behind the card.  Standard library only.
# Road 1 reads the boundary matrices straight off each gluing recipe: a letter
# is a cell, a capital runs it backwards, and a cell's boundary number is the
# signed count of its letters.  Road 2 cuts the same surface into triangles and
# builds the full simplicial boundary matrices.  Both are reduced by an integer
# Smith form written out here; Betti numbers are redone mod 2 and checked
# against the Euler characteristic, counted from cells.
from itertools import combinations

def smith(M):                              # nonzero diagonal of the Smith form
    A, out = [r[:] for r in M if any(r)], []
    while A and any(any(r) for r in A):
        while True:
            i, j = min(((i, j) for i, r in enumerate(A) for j, x in enumerate(r) if x),
                       key=lambda t: abs(A[t[0]][t[1]]))
            A[0], A[i] = A[i], A[0]
            for r in A:
                r[0], r[j] = r[j], r[0]
            p, done = A[0][0], True
            for r in A[1:]:                # clear the column under the pivot
                q = r[0] // p
                r[:] = [x - q * y for x, y in zip(r, A[0])]
                done = done and r[0] == 0
            for k in range(1, len(A[0])):  # clear the row beside the pivot
                q = A[0][k] // p
                for r in A:
                    r[k] -= q * r[0]
                done = done and A[0][k] == 0
            bad = [r for r in A[1:] if any(x % p for x in r[1:])]
            if done and bad:               # pivot must divide the rest
                A[0] = [x + y for x, y in zip(A[0], bad[0])]
                done = False
            if done:
                break
        out.append(abs(A[0][0]))
        A = [r[1:] for r in A[1:] if any(r[1:])]
    return out

def rank2(M):                              # rank mod 2, columns as sorted lists of odd rows
    low, r = {}, 0
    for c in [sorted(i for i in range(len(M)) if M[i][j] % 2) for j in range(len(M[0]) if M else 0)]:
        while c and c[-1] in low:
            c = sorted(set(c) ^ set(low[c[-1]]))
        if c:
            low[c[-1]], r = c, r + 1
    return r

def homology(cells, D):                    # D[n] has rows (n-1)-cells, columns n-cells
    top, sm = len(cells) - 1, {n: smith(D[n]) for n in D}
    rk = lambda n: len(sm[n]) if n in sm else 0
    r2 = lambda n: rank2(D[n]) if n in D else 0
    H = [(cells[n] - rk(n) - rk(n + 1), [t for t in sm.get(n + 1, []) if t > 1]) for n in range(top + 1)]
    return H, [cells[n] - r2(n) - r2(n + 1) for n in range(top + 1)]

def cellular(V, E, rims, signed=True):     # rims[n]: n-cell name -> rim word, n >= 2
    D = {1: [[(v == E[e][1]) - (v == E[e][0]) for e in E] for v in V]}
    for n, cells in sorted(rims.items()):
        below = list(E) if n == 2 else list(rims[n - 1])
        D[n] = [[w.count(f) + (-1 if signed else 1) * w.count(f.upper()) for w in cells.values()]
                for f in below]
    return [len(V), len(E)] + [len(rims[n]) for n in sorted(rims)], D

def simplicial(tris):                      # closure of the triangles, signed (-1)^i
    K = [sorted({f for t in tris for f in combinations(sorted(t), k)}) for k in (1, 2, 3)]
    D = {}
    for k in (1, 2):
        row = {s: i for i, s in enumerate(K[k - 1])}
        D[k] = [[0] * len(K[k]) for _ in K[k - 1]]
        for j, s in enumerate(K[k]):
            for i in range(k + 1):
                D[k][row[s[:i] + s[i + 1:]]][j] = (-1) ** i
    assert all(sum(set(e) <= set(t) for t in K[2]) == 2 for e in K[1])  # a closed surface
    assert all(sum(a * b for a, b in zip(r, col)) == 0 for r in D[1] for col in zip(*D[2]))
    return [len(x) for x in K], D

def grid(n, flip):                         # n x n grid, right edge glued to left (flipped or not)
    def v(i, j):
        if i == n:
            i, j = 0, (-j if flip else j)
        return (i % n) * n + j % n
    return [t for i in range(n) for j in range(n) for t in
            ((v(i, j), v(i + 1, j), v(i + 1, j + 1)), (v(i, j), v(i, j + 1), v(i + 1, j + 1)))]

rp2_tris = [(0, 1, 2), (0, 2, 3), (0, 3, 4), (0, 4, 5), (0, 5, 1),
            (1, 2, 4), (2, 3, 5), (3, 4, 1), (4, 5, 2), (5, 1, 3)]
v1, ab = ["v"], {"a": ("v", "v"), "b": ("v", "v")}
xyz = {"x": ("v", "v"), "y": ("v", "v"), "z": ("v", "v")}
recipes = [("torus, 1 square, rim abAB", v1, ab, {2: {"T": "abAB"}}, grid(3, False)),
           ("klein bottle, 1 square, rim abAb", v1, ab, {2: {"K": "abAb"}}, grid(3, True)),
           ("projective plane, 1 disc, rim aa", v1, {"a": ("v", "v")}, {2: {"P": "aa"}}, rp2_tris)]
fmt = lambda H: "; ".join(f"H{n}: rank {r}, torsion {t}" for n, (r, t) in enumerate(H))
chi = lambda c: sum((-1) ** n * x for n, x in enumerate(c))
results = []
print("road 1, cellular: cells per dimension and boundary matrices")
for label, V, E, rims, tris in recipes:
    c, D = cellular(V, E, rims)
    dd = [[sum(D[1][i][k] * D[2][k][j] for k in range(len(E))) for j in range(c[2])] for i in range(c[0])]
    print(f"{label}: cells {c}; d1 = {D[1]}; d2 = {D[2]}; d1 d2 = {dd}")
    results.append((label.split(",")[0], c, D, homology(c, D), simplicial(tris)))
print("homology over the integers, cellular (road 1) and simplicial (road 2):")
for name, c, D, (H, B2), (s, SD) in results:
    sH, sB2 = homology(s, SD)
    qb = [r for r, _ in H]
    print(f"{name}: {fmt(H)}")
    print(f"  triangles: {s[0]} vertices, {s[1]} edges, {s[2]} triangles; "
          f"same groups: {'yes' if sH == H else 'no'}")
    print(f"  matrix entries: cellular {c[0] * c[1] + c[1] * c[2]}, simplicial {s[0] * s[1] + s[1] * s[2]}")
    print(f"  Betti over Q {qb}, over Z mod 2 {B2}; chi from cells {chi(c)}, from triangles "
          f"{chi(s)}, from Betti over Q {chi(qb)}, over Z mod 2 {chi(B2)}")
    assert sH == H and sB2 == B2 and chi(c) == chi(s) == chi(qb) == chi(B2)
c3, D3 = cellular(v1, xyz, {2: {"p": "xyXY", "q": "xzXZ", "r": "yzYZ"}, 3: {"C": "pPqQrR"}})
H3, _ = homology(c3, D3)
print(f"3-torus, 1 cube, opposite faces glued: cells {c3}; d3 = {D3[3]}; Betti over Q {[r for r, _ in H3]}")
cu, Du = cellular(v1, ab, {2: {"T": "abAB"}}, signed=False)
Hu, _ = homology(cu, Du)
Hk = results[1][3][0]
c8, D8 = cellular(v1, ab, {})
H8, _ = homology(c8, D8)
print(f"mistake 1, torus with signs dropped: d2 = {Du[2]}; {fmt(Hu)}")
print(f"mistake 2, klein bottle by rank alone: H1 rank {Hk[1][0]}, the torsion {Hk[1][1]} unseen")
print(f"mistake 3, klein bottle cells {results[1][1]} read as Betti numbers; over Q they are {[r for r, _ in Hk]}")
print(f"mistake 4, torus with the square left out: {fmt(H8)}; chi {chi(c8)}")
print("figure, schematic: torus square (40, 50) side 160; klein square (260, 50) side 160; "
      "disc centre (560, 130) radius 80")
T, K, P = (r[3][0] for r in results)
assert T == [(1, []), (2, []), (1, [])] and K == [(1, []), (1, [2]), (0, [])] and P == [(1, []), (0, [2]), (0, [])]
assert [b for b in (r[3][1] for r in results)] == [[1, 2, 1], [1, 2, 1], [1, 1, 1]]
assert [r for r, _ in H3] == [1, 3, 3, 1] and Hu == [(1, []), (1, [2]), (0, [])] and H8 == [(1, []), (2, [])]
assert smith([[2, 4], [6, 8]]) == [2, 4] and smith([[0, 2], [3, 0]]) == [1, 6]
print("ALL CHECKS PASS")
