# FVA -- the check behind the card.  Standard library only.
# The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from Northwind with
# no collateral.  The bank funds at 100 bp over the collateral rate r; Northwind's hazard is
# 2% a year, the bank's own 1%, recovery 40% each.  Nothing imported knows the answer: the
# normal CDF is a series, integrals are Simpson's rule, random numbers are splitmix64.
from math import exp, log, sqrt, pi, cos

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
SF, LC, RC, LO, RO = 0.01, 0.02, 0.40, 0.01, 0.40   # funding spread, hazards, recoveries

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)              # bell-curve height
def N(x):                                                           # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def bs(s, left, put=False):                                         # Acme option with `left` years to run
    if left <= 1e-12: return max(K - s, 0.0) if put else max(s - K, 0.0)
    v = sig * sqrt(left)
    d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * left) / v
    if put: return K * exp(-r * left) * N(v - d1) - s * exp(-q * left) * N(-d1)
    return s * exp(-q * left) * N(d1) - K * exp(-r * left) * N(d1 - v)

def simpson(f, a, b, n):                                            # area under f from a to b, n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def dee(t, need=lambda v: max(v, 0.0)):
    # discounted expected funding need D(t) E[need(V(t))], integrated over Acme's price at t
    drift, vol = (r - q - 0.5 * sig * sig) * t, sig * sqrt(t)
    lo = -8.0 if t < T else (log(K / S) - drift) / vol              # at expiry, start at the kink
    f = lambda z: need(bs(S * exp(drift + vol * z), T - t)) * phi(z)
    return exp(-r * t) * simpson(f, lo, 8.0, 2000)

Q = lambda t, lam=LC: exp(-lam * t)                                 # survival to t
C0, P0 = bs(S, T), bs(S, T, put=True)

fca_closed = SF * C0 * (1.0 - Q(T)) / LC                            # road 1: flat exposure, integrated
weekly = [SF * dee((i + 0.5) / 52) * (Q(i / 52) - Q((i + 1) / 52)) / LC for i in range(52)]
fca_52 = sum(weekly)                                                # road 2: 52 weekly buckets

state = 20260928                                                    # road 3: simulation
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
def acme_at(t):
    z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
    return S * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * z)
def mean_se(xs):
    m = sum(xs) / len(xs)
    return m, sqrt((sum(x * x for x in xs) / len(xs) - m * m) / len(xs))
M = 400000
draws = []
for _ in range(M):                          # a date u in the year, Acme at u, Northwind's default date
    u = uniform() * T
    s_u = acme_at(u)
    alive = -log(uniform()) / LC > u
    draws.append(SF * T * exp(-r * u) * bs(s_u, T - u) if alive else 0.0)
fca_mc, se_fca = mean_se(draws)

# the sold call: the bank holds Northwind's premium, a negative exposure worth C0 in today's money
fba = SF * simpson(lambda t: dee(t, lambda v: max(v, 0.0)) * Q(t), 0.0, T, 8)   # FBA on the sold call
fca_sold = SF * simpson(lambda t: dee(t, lambda v: max(-v, 0.0)) * Q(t), 0.0, T, 8)
s_credit = (1.0 - RO) * LO                                          # the part of the spread that is default
fba_credit = s_credit * C0 * (1.0 - Q(T)) / LC                      # weighted by Northwind's survival
fba_credit2 = s_credit * C0 * (1.0 - Q(T, LC + LO)) / (LC + LO)     # and by the bank's own as well
fba_liquid = (SF - s_credit) * C0 * (1.0 - Q(T)) / LC
pd_o = 1.0 - Q(T, LO)
draws = []
for _ in range(M):                          # DVA by simulation: the bank defaults first, owing V
    tau = -log(1.0 - uniform() * pd_o) / LO                         # bank's default date, given one in the year
    s_tau = acme_at(tau)
    first = -log(uniform()) / LC > tau
    draws.append((1.0 - RO) * pd_o * exp(-r * tau) * bs(s_tau, T - tau) if first else 0.0)
dva_mc, se_dva = mean_se(draws)
# collateralised twin: Step 1 says V(0) = E[D(T) X] at the collateral rate; simulate the payoff
dx_mc, se_dx = mean_se([exp(-r * T) * max(acme_at(T) - K, 0.0) for _ in range(M)])

