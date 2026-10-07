# The annuity measure -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF, the integrator, the root
# finder and the random numbers are all written out below.
from math import exp, log, sqrt, cos, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)              # bell-curve height at x

def simpson(f, a, b, n):                                             # area under f, thin slices
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def N(x):                                                            # bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)

def black(F, K, vol, T):                                             # Black's bracket, per unit annuity
    d1 = (log(F / K) + 0.5 * vol * vol * T) / (vol * sqrt(T))
    return F * N(d1) - K * N(d1 - vol * sqrt(T))

# ---- today's curve: one-year forward rates for years 1 to 6, annual compounding ----
fwd = [0.050, 0.046, 0.043, 0.041, 0.040, 0.039]
D = [1.0]
for f in fwd: D.append(D[-1] / (1.0 + f))                            # D[k]: today's price of $1 in year k
L, T0, pay = 10_000_000.0, 1, [2, 3, 4, 5, 6]                        # 1-into-5, fixed paid yearly
A0 = sum(D[k] for k in pay)                                          # the annuity today
F = (D[T0] - D[6]) / A0                                              # the forward swap rate today

# ---- a one-factor curve model at the expiry date: one random number z moves every rate ----
sr = 0.0120                                                          # size of the parallel shift, per year
def bond1(k, z, s=sr):                                               # price at year 1 of $1 paid in year k
    b = k - T0
    return D[k] / D[T0] * exp(-b * s * z - 0.5 * b * b * s * s)
def ann1(z, s=sr):   return sum(bond1(k, z, s) for k in pay)         # the annuity at year 1
def swap1(z, s=sr):  return (1.0 - bond1(6, z, s)) / ann1(z, s)      # the swap rate at year 1
def weight(z, s=sr): return D[T0] * ann1(z, s) / A0                  # tilt from expiry dollars to annuities

def E(g): return simpson(lambda z: g(z) * phi(z), -8.0, 8.0, 4000)   # average in expiry-date dollars
bond_gap = max(abs(E(lambda z, k=k: bond1(k, z)) - D[k] / D[T0]) for k in pay)
w_mean = E(weight)
S_dollar = E(swap1)                                                  # swap rate averaged in dollars
S_ann = E(lambda z: weight(z) * swap1(z))                            # swap rate averaged in annuities

# ---- road 2: Monte Carlo with home-made random numbers (64-bit LCG, Box-Muller) ----
state = 20260928
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2.0**53
def normal():
    u1, u2 = unif(), unif()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
n_mc, K, vol = 100_000, F, 0.30                                      # at-the-money strike, 30% vol
sums = [0.0] * 5
for _ in range(n_mc):
    z, y = normal(), normal()
    for z in (z, -z):                                                # each draw and its mirror image
        s, w = swap1(z), weight(z)
        lz = F * exp(-0.5 * vol * vol + vol * y)                     # a lognormal swap rate, annuity units
        y = -y
        for i, v in enumerate((s, w * s, w, w * max(s - K, 0.0), max(lz - K, 0.0))): sums[i] += v
mc = [v / (2 * n_mc) for v in sums]

# ---- the swaption: priced in expiry dollars (Simpson) and in annuities (Monte Carlo) ----
model_dollar = L * D[T0] * E(lambda z: ann1(z) * max(swap1(z) - K, 0.0))
model_ann_mc = L * A0 * mc[3]
black_30 = L * A0 * black(F, K, vol, 1.0)
black_mc = L * A0 * mc[4]
def implied(price, K):                                               # bisection: Black vol that fits
    lo, hi = 0.01, 1.00
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if L * A0 * black(F, K, mid, 1.0) < price: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
smile = []
for Ks in (F - 0.01, F, F + 0.01):
    smile.append((Ks, implied(L * D[T0] * E(lambda z: ann1(z) * max(swap1(z) - Ks, 0.0)), Ks)))

d1 = (log(F / K) + 0.5 * vol * vol) / vol
rows = [(f"D({k})", D[k]) for k in range(1, 7)]
rows += [("annuity A0, years 2-6", A0), ("forward swap rate F", F),
        ("L x A0, dollars per basis point", L * A0 * 1e-4),
        ("worst bond gap, model vs forward", bond_gap), ("weight averages to", w_mean),
        ("mean S, dollar unit, Simpson", S_dollar), ("mean S, annuity unit, Simpson", S_ann),
        ("mean S, dollar unit, Monte Carlo", mc[0]), ("mean S, annuity unit, Monte Carlo", mc[1]),
        ("weight average, Monte Carlo", mc[2]), ("dollar-unit drift, basis points", (S_dollar - F) * 1e4),
        ("payer, model, dollar unit, Simpson", model_dollar), ("payer, model, annuity unit, MC", model_ann_mc),
        ("payer, Black 30%, formula", black_30), ("payer, Black 30%, Monte Carlo", black_mc),
        ("d1", d1), ("d2", d1 - vol), ("N(d1)", N(d1)), ("N(d2)", N(d1 - vol)),
        ("Black bracket F N(d1) - K N(d2)", black(F, K, vol, 1.0)),
        ("payer, Black 30%, % of notional", 100 * black_30 / L),
        ("payer, Black 30%, basis points of rate", black_30 / (L * A0 * 1e-4)),
        ("wrong: drifted mean as forward", L * A0 * black(S_dollar, K, vol, 1.0)),
        ("wrong: discount by D(1) only", L * D[1] * black(F, K, vol, 1.0)),
        ("wrong: annuity over years 1-5", L * sum(D[1:6]) * black(F, K, vol, 1.0)),
        ("wrong: model payoff, no weight", L * A0 * E(lambda z: max(swap1(z) - K, 0.0)))]
for Ks, iv in smile: rows.append((f"model Black vol at K = {100 * Ks:.4f}%", iv))
drifts = []
for s_try in (0.0, 0.024):
    drift = E(lambda z: swap1(z, s_try)) - E(lambda z: weight(z, s_try) * swap1(z, s_try))
    drifts.append(drift)
    rows.append((f"try: shift size {s_try:.3f}, drift in bp", abs(drift) * 1e4))
for name, v in rows: print(f"{name:<40} {v:>16.6f}")
print()
for z in (-2.0, -1.0, 0.0, 1.0, 2.0):
    print(f"chart, z {z:+.0f}   swap rate {100 * swap1(z):5.2f}%   annuity {ann1(z):.4f}   weight {weight(z):.4f}")

assert bond_gap < 1e-12,                        "the model prices every bond at today's forward price"
assert abs(w_mean - 1.0) < 1e-12,               "the tilt must average to one, or it is not a probability"
assert abs(S_ann - F) < 1e-10,                  "annuity-unit average must land on today's forward"
assert abs(mc[1] - F) < 1e-5,                   "Monte Carlo road, annuity unit, within sampling error"
assert S_dollar - F > 5e-5,                     "counted in expiry dollars the swap rate must drift up"
assert abs(model_ann_mc - model_dollar) < 0.01 * model_dollar, "two units, one swaption price"
assert abs(black_mc - black_30) < 0.01 * black_30,             "Black formula vs lognormal Monte Carlo"
assert smile[0][1] > smile[1][1] > smile[2][1],  "the model's Black volatility falls as the strike rises"
assert abs(drifts[0]) < 1e-12,                  "no randomness in rates, no drift"
assert abs(drifts[1] / (S_dollar - F) - 4.0) < 0.05, "double the shift size, four times the drift"
print("ALL CHECKS PASS")
