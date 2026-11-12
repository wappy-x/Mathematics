# Forward, backward and central differences -- the check behind the card.
# Python standard library only.  The function is the price P(y), in dollars, of
# $10,000,000 face of a 30-year bond paying a 4% coupon once a year, at an
# annual yield y near 4.5%.  The step h is one basis point, 0.0001.
# Road one: difference quotients from repriced values.  Road two: the exact
# slope from the price's closed-form derivative.  Road three: the error each
# quotient should have, from Taylor's theorem, using the exact P'' and P'''.
import math
FACE, CPN, YEARS, Y0, BP = 10_000_000.0, 0.04, 30, 0.045, 0.0001
def derivs(y):                        # P, P', P'', P''' by summing the cash flows
    d, df, s = 1.0 / (1.0 + y), 1.0, [0.0, 0.0, 0.0, 0.0]
    for t in range(1, YEARS + 1):
        df *= d                       # discount factor 1/(1+y)^t by repeated multiply
        a = FACE * CPN + (FACE if t == YEARS else 0.0)
        s[0] += a * df
        s[1] -= t * a * df * d
        s[2] += t * (t + 1) * a * df * d * d
        s[3] -= t * (t + 1) * (t + 2) * a * df * d * d * d
    return s
def P(y): return derivs(y)[0]
def fwd(f, y, h): return (f(y + h) - f(y)) / h
def bwd(f, y, h): return (f(y) - f(y - h)) / h
def ctr(f, y, h): return (f(y + h) - f(y - h)) / (2 * h)
def fwd3(f, y, h): return (-3 * f(y) + 4 * f(y + h) - f(y + 2 * h)) / (2 * h)
def bwd3(f, y, h): return (3 * f(y) - 4 * f(y - h) + f(y - 2 * h)) / (2 * h)
def bp(x): return x * BP              # dollars per unit of yield -> dollars per bp
p0, p1, p2, p3 = derivs(Y0)
print(f"price P(4.50%) = {p0:.6f}; P(4.51%) = {P(Y0 + BP):.6f}; P(4.49%) = {P(Y0 - BP):.6f}; "
      f"P(4.52%) = {P(Y0 + 2 * BP):.6f}; P(4.48%) = {P(Y0 - 2 * BP):.6f}")
print(f"exact slope P' = {bp(p1):.6f} $/bp; P'' = {p2:.0f}; P''' = {p3:.0f}")
rules = [("forward", fwd, p2 / 2, 1), ("backward", bwd, -p2 / 2, 1), ("central", ctr, p3 / 6, 2),
         ("one-sided 3-point up", fwd3, -p3 / 3, 2), ("one-sided 3-point down", bwd3, -p3 / 3, 2)]
ratio = {}
for name, rule, c, k in rules:        # c * h^k is the leading error Taylor predicts
    est = rule(P, Y0, BP)
    err, pred = bp(est - p1), bp(c * BP ** k)
    ratio[name] = err / pred
    print(f"{name}: {est * BP:.6f} $/bp; error {err:+.6f}; Taylor predicts {pred:+.6f}; ratio {err / pred:.4f}")
print(f"forward and backward averaged = {bp(fwd(P, Y0, BP) + bwd(P, Y0, BP)) / 2:.6f} $/bp, central's value")
steps = [64, 32, 16, 8, 4, 2, 1]      # steps in basis points
print("chart steps h (bp): log10 h [" + ", ".join(f"{math.log10(s):.2f}" for s in steps) + "]")
errs = {name: [abs(bp(rule(P, Y0, s * BP) - p1)) for s in steps] for name, rule, c, k in rules}
for name in ("forward", "central", "one-sided 3-point up"):
    e = errs[name]
    lg = [f"{math.log10(v):.2f}" for v in e]
    print(f"chart {name}: log10 error [{', '.join(lg)}]; halving ratios "
          + ", ".join(f"{e[i] / e[i + 1]:.3f}" for i in range(len(e) - 1)))
print("ladder: rungs 4.50% to 4.54%, one bp apart, each priced once")
lad = [Y0 + k * BP for k in range(5)]
pv = [P(y) for y in lad]
for k, y in enumerate(lad):
    exact = bp(derivs(y)[1])
    if k == 0:
        two, three, how = (pv[1] - pv[0]) / BP, (-3 * pv[0] + 4 * pv[1] - pv[2]) / (2 * BP), "up only"
    elif k == 4:
        two, three, how = (pv[4] - pv[3]) / BP, (3 * pv[4] - 4 * pv[3] + pv[2]) / (2 * BP), "down only"
    else:
        two = three = (pv[k + 1] - pv[k - 1]) / (2 * BP); how = "both sides"
    print(f"rung +{k} bp ({how}): exact {exact:.4f}; two-point {bp(two):.4f} err {bp(two) - exact:+.4f}; "
          f"best available {bp(three):.4f} err {bp(three) - exact:+.4f}")
uneven = (P(Y0 + BP) - P(Y0 - 2 * BP)) / (3 * BP)                 # up 1 bp, down 2 bp
half = (P(Y0 + BP) - P(Y0 - BP)) / BP                             # forgot the 2 in 2h
yk = 0.04                                                         # where P hits par
cap = lambda y: min(P(y), P(yk))                                  # callable at par, crude
P1K = derivs(yk)[1]                                               # smooth slope just above 4%
kink = [(s, ctr(cap, yk, s * BP), fwd(cap, yk, s * BP), bwd(cap, yk, s * BP)) for s in (1, 0.01)]
print(f"breaks: uneven pair +1/-2 bp over 3h {bp(uneven):.6f} err {bp(uneven - p1):+.6f}; "
      f"central over h not 2h {bp(half):.4f}")
for s, c, f, b in kink:
    print(f"breaks: capped at par, y = 4.00%, h = {s} bp: up {bp(f):.4f}, down {bp(b):.4f}, "
          f"central {bp(c):.4f}; uncapped slope {bp(P1K):.4f}")
assert abs(ratio["forward"] - 1) < 0.01 and abs(ratio["backward"] - 1) < 0.01  # first-order law
assert abs(ratio["central"] - 1) < 1e-3 and abs(ratio["one-sided 3-point up"] - 1) < 0.01
assert 1.9 < errs["forward"][-2] / errs["forward"][-1] < 2.1      # halve h, halve error
assert 3.9 < errs["central"][-2] / errs["central"][-1] < 4.1      # halve h, quarter error
assert abs(bp(uneven - p1)) > 100 * abs(bp(ctr(P, Y0, BP) - p1))  # uneven pair is first order
assert abs(kink[1][1] - P1K) > 0.4 * abs(P1K)                    # kink: no shrinking with h
print("ALL CHECKS PASS")
