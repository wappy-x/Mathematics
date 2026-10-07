# Expected exposure profiles -- the check behind the card.  Standard library only.
# The Acme call bought from Northwind, then a five-year swap with Northwind.
# Nothing imported knows the answer: the normal CDF is Marsaglia's series, the
# quantile is bisection, the integrals are Simpson's rule, the random numbers
# are splitmix64 plus Box-Muller, all written out below.
from math import exp, log, sqrt, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                                         # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total
def inv_N(p):                                                     # the z with N(z) = p, by bisection
    lo, hi = -9.0, 9.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if N(mid) < p: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3.0

S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0        # the house market
def call(s, tau):                                                 # Black-Scholes value, tau years left
    if tau <= 0.0: return max(s - K, 0.0)
    v = sig * sqrt(tau)
    d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * tau) / v
    return s * exp(-q * tau) * N(d1) - K * exp(-r * tau) * N(d1 - v)
def s_at(u, z, mu=r):                                             # Acme at date u; mu = total expected return
    return S0 * exp((mu - q - 0.5 * sig * sig) * u + sig * sqrt(u) * z)
def ee_integral(u, power=1):                                      # road 2: average the revalued call over the bell curve
    return simpson(lambda z: call(s_at(u, z), T - u) ** power * phi(z), -8.0, 8.0, 4000)

