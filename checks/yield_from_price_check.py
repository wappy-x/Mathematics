# Yield from price -- the check behind the card.  Nothing is imported.  The
# house bond: face 1000, a 6% coupon paid once a year, five years to run,
# quoted at 1043.294767.  The yield is found two ways that share no
# arithmetic: halving a bracket and following tangents.  The quote itself is
# a whole-number fraction, the exact price at 21/20, so the target is not an
# artefact of the floating-point code.  A quarry stream is then solved too.
FACE, CRATE, YEARS = 1000.0, 0.06, 5
BOND = [(t, FACE * CRATE + (FACE if t == YEARS else 0.0)) for t in range(1, YEARS + 1)]
QUARRY = [(0, -1000.0), (1, 3000.0), (2, -2000.0)]
NUM = sum(round(cf) * 20 ** t * 21 ** (YEARS - t) for t, cf in BOND)   # exact price at y = 1/20,
DEN = 21 ** YEARS                                                      # as a whole-number fraction
QUOTE = NUM / DEN

def pv(flows, y):                      # the price at a yield: every payment discounted, then added
    return sum(cf / (1.0 + y) ** t for t, cf in flows)

def slope(flows, y):                   # dP/dy: dollars of price per unit of yield
    return -sum(t * cf / (1.0 + y) ** (t + 1) for t, cf in flows)

def digits(err):                       # decimal digits of the answer that have settled
    d, e = 0, abs(err)
    while e < 1.0 and d < 17:
        e, d = e * 10.0, d + 1
    return d - 1

def bisect(flows, target, lo, hi, steps):
    """Halve a bracket whose ends price on opposite sides of the target."""
    trace, flo = [], pv(flows, lo) - target
    for k in range(steps):
        mid = 0.5 * (lo + hi)
        if (pv(flows, mid) - target) * flo > 0.0:
            lo = mid
        else:
            hi = mid
        trace.append((k + 1, lo, hi, 0.5 * (lo + hi)))
    return trace

def newton(flows, target, y0, steps):
    """Follow the tangent to where it crosses the quoted price."""
    trace, y = [], y0
    for k in range(steps):
        resid = pv(flows, y) - target
        y = y - resid / slope(flows, y)
        trace.append((k + 1, y, resid))
        if y <= -1.0:
            break
    return trace

def isqrt(n):                          # whole-number square root, written out here
    x = n
    while x * x > n:
        x = (x + n // x) // 2
    return x

def row(label, value):
    print(f"{label:<48}{value:>14.6f}")

def strip(label, values):
    print(f"{label:<38}" + "".join(f"{v:>10.2f}" for v in values))

print(f"the house bond: face {FACE:.2f}, coupon {CRATE * 100:.2f}% once a year, "
      f"{YEARS} payments, quoted at {QUOTE:.6f}")
print(f"the quote as a whole-number fraction: {NUM} / {DEN}")
print(f"the same fraction by long division:   {NUM // DEN}.{(NUM * 10 ** 12 // DEN) % 10 ** 12:012d}")
YS = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09]
curve = [pv(BOND, y) for y in YS]
strip("price at yields 3% to 9%", curve)
strip("the quote, flat, at those yields", [QUOTE] * len(YS))
print(f"bracket: the price at 0% is {pv(BOND, 0.0):.6f} and at 100% is {pv(BOND, 1.0):.6f}, "
      f"so the quote is caught between")
print("road 1  halving the bracket [0%, 100%]")
tr = bisect(BOND, QUOTE, 0.0, 1.0, 40)
for k, lo, hi, mid in tr:
    if k <= 6 or k in (10, 20, 40):
        print(f"  step {k:>2}  bracket [{lo:.6f}, {hi:.6f}]  midpoint {mid:.6f}"
              f"  price {pv(BOND, mid):>11.6f}")
print("road 2  tangent steps from the 6% coupon rate")
nt = newton(BOND, QUOTE, CRATE, 6)
for k, y, resid in nt[:4]:
    print(f"  step {k:>2}  price residual before the step {resid:>12.6f}"
          f"  yield after it {y * 100.0:.7f}%")
