# Two-stage stochastic programming with recourse -- the check behind the card.
# Standard library only.  The reservoir: 70 million m3 in store, room for 100.
# Now: let x out through the spill gates (GBP 2k per million m3).  Then the rain
# comes: dry, normal or wet.  After it: buy power the turbine could not make
# (10), pay for overflow (50) and for each million m3 below the 50 reserve (30),
# all in thousand pounds per million m3.  Minimise the expected cost.
# Road 1 solves the whole scenario tree as ONE linear program, by the dual
# simplex method in exact fractions.  Road 2 checks its dual prices (a lower
# bound).  Road 3 scans every whole x with the recourse rule worked out in words.
from fractions import Fraction as Fr

NAMES, P, RAIN = ["dry", "normal", "wet"], [Fr(3, 10), Fr(1, 2), Fr(1, 5)], [10, 30, 90]

def build(p, w, gate=2, flood=50, buy=10, short=30):
    """Extensive form: columns x, then (g_s, f_s, b_s) per scenario; rows A z >= h."""
    n = 1 + 3 * len(p)
    cost = [Fr(gate)] + [pi * k for pi in p for k in (buy, flood, short)]
    A, h, rows = [], [], []
    def row(coefs, rhs, name):
        a = [Fr(0)] * n
        for j, v in coefs: a[j] = Fr(v)
        A.append(a); h.append(Fr(rhs)); rows.append(name)
    row([(0, -1)], -70, "gates: x <= 70")
    for s, ws in enumerate(w):
        g, f, b, nm = 1 + 3 * s, 2 + 3 * s, 3 + 3 * s, NAMES[s]
        row([(0, 1), (g, -1), (f, 1)], ws - 50, nm + " room: level <= 100")
        row([(0, -1), (g, 1), (f, -1), (b, 1)], -ws, nm + " reserve: level + b >= 50")
        row([(g, -1)], -20, nm + " turbine: g <= 20")
        row([(0, -1), (g, 1), (f, -1)], -50 - ws, nm + " level >= 0")
    return cost, A, h, rows

def dual_simplex(cost, A, h):
    """Every cost >= 0, so the all-zero plan is the cheapest plan of all; it just
    breaks some rows.  Each pivot repairs one broken row at the least extra cost
    per unit, keeping every reduced cost >= 0.  When no row is broken, done."""
    m, n = len(A), len(cost)
    T = [[-a for a in A[i]] + [Fr(int(i == k)) for k in range(m)] + [-h[i]] for i in range(m)]
    d, basis, pivots = list(cost) + [Fr(0)] * m, [n + i for i in range(m)], 0
    while True:
        bad = [i for i in range(m) if T[i][-1] < 0]
        if not bad: break
        i = bad[0]                                       # Bland: lowest broken row
        cand = [j for j in range(n + m) if T[i][j] < 0]
        if not cand: raise ValueError("infeasible")
        j = min(cand, key=lambda j: (d[j] / -T[i][j], j))
        piv = T[i][j]; T[i] = [v / piv for v in T[i]]
        for k in range(m):
            if k != i and T[k][j] != 0:
                fct = T[k][j]; T[k] = [a - fct * b for a, b in zip(T[k], T[i])]
        fct = d[j]; d = [a - fct * b for a, b in zip(d, T[i][:-1])]
        basis[i], pivots = j, pivots + 1
    z = [Fr(0)] * n
    for i, j in enumerate(basis):
        if j < n: z[j] = T[i][-1]
    return z, d[n:], pivots                              # plan, dual prices, pivots

def Q(L, buy=10, flood=50, short=30):
    """Recourse rule in words, for L million m3 on hand after the rain: run the
    turbine to 20 unless that dips below the 50 reserve; spill what is over 100."""
    run = max(0, min(20, L - 50))
    return buy * (20 - run) + flood * max(0, L - run - 100) + short * max(0, 50 - L)

def expected(x, p=P, w=RAIN, gate=2, flood=50):
    return gate * x + sum(pi * Q(70 + wi - x, flood=flood) for pi, wi in zip(p, w))

def scan(p=P, w=RAIN, gate=2, flood=50):
    return min((expected(x, p, w, gate, flood), x) for x in range(71))

def show(label, v): print(f"{label:<44}{str(v):>12}")

