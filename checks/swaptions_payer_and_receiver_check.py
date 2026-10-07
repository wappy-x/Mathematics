# Swaptions, payer and receiver -- the check behind the card.  Standard library only.
# The bell-curve area, the integrator and the random numbers are all written here;
# nothing imported already knows a swaption price.
from math import log, sqrt, exp, cos, pi

FWD = [0.050, 0.046, 0.043, 0.041, 0.040, 0.039]    # one-year forward rates, years 1..6
L, K, SIG, T = 10_000_000.0, 0.043, 0.30, 1.0        # notional, strike, volatility, expiry in years
MASK = (1 << 64) - 1

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def simpson(f, a, b, n):                                 # area under f from a to b, n even slices
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def ncdf(x):                                             # N(x): bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)

D = [1.0]                                                # D[i]: today's price of 1 dollar at year i
for f in FWD: D.append(D[-1] / (1.0 + f))
A = sum(D[2:7])                                          # annuity: 1 unit of rate paid at years 2..6
F = (D[1] - D[6]) / A                                    # forward swap rate, road 1: the telescope
F_avg = sum(D[i] * FWD[i - 1] for i in range(2, 7)) / A  # road 2: forwards weighted by discount

def black(f, k, sig, t, a):                              # the formula: payer, receiver, d1, d2
    v = sig * sqrt(t)
    d1 = (log(f / k) + 0.5 * v * v) / v
    d2 = d1 - v
    return a * (f * ncdf(d1) - k * ncdf(d2)), a * (k * ncdf(-d2) - f * ncdf(-d1)), d1, d2

pay, rec, d1, d2 = black(F, K, SIG, T, A)
pay, rec = L * pay, L * rec

def by_integral(payoff, n=40000):                        # road 2: average the payoff over the bell curve
    v = SIG * sqrt(T)
    return L * A * simpson(lambda z: payoff(F * exp(-0.5 * v * v + v * z)) * phi(z), -10.0, 10.0, n)

pay_int = by_integral(lambda s: max(s - K, 0.0))
rec_int = by_integral(lambda s: max(K - s, 0.0))
swap_cc = L * sum(D[i] * (FWD[i - 1] - K) for i in range(2, 7))   # forward swap, coupon by coupon

state = 20260928
def uniform():                                           # xorshift64*, then a number in (0, 1)
    global state
    state ^= state >> 12
    state ^= (state << 25) & MASK
    state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & MASK) >> 11) / 9007199254740992.0 + 1.0 / 18014398509481984.0

def by_simulation(paths):                                # road 3: draw swap rates, average the payoffs
    v = SIG * sqrt(T)
    tot = tot2 = ex = exw = 0.0
    for _ in range(paths):
        z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())   # Box-Muller: one bell-curve draw
        s = F * exp(-0.5 * v * v + v * z)
        p = max(s - K, 0.0)
        tot += p; tot2 += p * p
        if s > K: ex += 1.0; exw += s / F
    m = tot / paths
    return L * A * m, L * A * sqrt((tot2 / paths - m * m) / paths), ex / paths, exw / paths

mc, se, ex_frac, ex_wfrac = by_simulation(200_000)

h = 1e-6                                                 # Greeks: formula and a nudge
delta_f = L * A * ncdf(d1) * 1e-4
delta_b = L * (black(F + h, K, SIG, T, A)[0] - black(F - h, K, SIG, T, A)[0]) / (2 * h) * 1e-4
vega_f = L * A * F * phi(d1) * sqrt(T) * 0.01
vega_b = L * (black(F, K, SIG + h, T, A)[0] - black(F, K, SIG - h, T, A)[0]) / (2 * h) * 0.01

