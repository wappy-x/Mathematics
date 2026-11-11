# LP duality -- the check behind the card.  Standard library only, exact fractions.
# Workshop: maximise profit 19x1 + 20x2 pounds (x1 tables, x2 chairs) subject to
# timber 4x1 + 2x2 <= 160 m, labour 3x1 + x2 <= 120 h, finish x1 + 2x2 <= 64 litres, x >= 0.
# Dual: minimise 160y1 + 120y2 + 64y3 subject to 4y1 + 3y2 + y3 >= 19, 2y1 + y2 + 2y3 >= 20, y >= 0.
from fractions import Fraction as F
from itertools import combinations

A, B, C = [[4, 2], [3, 1], [1, 2]], [160, 120, 64], [19, 20]
RES, PROD = ["timber", "labour", "finish"], ["tables", "chairs"]
dot = lambda u, v: sum(p * q for p, q in zip(u, v))
col = lambda M, j: [row[j] for row in M]
num = lambda x: str(x) if F(x).denominator == 1 else f"{float(x):.2f}"
show = lambda v: "(" + ", ".join(num(x) for x in v) + ")"

def solve(M, v):                          # Gauss-Jordan elimination in fractions; None if singular
    n = len(v)
    T = [[F(x) for x in row] + [F(w)] for row, w in zip(M, v)]
    for i in range(n):
        p = next((r for r in range(i, n) if T[r][i] != 0), None)
        if p is None: return None
        T[i], T[p] = T[p], T[i]
        for r in range(n):
            f = T[r][i] / T[i][i]
            if r != i and f != 0: T[r] = [a - f * b for a, b in zip(T[r], T[i])]
    return [T[i][n] / T[i][i] for i in range(n)]

def corners(G, h):                        # every point where n walls of G z <= h meet and all hold
    out = []
    for rows in combinations(range(len(G)), len(G[0])):
        z = solve([G[r] for r in rows], [h[r] for r in rows])
        if z is not None and all(dot(g, z) <= w for g, w in zip(G, h)) and z not in out: out.append(z)
    return out

def simplex(A, b, c):                     # max c.x, Ax <= b, x >= 0, b >= 0; Dantzig's rule
    m, n = len(A), len(c)
    T = [[F(x) for x in A[i]] + [F(int(i == k)) for k in range(m)] + [F(b[i])] for i in range(m)]
    z, basis, path = [F(-x) for x in c] + [F(0)] * (m + 1), [n + i for i in range(m)], []
    while min(z[:-1]) < 0:
        j = z.index(min(z[:-1]))          # entering column: most negative reduced cost
        r = min((T[i][-1] / T[i][j], i) for i in range(m) if T[i][j] > 0)[1]
        T[r] = [x / T[r][j] for x in T[r]]
        for i in range(m):
            f = T[i][j]
            if i != r: T[i] = [a - f * q for a, q in zip(T[i], T[r])]
        f = z[j]; z = [a - f * q for a, q in zip(z, T[r])]; basis[r] = j
        x = [F(0)] * n
        for i, v in enumerate(basis):
            if v < n: x[v] = T[i][-1]
        path.append(x)
    return x, z[n:n + m], z[-1], path     # plan, prices on the slack columns, value, corners visited

G = A + [[-1, 0], [0, -1]]
pc = corners(G, B + [0, 0])
print("primal corners (tables, chairs) and profit: " + " | ".join(f"{show(p)} {dot(C, p)}" for p in pc))
x, y, val, path = simplex(A, B, C)
print(f"road 1, simplex (Dantzig's rule): {len(path)} pivots, path (0, 0) -> " + " -> ".join(show(p) for p in path))
print(f"road 1, best plan {x[0]} tables, {x[1]} chairs, profit {val}")
print("road 1, prices read off the final tableau: " + ", ".join(f"{n} {v}" for n, v in zip(RES, y)))
dc = corners([[-a for a in col(A, j)] for j in range(2)] + [[-int(i == k) for k in range(3)] for i in range(3)], [-c for c in C] + [0] * 3)
yb = min(dc, key=lambda v: dot(B, v))
print(f"road 2, dual corners checked: {len(dc)}; cheapest price list {show(yb)} worth {dot(B, yb)}")
y3 = solve([[4, 3, 1], [2, 1, 2], [0, 1, 0]], [19, 20, 0])
print(f"road 3, slackness equations 4y1 + 3y2 + y3 = 19, 2y1 + y2 + 2y3 = 20, y2 = 0: y = {show(y3)}")
print(f"duality gap at the best pair: {dot(B, y)} - {val} = {dot(B, y) - val}")
use = [dot(row, x) for row in A]
print("resource  used  limit  slack  price  price x slack")
for i in range(3):
    print(f"{RES[i]:8s}  {use[i]!s:>4}  {B[i]:5d}  {B[i] - use[i]!s:>5}  {y[i]!s:>5}  {y[i] * (B[i] - use[i])!s:>13}")
