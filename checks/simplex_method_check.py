# The simplex method -- the check behind the card.  Standard library only.
# Every number on the card is printed here, in exact fractions.  Roads to the
# answer: the tableau walk; the prices read off its last row, checked against
# every limit; every corner of the region listed by crossing pairs of walls.
from fractions import Fraction as F
from itertools import combinations
from math import comb

def show(q, dec=4):               # whole number, short decimal, or a/b
    q = F(q)
    for k in range(dec):
        if (q * 10**k).denominator == 1:
            s = str(abs(q.numerator * 10**k // q.denominator)).rjust(k + 1, "0")
            return ("-" if q < 0 else "") + (s[:-k] + "." + s[-k:] if k else s)
    return f"{q.numerator}/{q.denominator}"

def pivot(T, z, basis, r, j):     # row r's basic variable leaves, column j enters
    p = T[r][j]; T[r] = [v / p for v in T[r]]
    for i in range(len(T)):
        if i != r:
            f = T[i][j]
            T[i] = [a - f * q for a, q in zip(T[i], T[r])]
    f = z[j]; z[:] = [a - f * q for a, q in zip(z, T[r])]; basis[r] = j

def start(A, b, c):               # slack basis: the origin, profit 0
    m = len(A)
    T = [[F(v) for v in A[i]] + [F(int(i == k)) for k in range(m)] + [F(b[i])] for i in range(m)]
    return T, [F(-v) for v in c] + [F(0)] * (m + 1), list(range(len(c), len(c) + m))

def point(T, basis, n):
    x = [F(0)] * n
    for i, bv in enumerate(basis):
        if bv < n:
            x[bv] = T[i][-1]
    return x

def simplex(A, b, c, enter="first", tie="high", cap=60, say=None):
    T, z, basis = start(A, b, c)
    n, m, log, seen = len(c), len(A), [], [sorted(basis)]
    while len(log) < cap:
        neg = [j for j in range(n + m) if z[j] < 0]   # columns that still raise profit
        if not neg:
            return T, z, basis, log, "optimal"
        j = neg[0] if enter == "first" else min(neg, key=lambda k: (z[k], k))
        rat = [T[i][-1] / T[i][j] if T[i][j] > 0 else None for i in range(m)]
        best = min(r for r in rat if r is not None)    # ratio test
        ties = [i for i in range(m) if rat[i] == best]
        r = (min if tie == "low" else max)(ties, key=lambda i: basis[i])
        out = basis[r]
        pivot(T, z, basis, r, j)
        log.append((j, out, best, z[-1], point(T, basis, n + m)))
        if say:
            say(len(log), j, out, rat, len(ties) > 1, T, z, basis)
        if sorted(basis) in seen:
            return T, z, basis, log, f"back to the basis of pivot {seen.index(sorted(basis))}"
        seen.append(sorted(basis))
    return T, z, basis, log, "cap"

NAME = ["t", "c", "s1", "s2", "s3"]
def table(T, z, basis):
    for i, row in enumerate(T + [z]):
        lab = NAME[basis[i]] if i < len(T) else "z"
        print(f"  {lab:>2} | " + " ".join(show(v, 1).rjust(5) for v in row[:-1]) + " | " + show(row[-1]))

def say(k, j, out, rat, tie, T, z, basis):
    x = point(T, basis, 2)
    rs = ", ".join("-" if r is None else show(r) for r in rat)
    print(f"pivot {k}: {NAME[j]} enters; ratios {rs}{'; tie' if tie else ''}; {NAME[out]} leaves; "
          f"point ({show(x[0])}, {show(x[1])}); profit {show(z[-1])}")
    table(T, z, basis)

A, b, c = [[4, 2], [3, 1], [1, 2]], [160, 120, 64], [19, 20]
print("maximise 19 t + 20 c pounds: timber 4,2 <= 160 m; labour 3,1 <= 120 h; finish 1,2 <= 64 l")
print("columns:   t     c    s1    s2    s3 | right side")
T0, z0, b0 = start(A, b, c)
print("tableau k=0: point (0, 0); profit 0")
table(T0, z0, b0)
T, z, basis, log, st = simplex(A, b, c, say=say)
x, y = point(T, basis, 2), z[2:5]                     # prices sit under the slack columns
print(f"stop: {st} after {len(log)} pivots; steps " + ", ".join(show(l[2]) for l in log)
      + f"; make {show(x[0])} tables, {show(x[1])} chairs, profit {show(z[-1])}")
print(f"prices: timber {show(y[0])}, labour {show(y[1])}, finish {show(y[2])}; bound "
      f"{' + '.join(f'{b[i]}*{show(y[i])}' for i in range(3))} = {show(sum(b[i] * y[i] for i in range(3)))}")
cover = [sum(A[i][j] * y[i] for i in range(3)) for j in range(2)]
print(f"prices cover each profit: tables {show(cover[0])} >= 19, chairs {show(cover[1])} >= 20")
walls = A + [[-1, 0], [0, -1]]
lims = b + [0, 0]
corners = {}
for p, q in combinations(range(5), 2):                 # cross every pair of walls
    (a1, a2), (a3, a4) = walls[p], walls[q]
    d = F(a1 * a4 - a2 * a3)
    if d:
        pt = ((lims[p] * a4 - a2 * lims[q]) / d, (a1 * lims[q] - lims[p] * a3) / d)
        if all(w[0] * pt[0] + w[1] * pt[1] <= l for w, l in zip(walls, lims)):
            corners[pt] = 19 * pt[0] + 20 * pt[1]
print("corners: " + "; ".join(f"({show(p[0])}, {show(p[1])}) {show(v)}" for p, v in sorted(corners.items())))
tight = sum(w[0] * 40 + w[1] * 0 == l for w, l in zip(walls, lims))
print(f"walls tight at (40, 0): {tight} for 2 unknowns, so the corner is degenerate; {comb(5, 3)} ways to pick 3 basic columns of 5")
_, zd, _, ld, _ = simplex(A, b, c, enter="dantzig")
print("Dantzig's rule: " + " -> ".join(f"({show(l[4][0])}, {show(l[4][1])}) {show(l[3])}" for l in ld) + f"; {len(ld)} pivots")
_, _, _, lb, _ = simplex(A, b, c, tie="low")
print("tie broken by timber: " + " -> ".join(f"({show(l[4][0])}, {show(l[4][1])}) {show(l[3])}" for l in lb)
      + f"; {len(lb)} pivots; after pivot 1, {NAME[lb[0][1]]} has left and s2 = {show(lb[0][4][3])}")
Tm, zm, bm = start(A, b, c)
pivot(Tm, zm, bm, 2, 0)                                # skip the ratio test: finish leaves
print(f"break, no ratio test: point ({show(Tm[2][-1])}, 0), timber slack {show(Tm[0][-1])}, "
      f"labour slack {show(Tm[1][-1])}, claimed profit {show(zm[-1])}")
first0 = next(l for l in log if l[2] == 0)
print(f"break, stop at the step-0 pivot: profit {show(first0[3])}, short by {show(z[-1] - first0[3])}")
BA = [[F(1, 4), -8, -1, 9], [F(1, 2), -12, F(-1, 2), 3], [0, 0, 1, 0]]
BB, BC = [0, 0, 1], [F(3, 4), -20, F(1, 2), -6]
_, _, _, lbe, sbe = simplex(BA, BB, BC, enter="dantzig", tie="low")
Tb, zb, bb, lbl, sbl = simplex(BA, BB, BC, enter="first", tie="low")
print(f"Beale, Dantzig's rule: profit after each pivot {', '.join(show(l[3]) for l in lbe)}; {sbe}")
xb, yb = point(Tb, bb, 4), zb[4:7]
print(f"Beale, Bland's rule: {sbl} after {len(lbl)} pivots, profit {show(zb[-1])}, "
      f"x = ({', '.join(show(v) for v in xb)}), prices ({', '.join(show(v) for v in yb)})")
KA, KB, KC = [[1, 0, 0], [20, 1, 0], [200, 20, 1]], [1, 100, 10000], [100, 10, 1]
_, zk, _, lk, _ = simplex(KA, KB, KC, enter="dantzig")
print(f"Klee-Minty cube, 3 variables, Dantzig's rule: {len(lk)} pivots to profit {show(zk[-1])}")
for lab, bb2 in [("finish 70 l", [160, 120, 70]), ("labour 130 h", [160, 130, 64])]:
    Tt, zt, bt, lt, _ = simplex(A, bb2, c)
    xt = point(Tt, bt, 2)
    print(f"try {lab}: ({show(xt[0])}, {show(xt[1])}), profit {show(zt[-1])}, {len(lt)} pivots, "
          f"{sum(l[2] == 0 for l in lt)} with step 0")
print("figure, px = 50 + 5*t, py = 225 - 5*c: corners " + " ".join(
    f"({show(50 + 5 * p[0])},{show(225 - 5 * p[1])})" for p in sorted(corners)) + "; timber to (160,45), labour to (190,45), finish to (370,225)")

best = max(corners.values())
assert x == [32, 16] and z[-1] == best == 928 and len(log) == 3     # walk meets enumeration
assert all(v >= 0 for v in y) and cover[0] >= 19 and cover[1] >= 20  # prices are a valid bound
assert sum(b[i] * y[i] for i in range(3)) == best                    # bound meets the best corner
assert log[1][2] == 0 and log[1][4] == log[0][4] and tight == 3      # the degenerate pivot
assert zd[-1] == best and len(ld) == 2 and len(lb) == 2 and lb[0][1] == 2 and lb[0][4][3] == 0
assert sbe == "back to the basis of pivot 0" and len(lbe) == 6       # cycling without Bland
assert sbl == "optimal" and zb[-1] == sum(BC[j] * xb[j] for j in range(4)) == sum(BB[i] * yb[i] for i in range(3)) == F(5, 4)
assert len(lk) == 2**3 - 1 and zk[-1] == 10000
print("ALL CHECKS PASS")
