# Quadratic forms -- the check behind the card.  Nothing is imported.  Two assets,
# monthly returns in percentage points, variances 4 and 9 and covariance 1, so the
# matrix is [[4, 1], [1, 9]].  The variance of a mix is reached by two roads that
# share no arithmetic: the matrix product x^T A x, and the average of the squared
# departures of the blended eight-month table.  The top eigenvalue is reached twice
# too: by the quadratic formula on trace and determinant, and by repeated multiplying.
A = [[4.0, 1.0], [1.0, 9.0]]
INDEP = [[4.0, 0.0], [0.0, 9.0]]                  # the same variances, covariance dropped
B, NEG = [[1.0, 2.0], [2.0, 1.0]], [[-4.0, -1.0], [-1.0, -9.0]]   # two counter-examples
P = [2, 2, 2, 2, -2, -2, -2, -2]                  # asset one, departures from its average
R = [5, 1, -1, -3, -5, -1, 1, 3]                  # asset two, departures from its average
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def form(a, x): return dot(x, [dot(a[0], x), dot(a[1], x)])       # road one: x^T A x
def det(a): return a[0][0] * a[1][1] - a[0][1] * a[1][0]
def from_table(x):                                # road two: average squared departure
    return sum((x[0] * p + x[1] * r) ** 2 for p, r in zip(P, R)) / len(P)
def eigs(a):                                      # roots of lam^2 - trace lam + det
    tr, gap = a[0][0] + a[1][1], ((a[0][0] + a[1][1]) ** 2 - 4 * det(a)) ** 0.5
    return [(tr + gap) / 2, (tr - gap) / 2]
def top_by_multiplying(a, steps=60):              # second road to the top eigenvalue
    v = [1.0, 1.0]
    for _ in range(steps):
        v = [dot(a[0], v), dot(a[1], v)]
        v = [v[0] / max(abs(v[0]), abs(v[1])), v[1] / max(abs(v[0]), abs(v[1]))]
    return form(a, v) / dot(v, v)                 # the score per unit of squared length
def row(name, vals): print(f"{name:<23}" + "".join(f"{v:>7.2f}" for v in vals))
grid, lam, best = [i / 10 for i in range(11)], eigs(A), 8 / 11
scan = [form(A, [i / 10000, 1 - i / 10000]) for i in range(10001)]
low, argw = min(scan), scan.index(min(scan)) / 10000
q2, q1, q0 = A[0][0] - 2 * A[0][1] + A[1][1], 2 * A[0][1] - 2 * A[1][1], A[1][1]
print("matrix rows: (4, 1) and (1, 9), in percent squared")
print("asset one departures:" + "".join(f"{p:>4}" for p in P))
print("asset two departures:" + "".join(f"{r:>4}" for r in R))
print(f"from the table: variances {from_table([1, 0]):.6f} and {from_table([0, 1]):.6f}, covariance "
      f"{(from_table([1, 1]) - from_table([1, 0]) - from_table([0, 1])) / 2:.6f}")
print(f"half and half: matrix road {form(A, [0.5, 0.5]):.6f}, table road {from_table([0.5, 0.5]):.6f}")
row("blended half and half", [0.5 * p + 0.5 * r for p, r in zip(P, R)])
print(f"eigenvalues {lam[0]:.6f} and {lam[1]:.6f}, sum {lam[0] + lam[1]:.6f}, product {lam[0] * lam[1]:.6f}")
print(f"top eigenvalue by repeated multiplying {top_by_multiplying(A):.6f}, and for [[4, 0], [0, 9]] "
      f"{top_by_multiplying(INDEP):.6f}")
print(f"three tests: entry {A[0][0]:.6f} > 0, determinant {det(A):.6f} > 0, smaller eigenvalue {lam[1]:.6f} > 0")
print(f"fully invested coefficients: w^2 {q2:.6f}, w {q1:.6f}, constant {q0:.6f}")
print(f"best fully invested mix {best:.6f} and {1 - best:.6f}, in whole parts 8 to 3")
print(f"smallest variance: 35/11 is {35 / 11:.6f}, matrix road {form(A, [best, 1 - best]):.6f}, scan of "
      f"10001 mixes {low:.6f} at weight {argw:.6f}")
row("weight in asset one", grid)
row("variance, covariance 1", [form(A, [w, 1 - w]) for w in grid])
row("variance, covariance 0", [form(INDEP, [w, 1 - w]) for w in grid])
print(f"wrong: covariance dropped {form(INDEP, [0.5, 0.5]):.6f}, cross term counted once "
      f"{4 * 0.25 + 0.25 + 9 * 0.25:.6f}, hold nothing at all {form(A, [0.0, 0.0]):.6f}")
print(f"positive diagonal is not enough: [[1, 2], [2, 1]] eigenvalues {eigs(B)[0]:.6f} and {eigs(B)[1]:.6f}, "
      f"score at (1, -1) {form(B, [1.0, -1.0]):.6f}")
print(f"never zero is not enough: [[-4, -1], [-1, -9]] scores {form(NEG, [0.5, 0.5]):.6f} at half and half")
assert all(abs(from_table([w, 1 - w]) - form(A, [w, 1 - w])) < 1e-12 for w in grid)
assert abs(top_by_multiplying(A) - lam[0]) < 1e-9 and abs(top_by_multiplying(INDEP) - 9.0) < 1e-9
assert abs(low - 35 / 11) < 1e-7 and abs(argw - best) < 1e-3 and all(v >= 35 / 11 - 1e-12 for v in scan)
assert all((min(eigs(m)) > 0) == (m[0][0] > 0 and det(m) > 0) for m in (A, INDEP, B, NEG)) \
    and form(B, [1.0, -1.0]) == -2.0 and min(eigs(B)) < 0 < max(eigs(B)) and form(NEG, [0.5, 0.5]) < 0
print("ALL CHECKS PASS")
