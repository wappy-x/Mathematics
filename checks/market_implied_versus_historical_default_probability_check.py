# Two default probabilities -- the check behind the card.  Standard library only.
# Q (market): Northwind's CDS curve, bootstrapped two ways, then re-priced by simulation.
# P (history): the rating table's Solid row, by matrix power and by first-step recursion.
from math import exp, log

r, R, NOTIONAL = 0.05, 0.40, 10_000_000.0
KNOTS, QUOTES = (0.0, 1.0, 3.0, 5.0), (0.0120, 0.0200, 0.0250)   # 1y, 3y, 5y par spreads
TABLE = ((0.90, 0.09, 0.01), (0.10, 0.80, 0.10), (0.00, 0.00, 1.00))   # Solid, Shaky, Default

def cum_hazard(t, lams, knots):              # flat hazard on each piece; the last piece runs on
    h = 0.0
    for i, lam in enumerate(lams):
        a, b = knots[i], (knots[i + 1] if i < len(lams) - 1 else 1e9)
        if t > a: h += lam * (min(t, b) - a)
    return h

def survival(t, lams, knots): return exp(-cum_hazard(t, lams, knots))

def annuity(T, lams, knots):                 # quarterly premiums, paid at quarter end if alive
    return sum(0.25 * exp(-r * 0.25 * j) * survival(0.25 * j, lams, knots) for j in range(1, round(4 * T) + 1))

def prot_exact(T, lams, knots, rec):         # (1-R) * integral of lam S e^{-rt}, closed form per piece
    v = 0.0
    for i, lam in enumerate(lams):
        a, b = knots[i], min(knots[i + 1], T)
        if b <= a: break
        v += (1 - rec) * lam / (lam + r) * exp(-r * a) * survival(a, lams, knots) * (1 - exp(-(lam + r) * (b - a)))
    return v

def prot_simpson(T, lams, knots, rec, n=200):   # the same integral, by Simpson's rule on each piece
    v = 0.0
    for i, lam in enumerate(lams):
        a, b = knots[i], min(knots[i + 1], T)
        if b <= a: break
        h = (b - a) / n
        f = lambda t: lam * survival(t, lams, knots) * exp(-r * t)
        s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
        v += (1 - rec) * s * h / 3
    return v

def bisect(f, lo=1e-9, hi=2.0):
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) > 0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def secant(f, x0=0.01, x1=0.05):
    for _ in range(60):
        f0, f1 = f(x0), f(x1)
        if f1 == f0: break
        x0, x1 = x1, x1 - f1 * (x1 - x0) / (f1 - f0)
    return x1

def bootstrap(prot, solve, rec):
    lams = []
    for k, s in enumerate(QUOTES):
        T = KNOTS[k + 1]
        lams.append(solve(lambda x: prot(T, lams[:k] + [x], KNOTS, rec) - s * annuity(T, lams[:k] + [x], KNOTS)))
    return lams

lam1 = bootstrap(prot_exact, bisect, R)        # road 1: closed-form legs, bisection
lam2 = bootstrap(prot_simpson, secant, R)      # road 2: Simpson legs, secant
SQ = [survival(t, lam1, KNOTS) for t in range(6)]

# road 3: 200,000 simulated default times from the curve, then the 5-year legs priced path by path
state = 20260928
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
def default_time(e, lams):                     # invert the cumulative hazard: H(tau) = e
    for i, lam in enumerate(lams):
        a, b = KNOTS[i], (KNOTS[i + 1] if i < len(lams) - 1 else 1e9)
        if e <= lam * (b - a): return a + e / lam
        e -= lam * (b - a)
DISC = [0.0]
for j in range(1, 21): DISC.append(DISC[-1] + 0.25 * exp(-r * 0.25 * j))
paths, dead, ann_sum, prot_sum = 200_000, 0, 0.0, 0.0
for _ in range(paths):
    tau = default_time(-log(uniform()), lam1)
    ann_sum += DISC[min(20, int(4 * tau))]
    if tau <= 5.0: dead += 1; prot_sum += (1 - R) * exp(-r * tau)
pd_mc, spread_mc = dead / paths, prot_sum / ann_sum

# history: Solid row of the table to the fifth power (road 1), first-step recursion (road 2)
row = [1.0, 0.0, 0.0]; SP = [1.0]
for _ in range(5):
    row = [sum(row[i] * TABLE[i][j] for i in range(3)) for j in range(3)]; SP.append(1 - row[2])
pd_s, pd_h = 0.0, 0.0
for _ in range(5):
    pd_s, pd_h = TABLE[0][2] + TABLE[0][0] * pd_s + TABLE[0][1] * pd_h, TABLE[1][2] + TABLE[1][0] * pd_s + TABLE[1][1] * pd_h
