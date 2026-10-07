# Futures margining and the forward-futures difference -- the check behind the
# card.  Nothing is imported that already holds an answer: the quote tree, the
# margin ledger, the bisection search and the hyperbolic tangent are written out
# here.  Acme: spot 100.00, bank 5 percent a year continuously compounded,
# dividend yield 2 percent, one year, settled at six months and at expiry.  The
# futures quote jumps 10.00 at every settlement.
from math import exp

S0, R, Q, T, DT, MOVE, DAYS = 100.0, 0.05, 0.02, 1.0, 0.5, 10.0, 252
F0 = S0 * exp((R - Q) * T)                 # cash and carry: where the quote tree starts
PATHS = (("up, up", (1, 1)), ("up, down", (1, -1)),
         ("down, up", (-1, 1)), ("down, down", (-1, -1)))
TILTS = (0.0, 0.03, -0.03)

def quotes(path):                          # the futures quote after each settlement
    return [F0 + MOVE * sum(path[:i]) for i in range(len(path) + 1)]

def bank(path, tilt):                      # growth factor per half year; tilt ties rates to the quote
    return [exp(R * DT), exp((R + tilt * path[0]) * DT)]

def ledger(path, sizes, tilt=0.0):         # road 1: carry the whole balance forward, date by date
    f, b, v = quotes(path), bank(path, tilt), 0.0
    for i, h in enumerate(sizes):
        v = v * b[i] + h * (f[i + 1] - f[i])
    return v

def bank_units(path, sizes, tilt=0.0):     # road 2: hold each settlement in bank units, cash out at expiry
    f, b, units, level = quotes(path), bank(path, tilt), 0.0, 1.0
    for i, h in enumerate(sizes):
        level *= b[i]                      # the bank account's value at that settlement date
        units += h * (f[i + 1] - f[i]) / level
    return units * level

def tail(path, tilt=0.0):                  # the sizes that cancel the carrying weights
    return [1.0 / bank(path, tilt)[1], 1.0]

def prices(tilt):                          # four equally likely paths: plain and weighted averages
    plain = weighted = bond = 0.0
    for _, path in PATHS:
        f, b = quotes(path), bank(path, tilt)
        d = 1.0 / (b[0] * b[1])            # today's worth of a dollar paid at expiry, on this path
        plain, weighted, bond = plain + 0.25 * f[-1], weighted + 0.25 * f[-1] * d, bond + 0.25 * d
    return plain, weighted / bond, weighted * exp(Q * T)

def forward_by_search(tilt):               # road 2 to the forward: the price worth nothing today
    def value(k):                          # what the contract is worth today, averaged over the paths
        return sum(0.25 * (quotes(p)[-1] - k) / (bank(p, tilt)[0] * bank(p, tilt)[1]) for _, p in PATHS)
    lo, hi = 50.0, 200.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if value(mid) > 0.0 else (lo, mid)
    return 0.5 * (lo + hi)

def futures_backward():                    # road 2 to the futures price: average backwards, node by node
    level = [F0 + 2 * MOVE, F0, F0 - 2 * MOVE]
    while len(level) > 1:
        level = [0.5 * (level[i] + level[i + 1]) for i in range(len(level) - 1)]
    return level[0]

def tanh(x): return (exp(x) - exp(-x)) / (exp(x) + exp(-x))   # written out here, not imported
def tidy(x): return 0.0 if abs(x) < 1e-9 else x              # a clean zero for a billionth

