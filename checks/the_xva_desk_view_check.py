# The XVA desk view -- the check behind the card.  Standard library only.
# One Acme call (S = K = 100, r 5%, q 2%, vol 20%, 1 year) bought from Northwind
# (hazard 2%, recovery 40%), uncollateralised; then the same call cleared.
# Road 1: closed forms on the exposure annuity.  Road 2: 52 weekly buckets, each
# week's exposure found by integrating the call's value over Acme's price (Simpson).
# Margin: the 99% ten-day move by bisection, and again by simulation.
from math import exp, log, sqrt, pi, cos

S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
lam, R, sF, hurdle, kcap = 0.02, 0.40, 0.01, 0.10, 0.08 * 1.00 * 1.4   # 8% of a 100% weight on 1.4 x exposure
sIM, hday, fdf = 0.005, 10.0 / 252.0, 0.10                              # margin spread, ten days, fund share of IM

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def ncdf(x):                                  # 1/2 + phi(x) (x + x^3/3 + x^5/(3*5) + ...)
    if x > 10.0: return 1.0
    if x < -10.0: return 0.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1; term *= x * x / (2 * n + 1); total += term
    return 0.5 + phi(x) * total
def call(S, t, rr=r):                         # Black-Scholes value with t years left
    if t <= 0: return max(S - K, 0.0)
    v = sig * sqrt(t); d1 = (log(S / K) + (rr - q + 0.5 * sig * sig) * t) / v
    return S * exp(-q * t) * ncdf(d1) - K * exp(-rr * t) * ncdf(d1 - v)
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def dee(t, m=800):                            # discounted expected exposure at t, by brute force
    g = lambda z: call(S0 * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * z), T - t) * phi(z)
    return exp(-r * t) * simpson(g, -8.0, 8.0, m)
def Q(t, h=lam): return exp(-h * t)          # survival chance to t

# ---- road 1: every charge is a rate times one exposure annuity ----
C0 = call(S0, T)
AE1 = C0 * (1 - exp(-lam * T)) / lam          # D(t)EE(t) is flat at C0 for a bought option
cva1, fva1, kva1 = (1 - R) * lam * AE1, sF * AE1, hurdle * kcap * AE1
V1 = C0 - cva1 + 0.0 - fva1 - 0.0 - kva1
# ---- road 2: 52 weekly buckets, exposure integrated week by week ----
n, dt = 52, T / 52
wk = [dee((i + 0.5) * dt) for i in range(n)]
cva2 = (1 - R) * sum(w * (Q(i * dt) - Q((i + 1) * dt)) for i, w in enumerate(wk))
AE2 = sum(w * Q((i + 0.5) * dt) * dt for i, w in enumerate(wk))
fva2, kva2 = sF * AE2, hurdle * kcap * AE2
V2 = C0 - cva2 - fva2 - kva2
C0int = dee(T, 20000)                          # the clean price itself, as a payoff average

