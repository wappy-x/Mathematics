# Nth-to-default baskets -- the check behind the card.  Standard library only.
# Five names, hazard 2% each, recovery 40%, five years, riskless rate 5%, quarterly premiums.
# Nothing imported knows the answer: the normal curve is a series written here, its inverse
# is bisection, integrals are Simpson's rule, random numbers come from a hand-written splitmix64.
from math import sqrt, exp, log, cos, sin, pi
LAM, R, T, RATE, DT, NAMES = 0.02, 0.40, 5.0, 0.05, 0.25, 5
DATES = [DT * j for j in range(1, 21)]

def N(x):                         # bell-curve area left of x: erf from its all-positive series
    z = abs(x) / sqrt(2.0)
    if z > 6.0: return 0.0 if x < 0 else 1.0
    term, s, n = z, z, 0
    while term > 1e-17 * s:
        n += 1; term *= 2.0 * z * z / (2 * n + 1); s += term
    erf = 2.0 / sqrt(pi) * exp(-z * z) * s
    return 0.5 * (1.0 - erf) if x < 0 else 0.5 * (1.0 + erf)

def Ninv(p):                      # the point with area p to its left, by bisection
    lo, hi = -10.0, 10.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)

def simpson(f, a, b, m):
    h = (b - a) / m
    return h / 3.0 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(a + i * h) for i in range(m + 1))

def count_law(q, nn):             # chance of 0..nn defaults when each name fails with chance q, independently
    law = [1.0] + [0.0] * nn
    for _ in range(nn):
        law = [law[j] * (1 - q) + (law[j - 1] * q if j else 0.0) for j in range(nn + 1)]
    return law

def survival(t, rho, lam=LAM, nn=NAMES, fix=True):
    # Q_k(t) = chance that fewer than k names have defaulted by t, for k = 1..nn
    if t == 0.0: return [1.0] * nn
    p = 1.0 - exp(-lam * t)
    if rho == 0.0: law = count_law(p, nn)
    elif rho == 1.0: law = [1.0 - p] + [0.0] * (nn - 1) + [p]        # all default at the same moment
    else:
        c, w = Ninv(p), (sqrt(1.0 - rho) if fix else 1.0)          # fix=False drops the sqrt(1-rho) weight
        law = [0.0] * (nn + 1)
        for i in range(401):                                        # Simpson over the economy score m
            m = -8.0 + i * 0.04
            wt = (1 if i in (0, 400) else 4 if i % 2 else 2) * 0.04 / 3.0 * exp(-m * m / 2) / sqrt(2 * pi)
            for j, v in enumerate(count_law(N((c - sqrt(rho) * m) / w), nn)): law[j] += wt * v
    out, acc = [], 0.0
    for j in range(nn): acc += law[j]; out.append(acc)
    return out

def legs(rho, lam=LAM, nn=NAMES, rec=R, fix=True):
    # Road 2: each kth default time is a synthetic name; price it with the CDS legs of its survival curve
    A = [sum(DT * exp(-RATE * t) * survival(t, rho, lam, nn, fix)[k] for t in DATES) for k in range(nn)]
    grid = {i: survival(T * i / 100, rho, lam, nn, fix) for i in range(101)}
    P = [(1 - rec) * (exp(-RATE * T) * (1 - grid[100][k])          # protection, integrated by parts
          + RATE * simpson(lambda t: exp(-RATE * t) * (1 - grid[round(t * 20)][k]), 0.0, T, 100)) for k in range(nn)]
    return A, P, [1e4 * P[k] / A[k] for k in range(nn)]

def flat_cds(lam):                # Road 1: the closed-form legs for one flat hazard
    c = RATE + lam; x = exp(-c * DT)
    A = DT * x * (1 - x ** 20) / (1 - x); P = (1 - R) * lam * (1 - exp(-c * T)) / c
    return A, P, 1e4 * P / A

