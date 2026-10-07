# Z-spread and asset-swap spread -- the check behind the card.  Standard
# library only, and nothing imported that already knows an answer: the root
# finders, the forward rates and the swap legs are all written out here.
# The curve is this morning's bootstrapped zero curve, 1 to 5 years.  The bond
# is Northwind 4s of 2031.  Each answer is reached twice by roads that share no
# arithmetic: discount factors straight from the zero rates against the same
# factors chained out of the one-year forwards; bisection against Newton; the
# asset-swap spread in closed form against the whole package priced cash flow
# by cash flow and solved to zero.
from math import exp

ZERO = [0.0300, 0.0330, 0.0355, 0.0375, 0.0390]      # continuously compounded, 1 to 5 years
YEAR = [1.0, 2.0, 3.0, 4.0, 5.0]
FACE, CPN, QUOTE = 100.0, 4.00, 94.833
FWD = [ZERO[0] * YEAR[0]] + [ZERO[i] * YEAR[i] - ZERO[i - 1] * YEAR[i - 1] for i in range(1, 5)]

def df(i, s=0.0):                          # road one: one exponential per pillar
    return exp(-(ZERO[i] + s) * YEAR[i])

def df_chain(i, s=0.0):                    # road two: multiply the one-year factors together
    out = 1.0
    for k in range(i + 1):
        out *= exp(-(FWD[k] + s))
    return out

def price(s, cpn=CPN, factor=df):          # the bond, discounted at curve plus spread
    return sum(cpn * factor(i, s) for i in range(5)) + FACE * factor(4, s)

def slope(s, cpn=CPN):                     # dP/ds, differentiated by hand, for Newton
    body = sum(YEAR[i] * cpn * df_chain(i, s) for i in range(5))
    return -(body + YEAR[4] * FACE * df_chain(4, s))

def bisect(f, lo, hi):                     # f falls from positive at lo to negative at hi
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) > 0.0:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)

def newton(f, fp, x):                      # the other solver: follow the slope
    for _ in range(60):
        x -= f(x) / fp(x)
    return x

curve_price = price(0.0)
chain_price = price(0.0, factor=df_chain)
z_bisect = bisect(lambda s: price(s) - QUOTE, -0.5, 1.0)
z_newton = newton(lambda s: price(s, factor=df_chain) - QUOTE, slope, 0.0)
annuity = sum(df(i) for i in range(5))
float_par = FACE * (1.0 - df(4))                                        # par leg identity
float_fwd = sum(FACE * (exp(FWD[i]) - 1.0) * df_chain(i) for i in range(5))
asw = (curve_price - QUOTE) / annuity / FACE                            # closed form

def package(a):                            # buy the bond, pay par, swap fixed for floating + a
    pv = QUOTE - FACE
    for i in range(5):
        pv += (FACE * (exp(FWD[i]) - 1.0) + FACE * a - CPN) * df_chain(i)
    return pv

asw_pkg = bisect(lambda a: -package(a), -0.5, 1.0)
ytm = bisect(lambda y: sum(CPN * exp(-y * t) for t in YEAR) + FACE * exp(-y * YEAR[4]) - QUOTE, -0.5, 1.0)
ytm_annual = exp(ytm) - 1.0
par_rate = (FACE - FACE * df(4)) / annuity / FACE
flat_z = bisect(lambda s: sum(CPN * exp(-(ZERO[4] + s) * t) for t in YEAR)
                + FACE * exp(-(ZERO[4] + s) * YEAR[4]) - QUOTE, -0.5, 1.0)
