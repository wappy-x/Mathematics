# Carry and roll-down -- the check behind the card.  Standard library only.
# A five-year zero-coupon bond, face 100, bought today and sold in one year on
# a curve that has not moved.  Roads to the answer: (1) the closed forms for
# carry and roll, (2) repricing the bond, (3) adding up the instantaneous
# forward rate along the path the bond travels, (4) bisection on the sale
# price for the breakeven, (5) the forward curve read off discount factors.
from math import exp, log

Y = {1: 0.030, 2: 0.033, 3: 0.0365, 4: 0.0405, 5: 0.045}  # zero yields, continuous
N, T, h = 100.0, 5, 1                                      # face, maturity, holding years
r1 = Y[1]                                                  # one-year rate: cash for the year

def y(t):                          # yield at any maturity from 1 to 5: straight line between pillars
    lo = min(max(int(t), 1), 4)
    w = t - lo
    return (1 - w) * Y[lo] + w * Y[lo + 1]

def D(t): return exp(-t * y(t))    # discount factor: today's value of 1 due in t years

def fwd_inst(t, e=1e-6):           # instantaneous forward rate: the slope of t * y(t)
    return ((t + e) * y(t + e) - (t - e) * y(t - e)) / (2 * e)

def slices(f, a, b, n=4000):       # add up n thin slices of f between a and b (midpoints)
    w = (b - a) / n
    return sum(f(a + (i + 0.5) * w) for i in range(n)) * w

