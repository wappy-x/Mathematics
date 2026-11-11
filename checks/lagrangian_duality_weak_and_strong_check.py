# Lagrangian duality -- the check behind the card.  Standard library only.
# Two pumps must deliver 140 L/s at least cost.  The demand rule is priced at
# lam pounds an hour per L/s; each price gives a lower bound q(lam) on the cost.
A, E, B = 0.30, (2.0, 1.5), (0.00625, 0.00375)   # £/kWh; L/s per kW; £/h per kW^2
D, LAM0, STEP = 140.0, 0.35, 0.001                  # demand L/s, trial price, ascent step

def cost(p):                                      # f0: pounds an hour for powers p (kW)
    return sum(A * x + b * x * x for x, b in zip(p, B))

def flow(p):                                      # litres a second delivered
    return sum(e * x for e, x in zip(E, p))

def inner(lam):                                   # each pump minimises its own priced cost
    return [max(0.0, (lam * e - A) / (2 * b)) for e, b in zip(E, B)]

def q(lam, d=D):                                  # dual function: min over p of L(p, lam)
    p = inner(lam)
    return cost(p) + lam * (d - flow(p))

def golden(f, lo, hi, n=200):                     # minimise a 1-D convex f, no derivatives
    r = (5 ** 0.5 - 1) / 2
    for _ in range(n):
        m1, m2 = hi - r * (hi - lo), lo + r * (hi - lo)
        if f(m1) < f(m2): hi = m2
        else: lo = m1
    return (lo + hi) / 2

def primal(d=D):                                  # road 1: the plan itself, demand met exactly
    pa = golden(lambda x: cost([x, (d - E[0] * x) / E[1]]), 0.0, d / E[0])
    p = [pa, (d - E[0] * pa) / E[1]]
    return p, cost(p)

def bisect_price(d=D):                            # road 2: the price at which the pumps meet demand
    lo, hi = 0.0, 5.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if flow(inner(mid)) < d: lo = mid
        else: hi = mid
    return (lo + hi) / 2

def ascent(lam, step, n):                         # dual ascent: raise the price by step * shortfall
    out = []
    for k in range(n + 1):
        short = D - flow(inner(lam))
        out.append((k, lam, short, q(lam)))
        lam = max(0.0, lam + step * short)
    return out

pstar_plan, pstar = primal()
p0 = inner(LAM0)
print(f"trial price {LAM0:.2f}: pumps at {p0[0]:.2f} and {p0[1]:.2f} kW, "
      f"deliver {flow(p0):.1f} L/s, short {D - flow(p0):.1f}")
print(f"trial plan costs {cost(p0):.3f} £/h; bound q = {cost(p0):.3f} + "
      f"{LAM0:.2f} x {D - flow(p0):.1f} = {q(LAM0):.3f}")
print(f"road 1, primal search: pumps at {pstar_plan[0]:.4f} and {pstar_plan[1]:.4f} kW, "
      f"p* = {pstar:.4f} £/h")
print(f"pumps switch on at prices {A / E[0]:.2f} and {A / E[1]:.2f}; strictly feasible plan "
      f"50 and 50 kW: {flow([50.0, 50.0]):.1f} L/s, {cost([50.0, 50.0]):.3f} £/h")
print(f"gap at the trial price: {pstar - q(LAM0):.4f} £/h = {100 * (pstar - q(LAM0)) / pstar:.2f}%")
slope_s = (flow(inner(0.41)) - flow(inner(0.39))) / 0.02          # how fast delivery rises with price
print(f"shortfall falls {slope_s:.1f} L/s per unit of price; error x {1 - STEP * slope_s:.2f} a step; "
      f"steps above {2 / slope_s:.6f} diverge")
print(" k   price   short L/s   bound q   gap %")
hist = ascent(LAM0, STEP, 6)
for k, lam, short, qq in hist:
    print(f"{k:2d}  {lam:.5f}  {short:9.4f}  {qq:8.4f}  {100 * (pstar - qq) / pstar:.4f}")
run, k = LAM0, 0
while abs(D - flow(inner(run))) >= 0.01:
    run, k = run + STEP * (D - flow(inner(run))), k + 1
print(f"ascent from {LAM0:.2f}, stop when |short| < 0.01 L/s: {k} steps, price {run:.5f}")
lstar = bisect_price()
dstar = q(lstar)
pl = inner(lstar)
print(f"road 2, price by bisection: lam* = {lstar:.6f}, plan {pl[0]:.4f} and {pl[1]:.4f} kW, "
      f"d* = {dstar:.4f}")