def daily(tailed):                         # 252 settlements: the quote ramps up 10.00, then back down
    g, v, marks = exp(R / DAYS), 0.0, [0.0]
    for day in range(1, DAYS + 1):
        step = MOVE / (DAYS // 2) * (1 if day <= DAYS // 2 else -1)
        v = v * g + step * (exp(-R * (T - day / DAYS)) if tailed else 1.0)
        if day % 63 == 0: marks.append(v)
    return v, marks

def row(label, value): print(f"{label:<46}{value:>14.6f}")

def table(title, sizes_of):
    print(title)
    print(f"{'path':<18}{'final quote':>14}{'futures cash':>14}{'forward pay':>14}{'difference':>14}")
    for name, path in PATHS:
        f, v = quotes(path), ledger(path, sizes_of(path))
        print(f"{name:<18}{f[-1]:>14.6f}{v:>14.6f}{f[-1] - F0:>14.6f}{tidy(v - (f[-1] - F0)):>14.6f}")

print(f"Acme spot {S0:.2f}, bank {R * 100:.0f} percent, dividend yield {Q * 100:.0f} percent, one year")
row("futures quote today, S e^(r-q)T", F0)
row("half-year bank growth factor, flat rates", bank((1, 1), 0.0)[1])
row("today's worth of a dollar at expiry, flat bank", 1.0 / (exp(R * DT) * bank((1, 1), 0.0)[1]))
print(f"quote tree: {F0:.6f} -> {F0 + MOVE:.6f} or {F0 - MOVE:.6f}")
print(f"         -> {F0 + 2 * MOVE:.6f}, {F0:.6f} or {F0 - 2 * MOVE:.6f}")
print()
table("one contract held throughout, flat rates", lambda path: [1.0, 1.0])
gaps = [abs(ledger(p, [1.0, 1.0], t) - bank_units(p, [1.0, 1.0], t)) for t in TILTS for _, p in PATHS]
row("widest gap between the two ledger roads, 12 cases", tidy(max(gaps)))
print()
table(f"tailed sizes {tail((1, 1))[0]:.6f} then 1.000000, flat rates", tail)
print(f"a settlement of {MOVE:.2f} at six months grows to {MOVE * bank((1, 1), 0.0)[1]:.6f} by expiry; tailed, {tail((1, 1))[0] * MOVE:.6f} grows to {tail((1, 1))[0] * MOVE * bank((1, 1), 0.0)[1]:.6f}")
print(f"tail needed once the bank tilts: {exp(-0.08 * DT):.6f} after a rise, "
      f"{exp(-0.02 * DT):.6f} after a fall")
print()
one_day, marks = daily(False)
print(f"daily settlement, {DAYS} steps, quote up {MOVE:.2f} then back down")
row("one contract, cash at expiry", one_day)
row("tailed sizes, cash at expiry", tidy(daily(True)[0]))
print("margin balance at months 0, 3, 6, 9, 12: " + " ".join(f"{m:.2f}" for m in marks))
print()
print("futures price and forward price, three banks")
print(f"{'bank':<30}{'futures':>13}{'forward':>13}{'gap':>13}{'Acme spot':>13}")
for label, tilt in (("flat at 5 percent", 0.0), ("up with Acme, 8 or 2", 0.03),
                    ("down with Acme, 2 or 8", -0.03)):
    fut, fwd, spot = prices(tilt)
    print(f"{label:<30}{fut:>13.6f}{fwd:>13.6f}{tidy(fut - fwd):>13.6f}{spot:>13.6f}")
row("gap by the closed form, MOVE tanh(tilt DT)", MOVE * tanh(0.03 * DT))
print(f"try: a quote moving 20.00 a settlement -> cash {2 * MOVE * (exp(R * DT) - 1.0):.6f}, "
      f"gap {2 * MOVE * tanh(0.03 * DT):.6f}")
print()
print("bars, gap on path up-down by bank rate:   "
      + " ".join(f"{MOVE * (exp(x * DT) - 1.0):.2f}" for x in (0.0, 0.02, 0.05, 0.08)))
print("bars, price gap by rate tilt:             "
      + " ".join(f"{MOVE * tanh(x * DT):.2f}" for x in (0.0, 0.01, 0.03, 0.06)))
grid = (-0.06, -0.04, -0.02, 0.0, 0.02, 0.04, 0.06)
print("chart, rate tilt in points:               " + " ".join(f"{x * 100:6.0f}" for x in grid))
print("chart, futures price:                     " + " ".join(f"{prices(x)[0]:6.2f}" for x in grid))
print("chart, forward price:                     " + " ".join(f"{prices(x)[1]:6.2f}" for x in grid))
print()
print("what breaks")
row("settlements added with no interest", tidy(sum(quotes((1, -1))[i + 1] - quotes((1, -1))[i] for i in (0, 1))))
row("one contract where a forward was wanted", ledger((1, -1), [1.0, 1.0]))
row("tail taken from today, not from the date", ledger((1, -1), [exp(-R * T), 1.0]))
row("futures quoted at the forward, rates up", prices(0.03)[0] - prices(0.03)[1])
for tilt in TILTS:                                          # two ledger roads, then tailing, every path
    for _, path in PATHS:
        assert abs(ledger(path, [1.0, 1.0], tilt) - bank_units(path, [1.0, 1.0], tilt)) < 1e-12
        assert abs(ledger(path, tail(path, tilt), tilt) - (quotes(path)[-1] - F0)) < 1e-12
assert abs(ledger((-1, 1), tail((1, 1), 0.03), 0.03)) > 0.2  # one size cannot serve both branches
assert abs(daily(True)[0]) < 1e-12                          # the same tail, over 252 settlements
assert abs(futures_backward() - prices(0.0)[0]) < 1e-12     # backwards tree vs the path average
for tilt in TILTS:                                          # bisection vs the weighted average
    assert abs(forward_by_search(tilt) - prices(tilt)[1]) < 1e-9
assert abs(prices(0.0)[1] - S0 * exp((R - Q) * T)) < 1e-12  # flat rates: forward = cash and carry
assert abs(prices(0.0)[2] - S0) < 1e-9                      # and Acme's spot comes back at 100.00
for tilt in (0.03, -0.03):                                  # the gap against its closed form
    assert abs((prices(tilt)[0] - prices(tilt)[1]) - MOVE * tanh(tilt * DT)) < 1e-12
assert prices(0.03)[0] > prices(0.03)[1] and prices(-0.03)[0] < prices(-0.03)[1]
print("ALL CHECKS PASS")
