# Covered interest parity -- the check behind the card.  Standard library only.
# EURUSD, quoted in dollars per euro.  Every number on the card is printed here.
# Road 1: the formula, with math.exp.  Road 2: never calls math.exp; it grows
# both deposits with a hand-summed series and finds, by bisection, the quote at
# which the cash-and-carry ledger nets zero.  Road 3: money-market quotes.
# Road 4: the three-month forward, carried nine more months.
from math import exp, log

def ex(x):                                    # e^x as 1 + x + x^2/2! + ... (roads 2 and 3)
    term, total, k = 1.0, 1.0, 0
    while abs(term) > 1e-18:
        k += 1; term *= x / k; total += term
    return total

def forward(S, rd, rf, T):                    # road 1: covered interest parity
    return S * exp((rd - rf) * T)

def sell_ledger(S, rd, rf, T, Fq):            # borrow dollars, buy 1 euro, deposit it, sell the euros forward
    euros_at_T = ex(rf * T)
    dollars_in = Fq * euros_at_T
    loan_due = S * ex(rd * T)
    return dollars_in - loan_due, euros_at_T, dollars_in, loan_due

def buy_ledger(S, rd, rf, T, Fq):             # borrow 1 euro, sell it spot, deposit dollars, buy the euros back forward
    dollars_at_T = S * ex(rd * T)
    dollars_out = Fq * ex(rf * T)
    return dollars_at_T - dollars_out, dollars_at_T, dollars_out

def bisect(f, lo, hi):                        # root finder: halve the bracket until it is a point
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

S, rd, rf, T = 1.10, 0.05, 0.03, 1.0          # dollars per euro; dollar rate; euro rate; years
F = forward(S, rd, rf, T)
F_led = bisect(lambda q: sell_ledger(S, rd, rf, T, q)[0], 0.5, 2.0)
tau = 365 / 360                               # one year of 365 days, counted actual/360
Rd_mm, Rf_mm = (ex(rd * T) - 1) / tau, (ex(rf * T) - 1) / tau
F_mm = S * (1 + Rd_mm * tau) / (1 + Rf_mm * tau)
F_3m = forward(S, rd, rf, 0.25)
F_roll = F_3m * ex((rd - rf) * 0.75)

p_hi, eur_T, usd_in, loan = sell_ledger(S, rd, rf, T, 1.15)
p_lo, usd_T, usd_out = buy_ledger(S, rd, rf, T, 1.10)
cf_hi, cf_lo = exp(rf * T) * (1.15 - F), exp(rf * T) * (F - 1.10)

# a desk quotes money-market rates: 5.00% dollars, 3.00% euros, actual/360, 365 days
F_desk = S * (1 + 0.05 * tau) / (1 + 0.03 * tau)
rd_c, rf_c = log(1 + 0.05 * tau) / T, log(1 + 0.03 * tau) / T
unhedged = lambda ST: ST * ex(rf * T) - S * ex(rd * T)       # buy and deposit a euro, no forward
breakeven = bisect(unhedged, 0.5, 2.0)

rows = [
    ("S spot, dollars per euro", S), ("carry (rd - rf) T", (rd - rf) * T), ("carry factor e^(rd-rf)T", exp((rd - rf) * T)),
    ("1 formula F", F), ("2 ledger nets zero at", F_led), ("3 money-market road", F_mm), ("4 3M carried to 1Y", F_roll),
    ("  forward points, pips", (F - S) * 1e4), ("  3M forward", F_3m), ("  3M points, pips", (F_3m - S) * 1e4),
    ("  dollars today, route A", F * exp(-rd * T)), ("  dollars today, route B", S * exp(-rf * T)),
    ("  Rd money-market, act/360", Rd_mm), ("  Rf money-market, act/360", Rf_mm),
    ("at 1.15: euros at T", eur_T), ("  dollars from forward", usd_in), ("  dollar loan due", loan),
    ("  seller's profit per euro", p_hi), ("  closed form e^rfT(Fq-F)", cf_hi), ("  on EUR 10m", p_hi * 1e7),
    ("at 1.10: dollar deposit at T", usd_T), ("  dollars paid on forward", usd_out),
    ("  buyer's profit per euro", p_lo), ("  closed form e^rfT(F-Fq)", cf_lo), ("  on EUR 10m", p_lo * 1e7),
    ("unhedged breakeven landing", breakeven),
    ("desk: F from 5%/3% act/360", F_desk), ("  rd continuous", rd_c), ("  rf continuous", rf_c),
    ("  F from continuous rates", forward(S, rd_c, rf_c, T)),
    ("wrong: drop rf", forward(S, rd, 0.0, T)), ("wrong: drop rd", forward(S, 0.0, rf, T)),
    ("wrong: rates flipped", forward(S, rf, rd, T)), ("wrong: desk rates in exponent", forward(S, 0.05, 0.03, T)),
    ("  gap to desk F, pips", (forward(S, 0.05, 0.03, T) - F_desk) * 1e4),
    ("wrong: T dropped, 3M deal", forward(S, rd, rf, 1.0)),
    ("try: rf = 0.07", forward(S, rd, 0.07, T)), ("  points, pips", (forward(S, rd, 0.07, T) - S) * 1e4),
    ("try: rd = rf = 0.04", forward(S, 0.04, 0.04, T)), ("try: T = 5", forward(S, rd, rf, 5.0)),
    ("try: one pip rich, EUR 10m", sell_ledger(S, rd, rf, T, F + 1e-4)[0] * 1e7),
]
for name, v in rows:
    print(f"{name:<30} {v:>16.6f}")
print("chart, years to delivery    " + " ".join(f"{t:7d}" for t in range(6)))
print("chart, forward F(T)         " + " ".join(f"{forward(S, rd, rf, t):7.2f}" for t in range(6)))
spots = [1.00 + 0.05 * i for i in range(6)]
print("chart, landing spot         " + " ".join(f"{s:7.2f}" for s in spots))
print("chart, unhedged, cents      " + " ".join(f"{100 * unhedged(s):7.2f}" for s in spots))
print("chart, hedged at 1.15, cents" + " ".join(f"{100 * p_hi:7.2f}" for s in spots))

assert abs(F - 1.122221) < 5e-7, "formula against the house number"
assert abs(F_led - F) < 1e-12, "ledger road (series e^x, bisection) lands on the formula"
assert abs(F_mm - F) < 1e-12, "money-market road lands on the formula"
assert abs(F_roll - F) < 1e-12, "3M forward carried nine months lands on the 1Y forward"
assert abs(p_hi - cf_hi) < 1e-12, "seller's ledger against the closed form"
assert abs(p_lo - cf_lo) < 1e-12, "buyer's ledger against the closed form"
assert abs(breakeven - F) < 1e-12, "unhedged trade breaks even at the forward"
assert abs(forward(S, rd_c, rf_c, T) - F_desk) < 1e-12, "desk quotes converted to continuous"
assert abs(F_desk - 1.121647) < 5e-7 and abs(F_3m - 1.105514) < 5e-7, "desk and 3M house numbers"
assert abs(p_hi - 0.028625) < 5e-7 and abs(p_lo - 0.022898) < 5e-7, "ledger profits at 1.15 and 1.10"
print("ALL CHECKS PASS")
