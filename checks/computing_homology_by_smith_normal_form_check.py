# Smith normal form -- the check behind the card.  Nothing is imported.  The
# Klein bottle's boundary matrices are reduced over the integers with row and
# column moves that can be undone, and the diagonal is read as hole counts plus
# torsion.  Roads: a 3-edge cell model by hand and a 9-corner triangulation;
# gcds of minors; ranks over Q, Z mod 2 and Z mod 3 by separate elimination.
CELL = [[1, 1], [1, -1], [-1, -1]]           # rows a, b, c; columns U, L
def gcd(a, b):
    while b: a, b = b, a % b
    return abs(a)
def smith(m):                                # the diagonal d_1 | d_2 | ... (nonzero part)
    a, diag, t = [row[:] for row in m], [], 0
    while True:
        spots = [(abs(a[i][j]), i, j) for i in range(t, len(a)) for j in range(t, len(a[0])) if a[i][j]]
        if not spots:
            return diag
        _, i, j = min(spots)                 # smallest nonzero entry becomes the pivot
        a[t], a[i] = a[i], a[t]
        for row in a:
            row[t], row[j] = row[j], row[t]
        if a[t][t] < 0:
            a[t] = [-x for x in a[t]]
        p = a[t][t]
        for i in range(t + 1, len(a)):       # row moves: divide with remainder
            q = a[i][t] // p
            a[i] = [x - q * y for x, y in zip(a[i], a[t])]
        for j in range(t + 1, len(a[0])):    # column moves: the same along the row
            q = a[t][j] // p
            for row in a:
                row[j] -= q * row[t]
        if any(a[i][t] for i in range(t + 1, len(a))) or any(a[t][t + 1:]):
            continue                         # a remainder is left: smaller than p, go again
        bad = [i for i in range(t + 1, len(a)) if any(x % p for x in a[i][t + 1:])]
        if bad:                              # p must divide the rest: add that row, go again
            a[t] = [x + y for x, y in zip(a[t], a[bad[0]])]
            continue
        diag.append(p)
        t += 1
def homology(d1, d2, n0, n1, n2):            # (rank, torsion) for H0, H1, H2
    s1, s2 = smith(d1), smith(d2)
    return [(n0 - len(s1), [d for d in s1 if d > 1]),
            (n1 - len(s1) - len(s2), [d for d in s2 if d > 1]), (n2 - len(s2), [])]
def show(h):
    return "; ".join(f"H{k}: rank {r}, torsion {t}" for k, (r, t) in enumerate(h))
def rank_q(m):                               # fraction-free elimination: exact rank over Q
    a, r, prev = [row[:] for row in m], 0, 1
    for c in range(len(a[0])):
        piv = next((i for i in range(r, len(a)) if a[i][c]), None)
        if piv is None: continue
        a[r], a[piv] = a[piv], a[r]
        for i in range(r + 1, len(a)):
            for j in range(c + 1, len(a[0])):
                num = a[i][j] * a[r][c] - a[i][c] * a[r][j]
                assert num % prev == 0
                a[i][j] = num // prev
            a[i][c] = 0
        prev, r = a[r][c], r + 1
    return r
def rank_p(m, p):                            # rank over Z mod p, p prime
    a, r = [[x % p for x in row] for row in m], 0
    for c in range(len(a[0])):
        piv = next((i for i in range(r, len(a)) if a[i][c]), None)
        if piv is None: continue
        a[r], a[piv] = a[piv], a[r]
        inv = pow(a[r][c], p - 2, p)
        for i in range(len(a)):
            if i != r and a[i][c]:
                f = a[i][c] * inv % p
                a[i] = [(x - f * y) % p for x, y in zip(a[i], a[r])]
        r += 1
    return r
def betti_field(d1, d2, n0, n1, n2, rank):  # Betti numbers over a field, from two ranks
    r1, r2 = rank(d1), rank(d2)
    return [n0 - r1, n1 - r1 - r2, n2 - r2]
def grid(flip):                              # 3 x 3 squares, each cut by one diagonal
    def v(i, j):
        j %= 3
        if i == 3:
            i, j = 0, (3 - j) % 3 if flip else j
        return 3 * i + j
    tris = sorted({tuple(sorted((v(i, j), v(i + 1, j), v(i + 1, j + 1)))) for i in range(3) for j in range(3)} |
                  {tuple(sorted((v(i, j), v(i, j + 1), v(i + 1, j + 1)))) for i in range(3) for j in range(3)})
    assert len(tris) == 18                   # no two triangles share their corners
    edges = sorted({e for x, y, z in tris for e in ((x, y), (x, z), (y, z))})
    d1 = [[(k == y) - (k == x) for x, y in edges] for k in range(9)]
    d2 = [[(e == (y, z)) - (e == (x, z)) + (e == (x, y)) for x, y, z in tris] for e in edges]
    return tris, edges, d1, d2
def minors2(m):                              # every 2 x 2 minor of a 3 x 2 matrix
    return [m[i][0] * m[j][1] - m[i][1] * m[j][0] for i in range(3) for j in range(i + 1, 3)]