pdQ, pdP = 1 - SQ[5], 1 - SP[5]
hQ, hP = -log(SQ[5]) / 5, -log(SP[5]) / 5
flatQ = bisect(lambda h: (1 - exp(-5 * h)) - pdQ)     # flat hazards found by search, not by logs
flatP = bisect(lambda h: (1 - exp(-5 * h)) - pdP)
knotsP = (0.0, 1.0, 2.0, 3.0, 4.0, 5.0)
lamP = [log(SP[k] / SP[k + 1]) for k in range(5)]     # history's hazard, year by year
spread_P = prot_exact(5, lamP, knotsP, R) / annuity(5, lamP, knotsP)
spread_Q = prot_simpson(5, lam1, KNOTS, R) / annuity(5, lam1, KNOTS)
odds = (pdQ / (1 - pdQ)) / (pdP / (1 - pdP))
mark_P = (spread_P - QUOTES[2]) * annuity(5, lamP, knotsP) * NOTIONAL
tri_pd = 1 - exp(-5 * QUOTES[2] / (1 - R))
def pd_at(rec): return 1 - survival(5, bootstrap(prot_exact, bisect, rec), KNOTS)
pd_r20, pd_r60 = pd_at(0.20), pd_at(0.60)
hH = -log(1 - pd_h) / 5

rows = [("lambda 1y, 3y, 5y  road 1 (exact, bisect)", lam1), ("lambda 1y, 3y, 5y  road 2 (Simpson, secant)", lam2),
        ("cumulative hazard H_Q(5), H_P(5)", [-log(SQ[5]), -log(SP[5])]), ("Q survival S_Q(5)", SQ[5]), ("Q default by 5y", pdQ), ("  road 3 simulated, 200,000 paths", pd_mc),
        ("  road 3 simulated 5y par spread", spread_mc), ("  5y par spread re-priced, Simpson", spread_Q),
        ("P survival S_P(5)", SP[5]), ("P default by 5y  matrix power", pdP), ("  first-step recursion", pd_s),
        ("Q average hazard -ln S_Q(5)/5", hQ), ("  flat hazard by bisection", flatQ),
        ("P average hazard -ln S_P(5)/5", hP), ("  flat hazard by bisection", flatP),
        ("hazard ratio hQ/hP", hQ / hP), ("  ln S_Q(5) / ln S_P(5)", log(SQ[5]) / log(SP[5])),
        ("gap in default chance (points)", pdQ - pdP), ("cumulative ratio pdQ/pdP (not rho)", pdQ / pdP),
        ("actuarial 5y spread from P curve", spread_P), ("risk premium 250 bp - actuarial", QUOTES[2] - spread_P),
        ("triangle premium (1-R)(hQ - hP)", (1 - R) * (hQ - hP)), ("pricing odds ratio, default vs survive", odds),
        ("expected loss on $10m, P", NOTIONAL * (1 - R) * pdP), ("expected loss on $10m, Q", NOTIONAL * (1 - R) * pdQ),
        ("wrong: mark 250 bp protection with P", mark_P), ("wrong: triangle 250/0.6 flat, default 5y", tri_pd),
        ("try: recovery 20%, Q default 5y", pd_r20), ("  hazard ratio", -log(1 - pd_r20) / 5 / hP),
        ("try: recovery 60%, Q default 5y", pd_r60), ("  hazard ratio", -log(1 - pd_r60) / 5 / hP),
        ("try: Shaky start, P default 5y", pd_h), ("  hazard ratio hQ/hP(Shaky)", hQ / hH)]
for name, v in rows:
    print(f"{name:<44}" + ("  ".join(f"{x:.6f}" for x in v) if isinstance(v, list) else f"{v:.6f}"))
print("year  Q default %  P default %  Q hazard %  P hazard %  ratio")
for t in range(1, 6):
    hq = cum_hazard(t, lam1, KNOTS) - cum_hazard(t - 1, lam1, KNOTS)
    print(f"{t:>4}  {100 * (1 - SQ[t]):>11.2f}  {100 * (1 - SP[t]):>11.2f}  {100 * hq:>10.2f}  {100 * lamP[t - 1]:>10.2f}  {hq / lamP[t - 1]:>5.2f}")

assert max(abs(a - b) for a, b in zip(lam1, lam2)) < 1e-9, "two bootstraps, two integrators, two root finders"
assert abs(pd_mc - pdQ) < 0.003 and abs(spread_mc - QUOTES[2]) < 0.0008, "simulation re-prices the 5y quote"
assert abs(pdP - pd_s) < 1e-12, "matrix power vs first-step recursion"
assert abs(pdP - 0.10805311) < 1e-12, "rating card's exact five-year Solid default chance"
assert abs(hQ / hP - flatQ / flatP) < 1e-9, "hazard ratio by logs vs by bisection"
assert abs(spread_Q - QUOTES[2]) < 1e-9, "curve built with exact legs re-prices 250 bp with Simpson legs"
assert max(abs(survival(t, lamP, knotsP) - SP[t]) for t in range(6)) < 1e-12, "yearly P hazards rebuild the table's survivals"
assert abs(prot_simpson(5, lamP, knotsP, R) / annuity(5, lamP, knotsP) - spread_P) < 1e-9, "actuarial spread, exact vs Simpson legs"
print("ALL CHECKS PASS")
