# Forward price by cash and carry -- the check behind the card.  Standard
# library only, and nothing imported that already holds the answer: the random
# numbers and the integrator are written out here.  Acme trades at 100.00, the
# bank charges and pays 5 percent, the share yields 2 percent, delivery is one
# year out.  Four roads reach the same delivery price.
from math import cos, exp, log, pi, sqrt

S, R, Q, T = 100.0, 0.05, 0.02, 1.0     # spot, bank rate, dividend yield, years
SIGMA, STEPS = 0.20, 365                # jumpiness and days, for the day-by-day road
DIV, T_DIV = 2.00, 0.5                  # a known cash dividend, paid at six months
HIGH, LOW = 105.00, 101.00              # two off-market delivery quotes

def forward(s, r, q, t):                # road 1: the formula
    return s * exp((r - q) * t)

class Rng:                              # a 64-bit linear congruential generator
    def __init__(self, seed):
        self.s = seed & 0xFFFFFFFFFFFFFFFF
    def unit(self):                     # a fresh number strictly inside (0, 1)
        self.s = (self.s * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return ((self.s >> 11) + 0.5) / 9007199254740992.0
    def normal(self):                   # Box-Muller: two flat draws make one bell draw
        return sqrt(-2.0 * log(self.unit())) * cos(2.0 * pi * self.unit())

def funded_trade(seed):
    """Road 2: the funded purchase, run day by day down one random share path.
    Trade A buys e^-qT shares and spends each dividend on more shares.  Trade B
    buys one whole share and banks each dividend instead.  Both borrow what they
    spend.  Returns where the share ended and the delivery price that leaves
    each trade holding exactly nothing at the end."""
    dt, rng, price = T / STEPS, Rng(seed), S
    shares, loan_a = exp(-Q * T), exp(-Q * T) * S
    loan_b, bank = S, 0.0
    for _ in range(STEPS):
        price *= exp((R - Q - 0.5 * SIGMA * SIGMA) * dt + SIGMA * sqrt(dt) * rng.normal())
        paid = exp(Q * dt) - 1.0                  # the day's dividend, per share held
        cash = shares * price * paid              # what trade A collects that day
        shares += cash / price                    # spent on more shares at that day's price
        bank = bank * exp(R * dt) + price * paid  # trade B's dividend, left at the bank
        loan_a *= exp(R * dt)
        loan_b *= exp(R * dt)
    return price, loan_a / shares, loan_b - bank

def simpson(f, a, b, n):                # the integrator, written out
    h = (b - a) / n
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return total * h / 3.0

def risk_neutral_average(sigma, n=40000):
    """Road 3: the average share price on delivery day when the share is taken
    to grow at the bank rate less its yield.  The bell curve is written out."""
    drift = (R - Q - 0.5 * sigma * sigma) * T
    def f(z):
        return S * exp(drift + sigma * sqrt(T) * z) * exp(-0.5 * z * z) / sqrt(2.0 * pi)
    return simpson(f, -10.0, 10.0, n)

F = forward(S, R, Q, T)                                      # road 1
F_none = forward(S, R, 0.0, T)
prepaid = S * exp(-Q * T)
repay = prepaid * exp(R * T)
pv_div = DIV * exp(-R * T_DIV)
F_cash = (S - pv_div) * exp(R * T)                           # road 1, known cash income
F_cash_ledger = S * exp(R * T) - DIV * exp(R * (T - T_DIV))  # road 4, the dated ledger
paths = [funded_trade(s) for s in (20260914, 7, 4242424242)]
finals, reinvested, banked = [list(c) for c in zip(*paths)]
rn = [risk_neutral_average(v) for v in (0.10, 0.20, 0.50)]
cc_T, rcc_T = HIGH - repay, repay - LOW
cc_now, rcc_now = cc_T * exp(-R * T), rcc_T * exp(-R * T)
years = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
curve_q = [forward(S, R, Q, y) for y in years]
curve_0 = [forward(S, R, 0.0, y) for y in years]
levels = [0.0, 0.02, 0.05, 0.08]
by_yield = [forward(S, R, y, T) for y in levels]
by_rate = [forward(S, x, Q, T) for x in levels]

def row(name, value):
    print(f"{name:<44}{value:>14.6f}")

print(f"Acme spot {S:.2f}, bank rate {R:.0%}, dividend yield {Q:.0%}, delivery in {T:.0f} year")
row("1 formula   F = S e^((r-q)T)", F)
for i, seed in enumerate((20260914, 7, 4242424242)):
    print(f"2 funded trade, day by day, path {i + 1:d} (seed {seed:d})")
    row("    share ended at", finals[i])
    row("    break-even delivery, dividends reinvested", reinvested[i])
    row("    break-even delivery, dividends banked", banked[i])
for v, a in zip((0.10, 0.20, 0.50), rn):
    row(f"3 average share price at delivery, sigma {v:.2f}", a)
row("prepaid forward   S e^-qT", prepaid)
row("carried to delivery, S e^-qT e^rT", repay)
row("no income at all, F = S e^rT", F_none)
print("known cash dividend of 2.00 at six months:")
row("    present value of the dividend", pv_div)
row("    1 formula   F = (S - I) e^rT", F_cash)
row("    4 dated ledger, dividend lent to delivery", F_cash_ledger)
print(f"cash-and-carry against a quote of {HIGH:.2f}:")
row("    shares bought today", prepaid / S)
row("    borrowed today", prepaid)
row("    repaid on delivery day", repay)
row("    profit on delivery day", cc_T)
row("    profit today", cc_now)
print(f"reverse cash-and-carry against a quote of {LOW:.2f}:")
row("    profit on delivery day", rcc_T)
row("    profit today", rcc_now)
print("what breaks if a piece goes missing:")
row("    income forgotten", F_none)
row("    income added, not subtracted", S * exp((R + Q) * T))
row("    cash dividend taken at face value", (S - DIV) * exp(R * T))
row("    simple interest, not compounded", S * (1.0 + (R - Q) * T))
row("    discounted back instead of grown", S * exp(-(R - Q) * T))
print()
print(f"{'chart, years to delivery':<38}" + "".join(f"{y:>9.0f}" for y in years))
print(f"{'chart, forward with the 2% yield':<38}" + "".join(f"{v:>9.2f}" for v in curve_q))
print(f"{'chart, forward with no income':<38}" + "".join(f"{v:>9.2f}" for v in curve_0))
print(f"{'bars, dividend yield 0/2/5/8 percent':<38}" + "".join(f"{v:>9.2f}" for v in by_yield))
print(f"{'bars, bank rate 0/2/5/8 percent':<38}" + "".join(f"{v:>9.2f}" for v in by_rate))

assert abs(F - 103.045453395352) < 1e-9,           "the delivery price quoted on the card"
assert abs(F_none - 105.127109637602) < 1e-9,      "the same share with no income"
assert abs(F_cash - 103.076479396554) < 1e-9,      "the known cash dividend version"
assert abs(F_cash_ledger - F_cash) < 1e-9,         "dated ledger vs the cash-income formula"
assert all(abs(b - F) < 1e-9 for b in reinvested), "the day-by-day road lands on the formula"
assert max(reinvested) - min(reinvested) < 1e-9,   "and does not care which path the share took"
assert max(finals) - min(finals) > 10.0,           "though the three paths end far apart"
assert max(banked) - min(banked) > 0.01,           "banking the dividends does not hedge"
assert all(abs(a - F) < 1e-6 for a in rn),         "three volatilities, one average"
assert abs(cc_T - (HIGH - F)) < 1e-9,              "the trade nets exactly the mispricing"
assert abs(rcc_T - (F - LOW)) < 1e-9,              "and so does the trade run backwards"
print("ALL CHECKS PASS")