STATE = [20261123]
def uniform():                    # splitmix64, then 53 random bits
    STATE[0] = (STATE[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = STATE[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def simulate(rho, paths=200000):  # Road 3: draw five default dates per basket, sort, settle
    cT = Ninv(1 - exp(-LAM * T)); S = [[0.0] * 5, [0.0] * 5]   # sums of a, v, a*a, a*v, v*v
    for _ in range(paths):
        g = []
        for _ in range(3):
            u1, u2 = 1.0 - uniform(), uniform(); rr = sqrt(-2 * log(u1))
            g += [rr * cos(2 * pi * u2), rr * sin(2 * pi * u2)]
        X = [sqrt(rho) * g[0] + sqrt(1 - rho) * e for e in g[1:]]
        taus = sorted(-log(N(-x)) / LAM for x in X if x < cT)   # dates inside five years only
        for k in range(2):
            tk = taus[k] if len(taus) > k else 99.0
            a = sum(DT * exp(-RATE * t) for t in DATES if t < tk)   # premium leg a, protection v
            v = (1 - R) * exp(-RATE * tk) if tk <= T else 0.0
            for j, z in enumerate((a, v, a * a, a * v, v * v)): S[k][j] += z
    out = []
    for k in range(2):   # the premium is a ratio of two averages: its error uses v - s*a, both legs random
        A, P, aa, av, vv = (z / paths for z in S[k]); s = P / A
        out.append((1e4 * s, 1e4 * sqrt((vv - 2 * s * av + s * s * aa) / paths) / A))
    return out

A1, P1, s1 = flat_cds(LAM)
print(f"single name: annuity {A1:.6f}  protection {P1:.6f}  spread {s1:.2f} bp")
assert abs(s1 - 121.06) < 0.005
Af, Pf, sf = flat_cds(NAMES * LAM)
print(f"independent first-to-default hazard {NAMES * LAM:.2%}: five-year survival {exp(-NAMES * LAM * T):.6f} = {exp(-LAM * T):.6f}^5")
print(f"independent FTD legs: x {exp(-(RATE + NAMES * LAM) * DT):.6f}  annuity {Af:.6f}  protection {Pf:.6f}")
L0, L3, L1 = legs(0.0), legs(0.3), legs(1.0)
print(f"rho 0.3 legs: FTD annuity {L3[0][0]:.6f} protection {L3[1][0]:.6f}  2TD annuity {L3[0][1]:.6f} protection {L3[1][1]:.6f}")
p5 = 1 - exp(-LAM * T); c5 = Ninv(p5)
print(f"rho 0.3 year 5: cutoff {c5:.4f}  weights {sqrt(0.3):.4f} {sqrt(0.7):.4f}  economies with q below 25% {1 - N((c5 - sqrt(0.7) * Ninv(0.25)) / sqrt(0.3)):.2%}")
for m in (-2, 0, 2):
    q = N((c5 - sqrt(0.3) * m) / sqrt(0.7)); law = count_law(q, NAMES)
    print(f"  economy {m:+d}: each name {q:.2%}  at least one {1 - law[0]:.2%}  at least two {1 - law[0] - law[1]:.2%}")
sim0, sim3 = simulate(0.0), simulate(0.3)
print(f"rho 0.0  FTD  closed form {sf:.2f}  curve road {L0[2][0]:.2f}  simulation {sim0[0][0]:.2f} +- {sim0[0][1]:.2f} bp")
print(f"rho 0.0  2TD  binomial curve {L0[2][1]:.2f}  simulation {sim0[1][0]:.2f} +- {sim0[1][1]:.2f} bp")
print(f"rho 0.3  FTD  copula integral {L3[2][0]:.2f}  simulation {sim3[0][0]:.2f} +- {sim3[0][1]:.2f} bp")
print(f"rho 0.3  2TD  copula integral {L3[2][1]:.2f}  simulation {sim3[1][0]:.2f} +- {sim3[1][1]:.2f} bp")
print(f"rho 1.0  FTD {L1[2][0]:.2f}  2TD {L1[2][1]:.2f} bp  (single name {s1:.2f})")
assert abs(L0[2][0] - sf) < 0.02 and abs(L1[2][0] - s1) < 0.02 and abs(L1[2][1] - s1) < 0.02
for (s, e), ref in zip(sim0 + sim3, [L0[2][0], L0[2][1], L3[2][0], L3[2][1]]):
    assert abs(s - ref) < 4 * e, (s, ref, e)
for rho in (0.0, 0.3, 1.0):
    S = survival(T, rho); assert p5 - 1e-12 < 1 - S[0] < NAMES * p5   # riskiest name <= any default <= sum
    print(f"rho {rho:.1f}  by year 5: no default {S[0]:.2%}  at least one {1 - S[0]:.2%}  at least two {1 - S[1]:.2%}")
print(f"at least one default by year 5, any dependence: from {p5:.2%} to {NAMES * p5:.2%}")
print(f"ladder at rho 0.3, k = 1..5: " + "  ".join(f"{s:.2f}" for s in L3[2]) + " bp")
for rho, L in ((0.0, L0), (0.3, L3), (1.0, L1)):
    print(f"sum of the five protection legs at rho {rho:.1f}: {sum(L[1]):.6f}  five single names {NAMES * P1:.6f}")
    assert abs(sum(L[1]) - NAMES * P1) < 1e-5
print("sweep: rho, FTD bp, 2TD bp")
sweep = {}
for i in range(11):
    rho = i / 10; sweep[rho] = legs(rho)[2][:2]
    print(f"  {rho:.1f}  {sweep[rho][0]:7.2f}  {sweep[rho][1]:7.2f}")
ftd = [sweep[i / 10][0] for i in range(11)]
assert all(a > b for a, b in zip(ftd, ftd[1:])), "FTD falls at every step"
peak = max(range(11), key=lambda i: sweep[i / 10][1])
print(f"2TD peaks on the grid at rho {peak / 10:.1f}: {sweep[peak / 10][1]:.2f} bp, then falls back to {s1:.2f}")
assert 0.0 < peak / 10 < 1.0 and sweep[0.3][1] > sweep[0.0][1]
print(f"dollars on $10m, per quarter: FTD rho 0 {sf * 250:,.0f}  rho 0.3 {L3[2][0] * 250:,.0f}  single {s1 * 250:,.0f}")
print(f"break: add the five single spreads {NAMES * s1:.2f}  treat as independent {sf:.2f}  vs {L3[2][0]:.2f}")
print(f"break: premiums for all five years {1e4 * L3[1][0] / sum(DT * exp(-RATE * t) for t in DATES):.2f}  drop sqrt(1-rho) {legs(0.3, fix=False)[2][0]:.2f}")
j2 = 1 - survival(T, 0.3, nn=2)[1]; dc = (j2 - p5 * p5) / (p5 * (1 - p5))   # both of two names default by year 5
print(f"trap: default correlation by year 5 at rho 0.3 {dc:.4f}; used as rho it gives FTD {legs(dc)[2][0]:.2f}")
print(f"try: recovery 20% {legs(0.3, rec=0.2)[2][0]:.2f}  ten names {legs(0.3, nn=10)[2][0]:.2f}"
      f"  hazard 1% {legs(0.3, lam=0.01)[2][0]:.2f}  rho 0.6 FTD {legs(0.6)[2][0]:.2f} 2TD {legs(0.6)[2][1]:.2f}")
print("ALL CHECKS PASS")
