# Krein-Milman: find the corners of a transport plan's feasible set and rebuild a plan
# from them.  Standard library only; Fractions keep every plan exact.  Two depots (30 and
# 20 pallets) ship to three shops (15, 25 and 10).  A plan is fixed by u = depot 1 -> shop 1
# and v = depot 1 -> shop 2; the other four entries follow from the totals.
from fractions import Fraction as F
SUP, DEM, COST = [30, 20], [15, 25, 10], [[4, 6, 9], [5, 3, 7]]
ROWS = [(1, 0, 0), (0, 1, 0), (-1, -1, 30), (-1, 0, 15), (0, -1, 25), (1, 1, -20)]  # a*u + b*v + c

def entries(p): return [a * p[0] + b * p[1] + c for a, b, c in ROWS]
def feasible(p): return all(e >= 0 for e in entries(p))
def grid(p): e = entries(p); return [[e[0], e[1], e[2]], [e[3], e[4], e[5]]]
def cost(p): return sum(COST[i][j] * grid(p)[i][j] for i in range(2) for j in range(3))
def fr(x): return str(x.numerator) if x.denominator == 1 else f"{x.numerator}/{x.denominator}"
def pt(p): return f"({fr(F(p[0]))}, {fr(F(p[1]))})"
def row(r): return "[" + ", ".join(fr(F(e)) for e in r) + "]"

# road 1: a corner is where two limits bind -- intersect every pair of zero-lines
road1 = set()
for i in range(6):
    for j in range(i + 1, 6):
        (a1, b1, c1), (a2, b2, c2) = ROWS[i], ROWS[j]
        det = a1 * b2 - a2 * b1
        if det:
            p = (F(-c1 * b2 + c2 * b1, det), F(-a1 * c2 + a2 * c1, det))
            if feasible(p): road1.add(p)
CORNERS = sorted(road1)
# road 2: test every whole-pallet plan: a corner is not the midpoint of two other plans
DIRS = [(1, 0), (0, 1), (1, -1), (1, 1)]
plans = [(F(u), F(v)) for u in range(16) for v in range(26) if feasible((u, v))]
road2 = [p for p in plans if not any(feasible((p[0] + F(d[0], 2), p[1] + F(d[1], 2))) and
         feasible((p[0] - F(d[0], 2), p[1] - F(d[1], 2))) for d in DIRS)]
edge = [p for p in plans if 0 in entries(p)]
assert road2 == CORNERS and len(CORNERS) == 5
print(f"whole-pallet plans {len(plans)}, on the boundary {len(edge)}, corners {len(CORNERS)}, dimension (2-1)(3-1) = 2")
for c in CORNERS:
    print(f"corner {pt(c)}: depot 1 sends {row(grid(c)[0])}, depot 2 sends {row(grid(c)[1])}, cost {cost(c)}")
assert min(cost(p) for p in plans) == min(cost(c) for c in CORNERS) == 240

def peel(x, corners):  # the proof of Minkowski's theorem, run: returns {corner: weight}
    if x in corners: return {x: F(1)}
    zero = [k for k, e in enumerate(entries(x)) if e == 0]
    face = [c for c in corners if all(entries(c)[k] == 0 for k in zero)]
    v = face[0]
    d = (x[0] - v[0], x[1] - v[1])
    t = min(e / -(a * d[0] + b * d[1]) for e, (a, b, c) in zip(entries(v), ROWS)
            if a * d[0] + b * d[1] < 0)        # walk from v through x until a limit binds
    y = (v[0] + t * d[0], v[1] + t * d[1])
    out = {c: w / t for c, w in peel(y, face).items()}
    out[v] = out.get(v, F(0)) + 1 - 1 / t
    return out

