# Growth, decay and cooling -- the check behind the card.  Standard library
# only.  y' = k y is answered by two roads: the closed form y0 e^(kt), and
# Euler's small steps along the slope, which never call exp.  Times and rates
# are found twice: by a logarithm, and by bisection, which halves a bracket
# around the answer and never calls log.
import math

def closed(y0, k, t):                     # the theorem: y = y0 e^(kt)
    return y0 * math.exp(k * t)

def euler(y0, k, t_end, h):               # new value = old value + step x rate
    y = y0
    for _ in range(round(t_end / h)):
        y = y + h * k * y
    return y

def bisect(f, lo, hi):                    # f changes sign between lo and hi
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

def coffee(t):                            # the shifted law: the gap T - 20 decays
    return 20 + closed(60, -0.1, t)

bal = closed(5000, 0.04, 10)
errs = [abs(euler(5000, 0.04, 10, h) - bal) for h in (1, 0.5, 0.25)]
k14 = -math.log(2) / 5730
k14_b = bisect(lambda k: closed(1, k, 5730) - 0.5, -0.01, 0)
t50, t50_b = 10 * math.log(2), bisect(lambda t: coffee(t) - 50, 0, 30)
slope = (coffee(5.001) - coffee(4.999)) / 0.002
fmt = lambda xs, d: " ".join(f"{x:.{d}f}" for x in xs)
print(f"balance: 5000 at 4% continuous for 10 years = {bal:.2f} dollars")
print(f"Euler, h = 1, 0.5, 0.25 years: {fmt([euler(5000, 0.04, 10, h) for h in (1, 0.5, 0.25)], 2)}")
print(f"Euler, h = 0.001 years: {euler(5000, 0.04, 10, 0.001):.2f}; errors at h = 1, 0.5, 0.25: {fmt(errs, 2)}")
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"ln 2 = {math.log(2):.4f}; doubling time ln 2 / 0.04 = {math.log(2) / 0.04:.2f} years; e^0.4 = {math.exp(0.4):.6f}")
print(f"carbon-14 k: -ln 2 / 5730 = {k14:.9f}; bisection on e^(5730k) = 1/2 gives {k14_b:.9f} per year")
print(f"bone with 30% of its carbon-14 left: ln 0.3 = {math.log(0.3):.4f}, / k = {math.log(0.3) / k14:.0f} years")
print(f"coffee t (min): {fmt(range(0, 35, 5), 0)}")
print(f"coffee T (C):   {fmt([coffee(t) for t in range(0, 35, 5)], 2)}")
print(f"coffee reaches 50 C: 10 ln 2 = {t50:.4f} min; bisection = {t50_b:.4f} min")
print(f"k read back from the gap T(5) - 20 = {coffee(5) - 20:.2f}: ln(gap / 60) / 5 = {math.log((coffee(5) - 20) / 60) / 5:.4f} per min")
print(f"rate at t = 5: finite difference {slope:.4f}; law -0.1(T - 20) = {-0.1 * (coffee(5) - 20):.4f} C/min")
print(f"mistake, cool toward 0 C: 80 e^(-0.1t) hits 50 at {math.log(80 / 50) / 0.1:.2f} min")
print(f"mistake, k from raw temperatures: ln(T(5) / 80) / 5 = {math.log(coffee(5) / 80) / 5:.4f} per min")
print(f"mistake, k = -1/5730 (ln 2 dropped): bone age {math.log(0.3) * -5730:.0f} years")
print(f"hypothesis dropped, 4% then 2% after year 5: {closed(closed(5000, 0.04, 5), 0.02, 5):.2f}, not {bal:.2f}")
assert abs(euler(5000, 0.04, 10, 0.001) - bal) < 0.1                # road two meets road one
assert 1.9 < errs[0] / errs[1] < 2.1 and 1.9 < errs[1] / errs[2] < 2.1  # Euler is order one
assert abs(t50_b - t50) < 1e-9 and abs(k14_b - k14) < 1e-8          # logs against bisection
assert abs(slope + 0.1 * (coffee(5) - 20)) < 1e-6                   # the answer obeys the law
print("ALL CHECKS PASS")
