# Inverse contracts -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  The bell-curve area is its own
# series, the integrals are Simpson's rule written out, the tree is a loop, and
# the coin P&L is also done in exact fractions, so no rounding can hide in it.
from fractions import Fraction
from math import exp, log, pi, sqrt

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)    # bell-curve height

def N(x):   # bell-curve area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        k += 2
        term *= x * x / k
        total += term
    return 0.5 + phi(x) * total

def simpson(f, a=-10.0, b=10.0, n=4000):                  # area under f, a to b
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

def line(label, v, fmt=".6f"): print(f"{label:<44} {v:>16{fmt}}")
def row(label, vals, fmt=".0f"): print(f"{label:<22}" + "".join(f"{v:>8{fmt}}" for v in vals))

# ---- the inverse future: 100 USD a contract, paid in bitcoin ----
Q, F0 = 100.0, 60000.0
def coin_pnl(F1): return Q * (1 / F0 - 1 / F1)            # BTC to a long, per contract
up, down = coin_pnl(61000.0), coin_pnl(59000.0)
exact_up = 100 * (Fraction(1, 60000) - Fraction(1, 61000))
exact_down = 100 * (Fraction(1, 60000) - Fraction(1, 59000))
tangent = Q * 1000.0 / F0 ** 2                            # coin delta at entry x 1000
line("coin P&L, 60000 -> 61000 (BTC)", up, ".10f")
print(f"{'same, in exact fractions (BTC)':<44} {str(exact_up):>16}")
line("its dollar value at 61000 (USD)", up * 61000.0, ".4f")
line("same, linear 100*(61000/60000 - 1) (USD)", Q * (61000.0 / 60000.0 - 1), ".4f")
line("coin P&L, 60000 -> 59000 (BTC)", down, ".10f")
print(f"{'same, in exact fractions (BTC)':<44} {str(exact_down):>16}")
line("straight-line guess, 1000 either way (BTC)", tangent, ".10f")
line("up move plus down move (BTC)", up + down, ".10f")
assert exact_up == Fraction(1, 36600)
assert abs(up - float(exact_up)) < 1e-18
assert abs(down - float(exact_down)) < 1e-18
assert down + up < 0                                      # concave for the long
assert abs(up * 61000.0 - Q / 60.0) < 1e-12                          # linear in dollars
h = 1000.0
fd = -(coin_pnl(F0 + h) + coin_pnl(F0 - h) - 2 * coin_pnl(F0)) / h ** 2   # curvature of 100/P
line("curvature of 100/P, by differences (x1e12)", fd * 1e12, ".6f")
line("curvature of 100/P, 2Q/P^3 (x1e12)", 2 * Q / F0 ** 3 * 1e12, ".6f")
assert abs(fd - 2 * Q / F0 ** 3) < 1e-3 * fd
for F1 in (40000.0, 60000.0, 80000.0):                    # 1 BTC + short 600 contracts
    coins = 1.0 - 600 * coin_pnl(F1)
    print(f"synthetic dollar at {F1:>7.0f}: holds {coins:.6f} BTC worth {coins * F1:>10.2f} USD")
    assert abs(coins * F1 - 60000.0) < 1e-6

# ---- the coin-settled call: 1 BTC, strike 60000, 3 months, 80% vol ----
S, K, rd, rf, vol, T = 60000.0, 60000.0, 0.05, 0.0, 0.80, 0.25
v = vol * sqrt(T)
F = S * exp((rd - rf) * T)
d1 = (log(S / K) + (rd - rf + 0.5 * vol * vol) * T) / v
d2 = d1 - v
C = S * exp(-rf * T) * N(d1) - K * exp(-rd * T) * N(d2)   # Garman-Kohlhagen, USD
c = C / S                                                 # the same call, in BTC
line("forward F (USD)", F, ".2f")
line("d1", d1); line("d2", d2); line("N(d1)", N(d1)); line("N(d2)", N(d2))
line("discount exp(-rd T)", exp(-rd * T))
line("share half, S exp(-rf T) N(d1) (USD)", S * exp(-rf * T) * N(d1), ".2f")
line("cash half, K exp(-rd T) N(d2) (USD)", K * exp(-rd * T) * N(d2), ".2f")
line("cash half counted in coin, / S (BTC)", K * exp(-rd * T) * N(d2) / S)
line("road 1: Garman-Kohlhagen call (USD)", C, ".2f")
line("road 1: coin-settled call, C/S (BTC)", c)
def ST(z, drift): return S * exp(drift * T + v * z)
btc_world = rd - rf + 0.5 * vol * vol                     # drift when counting in coin
usd_world = rd - rf - 0.5 * vol * vol                     # drift when counting in dollars
kink = lambda drift: (log(K / S) - drift * T) / v           # where S_T crosses K
c2 = exp(-rf * T) * simpson(lambda z: (1 - K / ST(z, btc_world)) * phi(z), kink(btc_world))
line("road 2: coin payoff averaged in coin (BTC)", c2)
steps = 2000                                              # road 3: coin-flip tree in dollars
dt = T / steps
u = exp(vol * sqrt(dt)); dn = 1 / u
p = (exp((rd - rf) * dt) - dn) / (u - dn)
vals = [max(S * u ** j * dn ** (steps - j) - K, 0.0) for j in range(steps + 1)]
for n in range(steps, 0, -1):
    vals = [exp(-rd * dt) * (p * vals[j + 1] + (1 - p) * vals[j]) for j in range(n)]
