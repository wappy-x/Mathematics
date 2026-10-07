# The adjacency matrix -- the check behind the card.  Nothing is imported.  The
# metro: stations A to F, lines A-B B-C C-D D-E E-F F-A and the crossings B-E
# and C-F.  Walk counts come twice over: from multiplying the table of ones and
# zeros out, and from stepping along the neighbour lists, which forms no matrix.
NAMES, N = "ABCDEF", 6
EDGES = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]
A = [[0] * N for _ in range(N)]
for u, v in EDGES:
    A[u][v] = A[v][u] = 1
nbr = [[v for v in range(N) if A[u][v]] for u in range(N)]
deg = [len(nbr[u]) for u in range(N)]
def mul(P, Q):                       # road one: each row against each column
    return [[sum(P[i][h] * Q[h][j] for h in range(N)) for j in range(N)] for i in range(N)]
def tris(G):                         # triangles by listing, on any map
    return sum(1 for a in range(N) for b in range(a + 1, N) for c in range(b + 1, N) if G[a][b] and G[a][c] and G[b][c])
def routes(i, j, k):                 # road two: every k-line route, written out
    if k == 0:
        return [NAMES[i]] if i == j else []
    return [NAMES[i] + "-" + t for h in nbr[i] for t in routes(h, j, k - 1)]
def nofix(i, j, k, seen):            # the same, refusing a station twice
    if k == 0:
        return int(i == j)
    return sum(nofix(h, j, k - 1, seen | {h}) for h in nbr[i] if h not in seen)
def row(v): return " ".join(str(x) for x in v)
A2 = mul(A, A)
A3 = mul(A2, A)
diag2 = [A2[u][u] for u in range(N)]
plus = [[int(A[u][v] or {u, v} == {0, 2}) for v in range(N)] for u in range(N)]   # the metro plus a line A-C
p3 = mul(mul(plus, plus), plus)
tr2, tr3, tri, trp, trip = sum(diag2), sum(A3[u][u] for u in range(N)), tris(A), sum(p3[u][u] for u in range(N)), tris(plus)
inc = [[int(v in e) for v in range(N)] for e in EDGES]       # one row per line
gram = [[sum(r[u] * r[v] for r in inc) for v in range(N)] for u in range(N)]
plusdeg = [[A[u][v] + deg[u] * int(u == v) for v in range(N)] for u in range(N)]
wait = [[A[u][v] + int(u == v) for v in range(N)] for u in range(N)]
wait3 = mul(mul(wait, wait), wait)
three = routes(0, 5, 3)
agree = all(len(routes(i, j, k)) == (A, A2, A3)[k - 1][i][j]
            for k in (1, 2, 3) for i in range(N) for j in range(N))
print(f"metro: {N} stations, {len(EDGES)} lines; the table A, rows and columns A to F, row sum at the right")
for u in range(N):
    print(f"  {NAMES[u]}  {row(A[u])}   sum {deg[u]}")
print(f"A^2 diagonal: {row(diag2)}, the degrees; trace {tr2} = 2 x {len(EDGES)} lines")
print(f"A^2 row A: {row(A2[0])} -- the 0 under F is parity, not distance, since A-F is a line")
print(f"A^3 row A: {row(A3[0])}")
print(f"three-line routes A to F: {A3[0][5]} from the table, {len(three)} from the list; "
      f"the two roads agree for k = 1, 2, 3: {'yes' if agree else 'no'}")
print("the six: " + " ".join(three))
print(f"never repeating a station: {nofix(0, 5, 3, {0})}, namely A-B-C-F and A-B-E-F")
print(f"trace A^3 = {tr3}, triangles = trace / 6 = {tr3 // 6}, by listing {tri}; plus a line A-C: trace {trp}, triangles {trp // 6}, by listing {trip}")
print(f"line-by-station table M: {len(EDGES)} rows x {N} columns, {sum(sum(r) for r in inc)} ones, "
      f"column sums {row([sum(r[v] for r in inc) for v in range(N)])}")
print(f"M transposed times M equals A plus the degrees down the diagonal: {'yes' if gram == plusdeg else 'no'}")
print(f"mistake, squaring cell by cell: (A, F) reads {A[0][5] * A[0][5]}, not {A2[0][5]}")
print(f"mistake, a 1 down the diagonal to allow waiting: three-line A to F reads {wait3[0][5]}, not {A3[0][5]}")
assert agree
assert diag2 == deg and tr2 == 2 * len(EDGES)
assert gram == plusdeg and tr3 == 6 * tri and trp == 6 * trip
assert len(three) == 6 and nofix(0, 5, 3, {0}) == 2 and A2[0][5] == 0 and A[0][5] == 1
print("ALL CHECKS PASS")