print("product  made  inputs at prices  profit  surplus  made x surplus")
for j in range(2):
    v = dot(col(A, j), y)
    print(f"{PROD[j]:7s}  {x[j]!s:>4}  {v!s:>16}  {C[j]:6d}  {v - C[j]!s:>7}  {x[j] * (v - C[j])!s:>14}")
yt = [3, 1, 7]; vt = [dot(col(A, j), yt) for j in range(2)]
s8, r = [B[i] - use[i] for i in range(3)], [vt[j] - C[j] for j in range(2)]
print(f"trial prices {show(yt)}: table inputs {vt[0]}, chair inputs {vt[1]}, total {dot(B, yt)}")
print(f"gap identity: {dot(B, yt)} - {val} = {dot(B, yt) - val} = " + " + ".join(
    [f"{yt[i]} x {s8[i]}" for i in range(3) if s8[i]] + [f"{x[j]} x {r[j]}" for j in range(2)]))
plans = [(t, c) for t in range(41) for c in range(33) if all(dot(row, (t, c)) <= w for row, w in zip(A, B))]
prices = [(a, b, d) for a in range(11) for b in range(11) for d in range(11) if all(dot(col(A, j), (a, b, d)) >= C[j] for j in range(2))]
gaps = [dot(B, q) - dot(C, p) for p in plans for q in prices]
print(f"weak duality grid: {len(plans)} whole-number plans x {len(prices)} price lists, smallest gap {min(gaps)}, zero gaps {gaps.count(0)}")
for bad in ([2, 0, 7], [8, -6, 5]):
    print(f"break, prices {show(bad)}: inputs {dot(col(A, 0), bad)} and {dot(col(A, 1), bad)}, total {dot(B, bad)}, below {val} by {val - dot(B, bad)}")
print(f"break, negative labour price: -6 x {s8[1]} spare hours = {-6 * s8[1]}")
A4, B4, w = A + [[0, -1]], B + [-40], [0, 0, 1, 2]   # add an order: x2 >= 40, written -x2 <= -40
none = corners(A4 + [[-1, 0], [0, -1]], B4 + [0, 0])
wa = [dot(col(A4, j), w) for j in range(2)]          # finish row + 2 x order row
print(f"break, order for 40 chairs: {len(none)} feasible corners; finish + 2 x order reads {wa[0]}x1 + {wa[1]}x2 <= {dot(B4, w)}")
yk = lambda k: [a + k * b for a, b in zip(y + [0], w)]
print(f"break, its dual: prices {show(y + [0])} + k x {show(w)} stay valid, value {dot(B, y)} - {-dot(B4, w)}k: "
      f"k = 10 -> {dot(B4, yk(10))}, k = 100 -> {dot(B4, yk(100))}")
y0 = solve([[1, 0, 0], [0, 1, 0], [2, 1, 2]], [0, 0, 20])
print(f"break, corner (0, 32): slackness prices {show(y0)}, tables valued {dot(col(A, 0), y0)} < 19, total {dot(B, y0)}")
tips = [[x[k] + y[i] * A[i][k] for k in range(2)] for i in (0, 2)] + [[x[k] + C[k] for k in range(2)]]
print("figure, corners " + " ".join(show(p) for p in pc) + f"; profit (19, 20) = {y[0]} x (4, 2) + {y[2]} x (1, 2); "
      "arrow tips " + " ".join(show(t) for t in tips))
fin, lab = simplex(A, [160, 120, 65], C), simplex(A, [160, 111, 64], C)
print(f"try, finish 65 litres: plan {show(fin[0])}, profit {fin[2]}, prices {show(fin[1])}")
print(f"try, labour 112 hours: profit {simplex(A, [160, 112, 64], C)[2]}; labour 111: plan {show(lab[0])}, "
      f"profit {num(lab[2])}, prices {show(lab[1])}")
ch = simplex(A, B, [19, 40])
print(f"try, chair profit 40: plan {show(ch[0])}, profit {ch[2]}, prices {show(ch[1])}")
assert val == 928 and x == [32, 16] and dot(B, y) == val                 # strong duality: equal values
assert max(dot(C, p) for p in pc) == val and yb == y and y3 == y         # three roads agree
assert min(gaps) == 0 and gaps.count(0) == 1                             # weak duality on the grid
assert all(y[i] * s8[i] == 0 for i in range(3)) and dot(B, yt) - val == 120  # the trial gap, by hand
assert [yt[i] * s8[i] for i in range(3)] + [x[j] * r[j] for j in range(2)] == [0, 8, 0, 96, 16]  # its terms
assert dot(B, [8, -6, 5]) < val and dot(col(A, 0), y0) < 19             # the broken certificates
assert none == [] and min(wa) >= 0 and dot(B4, w) < 0                   # Farkas: no plan fills the order
assert all(dot(col(A4, j), yk(k)) >= C[j] for j in range(2) for k in (10, 100))
print("ALL CHECKS PASS")
