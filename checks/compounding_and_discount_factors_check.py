# Compounding and discount factors -- the check behind the card.  Nothing is
# imported: the exponential and the natural logarithm are built here from their
# own series, so no library hands back the answer.  The money is a 1,000 bill
# due in five years at a 5 percent annual yield, and the shelf's 1,000
# five-year bond paying a 6 percent coupon, priced at that same yield.
FACE, COUPON, YEARS, R1 = 1000.0, 60.0, 5, 0.05

def my_exp(x):                                # e^x: halve the argument, sum the series, square back
    k = 0
    while abs(x) > 0.5:
        x, k = x / 2.0, k + 1
    term, total, n = 1.0, 1.0, 1
    while abs(term) > 1e-18:
        term *= x / n
        total += term
        n += 1
    for _ in range(k):
        total *= total
    return total

def ln_core(x):                               # ln x from the series in z = (x - 1) / (x + 1)
    z = (x - 1.0) / (x + 1.0)
    z2, term, total, n = z * z, z, 0.0, 1
    while abs(term) > 1e-18:
        total += term / n
        term *= z2
        n += 2
    return 2.0 * total

LN2 = ln_core(2.0)

def my_ln(x):                                 # halved into the range where the series is fast
    k = 0
    while x > 1.5:
        x, k = x / 2.0, k + 1
    while x < 0.75:
        x, k = x * 2.0, k - 1
    return ln_core(x) + k * LN2

def growth(factor, periods):                  # one multiply per period; no power function used
    out = 1.0
    for _ in range(periods):
        out *= factor
    return out

def row(name, value):
    print(f"{name:<46}{value:>14}")

