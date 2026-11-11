# Cutting planes -- the check behind the card.  Standard library, exact fractions.
# Festival: x1 headliners (60 thousand pounds, 4 hours, 5,500 tickets), x2 smaller
# acts (5 thousand, 2 hours, 1,000 tickets); 290 thousand pounds, 24 stage hours.
# Money in 5-thousand units, time in 2-hour slots; tickets in hundreds; maximise.
# Roads: simplex tableau; every corner of the region; every whole-number booking.
from fractions import Fraction as Fr
from itertools import combinations
from math import floor, gcd

A, B, C = [[12, 1], [2, 1]], [58, 12], [55, 10]
val = lambda x: C[0] * x[0] + C[1] * x[1]       # tickets, in hundreds

def simplex(A, b):                     # maximise C.x, Ax <= b, x >= 0, slack start
    m, n = len(A), 2
    T = [[Fr(v) for v in A[i]] + [Fr(int(i == j)) for j in range(m)] + [Fr(b[i])] for i in range(m)]
    z, basis, pivots = [Fr(-v) for v in C] + [Fr(0)] * (m + 1), [n + i for i in range(m)], 0
    while True:
        col = next((j for j in range(n + m) if z[j] < 0), None)          # Bland's rule
        if col is None:
            return T, z, basis, pivots
        r = min((T[i][-1] / T[i][col], basis[i], i) for i in range(m) if T[i][col] > 0)[2]
        T[r] = [v / T[r][col] for v in T[r]]
        for row in T + [z]:
            if row is not T[r]:
                f = row[col]
                row[:] = [a - f * c for a, c in zip(row, T[r])]
        basis[r], pivots = col, pivots + 1

def corners(A, b, extra=()):           # road 2: every crossing of two edges, kept if feasible
    rows = [(a, Fr(bi)) for a, bi in zip(A, b)] + [([-1, 0], Fr(0)), ([0, -1], Fr(0))] + list(extra)
    pts = set()
    for (p, e), (q, f) in combinations(rows, 2):
        d = p[0] * q[1] - p[1] * q[0]
        if d:
            x = ((e * q[1] - p[1] * f) / d, (p[0] * f - e * q[0]) / d)
            if all(a[0] * x[0] + a[1] * x[1] <= c for a, c in rows):
                pts.add(x)
    return sorted(pts)

def lp_best(A, b, extra=()):           # None when the region is empty
    return max(corners(A, b, extra), key=lambda x: (val(x), x), default=None)

def plans(A, b):                       # road 3: every whole-number booking
    return [(i, j) for i in range(13) for j in range(13)
            if all(a[0] * i + a[1] * j <= c for a, c in zip(A, b))]

frac = lambda v: v - floor(v)          # fractional part: frac(-0.1) = 0.9

