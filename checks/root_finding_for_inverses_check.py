# Solving backwards -- the check behind the card.  Standard library only, and nothing
# imported that already knows an answer: the bell-curve area N(x) is built from thin
# slices (Simpson's rule), and bisection, Newton and Brent are written out here.  One
# step means one trip through the pricer.  Case one takes the Acme call quote
# 9.227005508154 back to a volatility of 0.20 by three solvers; case two runs the same
# three on a bond yield, whose price is reached by two independent formulas.
from math import log, log10, sqrt, exp, pi

S, K, R, Q, T = 100.0, 100.0, 0.05, 0.02, 1.0        # the house market
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height at x
def N(x):                                            # bell-curve area to the left of x
    if x < 0.0: return 1.0 - N(-x)
    if x > 8.0: return 1.0
    s, h = phi(0.0) + phi(x), x / 1000.0             # Simpson's rule, written out
    for i in range(1, 1000): s += (4.0 if i % 2 else 2.0) * phi(i * h)
    return 0.5 + s * h / 3.0
def d1_of(sig, k): return (log(S / k) + (R - Q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
def price(sig, k=K):                                 # the call price at volatility sig
    d1 = d1_of(sig, k)
    return S * exp(-Q * T) * N(d1) - k * exp(-R * T) * N(d1 - sig * sqrt(T))
def vega(sig, k=K): return S * exp(-Q * T) * phi(d1_of(sig, k)) * sqrt(T)   # dC/dsig

def bisect(f, lo, hi, tol):                          # halve the bracket, no slope needed
    flo, n = f(lo), 1
    while hi - lo > tol:
        mid = 0.5 * (lo + hi); fm = f(mid); n += 1
        if (fm > 0.0) == (flo > 0.0): lo, flo = mid, fm
        else: hi = mid
    return 0.5 * (lo + hi), n
def newton(f, fp, x0, tol, cap=30):                  # slide down the tangent line
    x, rows = x0, []
    for n in range(1, cap + 1):
        fx, sl = f(x), fp(x); rows.append((n, x, fx, sl))
        if abs(fx) < tol: return x, rows, "converged after %d steps" % n
        if sl == 0.0: return x, rows, "the slope vanished"
        x -= fx / sl
        if x <= 0.0: return x, rows, "left the region after %d steps" % n
    return x, rows, "hit the step cap"
def brent(f, lo, hi, tol):                           # a fast step with a midpoint net
    a, b = lo, hi; fa, fb = f(a), f(b); n, mid = 2, 0
    if (fa > 0.0) == (fb > 0.0): return b, n, mid, "no sign change"
    if abs(fa) < abs(fb): a, b, fa, fb = b, a, fb, fa
    c, fc, d, wide = a, fa, a, True
    while abs(b - a) > tol and fb != 0.0:
        if fa != fc and fb != fc:                    # inverse quadratic, three points
            s = (a * fb * fc / ((fa - fb) * (fa - fc)) + b * fa * fc / ((fb - fa) * (fb - fc))
                 + c * fa * fb / ((fc - fa) * (fc - fb)))
        else: s = b - fb * (b - a) / (fb - fa)       # secant, two points
        edge = (3.0 * a + b) / 4.0
        stalled = abs(s - b) >= 0.5 * (abs(b - c) if wide else abs(c - d))
        if not (min(edge, b) < s < max(edge, b)) or stalled:
            s, wide, mid = 0.5 * (a + b), True, mid + 1
        else: wide = False
        fs = f(s); n += 1; d, c, fc = c, b, fb
        if (fa > 0.0) != (fs > 0.0): b, fb = s, fs
        else: a, fa = s, fs
        if abs(fa) < abs(fb): a, b, fa, fb = b, a, fb, fa
    return b, n, mid, "converged after %d steps" % n

CF = [4.0, 4.0, 4.0, 4.0, 104.0]                     # 4% annual coupon, 100 face, 5 years
def dfac(y, k):                                      # discount factor, one divide per year
    v = 1.0
    for _ in range(k): v /= 1.0 + y
    return v
def bond(y): return sum(c * dfac(y, i + 1) for i, c in enumerate(CF))    # payment by payment
def bond_annuity(y): return 4.0 * (1.0 - dfac(y, 5)) / y + 100.0 * dfac(y, 5)  # annuity form
def bond_slope(y): return -sum((i + 1) * c * dfac(y, i + 2) for i, c in enumerate(CF))
def row(name, v): print(f"{name:<48}{v:>18.12f}")
def txt(name, v): print(f"{name:<48}{v:>18}")

QUOTE = price(0.20)
f = lambda x: price(x) - QUOTE
vfloor = min(vega(0.10 + 0.0001 * i) for i in range(3001))
row("the quote: Acme call at sigma = 0.20", QUOTE)
row("the shelf's delta, e^-qT N(d1)", exp(-Q * T) * N(d1_of(0.20, K)))
row("vega at sigma = 0.20, dollars per 1.00 of vol", vega(0.20))
row("  the same slope by bumping sigma", (price(0.2001) - price(0.1999)) / 0.0002)
row("  smallest vega on [0.10, 0.40]", vfloor)
row("price floor, sigma -> 0: S e^-qT - K e^-rT", S * exp(-Q * T) - K * exp(-R * T))
row("  price at sigma = 0.01", price(0.01))
row("  vega at sigma = 0.01", vega(0.01))
row("price ceiling, sigma -> infinity: S e^-qT", S * exp(-Q * T))
sigs = [0.05 * i for i in range(1, 9)]
print(f"{'chart, volatility in percent':<32}" + "".join(f"{100.0 * x:>7.0f}" for x in sigs))
print(f"{'chart, Acme call price ($)':<32}" + "".join(f"{price(x):>7.2f}" for x in sigs))
print(f"{'chart, the quote ($)':<32}" + "".join(f"{QUOTE:>7.2f}" for x in sigs))
print("newton from sigma = 1.00:  step, sigma, residual ($), vega ($)")
sig_n, nrows, nstatus = newton(f, vega, 1.00, 1e-12)
for n, x, fx, sl in nrows: print(f"  {n:>2}{x:>18.12f}{fx:>18.12f}{sl:>18.12f}")
txt("  newton", nstatus)
sig_b, steps_b = bisect(f, 0.01, 1.00, 1e-12)
row("bisection on [0.01, 1.00], root", sig_b)
txt("  steps", steps_b)
sig_r, steps_r, mids, rstatus = brent(f, 0.01, 1.00, 1e-12)
row("brent on [0.01, 1.00], root", sig_r)
txt("  steps", steps_r)
row("gap between the newton and bisection roots", abs(sig_n - sig_b))
row("residual at the newton root, dollars", abs(f(sig_n)))
row("  that residual divided by the smallest vega", abs(f(sig_n)) / vfloor)
row("  one cent of residual, in volatility", 0.01 / vfloor)
print("steps to pin sigma to 12 decimals, one block = one step")
for label, count in (("bisection", steps_b), ("brent", steps_r), ("newton", len(nrows))):
    print(f"  {label:<11}{chr(9608) * count:<42}{count:>3}")
sig_round = brent(lambda x: price(x) - 9.23, 0.01, 1.00, 1e-12)[0]
row("quote rounded to 9.23: sigma", sig_round)
row("  volatility points away from 20.000", 100.0 * abs(sig_round - 0.20))
row("wing K = 200: price at sigma = 0.20", price(0.20, 200.0))
row("  vega there", vega(0.20, 200.0))
wing = brent(lambda x: price(x, 200.0) - (price(0.20, 200.0) + 0.01), 0.01, 1.00, 1e-12)
row("  sigma from a quote one cent higher", wing[0])
row("  volatility points away from 20.000", 100.0 * abs(wing[0] - 0.20))
txt("midpoint fallbacks: at the money, then on the wing", "%d and %d" % (mids, wing[2]))
wrows = newton(f, vega, 0.01, 1e-12)[1]
row("no bracket, newton from 0.01: sigma after 1 step", wrows[1][1])
row("  vega there", wrows[1][3])
txt("  next step proposes minus a sigma of order 10^", int(log10(abs(wrows[1][1] - wrows[1][2] / wrows[1][3]))))
row("bisection on [0.01, 0.10], both ends low", bisect(f, 0.01, 0.10, 1e-12)[0])
txt("quote 2.50, below the floor: brent reports", brent(lambda x: price(x) - 2.50, 0.01, 1.00, 1e-12)[3])
print("bond: 4% annual coupon, 100 face, 5 years, quoted 96.00")
y_b = bisect(lambda y: bond(y) - 96.00, 0.001, 0.50, 1e-14)[0]
y_n = newton(lambda y: bond(y) - 96.00, bond_slope, 0.10, 1e-12)[0]
y_r = brent(lambda y: bond(y) - 96.00, 0.001, 0.50, 1e-14)[0]
row("  yield by bisection", y_b)
row("  yield by newton", y_n)
row("  yield by brent", y_r)
row("  price at that yield, payment by payment", bond(y_n))
row("  the same price by the annuity formula", bond_annuity(y_n))
assert abs(QUOTE - 9.227005508154) < 1e-9, "the pricer must reproduce the shelf's quote"
assert abs(exp(-Q * T) * N(d1_of(0.20, K)) - 0.586851) < 1e-6, "delta vs the shelf's number"
assert abs(vega(0.20) - (price(0.2001) - price(0.1999)) / 0.0002) < 1e-6, "vega vs a bump"
assert abs(sig_b - 0.20) < 1e-11 and abs(sig_r - 0.20) < 1e-11, "bisection and brent find 0.20"
assert abs(sig_n - 0.20) < 1e-14 and abs(sig_n - sig_b) < 1e-11, "newton agrees with bisection"
assert abs(sig_n - 0.20) <= abs(f(sig_n)) / vfloor + 1e-16, "the residual bound holds"
assert abs(nrows[3][1] - 0.20) <= abs(nrows[3][2]) / vfloor, "and it bites at step 4"
assert all(price(sigs[i]) < price(sigs[i + 1]) for i in range(7)), "the price climbs with vol"
assert vfloor > 36.0 and abs(price(0.01) - (S * exp(-Q * T) - K * exp(-R * T))) < 1e-3
assert abs(y_n - y_b) < 1e-12 and abs(y_r - y_b) < 1e-12, "three solvers, one yield"
assert abs(bond(y_n) - bond_annuity(y_n)) < 1e-9, "two roads to the bond price"
assert abs(wing[0] - 0.20) > 100.0 * abs(sig_round - 0.20), "a flat slope hurts far more"
print("ALL CHECKS PASS")