cost, A, h, rows = build(P, RAIN)
z, lam, pivots = dual_simplex(cost, A, h)
pstar = sum(c * v for c, v in zip(cost, z))
print(f"tree: 1 decision now, 3 leaves; one LP with {len(cost)} columns, {len(A)} rows")
show("road 1: dual simplex pivots", pivots)
show("  x*, let out now (million m3)", z[0])
show("  p*, expected cost (GBP thousand)", pstar)
show("  of which gates, and expected repair", f"{2 * z[0]}, {pstar - 2 * z[0]}")
for s in range(3):
    g, f, b = z[1 + 3 * s: 4 + 3 * s]
    L = 70 + RAIN[s] - z[0]
    print(f"  {NAMES[s]:<7}rain {RAIN[s]:>2} p {str(P[s]):>4}: on hand {L}, turbine {20 - g}, "
          f"bought {g}, overflow {f}, short {b}, cost {Q(L)}")
    assert Q(L) == 10 * g + 50 * f + 30 * b, "LP recourse must match the rule in words"
print("road 2: dual prices lambda on the binding rows")
for i, v in enumerate(lam):
    if v != 0: show("  " + rows[i], v)
reduced = [c - sum(A[i][j] * lam[i] for i in range(len(A))) for j, c in enumerate(cost)]
bound = sum(hi * li for hi, li in zip(h, lam))
show("  smallest reduced cost, must be >= 0", min(reduced))
show("  dual bound h^T lambda", bound)
best_e, best_x = scan()
show("road 3: scan x = 0..70, best x", best_x)
show("  its expected cost", best_e)
print("chart x  " + " ".join(f"{x:>4}" for x in range(0, 61, 5)))
print("chart E  " + " ".join(f"{str(expected(x)):>4}" for x in range(0, 61, 5)))
for x in (10, 20, 30, 40): show(f"  expected cost at x = {x}", expected(x))

wbar = sum(pi * wi for pi, wi in zip(P, RAIN))     # plan for the average rain
fc, xbar = scan([Fr(1)], [wbar])
eev = expected(xbar)
ws_each = [scan([Fr(1)], [wi])[0] for wi in RAIN]   # perfect foresight, each leaf
ws = sum(pi * v for pi, v in zip(P, ws_each))
show("average rain (million m3)", wbar)
show("  its plan x, and the cost it forecasts", f"{xbar}, {fc}")
show("  EEV: that plan's real expected cost", eev)
show("wait-and-see: dry, normal, wet", ", ".join(str(v) for v in ws_each))
show("  WS, perfect-foresight average", ws)
show("VSS = EEV - p*", eev - pstar)
show("EVPI = p* - WS", pstar - ws)
x_wet = scan([Fr(1)], [90])[1]
x_avg = sum(pi * scan([Fr(1)], [wi])[1] for pi, wi in zip(P, RAIN))
fixed = min((2 * x + 10 * (20 - y) + sum(pi * (50 * max(0, 70 + wi - x - y - 100)
         + 30 * max(0, 50 - (70 + wi - x - y))) for pi, wi in zip(P, RAIN)), x, y)
         for x in range(71) for y in range(21))
show("wrong: plan for the average rain", eev)
show(f"wrong: plan for the wet year, x = {x_wet}", expected(x_wet))
show(f"wrong: average the 3 foresight plans, x = {x_avg}", expected(x_avg))
show(f"wrong: fix turbine {fixed[2]} now too, x = {fixed[1]}", fixed[0])
show("  extra cost of fixing it, over p*", fixed[0] - pstar)
show("size: leaves of a 12-month, 3-way tree", 3 ** 12)
for label, p, gate, flood in [("try: wet 40%, normal 30%", [Fr(3, 10), Fr(3, 10), Fr(2, 5)], 2, 50),
                              ("try: overflow costs 100", P, 2, 100), ("try: gates cost 12", P, 12, 50)]:
    e, x = scan(p, RAIN, gate, flood)
    assert dual_simplex(*build(p, RAIN, gate, flood)[:3])[0][0] == x, "LP and scan agree"
    show(label + ": x*, p*", f"{x}, {e}")
print(f"figure, root x {z[0]}; leaves (rain, chance, turbine, bought, overflow, cost): " + " | ".join(
    f"{NAMES[s]} {RAIN[s]} {float(P[s])} {20 - z[1 + 3 * s]} {z[1 + 3 * s]} {z[2 + 3 * s]} {Q(70 + RAIN[s] - z[0])}"
    for s in range(3)))

assert (z[0], pstar) == (best_x, best_e) == (30, 220), "LP must match the scan"
assert min(z) >= 0 and all(sum(a * v for a, v in zip(A[i], z)) >= h[i] for i in range(len(A))), "the plan must meet every row"
assert min(reduced) >= 0 and min(lam) >= 0, "dual prices must be feasible"
assert bound == pstar, "dual bound must meet the LP value: the certificate"
assert ws <= pstar <= eev and fc < eev, "foresight <= recourse <= mean-value plan"
assert (wbar, xbar, eev, ws) == (36, 0, 400, 16), "Step 5 by hand: average rain 36, its plan 0, EEV 400, WS 16"
print("ALL CHECKS PASS")
