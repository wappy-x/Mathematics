# NPV and IRR -- the check behind the card.  Standard library only, and nothing
# imported that already knows the answer: the powers, the square root, the
# bisection and the Newton steps are all written out below.  The project is a
# $100.00 dust-filter kit for a printing press that saves $60.00 at the end of
# each of two years.  Money in dollars, rates as decimals, dates in whole years.

def power(base, n):                      # repeated multiplication, so that the
    out = 1.0                            # Python and the Rust agree bit for bit
    for _ in range(n):
        out *= base
    return out

def npv(flows, y):                       # road 1: shrink each dated amount, add
    return sum(c / power(1.0 + y, i) for i, c in enumerate(flows))

def terminal(flows, y):                  # road 2: run a real bank account forward
    bal = 0.0
    for c in flows:
        bal = bal * (1.0 + y) + c
    return bal

def ledger_npv(flows, y):                # the end balance, shrunk back to today
    return terminal(flows, y) / power(1.0 + y, len(flows) - 1)

def slope(flows, y):                     # how NPV moves when the rate moves
    return sum(-i * c / power(1.0 + y, i + 1) for i, c in enumerate(flows))

def bisect(flows, lo, hi, steps=200):    # our own root finder: halve a bracket
    lo_is_positive = npv(flows, lo) > 0
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if (npv(flows, mid) > 0) == lo_is_positive:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)

def newton(flows, y, steps=40):          # our own Newton: slide down the slope
    for _ in range(steps):
        y -= npv(flows, y) / slope(flows, y)
    return y

def square_root(a, steps=60):            # our own square root, the same method
    x = a
    for _ in range(steps):
        x = 0.5 * (x + a / x)
    return x

def sign_changes(flows):                 # how often the cash switches direction
    marks = [c > 0 for c in flows if c != 0.0]
    return sum(1 for a, b in zip(marks, marks[1:]) if a != b)

def crossings(flows, lo=-0.90, hi=1.50, n=2400):   # every rate where NPV is zero
    found, step, before = [], (hi - lo) / n, npv(flows, lo)
    for k in range(1, n + 1):
        after = npv(flows, lo + k * step)
        if (after > 0) != (before > 0):
            found.append(bisect(flows, lo + (k - 1) * step, lo + k * step))
        before = after
    return found

def zeroed(v):                           # a crumb left by rounding is zero
    return 0.0 if abs(v) < 1e-9 else v

def row(name, v):
    print(f"{name:<52}{v:>13.6f}")

KIT = [-100.0, 60.0, 60.0]               # the card's project
BIG = [-250.0, 145.0, 145.0]             # the same press, a bigger kit
CLEANUP = [-100.0, 230.0, -132.0]        # a cleanup bill at the end: two IRRs
NEVER = [-100.0, 150.0, -100.0]          # a cleanup bill too big: no IRR at all
R = 0.08

print("project: pay 100.00 today, save 60.00 at the end of year 1 and 60.00 at the end of year 2")
print(f"growth factors at 8 percent: one year {1.0 + R:.6f}, two years {power(1.08, 2):.6f}")
row("discount factor for year 1, 1/1.08", 1.0 / power(1.08, 1))
row("discount factor for year 2, 1/(1.08 x 1.08)", 1.0 / power(1.08, 2))
row("year 1 saving in today's money", 60.0 / power(1.08, 1))
row("year 2 saving in today's money", 60.0 / power(1.08, 2))
row("both savings in today's money", 60.0 / power(1.08, 1) + 60.0 / power(1.08, 2))
row("1 NPV at 8 percent, by shrinking each amount", npv(KIT, R))
row("2 NPV at 8 percent, by the bank ledger", ledger_npv(KIT, R))
row("3 NPV at 8 percent, the exact fraction 5100/729", 5100.0 / 729.0)
print(f"{'NPV at 8 percent, to the cent':<52}{npv(KIT, R):>13.2f}")
row("bank balance at the end of year 2", terminal(KIT, R))
ledger = [KIT[0]]
for c in KIT[1:]:
    ledger += [ledger[-1] * (1.0 + R), ledger[-1] * (1.0 + R) + c]