asw_risky = (curve_price - QUOTE) / sum(df(i, z_bisect) for i in range(5)) / FACE
asw8 = (price(0.0, cpn=8.0) - price(z_bisect, cpn=8.0)) / annuity / FACE
widened = price(z_bisect + 0.01)
bps = [0, 60, 120, 180, 240, 300]
curve_prices = [price(b / 10000.0) for b in bps]
coupons = [3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
asw_curve = [(price(0.0, cpn=c) - price(z_bisect, cpn=c)) / annuity / FACE for c in coupons]

print("the curve this morning, bootstrapped from deposits, futures and swaps")
for i in range(5):
    print(f"   {int(YEAR[i])}y  zero {ZERO[i] * 100:.4f}%   D {df(i):.6f}   one-year forward {FWD[i] * 100:.4f}%")
print()
print("Northwind 4.000% of 2031, face 100, five annual coupons")
for label, v in (("price on the curve, from the zero rates", curve_price),
                 ("price on the curve, from chained forwards", chain_price),
                 ("market price, the dealer's quote", QUOTE),
                 ("price gap, curve minus market", curve_price - QUOTE)):
    print(f"{label:<45}{v:>12.6f}")
print(f"{'z-spread, bisection':<45}{z_bisect * 10000:>12.4f} bp")
print(f"{'z-spread, Newton':<45}{z_newton * 10000:>12.4f} bp")
for label, v in (("the bond repriced at the z-spread", price(z_bisect)),
                 ("floating leg, par minus the final factor", float_par),
                 ("floating leg, forward by forward", float_fwd),
                 ("annuity, the discount factors added up", annuity)):
    print(f"{label:<45}{v:>12.6f}")
print(f"{'asset-swap spread, closed form':<45}{asw * 10000:>12.4f} bp")
print(f"{'asset-swap spread, package solved to zero':<45}{asw_pkg * 10000:>12.4f} bp")
print(f"{'the bond yield, continuous then annual':<45}{ytm * 100:>12.4f}% {ytm_annual * 100:.4f}%")
print()
print(f"as the card quotes them: curve {curve_price:.2f}, market {QUOTE:.2f}, gap "
      f"{curve_price - QUOTE:.2f}, z {z_bisect * 10000:.2f} bp, asw {asw * 10000:.2f} bp")
print()
print("what breaks")
print(f"{'spread over the 5-year zero rate alone':<45}{flat_z * 10000:>12.4f} bp")
print(f"I-spread, yield {ytm_annual * 100:.4f}% less par rate {par_rate * 100:.4f}%"
      f"{(ytm_annual - par_rate) * 10000:>12.4f} bp")
print(f"{'asset-swap annuity discounted with the spread':<45}{asw_risky * 10000:>12.4f} bp")
print(f"{'the same z-spread on an 8% coupon bond, asw':<45}{asw8 * 10000:>12.4f} bp")
print()
print("how the price moves when the spread moves")
print(f"{'price slope, minus dP/dz at the quote':<45}{-slope(z_bisect):>12.4f}")
print(f"{'price given up per basis point of widening':<45}{-slope(z_bisect) / 10000.0:>12.6f}")
print(f"{'widen the spread by 100 bp: price':<45}{widened:>12.6f}, a drop of {price(z_bisect) - widened:.6f}")
print()
print(f"{'chart, spread in basis points':<32}" + "".join(f"{b:>8d}" for b in bps))
print(f"{'chart, price':<32}" + "".join(f"{p:>8.2f}" for p in curve_prices))
print(f"{'chart, the market quote':<32}" + "".join(f"{QUOTE:>8.2f}" for _ in bps))
print(f"{'bars, price given up per 100 face':<32}" + "".join(f"{curve_price - p:>8.2f}" for p in curve_prices))
print(f"{'chart, coupon in percent':<32}" + "".join(f"{c:>8.2f}" for c in coupons))
print(f"{'chart, asset-swap spread in bp':<32}" + "".join(f"{a * 10000:>8.2f}" for a in asw_curve))
print(f"{'chart, z-spread in bp':<32}" + "".join(f"{z_bisect * 10000:>8.2f}" for _ in coupons))
print()
print("try changing")
print(f"{'quote 94.733 instead of 94.833: z-spread':<45}"
      f"{bisect(lambda s: price(s) - 94.733, -0.5, 1.0) * 10000:>12.4f} bp")
print(f"{'quote 101.000, a bond richer than the curve':<45}"
      f"{bisect(lambda s: price(s) - 101.000, -0.5, 1.0) * 10000:>12.4f} bp")
print(f"{'every zero rate flattened to 3.9000%: z':<45}{flat_z * 10000:>12.4f} bp")
assert abs(curve_price - chain_price) < 1e-10          # zero rates against chained forwards
assert abs(z_bisect - z_newton) < 1e-12                # bisection against Newton
assert abs(float_par - float_fwd) < 1e-10              # par identity against forward by forward
assert abs(asw - asw_pkg) < 1e-12                      # closed form against the package priced out
assert abs(price(z_bisect) - QUOTE) < 1e-9             # the solved spread reprices the bond
print("ALL CHECKS PASS")