A_early = sum(D[1:6])                                    # wrong: annuity over years 1..5
S_spot = (1.0 - D[5]) / sum(D[1:6])                      # wrong underlying: 5-year swap starting today
wrong = [
    ("wrong: D(1) in place of the annuity", L * D[1] * (F * ncdf(d1) - K * ncdf(d2))),
    ("wrong: spot 5-year swap rate as F", L * black(S_spot, K, SIG, T, A)[0]),
    ("wrong: annuity over years 1 to 5", L * black((D[1] - D[6]) / A_early, K, SIG, T, A_early)[0]),
    ("wrong: N(d2) on both halves", L * A * (F - K) * ncdf(d2)),
]
print("D(1) to D(6)" + "".join(f" {x:.6f}" for x in D[1:]))
rows = [("annuity A", A), ("F, telescope", F), ("F, weighted forwards", F_avg),
        ("F minus K, bp", 1e4 * (F - K)), ("ln(F/K)", log(F / K)), ("half sigma^2 T", 0.5 * SIG * SIG * T), ("d1", d1), ("d2", d2), ("N(d1)", ncdf(d1)), ("N(d2)", ncdf(d2)), ("N(-d1)", ncdf(-d1)),
        ("F N(d1), bp", 1e4 * F * ncdf(d1)), ("K N(d2), bp", 1e4 * K * ncdf(d2)), ("bracket, bp", 1e4 * (F * ncdf(d1) - K * ncdf(d2))),
        ("1 payer, formula", pay), ("2 payer, Simpson", pay_int), ("3 payer, simulation", mc),
        ("  simulation std error", se), ("  simulation gap, std errors", (pay - mc) / se), ("  payer, percent of notional", 100 * pay / L),
        ("  payer, bp a year of annuity", 1e4 * pay / (L * A)), ("L A times one bp", L * A * 1e-4),
        ("receiver, formula", rec), ("receiver, Simpson", rec_int),
        ("4 payer - receiver", pay_int - rec_int), ("  swap, coupon by coupon", swap_cc),
        ("  L A (F - K)", L * A * (F - K)),
        ("exercise share, simulated", ex_frac), ("rate-weighted share, sim.", ex_wfrac),
        ("5 payer delta per bp, formula", delta_f), ("  payer delta per bp, nudge", delta_b),
        ("  receiver delta per bp", -L * A * ncdf(-d1) * 1e-4),
        ("  vega per vol point, formula", vega_f), ("  vega per vol point, nudge", vega_b)] + wrong + [
        ("spot 5-year swap rate", S_spot),
        ("try: sigma 0.20 payer", L * black(F, K, 0.20, T, A)[0]),
        ("try: sigma 0.40 payer", L * black(F, K, 0.40, T, A)[0]),
        ("try: strike = F, payer", L * black(F, F, SIG, T, A)[0]),
        ("try: strike = F, receiver", L * black(F, F, SIG, T, A)[1])]
for name, v in rows:
    print(f"{name:<36} {v:>16.6f}")

print("\nchart, swap rate at expiry %   " + " ".join(f"{3.5 + 0.2 * i:6.1f}" for i in range(9)))
print("chart, payer payoff, bp a year " + " ".join(f"{max(3.5 + 0.2 * i - 4.3, 0) * 100:6.0f}" for i in range(9)))
print("chart, receiver payoff, bp     " + " ".join(f"{max(4.3 - 3.5 - 0.2 * i, 0) * 100:6.0f}" for i in range(9)))
ks = [0.036 + 0.002 * i for i in range(7)]
print("chart, strike %                " + " ".join(f"{100 * k:6.1f}" for k in ks))
print("chart, payer, $ thousands      " + " ".join(f"{L * black(F, k, SIG, T, A)[0] / 1e3:6.2f}" for k in ks))
print("chart, receiver, $ thousands   " + " ".join(f"{L * black(F, k, SIG, T, A)[1] / 1e3:6.2f}" for k in ks))

assert abs(pay - 191290.0) < 50.0,                  "the card's worked number, 1.9 percent of notional"
assert abs(pay_int - pay) < 0.01,                   "Simpson road lands on the formula to the cent"
assert abs(mc - pay) < 4.0 * se,                    "simulation road within four standard errors"
assert abs((pay_int - rec_int) - swap_cc) < 0.01,   "parity: payer - receiver = the forward swap"
assert abs(F - F_avg) < 1e-12,                      "forward swap rate: telescope = weighted forwards"
assert abs(delta_f - delta_b) < 1e-3,               "delta: formula = nudge"
assert abs(rec - rec_int) < 0.01,                   "receiver formula = Simpson road"
assert abs(vega_f - vega_b) < 1e-3,                 "vega: formula = nudge"
print("ALL CHECKS PASS")
