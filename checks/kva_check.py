# KVA on the Acme call bought from Northwind: capital cost over the trade's life.
# Standard library only. The bell-curve area, its inverse, the integrator and the
# random numbers are all written here; nothing imported knows the answer.
from math import exp, log, sqrt, pi, cos

def N(x):                                   # bell-curve area left of x, positive-term erf series
    if x > 12.0: return 1.0
    if x < -12.0: return 0.0
    z = abs(x) / sqrt(2.0)
    term, total, n = z, z, 0
    while term > 1e-17 * total:
        n += 1
        term *= 2.0 * z * z / (2 * n + 1)
        total += term
    half = exp(-z * z) * total / sqrt(pi)   # erf(z) / 2
    return 0.5 + half if x >= 0 else 0.5 - half

def N_inv(u):                               # bisection root finder on N
    lo, hi = -12.0, 12.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < u else (lo, mid)
    return 0.5 * (lo + hi)

S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
lam, R = 0.02, 0.40                         # Northwind's hazard and recovery
h, alpha, ratio, rw = 0.10, 1.4, 0.08, 1.00 # hurdle, EAD multiplier, capital ratio, risk weight
c = ratio * rw * alpha                      # capital per $1 of exposure: 0.112

def call(S, tau):
    if tau <= 0.0: return max(S - K, 0.0)
    v = sig * sqrt(tau)
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * tau) / v
    return S * exp(-q * tau) * N(d1) - K * exp(-r * tau) * N(d1 - v)

def addon(S, tau):                          # SA-CCR add-on for one bought equity call, unmargined
    m = max(tau, 10.0 / 250.0)              # maturity factor's input, floored at 10 business days
    if tau <= 0.0: d = 40.0 if S > K else -40.0                # delta at expiry: 1 or 0
    else: d = (log(S / K) + 0.72 * tau) / (1.2 * sqrt(tau))    # delta: time to expiry, vol 120%
    return 0.32 * N(d) * S * sqrt(min(m, 1.0))                 # supervisory factor 32%

def S_at(t, z): return S0 * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * z)

def avg(f, t, n=200):                       # Simpson over the bell curve of Acme's price at t
    if t == 0.0: return f(S0, T)
    a, w = -8.0, 16.0 / n
    tot = 0.0
    for i in range(n + 1):
        z = a + i * w
        wt = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += wt * f(S_at(t, z), T - t) * exp(-0.5 * z * z)
    return tot * w / 3.0 / sqrt(2.0 * pi)

C0 = call(S0, T)
cva = (1 - R) * C0 * (1 - exp(-lam * T))
life = (1 - exp(-lam * T)) / lam            # integral of survival over the year
kva_closed = h * c * C0 * life              # road 1: the flat discounted exposure collapses it

# road 2: 52 weekly buckets, expected capital at each midpoint by Simpson
kva_wk = kva_wk_rh = kva_sa = 0.0
for i in range(52):
    t, dt = (i + 0.5) / 52.0, 1.0 / 52.0
    ee = avg(call, t)
    ea = avg(addon, t)
    w = h * exp(-(r + lam) * t) * dt
    kva_wk += w * c * ee
    kva_wk_rh += w * c * ee * exp(-h * t)   # variant: discount the cost at r + h
    kva_sa += w * c * (ee + ea)