# ---- cleared: initial margin, MVA, default-fund contribution ----
d1 = (log(S0 / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
delta = exp(-q * T) * ncdf(d1)
lo, hi = 0.0, 5.0
for _ in range(60):                           # bisection: N(z) = 0.99
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if ncdf(mid) < 0.99 else (lo, mid)
z99 = 0.5 * (lo + hi)
IM1 = delta * S0 * sig * sqrt(hday) * z99
state = 88172645463325252
def unif():                                   # xorshift64, then scale to (0, 1)
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7
    state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
zs = sorted(sqrt(-2 * log(unif())) * cos(2 * pi * unif()) for _ in range(200000))
zmc = -zs[1999]                                # 1% of 200,000 draws lie below minus this
dfd = (call(S0 + 0.01, T) - call(S0 - 0.01, T)) / 0.02     # delta by bumping Acme a cent
IM1b = dfd * S0 * sig * sqrt(hday) * zmc       # delta-normal margin, second road
Sdn = S0 * exp((r - q - 0.5 * sig * sig) * hday + sig * sqrt(hday) * -zmc)
IM2 = C0 - call(Sdn, T - hday)                 # full revaluation after the bad ten days
mva = sIM * IM1 * T
dfund = fdf * IM1
dfc = hurdle * dfund * T
Vclr = C0 - mva - dfc

# ---- the overlap: the mirror trade, bank sells the call, own spread 100 bp ----
lamB = sF / (1 - R)
dva1 = (1 - R) * C0 * (1 - exp(-lamB * T))
fba1 = sF * C0 * (1 - exp(-lamB * T)) / lamB
dva2 = (1 - R) * sum(w * (Q(i * dt, lamB) - Q((i + 1) * dt, lamB)) for i, w in enumerate(wk))
fba2 = sF * sum(w * Q((i + 0.5) * dt, lamB) * dt for i, w in enumerate(wk))
dva200 = (1 - R) * C0 * (1 - exp(-0.02 / (1 - R) * T))

rows = [
    ("clean price, formula", C0), ("clean price, payoff integral", C0int),
    ("exposure annuity A_E, road 1", AE1), ("exposure annuity A_E, road 2", AE2),
    ("CVA, road 1", cva1), ("CVA, road 2", cva2), ("FVA, road 1", fva1), ("FVA, road 2", fva2),
    ("KVA, road 1", kva1), ("KVA, road 2", kva2),
    ("bilateral charges, total", cva1 + fva1 + kva1),
    ("adjusted price, road 1", V1), ("adjusted price, road 2", V2),
    ("z99 by bisection", z99), ("z99 by simulation", zmc), ("delta", delta), ("delta by bump", dfd),
    ("IM, delta-normal", IM1), ("IM, delta-normal, simulated", IM1b), ("IM, full revaluation", IM2),
    ("MVA", mva), ("default-fund contribution", dfund), ("default-fund cost", dfc),
    ("cleared charges, total", mva + dfc), ("cleared price", Vclr),
    ("cleared minus bilateral", Vclr - V1),
    ("mirror: bank hazard", lamB), ("mirror: DVA, road 1", dva1), ("mirror: FBA, road 1", fba1),
    ("mirror: DVA, road 2", dva2), ("mirror: FBA, road 2", fba2),
    ("mirror: DVA + FBA, double counted", dva1 + fba1),
    ("mirror: DVA at 200 bp own spread", dva200), ("mirror: DVA gain, 100 -> 200 bp", dva200 - dva1),
    ("wrong: Black-Scholes at 6% funding", call(S0, T, 0.06)),
    ("wrong: no survival weighting", C0 - ((1 - R) * lam + sF + hurdle * kcap) * C0 * T),
    ("try: FVA at 200 bp", 0.02 * AE1), ("try: cleared charges, fund share 20%", mva + hurdle * 0.20 * IM1 * T),
]
for name, v in rows:
    print(f"{name:<36} {v:>12.6f}")
print()
print("chart, hazard %      " + " ".join(f"{h:6d}" for h in range(11)))
line = []
for h in range(11):
    lm = h / 100.0
    A = C0 * T if h == 0 else C0 * (1 - exp(-lm * T)) / lm
    line.append(100 * ((1 - R) * lm + sF + hurdle * kcap) * A)
print("chart, bilateral c   " + " ".join(f"{v:6.2f}" for v in line))
print("chart, cleared c     " + " ".join(f"{100 * (mva + dfc):6.2f}" for _ in range(11)))

assert abs(C0int - C0) < 1e-6, "payoff integral must land on the formula"
assert abs(AE2 - AE1) < 1e-5, "weekly exposures must rebuild the closed-form annuity"
assert abs(V2 - V1) < 1e-5, "bucket road and closed-form road must agree on the adjusted price"
assert abs(dva2 - fba2) < 1e-6 and abs(dva2 - dva1) < 1e-5, "DVA and FBA are one amount when spread = (1-R) x hazard"
assert abs(IM1b - IM1) < 0.03, "simulated delta-normal margin near the bisection one"
assert 0 < IM2 < IM1, "curvature cushions a bought call: full revaluation loses less than delta says"
assert abs(line[2] / 100 - (C0 - V2)) < 1e-5, "chart at a 2% hazard must equal the bucket road's charges"
assert abs(mva - 0.027) < 5e-4 and abs(IM1 - 5.4) < 0.05, "margin and MVA must land on the house example"
print("ALL CHECKS PASS")
