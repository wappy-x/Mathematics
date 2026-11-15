# Homology groups -- the check behind the card.  Standard library only.
# Betti numbers over the rationals are read from exact integer ranks of the
# boundary matrices, then checked against counts that share none of that
# arithmetic: components by union-find, ranks redone mod 2, V - E + F, and an
# exhaustive search over small chains.
from itertools import combinations, product

def gcd_all(vals):                          # Euclid's algorithm, run along a whole row
    g = 0
    for v in vals:
        while v:
            g, v = v, g % v
    return abs(g)

def closure(tris, edges=()):                # every face of every simplex, sorted
    K = {0: set(), 1: set(), 2: set()}
    for s in [tuple(sorted(t)) for t in list(tris) + list(edges)]:
        for k in range(len(s)):
            K[k].update(combinations(s, k + 1))
    return {k: sorted(K[k]) for k in K}

def boundary(K, k, signed=True):            # rows: (k-1)-simplices, columns: k-simplices
    row = {s: i for i, s in enumerate(K[k - 1])}
    M = [[0] * len(K[k]) for _ in K[k - 1]]
    for j, s in enumerate(K[k]):
        for i in range(len(s)):
            M[row[s[:i] + s[i + 1:]]][j] = (-1) ** i if signed else 1
    return M

def rank(M):                                # exact elimination, integer rows cut by their gcd
    A, r = [row[:] for row in M], 0
    for c in range(len(A[0]) if A else 0):
        p = next((i for i in range(r, len(A)) if A[i][c]), None)
        if p is None:
            continue
        A[r], A[p] = A[p], A[r]
        for i in range(r + 1, len(A)):
            if A[i][c]:
                new = [A[r][c] * y - A[i][c] * x for x, y in zip(A[r], A[i])]
                g = gcd_all(new)
                A[i] = [v // g for v in new] if g else new
        r += 1
    return r

def rank_mod2(M):                           # columns as sorted lists of odd rows
    cols, low, r = [sorted(i for i in range(len(M)) if M[i][j] % 2) for j in range(len(M[0]) if M else 0)], {}, 0
    for c in cols:
        while c and c[-1] in low:
            c = sorted(set(c) ^ set(low[c[-1]]))
        if c:
            low[c[-1]], r = c, r + 1
    return r

def components(K):                          # union-find on the edges
    parent = {v: v for (v,) in K[0]}
    def find(v):
        while parent[v] != v:
            v = parent[v]
        return v
    for a, b in K[1]:
        parent[find(a)] = find(b)
    return len({find(v) for (v,) in K[0]})

def betti(K, rk=rank, signed=True):
    n = [len(K[k]) for k in range(3)]
    r1, r2 = rk(boundary(K, 1, signed)), rk(boundary(K, 2, signed))
    return n, r1, r2, (n[0] - r1, n[1] - r1 - r2, n[2] - r2)

def apply(M, x):                            # the matrix M times the chain x
    return [sum(a * b for a, b in zip(row, x)) for row in M]

# the dome: an icosahedron, every face cut into 4 panels -> 42 joints, 120 struts, 80 panels
U, L = [1 + i for i in range(5)], [6 + i for i in range(5)]
ico = []
for i in range(5):
    j = (i + 1) % 5
    ico += [(0, U[i], U[j]), (U[i], U[j], L[i]), (U[j], L[i], L[j]), (11, L[i], L[j])]
mid = {e: 12 + n for n, e in enumerate(closure(ico)[1])}
dome, centres = [], []
for a, b, c in ico:
    ab, bc, ca = mid[tuple(sorted((a, b)))], mid[tuple(sorted((b, c)))], mid[tuple(sorted((c, a)))]
    dome += [(a, ab, ca), (b, ab, bc), (c, bc, ca), (ab, bc, ca)]
    centres.append(tuple(sorted((ab, bc, ca))))
out = [centres[0], centres[19], centres[9]]   # three central panels, no two touching

ring = [(i, (i + 1) % 3, 3 + i) for i in range(3)] + [((i + 1) % 3, 3 + i, 3 + (i + 1) % 3) for i in range(3)]
cases = [("hollow triangle", closure([], [(0, 1), (1, 2), (0, 2)])),
         ("filled triangle", closure([(0, 1, 2)])),
         ("annulus", closure(ring)),
         ("two hollow triangles", closure([], [(0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5)]))]
cases += [(f"dome, {m} out", closure([t for t in dome if tuple(sorted(t)) not in out[:m]])) for m in range(4)]

print("figure, annulus to scale: 0 (210,130) 1 (158,220) 2 (262,220) 3 (210,30) 4 (71,270) 5 (349,270)")
print("complex: V E F | rank d1, rank d2 | dim Z1, dim B1 | b0 b1 b2 over Q | mod 2 | pieces | V-E+F")
table = {}
for name, K in cases:
    n, r1, r2, b = betti(K)
    b2 = betti(K, rank_mod2)[3]
    chi = n[0] - n[1] + n[2]
    table[name] = b
    print(f"{name}: {n[0]} {n[1]} {n[2]} | {r1}, {r2} | {n[1] - r1}, {r2} | {b[0]} {b[1]} {b[2]} | "
          f"{b2[0]} {b2[1]} {b2[2]} | {components(K)} | {chi}")
    assert b == b2 and b[0] == components(K) and chi == b[0] - b[1] + b[2]

A = cases[2][1]
d1, d2 = boundary(A, 1), boundary(A, 2)
z = [{(0, 1): 1, (1, 2): 1, (0, 2): -1}.get(e, 0) for e in A[1]]       # the inner rim
w = [{(3, 4): 1, (4, 5): 1, (3, 5): -1}.get(e, 0) for e in A[1]]       # the outer rim
diff = [p - q for p, q in zip(w, z)]
print("annulus edges:", " ".join(f"{a}{b}" for a, b in A[1]))
print("annulus panels:", " ".join(f"{a}{b}{c}" for a, b, c in A[2]))
print(f"inner rim z = 01 + 12 - 02, its boundary: {apply(d1, z)}")
print(f"outer rim w = 34 + 45 - 35, its boundary: {apply(d1, w)}")
rz = rank([row + [v] for row, v in zip(d2, z)])
rd = rank([row + [v] for row, v in zip(d2, diff)])
print(f"rank of d2 alone {rank(d2)}; with z added {rz}; with w - z added {rd}")
hits_z = [x for x in product((-1, 0, 1), repeat=6) if apply(d2, x) == z]
hits_d = [x for x in product((-1, 0, 1), repeat=6) if apply(d2, x) == diff]
print(f"search over 3^6 = 729 panel chains: {len(hits_z)} with boundary z, {len(hits_d)} with boundary w - z")
print(f"w - z is the boundary of panel coefficients {list(hits_d[0])}")
T = cases[1][1]
print(f"filled triangle: boundary of 012 = {apply(boundary(T, 2), [1])} on edges 01 02 12")

hollow2 = betti(cases[0][1], signed=False)[3]
dd = [apply(boundary(A, 1, False), col) for col in zip(*boundary(A, 2, False))]
print(f"mistake 1, cycles not divided by boundaries: annulus dim Z1 = {len(A[1]) - rank(d1)}, "
      f"filled triangle {len(T[1]) - rank(boundary(T, 1))}")
print(f"mistake 2, one loop per panel out: 3 out gives 3, true b1 = {table['dome, 3 out'][1]}")
print(f"mistake 3, signs dropped: d1 of d2 on panel 013 = {dd[0]}, not zero; "
      f"hollow triangle b read as {list(hollow2)}")
print(f"mistake 4, V-E+F alone: annulus 0 = two hollow triangles 0, "
      f"but b = {list(table['annulus'])} against {list(table['two hollow triangles'])}")

assert [table[f"dome, {m} out"] for m in range(4)] == [(1, 0, 1), (1, 0, 0), (1, 1, 0), (1, 2, 0)]
assert table["annulus"] == (1, 1, 0) and table["hollow triangle"] == (1, 1, 0) and table["filled triangle"] == (1, 0, 0)
assert not any(apply(d1, z)) and not any(apply(d1, w)) and rz == rank(d2) + 1 and rd == rank(d2)
assert hits_z == [] and len(hits_d) == 1                   # search agrees with the rank test
assert any(map(any, dd)) and hollow2 != table["hollow triangle"]
print("ALL CHECKS PASS")
