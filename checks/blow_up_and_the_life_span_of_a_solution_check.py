# Blow-up -- the check behind the card.  Standard library only.  The square
# scheme y' = 0.01 y^2, y(0) = 10 is answered by three roads: the closed form
# y = 100/(10 - t); Euler's small steps along the slope; and the time for each
# doubling, integrated by Simpson's rule and summed.  None calls another.
import math
K, Y0 = 0.01, 10.0

def closed(t):                              # separating gives 1/y0 - 1/y = k t
    return 1 / (1 / Y0 - K * t)

def euler(f, y, t_end, h):                  # new value = old value + step x rate
    for _ in range(round(t_end / h)):
        y = y + h * f(y)
    return y

def simpson(g, a, b, n=100):                # area under g from a to b, n even
    w = (b - a) / n
    return w / 3 * sum(g(a + i * w) * (1 if i in (0, n) else 4 if i % 2 else 2) for i in range(n + 1))

sq, lin = (lambda y: K * y * y), (lambda y: 0.1 * y)
dbl = [simpson(lambda y: 1 / sq(y), Y0 * 2**j, Y0 * 2**(j + 1)) for j in range(40)]
dbl_lin = [simpson(lambda y: 1 / lin(y), Y0 * 2**j, Y0 * 2**(j + 1)) for j in range(40)]
lo, hi = 0.0, 20.0                          # bisection: when does 10 e^(0.1t) reach 20?
for _ in range(100):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if 10 * math.exp(0.1 * mid) < 20 else (lo, mid)
t, y, h = 0.0, Y0, 1e-4                     # Euler until the members pass a million
while y < 1e6:
    y, t = y + h * sq(y), t + h
hs = (0.1, 0.05, 0.025)
e5 = [euler(sq, Y0, 5, h) for h in hs]
errs = [abs(v - closed(5)) for v in e5]
ts = list(range(10)) + [9.5]
fmt = lambda xs, d: " ".join(f"{x:.{d}f}" for x in xs)
print(f"square scheme: y' = 0.01 y^2, y(0) = 10; blow-up time 1/(k y0) = {1 / (K * Y0):.2f} months")
print(f"starting rate: square 0.01 x 10^2 = {sq(Y0):.2f}, linear 0.1 x 10 = {lin(Y0):.2f} members per month")
print(f"t (months):  {fmt(ts, 1)}")
print(f"square y:    {fmt([closed(s) for s in ts], 2)}")
print(f"linear y:    {fmt([10 * math.exp(0.1 * s) for s in ts], 2)}")
print(f"linear at t = 10: {10 * math.exp(1):.2f} members; doubling ln 2 / 0.1 = {math.log(2) / 0.1:.4f}, bisection {lo:.4f} months")
print(f"square doublings, 10->20, 20->40, ... (Simpson): {fmt(dbl[:5], 4)} months")
print(f"sum of 40 square doublings = {sum(dbl):.6f} months, ending at {Y0 * 2**40:.0f} members")
print(f"linear doublings (Simpson): {fmt(dbl_lin[:3], 4)} ...; 40 of them = {sum(dbl_lin):.2f} months")
print(f"Euler, h = 0.0001, passes 1,000,000 members at t = {t:.4f}; formula: {1 / (K * Y0) - 1 / (K * 1e6):.4f}")
print(f"Euler at t = 5, h = 0.1, 0.05, 0.025: {fmt(e5, 4)}; exact {closed(5):.4f}")
print(f"errors {fmt(errs, 4)}; ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"life span 1/(k y0) for y0 = 5, 20, 100: {fmt([1 / (K * v) for v in (5, 20, 100)], 2)} months")
print(f"bucket h' = -0.2 sqrt(h), h(0) = 25: h = (5 - 0.1t)^2 is 0 at t = {math.sqrt(25) / 0.1:.2f}, its edge")
print(f"mistake, exponential at the starting rate 0.1 per month: y(10) = {10 * math.exp(1):.2f}, not infinite")
print(f"mistake, formula read past blow-up, t = 12: y = {closed(12):.2f} members")
print(f"mistake, Euler with h = 0.5 steps through t = 10: y(10) = {euler(sq, Y0, 10, 0.5):.2f}")
assert abs(sum(dbl) - 1 / (K * Y0)) < 1e-6          # doubling sum meets the formula
assert abs(t - 10) < 0.01                            # Euler's blow-up time meets it too
assert 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2  # Euler is order one
assert abs(lo - dbl_lin[0]) < 1e-6                   # bisection meets Simpson on 6.93
print("ALL CHECKS PASS")
