# Payoffs and positions -- the check behind the card.  Nothing is imported that
# already knows an answer: the root finder is written out here, and the only
# library call is exp, for the discount and growth factors.  One share of Acme,
# strike 100, European exercise one year from today.  Payoffs are built four ways
# -- the positive-part formula, the holder's ledger, the writer's ledger and a
# stack of thin cash bets -- and every break-even twice, by bisection and algebra.
from math import exp

K = 100.0                                     # the strike written on the tickets
CALL, PUT = 9.227005508154, 6.330080627550    # today's quoted premiums, one share
S0, R, Q, T = 100.0, 0.05, 0.02, 1.0          # Acme today, rates, dividend, years
STRADDLE = CALL + PUT                         # buying the call and the put together
GRID = [60.0 + 10.0 * i for i in range(9)]    # the nine prices the table shows
FINE = [0.25 * i for i in range(801)]         # 801 prices, 0.00 to 200.00, across the bend


def pos(x):                                   # the positive part: a gain kept, a loss dropped
    return x if x > 0.0 else 0.0


def by_formula(s, kind):                      # road 1: the payoff as a positive part
    if kind == "forward":
        return s - K
    if kind == "call":
        return pos(s - K)
    return pos(K - s)


def by_ledger(s, kind):                       # road 2: the cash the holder actually moves
    if kind == "forward":
        return s - K                          # no choice: hand over K, hold a share worth s
    if kind == "call":
        use = s - K                           # hand over K, sell the share for s
    else:
        use = K - s                           # buy a share for s, hand it over for K
    return use if use > 0.0 else 0.0          # or walk away, and no cash moves at all


def by_writer(s):                             # road 3: the same call from the writer's side
    called = by_ledger(s, "call") > 0.0       # the holder exercises only when it pays
    return (K - s) if called else 0.0         # deliver a share worth s, receive the strike


def by_digitals(s, n=100000, hi=200.0):
    # road 4: a call is a stack of thin bets, one for each price level above the
    # strike, each paying h if Acme clears that level.  No positive part is used.
    h = (hi - K) / n
    total = 0.0
    for i in range(n):
        if s > K + (i + 0.5) * h:
            total += h
    return total


def bisect(g, lo, hi, steps=200):             # our own root finder, halving an interval
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if (g(lo) > 0.0) == (g(mid) > 0.0):
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def yn(claim):
    return "yes" if claim else "no"


call_pay = [by_formula(s, "call") for s in GRID]
put_pay = [by_formula(s, "put") for s in GRID]
fwd_pay = [by_formula(s, "forward") for s in GRID]
digital = [by_digitals(s) for s in GRID]
rows = [
    ("long forward", fwd_pay),
    ("long call", call_pay),
    ("long put", put_pay),
    ("short call, the writer's ledger", [by_writer(s) for s in GRID]),
    ("call minus put", [c - p for c, p in zip(call_pay, put_pay)]),
    ("long call, from thin cash bets", digital),
    ("straddle, call plus put", [c + p for c, p in zip(call_pay, put_pay)]),
    ("long call profit, less 9.23", [v - CALL for v in call_pay]),
    ("straddle profit, less 15.56", [c + p - STRADDLE for c, p in zip(call_pay, put_pay)]),
]
print("One share of Acme, strike 100.  Acme's price on expiry day runs across.")
print(f"{'Acme at expiry':<32}" + "".join(f"{s:>8.2f}" for s in GRID))
for name, vals in rows:
    print(f"{name:<32}" + "".join(f"{v:>8.2f}" for v in vals))

ledger_ok = all(by_formula(s, k) == by_ledger(s, k)
                for s in FINE for k in ("forward", "call", "put"))
identity_ok = all(abs(by_formula(s, "call") - by_formula(s, "put") - (s - K)) < 1e-12 for s in FINE)
writer_ok = all(by_formula(s, "call") + by_writer(s) == 0.0 for s in FINE)
digital_gap = max(abs(d - c) for d, c in zip(digital, call_pay))
print()
print(f"{'holder ledger matches the formula, 801 prices':<50}{yn(ledger_ok):>10}")
print(f"{'call minus put equals the forward, 801 prices':<50}{yn(identity_ok):>10}")
print(f"{'writer ledger mirrors the holder, 801 prices':<50}{yn(writer_ok):>10}")
print(f"{'largest gap, thin-bet call against the formula':<50}{digital_gap:>10.6f}")

be_call = bisect(lambda s: by_formula(s, "call") - CALL, K, 200.0)
be_low = bisect(lambda s: by_formula(s, "call") + by_formula(s, "put") - STRADDLE, 0.0, K)
be_high = bisect(lambda s: by_formula(s, "call") + by_formula(s, "put") - STRADDLE, K, 200.0)
carried = CALL * exp(R * T)
priced = [
    ("call premium quoted today", CALL),
    ("put premium quoted today", PUT),
    ("call minus put, in today's money", CALL - PUT),
    ("  S e^-qT - K e^-rT", S0 * exp(-Q * T) - K * exp(-R * T)),
    ("long call break-even, by bisection", be_call),
    ("  the same, strike plus premium", K + CALL),
    ("premium carried to expiry at 5 percent", carried),
    ("  break-even once the premium is financed", K + carried),
    ("straddle cost today", STRADDLE),
    ("straddle break-even below, by bisection", be_low),
    ("  the same, strike minus cost", K - STRADDLE),
    ("straddle break-even above, by bisection", be_high),
    ("  the same, strike plus cost", K + STRADDLE),
]
print()
for name, v in priced:
    print(f"{name:<42}{v:>14.6f}")

print()
print(f"mistake 1, payoff read as profit, Acme at 100: {by_formula(100.0, 'call'):.2f}, "
      f"when the position is down {CALL:.2f}")
print(f"mistake 2, break-even read at the strike: {K:.2f}, not {K + CALL:.2f}")
print(f"mistake 3, premium never carried to expiry: {K + CALL:.2f}, not {K + carried:.2f}")
print(f"mistake 4, short call called a capped loss: {by_writer(140.0):.2f} "
      f"at 140, and falling")
print(f"mistake 5, put's gap written the call's way, Acme at 90: "
      f"{by_formula(90.0, 'call'):.2f}, not {by_formula(90.0, 'put'):.2f}")
print(f"mistake 6, straddle break-evens from one premium: {K - CALL:.2f} and {K + CALL:.2f}")
assert ledger_ok and identity_ok and writer_ok       # four roads, one set of payoffs
assert digital_gap < 1e-9                            # thin bets rebuild the call's payoff
assert abs(be_call - (K + CALL)) < 1e-9              # bisection against the algebra
assert abs(be_low - (K - STRADDLE)) < 1e-9
assert abs(be_high - be_low - 2.0 * STRADDLE) < 1e-9
assert abs((CALL - PUT) - (S0 * exp(-Q * T) - K * exp(-R * T))) < 1e-9
print("ALL CHECKS PASS")
