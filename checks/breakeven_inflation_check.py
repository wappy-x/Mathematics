# Breakeven inflation -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  The breakeven is reached
# by three roads: the closed form, bisection on two zero-coupon payoffs, and
# Newton's method on a coupon linker's price.  The root finders are our own.
from math import log

T, n, r = 10, 0.03525, 0.01        # years; nominal yield; real yield (annual effective)
c, k, FACE = 0.01, 0.026, 1000.0   # linker's real coupon; swap fixed rate; dollars invested

def closed_form(n, r):             # Road 1: divide the growth factors, subtract one
    return (1 + n) / (1 + r) - 1

def bisect(f, lo, hi, steps=200):  # halve a sign-changing bracket until it is tiny
    assert f(lo) < 0 < f(hi), "bracket must straddle the root"
    for _ in range(steps):
        mid = (lo + hi) / 2
        if f(mid) < 0: lo = mid
        else: hi = mid
    return (lo + hi) / 2

def zero_gap(pi, n=n, r=r, T=T):   # Road 2: linker zero minus nominal zero, in dollars at year T
    return FACE * (1 + r) ** T * (1 + pi) ** T - FACE * (1 + n) ** T

def real_price(c, y, T):           # a bond's price per 1 of face, flows in real units, at yield y
    return sum(c / (1 + y) ** t for t in range(1, T + 1)) + 1 / (1 + y) ** T

def linker_pv(pi, c, n, T):        # the linker's flows inflated at pi, discounted at the nominal yield
    return sum(c * (1 + pi) ** t / (1 + n) ** t for t in range(1, T + 1)) + (1 + pi) ** T / (1 + n) ** T

def newton(f, x, steps=50, h=1e-7):  # Road 3: slide down the tangent, slope by nudging
    for _ in range(steps):
        x -= f(x) / ((f(x + h) - f(x - h)) / (2 * h))
    return x

pi1 = closed_form(n, r)
pi2 = bisect(zero_gap, -0.5, 1.0)
P_c = real_price(c, r, T)                                   # the 1% linker, priced off its real yield
pi3 = newton(lambda p: linker_pv(p, c, n, T) - P_c, 0.0)
P_lo = real_price(0.00125, r, T)                            # a second linker, 0.125% coupon
pi4 = newton(lambda p: linker_pv(p, 0.00125, n, T) - P_lo, 0.0)

J = (1 + pi1) ** T                                          # index ratio that makes the bonds tie
nominal_end = FACE * (1 + n) ** T
linker_real_end = FACE * (1 + r) ** T
spread = n - r
cont = log(1 + n) - log(1 + r)                              # continuous-rate breakeven

# ---- reading against the inflation swap ----
basis = k - pi1
synth_real = (1 + n) / (1 + k) - 1                          # nominal bond + receive CPI, pay fixed
locked = FACE * ((1 + r) * (1 + k)) ** T                    # linker + pay CPI, receive fixed
receiver_at_tie = FACE * ((1 + pi1) ** T - (1 + k) ** T)

# ---- what breaks ----
inverted = (1 + r) / (1 + n) - 1
simple_ann = (J - 1) / T
y_sa = 2 * ((1 + n) ** 0.5 - 1)                             # the same nominal yield quoted semiannually
mixed = (1 + y_sa) / (1 + r) - 1

# ---- boundary: nominal yield below real yield, principal floor ----
n_low = 0.005
pi_low = closed_form(n_low, r)
floor_min = FACE * (1 + r) ** T                             # floored linker pays at least this
nominal_low = FACE * (1 + n_low) ** T

