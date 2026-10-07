# Caplets and floorlets -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is the Taylor series of erf written out,
# the integrals are Simpson's rule, the random numbers come from a xorshift generator.
from math import log, sqrt, exp, pi, cos

def N(x):                                            # bell-curve area left of x (erf series)
    if abs(x) > 8.0: return 0.0 if x < 0 else 1.0
    y = x / sqrt(2.0); term = y; s = y; n = 0
    while abs(term) > 1e-17:
        n += 1; term *= -y * y / n; s += term / (2 * n + 1)
    return 0.5 + s / sqrt(pi)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def black(F, K, sig, T, cp):                         # Black-76 per unit of rate; cp +1 caplet, -1 floorlet
    v = sig * sqrt(T); d1 = (log(F / K) + 0.5 * v * v) / v; d2 = d1 - v
    return cp * (F * N(cp * d1) - K * N(cp * d2))

def simpson(f, a, b, n=4000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def average(F, sig, T, g, kink):                     # E[g(L)] with L lognormal, centre F; no d1, d2 or N
    f = lambda z: g(F * exp(-0.5 * sig * sig * T + sig * sqrt(T) * z)) * phi(z)
    return simpson(f, -10.0, kink) + simpson(f, kink, 10.0)

# ---- the example: one quarter of a $10m loan, strike 5%, 30% vol, flat 5% continuous curve ----
M, tau, K, sig, r, T1, T2 = 10_000_000.0, 0.25, 0.05, 0.30, 0.05, 2.5, 2.75
D = lambda t: exp(-r * t)
D1, D2 = D(T1), D(T2)
F = (D1 / D2 - 1.0) / tau                             # the forward rate, read from two bond prices
v = sig * sqrt(T1); d1 = (log(F / K) + 0.5 * v * v) / v; d2 = d1 - v
cpl = M * tau * D2 * black(F, K, sig, T1, +1)
flr = M * tau * D2 * black(F, K, sig, T1, -1)
kz = (log(K / F) + 0.5 * v * v) / v                    # where the payoff bends, in z units
rows = [("D(T1) reset 2.5y", D1, 6), ("D(T2) payment 2.75y", D2, 6), ("forward rate F", F, 8),
        ("sigma sqrt(T1)", v, 6), ("d1", d1, 6), ("d2", d2, 6), ("N(d1)", N(d1), 6), ("N(d2)", N(d2), 6),
        ("F N(d1)", F * N(d1), 8), ("K N(d2)", K * N(d2), 8), ("Black value, rate units", F * N(d1) - K * N(d2), 8),
        ("M tau D(T2)", M * tau * D2, 2), ("1 CAPLET, formula", cpl, 2), ("  per cent of notional", 100 * cpl / M, 4),
        ("  breakeven fixing, per cent", 100 * (K + cpl / (M * tau * D2)), 4), ("FLOORLET, formula", flr, 2)]

# ---- road 2: Simpson average of the payoff under the payment-date odds ----
cpl_int = M * tau * D2 * average(F, sig, T1, lambda L: max(L - K, 0.0), kz)
flr_int = M * tau * D2 * average(F, sig, T1, lambda L: max(K - L, 0.0), kz)
mean_L = average(F, sig, T1, lambda L: L, kz)
rows += [("2 CAPLET, Simpson integral", cpl_int, 2), ("  FLOORLET, Simpson integral", flr_int, 2),
         ("  average fixing (must be F)", mean_L, 8)]

# ---- road 3: Monte Carlo, 200,000 fixings, own generator ----
state, MASK = 88172645463325252, (1 << 64) - 1
def uniform():
    global state
    state ^= (state << 13) & MASK; state ^= state >> 7; state ^= (state << 17) & MASK
    return ((state >> 11) + 0.5) / 9007199254740992.0
n_mc, s1, s2 = 200_000, 0.0, 0.0
for _ in range(n_mc):
    z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
    p = M * tau * D2 * max(F * exp(-0.5 * v * v + v * z) - K, 0.0)
    s1 += p; s2 += p * p
mc = s1 / n_mc; se = sqrt((s2 / n_mc - mc * mc) / n_mc)
rows += [("3 CAPLET, Monte Carlo 200k", mc, 2), ("  standard error", se, 2)]

# ---- road 4: the same caplet as bond puts, counted in reset-date bonds ----
X = lambda L: 1.0 / (1.0 + tau * L)                  # price at T1 of $1 paid at T2
w = lambda L: (D2 / D1) / X(L)                        # reweighting: payment-date odds -> reset-date odds
Kb = 1.0 / (1.0 + tau * K)
w_mean = average(F, sig, T1, w, kz)
bond_put = M * (1 + tau * K) * D1 * average(F, sig, T1, lambda L: w(L) * max(Kb - X(L), 0.0), kz)
rows += [("4 bond strike 1/(1+tau K)", Kb, 8), ("  average reweighting (must be 1)", w_mean, 10),
         ("  CAPLET as bond puts, reset-date odds", bond_put, 2)]

# ---- parity for one period: caplet - floorlet = forward rate agreement ----
fra = M * tau * D2 * (F - K)
rows += [("caplet - floorlet (floorlet by integral)", cpl - flr_int, 4), ("M tau D(T2) (F - K)", fra, 4)]

# ---- a two-state world: which odds make the forward a fair bet? ----
Lu, Ld = 0.08, 0.03
pu = (D2 - D1 * X(Ld)) / (X(Lu) - X(Ld)); pd = D1 - pu          # state prices at T1
bank = (pu * Lu + pd * Ld) / D1                                 # odds of the reset-date bond
fwd = (pu * X(Lu) * Lu + pd * X(Ld) * Ld) / D2                  # odds of the payment-date bond
true2 = M * tau * (pu * X(Lu) * max(Lu - K, 0) + pd * X(Ld) * max(Ld - K, 0))
wrong2 = M * tau * D2 * (pu * max(Lu - K, 0) + pd * max(Ld - K, 0)) / D1
rows += [("toy: state price, rate 8%", pu, 6), ("toy: state price, rate 3%", pd, 6),
         ("toy: average rate, reset-bond odds", bank, 8), ("toy: average rate, payment-bond odds", fwd, 8),
         ("toy: caplet, state prices", true2, 2), ("toy: caplet, wrong odds", wrong2, 2)]

# ---- Greeks by formula and by bumping ----
dlt = M * tau * D2 * N(d1) * 1e-4; vga = M * tau * D2 * F * phi(d1) * sqrt(T1) * 0.01
b = 1e-6
dlt_b = M * tau * D2 * (black(F + b, K, sig, T1, 1) - black(F - b, K, sig, T1, 1)) / (2 * b) * 1e-4
vga_b = M * tau * D2 * (black(F, K, sig + b, T1, 1) - black(F, K, sig - b, T1, 1)) / (2 * b) * 0.01
rows += [("delta per 1bp of F, formula", dlt, 4), ("delta per 1bp of F, bump", dlt_b, 4),
         ("floorlet delta per 1bp", -M * tau * D2 * N(-d1) * 1e-4, 4),
         ("vega per vol point, formula", vga, 4), ("vega per vol point, bump", vga_b, 4)]

# ---- what breaks, try changing, and the shelf's cross-check ----
c = lambda F_, K_, s_, T_, D_, t_=tau: M * t_ * D_ * black(F_, K_, s_, T_, 1)
Fq = lambda rr, a, bb: (exp(rr * (bb - a)) - 1.0) / (bb - a)
rows += [("wrong: discount to reset date", c(F, K, sig, T1, D1), 2), ("wrong: vol clock to payment date", c(F, K, sig, T2, D2), 2),
         ("wrong: curve's 5% read as F", c(0.05, K, sig, T1, D2), 2), ("wrong: no accrual tau", c(F, K, sig, T1, D2, 1.0), 2),
         ("wrong: N(d2) on both sides", M * tau * D2 * (F - K) * N(d2), 2),
         ("try: sigma = 0.20", c(F, K, 0.20, T1, D2), 2), ("try: K = 5.5%", c(F, 0.055, sig, T1, D2), 2),
         ("try: fixes 1y, pays 1.25y", c(F, K, sig, 1.0, D(1.25)), 2),
         ("try: curve at 4%", c(Fq(0.04, T1, T2), K, sig, T1, exp(-0.04 * T2)), 2)]
Dq = [1.0]
for i in range(8): Dq.append(Dq[-1] / (1 + 0.25 * (0.044 + 0.0005 * i)))
rows += [("shelf: caplet 7 of the 2-year cap", c(0.0475, K, sig, 1.75, Dq[8]), 2)]
for name, val, dp in rows: print(f"{name:<42}{val:>16.{dp}f}")

fix = [3.0 + 0.5 * i for i in range(9)]
print("chart, fixing %  " + " ".join(f"{x:.1f}" for x in fix))
print("chart, payoff    " + " ".join(f"{M * tau * max(x / 100 - K, 0):.0f}" for x in fix))
print("chart, profit    " + " ".join(f"{M * tau * max(x / 100 - K, 0) - cpl / D2:.0f}" for x in fix))

assert abs(cpl_int - cpl) < 1e-4, "Simpson road must land on the formula"
assert abs(mc - cpl) < 3 * se, "Monte Carlo within three standard errors"
assert abs(bond_put - cpl) < 1e-4, "bond-put road under reset-date odds must agree"
assert abs((cpl - flr_int) - fra) < 1e-4, "caplet - floorlet must equal the FRA"
assert abs(fwd - F) < 1e-12, "payment-date odds make the forward a fair bet"
assert abs(dlt_b - dlt) < 1e-4, "delta by bump matches N(d1)"
assert abs(vga_b - vga) < 1e-4, "vega by bump matches the formula"
assert abs(mean_L - F) < 1e-12, "under payment-date odds the fixing averages to F"
assert abs(w_mean - 1.0) < 1e-12, "the reweighting averages to 1"
print("ALL CHECKS PASS")
