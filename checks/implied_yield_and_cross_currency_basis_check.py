# Implied yield and cross-currency basis -- the check behind the card.  Standard library only.
# EURUSD quoted in dollars per euro.  Rates continuously compounded, as decimals; time in years.
# Road 1: the closed form rf = rd - ln(F/S)/T.
# Road 2: bisection on the parity formula itself, using exp only: no logarithm in it.
# Road 3: the cash ledger of borrowing dollars through the FX market, read off as a rate.
from math import exp, log

S, rd, rf_dep = 1.10, 0.05, 0.03          # spot, dollar deposit rate, euro deposit rate
PIP = 0.0001

def implied_rf(S, F, rd, T):              # road 1: parity run backwards
    return rd - log(F / S) / T

def implied_rd(S, F, rf, T):              # the same inverse, solved for the dollar rate
    return rf + log(F / S) / T

def bisect_rf(S, F, rd, T, lo=-1.0, hi=1.0):
    # road 2: the forward S e^{(rd - rf)T} falls as rf rises, so halve the bracket 200 times.
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if S * exp((rd - mid) * T) > F: lo = mid   # forward too high: euro rate must be higher
        else: hi = mid
    return 0.5 * (lo + hi)

def ledger(S, F, rf, T):
    # road 3: borrow one euro at the deposit rate, sell it at spot, buy the repayment forward.
    usd_now = S                                      # dollars in hand today
    usd_owed = exp(rf * T) * F                       # dollars needed at T to buy the euros owed
    return usd_now, usd_owed

def show(label, v, fmt="{:>14.6f}"):
    print(f"{label:<40}" + fmt.format(v))

# ---- the house forward, run backwards ----
F_house, F_house3m = S + 222.21 * PIP, S + 55.14 * PIP
r_house = implied_rf(S, F_house, rd, 1.0)
r_house3m = implied_rf(S, F_house3m, rd, 0.25)
show("house F, 1 year (+222.21 pips)", F_house)
show("  ln(F / S)", log(F_house / S))
show("  implied euro rate, %", 100 * r_house)
show("house F, 3 months (+55.14 pips)", F_house3m)
show("  implied euro rate, %", 100 * r_house3m)

# ---- two market quotes either side of fair, 1 year ----
cases = {}
for pips in (195.0, 249.0):
    F = S + pips * PIP
    r1, r2 = implied_rf(S, F, rd, 1.0), bisect_rf(S, F, rd, 1.0)
    usd_now, usd_owed = ledger(S, F, rf_dep, 1.0)
    synth_usd = log(usd_owed / usd_now)              # dollar rate paid through the FX route
    basis = r1 - rf_dep                              # the basis, Du-Tepper-Verdelhan sign
    cases[pips] = (F, r1, r2, synth_usd, basis, usd_owed)
    print()
    show(f"market +{pips:.0f} pips: F", F)
    show("  F / S", F / S)
    show("  ln(F / S)", log(F / S))
    show("  1 closed form, implied euro %", 100 * r1)
    show("  2 bisection, implied euro %", 100 * r2)
    show("  basis = implied - deposit, bp", 1e4 * basis, "{:>14.2f}")
    show("  3 ledger: dollars owed per euro", usd_owed)
    show("    synthetic dollar rate, %", 100 * synth_usd)
    show("    basis = 5% - synthetic, bp", 1e4 * (rd - synth_usd), "{:>14.2f}")
    show("  implied dollar rate at 3% euro, %", 100 * implied_rd(S, F, rf_dep, 1.0))

# ---- the trade a bank with spare dollars sees at +249, per euro and on EUR 10m ----
F249, usd_owed249 = cases[249.0][0], cases[249.0][5]
repay = S * exp(rd)                                  # borrowed dollars repaid at 5%
print()
show("euros owed at T per euro borrowed at 3%", exp(rf_dep))
show("+249: lend dollars via swap, receive", usd_owed249)
show("  repay the dollar loan", repay)
show("  profit per euro", usd_owed249 - repay)
show("  profit on EUR 10m", 1e7 * (usd_owed249 - repay), "{:>14.2f}")

# ---- what breaks, on the +249 quote ----
print()
show("wrong: sign flipped, rd + ln(F/S), %", 100 * (rd + log(F249 / S)))
show("wrong: 3M house, T dropped, %", 100 * (rd - log(F_house3m / S)))
show("wrong: points/spot, no log, %", 100 * (rd - (F249 - S) / S))
show("wrong: basis as deposit - implied, bp", 1e4 * (rf_dep - cases[249.0][1]), "{:>14.2f}")

# ---- try changing ----
print()
show("try: +700 pips, implied euro %", 100 * implied_rf(S, S + 700 * PIP, rd, 1.0))
show("try: F = S, implied euro %", 100 * implied_rf(S, S, rd, 1.0))
show("try: +249 over 2 years, implied %", 100 * implied_rf(S, F249, rd, 2.0))

# ---- one pip of noise, by tenor, around the house forward for that tenor ----
print()
for name, T in (("1 week", 7 / 365), ("1 month", 1 / 12), ("3 months", 0.25), ("1 year", 1.0)):
    Ft = S * exp((rd - rf_dep) * T)
    move = implied_rf(S, Ft, rd, T) - implied_rf(S, Ft + PIP, rd, T)
    show(f"bar, bp per pip, {name}", 1e4 * move, "{:>14.2f}")

# ---- chart: implied euro rate against the quoted points, 1 year ----
print()
grid = (150.0, 175.0, 195.0, 222.21, 249.0, 275.0, 300.0)
print("chart, points  " + " ".join(f"{p:7.2f}" for p in grid))
print("chart, euro %  " + " ".join(f"{100 * implied_rf(S, S + p * PIP, rd, 1.0):7.2f}" for p in grid))

# ---- uniqueness: the forward falls strictly as the euro rate rises, so one rate per forward ----
fwd = [S * exp((rd - r) * 1.0) for r in [-0.05 + 0.001 * i for i in range(201)]]
assert all(a > b for a, b in zip(fwd, fwd[1:])),          "forward must fall as the euro rate rises"
assert abs(r_house - rf_dep) < 5e-6,                      "house points give back 3% to the quote's precision"
assert abs(r_house3m - bisect_rf(S, F_house3m, rd, 0.25)) < 1e-12, "3-month closed form and bisection agree"
for F, r1, r2, synth, basis, _ in cases.values():
    assert abs(r1 - r2) < 1e-12,                          "closed form and bisection agree"
    assert abs((rd - synth) - basis) < 1e-12,             "ledger basis equals implied minus deposit"
    assert abs(S * exp((rd - r2) * 1.0) - F) < 1e-12,     "bisection's rate rebuilds the quoted forward"
assert cases[195.0][4] > 0 > cases[249.0][4],             "fewer points than fair: basis up; more: down"
print("ALL CHECKS PASS")
