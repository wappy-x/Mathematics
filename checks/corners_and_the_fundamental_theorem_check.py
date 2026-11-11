# Corners are enough: the check behind the card. Standard library only.
# The workshop: t tables, c chairs; maximise profit 19 t + 20 c (pounds) with
# timber 4t + 2c <= 160 m, labour 3t + c <= 120 h, finish t + 2c <= 64 litres.
# Exact fractions throughout. Roads: (1) every choice of 3 basic columns,
# solved by elimination; (2) prices that cap the profit; (3) every plan on a
# grid of tenths; (4) the proof's reduction, run from a plan inside.
from fractions import Fraction as F
from itertools import combinations

A = [[4, 2, 1, 0, 0], [3, 1, 0, 1, 0], [1, 2, 0, 0, 1]]  # slack columns added
b, c = [160, 120, 64], [19, 20, 0, 0, 0]
COL = ["t", "c", "s_timber", "s_labour", "s_finish"]
LIM = ["t >= 0", "c >= 0", "timber", "labour", "finish"]  # zero entry = tight limit

def show(x):  # exact fraction -> decimal text, at most 3 places
    x = F(x); n = round(abs(x) * 1000)
    s = f"{n // 1000}.{n % 1000:03d}".rstrip("0").rstrip(".")
    return ("-" if x < 0 else "") + s
def pt(x): return f"({show(x[0])}, {show(x[1])})"
def vec(x): return "(" + ", ".join(show(v) for v in x) + ")"
def profit(x): return sum(F(ci) * xi for ci, xi in zip(c, x))

def rref(cols):  # row-reduce the chosen columns of A; return the rows and pivot columns
    M = [[F(A[r][j]) for j in cols] for r in range(3)]
    piv, r = [], 0
    for k in range(len(cols)):
        p = next((i for i in range(r, 3) if M[i][k] != 0), None)
        if p is None: continue
        M[r], M[p] = M[p], M[r]
        M[r] = [v / M[r][k] for v in M[r]]
        for i in range(3):
            if i != r and M[i][k] != 0:
                M[i] = [a - M[i][k] * bb for a, bb in zip(M[i], M[r])]
        piv.append(k); r += 1
    return M, piv

def basic(cols, b=b):  # solve B x_B = b by elimination, all other entries zero
    M = [[F(A[r][j]) for j in cols] + [F(b[r])] for r in range(3)]
    for k in range(3):
        p = next((i for i in range(k, 3) if M[i][k] != 0), None)
        if p is None: return None
        M[k], M[p] = M[p], M[k]
        M[k] = [v / M[k][k] for v in M[k]]
        for i in range(3):
            if i != k: M[i] = [a - M[i][k] * bb for a, bb in zip(M[i], M[k])]
    x = [F(0)] * 5
    for k, j in enumerate(cols): x[j] = M[k][3]
    return x

print("model, max 19 t + 20 c | timber 4 t + 2 c <= 160 m | labour 3 t + c <= 120 h | finish t + 2 c <= 64 litres")
print(f"standard form, m = 3 rows, n = 5 columns (t, c and 3 slacks), at most {5 * 4 * 3 // 6} bases")
corners, nfeas, bad, ntry = {}, 0, [], 0
for cols in combinations(range(5), 3):
    x = basic(cols); ntry += 1
    ok = x is not None and min(x) >= 0
    nfeas += ok
    names = " ".join(COL[j] for j in cols)
    if ok: corners.setdefault((x[0], x[1]), []).append(names)
    else: bad.append(x)
    neg = "" if ok else ", negative " + " ".join(COL[j] for j in range(5) if x[j] < 0)
    print(f"basis {names}: x = {vec(x)}, {'feasible' if ok else 'infeasible'}{neg}, profit {show(profit(x))}")
print(f"bases, {ntry} tried, {nfeas} feasible, {len(corners)} distinct corners")
for p, names in sorted(corners.items()):
    x = [p[0], p[1]] + [F(b[r]) - A[r][0] * p[0] - A[r][1] * p[1] for r in range(3)]
    tight = [j for j in range(5) if x[j] == 0]
    _, piv = rref([j for j in range(5) if x[j] != 0])
    assert len(piv) == 5 - len(tight)  # positive entries have independent columns
    print(f"corner {pt(p)}: bases giving it {len(names)}, tight {', '.join(LIM[j] for j in tight)}, profit {show(profit(x))}")
best = max(corners, key=lambda p: profit(list(p) + [0, 0, 0]))
zstar = profit(list(best) + [0, 0, 0])
print(f"best corner, {pt(best)}, profit {show(zstar)}")
th = (b[0] - b[2]) // (A[0][0] - A[2][0]); ch = (b[2] - th) // 2  # by hand: timber minus finish
print(f"hand, timber minus finish: 3 t = {b[0] - b[2]}, t = {th}; finish: 2 c = {b[2] - th}, c = {ch}; "
      f"labour slack {b[1] - 3 * th - ch}; profit {19 * th} + {20 * ch} = {19 * th + 20 * ch}")
assert (F(th), F(ch)) == best
y = [3, 0, 7]  # road 2: prices per metre, hour and litre
cover = [sum(y[r] * A[r][j] for r in range(3)) for j in range(2)]
bound = sum(yr * br for yr, br in zip(y, b))
print(f"certificate, prices timber {y[0]} labour {y[1]} finish {y[2]}; inputs priced: table {cover[0]} vs profit {c[0]}, chair {cover[1]} vs profit {c[1]}; cap {y[0] * b[0]} + {y[1] * b[1]} + {y[2] * b[2]} = {bound}, gap {show(bound - zstar)}")
gbest, garg, nfit = -1, None, 0  # road 3: plans in tenths, whole numbers so nothing rounds
for T in range(0, 401):
    for C_ in range(0, 321):
        if 4 * T + 2 * C_ <= 1600 and 3 * T + C_ <= 1200 and T + 2 * C_ <= 640:
            nfit += 1
            if 19 * T + 20 * C_ > gbest: gbest, garg = 19 * T + 20 * C_, (F(T, 10), F(C_, 10))
