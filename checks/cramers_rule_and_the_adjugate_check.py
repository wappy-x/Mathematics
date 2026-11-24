# Cramer's rule and the adjugate -- the check behind the card.  Nothing is imported.  The cafe's
# prices come out three ways: Cramer's ratios of determinants, the adjugate times the takings over
# det A, and plain elimination.  Every multiply and divide is counted, to compare the costs.
A, b, OPS = [[2, 1, 1], [1, 1, 2], [1, 2, 1]], [13, 11, 12], [0]   # a row per day: coffee, pastry, juice; OPS counts
def det(M):                             # cofactor expansion along the top row (OPS: multiplies and divides)
    if len(M) == 1: return M[0][0]
    OPS[0] += len(M)
    return sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)))
def with_col(M, j, v): return [r[:j] + [v[i]] + r[j + 1:] for i, r in enumerate(M)]
def minor(M, i, j): return [r[:j] + r[j + 1:] for k, r in enumerate(M) if k != i]
def cofactors(M, s=1): return [[(-1) ** (s * (i + j)) * det(minor(M, i, j)) for j in range(len(M))] for i in range(len(M))]
def flip(M): return [list(col) for col in zip(*M)]          # rows become columns
def mul(P, Q): return [[sum(p * q for p, q in zip(r, c)) for c in zip(*Q)] for r in P]
def mv(P, v): return [sum(p * q for p, q in zip(r, v)) for r in P]
def cramer(M, v):                       # road 1: one determinant over another, n times
    d = det(M); OPS[0] += len(M)
    return [det(with_col(M, j, v)) / d for j in range(len(M))]
def eliminate(M, v):                    # road 3: elimination, then back-substitution
    n, T = len(M), [r[:] + [v[i]] for i, r in enumerate(M)]
    for k in range(n):
        for i in range(k + 1, n):
            f = T[i][k] / T[k][k]; OPS[0] += 1 + n - k
            T[i] = T[i][:k + 1] + [T[i][j] - f * T[k][j] for j in range(k + 1, n + 1)]
    x = [0.0] * n
    for i in reversed(range(n)):
        OPS[0] += n - i; x[i] = (T[i][n] - sum(T[i][j] * x[j] for j in range(i + 1, n))) / T[i][i]
    return x
def vec(v): return "(" + ", ".join(f"{x:g}" for x in v) + ")"
def mat(M): return "[" + ", ".join(vec(r)[1:-1].join("[]") for r in M) + "]"
def P(n): return 0 if n == 1 else n * (P(n - 1) + 1)        # products in one n by n expansion
def cost(n): return (n + 1) * P(n) + n, sum(m * m - 1 for m in range(1, n + 1)) + n * (n + 1) // 2
def sci(x): e = len(str(int(x))) - 1; return f"{x / 10 ** e:.2f} x 10^{e}"
d, dets, x1, C = det(A), [det(with_col(A, j, b)) for j in range(3)], cramer(A, b), cofactors(A); adj = flip(C)
x2, x3, inv = [v / d for v in mv(adj, b)], eliminate(A, b), [[v / d for v in r] for r in adj]
print(f"cafe A = {mat(A)}   takings b = {vec(b)}   det A = {d}")
print(f"takings put in column 1, 2, 3: determinants {vec(dets)}; Cramer: prices {vec(x1)}\ntop-row terms: " + "; ".join(
    k + " " + " ".join(f"{(-1) ** j * M[0][j] * det(minor(M, 0, j)):+g}" for j in range(3)) for k, M in [("A", A)] + [(f"A_{j + 1}", with_col(A, j, b)) for j in range(3)]))
print(f"cofactor table C = {mat(C)}   adjugate = C flipped = {mat(adj)}")
print(f"adj(A) b = {vec(mv(adj, b))}   A adj(A) = {mat(mul(A, adj))} = adj(A) A")
print(f"inverse = adj(A) / det A = {mat(inv)}")
print(f"adjugate road: prices {vec(x2)}   elimination road: {vec(x3)}   A x = {vec(mv(A, x1))}")
for n in (3, 4, 6):                     # count the work on a test system, then match the formulas
    M, v = [[n if i == j else 1 for j in range(n)] for i in range(n)], list(range(1, n + 1))
    OPS[0] = 0; cramer(M, v); cr = OPS[0]; OPS[0] = 0; eliminate(M, v); assert (cr, OPS[0]) == cost(n)
    print(f"n = {n}: Cramer by cofactors {cr} products, elimination {OPS[0]} (counted = formula)")
print(f"n = 10: Cramer {sci(cost(10)[0])}, elimination {cost(10)[1]}; at a billion a second {cost(10)[0] / 1e9:.3f} seconds")
print(f"n = 20: Cramer {sci(cost(20)[0])}, elimination {cost(20)[1]}; Cramer {cost(20)[0] / 1e9 / 31557600:.0f} years")
S, bs, Z, plain = [[2, 1, 1], [1, 1, 1], [1, 2, 1]], [17, 13, 16], [[2, 1, 1], [1, 1, 2], [3, 2, 3]], [v / d for v in mv(flip(cofactors(A, 0)), b)]
print(f"mistakes: minors with no signs {vec(plain)}; sandwich cafe, table not flipped "
      f"{vec([v / det(S) for v in mv(cofactors(S), bs)])} not {vec(cramer(S, bs))}")
print(f"singular cafe {mat(Z)}, takings (13, 11, 24): det {det(Z)}, column determinants "
      f"{vec([det(with_col(Z, j, [13, 11, 24])) for j in range(3)])}")
print(f"try changing: Monday $14 {vec(cramer(A, [14, 11, 12]))}; Tue and Wed swapped det {det([A[0], A[2], A[1]])} "
      f"prices {vec(cramer([A[0], A[2], A[1]], [13, 12, 11]))}; n = 25 Cramer {sci(cost(25)[0] / 1e9 / 31557600)} years")
assert d == -4 and dets == [-16, -12, -8] and x1 == [4, 3, 2] and mv(A, x1) == b
assert mv(adj, b) == dets and x2 == x1 and max(abs(p - q) for p, q in zip(x3, x1)) < 1e-12
assert mul(A, adj) == [[d if i == j else 0 for j in range(3)] for i in range(3)] == mul(adj, A)
assert cramer(S, bs) == [4, 3, 6] and det(Z) == 0 and mul(A, inv) == [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
assert mul(S, flip(cofactors(S))) == [[-1, 0, 0], [0, -1, 0], [0, 0, -1]]   # S is lopsided: the flip matters
print("ALL CHECKS PASS")
