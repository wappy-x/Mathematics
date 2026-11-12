# Forward and backward error, the check behind the card.  Standard library only.
# A mine: pay $100 now, earn $230 in a year, pay a $132.24 cleanup bill a year later.
# NPV(x) = -100 x^2 + 230 x - c, where x = 1 + the yearly rate.  The IRR is a root.
import math
def sci(v, k=3):                              # 6.055e-4, the form Rust prints
    m, e = f"{v:.{k}e}".split("e")
    return f"{m}e{int(e)}"
def isqrt(n):                                 # whole-number square root, by halving
    lo, hi = 0, n + 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if mid * mid <= n else (lo, mid)
    return lo
C = 13224                                     # the cleanup bill in cents: $132.24
def npv100(n, d, C=C):                        # 100 d^2 NPV(n/d): exact, in whole numbers
    return -10000 * n * n + 23000 * n * d - C * d * d

# road 1: the true roots, exactly, from the quadratic formula
D = 52900 - 4 * C                             # 230^2 - 4 * 100 * c
s = isqrt(D)
assert s * s == D
print(f"true IRRs, quadratic formula: x = {(230 - s) / 200:.4f} and {(230 + s) / 200:.4f}, rates "
      f"{(30 - s) / 2:.2f}% and {(30 + s) / 2:.2f}%")
print(f"NPV at the peak, rate 15%: {npv100(23, 20) / 400:+.4f} cents")
# road 2: bisection on [1.15, 1.25] in exact fractions m/d, stopping when |NPV| < half a cent
print(f"cash flows -100, +230, -{C / 100:.2f} dollars; bisection on x in [1.15, 1.25], stop when |NPV| < 0.5 cents")
a, b, d, k = 23, 25, 20, 0
while True:
    a, b, d = 2 * a, 2 * b, 2 * d             # same bracket, finer denominator
    m, k = (a + b) // 2, k + 1
    N = npv100(m, d)
    print(f"bisection {k}: x = {m / d:.6f}, rate {100 * (m - d) / d:.4f}%, NPV {N / d / d:+.4f} cents")
    if 2 * abs(N) < d * d: break              # the stop test: |NPV| under half a cent
    a, b = (m, b) if N > 0 else (a, m)        # NPV > 0 means the root lies above m
xs = (230 + s) / 200
fe = abs(200 * m - (230 + s) * d) / (200 * d) # forward error: distance to the true root
be = abs(N) / (100 * d * d)                   # backward error: the residual, in dollars
print(f"computed rate {100 * (m - d) / d:.2f}% against true {(30 + s) / 2:.2f}%: forward error {fe:.6f} in x, {100 * fe:.4f} points")
rr = fe / ((30 + s) / 200)                     # relative error of the rate itself
print(f"rate relative error {sci(rr)}, about {-math.log10(rr):.2f} correct digits; x about {-math.log10(fe / xs):.2f}")
print(f"backward error: NPV {be:.10f} dollars, so the bill changes to {(C * d * d + N) / (100 * d * d):.10f}")
D2 = D * d * d - 4 * N                        # road 3: solve the changed problem afresh
s2 = isqrt(D2)
assert s2 * s2 == D2 and 230 * d + s2 == 200 * m
print(f"quadratic formula on the changed bill: x = {(230 * d + s2) / (200 * d):.6f}, exactly the computed root")
kap = 1 / s                                   # 1 / |slope at the root|; the slope is -s
h = 1e-6                                      # road 4: nudge the bill, re-solve, measure
xr = lambda c: (230 + (52900 - 400 * c) ** 0.5) / 200
kfd = (xr(C / 100) - xr(C / 100 + h)) / h
print(f"slope at the root {-s:.1f}, absolute condition number kappa_abs = 1/|slope| = {kap:.4f}; nudged bill gives {kfd:.6f}")
est = kap * be
print(f"rule of thumb: kappa_abs x backward = {sci(est)}; true forward {sci(fe)}; ratio {fe / est:.4f}")
smin = min(abs(200 * m - 230 * d) / d, s)     # smallest slope between computed and true root
print(f"guaranteed bound backward/smallest slope = {be:.10f}/{smin:.4f} = {sci(be / smin)}, ratio to true {be / smin / fe:.4f}")
assert abs(kfd - kap) < 1e-4 and 0.9 < fe / est < 1.1 and fe <= be / smin
assert abs((200 * m - (230 + s) * d) * (200 * m - (230 - s) * d)) == 4 * abs(N)  # mean value step, exact
rb, rf, kr = be / (C / 100), fe / xs, kap * (C / 100) / xs
print(f"relative: backward {sci(rb)}, forward {sci(rf)}, kappa_rel {kr:.2f}, estimate {sci(kr * rb)}")
# road 5: Newton in doubles, to the floor set by rounding
c = C / 100
f, df = (lambda x: (-100 * x + 230) * x - c), (lambda x: -200 * x + 230)
def exact(x):                                 # a double in [1, 2) is n52 / 2^52 exactly
    n, q = x.as_integer_ratio()
    return n * (2 ** 52 // q)
err = lambda x: (200 * exact(x) - (230 + s) * 2 ** 52) / (200 * 2 ** 52)  # true error, exact
x, k = 1.2, 0
while True:
    print(f"Newton {k}: x = {x:.16f}, computed NPV {sci(f(x), 2)}, error {sci(err(x), 2)}")
    if f(x) == 0 or k == 9: break
    x, k = x - f(x) / df(x), k + 1
tr = npv100(exact(x), 2 ** 52) / (100 * 2 ** 104)  # the true residual of that double
ex = abs(err(x))
noise = 2 ** -53 * (100 * x * x + 230 * x + c)
print(f"floor: rounding noise in NPV about {sci(noise, 2)} dollars; kappa_abs x noise = {sci(kap * noise, 2)} bound")
print(f"computed NPV 0, true NPV {sci(tr, 2)}; true error {sci(ex, 2)}, {round(ex / 2 ** -52)} steps of 2^-52, bound/true {kap * noise / ex:.2f}")
assert 0 < ex <= kap * noise and abs(ex - kap * abs(tr)) < 1e-6 * ex
# what breaks
print(f"break 1, read relative backward error as accuracy: claims {sci(rb)}, truth {sci(rf)}, {rf / rb:.1f} times worse")
e2 = (be ** 0.5) / 10                         # bill $132.25: NPV = -(10x - 11.5)^2, slope 0 at the root
x2 = (230 + (52900 - 4 * 13225 + 400 * be) ** 0.5) / 200  # the root of that problem with the bill cut by be
assert abs(x2 - 1.15 - e2) < 1e-12 and e2 > 2 * be
print(f"break 2, bill $132.25, slope 0 at x = 1.15, kappa_abs = 1/0: backward error {sci(be)} gives error {sci(e2)}")
print(f"break 3, computed NPV 0 taken as exact: x = {x:.16f} still {sci(ex, 2)} off")
pts = [npv100(4540 + 10 * j, 4000) / 16e6 for j in range(13)]  # x = 1.135 + 0.0025 j
print("chart, NPV in cents at rates 13.50% to 16.50% in steps of 0.25:", " ".join(f"{v:.4f}" for v in pts))
assert abs(pts[0] + 1.25) < 1e-12 and abs(pts[6] - 1) < 1e-12
print("ALL CHECKS PASS")