X = (F(SUP[0] * DEM[0], 50), F(SUP[0] * DEM[1], 50))  # proportional plan: a_i b_j / 50
W = peel(X, CORNERS)
print(f"proportional plan {pt(X)}: depot 1 sends {row(grid(X)[0])}, depot 2 sends {row(grid(X)[1])}, cost {cost(X)}")
v0, y = CORNERS[0], (F(15), F(35, 3))  # the stop, checked: on the line, on the edge, 3/5 of the way
assert feasible(y) and entries(y)[3] == 0 and X == (F(2, 5) * v0[0] + F(3, 5) * y[0], F(2, 5) * v0[1] + F(3, 5) * y[1])
assert y == (F(1, 3) * 15 + F(2, 3) * 15, F(1, 3) * 5 + F(2, 3) * 15)  # the stop splits its edge 1/3 : 2/3
print(f"peel: walk from corner {pt(v0)} through {pt(X)}, stop at {pt(y)} on the edge u = 15, t = 5/3")
print(f"  plan = 2/5 x {pt(v0)} + 3/5 x stop; stop = 1/3 x (15, 5) + 2/3 x (15, 15)")
for c in sorted(W): print(f"  weight {fr(W[c])} on corner {pt(c)}, cost {cost(c)}")
mix = [[sum(W[c] * grid(c)[i][j] for c in W) for j in range(3)] for i in range(2)]
assert mix == grid(X) and sum(W.values()) == 1 and len(W) <= 3
assert sum(W[c] * cost(c) for c in W) == cost(X) == 268
# road 2 to the weights: Cramer's rule in every triangle of three corners
def bary(p, a, b, c):
    det = (b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1])
    if det == 0: return None
    wb = ((p[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (p[1] - a[1])) / det
    wc = ((b[0] - a[0]) * (p[1] - a[1]) - (p[0] - a[0]) * (b[1] - a[1])) / det
    return (1 - wb - wc, wb, wc)
tri = [(i, j, k) for i in range(5) for j in range(i + 1, 5) for k in range(j + 1, 5)]
hold = [(t, bary(X, *[CORNERS[n] for n in t])) for t in tri]
hold = [(t, w) for t, w in hold if w and min(w) >= 0]
print(f"corner triangles holding the plan: {len(hold)} of {len(tri)}")
for t, w in hold:
    print(f"  {' + '.join(fr(a) + ' x ' + pt(CORNERS[n]) for a, n in zip(w, t))}")
assert any({CORNERS[n]: a for a, n in zip(w, t) if a} == W for t, w in hold) and len(hold) > 1
even = (sum(c[0] for c in CORNERS) / 5, sum(c[1] for c in CORNERS) / 5)
print(f"mistake: equal weights 1/5 on all five corners give {pt(even)}, not {pt(X)}")
print("figure, corners " + " ".join(pt(c) for c in CORNERS) + f"; plan {pt(X)}; stop {pt(y)}")

# N depots and N shops, one pallet each: the corners are the N! one-to-one plans
def count01(n):  # brute force over every 0/1 table with row and column sums 1
    good = 0
    for m in range(2 ** (n * n)):
        b = [[(m >> (n * i + j)) & 1 for j in range(n)] for i in range(n)]
        good += all(sum(r) == 1 for r in b) and all(sum(b[i][j] for i in range(n)) == 1 for j in range(n))
    return good
for n in (2, 3, 4):
    fact = 1
    for k in range(2, n + 1): fact *= k
    shifts = [[[int((i + s) % n == j) for j in range(n)] for i in range(n)] for s in range(n)]
    ok = all(sum(r) == 1 and sum(b[k][j] for k in range(n)) == 1 for b in shifts for j, r in enumerate(b))
    avg = [[sum(F(b[i][j], n) for b in shifts) for j in range(n)] for i in range(n)]
    assert count01(n) == fact and ok and all(e == F(1, n) for r in avg for e in r)
    print(f"N = {n}: corners {fact}, dimension {(n - 1) ** 2}, even plan = average of {n} shifts")

# the c0 ball: closed, bounded, convex, not compact -- every point can be wiggled
for n in (4, 8, 16):
    print(f"N = {n}: the cube [-1, 1]^N has {2 ** n} corners; each has every entry +1 or -1")
x = [F(1, k) for k in range(1, 17)]  # x_n = 1/n, in the c0 ball; entry 2 is 1/2
up, dn = x[:1] + [x[1] + F(1, 2)] + x[2:], x[:1] + [x[1] - F(1, 2)] + x[2:]
assert max(abs(e) for e in up) == max(abs(e) for e in dn) == 1 and x[1] == F(1, 2)
print("c0: x_n = 1/n is the midpoint of x + e_2/2 and x - e_2/2, both of sup norm 1")

# one unit spread evenly over [0, 1] against N point masses at the midpoints (k - 1/2)/N
for n in (1, 10, 100, 1000):
    m = 10 * n; h = 1 / m; w1 = 0.0
    for i in range(m):  # W1 = integral of |F_even - F_points|, midpoint rule, kinks on cell edges
        s = (i + 0.5) * h
        w1 += abs(s - min(n, int(s * n + 0.5)) / n) * h
    sq = sum(((k - 0.5) / n) ** 2 for k in range(1, n + 1)) / n
    cuts = [F(0)] + [F(2 * k - 1, 2 * n) for k in range(1, n + 1)] + [F(1)]  # 0, the n atoms, 1
    # total variation, summed over pieces: each atom (points 1/n, even spread 0) and each gap
    # between atoms (points 0, even spread its length); it can never exceed 1 + 1, the two masses
    tv = sum(abs(F(1, n) - 0) for a in cuts[1:-1]) + sum(abs(0 - (b - a)) for a, b in zip(cuts, cuts[1:]))
    assert tv == 1 + 1
    assert abs(w1 - 1 / (4 * n)) < 1e-12 and abs((1 / 3 - sq) - 1 / (12 * n * n)) < 1e-12
    print(f"N = {n}: W1 = {w1:.6f} (1/4N = {1 / (4 * n):.6f}), x^2 error {1 / 3 - sq:.12f}, total variation {tv}")
print("ALL CHECKS PASS")
