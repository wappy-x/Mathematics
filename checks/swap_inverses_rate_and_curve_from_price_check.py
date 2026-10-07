# Solving a swap backwards -- the check behind the card.  Standard library only.
# Nothing imported knows an answer: the curve is bootstrapped here, the floating leg is
# built payment by payment from forward rates, and bisection is written out.  Case one
# takes a value of 100,000 back to a fixed rate; case two takes the 4.65 percent
# five-year par quote back to the five-year discount factor.
N = 10_000_000.0                                   # notional, dollars
PAR = {2: 0.0440, 3: 0.0455, 4: 0.0462, 5: 0.0465} # the screen's par swap quotes
YEARS = (1, 2, 3, 4, 5)                            # annual payments, accrual 1 each

def bootstrap(par):                                # the rung formula, shortest first
    D = {0: 1.0, 1: 1.0 / (1.0 + 1.0 * 0.042)}     # one-year deposit at 4.20 percent
    for n in (2, 3, 4, 5):
        B = sum(D[i] for i in range(1, n))
        D[n] = (1.0 - par[n] * B) / (1.0 + par[n])
    return D

def legs(D, K):                                    # payment by payment, no telescoping
    fixed = sum(N * K * D[i] for i in YEARS)
    fwd = [D[i - 1] / D[i] - 1.0 for i in YEARS]   # forward rate for each year
    floating = sum(N * f * D[i] for f, i in zip(fwd, YEARS))
    return fixed, floating, fwd

def receiver(D, K):                                # value to whoever receives fixed
    fixed, floating, _ = legs(D, K)
    return fixed - floating

def bisect(g, lo, hi, tol=1e-15):                  # g(lo) < 0 < g(hi), g rising
    steps = 0
    while hi - lo > tol and steps < 200:
        mid = 0.5 * (lo + hi); steps += 1
        if g(mid) < 0.0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi), steps

D = bootstrap(PAR)
A = sum(D[i] for i in YEARS)                       # annuity: one dollar a year, today
V = 100_000.0                                      # target value to the fixed receiver
# ---- case one: value back to a fixed rate ----
K1 = (V / N + 1.0 - D[5]) / A                      # road 1: the line, solved by hand
K2, it = bisect(lambda k: receiver(D, k) - V, -1.0, 1.0)   # road 2: search on full legs
k0, k1 = 0.01, 0.09                                # road 3: one secant step from anywhere
K3 = k0 + (V - receiver(D, k0)) * (k1 - k0) / (receiver(D, k1) - receiver(D, k0))
K0 = (1.0 - D[5]) / A                              # the same line at value zero: par
_, fl, fwd = legs(D, 0.0)
S_fwd = sum(f * D[i] for f, i in zip(fwd, YEARS)) / A      # par as weighted forwards
V_house = -receiver(D, 0.045)                      # house swap: pay 4.50 percent fixed
K_house = K0 - V_house / (N * A)                   # payer's inverse, back to 4.50
# ---- case two: a par quote back to one discount factor ----
S5 = PAR[5]
B5 = sum(D[i] for i in (1, 2, 3, 4))
D5_1 = (1.0 - S5 * B5) / (1.0 + S5)                # road 1: the rung
def par_value(d5):                                 # a new 5y swap at S5, trial D5
    Dt = dict(D); Dt[5] = d5
    return receiver(Dt, S5) / N
D5_2, it2 = bisect(par_value, 1e-9, 1.0)           # road 2: search, legs from forwards
h = 1e-4
slope_fd = ((1 - (S5 + h) * B5) / (1 + S5 + h) - (1 - (S5 - h) * B5) / (1 + S5 - h)) / (2 * h)
slope_an = -(1.0 + B5) / (1.0 + S5) ** 2
# ---- what breaks ----
w_undisc = S5 + V / (N * 5.0)                      # annuity read as 5 payments
w_sign = K0 - V / (N * A)                          # payer's inverse used for a receiver
w_nofloat = V / (N * A)                            # floating leg forgotten
w_nocoup = 1.0 / (1.0 + S5)                        # earlier coupons forgotten
w_zero = 1.0 / (1.0 + S5) ** 5                     # par read as an annual zero rate

