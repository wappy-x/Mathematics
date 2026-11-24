# Block designs and Fisher's inequality -- the check behind the card.  Nothing
# is imported.  The design is the Fano plane: 7 blends, 7 tasters, 3 blends
# each.  The counts are read off the schedule and from the two formulas; the
# determinant of N N^T is found three ways: by elimination, as (det N)^2 and
# from the closed form (r - lambda)^(v - 1) x r k.
LINES = [(1, 2, 4), (2, 3, 5), (3, 4, 6), (4, 5, 7), (5, 6, 1), (6, 7, 2), (7, 1, 3)]
v, b, k = 7, len(LINES), 3

def det(m):                                     # exact whole-number elimination (Bareiss)
    a, n, sign, prev = [row[:] for row in m], len(m), 1, 1
    for i in range(n):
        p = next((r for r in range(i, n) if a[r][i] != 0), None)
        if p is None:
            return 0                            # no pivot left: the matrix is flat
        if p != i:
            a[i], a[p], sign = a[p], a[i], -sign
        for r in range(i + 1, n):
            for c in range(i + 1, n):
                a[r][c] = (a[r][c] * a[i][i] - a[r][i] * a[i][c]) // prev
        prev = a[i][i]
    return sign * a[n - 1][n - 1]

def gram(n_mat):                                # N times N transposed
    return [[sum(x * y for x, y in zip(p, q)) for q in n_mat] for p in n_mat]

def counts(v, k, lam):                          # the two counts solved for r, then b = v r / k
    r = lam * (v - 1) / (k - 1)
    return r, v * r / k

N = [[1 if x in line else 0 for line in LINES] for x in range(1, v + 1)]
r_seen = sorted({sum(row) for row in N})        # road one: read the schedule
pairs = {(x, y): sum(x in L and y in L for L in LINES) for x in range(1, 8) for y in range(x + 1, 8)}
lam_seen = sorted(set(pairs.values()))
r = b * k // v                                  # road two: b k = v r ...
lam = r * (k - 1) // (v - 1)                    # ... and r(k - 1) = lambda(v - 1)
G = gram(N)
closed = (r - lam) ** (v - 1) * r * k
print(f"blocks: {LINES}")
print(f"v = {v}, b = {b}, k = {k}; each blend tasted {r_seen} times; each pair together {lam_seen} times")
print(f"b k = {b * k}, v r = {v * r}; r (k - 1) = {r * (k - 1)}, lambda (v - 1) = {lam * (v - 1)}")
print(f"pairs per taster {k * (k - 1) // 2} x {b} tasters = {b * k * (k - 1) // 2} = all {len(pairs)} pairs")
print(f"N N^T row 1: {G[0]}; diagonal {sorted({G[i][i] for i in range(v)})}, off-diagonal "
      f"{sorted({G[i][j] for i in range(v) for j in range(v) if i != j})}")
print(f"det(N N^T): elimination {det(G)}; (det N)^2 = ({det(N)})^2 = {det(N) ** 2}; "
      f"closed form {r - lam}^{v - 1} x {r * k} = {closed}")
print(f"rank N = {v} since det N is not 0, so b = {b} >= v = {v}")
tested = [(rr, ll, vv) for rr in range(2, 9) for ll in range(1, rr) for vv in range(2, 9)]
ok = all(det([[rr if i == j else ll for j in range(vv)] for i in range(vv)])
         == (rr - ll) ** (vv - 1) * (rr + (vv - 1) * ll) for rr, ll, vv in tested)
print(f"closed form against elimination on {len(tested)} small (r, lambda, v) cases: {'agree' if ok else 'DIFFER'}")
(r81, _), (r16, b16) = counts(8, 3, 1), counts(16, 6, 1)
print(f"mistake 1, (8, 3, 1): r = (8 - 1)/(3 - 1) = {r81:g}, not whole; upside down (3 - 1)/(8 - 1) = 1/r = {1 / r81:.2f}")
print(f"mistake 2, (16, 6, 1): r = {r16:g}, b = 16 x {r16:g} / 6 = {b16:g}, whole, but {b16:g} < 16")
one = [[1] for _ in range(v)]                   # one taster given all 7 blends
print(f"mistake 3, k = v: one block, N N^T = J, det {det(gram(one))}, so b = 1 < 7 is no contradiction")
assert r_seen == [r] and lam_seen == [lam] == [1] and counts(v, k, lam_seen[0]) == (r_seen[0], b)
assert det(G) == det(N) ** 2 == closed == 576 and ok
assert all(G[i][j] == (r - lam) * (i == j) + lam for i in range(v) for j in range(v))
assert det(gram(one)) == 0 and r81 % 1 != 0 and r16 % 1 == b16 % 1 == 0 and b16 < 16
print("ALL CHECKS PASS")
