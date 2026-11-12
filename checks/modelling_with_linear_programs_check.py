# Linear programs: the check behind the card. Standard library only.
# Two cake mixes, 4 ovens, limited flour: which plan earns the most margin?
# Three roads: (1) a corner solver that makes every pair of limits tight,
# (2) a grid of every plan in tenths of a batch, (3) a certificate: weights
# on the limits that cap the margin. Every number on the card is printed.
BIG = 1e6  # a far fence: a best corner on it means the margin has no ceiling
NAMES = ["oven", "flour", "demand", "x1>=0", "x2>=0", "fence", "fence"]

def solve(c, A, b):
    rows = [(r[0], r[1], v) for r, v in zip(A, b)]
    rows += [(-1.0, 0.0, 0.0), (0.0, -1.0, 0.0), (1.0, 0.0, BIG), (0.0, 1.0, BIG)]
    cands, best = [], None
    for i in range(len(rows)):
        for j in range(i + 1, len(rows)):
            (a1, b1, r1), (a2, b2, r2) = rows[i], rows[j]
            det = a1 * b2 - a2 * b1
            if abs(det) < 1e-12:
                continue  # parallel limits never meet
            x = ((r1 * b2 - r2 * b1) / det, (a1 * r2 - a2 * r1) / det)
            ok = all(p * x[0] + q * x[1] <= r + 1e-9 for p, q, r in rows)
            val = c[0] * x[0] + c[1] * x[1]
            if j < len(A) + 2:
                cands.append((i, j, x, ok, val))
            if ok and (best is None or val > best[4] + 1e-9):
                best = (i, j, x, ok, val)
    if best is None:
        return "infeasible", None, cands
    if best[1] >= len(A) + 2:
        return "unbounded", None, cands
    return "optimal", best, cands

def f2(v): return f"{v + 0.0:.2f}"
def pt(x): return f"({f2(x[0])}, {f2(x[1])})"

c, A, b = (40.0, 60.0), [(2.0, 4.0), (20.0, 10.0), (0.0, 1.0)], [48.0, 300.0, 10.0]
print(f"model, {4 * 12} oven hours from 4 ovens x 12 h | max 40 x1 + 60 x2 | oven 2 x1 + 4 x2 <= 48 | flour 20 x1 + 10 x2 <= 300 | demand x2 <= 10")
status, best, cands = solve(c, A, b)
for i, j, x, ok, val in cands:
    print(f"corner, {NAMES[i]} + {NAMES[j]}, {pt(x)}, {'fits' if ok else 'breaks a limit'}, margin {f2(val)}")
fit = sum(1 for k in cands if k[3])
print(f"corners, {len(cands)} candidates from 5 limits, {fit} fit")
i, j, x, _, val = best
print(f"solver, status {status}, x1 {f2(x[0])}, x2 {f2(x[1])}, margin {f2(val)}")
k0, k1 = b[0] / A[0][0], A[0][1] / A[0][0]  # by hand: substitute the oven line into flour
h2 = (A[1][0] * k0 - b[1]) / (A[1][0] * k1 - A[1][1])
print(f"hand, oven: x1 = {f2(k0)} - {f2(k1)} x2; flour: {f2(A[1][0] * k0)} - {f2(A[1][0] * k1 - A[1][1])} x2 = {f2(b[1])}; x2 {f2(h2)}, x1 {f2(k0 - k1 * h2)}")
assert abs(h2 - x[1]) < 1e-9 and abs(k0 - k1 * h2 - x[0]) < 1e-9
s = [bb - (a[0] * x[0] + a[1] * x[1]) for a, bb in zip(A, b)]
print(f"slack, oven {f2(s[0])} h, flour {f2(s[1])} kg, demand {f2(s[2])} batches")
# road 2: every plan on a grid of tenths, in whole numbers so nothing rounds
feasible, gbest, garg = 0, -1, None
for u in range(0, 241):
    for v in range(0, 121):
        if 2 * u + 4 * v <= 480 and 20 * u + 10 * v <= 3000 and v <= 100:
            feasible += 1
            if 40 * u + 60 * v > gbest:
                gbest, garg = 40 * u + 60 * v, (u / 10, v / 10)
print(f"grid, {feasible} plans fit out of {241 * 121}, best {f2(gbest / 10)} at {pt(garg)}")
assert abs(gbest / 10 - val) < 1e-9 and garg == (round(x[0], 9), round(x[1], 9))
# dual values: weights on the two tight limits whose rows add up to c
(p1, q1), (p2, q2) = A[i], A[j]
det = p1 * q2 - p2 * q1
w = [0.0, 0.0, 0.0]
w[i], w[j] = (c[0] * q2 - p2 * c[1]) / det, (p1 * c[1] - q1 * c[0]) / det
print(f"dual, oven {f2(w[0])} per h, flour {f2(w[1])} per kg, demand {f2(w[2])} per batch")
# road 3: the certificate. Weights >= 0 whose rows cover c cap every plan
cap = sum(wk * bk for wk, bk in zip(w, b))
assert min(w) >= 0  # a negative weight would flip its limit's inequality
print(f"certificate, {f2(w[0])} x oven + {f2(w[1])} x flour caps margin at {f2(w[0] * b[0])} + {f2(w[1] * b[1])} = {f2(cap)}")
assert abs(cap - gbest / 10) < 1e-9
# along an edge the margin moves at a steady rate: the midpoint is the average
e1, e2 = (12.0, 6.0), (4.0, 10.0)
mid = ((e1[0] + e2[0]) / 2, (e1[1] + e2[1]) / 2)
mv = lambda p: c[0] * p[0] + c[1] * p[1]
print(f"edge, midpoint {pt(mid)} margin {f2(mv(mid))}, average of ends {f2((mv(e1) + mv(e2)) / 2)}")
assert mv(mid) < val