print("bank ledger at 8 percent, after each move: " + ", ".join(f"{v:.2f}" for v in ledger))
irr_bisect = bisect(KIT, 0.0, 1.0)
irr_newton = newton(KIT, 0.20)
irr_exact = (3.0 + square_root(69.0)) / 10.0 - 1.0
row("1 IRR by bisection, percent", 100.0 * irr_bisect)
row("2 IRR by Newton, percent", 100.0 * irr_newton)
row("3 IRR from the exact root (3 + sqrt 69)/10, percent", 100.0 * irr_exact)
row("NPV at that rate, distance from zero", abs(npv(KIT, irr_bisect)))
row("wrong: the three amounts added with no dates", KIT[0] + KIT[1] + KIT[2])
row("wrong: today's 100.00 shrunk as well", npv(KIT, R) - KIT[0] + KIT[0] / power(1.08, 1))
row("wrong: year 1's factor used for both years", KIT[0] + (KIT[1] + KIT[2]) / power(1.08, 1))
npv_big = npv(BIG, R)
row("bigger kit: pay 250.00, save 145.00 twice -- its NPV", npv_big)
row("bigger kit, its IRR, percent", 100.0 * bisect(BIG, 0.0, 1.0))
row("dollars the bigger kit adds over the small one", npv_big - npv(KIT, R))
print("cleanup kit: -100.00 today, +230.00 at year 1, -132.00 at year 2")
print(f"  times the cash switches direction: {sign_changes(CLEANUP)}")
roots = crossings(CLEANUP)
print("  rates where its NPV is zero, percent: " + ", ".join(f"{100.0 * y:.6f}" for y in roots))
row("  its NPV at 15 percent, between those two rates", npv(CLEANUP, 0.15))
print("doomed kit: -100.00 today, +150.00 at year 1, -100.00 at year 2")
print(f"  times the cash switches direction: {sign_changes(NEVER)}")
print(f"  rates where its NPV is zero: {len(crossings(NEVER))} found between -90 and 150 percent")
row("  the best its NPV ever reaches, at 33.33 percent", npv(NEVER, 1.0 / 3.0))
price = sum(60.0 / power(1.05, i) for i in range(1, 6)) + 1000.0 / power(1.05, 5)
bond = [-price, 60.0, 60.0, 60.0, 60.0, 1060.0]
row("house bond at a 5 percent yield: its price today", price)
row("  the IRR of that bond's cashflows, percent", 100.0 * bisect(bond, 0.0, 0.50))
rates = [0.02 * i for i in range(11)]
print("chart, rate percent        " + " ".join(f"{100.0 * y:6.0f}" for y in rates))
print("chart, NPV dollars         " + " ".join(f"{zeroed(npv(KIT, y)):6.2f}" for y in rates))
cleanup_rates = [0.05 * i for i in range(7)]
print("chart, cleanup rate percent" + " ".join(f"{100.0 * y:6.0f}" for y in cleanup_rates))
print("chart, cleanup NPV dollars " + " ".join(f"{zeroed(npv(CLEANUP, y)):6.2f}" for y in cleanup_rates))
print("bars, NPV at 0, 4, 8 and 12 percent: "
      + " ".join(f"{npv(KIT, y):.2f}" for y in (0.0, 0.04, 0.08, 0.12)))

assert abs(npv(KIT, R) - ledger_npv(KIT, R)) < 1e-12       # shrinking vs the ledger
assert abs(npv(KIT, R) - 5100.0 / 729.0) < 1e-12           # vs the exact fraction
assert abs(irr_bisect - irr_exact) < 1e-10                 # bisection vs the root formula
assert abs(irr_newton - irr_exact) < 1e-10                 # Newton vs the root formula
assert abs(slope(KIT, R) - (npv(KIT, R + 1e-6) - npv(KIT, R - 1e-6)) / 2e-6) < 1e-4
assert abs(npv(KIT, irr_bisect)) < 1e-9                    # that rate really breaks even
assert len(roots) == 2 and max(abs(roots[0] - 0.10), abs(roots[1] - 0.20)) < 1e-9
assert (sign_changes(KIT), sign_changes(CLEANUP), sign_changes(NEVER)) == (1, 2, 2)
assert crossings(NEVER) == [] and npv(NEVER, 1.0 / 3.0) < 0.0
assert abs(bisect(bond, 0.0, 0.50) - 0.05) < 1e-12         # the bond's IRR is its yield
assert npv_big > npv(KIT, R) and bisect(BIG, 0.0, 1.0) < irr_bisect
print("ALL CHECKS PASS")
