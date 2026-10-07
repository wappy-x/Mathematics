# No arbitrage and the law of one price -- the check behind the card.  Only
# math.exp is imported, and nothing here is handed an option price.  Acme is
# 100.00 today and finishes the year at 130.00, 105.00 or 85.00; one dollar
# banked becomes e^0.05.  A note paying Acme's closing price trades at
# 100.00 x e^-0.02.  The call's price band is reached twice, by roads that find
# the copy different ways: a narrowing search, and exact two-scenario solves.
from math import exp

S0, K, QA, QB = 100.0, 100.0, 96.50, 99.00
STATES, NAMES = (130.0, 105.0, 85.0), ("high", "middle", "low")
R, D = exp(0.05), exp(-0.05)                  # a banked dollar; a dollar due at expiry
P = S0 * exp(-0.02)                           # the note: one Acme share, delivered at expiry
PAY = tuple(max(s - K, 0.0) for s in STATES)  # the call pays 30.00, 5.00, 0.00
HOUSE_CALL, HOUSE_PUT = 9.227005508154, 6.330080627550   # the shelf's quoted pair

def cost(a, b):                    # a notes bought today, b dollars due from the bank
    return a * P + b * D

def held(a, b, s):                 # what that copy holds at expiry if Acme ends at s
    return a * s + b

def ceiling_at(a):                 # cheapest copy holding a notes that never pays less
    return cost(a, max(PAY[i] - a * STATES[i] for i in range(3)))

def floor_at(a):                   # dearest copy holding a notes that never pays more
    return cost(a, min(PAY[i] - a * STATES[i] for i in range(3)))

def hunt(f, want_min, lo=-5.0, hi=5.0):        # road one: narrow in on the best copy
    for _ in range(200):                       # chop a third off the range each round
        m1, m2 = lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0
        if (f(m1) < f(m2)) == want_min:
            hi = m2
        else:
            lo = m1
    return f(0.5 * (lo + hi))

def matched(i, j):                 # road two: the copy matching the call in scenarios i, j
    a = (PAY[i] - PAY[j]) / (STATES[i] - STATES[j])
    return a, PAY[i] - a * STATES[i]

def line(name, v):
    print(f"{name:<48}{v:>12}")

def row(name, values):
    print(f"{name:<34}" + "".join(f"{v:>10}" for v in values))

row("scenario", NAMES)
row("Acme in one year", [f"{s:.2f}" for s in STATES])
row("call payoff, strike 100.00", [f"{p:.2f}" for p in PAY])
line("banked dollar R, discount factor D", f"{R:.6f} {D:.6f}")
line("the note's price P = 100.00 x e^-0.02", f"{P:.6f}")
line("the same note priced for delivery day, P / D", f"{P / D:.6f}")

print()
print(f"two desks quote that same note: {QA:.2f} and {QB:.2f}")
gap = QB - QA
legs = ((1.0, QA), (-1.0, QB))                 # bought from one desk, sold to the other
banked = -sum(q * price for q, price in legs)  # what is left over goes to the bank
ledger = [sum(q * s for q, _ in legs) + banked * R for s in STATES]
line("  gap taken in today", f"{gap:.2f}")
for nm, v in zip(NAMES, ledger):
    line(f"  profit at expiry, {nm} scenario", f"{v:.6f}")
line("  the same, in one line: gap x R", f"{gap * R:.6f}")
line("  mistake, banking the gap and not its interest", f"{gap:.2f}")
line("  with 0.10 a note of round-trip cost, net today", f"{gap - 0.20:.2f}")
line("  and that net at expiry", f"{(gap - 0.20) * R:.6f}")

print()
print("what no arbitrage allows the call to cost")
ceiling, floor_ = hunt(ceiling_at, True), hunt(floor_at, False)
pairs = [matched(i, j) for i, j in ((0, 1), (0, 2), (1, 2))]
over = [(cost(a, b), a, b) for a, b in pairs
        if all(held(a, b, s) >= PAY[k] - 1e-9 for k, s in enumerate(STATES))]
under = [(cost(a, b), a, b) for a, b in pairs
         if all(held(a, b, s) <= PAY[k] + 1e-9 for k, s in enumerate(STATES))]