def bisect(g, lo, hi):             # the root of g between lo and hi, by halving
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (g(lo) > 0) == (g(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def zero_price(years_left, yld): return N * exp(-years_left * yld)

# ---- road 1: the closed forms;  road 2: reprice the bond ----
carry, roll = h * Y[5], (T - h) * (Y[5] - Y[4])
P0, flat, static = zero_price(T, Y[5]), zero_price(T - h, Y[5]), zero_price(T - h, Y[4])
total_reprice = log(static / P0)
# ---- road 3: the bond slides from 5 years to 4 and earns the forward rate on the way ----
total_path = slices(fwd_inst, T - h, T)
excess = carry + roll - h * r1
# ---- breakevens: road 4 bisection on the price, road 5 the forward yield ----
be_zero_formula = (carry + roll) / (T - h)
be_zero_bisect = bisect(lambda d: zero_price(T - h, Y[4] + d) - P0, -0.1, 0.1)
be_cash_formula = excess / (T - h)
be_cash_bisect = bisect(lambda d: zero_price(T - h, Y[4] + d) - P0 * exp(h * r1), -0.1, 0.1)
fwd_4y = log(D(1) / D(5)) / (T - h)          # the 4-year yield, one year ahead, locked in today

def pct(x): return f"{100 * x:.4f}%"
def bp(x):  return f"{10000 * x:.2f} bp"
rows = [
    ("5-year yield today", pct(Y[5])), ("4-year yield today", pct(Y[4])),
    ("roll-down in yield, 5y minus 4y", bp(Y[5] - Y[4])), ("one-year rate (cash)", pct(r1)),
    ("price today, 100 e^-5y5", f"{P0:.6f}"), ("sale price at the old 5y yield", f"{flat:.6f}"),
    ("sale price at the 4y yield", f"{static:.6f}"),
    ("carry in dollars", f"{flat - P0:.6f}"), ("roll in dollars", f"{static - flat:.6f}"),
    ("total in dollars", f"{static - P0:.6f}"),
    ("1 carry, h y(5)", pct(carry)), ("1 roll, (T-h)(y5 - y4)", pct(roll)),
    ("1 carry + roll", pct(carry + roll)), ("2 log(sale / price today)", pct(total_reprice)),
    ("3 forward rate added up, 4y to 5y", pct(total_path)),
    ("simple return, e^total - 1", pct(exp(carry + roll) - 1)),
    ("net carry, h (y5 - r1)", pct(h * (Y[5] - r1))), ("excess over cash", pct(excess)),
    ("breakeven vs zero, formula", bp(be_zero_formula)), ("breakeven vs zero, bisection", bp(be_zero_bisect)),
    ("breakeven vs cash, formula", bp(be_cash_formula)), ("breakeven vs cash, bisection", bp(be_cash_bisect)),
    ("forward 4y yield in one year", pct(fwd_4y)), ("forward minus today's 4y", bp(fwd_4y - Y[4])),
    ("wrong: 45 bp read as the return", pct(Y[5] - Y[4])),
    ("wrong: roll times 5 years", pct(T * (Y[5] - Y[4]))),
    ("wrong: breakeven over 5 years", bp(excess / T)),
    ("wrong: breakeven from roll alone", bp(roll / (T - h))),
]
for name, v in rows:
    print(f"{name:<36} {v:>14}")
def try_curve(y5, y4, y1):         # the closed forms again, for the Try-changing box
    c, r = h * y5, (T - h) * (y5 - y4)
    return f"carry {pct(c)}, roll {pct(r)}, breakeven vs cash {bp((c + r - h * y1) / (T - h))}"
print("try: 4y yield 4.80%      " + try_curve(0.045, 0.048, 0.030))
print("try: cash rate 4.50%     " + try_curve(0.045, 0.0405, 0.045))
print("try: flat curve at 4.50% " + try_curve(0.045, 0.045, 0.045))

print("\nbond, % a year   carry   roll  total   path excess  breakeven")
for m in (2, 3, 4, 5):                       # every bond on the curve, held one year
    c, r = h * y(m), (m - h) * (y(m) - y(m - h))
    p = slices(fwd_inst, m - h, m)
    print(f"{m}-year zero     {100*c:6.2f} {100*r:6.2f} {100*(c+r):6.2f} {100*p:6.2f} {100*(c+r-r1):6.2f}"
          f" {10000*(c+r-r1)/(m-h):7.2f} bp")
print("chart, years left at sale " + "".join(f"{u:9d}" for u in (1, 2, 3, 4)))
print("chart, today's curve bp   " + "".join(f"{10000*y(u):9.2f}" for u in (1, 2, 3, 4)))
print("chart, breakeven curve bp " + "".join(f"{10000*log(D(1)/D(1+u))/u:9.2f}" for u in (1, 2, 3, 4)))
shifts = [-0.005 + 0.0025 * i for i in range(11)]
print("chart, 4y yield move bp   " + "".join(f"{10000*d:7.0f}" for d in shifts))
print("chart, log return %       " + "".join(f"{100*log(zero_price(4, Y[4]+d)/P0):7.2f}" for d in shifts))

# ---- a 4.5% annual-coupon five-year bond on the same curve ----
cf = {t: 4.5 + (N if t == 5 else 0.0) for t in range(1, 6)}
Pc = sum(cf[t] * D(t) for t in cf)
q = bisect(lambda z: sum(cf[t] * exp(-z * t) for t in cf) - Pc, -0.5, 0.5)   # its own yield
w_flat = cf[1] + sum(cf[t] * exp(-q * (t - 1)) for t in cf if t > 1)
w_static = cf[1] + sum(cf[t] * D(t - 1) for t in cf if t > 1)
fwd = {u: ((1 + u) * y(1 + u) - y(1)) / u for u in (1, 2, 3, 4)}              # breakeven curve
w_fwd = cf[1] + sum(cf[t] * exp(-(t - 1) * fwd[t - 1]) for t in cf if t > 1)
be_c = bisect(lambda d: cf[1] + sum(cf[t] * D(t - 1) * exp(-(t - 1) * d) for t in cf if t > 1)
              - Pc * exp(h * r1), -0.1, 0.1)
print(f"\ncoupon bond price today {Pc:.6f}, its own yield {pct(q)}")
print(f"coupon bond carry {pct((w_flat - Pc) / Pc)}, roll {pct((w_static - w_flat) / Pc)}, "
      f"total {pct((w_static - Pc) / Pc)}")
print(f"coupon bond on the breakeven curve: growth {w_fwd / Pc:.10f}, cash e^r1 {exp(h * r1):.10f}")
print(f"coupon bond breakeven, parallel move {bp(be_c)}")

assert abs(total_path - (carry + roll)) < 1e-9, "forward rate added up must equal carry + roll"
assert abs(total_reprice - (carry + roll)) < 1e-12, "repricing must equal the closed form"
assert abs(be_cash_bisect - (fwd_4y - Y[4])) < 1e-12, "breakeven by bisection = forward minus spot"
assert abs(be_zero_bisect - be_zero_formula) < 1e-12, "zero-return breakeven, two roads"
assert abs(w_fwd / Pc - exp(h * r1)) < 1e-12, "on the forward curve every bond earns cash"
assert abs(be_cash_bisect - 0.00825) < 1e-12, "breakeven vs cash: 82.5 bp, the audited reference"
assert abs(be_zero_bisect - 0.01575) < 1e-12, "breakeven vs zero: 157.5 bp, the audited reference"
print("ALL CHECKS PASS")