C, Y, RS = 100000.0, 5, 0.02                                        # folded example: a bought cash stream
D = lambda t, rate=RS: exp(-rate * t)
stream_exact = sum(C * (D(k) - D(k, RS + SF)) for k in range(1, Y + 1))
stream_200 = sum(C * (D(k) - D(k, RS + 2 * SF)) for k in range(1, Y + 1))
stream_lin = SF * sum(k * C * D(k) for k in range(1, Y + 1))        # need at t = value of flows after t
n = 5000
stream_lin2 = SF * sum(sum(C * D(k) for k in range(1, Y + 1) if k > (j + 0.5) * Y / n) * Y / n for j in range(n))

rows = [
    ("clean call C0", C0), ("clean put P0", P0), ("funding spread s_F", SF),
    ("discount factor D(1)", exp(-r * T)), ("Northwind survival Q_C(1)", Q(T)),
    ("expected years alive (1-e^-lam T)/lam", (1.0 - Q(T)) / LC),
    ("1 closed form s C0 (1-e^-lam T)/lam", fca_closed), ("2 bucketed sum, 52 weeks", fca_52),
    ("3 simulated, 400000 draws", fca_mc), ("  standard error", se_fca),
    ("funded call C0 - FVA", C0 - fca_closed), ("collateral-rate value E[D(T)X], sim.", dx_mc), ("  standard error", se_dx), ("FCA at 200 bp", 2.0 * fca_52),
    ("sold call: FCA", fca_sold), ("sold call: FBA", fba),
    ("  credit part of spread (1-R_O)lam_O", s_credit), ("  FBA, credit part", fba_credit),
    ("  FBA, credit part, both survivals", fba_credit2),
    ("  FBA, liquidity part", fba_liquid), ("  bank DVA, simulated", dva_mc), ("  standard error", se_dva),
    ("wrong: no survival weight", SF * C0 * T), ("wrong: full funding rate r+s_F", (r + SF) * fca_52 / SF),
    ("wrong: funding-rate discount, collat.", C0 * (1.0 - exp(-SF * T))), ("wrong: FBA plus DVA", fba + fba_credit2),
    ("compounded, not linear", SF * C0 * (1.0 - Q(T, LC + SF)) / (LC + SF)),
    ("try: long put", SF * P0 * (1.0 - Q(T)) / LC), ("try: 5-year call", SF * bs(S, 5.0) * (1.0 - Q(5.0)) / LC),
    ("stream: FVA, discount at 3% vs 2%", stream_exact), ("stream: same at 200 bp", stream_200),
    ("stream: linear, closed form", stream_lin), ("stream: linear, integrated", stream_lin2),
    ("stream: integral of discounted need", stream_lin2 / SF), ("stream: linear minus exact", stream_lin - stream_exact),
]
for name, v in rows:
    print(f"{name:<38}{v:14.6f}")
print()
print("chart, quarter end    " + " ".join(f"{t:6.2f}" for t in (0.0, 0.25, 0.5, 0.75, 1.0)))
cum = [0.0] + [100 * sum(weekly[:13 * j]) for j in range(1, 5)]
print("chart, FCA cents 100bp" + " ".join(f"{c:6.2f}" for c in cum))
print("chart, FCA cents 200bp" + " ".join(f"{2 * c:6.2f}" for c in cum))
print("bars, cents: FBA credit, liquidity; credit both surv., DVA " + " ".join(f"{100 * x:.2f}" for x in (fba_credit, fba_liquid, fba_credit2, dva_mc)))

assert abs(C0 - 9.227005508154) < 1e-9, "own normal CDF reproduces the house call"
assert abs(fca_52 - fca_closed) < 1e-6, "weekly sum with integrated exposure matches the flat-exposure integral"
assert abs(fca_mc - fca_closed) < 4 * se_fca, "simulation within four standard errors"
assert abs(dva_mc - fba_credit2) < 4 * se_dva, "credit part of the FBA is the bank's DVA"
assert abs(dx_mc - C0) < 4 * se_dx, "collateralised twin: payoff discounted at r averages to C0"
assert abs(stream_lin2 - stream_lin) < 1e-6 * stream_lin, "stream: two roads to the linear FVA"
print("ALL CHECKS PASS")
