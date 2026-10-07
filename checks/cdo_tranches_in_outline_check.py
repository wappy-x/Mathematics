# Tranches in outline -- the check behind the card.  Standard library only.
# House pool: 100 loans, 5% five-year default chance, recovery 40%, correlation 20%.
# The normal CDF, its inverse, the integrator and the random numbers are written here.
from math import sqrt, exp, log, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                 # bell-curve area, by series
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total
def Ninv(u):                                              # its inverse, by bisection
    lo, hi = -9.0, 9.0
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < u else (lo, mid)
    return 0.5 * (lo + hi)
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

P5, R, RHO, NAMES = 0.05, 0.40, 0.20, 100
LGD = 1.0 - R
TR = [("equity 0-3%", 0.00, 0.03), ("junior mezz 3-7%", 0.03, 0.07),
      ("senior mezz 7-10%", 0.07, 0.10), ("senior 10-100%", 0.10, 1.00)]

def cut(L, A, D):                            # call spread on pool loss, per unit of width
    return min(max(L - A, 0.0), D - A) / (D - A)
def etl_factor(p, rho, A, D, n=2000, lgd=LGD):  # road 1: average over the economy
    c = Ninv(p)
    def f(m):
        q = p if rho == 0.0 else N((c - sqrt(rho) * m) / sqrt(1.0 - rho))
        return cut(lgd * q, A, D) * phi(m)
    return simpson(f, -8.0, 8.0, n)
def etl_losscurve(p, rho, A, D, n=20000):    # road 2: integrate P(pool loss > x), A to D
    c, top = Ninv(p), min(D, LGD)
    def surv(x):
        if x <= 0.0: return 1.0
        if x >= LGD: return 0.0
        return 1.0 - N((sqrt(1.0 - rho) * Ninv(x / LGD) - c) / sqrt(rho))
    return simpson(surv, A, top, n) / (D - A) if top > A else 0.0
def etl_recursion(p, rho, n=400):            # road 3: exact 100-name pool, name by name
    c = Ninv(p)
    def dist_at(m):
        q = N((c - sqrt(rho) * m) / sqrt(1.0 - rho))
        dist = [1.0] + [0.0] * NAMES         # dist[k]: chance of k defaults so far
        for j in range(NAMES):               # add one name at a time
            for k in range(j + 1, 0, -1):
                dist[k] = dist[k] * (1.0 - q) + dist[k - 1] * q
            dist[0] *= 1.0 - q
        return dist
    h, out = 16.0 / n, [0.0] * len(TR)
    for i in range(n + 1):
        m = -8.0 + i * h
        w = (1 if i in (0, n) else (4 if i % 2 else 2)) * h / 3.0 * phi(m)
        dist = dist_at(m)
        for t, (_, A, D) in enumerate(TR):
            out[t] += w * sum(d * cut(k * LGD / NAMES, A, D) for k, d in enumerate(dist))
    return out

state = 20260928                             # road 4: Monte Carlo, own generator
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % (1 << 64)
    return ((state >> 11) + 0.5) / float(1 << 53)
def etl_montecarlo(p, rho, runs):
    c, tot = Ninv(p), [0.0] * len(TR)
    for _ in range(runs):
        q = N((c - sqrt(rho) * Ninv(unif())) / sqrt(1.0 - rho))
        L = sum(1 for _ in range(NAMES) if unif() < q) * LGD / NAMES
        for i, (_, A, D) in enumerate(TR): tot[i] += cut(L, A, D)
    return [t / runs for t in tot]

print(f"pool: {NAMES} names, 5y default chance {P5}, recovery {R}, correlation {RHO}")
print(f"threshold c = Ninv(0.05) {Ninv(P5):.6f}   sqrt(rho) {sqrt(RHO):.6f}   sqrt(1-rho) {sqrt(1 - RHO):.6f}")
print(f"pool expected loss (1-R) p               {LGD * P5:.6f}")
r1 = [etl_factor(P5, RHO, A, D) for _, A, D in TR]
r2 = [etl_losscurve(P5, RHO, A, D) for _, A, D in TR]
r3, r4 = etl_recursion(P5, RHO), etl_montecarlo(P5, RHO, 20000)
print("expected tranche loss, % of width      factor losscurve  100-name montecarlo")
for i, (nm, A, D) in enumerate(TR):
    print(f"  {nm:<19} {100 * r1[i]:9.4f} {100 * r2[i]:9.4f} {100 * r3[i]:9.4f} {100 * r4[i]:9.4f}")