sl = [e * e / (2 * b) for e, b in zip(E, B)]     # a running pump delivers sl * lam - ic litres a second
ic = [e * A / (2 * b) for e, b in zip(E, B)]
lam_exact = (D + sum(ic)) / sum(sl)
print(f"road 3, shortfall {D:.0f} - ({sl[0]:.0f} lam - {ic[0]:.0f}) - ({sl[1]:.0f} lam - {ic[1]:.0f}) = "
      f"{D + sum(ic):.0f} - {sum(sl):.0f} lam = 0 at lam* = {lam_exact:.6f}")
stat = max(abs(A + 2 * b * x - lstar * e) for x, b, e in zip(pstar_plan, B, E))  # road-1 plan, road-2 price
print(f"KKT, road-1 plan with lam*: stationarity residual {stat:.6f}, lam* x shortfall {abs(lstar * (D - flow(pstar_plan))):.6f}")
curv = (q(0.41) - 2 * q(0.40) + q(0.39)) / 0.01 ** 2
print(f"curvature of q near lam*: {curv:.1f} (gap at 0.35 = {-curv / 2:.0f} x 0.05^2 = {-curv / 2 * 0.0025:.4f})")
lams = [i / 100 for i in range(0, 101)]
plans = [[i * 2.0, j * 2.0] for i in range(41) for j in range(41)]
feas = [p for p in plans if flow(p) >= D]
worst = min(cost(p) - q(l) for p in feas for l in lams)
print(f"weak duality: {len(feas)} feasible plans x {len(lams)} prices, smallest cost - q = {worst:.4f}")
mids = sum(q((x + y) / 2) >= (q(x) + q(y)) / 2 - 1e-9 for x in lams for y in lams)
print(f"concavity: midpoint test passed for {mids} of {len(lams) ** 2} price pairs")
slope = (primal(141.0)[1] - primal(139.0)[1]) / 2
print(f"shadow price: (p*(141) - p*(139)) / 2 = {slope:.4f} £/h per L/s")
print("chart, price " + " ".join(f"{0.20 + 0.05 * i:6.2f}" for i in range(9)))
print("chart, q     " + " ".join(f"{q(0.20 + 0.05 * i):.3f}" for i in range(9)))
# ---- what breaks ----
CB = A * 70 + B[1] * 70 * 70                      # fixed-speed pump B: off, or 70 kW
def q_fixed(lam):
    pa = max(0.0, (lam * E[0] - A) / (2 * B[0]))
    return lam * D + A * pa + B[0] * pa * pa - lam * E[0] * pa + min(0.0, CB - lam * E[1] * 70)
fix_p = min(cost([D / E[0], 0.0]), CB + cost([(D - E[1] * 70) / E[0], 0.0]))
fix_l = max((q_fixed(i / 10000), i / 10000) for i in range(10001))
print(f"break, fixed-speed pump: p* = {fix_p:.4f}, best bound d* = {fix_l[0]:.4f} at "
      f"{fix_l[1]:.4f}, gap {100 * (fix_p - fix_l[0]) / fix_p:.2f}%")
print(f"break, fixed-speed best plan: pump 1 at {(D - E[1] * 70) / E[0]:.2f} kW, pump 2 at 70 kW "
      f"({E[1] * 70:.1f} L/s), priced cost of pump 2 at {fix_l[1]:.4f}: {CB - fix_l[1] * E[1] * 70:.4f}")
big = ascent(LAM0, 0.004, 6)
print("break, step 0.004, prices: " + " ".join(f"{lam:.3f}" for _, lam, _, _ in big))
print(f"break, step 0.004, gap after 6 steps: {100 * (pstar - big[-1][3]) / pstar:.2f}%")
print(f"break, trial plan read as the answer: {cost(p0):.3f} £/h, {flow(p0):.1f} of {D:.0f} L/s")
print(f"break, demand term left out: q = {cost(p0) - LAM0 * flow(p0):.3f}")
# ---- try changing ----
p160 = primal(160.0)
print(f"try, demand 160: lam* = {bisect_price(160.0):.4f}, p* = {p160[1]:.4f}, "
      f"pumps {p160[0][0]:.2f} and {p160[0][1]:.2f}")
print(f"try, trial price 0.45: q = {q(0.45):.4f}; step 1/620 from 0.35: {ascent(LAM0, 1 / 620, 1)[1][1]:.6f}")
assert abs(pstar - 40.0) < 1e-6 and abs(dstar - pstar) < 1e-6        # strong duality, two roads
assert abs(lstar - lam_exact) < 1e-9 and abs(slope - lstar) < 1e-6   # price three ways
assert abs((pstar - q(LAM0)) / pstar - 0.019375) < 1e-9              # the 2 percent at the trial price
assert worst >= -1e-9 and mids == len(lams) ** 2                     # weak duality and concavity
assert fix_p - fix_l[0] > 1.0 and stat < 1e-6                       # nonconvex: the gap stays open
print("ALL CHECKS PASS")
