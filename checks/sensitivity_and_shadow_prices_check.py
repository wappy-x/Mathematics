# Shadow prices: the workshop LP.  Maximise 19x1 + 20x2 pounds (x1 tables, x2
# chairs); timber 4x1 + 2x2 <= 160 m, labour 3x1 + x2 <= 120 h, finish x1 + 2x2 <= 64 l.
# Road 1 reads prices, reduced costs and ranges off the final simplex tableau.
# Road 2 finds the dual prices by listing the dual's corners.  Road 3 re-solves
# the LP at shifted limits by listing every corner.  Exact fractions throughout.
from fractions import Fraction as F
from itertools import combinations
C, B = [F(19), F(20)], [F(160), F(120), F(64)]
A = [[F(4), F(2)], [F(3), F(1)], [F(1), F(2)]]
NAMES, COLS = ["timber", "labour", "finish"], ["x1", "x2", "s1", "s2", "s3"]

def fmt(q):                          # whole, short decimal, or a/b
    if q.denominator == 1: return str(q.numerator)
    for k in (1, 2, 3):
        if 10 ** k % q.denominator == 0: return f"{float(q):.{k}f}"
    return f"{q.numerator}/{q.denominator}"

def solve(M, v):                     # Gaussian elimination; None if singular
    n = len(v); M = [row[:] + [v[i]] for i, row in enumerate(M)]
    for k in range(n):
        p = next((r for r in range(k, n) if M[r][k] != 0), None)
        if p is None: return None
        M[k], M[p] = M[p], M[k]
        for r in range(n):
            if r != k and M[r][k] != 0:
                f = M[r][k] / M[k][k]; M[r] = [a - f * b for a, b in zip(M[r], M[k])]
    return [M[i][n] / M[i][i] for i in range(n)]

def best(c, A, b):                   # max c.x, Ax <= b, x >= 0: try every corner
    n = len(c); rows = A + [[F(-(i == j)) for j in range(n)] for i in range(n)]
    rhs = b + [F(0)] * n; top = None
    for pick in combinations(range(len(rows)), n):
        x = solve([rows[i] for i in pick], [rhs[i] for i in pick])
        if x is None or any(sum(a * xi for a, xi in zip(r, x)) > h for r, h in zip(rows, rhs)):
            continue
        z = sum(ci * xi for ci, xi in zip(c, x))
        if top is None or z > top[0]: top = (z, x)
    return top

def z_at(i, level):                  # best profit with limit i moved to `level`
    b = B[:]; b[i] = F(level); return best(C, A, b)[0]

# Road 1: simplex, Dantzig's rule (most negative profit-row entry enters)
T = [A[i] + [F(int(i == j)) for j in range(3)] + [B[i]] for i in range(3)]
z = [-x for x in C] + [F(0)] * 4
basis, path = [2, 3, 4], []
while min(z[:-1]) < 0:
    e = z.index(min(z[:-1]))
    r = min((T[i][-1] / T[i][e], i) for i in range(3) if T[i][e] > 0)[1]
    path.append(f"{COLS[e]} in, {COLS[basis[r]]} out"); basis[r] = e
    T[r] = [x / T[r][e] for x in T[r]]
    for i in range(3):
        if i != r: T[i] = [a - T[i][e] * p for a, p in zip(T[i], T[r])]
    z = [a - z[e] * p for a, p in zip(z, T[r])]
print("pivots: " + "; ".join(path))
print(f"{'final tableau':<14}" + "".join(f"{h:>7}" for h in COLS + ["rhs"]))
for i in range(3): print(f"{'row ' + COLS[basis[i]]:<14}" + "".join(f"{fmt(x):>7}" for x in T[i]))
print(f"{'profit row':<14}" + "".join(f"{fmt(x):>7}" for x in z))
y = [z[2 + i] for i in range(3)]
print("shadow prices, pounds per unit:", ", ".join(f"{n} {fmt(p)}" for n, p in zip(NAMES, y)))
ranges = []
for i in range(3):                   # basic values move by delta * slack column
    lo, hi = None, None
    for r in range(3):
        a, v = T[r][2 + i], T[r][-1]
        if a > 0: lo = max(lo, -v / a) if lo is not None else -v / a
        if a < 0: hi = min(hi, v / -a) if hi is not None else v / -a
    ranges.append((B[i] + lo, None if hi is None else B[i] + hi))
    print(f"{NAMES[i]} price {fmt(y[i])} holds from {fmt(ranges[i][0])} to "
          f"{'no limit' if hi is None else fmt(ranges[i][1])}")
margins = []
for j in range(2):                   # a margin moves the profit row by eps * its row
    r, out = basis.index(j), [k for k in range(5) if k not in basis]
    lo = max(-z[k] / T[r][k] for k in out if T[r][k] > 0)
    hi = min(z[k] / -T[r][k] for k in out if T[r][k] < 0); margins.append((C[j] + lo, C[j] + hi))
    print(f"{['table', 'chair'][j]} margin {fmt(C[j])}: plan stays best from {fmt(C[j] + lo)} to {fmt(C[j] + hi)}")
