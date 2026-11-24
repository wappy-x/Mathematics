# Column generation on a cutting-stock problem.  Standard library only, exact fractions.
# Minimise the number of 10 m boards cut to cover an order of pieces.  The master LP picks how many
# boards to cut to each pattern; a knapsack (the pricing problem) writes each new pattern from the duals.
from fractions import Fraction as F
from math import ceil

def solve_master(P, d):        # max d.y s.t. a.y <= 1 for each pattern a, y >= 0: the master's dual
    m, n = len(d), len(P)      # simplex on the dual, Bland's rule; the boards x_p are read from the last row
    T = [[F(a[i]) for i in range(m)] + [F(int(j == r)) for j in range(n)] + [F(1)] for r, a in enumerate(P)]
    obj, basis = [F(-v) for v in d] + [F(0)] * (n + 1), [m + r for r in range(n)]
    while True:
        e = next((j for j in range(m + n) if obj[j] < 0), None)
        if e is None: break
        r = min((r for r in range(n) if T[r][e] > 0), key=lambda r: (T[r][-1] / T[r][e], basis[r]))
        T[r] = [v / T[r][e] for v in T[r]]
        for k in range(n):
            if k != r and T[k][e]: f = T[k][e]; T[k] = [a - f * b for a, b in zip(T[k], T[r])]
        f = obj[e]; obj = [a - f * b for a, b in zip(obj, T[r])]; basis[r] = e
    y = [F(0)] * m
    for r, b in enumerate(basis):
        if b < m: y[b] = T[r][-1]
    return obj[-1], y, obj[m:m + n]

def price(y, l, L):            # exact pricing: unbounded knapsack by a table over board length 0..L
    best = [(F(0), ())] * (L + 1)
    for c in range(1, L + 1):
        best[c] = best[c - 1]
        for i in range(len(l)):
            if l[i] <= c and best[c - l[i]][0] + y[i] > best[c][0]:
                best[c] = (best[c - l[i]][0] + y[i], best[c - l[i]][1] + (i,))
    v, items = best[L]
    return v, tuple(items.count(i) for i in range(len(l)))

def greedy(y, l, L):           # a quick pricing guess: fill by price per metre, best first
    a, room = [0] * len(l), L
    for i in sorted(range(len(l)), key=lambda i: (-y[i] / l[i], i)):
        a[i] = room // l[i]; room -= a[i] * l[i]
    return sum(y[i] * a[i] for i in range(len(l))), tuple(a)

def colgen(l, d, L, P, pricer=price, show=None):
    P, hist = [tuple(p) for p in P], []
    while True:
        z, y, x = solve_master(P, d)
        v, a = pricer(y, l, L)
        hist.append((z, y, v, a, z / v))
        if show: show(len(hist) - 1, z, y, v, a)
        if v <= 1: return z, y, x, P, hist
        P.append(a)

fs = lambda v: " ".join(str(t) for t in v)
def show(k, z, y, v, a):
    print(f"round {k}: master {z} boards, duals {fs(y)}; best pattern {a} worth {v},",
          f"reduced cost {1 - v}; bound {z / v} = {float(z / v):.4f}")

l, d, L = [3, 4, 5], [30, 20, 10], 10          # piece lengths (m), pieces wanted, board length (m)
start = [(3, 0, 0), (0, 2, 0), (0, 0, 2)]
z, y, x, P, hist = colgen(l, d, L, start, show=show)
print("round 0, bound from kappa = 25 boards:", hist[0][0] + 25 * (1 - hist[0][2]))
print("master plan:", ", ".join(f"{xp} x {p}" for xp, p in zip(x, P) if xp))
allp = [(a, b, c) for a in range(4) for b in range(3) for c in range(3) if 3 * a + 4 * b + 5 * c <= L and a + b + c]
maxp = [p for p in allp if 10 - (3 * p[0] + 4 * p[1] + 5 * p[2]) < 3]
vals = [sum(yi * ai for yi, ai in zip(y, p)) for p in allp]
print(f"patterns that fit: {len(allp)}, with no room for another piece: {len(maxp)};",
      f"highest value at the final duals {max(vals)}, on {sum(v == 1 for v in vals)} patterns")
print("round 0 master plan:", fs(solve_master(start, d)[2]), "boards for", ", ".join(map(str, start)))
for k in range(2):
    print(f"round {k} values:", ", ".join(f"{p} {sum(yi * ai for yi, ai in zip(hist[k][1], p))}" for p in maxp))
covered = [sum(xp * p[i] for xp, p in zip(x, P)) for i in range(3)]
print("certificate: pieces covered", fs(covered), "; boards", sum(x), "; dual value", sum(a * b for a, b in zip(d, y)))
z_all = solve_master(allp, d)[0]
print("road 2, master with all", len(allp), "patterns listed:", z_all)
length = sum(a * b for a, b in zip(l, d))
k_pt = [F(di, 22) for di in d]
print(f"compact LP: total length {length} m, so at least {F(length, L)} boards;",
      f"22 boards each holding {fs(k_pt)} pieces fill {sum(a * b for a, b in zip(l, k_pt))} m")
