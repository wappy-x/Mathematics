# The four fundamental subspaces -- the check behind the card.  Nothing is imported.
# A bakery: a small batch uses 1 kg butter, 2 sugar, 3 flour; a double batch twice that.
# Bases by elimination and by brute force; each stock report b is judged three ways.
A = [[1, 2], [2, 4], [3, 6]]; T = [list(c) for c in zip(*A)]   # T is A^T: rows and columns swapped
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def times(M, v): return [dot(row, v) for row in M]
def staircase(M):                                  # row moves until each pivot stands alone
    M, piv, r = [[float(x) for x in row] for row in M], [], 0
    for c in range(len(M[0])):
        s = next((i for i in range(r, len(M)) if abs(M[i][c]) > 1e-9), None)
        if s is None: continue                     # no pivot here: a free column
        M[r], M[s] = M[s], M[r]
        M[r] = [x / M[r][c] for x in M[r]]
        for i in range(len(M)):
            if i != r: M[i] = [a - M[i][c] * b for a, b in zip(M[i], M[r])]
        piv.append(c); r += 1
    return M, piv
def null_basis(M):                                 # one killed direction per free column
    R, piv = staircase(M); out = []
    for j in (c for c in range(len(M[0])) if c not in piv):
        v = [0.0] * len(M[0]); v[j] = 1.0
        for i, c in enumerate(piv): v[c] = -R[i][j]
        out.append(v)
    return out
def num(x): return str(int(round(x))) if abs(x - round(x)) < 1e-9 else f"{x:.4f}"
def show(v): return "(" + ", ".join(num(x) for x in v) + ")"
(R, piv), yn = staircase(A), lambda c: "yes" if c else "no"
rank = len(piv); rows, cols = R[:rank], [[row[c] for row in A] for c in piv]   # row space, column space
nul, lnul = null_basis(A), null_basis(T)                         # null, left null space
grid = range(-3, 4)                                # road 2: every whole-number vector
nul_bf = [[a, b] for a in grid for b in grid if (a, b) != (0, 0) and times(A, [a, b]) == [0, 0, 0]]
lnul_bf = [[a, b, c] for a in grid for b in grid for c in grid
           if (a, b, c) != (0, 0, 0) and times(T, [a, b, c]) == [0, 0]]
on_nul = all(v == [v[1] * x for x in nul[0]] for v in nul_bf)
on_lnul = all(v == [v[1] * p + v[2] * q for p, q in zip(*lnul)] for v in lnul_bf)
perp = [dot(r, z) for r in rows for z in nul] + [dot(c, y) for c in cols for y in lnul]
print(f"A = {A}: rank {rank}; row space {show(rows[0])}; null space {show(nul[0])}")
print(f"column space {show(cols[0])}; left null space {show(lnul[0])}, {show(lnul[1])}")
print(f"sizes: {rank} + {len(nul)} = {len(T)} inputs, {rank} + {len(lnul)} = {len(A)} outputs")
print(f"perpendicular pairs, every dot product: {show(perp)}")
print(f"brute force -3..3: {len(nul_bf)} null, {len(lnul_bf)} left null, all built from the bases: {yn(on_nul and on_lnul)}")
x = [3, 1]; part = [dot(x, rows[0]) / dot(rows[0], rows[0]) * t for t in rows[0]]
print(f"order {show(x)} = row part {show(part)} + null part {show([a - b for a, b in zip(x, part)])}; "
      f"kg used {show(times(A, x))} and {show(times(A, part))}")
verdicts = []
for b in ([1, 0, 0], [5, 10, 15], [1, 2, 0]):
    tests = [dot(y, b) for y in lnul]
    aug = len(staircase([row + [bi] for row, bi in zip(A, b)])[1])
    p = [dot(b, cols[0]) / dot(cols[0], cols[0]) * t for t in cols[0]]
    left = [bi - pi for bi, pi in zip(b, p)]; gap = dot(left, left) ** 0.5; assert max(map(abs, times(T, left))) < 1e-9
    verdicts.append((all(abs(t) < 1e-9 for t in tests), aug == rank, gap < 1e-9))
    print(f"b = {show(b)}: tests {show(tests)}, rank [A | b] {aug}, nearest {show(p)}")
    print(f"   leftover {show(left)}, length {num(gap)}, A^T leftover {show(times(T, left))}")
print(f"mistake, a column as the test: {show(cols[0])} . (5, 10, 15) = {num(dot(cols[0], [5, 10, 15]))}\n"
      f"mistake, counting rows as the rank: nullity {len(T)} - {len(A)} = {len(T) - len(A)}")
assert rank == 1 and len(staircase(nul_bf)[1]) + rank == len(T) and len(lnul) + rank == len(A)
assert on_nul and on_lnul and len(nul_bf) == 2 and all(abs(p) < 1e-12 for p in perp)
assert verdicts == [(False,) * 3, (True,) * 3, (False,) * 3]  # three roads agree on each b
assert times(A, x) == times(A, [1, 2]) and dot(lnul[0], [1, 0, 0]) == -2
print("ALL CHECKS PASS")