rows = [
    ("1 closed form, pct", 100 * pi1), ("2 bisection, zero bonds, pct", 100 * pi2),
    ("3 Newton, 1% coupon linker, pct", 100 * pi3), ("  linker price per 1000", 1000 * P_c),
    ("4 Newton, 0.125% coupon linker, pct", 100 * pi4), ("  linker price per 1000", 1000 * P_lo),
    ("growth ratio (1+n)/(1+r)", (1 + n) / (1 + r)),
    ("index ratio at the tie J*", J),
    ("nominal zero at year 10, $", nominal_end), ("linker zero, real units, $", linker_real_end),
    ("linker zero at the tie, $", linker_real_end * J),
    ("linker if inflation 2%, $", linker_real_end * 1.02 ** T),
    ("linker if inflation 3%, $", linker_real_end * 1.03 ** T),
    ("shortcut spread n - r, pct", 100 * spread), ("shortcut error, bp", 10000 * (spread - pi1)),
    ("  r times breakeven, bp", 10000 * r * pi1),
    ("continuous-rate breakeven, pct", 100 * cont),
    ("swap fixed rate, pct", 100 * k), ("swap minus breakeven, bp", 10000 * basis),
    ("synthetic real yield, pct", 100 * synth_real),
    ("linker + pay-CPI swap at year 10, $", locked), ("  gain over nominal zero, $", locked - nominal_end),
    ("CPI receiver at the tie path, $", receiver_at_tie),
    ("wrong: inverted ratio, pct", 100 * inverted),
    ("wrong: simple annualising, pct", 100 * simple_ann),
    ("  nominal yield quoted semiannual, pct", 100 * y_sa),
    ("wrong: semiannual over annual, pct", 100 * mixed),
    ("boundary: n = 0.5%, breakeven pct", 100 * pi_low), ("  index ratio at that tie", (1 + pi_low) ** T),
    ("  floored linker at least, $", floor_min), ("  nominal zero, $", nominal_low),
    ("try: real yield 2%, pct", 100 * closed_form(n, 0.02)),
    ("try: nominal yield 5%, pct", 100 * closed_form(0.05, r)),
    ("try: 30 years, bisection, pct", 100 * bisect(lambda p: zero_gap(p, T=30), -0.5, 1.0)),
    ("try: swap 2.5%, synthetic real, pct", 100 * ((1 + n) / 1.025 - 1)),
]
for name, v in rows:
    print(f"{name:<38} {v:>12.6f}")

grid = [0.005 * i for i in range(11)]
print(f"{'chart, inflation pct':<22}" + "".join(f"{100 * p:>9.1f}" for p in grid))
print(f"{'chart, linker $':<22}" + "".join(f"{linker_real_end * (1 + p) ** T:>9.2f}" for p in grid))
print(f"{'chart, nominal $':<22}" + "".join(f"{nominal_end:>9.2f}" for p in grid))

# linker + pay-CPI swap is fixed whatever the index does: test on random index ratios
seed, worst = 20260928, 0.0
for _ in range(1000):
    seed = (6364136223846793005 * seed + 1442695040888963407) % 2 ** 64
    Jx = 0.5 + 1.5 * (seed >> 11) / 2 ** 53                 # an index ratio between 0.5 and 2
    linker_leg = FACE * (1 + r) ** T * Jx
    swap_leg = FACE * (1 + r) ** T * ((1 + k) ** T - Jx)   # pay CPI growth, receive fixed
    worst = max(worst, abs(linker_leg + swap_leg - locked))

assert abs(pi2 - pi1) < 1e-12, "bisection on zero payoffs must land on the closed form"
assert abs(pi3 - pi1) < 1e-10, "Newton on the coupon linker must land on the closed form"
assert abs(pi4 - pi1) < 1e-10, "the coupon must not move the breakeven"
assert abs((spread - pi1) - r * pi1) < 1e-15, "shortcut error must equal r times breakeven"
assert zero_gap(0.02) < 0 < zero_gap(0.03), "linker loses below, wins above"
assert worst < 1e-9, "linker + pay-CPI swap must be fixed on every index path"
assert floor_min > nominal_low, "with n < r the floored linker beats the nominal bond: no tie"
print("ALL CHECKS PASS")