f = {}                                          # road 3: fewest whole boards for every smaller order
for a in range(31):
    for b in range(21):
        for c in range(11):
            nxt = [(max(a - p[0], 0), max(b - p[1], 0), max(c - p[2], 0)) for p in maxp]
            f[a, b, c] = 0 if a + b + c == 0 else 1 + min(f[s] for s in nxt if s != (a, b, c))
plan = [ceil(xp) for xp in x]
cover = [sum(n * p[i] for n, p in zip(plan, P)) for i in range(3)]
print(f"road 3, whole boards by table over {len(f)} orders: {f[30, 20, 10]};",
      f"rounding the master up: {sum(plan)} boards covering {fs(cover)}")
down = [int(xp) for xp in x]
print("round down:", sum(down), "boards covering", fs(sum(n * p[i] for n, p in zip(down, P)) for i in range(3)))
zg, _, _, _, hg = colgen(l, d, L, start, pricer=greedy)
print(f"greedy pricing: pattern {hg[0][3]} worth {hg[0][2]}; stops at {zg} boards")
waste = sum(n * (L - sum(a * b for a, b in zip(l, p))) for n, p in zip(plan, P))   # sawn offcut, board by board
print(f"unused: {sum(plan) * L - length} m over {sum(plan)} boards: offcut {waste} m, spare pieces {fs(c - di for c, di in zip(cover, d))}")

lb, db, Lb = [120, 150, 180, 230, 270, 310, 340, 380, 430, 470], [30, 25, 40, 22, 18, 35, 14, 20, 12, 16], 1000
zb, yb, xb, Pb, hb = colgen(lb, db, Lb, [[Lb // lb[i] * (i == j) for j in range(10)] for i in range(10)])
for k, (zk, _, vk, _, bk) in enumerate(hb):
    print(f"tail k={k:2d}: master {float(zk):8.4f} bound {float(bk):8.4f} gap {float(zk - bk):7.4f}")
print(f"tail: LP {zb} = {float(zb):.2f} after {len(hb) - 1} new patterns; at least {ceil(zb)} boards;",
      f"rounding up uses {sum(ceil(v) for v in xb)}; final duals {fs(yb[:3])} ...")
kb = max(range(len(hb) - 1), key=lambda k: (hb[k][4], -k))
lenb = F(sum(a * b for a, b in zip(lb, db)), Lb)               # length floor: price every piece at l_i / L
ks = next(k for k, h in enumerate(hb) if ceil(h[0]) == ceil(max([lenb] + [g[4] for g in hb[:k + 1]])))
print(f"tail: length floor {float(lenb):.2f} from k=0, proving {ceil(lenb)} boards;",
      f"best bound z/v* before the last round {float(hb[kb][4]):.4f} at k={kb}, proving {ceil(hb[kb][4])}")
print(f"tail: stop rule, master and best floor both round up to {ceil(hb[ks][0])} from k={ks}, {len(hb) - 1 - ks} rounds early;",
      f"master within 1% from k={next(k for k, h in enumerate(hb) if h[0] <= F(101, 100) * zb)}")
def fits(l, L, i=0):           # every pattern that fits one board, listed by brute force
    return [()] if i == len(l) else [(a,) + p for a in range(L // l[i] + 1) for p in fits(l, L - a * l[i], i + 1)]
allb = [p for p in fits(lb, Lb) if any(p)]
vb = max(sum(a * b for a, b in zip(yb, p)) for p in allb)
print(f"tail: all {len(allb)} patterns that fit, listed: highest value at the final duals {vb}")

assert z == z_all == F(45, 2) == sum(a * b for a, b in zip(d, y))     # column generation = full master = dual
assert max(vals) == 1 and all(c >= di for c, di in zip(covered, d))   # duals feasible for every pattern
assert f[30, 20, 10] == sum(plan) == ceil(z) and all(c >= di for c, di in zip(cover, d))
assert all(h[4] <= z for h in hist) and all(h[4] <= zb for h in hb)    # every round's bound is below the LP
assert zg == 25 > z and covered[1] > sum(n * p[1] for n, p in zip(down, P))
assert vb == 1                                                     # the final duals price every pattern at most 1
assert zb == lenb and ceil(hb[ks][0]) == ceil(zb) and all(v >= 0 for v in xb)   # LP = length floor; the stop rule's bound is final
for nd, nl, lab in [([31, 20, 10], 10, "31 short pieces"), ([30, 20, 10], 11, "11 m boards")]:
    zt = colgen(l, nd, nl, start)[0]
    print(f"try {lab}: LP {zt} = {float(zt):.2f}, so at least {ceil(zt)} boards")
zt, _, _, _, ht = colgen(l, d, L, [(1, 0, 0), (0, 1, 0), (0, 0, 1)])
print(f"try one piece per board to start: {ht[0][0]} boards, {len(ht) - 1} new patterns, LP {zt}")
print("ALL CHECKS PASS")