print("economy m        z  default chance  pool loss %  equity %  jr mezz %  senior %")
for m in (-2.0, -1.0, 0.0, 1.0, 2.0):
    z = (Ninv(P5) - sqrt(RHO) * m) / sqrt(1.0 - RHO); q = N(z)
    print(f"  {m:5.1f} {z:9.4f} {q:14.6f} {100 * LGD * q:12.4f}" + "".join(f"{100 * cut(LGD * q, A, D):10.4f}" for _, A, D in TR if A != 0.07))
pool_back = sum(r1[i] * (D - A) for i, (_, A, D) in enumerate(TR))
print(f"sum of width x tranche loss              {pool_back:.6f}")
print("correlation sweep, % of width    equity   jr mezz   sr mezz    senior")
sweep = []
for rho in (0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8):
    sweep.append([etl_factor(P5, rho, A, D, 2000) for _, A, D in TR])
    print(f"  rho {rho:.1f}  " + "  ".join(f"{100 * v:8.2f}" for v in sweep[-1]))
print("payoff chart: pool loss %" + " ".join(f"{x:6d}" for x in range(0, 13)))
for nm, A, D in TR:
    print(f"  {nm:<22}" + " ".join(f"{100 * cut(x / 100, A, D):6.2f}" for x in range(0, 13)))

lam, r, dt = -log(1.0 - P5) / 5.0, 0.05, 0.25        # flat hazard; house rate 5%
print(f"hazard rate lambda = -ln(0.95)/5          {lam:.6f}")
print("tranche legs, quarterly, 5 years       protection  annuity  par spread bp")
prot_sum, ann_sum, legs = 0.0, 0.0, []
for nm, A, D in TR:
    prev, prot, ann = 0.0, 0.0, 0.0
    for i in range(1, 21):
        t = i * dt
        e = etl_factor(1.0 - exp(-lam * t), RHO, A, D, 400)
        prot += exp(-r * t) * (e - prev)                   # losses paid as they land
        ann += dt * exp(-r * t) * (1.0 - 0.5 * (prev + e)) # premium on what survives
        prev = e
    legs.append((prot, ann))
    prot_sum, ann_sum = prot_sum + prot * (D - A), ann_sum + ann * (D - A)
    print(f"  {nm:<19} {prot:12.6f} {ann:9.6f} {1e4 * prot / ann:12.1f}")
def pool_el(t): return LGD * (1.0 - exp(-lam * t))       # pool's own expected loss, no copula
idx_prot = sum(exp(-r * i * dt) * (pool_el(i * dt) - pool_el((i - 1) * dt)) for i in range(1, 21))
idx_ann = sum(dt * exp(-r * i * dt) * (1.0 - 0.5 * (pool_el((i - 1) * dt) + pool_el(i * dt))) for i in range(1, 21))
print(f"pool protection: tranches {prot_sum:.6f}   pool alone {idx_prot:.6f}")
print(f"pool annuity:    tranches {ann_sum:.6f}   pool alone {idx_ann:.6f}")
print(f"equity upfront % with 500 bp running      {100 * (legs[0][0] - 0.05 * legs[0][1]):.4f}")

print("what breaks, % of width                equity    senior")
print(f"  tranche of the average pool loss    {100 * cut(LGD * P5, 0, .03):9.4f} {100 * cut(LGD * P5, .1, 1):9.4f}")
print(f"  forgot recovery, lose 100%          {100 * etl_factor(P5, RHO, 0, .03, 2000, 1.0):9.4f} "
      f"{100 * etl_factor(P5, RHO, .1, 1, 2000, 1.0):9.4f}")
print(f"  divided by pool, not by width       {100 * r1[0] * 0.03:9.4f} {100 * r1[3] * 0.90:9.4f}")
print(f"  default corr 0.058 for asset 0.20   {100 * etl_factor(P5, 0.058, 0, .03):9.4f} "
      f"{100 * etl_factor(P5, 0.058, .1, 1):9.4f}")

assert all(abs(a - b) < 2e-5 for a, b in zip(r1, r2)),  "factor road vs loss-curve road"
assert abs(pool_back - LGD * P5) < 1e-6,                "tranches add back to the pool loss"
assert all(abs(a - b) < 0.01 for a, b in zip(r3, r4)),  "recursion vs Monte Carlo"
assert abs(prot_sum - idx_prot) < 1e-6,                 "tranche legs add to the pool leg"
assert abs(ann_sum - idx_ann) < 1e-6,                   "tranche annuities add to the pool annuity"
assert all(sweep[i + 1][0] < sweep[i][0] and sweep[i + 1][3] > sweep[i][3] for i in range(8)), \
    "equity falls and senior rises as correlation climbs"
print("ALL CHECKS PASS")