def gomory(row, A, b):                 # sum frac(a_j) s_j >= frac(rhs), rewritten in x1, x2
    m = len(A)
    fs, fx = [frac(v) for v in row[2:2 + m]], [frac(v) for v in row[:2]]
    cx = [sum(fs[i] * A[i][k] for i in range(m)) - fx[k] for k in range(2)]  # s_i = b_i - A_i x
    rhs = sum(fs[i] * b[i] for i in range(m)) - frac(row[-1])
    scale = 1
    for v in cx + [rhs]:
        scale = scale * v.denominator // gcd(scale, v.denominator)
    ints = [int(v * scale) for v in cx + [rhs]]
    g = gcd(gcd(ints[0], ints[1]), ints[2])
    return fs, frac(row[-1]), [ints[0] // g, ints[1] // g], ints[2] // g

def bnb(extra, st, log, depth=0):      # depth first, x <= floor branch first; st = [best, plan, nodes]
    x = lp_best(A, B, extra)
    st[2] += 1
    log.append((depth, x))
    if x is None or (st[0] is not None and val(x) <= st[0]):
        return                         # empty, or cannot beat the best booking found
    k = next((k for k in range(2) if x[k].denominator > 1), None)
    if k is None:
        st[0], st[1] = val(x), x
        return
    lo, hi = [0, 0], [0, 0]
    lo[k], hi[k] = 1, -1
    bnb(tuple(extra) + ((lo, Fr(floor(x[k]))),), st, log, depth + 1)
    bnb(tuple(extra) + ((hi, Fr(-floor(x[k]) - 1)),), st, log, depth + 1)

show = lambda v: str(v) if v.denominator == 1 else f"{float(v):.2f}".rstrip("0")
pt = lambda p: f"({show(Fr(p[0]))}, {show(Fr(p[1]))})"
tk = lambda p: show(100 * val(p))

T, z, basis, piv = simplex(A, B)
x = [next((T[i][-1] for i, bv in enumerate(basis) if bv == k), Fr(0)) for k in range(2)]
top = lp_best(A, B)
print(f"relaxation by simplex: {pt(x)}, {show(x[0] + x[1])} acts, {show(100 * z[-1])} tickets, {piv} pivots")
print(f"relaxation by corners: {' '.join(pt(p) for p in corners(A, B))} -> best {pt(top)}, {tk(top)} tickets")
for i, bv in enumerate(basis):
    print(f"tableau row x{bv + 1}: s1 {show(T[i][2])}, s2 {show(T[i][3])}, right side {show(T[i][-1])}")
pts = plans(A, B)
best = max(pts, key=val)
print(f"whole-number bookings: {len(pts)}; best {pt(best)}, {tk(best)} tickets; gap {show(100 * (val(top) - val(best)))}")
cuts = {}
for i, bv in enumerate(basis):
    fs, f0, a, c = gomory(T[i], A, B)
    cuts[bv] = ((a, Fr(c)),)
    new = lp_best(A, B, cuts[bv])
    print(f"cut from row x{bv + 1}: {show(fs[0])} s1 + {show(fs[1])} s2 >= {show(f0)}  ->  {a[0]} x1 + {a[1]} x2 <= {c}; "
          f"corner gives {show(a[0] * top[0] + a[1] * top[1])}; new best {pt(new)}, {tk(new)} tickets")
    assert all(a[0] * p + a[1] * q <= c for p, q in pts)            # keeps every whole booking
    assert a[0] * top[0] + a[1] * top[1] > c                        # removes the 7.4-act corner
w = [Fr(1, 10), Fr(9, 10)]                     # the x1 cut as a blend of the two limits, rounded
print(f"blend 0.1 x budget + 0.9 x slots: {show(w[0] * 12 + w[1] * 2)} x1 + {show(w[0] + w[1])} x2 <= "
      f"{show(w[0] * 58 + w[1] * 12)}, round down to {floor(w[0] * 58 + w[1] * 12)}")
T2, z2, b2, piv2 = simplex(A + [cuts[0][0][0]], B + [cuts[0][0][1]])
print(f"re-solve with the cut by simplex: {show(100 * z2[-1])} tickets, gap {show(100 * (z2[-1] - val(best)))}, {piv2} pivots")
for name, extra in (("branch and bound, no cut", ()), ("branch and cut, x1-row cut at root", cuts[0])):
    st, log = [None, None, 0], []
    bnb(extra, st, log)
    print(f"{name}: nodes {st[2]}, best {pt(st[1])}, {tk(st[1])} tickets")
    for d, p in log:
        print(f"  node at depth {d}: " + ("empty" if p is None else f"{pt(p)}, {tk(p)} tickets"))
rows, rounds, cur = [], 0, top                 # pure cutting: the x1 row's cut, round after round
while any(v.denominator > 1 for v in cur):
    Ac, Bc = A + [r[0] for r in rows], B + [r[1] for r in rows]
    T3, z3, b3, _ = simplex(Ac, Bc)
    _, _, a3, c3 = gomory(T3[b3.index(0 if cur[0].denominator > 1 else 1)], Ac, Bc)
    assert all(a3[0] * p + a3[1] * q <= c3 for p, q in pts)          # keeps every whole booking
    assert a3[0] * cur[0] + a3[1] * cur[1] > c3                      # removes the current corner
    rows, rounds = rows + [(a3, Fr(c3))], rounds + 1
    cur = lp_best(A, B, rows)
    print(f"  pure cutting, round {rounds}: {a3[0]} x1 + {a3[1]} x2 <= {c3}; best {pt(cur)}, {tk(cur)} tickets")
print(f"mistake 1, round the corner to (5, 3): budget {60 * 5 + 5 * 3} > 290, hours {4 * 5 + 2 * 3} > 24")
print(f"mistake 2, round down to (4, 2): {tk((4, 2))} tickets, {show(100 * (val(best) - val((4, 2))))} short")
Am, Bm = [[Fr(6, 100), Fr(5, 1000)], [4, 2]], [Fr(29, 100), 24]   # budget in millions of pounds
Tm, zm, bm, _ = simplex(Am, Bm)
_, _, a5, c5 = gomory(Tm[bm.index(0)], Am, Bm)
lost = [p for p in pts if a5[0] * p[0] + a5[1] * p[1] > c5]
left = max((p for p in pts if p not in lost), key=val)
print(f"mistake 3, budget in millions, 0.06 x1 + 0.005 x2 <= 0.29: cut {a5[0]} x1 + {a5[1]} x2 <= {c5} "
      f"throws out {lost}; best left {pt(left)}, {tk(left)} tickets")
for name, extra in (("region", ()), ("after the cut", cuts[0])):
    print(f"figure, {name}: {' '.join(pt(p) for p in corners(A, B, extra))}")
assert x == list(top) and 100 * z[-1] == 28100 == 100 * val(top)      # simplex agrees with corners
assert best == (4, 4) == tuple(st[1]) and val(best) == 260 == st[0]   # search agrees with the list
assert cuts[0][0] == ([3, 1], 16) and z2[-1] == val(lp_best(A, B, cuts[0]))
assert (4, 4) in lost and val(left) < val(best)                       # fractional data breaks it
assert cur == best and rounds == 4                                    # pure cutting ends at the listed best
print("ALL CHECKS PASS")
