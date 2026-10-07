# Gold forward and the lease rate -- the check behind the card.  Standard
# library only.  Every number on the card is printed here.  The forward is
# reached four ways that share no formula: the closed form, the break-even
# quote of the cash-and-carry ledger found by bisection, both loans rolled
# day by day, and an average over simulated gold prices drawn with a
# hand-written random number generator.
from math import exp, log, sqrt, cos, pi

S, r, l, T = 2000.0, 0.05, 0.01, 1.0             # spot USD/oz, dollar rate, lease rate, years

def forward(S, r, l, T):                           # road 1: the formula
    return S * exp((r - l) * T)

def rich(Fq):                                      # forward quoted too high: sell it, deliver 1 oz
    oz = exp(-l * T)                               # buy this much gold today and lend it out
    usd = oz * S                                   # borrow the dollars that pay for it
    back = oz * exp(l * T)                         # ounces the gold borrower returns at T
    debt = usd * exp(r * T)                        # dollars owed at T
    return oz, usd, back, debt, back * Fq - debt   # deliver the ounces for Fq, repay the loan

def cheap(Fq):                                     # forward quoted too low: buy it, owe 1 oz
    oz = exp(-l * T)                               # borrow this much gold and sell it
    usd = oz * S                                   # lend the dollars
    owed = oz * exp(l * T)                         # ounces owed to the gold lender at T
    deposit = usd * exp(r * T)                     # dollars back from the deposit at T
    return oz, usd, deposit, owed, deposit - owed * Fq

def bisect(f, lo, hi):                             # root of an increasing or decreasing f
    flo = f(lo)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(mid) > 0) == (flo > 0): lo, flo = mid, f(mid)
        else: hi = mid
    return 0.5 * (lo + hi)

def daily_roll(days=365):                          # road 3: both loans rolled once a day
    oz, debt = 1.0, S                              # 1 oz lent, S dollars borrowed to buy it
    for _ in range(int(days * T)):
        oz *= 1.0 + l / 365.0
        debt *= 1.0 + r / 365.0
    return debt / oz                               # dollars owed per ounce delivered

state = 20260927                                   # road 4: 64-bit linear congruential generator
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53

def mc_mean(drift, sigma=0.15, pairs=100000):      # average of simulated gold prices at T
    tot = tot2 = 0.0
    for _ in range(pairs):
        z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())    # Box-Muller
        for zz in (z, -z):
            ST = S * exp((drift - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * zz)
            tot += ST; tot2 += ST * ST
    m = tot / (2 * pairs)
    return m, sqrt((tot2 / (2 * pairs) - m * m) / (2 * pairs))

F = forward(S, r, l, T)
F_root = bisect(lambda q: rich(q)[4], 0.0, 10.0 * S)
F_day = daily_roll()
F_mc, se = mc_mean(r - l)
real_mc, _ = mc_mean(0.08)
implied = lambda q: r - log(q / S) / T             # the lease rate a quote implies
implied_root = bisect(lambda x: forward(S, r, x, T) - 2100.0, -1.0, 1.0)

def show(name, v, fmt="{:>16.6f}"):
    print(f"{name:<40}" + fmt.format(v))

print("gold 2000 USD/oz, dollars 5%, lease 1%, 1 year")
show("1 formula S e^((r-l)T)", F)
show("2 ledger break-even, bisection", F_root)
show("3 both loans rolled daily, 365 days", F_day)
show("4 Monte Carlo, vol 15%, 200000 draws", F_mc, "{:>16.2f}")
show("  standard error", se, "{:>16.2f}")
show("  mean if gold drifts at 8%", real_mc, "{:>16.2f}")
for name, v in zip(("gold bought and lent (oz)", "dollars borrowed", "gold returned at T (oz)",
                    "dollar debt at T", "profit at T"), rich(2100.0)):
    show("rich 2100: " + name, v)
for name, v in zip(("gold borrowed and sold (oz)", "dollars lent", "deposit at T",
                    "gold owed at T (oz)", "profit at T"), cheap(2060.0)):
    show("cheap 2060: " + name, v)
show("route A today: F e^(-rT)", F * exp(-r * T))
show("route B today: S e^(-lT)", S * exp(-l * T))
show("carry factor e^((r-l)T)", exp((r - l) * T))
show("premium ln(F/S)/T", log(F / S) / T)
show("  simple premium F/S - 1", F / S - 1.0)
show("implied lease at 2100, log inverse", implied(2100.0), "{:>16.12f}")
show("implied lease at 2100, bisection", implied_root, "{:>16.12f}")
show("full-carry ceiling S e^(rT)", forward(S, r, 0.0, T))
show("wrong: forgot the lease", forward(S, r, 0.0, T))
show("  2100 then looks cheap by", forward(S, r, 0.0, T) - 2100.0)
show("wrong: lease added", forward(S, r, -l, T))
show("wrong: simple gap S(1+(r-l)T)", S * (1.0 + (r - l) * T))
show("wrong: discounted, not grown", S * exp(-(r - l) * T))
show("wrong: lent 1 oz, cash at T", 2100.0 - S * exp(r * T))
show("  loose ounces left over", exp(l * T) - 1.0)
show("try: lease 5%", forward(S, r, 0.05, T))
show("try: lease 8%", forward(S, r, 0.08, T))
show("try: 5 years", forward(S, r, l, 5.0))
show("try: dollars 2%", forward(S, 0.02, l, T))
print("chart, years       " + "".join(f"{t:>9d}" for t in range(6)))
print("chart, lease 1%    " + "".join(f"{forward(S, r, l, t):>9.2f}" for t in range(6)))
print("chart, no lease    " + "".join(f"{forward(S, r, 0.0, t):>9.2f}" for t in range(6)))
quotes = (2040.0, 2060.0, 2080.0, 2100.0, 2120.0)
print("chart, quote       " + "".join(f"{q:>9.0f}" for q in quotes))
print("chart, implied %   " + "".join(f"{100 * implied(q):>9.2f}" for q in quotes))

assert abs(F - 2081.621548384777) < 1e-9,         "formula vs the value worked out by series"
assert abs(F_root - F) < 1e-8,                    "the ledger breaks even exactly at the formula"
assert abs(F_day - F) < 0.01,                     "daily compounding lands within a cent"
assert abs(F_mc - F) < 3.0 * se,                  "risk-neutral average of the gold price is the forward"
assert abs(real_mc - F) > 50.0,                   "a real-world forecast is a different number"
assert abs(implied(2100.0) - 0.001209835831) < 1e-12, "log inverse vs the value worked out by series"
assert abs(implied_root - implied(2100.0)) < 1e-12, "bisection inverse agrees with the log inverse"
assert abs(rich(2100.0)[4] - 18.378451615223) < 1e-9, "rich ledger locks in the quote minus the forward"
assert abs(cheap(2060.0)[4] - 21.621548384777) < 1e-9, "cheap ledger locks in the forward minus the quote"
print("ALL CHECKS PASS")
