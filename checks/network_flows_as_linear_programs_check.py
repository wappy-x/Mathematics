# Network flows as linear programs -- the check behind the card. Standard library only.
# Two mills ship timber to three workshops; MINIMISE haulage cost. Roads: the transportation
# simplex (it only adds and subtracts); its prices as a certificate; every corner of the
# linear program in exact fractions; every whole-tonne plan listed.
from fractions import Fraction as Fr
from itertools import combinations, product

COST = [[6, 7, 10], [7, 6, 7]]            # pounds per tonne, North and South mill to W1, W2, W3
SUPPLY, DEMAND = [40, 30], [25, 20, 15]   # tonnes a week
HOURS, BUDGET = [3, 2, 2], 55             # South lorry hours per tonne to W1, W2, W3; hours a week
NAMES = ["W1", "W2", "W3", "spare"]
lab = lambda r: f"{'NS'[r[0]]}-{NAMES[r[1]]}"

def transport(cost, supply, demand, log=False):
    c = [row + [0] for row in cost]                  # the spare column costs nothing
    a, b = list(supply), list(demand) + [sum(supply) - sum(demand)]
    m, n = len(a), len(b)
    x, i, j = {}, 0, 0                               # northwest-corner start
    while i < m and j < n:
        q = min(a[i], b[j]); x[(i, j)] = q; a[i] -= q; b[j] -= q
        if a[i] == 0 and i < m - 1: i += 1
        else: j += 1
    total = lambda: sum(c[i][j] * q for (i, j), q in x.items())
    if log: print("northwest-corner start:", ", ".join(f"{lab(r)} {q}" for r, q in x.items()), "| cost", total())
    k = 0
    while True:
        u, v = [None] * m, [None] * n; v[n - 1] = 0  # prices: u_i + v_j = c_ij on used routes
        for _ in range(m + n):
            for (i, j) in x:
                if u[i] is None and v[j] is not None: u[i] = c[i][j] - v[j]
                if v[j] is None and u[i] is not None: v[j] = c[i][j] - u[i]
        red = {(i, j): c[i][j] - u[i] - v[j] for i in range(m) for j in range(n) if (i, j) not in x}
        e = min(red, key=lambda r: (red[r], r))
        if red[e] >= 0: return x, total(), u, v, red, k
        adj = {}                                     # the loop the new route closes, a path in the tree
        for (i, j) in x:
            adj.setdefault(("r", i), []).append(("c", j)); adj.setdefault(("c", j), []).append(("r", i))
        prev, stack = {("c", e[1]): None}, [("c", e[1])]
        while stack:
            nd = stack.pop()
            for nb in adj.get(nd, []):
                if nb not in prev: prev[nb] = nd; stack.append(nb)
        path = [("r", e[0])]
        while prev[path[-1]] is not None: path.append(prev[path[-1]])
        cells = [(p[1], q[1]) if p[0] == "r" else (q[1], p[1]) for p, q in zip(path, path[1:])]
        minus, plus = cells[0::2], cells[1::2]
        th = min(x[r] for r in minus); out = min(r for r in minus if x[r] == th)
        for r in minus: x[r] -= th
        for r in plus: x[r] += th
        x[e] = th; del x[out]; k += 1
        if log: print(f"pivot {k}: enter {lab(e)} (reduced cost {red[e]}), shift {th} t, leave {lab(out)}, cost {total()}")

def det3(M):
    return (M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) - M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0])
            + M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0]))

def rows(supply, budget):  # y = North's tonnes to W1..W3; South sends DEMAND - y; each row g.y <= h
    R = [([-int(i == j) for i in range(3)], 0) for j in range(3)]
    R += [([int(i == j) for i in range(3)], DEMAND[j]) for j in range(3)]
    R += [([1, 1, 1], supply[0]), ([-1, -1, -1], supply[1] - sum(DEMAND))]
    if budget: R.append(([-h for h in HOURS], budget - sum(h * d for h, d in zip(HOURS, DEMAND))))
    return R

fits = lambda R, y: all(sum(g[k] * y[k] for k in range(3)) <= h for g, h in R)
plan_cost = lambda y: sum(COST[0][j] * y[j] + COST[1][j] * (DEMAND[j] - y[j]) for j in range(3))
south_hours = lambda y: sum(HOURS[j] * (DEMAND[j] - y[j]) for j in range(3))
show = lambda y: "(" + ", ".join(str(q) for q in y) + ")"