print("figure, corners P0 (60,360) P1 (360,360) P2 (360,60) P3 (60,60); diagonal c (60,360) to (360,60)")
print(f"cell Klein bottle: 1 corner, 3 edges a b c, 2 triangles U L; d2 = {CELL}")
s1 = [CELL[0], [x - y for x, y in zip(CELL[1], CELL[0])], [x + y for x, y in zip(CELL[2], CELL[0])]]
s2 = [[r[0], r[1] - r[0]] for r in s1]
s3 = [s2[0], [-x for x in s2[1]], s2[2]]
print(f"step 1, clear column U: row b - row a, row c + row a -> {s1}")
print(f"step 2, clear row a: column L - column U -> {s2}")
print(f"step 3, row b times -1 -> {s3}")
mins, g1, g2 = minors2(CELL), 0, 0
for x in sum(CELL, []): g1 = gcd(g1, x)
for x in mins: g2 = gcd(g2, x)
print(f"Smith diagonal, cell Klein: {smith(CELL)}; of [[2, 0], [0, 3]]: {smith([[2, 0], [0, 3]])}; of [[4, 6]]: {smith([[4, 6]])}")
print(f"gcd road: entries {g1}, 2x2 minors {mins} -> {g2}, so d_2 = {g2 // g1}")
print(f"boundary of U - L, in a b c: {[r[0] - r[1] for r in CELL]}; of U + L: {[r[0] + r[1] for r in CELL]}")
cell_h = homology([[0, 0, 0]], CELL, 1, 3, 2)
print(f"cell Klein: {show(cell_h)}")
results = {}
for name, flip in (("Klein", True), ("torus", False)):
    tris, edges, d1, d2 = grid(flip)
    on_two = all(sum(1 for t in tris if set(e) <= set(t)) == 2 for e in edges)
    zero = all(sum(d1[k][e] * d2[e][t] for e in range(27)) == 0 for k in range(9) for t in range(18))
    sd1, sd2, h = smith(d1), smith(d2), homology(d1, d2, 9, len(edges), len(tris))
    results[name] = (d1, d2, h)
    print(f"grid {name}: {9} corners, {len(edges)} edges, {len(tris)} triangles; "
          f"each edge on 2 triangles: {'yes' if on_two else 'no'}; d1 d2 = 0: {'yes' if zero else 'no'}")
    print(f"grid {name}: Smith d1 has {sd1.count(1)} ones, others {[d for d in sd1 if d > 1]}; "
          f"Smith d2 has {sd2.count(1)} ones, others {[d for d in sd2 if d > 1]}")
    print(f"grid {name}: {show(h)}")
d1, d2, kh = results["Klein"]
bq = betti_field(d1, d2, 9, 27, 18, rank_q)
print(f"Euler characteristic: 9 - 27 + 18 = {9 - 27 + 18}; Betti over Q {bq[0]} - {bq[1]} + {bq[2]} = {bq[0] - bq[1] + bq[2]}")
print(f"Klein over Q, fraction-free elimination: {bq}")
rule = {}
for p in (2, 3):
    direct = betti_field(d1, d2, 9, 27, 18, lambda m: rank_p(m, p))
    t = [sum(1 for d in tor if d % p == 0) for _, tor in kh]
    rule[p] = [kh[k][0] + t[k] + (t[k - 1] if k else 0) for k in range(3)]
    print(f"Klein over Z mod {p}: elimination {direct}, counting rule from Smith {rule[p]}")
    assert direct == rule[p]
tq, t2 = (betti_field(*results["torus"][:2], 9, 27, 18, r) for r in (rank_q, lambda m: rank_p(m, 2)))
print(f"torus over Q {tq}, over Z mod 2 {t2}")
unsigned = [[abs(x) for x in row] for row in CELL]
print(f"mistake 1, signs dropped: d2 = {unsigned}, Smith {smith(unsigned)} -> {show(homology([[0, 0, 0]], unsigned, 1, 3, 2))}")
print(f"mistake 2, ranks over Q only: H1 rank {bq[1]}, torsion seen: none")
print(f"mistake 3, mod 2 count read as free loops: {rule[2][1]} loops, the torus's count")
print(f"mistake 4, rank of d1 forgotten: 27 - {rank_q(d2)} = {27 - rank_q(d2)} loops")
assert smith(CELL) == [1, 2] and g2 // g1 == 2 and s3 == [[1, 0], [0, 2], [0, 0]]   # reduction meets minors
assert smith([[2, 0], [0, 3]]) == [1, 2 * 3] and smith([[4, 6]]) == [gcd(4, 6)]   # 2 | 3 forced; Euclid
assert cell_h == kh == [(1, []), (1, [2]), (0, [])]         # cell model meets triangulation
assert bq == [kh[0][0], kh[1][0], kh[2][0]] == [1, 1, 0]    # Q ranks meet Smith ranks
assert results["torus"][2] == [(1, []), (2, []), (1, [])] and tq == t2 == [1, 2, 1]
print("ALL CHECKS PASS")
