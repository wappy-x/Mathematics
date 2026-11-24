# Index lag and seasonality -- the check behind the card.  Standard library only.
# Reference CPI on 15 Apr 2027 from January 300.0 and February 301.2 (invented levels).
# Curve: 1-year zero-coupon swap rate 2.50%, plus twelve monthly seasonal factors that sum to zero.
from math import exp, log

def days_in(n):                          # month n counts from Jan 2027 = 1
    y, m = 2027 + (n - 1) // 12, (n - 1) % 12 + 1
    if m == 2:
        return 29 if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0) else 28
    return 30 if m in (4, 6, 9, 11) else 31

def ref_cpi(m0, m1, day, days):          # CPI in thousandths -> reference CPI in units of 0.00001
    formula = m0 * days + (day - 1) * (m1 - m0)     # road 1: the Treasury formula
    walk = m0 * days
    for _ in range(day - 1):                         # road 2: one day at a time
        walk += m1 - m0
    assert walk == formula
    return (formula * 1000 // days + 5) // 10        # truncate to six decimals, round to five

SEAS = [0.30, 0.20, 0.15, 0.10, 0.03, 0.02, -0.08, -0.05, -0.02, -0.10, -0.25, -0.30]  # % a month, Jan..Dec
K1, DAY, N = 0.025, 15, 10_000_000
def s(n, table=SEAS):                    # seasonal factor of month n, as a log change
    return table[(n - 1) % 12] / 100

def window_A(n, h, lag=3, table=SEAS):   # road A: the weights formula, 15th of month n to 15th of n+h
    w0, w1 = (DAY - 1) / days_in(n), (DAY - 1) / days_in(n + h)
    inner = sum(s(j, table) for j in range(n - lag + 2, n + h - lag + 1))
    return (1 - w0) * s(n - lag + 1, table) + inner + w1 * s(n + h - lag + 1, table)

def window_B(n, h):                      # road B: whole CPI months, read through the Treasury rule
    q = (1 + K1) ** (1 / 12)
    sig, level = {-24: 0.0}, {}
    for j in range(-23, 40):             # seasonal level: running total of the factors
        sig[j] = sig[j - 1] + s(j)
    def ref(n_, with_season):
        lev = lambda j: q ** j * (exp(sig[j]) if with_season else 1.0)
        w = (DAY - 1) / days_in(n_)
        return lev(n_ - 3) + w * (lev(n_ - 2) - lev(n_ - 3))
    seasonal = ref(n + h, True) / ref(n, True)
    trend = ref(n + h, False) / ref(n, False)
    return log(seasonal / trend)

def rate(S, T):                          # zero-coupon rate for a term of T years
    return (1 + K1) * exp(S / T) - 1

# ---- the reference index on 15 April 2027 ----
R0 = ref_cpi(300000, 301200, 15, 30) / 1e5
R0_flat = ref_cpi(300000, 301200, 1, 30) / 1e5      # no interpolation: January alone
R0_15 = ref_cpi(300000, 301200, 16, 30) / 1e5       # 15 days counted, not 14
assert abs(R0 - (300.0 + 14 / 30 * 1.2)) < 1e-9

# ---- the seasonal factors ----
assert abs(sum(SEAS)) < 1e-12
S_A, S_B = window_A(4, 3), window_B(4, 3)
k3, k3_B = rate(S_A, 0.25), rate(S_B, 0.25)
assert abs(k3 - k3_B) < 1e-5                         # two roads agree within 0.1 bp
parts = [(1 - 14 / 30) * s(2), s(3), s(4), 14 / 31 * s(5)]
assert abs(sum(parts) - S_A) < 1e-12                 # hand weights match the general formula
k1_A = rate(window_A(4, 12), 1.0)
assert abs(k1_A - K1) < 1e-12                        # 1-year point untouched, road A
shifts = [rate(window_B(n, 12), 1.0) - K1 for n in range(4, 16)]
assert all(abs(x) < 1e-12 for i, x in enumerate(shifts) if i != 10)   # every start but Feb 2028
assert abs(shifts[10] - ((1 + K1) * exp(s(12) * (14 / 28 - 14 / 29)) - 1 - K1)) < 1e-8  # leap day: Dec at 14/29, 14/28
R_jul = R0 * (1 + K1) ** 0.25 * exp(S_A)
assert abs((R_jul / R0) ** 4 - 1 - k3) < 1e-12

# ---- money on a 10,000,000 dollar 3-month swap, paid 15 July ----
infl_leg = N * (R_jul / R0 - 1)
fixed_naive = N * ((1 + K1) ** 0.25 - 1)
fixed_fair = N * ((1 + k3) ** 0.25 - 1)
assert abs(infl_leg - fixed_fair) < 1e-6

# ---- what breaks ----
k3_nolag = rate(window_A(4, 3, lag=0), 0.25)
bad = SEAS[:11] + [0.0]                              # December dropped: factors sum to +0.30%
k1_bad = rate(window_A(4, 12, table=bad), 1.0)
assert abs(k1_bad - ((1 + K1) * exp(0.003) - 1)) < 1e-12

def row(label, v, d=4): print(f"{label:<46} {v:.{d}f}")
row("reference CPI 15 Apr 2027", R0, 5)
row("  wrong: January alone, no interpolation", R0_flat, 5)
row("  wrong: 15/30 of the way, not 14/30", R0_15, 5)
print("seasonal factors Jan..Dec (%)", " ".join(f"{x:+.2f}" for x in SEAS))
row("sum of the twelve factors (%)", sum(SEAS) * 100 + 0.0, 2)
row("weight 16/30 x Feb factor (%)", parts[0] * 100)
row("Mar factor (%)", parts[1] * 100); row("Apr factor (%)", parts[2] * 100)
row("weight 14/31 x May factor (%)", parts[3] * 100)
row("S, road A: weights formula (%)", S_A * 100, 6)
row("S, road B: whole CPI months (%)", S_B * 100, 6)
row("trend factor 1.025^0.25", (1 + K1) ** 0.25, 6)
row("seasonal factor exp(S)", exp(S_A), 6)
row("projected reference CPI 15 Jul 2027", R_jul, 4)
row("3-month breakeven, no seasonality (%)", K1 * 100, 2)
row("3-month breakeven, road A (%)", k3 * 100)
row("3-month breakeven, road B (%)", k3_B * 100)
row("  road A minus road B (bp)", (k3 - k3_B) * 1e4, 2)
row("S / T over 3 months (%)", S_A / 0.25 * 100, 2)
row("same S spread over one year, rate (%)", rate(S_A, 1.0) * 100, 2)
row("  gap from seasonality (bp)", (k3 - K1) * 1e4, 1)
row("1-year breakeven with seasonality (%)", k1_A * 100)
row("largest 1-year shift, 11 start months (bp)", max(abs(x) for i, x in enumerate(shifts) if i != 10) * 1e4, 1)
row("1-year shift, 15 Feb 2028 start (bp)", shifts[10] * 1e4, 2)
row("inflation leg, 10m notional ($)", infl_leg, 2)
row("fixed leg struck at 2.50% ($)", fixed_naive, 2)
row("fixed leg struck at the fair rate ($)", fixed_fair, 2)
row("  loss from ignoring seasonality ($)", infl_leg - fixed_naive, 2)
row("wrong: no lag, factors May..Aug (%)", k3_nolag * 100)
row("wrong: December dropped, 1-year rate (%)", k1_bad * 100)
print("chart: 3-month breakeven (%) starting the 15th of Apr 2027 .. Mar 2028")
print(" ".join(f"{rate(window_A(n, 3), 0.25) * 100:.2f}" for n in range(4, 16)))
print("ALL CHECKS PASS")
