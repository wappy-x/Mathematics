# Derivatives of exp and log -- the check behind the card.  $100 grows at 5% a
# year, compounded continuously.  math supplies exp and log as primitives only:
# every rate is found twice, by the card's formula and by shrinking difference
# quotients on an exponential summed from its own series.
import math
R, B0, NOW = 0.05, 100.0, 10.0                 # rate, deposit, the moment we look
def my_exp(x):                                   # e^x from its series, term by term
    term, total, k = 1.0, 1.0, 0
    while abs(term) > 1e-17 * total:
        k += 1; term *= x / k; total += term
    return total
def bal(t): return B0 * my_exp(R * t)            # road 2's balance
def years_to(b): return math.log(b / B0) / R     # years until the balance reads b
def fund(t): return (100 + 10 * t) * 20 * my_exp(R * t)   # shares times price
def sec(f, x, h): return (f(x + h) - f(x)) / h   # forward difference quotient
def mid(f, x): return (f(x + 1e-5) - f(x - 1e-5)) / 2e-5  # central, for the asserts
b10 = B0 * math.exp(R * NOW); rate = R * b10     # road 1: rate = 5% of the balance
print(f"e = {my_exp(1):.6f}, e^{R * NOW:g} = {my_exp(R * NOW):.6f}; balance at {NOW:g} years {b10:.6f} "
      f"(series road {bal(NOW):.6f}); rate r x B = {rate:.6f} $/yr")
for h in (0.1, 0.01, 0.001):
    q = sec(bal, NOW, h)
    print(f"secant over h = {h:g} yr: {q:.6f} $/yr, error {q - rate:.6f}")
ok = True
for h in (0.1, 0.01, 0.001, -0.01):
    q, top = (my_exp(h) - 1) / h, 1 / (1 - h)
    lo, hi = min(1, top), max(1, top)
    ok = ok and lo <= q <= hi
    print(f"slope at zero, h = {h:g}: {lo:.6f} <= {q:.6f} <= {hi:.6f}")
print(f"tolerance: 1/(1 - h) - 1 <= 0.001 once h <= {0.001 / 1.001:.6f}")
for b in (b10, 200.0):
    print(f"years to reach {b:.2f}: {math.log(b / B0):.6f} / r = {years_to(b):.6f}; 1/(r B) = {1 / (R * b):.6f} yr per $, "
          f"secant {sec(years_to, b, 0.001):.6f}")
a10, lnb = 1.05 ** NOW, math.log(1.05)           # another base: rate x ln b
print(f"annual 5%: balance {B0 * a10:.6f}, ln 1.05 = {lnb:.6f}, rate {B0 * a10 * lnb:.6f} $/yr")
n = 100 + 10 * NOW; v, rel = fund(NOW), 10 / n + R
print(f"fund at {NOW:g} years: {n:g} shares x {20 * my_exp(R * NOW):.6f} = {v:.6f}; V'/V = {10 / n:.2f} + {R:.2f} = {rel:.2f}")
print(f"fund rate by logs {v * rel:.6f}, by product rule {10 * 20 * my_exp(R * NOW) + n * 20 * R * my_exp(R * NOW):.6f}, "
      f"by secant {mid(fund, NOW):.6f}")
print(f"mistake 1, inner 0.05 dropped: {b10:.6f} $/yr; mistake 2, power rule on 1.05^t: {B0 * NOW * 1.05 ** (NOW - 1):.6f}")
print(f"mistake 3, 5% of the annual balance: {0.05 * B0 * a10:.6f} $/yr, not {B0 * a10 * lnb:.6f}")
def stair(t): return B0 * 1.05 ** math.floor(t)  # interest credited once a year
print(f"staircase at year {NOW:g}: left secant {sec(stair, NOW, -0.001):.1f}, right secant {sec(stair, NOW, 0.001):.1f} $/yr")
pts = [2.5 * i for i in range(9)]
print("chart, balance at t = 0, 2.5, ..., 20:", ", ".join(f"{B0 * math.exp(R * t):.2f}" for t in pts))
print(f"chart, tangent at t = {NOW:g}:", ", ".join(f"{b10 + rate * (t - NOW):.2f}" for t in pts))
assert abs(mid(bal, NOW) - rate) < 1e-6                       # e^x is its own rate
assert ok                                                     # the squeeze on the slope at zero
assert abs(mid(years_to, 200.0) - 1 / (R * 200)) < 1e-8 and abs(mid(lambda t: B0 * 1.05 ** t, NOW) - B0 * a10 * lnb) < 1e-6
assert abs(mid(fund, NOW) - v * rel) < 1e-5                   # logarithmic differentiation
print("ALL CHECKS PASS")