# Road 2: the dual (minimise 160y1 + 120y2 + 64y3, each product's margin covered)
At = [[-A[i][j] for i in range(3)] for j in range(2)]
dv, dy = best([-b for b in B], At, [-c for c in C])
print("dual by its corners: y =", ", ".join(fmt(v) for v in dy), "| dual value", fmt(-dv))
# Road 3: re-solve by listing corners, at shifted limits
zs, xs = best(C, A, B)
print(f"primal by its corners: tables {fmt(xs[0])}, chairs {fmt(xs[1])}, profit {fmt(zs)}")
for i, (lo, hi) in enumerate(ranges):
    top = hi if hi is not None else lo + 50
    print(f"{NAMES[i]} at {fmt(lo - 1)}, {fmt(lo)}, {fmt(top)}, {fmt(top + 1)}: profit "
          + ", ".join(fmt(z_at(i, v)) for v in (lo - 1, lo, top, top + 1)))
lab = (z_at(1, 112) - z_at(1, 32)) / 80
print(f"labour below 112 h: profit {fmt(z_at(1, 111))} at 111 h; price {fmt(lab)} an hour from 32 to 112")
stool = [F(1), F(1), F(1)]
for m in (9, 11):
    r_j = sum(p * a for p, a in zip(y, stool)) - m   # value used minus margin
    C3, A3 = C + [F(m)], [row + [s] for row, s in zip(A, stool)]
    z3, x3 = best(C3, A3, B)
    print(f"stool at {m}: profit-row entry {fmt(r_j)}; re-solved tables {fmt(x3[0])}, chairs {fmt(x3[1])}, "
          f"stools {fmt(x3[2])}, profit {fmt(z3)}")
force = lambda k: best(C3[:2] + [F(9)], A3 + [[F(0), F(0), F(-1)]], B + [F(-k)])[0]
print(f"stool at 9, forced: 1 stool {fmt(force(1))}, 16 stools {fmt(force(16))}")
print(f"finish at 40: one litre more adds {fmt(z_at(2, 41) - z_at(2, 40))}, one fewer loses {fmt(z_at(2, 40) - z_at(2, 39))}")
print(f"mistake, 100 more litres at 7: predicts {fmt(zs + 700)}, true {fmt(z_at(2, 164))}")
print(f"mistake, labour at its average: {float(zs / B[1]):.2f} an hour, true {fmt(z_at(1, 121) - zs)}")
print(f"mistake, one fewer litre at 40 at 7: predicts {fmt(z_at(2, 40) - 7)}, true {fmt(z_at(2, 39))}")
pts = list(range(0, 201, 20))
print("chart, finish litres:", " ".join(str(p) for p in pts))
print("chart, best profit:", " ".join(fmt(z_at(2, p)) for p in pts))
X, Y = (lambda t: F(50) + F(16, 5) * t), (lambda c: F(300) - F(16, 5) * c)
pt = lambda t, c: f"({float(X(t)):.1f} {float(Y(c)):.1f})"
print("figure, best", pt(32, 16), "origin", pt(0, 0), "timber", pt(0, 80), pt(40, 0), "finish64", pt(0, 32),
      pt(64, 0), "labour", pt(F(35, 3), 85), "finish40", pt(0, 20), "finish160", pt(64, 48))
assert y == dy and -dv == zs == z[-1] == 928           # tableau prices = dual corners
assert [xs[0], xs[1]] == [T[basis.index(0)][-1], T[basis.index(1)][-1]] == [32, 16]
for i, (lo, hi) in enumerate(ranges):                  # re-solves confirm price and ends
    top = hi if hi is not None else lo + 50
    assert z_at(i, top) - z_at(i, lo) == y[i] * (top - lo)
    assert z_at(i, lo) - z_at(i, lo - 1) != y[i]
    assert hi is None or z_at(i, hi + 1) - z_at(i, hi) != y[i]
assert ranges[2] == (40, 160) and ranges[0] == (64, F(848, 5)) and lab == F(18, 5)
assert z_at(1, 72) * 2 == z_at(1, 32) + z_at(1, 112) and z_at(1, 32) - z_at(1, 31) != lab
assert force(1) == zs - 1 and force(16) == zs - 16 and z3 == zs - 16 * r_j   # reduced cost x stools
assert z_at(2, 65) - zs == y[2] and z_at(0, 161) - zs == y[0] and z_at(1, 121) == zs
for j, (lo, hi) in enumerate(margins):                # re-solve at, and past, each margin end
    for m, stays in ((lo, True), (hi, True), (lo - 1, False), (hi + 1, False)):
        c2 = C[:]; c2[j] = m; zz = best(c2, A, B)[0]
        assert (zz == c2[0] * 32 + c2[1] * 16) == stays
print("ALL CHECKS PASS")
