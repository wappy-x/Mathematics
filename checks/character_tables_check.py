# Character tables -- the check behind the card.  Nothing is imported.  Each group is the list r^k f^m built from
# two generators.  Road one finds the classes by conjugating; road two finds the one-dimensional pieces by trying
# signs for r and f; road three is the trace of a 2-by-2 action.  Orthogonality, the regular representation and commutators cross-check.
def mat(p, q):                                  # 2-by-2 matrices, stored row by row
    return (p[0]*q[0] + p[1]*q[2], p[0]*q[1] + p[1]*q[3], p[2]*q[0] + p[3]*q[2], p[2]*q[1] + p[3]*q[3])
def quat(p, q):                                 # quaternions a + b i + c j + d k
    return (p[0]*q[0] - p[1]*q[1] - p[2]*q[2] - p[3]*q[3], p[0]*q[1] + p[1]*q[0] + p[2]*q[3] - p[3]*q[2],
            p[0]*q[2] - p[1]*q[3] + p[2]*q[0] + p[3]*q[1], p[0]*q[3] + p[1]*q[2] - p[2]*q[1] + p[3]*q[0])
def qmat(q): return (complex(q[0], q[1]), complex(q[2], q[3]), complex(-q[2], q[3]), complex(q[0], -q[1]))   # q0 + q1 i + q2 j + q3 k, complex
def fixed(g, corners):                          # corners a matrix sends to themselves
    return sum((g[0]*x + g[1]*y, g[2]*x + g[3]*y) == (x, y) for x, y in corners)
def ip(sizes, u, v):                            # sum over classes of size x row u x row v
    return sum(s * a * b for s, a, b in zip(sizes, u, v))
yn = lambda c: "yes" if c else "no"
def table(name, r, f, n, mul, one, act2):  # act2: a member's 2-by-2 matrix
    pw = lambda x, k: one if k == 0 else mul(pw(x, k - 1), x)
    G = [mul(pw(r, k), pw(f, m)) for m in (0, 1) for k in range(n)]
    inv = {x: next(y for y in G if mul(x, y) == one) for x in G}
    reps, classes = [], []                      # road one: conjugate each member by all
    for x in G:
        if not any(x in c for c in classes):
            reps.append(x); classes.append({mul(mul(h, x), inv[h]) for h in G})
    reps, classes = zip(*sorted(zip(reps, classes), key=lambda rc: len(rc[1])))   # smaller classes first
    sizes, rows = [len(c) for c in classes], []                 # road two: a sign for r, a sign for f
    for a, b in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        val = {G[m * n + k]: a**k * b**m for m in (0, 1) for k in range(n)}
        if all(val[mul(x, y)] == val[x] * val[y] for x in G for y in G):
            rows.append([val[x] for x in reps])
    ones = len(rows); rows.append([int((act2(x)[0] + act2(x)[3]).real) for x in reps])   # road three: trace of the 2-by-2 action
    hom2 = all(mat(act2(x), act2(y)) == act2(mul(x, y)) for x in G for y in G)            # ... and it respects products
    dims, big = [row[0] for row in rows], len(G)
    orth = all(ip(sizes, u, v) == (big if i == j else 0) for i, u in enumerate(rows) for j, v in enumerate(rows))
    reg = [sum(mul(h, x) == x for x in G) for h in reps]        # the regular representation
    split = [sum(d * row[c] for d, row in zip(dims, rows)) for c in range(len(reps))]
    comm = {mul(mul(x, y), mul(inv[x], inv[y])) for x in G for y in G}
    while any(mul(a, b) not in comm for a in comm for b in comm):
        comm |= {mul(a, b) for a in comm for b in comm}
    print(f"{name}: {big} members, {len(reps)} classes of sizes {sizes}, commutator subgroup of size {len(comm)}")
    print(f"{name} table: " + " ".join(str(row) for row in rows))
    print(f"{name}: {len(rows)} pieces, " + " + ".join(str(d * d) for d in dims) + f" = {sum(d * d for d in dims)}; "
          f"one-dim {ones} = {big} / {len(comm)}; rows orthonormal: {yn(orth)}; regular = dims x rows: {yn(reg == split)}")
    assert len(rows) == len(reps) and sum(d * d for d in dims) == big   # pieces = classes, squares add to |G|
    assert orth and reg == split and ones * len(comm) == big and all(mul(mul(x, y), z) == mul(x, mul(y, z)) for x in G for y in G for z in G)
    return reps, sizes, rows, sum(mul(x, x) == one for x in G) - 1, hom2
tr, ts, trows, t2, _ = table("tile", (0, -1, 1, 0), (1, 0, 0, -1), 4, mat, (1, 0, 0, 1), lambda g: g)
sr, ss, srows, _, _ = table("S3", (0, -1, 1, -1), (0, 1, 1, 0), 3, mat, (1, 0, 0, 1), lambda g: g)
qr, qs, qrows, q2, qhom = table("Q8", (0, 1, 0, 0), (0, 0, 1, 0), 4, quat, (1, 0, 0, 0), qmat)
by_corners = [fixed(g, [(1, 0), (0, 1), (-1, -1)]) - 1 for g in sr]
shuffle = [fixed(g, [(1, 0), (0, 1), (-1, 0), (0, -1)]) for g in tr]   # corners on the axes
holds = [ip(ts, shuffle, row) // 8 for row in trows]
rebuilt = [sum(h * row[c] for h, row in zip(holds, trows)) for c in range(5)]
print(f"S3 two-dim row by fixed corners minus 1: {by_corners}")
print(f"tile 4-by-4 corner shuffle by fixed corners: {shuffle}; copies of each piece: {holds}")
print(f"Q8's complex 2-by-2 matrices multiply like Q8: {yn(qhom)}; tile and Q8 tables identical: {yn(trows == qrows and ts == qs)}; members of order 2: tile {t2}, Q8 {q2}")
print(f"mistake 1, dimensions added, not squared: tile {sum(r[0] for r in trows)}, S3 {sum(r[0] for r in srows)}")
print(f"mistake 2, S3 trivial against sign without class sizes: {sum(a * b for a, b in zip(srows[0], srows[1]))}/6, not {ip(ss, srows[0], srows[1])}")
print(f"mistake 3, one piece per member: 8 one-dim pieces needed, {sum(r[0] == 1 for r in trows)} found")
assert by_corners == srows[-1] and rebuilt == shuffle            # two roads to the same rows
assert qhom and trows == qrows and ts == qs and (t2, q2) == (5, 1)   # one table, two different groups
print("ALL CHECKS PASS")