def corners(supply, budget=0):  # every corner: three rows tight, solved by Cramer's rule
    R, pts = rows(supply, budget), set()
    for trio in combinations(R, 3):
        A = [g for g, _ in trio]; D = det3(A)
        if D == 0: continue
        y = tuple(Fr(det3([[trio[r][1] if k == col else A[r][k] for k in range(3)] for r in range(3)]), D)
                  for col in range(3))
        if fits(R, y): pts.add(y)
    best = min(pts, key=plan_cost)
    return len(pts), sum(all(q.denominator == 1 for q in p) for p in pts), best, plan_cost(best)

def whole_best(supply, budget=0):
    R = rows(supply, budget)
    ok = [y for y in product(*(range(d + 1) for d in DEMAND)) if fits(R, y)]
    return len(ok), min(map(plan_cost, ok))

x, cost, u, v, red, piv = transport(COST, SUPPLY, DEMAND, log=True)
print("best plan:", ", ".join(f"{lab(r)} {q}" for r, q in sorted(x.items())), f"| cost {cost}, pivots {piv}")
print(f"prices: u North {u[0]}, South {u[1]}; v W1 {v[0]}, W2 {v[1]}, W3 {v[2]}, spare {v[3]}")
print("reduced costs, unused routes:", ", ".join(f"{lab(r)} {q}" for r, q in sorted(red.items())))
dual = sum(a * p for a, p in zip(SUPPLY + DEMAND + [sum(SUPPLY) - sum(DEMAND)], u + v))
print("dual value: supplies times u plus demands times v =", dual)
nc, nw, cb, cv = corners(SUPPLY)
print(f"corners {nc}, whole {nw}, best corner, North sends {show(cb)}, cost {cv}")
nplans, wb = whole_best(SUPPLY)
print(f"whole plans {nplans}, best {wb}; South lorry hours in best plan {south_hours(cb)}")
hc, hw, hb, hv = corners(SUPPLY, BUDGET)
hn, hwb = whole_best(SUPPLY, BUDGET)
print(f"break, hours <= {BUDGET}: corners {hc}, whole {hw}, best: North sends {show(hb)}, South-W2 {DEMAND[1] - hb[1]}, cost {hv} = {float(hv)}")
print(f"break, hours <= {BUDGET}: whole plans {hn}, best whole plan {hwb}")
f = [j for j in range(3) if hb[j].denominator > 1][0]          # the route with a half tonne
up = tuple(int(q) for q in hb); down = tuple(q + (j == f) for j, q in enumerate(up))
print(f"break, round South-{NAMES[f]} up to {DEMAND[f] - up[f]} t: hours {south_hours(up)}; down to "
      f"{DEMAND[f] - down[f]} t: hours {south_hours(down)}, cost {plan_cost(down)}")
_, _, fb, fv = corners([40, Fr(61, 2)])
print(f"break, South 30.5 t: best: North sends {show(fb)}, cost {fv} = {float(fv)}")
print(f"break, supply as equality: supply {sum(SUPPLY)} t, demand {sum(DEMAND)} t, no plan fits")
t1 = transport(COST, [40, 35], DEMAND)[1]
t2 = transport(COST, SUPPLY, [25, 21, 15])[1]
x3, t3 = transport([[6, 7, 10], [4, 6, 7]], SUPPLY, DEMAND)[:2]
_, _, _, t4 = corners(SUPPLY, 56)
print(f"try, South 35 t: {t1}; W2 needs 21 t: {t2}; hours <= 56: {t4}")
print("try, S-W1 at 4:", ", ".join(f"{lab(r)} {q}" for r, q in sorted(x3.items())), f"| cost {t3}")
print("figure, North (60 80) South (60 180) spare (290 35) W1 (290 95) W2 (290 155) W3 (290 215)")

assert cost == cv == wb == 380, "simplex, all corners and all whole plans must agree"
assert dual == cost and min(red.values()) >= 0, "prices certify the plan: no route undercuts them"
assert nw == nc and cb == tuple(x.get((0, j), 0) for j in range(3)), "every corner whole; the best is the simplex plan"
assert hb[f].denominator == 2 and hv < hwb, "a non-network row lets a half tonne in, below the best whole plan"
assert t1 == cost + 5 * u[1] and t2 == cost + v[1], "prices predict the cost of one more tonne"
assert t3 == cost + 15 * (red[(1, 0)] - 3), "S-W1 at 4: reduced cost 2 - 3 = -1 a tonne, over 15 t"
print("ALL CHECKS PASS")
