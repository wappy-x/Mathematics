# Rank and nullity -- the check behind the card.  Nothing is imported.  P is the
# projector: a 3D model in, a flat screen picture out; B flattens harder.  Two roads
# to the rank: count the staircase's pivots, or take the biggest square block whose
# determinant is not zero.  Every number quoted on the card is printed below.
P = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]]           # keeps across and up, kills depth
B = [[1.0, 2.0, 3.0], [2.0, 4.0, 6.0]]           # row 2 is twice row 1
def combos(xs, k):                               # every k of the items, in order
    if k == 0 or len(xs) < k: return [[]] if k == 0 else []
    return [[xs[0]] + c for c in combos(xs[1:], k - 1)] + combos(xs[1:], k)
def det(M):                                      # determinant, expanding the top row
    if len(M) == 1: return M[0][0]
    return sum((-1) ** j * M[0][j] * det([r[:j] + r[j+1:] for r in M[1:]]) for j in range(len(M)))
def staircase(A):                                # legal row moves, until a pivot stands alone
    M, piv, r = [row[:] for row in A], [], 0
    for c in range(len(A[0])):
        s = next((i for i in range(r, len(M)) if abs(M[i][c]) > 1e-9), None)
        if s is None: continue                   # no pivot in this column: it is free
        M[r], M[s] = M[s], M[r]
        M[r] = [x / M[r][c] for x in M[r]]
        for i in range(len(M)):
            if i != r: M[i] = [a - M[i][c] * b for a, b in zip(M[i], M[r])]
        piv.append(c); r += 1
    return M, piv
def killed(A):                                   # one direction per column with no pivot
    M, piv, out = *staircase(A), []
    for j in (c for c in range(len(A[0])) if c not in piv):
        v = [0.0] * len(A[0]); v[j] = 1.0
        for i, c in enumerate(piv): v[c] = 0.0 - M[i][j]
        out.append(v)
    return out
def rank_by_blocks(A):                           # road 2: no elimination in here at all
    for k in range(min(len(A), len(A[0])), 0, -1):
        for rs in combos(list(range(len(A))), k):
            for cs in combos(list(range(len(A[0]))), k):
                if abs(det([[A[i][j] for j in cs] for i in rs])) > 1e-9: return k
    return 0
def apply(A, v): return [sum(a * b for a, b in zip(row, v)) for row in A]
def show(v): return "(" + ", ".join(f"{x:g}" for x in v) + ")"
def report(name, A):
    piv, ks, n = staircase(A)[1], killed(A), len(A[0])
    print(f"{name}: {len(A)} rows x {n} columns")
    print(f"  pivot columns             {', '.join(str(c + 1) for c in piv)}")
    print(f"  rank, by pivots           {len(piv)}")
    print(f"  rank, by biggest block    {rank_by_blocks(A)}")
    print(f"  nullity                   {len(ks)}")
    print(f"  killed directions         {', '.join(show(v) for v in ks)}")
    print(f"  rank + nullity            {len(piv)} + {len(ks)} = {len(piv) + len(ks)} = columns")
    return len(piv), ks
rP, kP = report("projector P = [[1, 0, 0], [0, 1, 0]]", P)
rB, kB = report("flattener B = [[1, 2, 3], [2, 4, 6]]", B)
front, back = [3.0, 4.0, 5.0], [3.0, 4.0, 9.0]
print(f"two model points            {show(front)} and {show(back)} both land on {show(apply(P, front))}")
print(f"their difference            {show([0.0, 0.0, 4.0])} = 4 x {show(kP[0])}, a killed direction")
print(f"every model point there     x = {show([3.0, 4.0, 0.0])} + t x {show(kP[0])}")
print(f"mistakes: rows - rank gives nullity {len(P) - rP} for P; B's {len(B)} nonzero rows read as rank {len(B)} give {len(B)} + {len(kB)} = {len(B) + len(kB)}, not {len(B[0])}")
assert rP == rank_by_blocks(P) and rB == rank_by_blocks(B)       # two roads, one rank
assert rP + len(kP) == len(P[0]) and rB + len(kB) == len(B[0])   # the theorem itself
assert all(max(abs(x) for x in apply(A, v)) < 1e-9 for A, ks in ((P, kP), (B, kB)) for v in ks)
assert apply(P, front) == apply(P, back) == [3.0, 4.0]           # depth moved, picture did not
print("ALL CHECKS PASS")