rows = [
    ("D1", D[1]), ("D2", D[2]), ("D3", D[3]), ("D4", D[4]), ("D5", D[5]),
    ("annuity A = D1+...+D5", A), ("N x A, dollars per unit rate", N * A),
    ("floating leg per dollar, 1 - D5", 1.0 - D[5]), ("floating leg, from forwards", fl), ("floating leg, N(1 - D5)", N * (1 - D[5])),
    ("par rate, (1 - D5)/A", K0), ("par rate, weighted forwards", S_fwd),
    ("1 fixed rate, the line", K1), ("2 fixed rate, bisection", K2),
    ("  bisection halvings", it), ("3 fixed rate, one secant step", K3),
    ("  value at that rate", receiver(D, K1)),
    ("  rate shift, V/(N A)", V / (N * A)), ("  value per 1bp of fixed rate", N * A * 1e-4),
    ("  value where fixed rate is 0", -N * (1 - D[5])),
    ("house: payer value at 4.50%", V_house), ("house: rate from that value", K_house),
    ("4 D5, the rung", D5_1), ("5 D5, bisection", D5_2), ("  bisection halvings", it2),
    ("  known part B5 = D1+...+D4", B5), ("  1 - S5 x B5", 1.0 - S5 * B5),
    ("  top edge of quote, 1/B5", 1 / B5), ("  bottom edge of quote, -1", -1.0),
    ("  dD5/dS by bump", slope_fd), ("  dD5/dS = -(1+B5)/(1+S)^2", slope_an),
    ("  D5 move for +1bp quote", slope_an * 1e-4),
    ("wrong: annuity read as 5", w_undisc), ("  reprices at", receiver(D, w_undisc)),
    ("wrong: payer sign", w_sign), ("  reprices at", receiver(D, w_sign)),
    ("wrong: floating leg dropped", w_nofloat), ("  reprices at", receiver(D, w_nofloat)),
    ("wrong: D5 without coupons", w_nocoup), ("wrong: par as annual zero", w_zero),
    ("try: 20m notional, rate", K0 + V / (2 * N * A)),
    ("try: 5y quote 4.66%, D5", (1 - 0.0466 * B5) / (1.0466)),
]
for name, v in rows:
    print(f"{name:<32} {v:>18d}" if "halvings" in name else f"{name:<32} {v:>18.8f}")
print()
print("chart, value target        " + " ".join(f"{t:>8.0f}" for t in (-200e3, -100e3, 0, 100e3, 200e3)))
print("chart, fixed rate %        " + " ".join(f"{100 * (K0 + t / (N * A)):>8.2f}" for t in (-200e3, -100e3, 0, 100e3, 200e3)))
qs = (0.0, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28)
print("chart, 5y quote %          " + " ".join(f"{100 * s:>7.0f}" for s in qs))
print("chart, $100 due in 5y      " + " ".join(f"{100 * (1 - s * B5) / (1 + s):>7.2f}" for s in qs))

assert abs(K2 - K1) < 1e-12, "bisection on full legs must land on the line"
assert abs(K3 - K1) < 1e-12, "a linear value: one secant step must land exactly"
assert abs(S_fwd - PAR[5]) < 1e-12, "weighted forwards must give back the 5y quote"
assert abs(D5_2 - D5_1) < 1e-12, "bisection on the par swap must land on the rung"
assert abs(D[5] - 0.79621728) < 5e-9, "five-year price from the bootstrapping card"
assert abs(K_house - 0.045) < 1e-12, "the house swap's value must invert to 4.50%"
assert abs(slope_fd - slope_an) < 1e-6, "bumped slope vs the derivative"
print("ALL CHECKS PASS")