# ---- five roads to one discount factor for five years ----
d_annual = 1.0 / growth(1.0 + R1, YEARS)                       # 1: one multiply a year
num, den = 20 ** YEARS, 21 ** YEARS                            # 2: exact whole numbers
d_exact = ((num * 10 ** 12 + den // 2) // den) / 10 ** 12
rc = my_ln(1.0 + R1)                                           # 3: the continuous quote
d_cont = my_exp(-rc * YEARS)
r2 = 2.0 * (my_exp(rc / 2.0) - 1.0)                            # 4: twice a year
d_semi = 1.0 / growth(1.0 + r2 / 2.0, 2 * YEARS)
r12 = 12.0 * (my_exp(rc / 12.0) - 1.0)
r365 = 365.0 * (my_exp(rc / 365.0) - 1.0)                      # 5: every day
d_daily = 1.0 / growth(1.0 + r365 / 365.0, 365 * YEARS)
deposit = FACE * d_annual
ledger = deposit                                               # the deposit grown forward again
for _ in range(YEARS):
    ledger *= 1.0 + R1
rate_back = -my_ln(d_annual) / YEARS                           # the factor read back as a rate

# ---- the shelf's bond, two ways ----
dfs = [1.0 / growth(1.0 + R1, t) for t in range(1, YEARS + 1)]
flows = [COUPON] * (YEARS - 1) + [COUPON + FACE]
price_sum = 0.0
for c, d in zip(flows, dfs):
    price_sum += c * d
annuity = (1.0 - dfs[-1]) / R1                                 # coupons as one annuity factor
price_closed = COUPON * annuity + FACE * dfs[-1]
pulls = [COUPON * (1.0 - 1.0 / growth(1.0 + R1, n)) / R1 + FACE / growth(1.0 + R1, n)
         for n in range(YEARS, -1, -1)]

# ---- the two forces, and the curve ----
by_maturity = [FACE / growth(1.0 + R1, t) for t in (1, 2, 5, 10, 30)]
by_rate = [FACE / growth(1.0 + r, YEARS) for r in (0.0, 0.02, 0.05, 0.08, 0.12)]
curve5 = [FACE / growth(1.05, t) for t in range(11)]
curve8 = [FACE / growth(1.08, t) for t in range(11)]

# ---- what breaks if the convention is read wrong ----
grow5 = growth(1.0 + R1, YEARS)
wrongs = [("5 percent read as a continuous rate", FACE * my_exp(-R1 * YEARS)),
          ("nominal 5 percent, paid twice a year", FACE / growth(1.0 + R1 / 2.0, 2 * YEARS)),
          ("simple interest, 1 + 0.05 x 5", FACE / (1.0 + R1 * YEARS)),
          ("time counted in months, not years", FACE / growth(1.0 + R1, 12 * YEARS))]

print("a 1,000 bill due in five years, quoted at 5 percent a year")
for name, r in (("quoted once a year", R1), ("the same money, twice a year", r2),
                ("the same money, monthly", r12), ("the same money, daily", r365),
                ("the same money, continuously", rc)):
    row(name, f"{100.0 * r:.6f} percent")
print()
print("five roads to the discount factor D(5):")
for name, d in (("1 annual, 1.05 multiplied in five times", d_annual),
                ("2 whole numbers, 20^5 / 21^5", d_exact),
                ("3 continuous, e to the minus 4.879016% x 5", d_cont),
                ("4 semi-annual, ten half-years", d_semi),
                ("5 daily, 1825 days", d_daily)):
    row(name, f"{d:.10f}")
row("deposit today for the 1,000 bill", f"{deposit:.2f}")
row("that deposit grown five years at 5 percent", f"{ledger:.2f}")
row("the factor read back as a rate, -ln(D) / 5", f"{100.0 * rate_back:.6f} percent")
print()
print("the shelf's bond: 1,000 face, 6 percent coupon, five years, yield 5 percent")
print("  year    cashflow    discount factor     present value")
for t, (c, d) in enumerate(zip(flows, dfs), start=1):
    print(f"  {t:>4}  {c:>10.2f}       {d:.10f}      {c * d:>11.2f}")
row("price, cashflow by cashflow", f"{price_sum:.2f}")
row("price, coupon annuity plus discounted face", f"{price_closed:.2f}")
print()
print("pull to par, 5 years left down to 0: " + "  ".join(f"{p:.2f}" for p in pulls))
print()
print("deposit funding 1,000 by maturity 1 2 5 10 30 years: "
      + " ".join(f"{v:.2f}" for v in by_maturity))
print("deposit funding 1,000 by rate 0 2 5 8 12 percent:    "
      + " ".join(f"{v:.2f}" for v in by_rate))
print()
print("chart, years from now       " + " ".join(f"{t:>7}" for t in range(11)))
print("chart, deposit at 5 percent " + " ".join(f"{v:>7.2f}" for v in curve5))
print("chart, deposit at 8 percent " + " ".join(f"{v:>7.2f}" for v in curve8))
print()
print("what breaks, each deposit then grown at the true 5 percent:")
for name, v in wrongs:
    print(f"  {name:<40} deposit {v:>8.2f}   grows to {v * grow5:>8.2f}")

assert abs(d_annual - d_exact) < 1e-11,        "floats against exact whole-number arithmetic"
assert abs(d_cont - d_annual) < 1e-12,         "the continuous road against the annual one"
assert abs(d_daily - d_annual) < 1e-12,        "1825 daily steps against five yearly ones"
assert abs(ledger - FACE) < 1e-9,              "the deposit grown forward must land on the bill"
assert abs(price_sum - price_closed) < 1e-9,   "cashflow by cashflow against the annuity form"
assert abs(rate_back - rc) < 1e-14,            "the rate read back out of the factor"
assert abs(my_ln(my_exp(0.37)) - 0.37) < 1e-14, "the series exp and ln must undo each other"
d_neg = 1.0 / growth(1.0 - 0.02, YEARS)        # a shrinking account: the rate is minus 2 percent
assert all(a > b for a, b in zip(by_rate, by_rate[1:])), "a higher rate must give a smaller factor"
assert d_neg > 1.0,                            "a negative rate lifts the factor above one"
print("ALL CHECKS PASS")
