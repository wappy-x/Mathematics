# Forward measures for rates -- the check behind the card.  Standard library only.
# Caplet 7 of the shelf's 2-year cap: the 3-month rate fixed at 1.75 years, paid
# at 2.00 years, strike 5%, lognormal volatility 30%, notional $10,000,000.
# 1 Black's formula: the pay-date bond is the unit, the forward rate has no drift
# 2 Simpson quadrature of the payoff over that driftless lognormal law
# 3 Monte Carlo with the FIX-date bond as the unit: the forward now carries the
#   drift sigma^2 tau F / (1 + tau F), and the payoff is valued in fix-date bonds
# 4 martingale tests: what averages to its starting value under which unit
from math import exp, log, sqrt, cos, pi

TAU, K, SIG, T1, T2, NOTL = 0.25, 0.05, 0.30, 1.75, 2.0, 1e7
FWD = [0.044 + 0.0005 * i for i in range(8)]          # the shelf's quarterly forwards
D = [1.0]
for f in FWD:
    D.append(D[-1] / (1 + TAU * f))                   # discount factors, chained
F0, P1, P2 = FWD[7], D[7], D[8]                       # forward, fix-date bond, pay-date bond

def ncdf(x):                                          # bell-curve area left of x, by its series
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    term, s, n = x, x, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -x * x / (2 * n)
        s += term / (2 * n + 1)
    return 0.5 + s / sqrt(2 * pi)

def black(F, k, sig, t):                              # F N(d1) - k N(d2), per unit of rate
    v = sig * sqrt(t)
    d1 = (log(F / k) + v * v / 2) / v
    return F * ncdf(d1) - k * ncdf(d1 - v)

def quad(g, t=T1, n=40000):                            # E[g(F(t))], F driftless lognormal
    v, a, h = SIG * sqrt(t), -10.0, 20.0 / n
    tot = 0.0
    for i in range(n + 1):
        z = a + i * h
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += w * g(F0 * exp(v * z - v * v / 2)) * exp(-z * z / 2) / sqrt(2 * pi)
    return tot * h / 3

state = 88172645463325252                             # 64-bit LCG, then Box-Muller
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
def gauss():
    u1 = unif()
    return sqrt(-2 * log(u1)) * cos(2 * pi * unif())

STRIKES = [0.03 + 0.005 * j for j in range(9)]
PAIRS, STEPS = 100000, 35
dt = T1 / STEPS
pay1 = [0.0] * 9                                      # strike sweep, fix-date unit
s_d = s_dd = s1 = s11 = sh = shh = sf = sff = sn = snn = 0.0
for p in range(PAIRS):
    zs = [gauss() for _ in range(STEPS)]
    for sign in (1.0, -1.0):
        x = log(F0); y = log(F0)                      # x: fix-date unit (drift), y: pay-date unit
        for z in zs:
            F = exp(x)
            x += (SIG * SIG * TAU * F / (1 + TAU * F) - SIG * SIG / 2) * dt + SIG * sqrt(dt) * sign * z
            y += -SIG * SIG / 2 * dt + SIG * sqrt(dt) * sign * z
        Fx, Fy = exp(x), exp(y)
        for j in range(9):
            pay1[j] += P1 * TAU * max(Fx - STRIKES[j], 0) / (1 + TAU * Fx)
        c1 = P1 * TAU * max(Fx - K, 0) / (1 + TAU * Fx)
        s1 += c1; s11 += c1 * c1
        d = c1 - P2 * TAU * max(Fy - K, 0)            # same draws, the other unit
        s_d += d; s_dd += d * d
        h = Fx - Fy; sh += h; shh += h * h            # drift shift, paired
        g = Fx / (1 + TAU * Fx) - Fy / (1 + TAU * F0); sf += g; sff += g * g
        e = P1 * TAU * max(Fy - K, 0) / (1 + TAU * Fy) - c1   # drift forgotten, minus right
        sn += e; snn += e * e
