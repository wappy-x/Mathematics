# Benders decomposition and the L-shaped method -- the check behind the card.
# Standard library only, exact fractions.  The reservoir buys x thousand m3 of
# irrigation water now at GBP 1k per thousand m3.  Demand is 50, 100 or 150
# (chance 1/3 each); each thousand m3 short on the day costs GBP 2k.  Minimise
# the expected cost.  Road 1: the L-shaped method, single-cut.  Road 2: the
# multi-cut version.  Road 3: the extensive form's plan with dual prices that
# meet its cost.  Road 4: a scan of every whole x, cost worked out directly.
from fractions import Fraction as F
from math import ceil

D, P, C = [50, 100, 150], [F(1, 3)] * 3, 1

def fmt(v): return str(v) if v == int(v) else f"{float(v):.2f}"
def line(a, b): return f"theta >= {a} {'-' if b < 0 else '+'} {abs(b)} x"

def sub(x, d, q=2, cap=None, tight=True):
    # scenario LP: min q*y, y >= d - x, 0 <= y (<= cap).  Its dual: max lam*(d-x) - mu*cap
    # over lam, mu >= 0, lam - mu <= q.  Corners (0,0), (q,0); rays (0,1), (1,1) if capped.
    for lam, mu in ([(0, 1), (1, 1)] if cap is not None else []):
        if lam * (d - x) - mu * cap > 0: return "ray", F(lam * d - mu * cap, lam)
    best = q if d - x > 0 else 0                     # the better corner (ties go to 0)
    return "opt", best * (d - x), best if tight else q

def master(groups, w, lo=F(0), grid=None):
    # min C*x + sum_g w_g * max(0, cuts in g) over x >= lo (or x in grid): convex and
    # piecewise linear, so its minimum sits at lo or at a crossing of two lines.
    def g(x): return C * x + sum(wi * max([F(0)] + [a + b * x for a, b in gr]) for wi, gr in zip(w, groups))
    cand = grid if grid else {lo} | {(a2 - a1) / (b1 - b2) for gr in groups
            for a1, b1 in gr + [(0, 0)] for a2, b2 in gr + [(0, 0)] if b1 != b2}
    cand = sorted(x for x in cand if x >= lo)
    best = min(cand, key=lambda x: (g(x), x))
    return best, g(best)

def benders(q=2, cap=None, multi=False, block=None, tight=True, tag="single", show=True, kmax=20):
    groups = [[] for _ in D] if multi else [[]]
    w = P if multi else [F(1)]
    lo, ub, k, visited = F(0), None, 0, []
    while k <= kmax:
        grid = [F(block * n) for n in range(6)] if block else None
        x, lb = master(groups, w, lo, [v for v in grid if v >= lo] if grid else None)
        res = [sub(x, d, q, cap, tight) for d in D]
        rays = [r[1] for r in res if r[0] == "ray"]
        if rays:
            lo = max([lo] + rays)
            if show: print(f"{tag} k={k} x={fmt(x)} infeasible -> feasibility cuts " + ", ".join(f"x >= {r}" for r in rays))
            k += 1; continue
        visited.append(x)
        val = C * x + sum(p * r[1] for p, r in zip(P, res))
        ub = val if ub is None else min(ub, val)
        cuts = [(F(r[2] * d), F(-r[2])) for r, d in zip(res, D)]   # Q_s(x) >= lam_s * (d_s - x)
        if not multi: cuts = [(sum(p * a for p, (a, _) in zip(P, cuts)), sum(p * b for p, (_, b) in zip(P, cuts)))]
        lams = ",".join(str(r[2]) for r in res)
        done = lb == ub
        qs = ",".join(fmt(r[1]) for r in res)
        if show: print(f"{tag} k={k} x={fmt(x)} theta={fmt(lb - C * x)} LB={fmt(lb)} | Q={qs} cost={fmt(val)} UB={fmt(ub)} | "
                       + ("stop" if done else f"prices {lams} | " + ("; ".join(line(a, b) for a, b in cuts) if not multi else f"{len(cuts)} cuts")))
        if done: return x, ub, k, visited
        for gr, cut in zip(groups, cuts): gr.append(cut)
        k += 1
    return x, lb, k, visited

def f(x, q=2, cap=None):   # expected cost worked out directly from the primal repair y = max(0, d - x)
    short = [max(0, d - x) for d in D]
    if cap is not None and max(short) > cap: return None
    return C * x + sum(p * q * s for p, s in zip(P, short))

def scan(xs, **kw):
    vals = [(f(x, **kw), x) for x in xs if f(x, **kw) is not None]
    return min(vals)[1], min(vals)[0]