(ex_ceiling, a_up, b_up), (ex_floor, a_dn, b_dn) = min(over), max(under)
line("  cheapest dominating copy, by search", f"{ceiling:.6f}")
line("  the same copy, by a two-scenario solve", f"{ex_ceiling:.6f}")
line("  it holds notes, and dollars due at expiry", f"{a_up:.6f} {b_up:.6f}")
line("  dearest dominated copy, by search", f"{floor_:.6f}")
line("  the same copy, by a two-scenario solve", f"{ex_floor:.6f}")
line("  it holds notes, and dollars due at expiry", f"{a_dn:.6f} {b_dn:.6f}")
line("  floor with no scenario list, P - K x D", f"{P - K * D:.6f}")
line("  the shelf's call minus its put", f"{HOUSE_CALL - HOUSE_PUT:.6f}")
line("  ceiling with no scenario list, the note itself", f"{P:.6f}")
line("  the other dominated copy, 1 note and -100.00", f"{min(c for c, _, _ in under):.6f}")
line("  the shelf's call price, inside the band", f"{HOUSE_CALL:.6f}")

print()
for quote, sign, a, b, copy in ((12.00, 1.0, a_up, b_up, ex_ceiling),
                                (4.00, -1.0, a_dn, b_dn, ex_floor)):
    credit = sign * (quote - copy)
    what = "sell the call, buy the dominating copy" if sign > 0 else \
           "buy the call, sell the dominated copy"
    print(f"a call quoted at {quote:.2f}: {what}")
    line("  credit today, and that credit at expiry", f"{credit:.6f} {credit * R:.6f}")
    profits = [sign * (held(a, b, s) - PAY[i]) + credit * R for i, s in enumerate(STATES)]
    row("  profit at expiry", [f"{v:.2f}" for v in profits])
    assert min(profits) > 1e-9, "a quote outside the band must pay in every scenario"

print()
print("one price is weaker than no free money: a bank unit and a free certificate")
cert, cert_cost = (1.0, 0.0, 0.0), 0.0    # a dollar in the high scenario only; free
market = [(b + h * cert_cost, tuple(b * R + h * cert[i] for i in range(3)))
          for b in range(-10, 11) for h in range(-10, 11)]  # each holding: price, then payoff
seen, same, worst, free = 0, 0, 0.0, 0
for c1, x1 in market:
    if c1 <= 1e-9 and min(x1) >= -1e-9 and max(x1) > 1e-9:
        free += 1                             # costs nothing, never loses, gains somewhere
    for c2, x2 in market:
        seen += 1
        if all(abs(u - v) < 1e-9 for u, v in zip(x1, x2)):
            same += 1
            worst = max(worst, abs(c1 - c2))  # two prices, each from its own holding
line("  portfolio pairs checked", f"{seen}")
line("  pairs paying the same in all three scenarios", f"{same}")
line("  the largest price gap among those pairs", f"{worst:.6f}")
line("  holdings in the grid that are free money", f"{free}")
row("  the free certificate pays", [f"{c:.2f}" for c in cert])
line("  and it costs", f"{cert_cost:.2f}")

print()
row("chart, Acme in one year", [f"{s:.2f}" for s in reversed(STATES)])
row("chart, call payoff", [f"{p:.2f}" for p in reversed(PAY)])
row("chart, dominating copy", [f"{held(a_up, b_up, s):.2f}" for s in reversed(STATES)])
row("chart, dominated copy", [f"{held(a_dn, b_dn, s):.2f}" for s in reversed(STATES)])
line("  add a 60.00 scenario and that copy would hold", f"{held(a_up, b_up, 60.0):.6f}")

assert abs(ceiling - ex_ceiling) < 1e-9, "search and two-scenario solve must agree"
assert abs(floor_ - ex_floor) < 1e-9, "search and two-scenario solve must agree"
assert abs((HOUSE_CALL - HOUSE_PUT) - (P - K * D)) < 1e-9, "the shelf's pair vs the floor"
assert min(STATES) < P / D < max(STATES), "the note and the bank are no arbitrage on their own"
assert all(abs(v - gap * R) < 1e-12 for v in ledger), "the note legs must cancel"
assert ex_floor > P - K * D and ex_ceiling < P, "the scenario list tightens both ends"
assert same == 441 and worst < 1e-9, "matched payoffs carried matched prices on every pair"
assert free == 10, "yet ten holdings in that same market are free money"
print("ALL CHECKS PASS")