y_bis, y_new = tr[-1][3], nt[3][1]
row("road 1  yield after 40 halvings, percent", y_bis * 100.0)
row("road 2  yield after 4 tangent steps, percent", y_new * 100.0)
row("the exact 1/20 the quote was built at, percent", 100.0 / 20.0)
row("roads 1 and 2 apart by, percent", abs(y_bis - y_new) * 100.0)
print(f"{'digits of the yield settled after step':<38}" + "".join(f"{k:>10d}" for k in range(1, 7)))
print(f"{'  by halving':<38}" + "".join(f"{digits(tr[k][3] - 0.05):>10d}" for k in range(6)))
print(f"{'  by tangents':<38}" + "".join(f"{digits(nt[k][1] - 0.05):>10d}" for k in range(6)))
m = -slope(BOND, 0.06)                 # the slowest the price falls anywhere in 4% to 6%
stop10 = tr[9][3]
row("price fall per unit of yield at 5%, dollars", -slope(BOND, 0.05))
row("price fall for one basis point, dollars", -slope(BOND, 0.05) * 0.0001)
row("slowest price fall anywhere in 4% to 6%", m)
row("yield a 1 cent price error can hide, percent", 0.01 / m * 100.0)
row("mistake: coupon over price, the current yield, %", FACE * CRATE / QUOTE * 100.0)
row("mistake: the 6% coupon read as the yield, %", CRATE * 100.0)
row("mistake: halving stopped after 10 steps, %", stop10 * 100.0)
row("  that guess is out by, percent", abs(stop10 - 0.05) * 100.0)
row("  with this much price still missing, dollars", abs(pv(BOND, stop10) - QUOTE))
row("  and that residual allows a yield error of, %", abs(pv(BOND, stop10) - QUOTE) / m * 100.0)
print("the quarry: 1000 paid out today, 3000 back in a year, 2000 of clean-up at the end")
strip("its value at yields 0% to 150%", [pv(QUARRY, y) for y in (0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5)])
strip("the zero line it must cross", [0.0] * 7)
qr = bisect(QUARRY, 0.0, 0.5, 3.0, 60)[-1][3]
row("quarry yield by halving [50%, 300%], percent", qr * 100.0)
row("quarry value at a yield of 0%, dollars", pv(QUARRY, 0.0))
roots = []
for cost in (1000, 1125, 1200):
    disc = 3000 * 3000 - 4 * cost * 2000          # the whole-number test for how many yields exist
    if disc < 0:
        print(f"  bought for {cost}: the root sign holds {disc}, so no yield exists at all")
    else:
        zs = sorted({3000 - isqrt(disc), 3000 + isqrt(disc)})
        ys = [z / (2 * cost) - 1.0 for z in zs]
        roots = ys if cost == 1000 else roots
        print(f"  bought for {cost}: the root sign holds {disc}, giving "
              f"{'one yield' if len(ys) == 1 else 'two yields'}: "
              + " and ".join(f"{y * 100.0:.6f}%" for y in ys))
print(f"  a tangent step from a yield of 30% lands at {newton(QUARRY, 0.0, 0.30, 1)[0][1] * 100.0:.4f}%,"
      f" outside every price")
assert abs(y_bis - y_new) < 1e-9, "halving and tangents must land on the same yield"
assert abs(pv(BOND, y_new) - QUOTE) < 1e-9, "the found yield must reprice the whole-number quote"
assert abs(y_bis - 0.05) < 1e-11, "the search must find the 1/20 built into the quote"
assert abs(stop10 - 0.05) <= abs(pv(BOND, stop10) - QUOTE) / m, "the price-residual bound holds"
assert all(curve[i] > curve[i + 1] for i in range(len(curve) - 1)), "one price per yield, no ties"
assert abs(qr - roots[1]) < 1e-9 and pv(QUARRY, roots[0]) == 0.0, "both quarry yields, two ways"
print("ALL CHECKS PASS")