print("demand 50/100/150 (1/3 each), buy at 1, shortfall at 2; GBP thousand, thousand m3")
x1, v1, k1, vis = benders()
x2, v2, k2, _ = benders(multi=True, tag="multi")
xs, vs = scan(range(0, 201))
print(f"dual corners per scenario 2, so at most {2 ** len(D)} different single cuts")
print(f"scan x = 0..200: best x={xs} cost={fmt(vs)};  f at kinks 0,50,100,150: " + ", ".join(fmt(f(x)) for x in (0, 50, 100, 150)))
ys = [max(0, d - x1) for d in D]                       # extensive form: plan and dual prices
lam, left = [], F(C)
for p, d in sorted(zip(P, D), key=lambda t: -t[1]):   # dual: max sum lam*d, lam_s <= 2p_s, sum <= C
    lam.append(min(2 * p, left)); left -= lam[-1]
lam = lam[::-1]
primal = C * x1 + sum(2 * p * y for p, y in zip(P, ys))
bound = sum(l * d for l, d in zip(lam, D))
print(f"extensive form: x={x1}, y={', '.join(map(str, ys))}, cost {fmt(primal)}; dual prices {', '.join(map(str, lam))} sum {sum(lam)}, bound {fmt(bound)}")
xc, vc, kc, _ = benders(cap=30, tag="cap 30")
xcs, vcs = scan(range(0, 201), cap=30)
print(f"cap 30 scan: best x={xcs} cost={fmt(vcs)}")
xb, vb, kb, _ = benders(block=35, tag="blocks 35")
grid = [35 * n for n in range(6)]
xbs, vbs = scan(grid)
print("blocks 35 enumeration: " + ", ".join(f"f({x})={fmt(f(x))}" for x in grid))
print("chart x       " + " ".join(f"{x:>6}" for x in range(0, 151, 25)))
for name, cuts in [("true", None), ("1 cut", [(200, -2)]), ("2 cuts", [(200, -2), (100, F(-2, 3))])]:
    vals = [f(x) if cuts is None else C * x + max([0] + [a + b * x for a, b in cuts]) for x in range(0, 151, 25)]
    print(f"chart {name:<8}" + " ".join(f"{fmt(v):>6}" for v in vals))
_, lbc = master([[(F(200), F(0))]], [F(1)])            # breaks 1: a cut with no slope
print(f"break: flat cut theta >= 200 from x=0 -> master LB {lbc} > optimum {fmt(v1)}")
xl, lbl, kl, visl = benders(tight=False, show=False, kmax=4)   # breaks 2: loose prices
print(f"break: prices 2 in every season -> x visits {', '.join(map(fmt, visl))}; LB stuck at {fmt(lbl)}")
unmet = max(D) - x1 - 30                               # breaks 3: no feasibility cut
print(f"break: cap 30 ignored -> x={x1}, {unmet} thousand m3 unmet when demand is 150")
fi = lambda x: C * x + sum(p * 80 * ceil(max(0, d - x) / 40) for p, d in zip(P, D))
xi = min(range(0, 201), key=lambda x: (fi(x), x))       # breaks 4: integer recourse
ubi = min(fi(x) for x in vis)
print(f"break: tankers of 40 at 80 -> LP cuts stop at LB {fmt(v1)}, best visited {fmt(ubi)}; true best x={xi} cost {fmt(fi(xi))}")
for label, kw in [("shortfall 4", dict(q=4)), ("cap 60", dict(cap=60)), ("blocks 25", dict(block=25))]:
    xt, vt, kt, _ = benders(show=label == "cap 60", tag=f"try {label}", **kw)
    print(f"try {label}: x={fmt(xt)} cost={fmt(vt)} after {kt + 1} master solves")
C = F(3, 2); xt, vt, kt, _ = benders(show=False); print(f"try buy 1.5: x={fmt(xt)} cost={fmt(vt)} after {kt + 1} master solves"); C = 1

assert (x1, v1, k1) == (xs, vs, 3) == (100, F(400, 3), 3), "single-cut must match the scan, in 4 master solves"
assert (x2, v2) == (100, F(400, 3)) and k2 == 1, "multi-cut must match, in 2 master solves"
assert min(lam) >= 0 and sum(lam) <= C and all(l <= 2 * p for l, p in zip(lam, P)), "dual prices feasible"
assert bound == primal == v1, "dual bound must meet the extensive form's cost: the certificate"
assert (xc, vc) == (xcs, vcs) == (120, 140), "feasibility cuts must reach the capped optimum"
assert (xb, vb) == (xbs, vbs) == (105, 135), "integer master must match enumeration"
assert lbc > v1 and lbl < v1 and fi(xi) < ubi and v1 < fi(xi), "the four breaks must show"
print("ALL CHECKS PASS")