def fill(order):  # greedy: make as much as possible of one cake, then the other
    x, left = [0.0, 0.0], list(b)
    for k in order:
        x[k] = min(left[r] / A[r][k] for r in range(3) if A[r][k] > 0)
        left = [left[r] - A[r][k] * x[k] for r in range(3)]
    return x
g1, g2 = fill([1, 0]), fill([0, 1])
print(f"breaks, fruit first {pt(g1)} margin {f2(mv(g1))}")
print(f"breaks, best per oven hour (sponge {f2(c[0] / A[0][0])}, fruit {f2(c[1] / A[0][1])}) {pt(g2)} margin {f2(mv(g2))}")
assert mv(g1) < val and mv(g2) < val
_, nb, _ = solve(c, [A[0], A[2]], [b[0], b[2]])
print(f"breaks, no flour limit {pt(nb[2])} margin {f2(nb[4])}, needs {f2(20 * nb[2][0] + 10 * nb[2][1])} kg flour")
_, lp, _ = solve(c, A, [48.0, 310.0, 10.0])
r = (round(lp[2][0]), round(lp[2][1]))
print(f"breaks, flour 310 kg: LP {pt(lp[2])} margin {f2(lp[4])}")
print(f"breaks, rounded {r} margin {f2(mv(r))}, oven over by {f2(2 * r[0] + 4 * r[1] - 48)} h, flour over by {f2(20 * r[0] + 10 * r[1] - 310)} kg")
assert 2 * r[0] + 4 * r[1] > 48 and 20 * r[0] + 10 * r[1] > 310
wb = max(((p, q) for p in range(25) for q in range(11) if 2 * p + 4 * q <= 48 and 20 * p + 10 * q <= 310), key=mv)
dn = (int(lp[2][0]), int(lp[2][1]))
print(f"breaks, rounded down {dn} margin {f2(mv(dn))}; best whole plan {wb} margin {f2(mv(wb))}")
assert mv(dn) < mv(wb) <= lp[4]
st, mn, _ = solve((-40.0, -60.0), A, b)
print(f"trap, minimise by mistake {pt(mn[2])} margin {f2(-mn[4])}")
_, bag, _ = solve(c, A, [48.0, 12.0, 10.0])
print(f"trap, flour limit in 25 kg bags (12) beside kg per batch: margin {f2(bag[4])}")
for label, AA, bb in [("at least 14 sponge as -x1 <= -14", A + [(-1.0, 0.0)], b + [-14.0]),
                      ("exactly 8 fruit as x2 <= 8 and -x2 <= -8", A + [(0.0, 1.0), (0.0, -1.0)], b + [8.0, -8.0]),
                      ("at least 20 sponge as -x1 <= -20", A + [(-1.0, 0.0)], b + [-20.0])]:
    st, sf, _ = solve(c, AA, bb)  # standard form: "at least" flips sign, "exactly" is two rows
    print(f"standard form, {label}: status {st}" + (f", {pt(sf[2])} margin {f2(sf[4])}" if sf else ""))
assert st == "infeasible"
for label, cc, AA, bb in [("sponge margin 20", (20.0, 60.0), A, b), ("sponge margin 130", (130.0, 60.0), A, b),
                          ("flour 400 kg", c, A, [48.0, 400.0, 10.0])]:
    _, t, _ = solve(cc, AA, bb)
    print(f"try, {label}: {pt(t[2])} margin {f2(t[4])}")
st, _, _ = solve(c, [A[2]], [b[2]])
print(f"try, no oven and no flour limit: status {st}")
assert st == "unbounded"

def comb(n, k):
    out = 1
    for t in range(k):
        out = out * (n - t) // (t + 1)
    return out
assert len(cands) == comb(5, 2) - 1  # one pair is parallel: demand and x2 >= 0
print("growth, " + "; ".join(f"n {n} m {m}: {comb(n + m, n)} candidates" for n, m in [(2, 3), (10, 20), (20, 40)]))
X = lambda q: 45 + 11 * q[0]
Y = lambda q: 205 - 13 * q[1]
print("figure, corners px " + " ".join(f"{X(q):g},{Y(q):g}" for q in [(0, 0), (15, 0), (12, 6), (4, 10), (0, 10)]))
print("ALL CHECKS PASS")
