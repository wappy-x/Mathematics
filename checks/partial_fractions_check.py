# Partial fractions -- the check behind the card.  Standard library only;
# math.log is the one primitive used, and arctan is built from its own series.
# Road one: split the fraction, integrate each piece to a log (or an arctan).
# Road two: a Simpson sum of the original, unsplit curve, refined until it closes.
import math

def simpson(f, a, b, n):                    # n even; weights 1, 4, 2, 4, ..., 4, 1
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def arctan(y):                              # the series y - y^3/3 + y^5/5 - ..., for small y
    return sum((-1) ** k * y ** (2 * k + 1) / (2 * k + 1) for k in range(30))

f = lambda x: 1 / (x * x - 1)
A, B = 1 / (1 + 1), 1 / (-1 - 1)            # cover-up: hide (x - 1), set x = 1; hide (x + 1), set x = -1
Am, Bm = (0 + 1) / 2, (0 - 1) / 2           # matching: A + B = 0 (the x's), A - B = 1 (the constants)
print(f"cover-up: A = {A:.6f}, B = {B:.6f}; matching coefficients: A = {Am:.6f}, B = {Bm:.6f}")
gap = max(abs(f(x) - (A / (x - 1) + B / (x + 1))) for x in (-3, -0.5, 0.5, 2, 2.5, 3, 10))
print(f"1/(x^2 - 1) against the two pieces at seven points, largest gap below 1e-12: {'yes' if gap < 1e-12 else 'no'}")
F = lambda x: A * math.log(abs(x - 1)) + B * math.log(abs(x + 1))
two_logs = F(3) - F(2)
print(f"two logs on 2..3: F(3) - F(2) = {two_logs:.6f}; half of ln(3/2) = {0.5 * math.log(1.5):.6f}")
for n in (4, 8, 16):
    s = simpson(f, 2.0, 3.0, n)
    print(f"Simpson, {n:2d} strips: {s:.10f}, error {s - two_logs:.10f}")
for x in (2, 2.25, 2.5, 2.75, 3):
    print(f"chart, x = {x:.2f}: curve {f(x):.2f}, A/(x - 1) {A / (x - 1):.2f}, B/(x + 1) {B / (x + 1):.2f}")
div = (9 - 4) / 2 + 0.5 * math.log(8 / 3)    # x^3/(x^2 - 1) = x + x/(x^2 - 1)
print(f"divide first, x^3/(x^2 - 1): {(9 - 4) / 2:.6f} + {div - (9 - 4) / 2:.6f} = {div:.6f}; Simpson {simpson(lambda x: x ** 3 / (x * x - 1), 2.0, 3.0, 64):.6f}")
G = lambda x: 0.25 * (-1 / (x - 1) - math.log(x - 1) - 1 / (x + 1) + math.log(x + 1))
rep = G(3) - G(2)                           # pieces -1/4, 1/4 on the logs; 1/4, 1/4 on the squares
print(f"repeated, 1/(x^2 - 1)^2: {rep:.6f}; Simpson {simpson(lambda x: f(x) ** 2, 2.0, 3.0, 64):.6f}")
quad = 0.5 * two_logs - 0.5 * arctan(1 / 7)  # arctan 3 - arctan 2 = arctan(1/7)
print(f"quadratic, 1/(x^4 - 1): {quad:.6f}; Simpson {simpson(lambda x: 1 / (x ** 4 - 1), 2.0, 3.0, 64):.6f}; arctan(1/7) {arctan(1 / 7):.6f}")
print(f"mistake, the half forgotten: {math.log(3 / 2):.6f}, not {two_logs:.6f}")
print(f"mistake, no division, pieces 1/2 and 1/2: {0.5 * math.log(8 / 3):.6f}, not {div:.6f}")
print(f"mistake, repeated factor given logs only: {0.25 * (-math.log(2) + math.log(4) - math.log(3)):.6f}, not {rep:.6f}")
print(f"mistake, F(2) - F(0) across the wall at 1: {F(2) - F(0):.6f}; 0 to 0.9999 alone {F(0.9999) - F(0):.6f}, to 0.999999 {F(0.999999) - F(0):.6f}")
assert gap < 1e-12                                                  # the pieces rebuild the curve
assert abs(two_logs - simpson(f, 2.0, 3.0, 256)) < 1e-10             # logs against strips
assert abs(rep - simpson(lambda x: f(x) ** 2, 2.0, 3.0, 256)) < 1e-9
assert abs(quad - simpson(lambda x: 1 / (x ** 4 - 1), 2.0, 3.0, 256)) < 1e-9
print("ALL CHECKS PASS")