print(f"grid, {nfit} plans in tenths fit, best {show(F(gbest, 10))} at {pt(garg)}")
# road 4: the proof's reduction. While the columns of the positive entries are
# dependent, move along a direction d with A d = 0 that does not lower profit.
def reduce(t0, c0, say):
    x, step = [F(t0), F(c0)] + [F(b[r] - A[r][0] * t0 - A[r][1] * c0) for r in range(3)], 0
    if say: print(f"reduce, start {vec(x)}, {sum(v > 0 for v in x)} positive entries, profit {show(profit(x))}")
    while True:
        S = [j for j in range(5) if x[j] > 0]
        M, piv = rref(S)
        if len(piv) == len(S): break
        f = next(k for k in range(len(S)) if k not in piv)
        d = [F(0)] * 5; d[S[f]] = F(1)
        for r, k in enumerate(piv): d[S[k]] = -M[r][f]
        if profit(d) < 0 or (profit(d) == 0 and min(d) >= 0): d = [-v for v in d]
        assert all(sum(A[r][j] * d[j] for j in range(5)) == 0 for r in range(3))
        theta = min(x[j] / -d[j] for j in range(5) if d[j] < 0)
        old = profit(x); x = [xi + theta * di for xi, di in zip(x, d)]; step += 1
        assert profit(x) >= old and min(x) >= 0
        if say: print(f"reduce step {step}: d = {vec(d)}, move {show(theta)}, profit rate {show(profit(d))}, x = {vec(x)}, profit {show(profit(x))}")
    return x, step
x, step = reduce(10, 10, True)
print(f"reduce, ends at {pt(x)} after {step} moves: in the corner list, {'yes' if (x[0], x[1]) in corners else 'no'}")
inf = max(bad, key=profit)
print(f"breaks, feasibility skipped: best basic solution {pt(inf)}, profit {show(profit(inf))}, timber {show(4 * inf[0] + 2 * inf[1])} m > 160")
print(f"breaks, feasible bases counted as corners: {nfeas}, but {len(corners)} corners")
tie = [10 * p[0] + 20 * p[1] for p in sorted(corners)]  # profit line parallel to the finish edge
print(f"breaks, profit 10 t + 20 c: corners {' '.join(show(v) for v in tie)}; midpoint (16, 24) also {10 * 16 + 20 * 24}")
def bent(p): return 19 * p[0] + 20 * p[1] - p[1] * p[1] / 2  # chair profit falls 50p a chair
bc = max(corners, key=bent)
ce = F(21, 2); te = 40 - ce / 2  # on the timber edge t = 40 - c/2 the slope 10.5 - c is zero
gb, ga = -1, None
for T in range(0, 401):
    for C_ in range(0, 321):
        if 4 * T + 2 * C_ <= 1600 and 3 * T + C_ <= 1200 and T + 2 * C_ <= 640:
            v = 380 * T + 400 * C_ - C_ * C_  # profit x 200
            if v > gb: gb, ga = v, [(F(T, 10), F(C_, 10))]
            elif v == gb: ga.append((F(T, 10), F(C_, 10)))
print(f"breaks, chair profit falling 50p a chair: best corner {pt(bc)} {show(bent(bc))}; edge point {pt((te, ce))} {show(bent((te, ce)))}; grid best {show(F(gb, 200))} at {' and '.join(pt(g) for g in ga)}")
ends = [(F(t0), (zstar - 19 * t0) / 20) for t0 in (12, 44)]  # the profit-928 line, drawn dashed
print(f"figure, corners {' '.join(pt(p) for p in sorted(corners))}; infeasible crossings {pt(bad[0])} {pt(bad[1])}; profit line {show(zstar)} from {pt(ends[0])} to {pt(ends[1])}")
f64 = [v for v in (basic(cols, [160, 64, 64]) for cols in combinations(range(5), 3)) if min(v) >= 0]  # Try changing
b64 = max(f64, key=profit)
print(f"try, labour 64 h: {len(f64)} bases fit, {len({(v[0], v[1]) for v in f64})} corners, best {pt(b64)}, profit {show(profit(b64))}")
x5, s5 = reduce(5, 25, False)
print(f"try, start (5, 25): {s5} moves to {pt(x5)}, profit {show(profit(x5))}")
y6 = [3, 0, 6]; c6 = [sum(y6[r] * A[r][j] for r in range(3)) for j in range(2)]
print(f"try, finish price 6: inputs priced table {c6[0]} vs profit 19, chair {c6[1]} vs profit 20; cap {sum(v * w for v, w in zip(y6, b))}")
assert sorted(corners) == [(0, 0), (0, 32), (32, 16), (40, 0)] and len(corners[(40, 0)]) == 3
assert zstar == bound == F(gbest, 10) == 928 and best == garg == (32, 16)
assert min(cover[0] - 19, cover[1] - 20, *y) >= 0 and (x[0], x[1]) in corners
assert bent((te, ce)) > bent(bc) and bent((te, ce)) >= F(gb, 200) > bent(bc)
print("ALL CHECKS PASS")