# road 3: Monte Carlo, a uniform date and a price on that date, splitmix64 + Box-Muller
state = 20260928
def U():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((x ^ (x >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
M = 100000
s1 = s2 = sa1 = sa2 = 0.0
for _ in range(M):
    t = U() * T
    z = sqrt(-2.0 * log(U())) * cos(2.0 * pi * U())
    S = S_at(t, z)
    base = h * exp(-(r + lam) * t) * T * c
    x, y = base * call(S, T - t), base * (call(S, T - t) + addon(S, T - t))
    s1 += x; s2 += x * x; sa1 += y; sa2 += y * y
kva_mc, kva_mc_sa = s1 / M, sa1 / M
se = sqrt((s2 / M - kva_mc ** 2) / M)
se_sa = sqrt((sa2 / M - kva_mc_sa ** 2) / M)

# the refined route: Basel IRB capital per $1 for Northwind (PD 2%, LGD 60%, M = 1)
pd, lgd = 0.02, 0.60
wgt = (1 - exp(-50 * pd)) / (1 - exp(-50))
rho = 0.12 * wgt + 0.24 * (1 - wgt)
x999 = N((N_inv(pd) + sqrt(rho) * N_inv(0.999)) / sqrt(1 - rho))
k_irb = lgd * (x999 - pd)
kva_irb = h * alpha * k_irb * C0 * life

rows = [
    ("clean call C0", C0), ("CVA, Northwind 2%, R 40%", cva),
    ("capital per $ of exposure c", c), ("EAD today 1.4 x C0", alpha * C0),
    ("capital today 0.112 x C0", c * C0), ("survival integral", life),
    ("1 KVA closed form", kva_closed), ("2 KVA 52 weekly buckets", kva_wk),
    ("3 KVA Monte Carlo", kva_mc), ("  MC standard error", se),
    ("KVA / CVA", kva_closed / cva), ("running rate, CVA (1-R) lam", (1 - R) * lam),
    ("running rate, KVA h c", h * c), ("Northwind 1-year default", 1 - exp(-lam)),
    ("IRB correlation", rho), ("IRB 99.9% default rate", x999),
    ("IRB capital per $ of EAD", k_irb), ("IRB risk weight", 12.5 * k_irb),
    ("rule: simple 8% x 100%", kva_closed), ("rule: IRB", kva_irb),
    ("rule: SA-CCR, weekly", kva_sa), ("rule: SA-CCR, Monte Carlo", kva_mc_sa),
    ("  MC standard error", se_sa), ("SA-CCR add-on today", addon(S0, T)),
    ("SA-CCR EAD today", alpha * (C0 + addon(S0, T))),
    ("hurdle 8%", 0.08 / h * kva_closed), ("hurdle 12%", 0.12 / h * kva_closed),
    ("charge h - r = 5%", (h - r) / h * kva_closed),
    ("discount at r + h, weekly", kva_wk_rh),
    ("discount at r + h, closed", h * c * C0 * (1 - exp(-(lam + h))) / (lam + h)),
    ("capital frozen at today's", h * c * C0 * (1 - exp(-(r + lam))) / (r + lam)),
    ("wrong: no survival", h * c * C0 * T), ("wrong: no alpha", h * ratio * C0 * life),
    ("wrong: no discount", h * c * C0 * (exp((r - lam) * T) - 1) / (r - lam)),
    ("wrong: hurdle on EAD itself", h * alpha * C0 * life), ("KVA + CVA", kva_closed + cva),
    ("try: hurdle 15%", 0.15 / h * kva_closed), ("try: risk weight 20%", 0.20 * kva_closed),
    ("try: hazard 10%, KVA", h * c * C0 * (1 - exp(-0.1)) / 0.1),
    ("try: hazard 10%, CVA", (1 - R) * C0 * (1 - exp(-0.1))),
]
for name, v in rows:
    print(f"{name:<30} {v:>12.6f}")
print("chart, expected capital by month (t dollars)")
for mo in (0, 3, 6, 9, 12):
    t = mo / 12.0
    print(f"  month {mo:>2}  simple {c * avg(call, t, 2000):6.2f}  SA-CCR {c * (avg(call, t, 2000) + avg(addon, t, 2000)):6.2f}")

assert abs(kva_wk - kva_closed) < 1e-7,             "weekly Simpson sum vs closed form"
assert abs(kva_mc - kva_closed) < 4 * se,           "Monte Carlo vs closed form"
assert abs(kva_mc_sa - kva_sa) < 4 * se_sa,         "SA-CCR: Monte Carlo vs weekly sum"
assert abs(avg(call, T, 2000) - C0 * exp(r * T)) < 1e-4, "payoff averaged at expiry vs C0 grown at r"
assert abs(k_irb - 0.1022) < 5e-5,                  "IRB capital vs the Vasicek card's 10.22 per 100"
print("ALL CHECKS PASS")