M64 = (1 << 64) - 1
seed = [2026]
def rand():                                                       # splitmix64 -> uniform strictly inside (0, 1)
    seed[0] = (seed[0] + 0x9E3779B97F4A7C15) & M64
    z = seed[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def gauss():
    a = rand(); b = rand()
    return sqrt(-2.0 * log(a)) * cos(2.0 * pi * b)
def mc_profile(dates, step, value, x0, n=40000):                  # road 3: simulate paths, revalue at each date
    cols = [[] for _ in dates]
    for _ in range(n):
        x, t = x0, 0.0
        for j, u in enumerate(dates):
            x = step(x, u - t, gauss()); t = u
            cols[j].append(max(value(x, u), 0.0))
    out = []
    for c in cols:
        c.sort()
        out.append((sum(c) / n, c[-(-95 * n // 100) - 1]))        # mean, and the ceil(0.95 n)-th smallest
    return out

C0 = call(S0, T)
z95 = inv_N(0.95)
dates = [0.25, 0.5, 0.75, 1.0]
mc = mc_profile(dates, lambda s, dt, z: s * exp((r - q - 0.5 * sig * sig) * dt + sig * sqrt(dt) * z),
                lambda s, u: call(s, T - u), S0)
print("Acme call bought from Northwind, profile by date (years)")
print(f"{'u':>5}{'EE formula':>11}{'EE integral':>12}{'EE sim':>9}{'disc EE':>9}{'PFE95':>9}{'PFE95 sim':>10}")
ee_int, rows = [C0], []
for (u, (m, p)) in zip(dates, mc):
    e = ee_integral(u); ee_int.append(e)
    pfe = call(s_at(u, z95), T - u)
    rows.append((u, e, m, p, pfe))
    print(f"{u:5.2f}{C0 * exp(r * u):11.4f}{e:12.4f}{m:9.4f}{e * exp(-r * u):9.4f}{pfe:9.4f}{p:10.4f}")
u = 0.5; sq = s_at(u, z95); v = sig * sqrt(u)
d1 = (log(sq / K) + (r - q + 0.5 * sig * sig) * u) / v
sd = sqrt(ee_integral(u, 2) - ee_integral(u) ** 2)
sp = s_at(u, z95, 0.08)
wts = [1, 4, 2, 4, 1]                                             # Simpson over the five integral-road dates
epe = sum(w * e for w, e in zip(wts, ee_int)) * 0.25 / 3.0
epe_closed = C0 * (exp(r) - 1.0) / r
lam, R = 0.02, 0.40                                                # Northwind: hazard 2% a year, recovery 40%
cva = (1 - R) * sum(w * lam * exp(-(lam + r) * t) * e for w, t, e in zip(wts, [0.0] + dates, ee_int)) * 0.25 / 3.0
cva_closed = (1 - R) * C0 * (1.0 - exp(-lam))
for name, x in [("call today C0", C0), ("z95", z95), ("six months: e^(r u)", exp(r * u)), ("  e^(-r u)", exp(-r * u)),
                ("  drift (r - q - sig^2/2) u", (r - q - 0.5 * sig * sig) * u), ("  sig sqrt(u)", v),
                ("  Acme at 95%", sq), ("  d1", d1), ("  d2", d1 - v),
                ("  N(d1)", N(d1)), ("  N(d2)", N(d1 - v)), ("  share half", sq * exp(-q * u) * N(d1)),
                ("  cash half", K * exp(-r * u) * N(d1 - v)), ("  PFE95 = call there", call(sq, T - u)),
                ("  intrinsic only S - K", sq - K), ("  sd of call value", sd),
                ("  mean + 1.645 sd", ee_int[2] + z95 * sd), ("  real world 8%: Acme", sp),
                ("  real world 8%: PFE95", call(sp, T - u)), ("EPE year one, Simpson", epe),
                ("EPE year one, closed", epe_closed), ("CVA from flat disc EE", cva), ("  closed 0.6 C0 (1-e^-0.02)", cva_closed),
                ("  risky price", C0 - cva_closed)]:
    print(f"{name:<30}{x:12.4f}")

r0, sn, cpn = 0.05, 0.01, exp(0.05) - 1.0                          # par swap: flat 5%, rate spread 1% a year
def swap(x, k):                                                   # receiver, $100 notional, after year-k payment
    m = 5 - int(round(k))
    return 100.0 * (cpn * sum(exp(-x * j) for j in range(1, m + 1)) + exp(-x * m) - 1.0)
years = [1.0, 2.0, 3.0, 4.0, 5.0]
smc = mc_profile(years, lambda x, dt, z: x + sn * sqrt(dt) * z, swap, r0)
print("Five-year receiver swap with Northwind, $100 notional, after each payment")
print(f"{'year':>5}{'EE integral':>12}{'EE sim':>9}{'PFE95':>9}{'PFE95 sim':>10}{'(mean V)+':>10}")
sw = []
for (k, (m, p)) in zip(years, smc):
    e = simpson(lambda z: swap(r0 + sn * sqrt(k) * z, k) * phi(z), -8.0, 0.0, 2000)    # V > 0 only when rates fall
    mean_v = simpson(lambda z: swap(r0 + sn * sqrt(k) * z, k) * phi(z), -8.0, 8.0, 4000)
    pfe = swap(r0 - sn * sqrt(k) * z95, k)
    sw.append((e, m, pfe, p))
    print(f"{k:5.0f}{e:12.4f}{m:9.4f}{pfe:9.4f}{p:10.4f}{max(mean_v, 0.0):10.4f}")
for name, x in [("swap par coupon, percent", 100.0 * cpn), ("year 2: rate spread, percent", 100.0 * sn * sqrt(2.0)),
                ("year 2: rate at the 5% tail, percent", 100.0 * (r0 - sn * sqrt(2.0) * z95))]:
    print(f"{name:<38}{x:9.4f}")
print("chart, call EE " + " ".join(f"{x:.2f}" for x in [C0] + [C0 * exp(r * u) for u in dates]))
print("chart, call disc EE " + " ".join(f"{x * exp(-r * u):.2f}" for x, u in zip(ee_int, [0.0] + dates)))
print("chart, call PFE " + " ".join(f"{x:.2f}" for x in [C0] + [t[4] for t in rows]))
print("chart, swap EE 0.00 " + " ".join(f"{t[0]:.2f}" for t in sw))
print("chart, swap PFE 0.00 " + " ".join(f"{t[2]:.2f}" for t in sw))

for (u, e, m, p, pfe) in rows:
    assert abs(e - C0 * exp(r * u)) < 1e-4, "integral road must land on C0 e^(ru)"
    assert abs(m - e) < 0.15, "simulated EE within about three standard errors"
    assert abs(p - pfe) < 0.5, "simulated 95% quantile near the quantile formula"
assert abs(epe - epe_closed) < 1e-4, "EPE from the integral road vs the closed form"
assert abs(cva - cva_closed) < 1e-5, "CVA from the integral road vs the closed form"
for (e, m, pfe, p) in sw[:4]:
    assert abs(m - e) < 0.06, "swap: simulated EE agrees with the integral"
    assert abs(p - pfe) < 0.25, "swap: simulated 95% quantile agrees with the quantile formula"
assert sw[1][0] > sw[0][0], "the swap's EE rises first"
assert sw[1][0] > sw[3][0], "then falls: a hump"
print("ALL CHECKS PASS")
