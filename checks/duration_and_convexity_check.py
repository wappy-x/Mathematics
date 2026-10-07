# Duration and convexity -- the check behind the card.  Nothing is imported.
# The bond: 1,000 face, 6% annual coupon, five years, priced at a 5% yield.
# Four roads reach the same numbers: present-value weighted sums; central
# differences on the price function itself; whole-number arithmetic with a
# single division at the end; and a certified bound on what the second-order
# estimate leaves out.
FACE, COUPON, YEARS, Y, UP = 1000, 60, 5, 0.05, 0.01

def flows(face=FACE, coupon=COUPON, years=YEARS):
    return [(t, coupon + (face if t == years else 0)) for t in range(1, years + 1)]

def price(y, fl):
    return sum(c / (1.0 + y) ** t for t, c in fl)

def macaulay(y, fl):                 # road 1: the present-value weighted average time
    return sum(t * c / (1.0 + y) ** t for t, c in fl) / price(y, fl)

def convexity(y, fl):                # road 1: weighted t(t+1), two extra discounts
    return sum(t * (t + 1) * c / (1.0 + y) ** (t + 2) for t, c in fl) / price(y, fl)

def third_size(y, fl):               # the largest the third derivative gets on a move
    return sum(t * (t + 1) * (t + 2) * c / (1.0 + y) ** (t + 3) for t, c in fl)

def slope(y, fl, h=1e-5):            # road 2: dP/dy by nudging the yield both ways
    return (price(y + h, fl) - price(y - h, fl)) / (2.0 * h)

def bend(y, fl, h=1e-4):             # road 2: d2P/dy2 by nudging the yield both ways
    return (price(y + h, fl) - 2.0 * price(y, fl) + price(y - h, fl)) / (h * h)

def exact_price(a, b, fl, n=YEARS):  # road 3: (1+y) = a/b, whole numbers, one division
    return sum(c * b ** t * a ** (n - t) for t, c in fl) / a ** n

def pair(label, vals):
    print(f"{label:<38}" + "".join(f"{v:>15.6f}" for v in vals))

fl = flows()
P = price(Y, fl)
Dmac = macaulay(Y, fl)
Dmod = Dmac / (1.0 + Y)
Cvx = convexity(Y, fl)

print("the house bond: 1000 face, 6% annual coupon, 5 years, priced at a 5% yield")
print(f"{'year':>4}{'cash':>10}{'present value':>16}{'share of price':>16}{'year x share':>14}")
for t, c in fl:
    pv = c / (1.0 + Y) ** t
    print(f"{t:>4}{c:>10.2f}{pv:>16.6f}{pv / P:>16.6f}{t * pv / P:>14.6f}")
print(f"{'totals':>14}{P:>16.6f}{1.0:>16.6f}{Dmac:>14.6f}")
print()
print(f"{'price P':<40}{P:>14.6f}")
print(f"{'  by whole-number arithmetic':<40}{exact_price(21, 20, fl):>14.6f}")
print(f"{'Macaulay duration, years':<40}{Dmac:>14.6f}")
print(f"{'modified duration, per 1.00 of yield':<40}{Dmod:>14.6f}")
print(f"{'  -(1/P) dP/dy by nudging':<40}{-slope(Y, fl) / P:>14.6f}")
print(f"{'convexity, years squared':<40}{Cvx:>14.6f}")
print(f"{'  (1/P) d2P/dy2 by nudging':<40}{bend(Y, fl) / P:>14.6f}")
print(f"{'DV01, dollars per basis point':<40}{Dmod * P * 1e-4:>14.6f}")

shocks = []
for h, a, b in ((UP, 53, 50), (-UP, 26, 25)):
    exact = exact_price(a, b, fl)
    lin = P * (1.0 - Dmod * h)
    quad = lin + P * 0.5 * Cvx * h * h
    bound = third_size(min(Y, Y + h), fl) * abs(h) ** 3 / 6.0
    shocks.append((h, exact, lin, quad, bound))