M = 2 * PAIRS
def se(s, ss): return sqrt((ss / M - (s / M) ** 2) / M)

c_black = TAU * P2 * black(F0, K, SIG, T1) * NOTL
c_quad = TAU * P2 * quad(lambda F: max(F - K, 0)) * NOTL
c_mc1, se1 = s1 / M * NOTL, se(s1, s11) * NOTL
diff, se_d = s_d / M * NOTL, se(s_d, s_dd) * NOTL
mean_fix = (F0 + TAU * F0 * F0 * exp(SIG * SIG * T1)) / (1 + TAU * F0)
no_drift = P1 * TAU * quad(lambda F: max(F - K, 0) / (1 + TAU * F)) * NOTL
v = SIG * sqrt(T1); d1 = (log(F0 / K) + v * v / 2) / v
out = [
    ("fix-date bond P(0,1.75)", P1, 6), ("pay-date bond P(0,2.00)", P2, 6),
    ("forward F(0), percent", 100 * F0, 4), ("sigma sqrt(T1)", v, 6),
    ("d1", d1, 6), ("d2", d1 - v, 6), ("N(d1)", ncdf(d1), 6), ("N(d2)", ncdf(d1 - v), 6),
    ("F N(d1) - K N(d2), percent", 100 * black(F0, K, SIG, T1), 6),
    ("1 Black, pay-date unit $", c_black, 2), ("2 Simpson quadrature $", c_quad, 2),
    ("3 MC, fix-date unit + drift $", c_mc1, 2), ("  standard error $", se1, 2),
    ("  road 3 minus pay-date road, MC $", diff, 2), ("  its standard error $", se_d, 2),
    ("mean F(1.75) under fix-date unit %", 100 * mean_fix, 4),
    ("  its lift over F(0), bp, exact", 1e4 * (mean_fix - F0), 4),
    ("  its lift over F(0), bp, MC paired", 1e4 * sh / M, 4),
    ("  standard error, bp", 1e4 * se(sh, shh), 4),
    ("fair bet F/(1+tau F) gap, bp, MC", 1e4 * sf / M, 4),
    ("  standard error, bp", 1e4 * se(sf, sff), 4),
    ("wrong: discount from fix date $", TAU * P1 * black(F0, K, SIG, T1) * NOTL, 2),
    ("wrong: no accrual fraction $", P2 * black(F0, K, SIG, T1) * NOTL, 2),
    ("wrong: volatility to pay date $", TAU * P2 * black(F0, K, SIG, T2) * NOTL, 2),
    ("wrong: fix-date unit, no drift $", no_drift, 2),
    ("  its error, quadrature $", no_drift - c_black, 2),
    ("  its error, MC paired $", sn / M * NOTL, 2),
]
for name, val, dp in out:
    print(f"{name:<38}{val:>16.{dp}f}")
print("chart, strike %      " + " ".join(f"{100 * k:8.2f}" for k in STRIKES))
print("chart, Black $       " + " ".join(f"{TAU * P2 * black(F0, k, SIG, T1) * NOTL:8.0f}" for k in STRIKES))
print("chart, MC fix-date $ " + " ".join(f"{pay1[j] / M * NOTL:8.0f}" for j in range(9)))

assert abs(c_quad - c_black) < 1e-4, "quadrature road vs Black's formula"
assert abs(c_black - 14793.71) < 0.005, "caplet 7 as priced on the caps shelf"
assert abs(c_mc1 - c_black) < 4 * se1, "fix-date-unit simulation vs Black"
assert abs(diff) < 4 * se_d, "paired: fix-date road vs pay-date road, path by path"
assert abs(sh / M - (mean_fix - F0)) < 4 * se(sh, shh), "forward drifts under the fix-date unit, by the exact amount"
assert abs(sf / M) < 4 * se(sf, sff), "F/(1+tau F) is the fair bet there instead"
assert abs(sn / M * NOTL - (no_drift - c_black)) < 4 * se(sn, snn) * NOTL, "the no-drift error, two roads"
print("ALL CHECKS PASS")