c3 = vals[0] / S
line("road 3: dollar tree, then / S (BTC)", c3)
assert abs(c2 - c) < 1e-9
assert abs(c3 - c) < 5e-5
wrong = exp(-rd * T) * simpson(lambda z: (1 - K / ST(z, usd_world)) * phi(z), kink(usd_world))
line("wrong: coin payoff averaged in dollars (BTC)", wrong)
delta_usd = exp(-rf * T) * N(d1)
line("delta of the dollar call (BTC)", delta_usd)
line("delta net of the coin premium (BTC)", delta_usd - c)
def coin_call(s):                                         # C/S at any spot, for nudging
    a = (log(s / K) + btc_world * T) / v
    return exp(-rf * T) * N(a) - K / s * exp(-rd * T) * N(a - v)
nudged = S * (coin_call(S + 1.0) - coin_call(S - 1.0)) / 2.0
line("same, S x slope of the coin price (BTC)", nudged)
assert abs(nudged - (delta_usd - c)) < 1e-7

# ---- the trap: average 1/S_T in the wrong world ----
inv_usd = simpson(lambda z: phi(z) / ST(z, usd_world))
inv_btc = simpson(lambda z: phi(z) / ST(z, btc_world))
line("F x average of 1/S_T, dollar world", F * inv_usd)
line("F x average of 1/S_T, coin world", F * inv_btc)
line("exp(sigma^2 T), the Jensen factor", exp(vol * vol * T))
line("fair inverse future price, coin world (USD)", 1 / inv_btc, ".2f")
line("wrong inverse future price, dollar world", 1 / inv_usd, ".2f")
assert abs(F * inv_usd - exp(vol * vol * T)) < 1e-9
assert abs(F * inv_btc - 1) < 1e-9

# ---- try changing ----
def gk_coin(K_, vol_, T_):                                # coin-settled call in BTC
    a = (log(S / K_) + (rd - rf + 0.5 * vol_ * vol_) * T_) / (vol_ * sqrt(T_))
    return exp(-rf * T_) * N(a) - K_ / S * exp(-rd * T_) * N(a - vol_ * sqrt(T_))
assert abs(gk_coin(K, vol, T) - c) < 1e-15
line("try: vol 40%, coin-settled call (BTC)", gk_coin(K, 0.40, T))
line("try: strike 70000, coin-settled call (BTC)", gk_coin(70000.0, vol, T))
for F1 in (40000.0, 80000.0):
    line(f"try: 1 BTC + short 300 at {F1:.0f} (USD)", (1.0 - 300 * coin_pnl(F1)) * F1, ".2f")
line("try: 1 year, Jensen factor", exp(vol * vol * 1.0))
line("try: 1 year, wrong inverse future price", S * exp((rd - rf) * 1.0) / exp(vol * vol * 1.0), ".2f")

# ---- chart: coin P&L of one long contract, in satoshis (1e-8 BTC) ----
xs = [50000.0 + 2500.0 * i for i in range(9)]
row("chart, exit price", xs)
row("chart, inverse (sat)", [coin_pnl(x) * 1e8 for x in xs])
row("chart, straight (sat)", [Q * (x - F0) / F0 ** 2 * 1e8 for x in xs])
print("ALL CHECKS PASS")