print()
print(f"{'a 1-point move from the 5% yield':<38}{'rise to 6%':>15}{'fall to 4%':>15}")
pair("  exact new price, whole numbers", [s[1] for s in shocks])
pair("  duration-only estimate", [s[2] for s in shocks])
pair("  duration + convexity estimate", [s[3] for s in shocks])
pair("  duration-only error, dollars", [s[1] - s[2] for s in shocks])
pair("  duration + convexity error, dollars", [s[1] - s[3] for s in shocks])
pair("  certified error bound, dollars", [s[4] for s in shocks])
pair("  actual move, percent of price", [100.0 * (s[1] - P) / P for s in shocks])
pair("  duration-only said, percent", [-100.0 * Dmod * s[0] for s in shocks])
pair("  convexity correction, percent", [50.0 * Cvx * s[0] * s[0] for s in shocks])

print()
print("what breaks, on the 1-point rise (right answer 1000.000000)")
print(f"{'  Macaulay used in place of modified':<40}{P * (1.0 - Dmac * UP):>14.6f}")
print(f"{'  convexity term without the half':<40}{shocks[0][2] + P * Cvx * UP * UP:>14.6f}")
print(f"{'  convexity term subtracted':<40}{shocks[0][2] - P * 0.5 * Cvx * UP * UP:>14.6f}")
print(f"{'  100 basis points typed as 1.0':<40}{P * (1.0 - Dmod * 1.0):>14.6f}")

print()
zc = flows(coupon=0)
ten = flows(years=10)
big = 3.0 * UP
print(f"{'try: 5-year zero, Macaulay duration':<40}{macaulay(Y, zc):>14.6f}")
print(f"{'try: 5-year zero, convexity':<40}{convexity(Y, zc):>14.6f}")
print(f"{'try: 10-year bond, modified duration':<40}{macaulay(Y, ten) / (1.0 + Y):>14.6f}")
print(f"{'try: 3-point rise, with convexity error':<40}"
      f"{price(Y + big, fl) - P * (1.0 - Dmod * big + 0.5 * Cvx * big * big):>14.6f}")

print()
chart_y = [0.03 + 0.005 * i for i in range(9)]
print("chart, yield percent      " + " ".join(f"{100.0 * y:7.2f}" for y in chart_y))
print("chart, actual price       " + " ".join(f"{price(y, fl):7.2f}" for y in chart_y))
print("chart, duration-only line " + " ".join(f"{P * (1.0 - Dmod * (y - Y)):7.2f}" for y in chart_y))
moves = [0.001, 0.005, 0.01, 0.02, 0.03]
print("bars, move in basis points" + " ".join(f"{10000.0 * h:7.0f}" for h in moves))
print("bars, duration-only error " + " ".join(
    f"{price(Y + h, fl) - P * (1.0 - Dmod * h):7.2f}" for h in moves))
ages = [5, 4, 3, 2, 1]
print("chart, years remaining    " + " ".join(f"{n:7d}" for n in ages))
print("chart, modified duration  " + " ".join(
    f"{macaulay(Y, flows(years=n)) / (1.0 + Y):7.2f}" for n in ages))
drift = [0.03, 0.04, 0.05, 0.06, 0.07]
print("drift, yield percent      " + " ".join(f"{100.0 * y:7.2f}" for y in drift))
print("drift, modified duration  " + " ".join(f"{macaulay(y, fl) / (1.0 + y):7.2f}" for y in drift))

assert abs(-slope(Y, fl) / P - Dmod) < 1e-6, "nudged slope must land on Macaulay/(1+y)"
assert abs(bend(Y, fl) / P - Cvx) < 1e-4, "nudged bend must land on the weighted t(t+1) sum"
assert abs(exact_price(21, 20, fl) - P) < 1e-9, "whole numbers must land on the float price"
assert abs(macaulay(Y, zc) - YEARS) < 1e-12, "a zero's average payment time is its maturity"
for h, exact, lin, quad, bound in shocks:
    assert abs(exact - quad) <= bound, "the second-order error must respect its bound"
    assert abs(exact - quad) < abs(exact - lin), "convexity must shrink the error"
    assert exact > lin, "the curve must sit above its tangent on both sides"
print("ALL CHECKS PASS")
