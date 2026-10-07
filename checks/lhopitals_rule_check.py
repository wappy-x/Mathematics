# L'Hopital's rule -- the check behind the card.  math supplies sin, cos, exp
# and sqrt only; every rate comes from the card's own difference quotient.
# Example one: sin x / x as x heads for 0.  Example two: x e^(-x) as x heads
# for infinity, rearranged to x / e^x.
from math import sin, cos, exp, sqrt, pi

def rate(f, x, h=1e-5):                  # central difference quotient
    return (f(x + h) - f(x - h)) / (2 * h)

def ident(x):
    return x

def bisect(fun, lo, hi):                 # a root of fun between lo and hi
    for _ in range(200):
        mid = (lo + hi) / 2
        if (fun(lo) > 0) == (fun(mid) > 0):
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2

xs = [0.25 * k for k in range(1, 9)]
print("chart x:        ", " ".join(f"{x:.2f}" for x in xs))
print("chart sin x / x:", " ".join(f"{sin(x) / x:.2f}" for x in xs))
print("chart cos x:    ", " ".join(f"{cos(x):.2f}" for x in xs))
for x in (0.5, 0.1, 0.01):
    orig = sin(x) / x                                # road one: the ratio itself
    ratio = rate(sin, x) / rate(ident, x)            # road two: the two rates
    c = bisect(lambda t: cos(t) - orig, 0.0, x)      # Cauchy's shared point
    print(f"x={x}: sin x / x = {orig:.6f}, rate ratio = {ratio:.6f}, "
          f"c = {c:.6f}, c/x = {c / x:.5f}")
    assert cos(x) < orig < 1 and abs(orig - rate(sin, c) / rate(ident, c)) < 1e-8
print(f"c/x heads for 1/sqrt(3) = {1 / sqrt(3):.5f}")
assert abs(c / x - 1 / sqrt(3)) < 1e-4
tol = 0.001
d = sqrt(2 * tol)                                    # 1 - cos c <= c^2/2 < tol
print(f"tolerance {tol}: stay within {d:.4f} of 0; cos {d:.4f} = {cos(d):.7f}, "
      f"sin x / x there = {sin(d) / d:.6f}")
assert 1 - sin(d) / d < tol and 1 - cos(d) < tol
for x in (5, 10, 15):
    orig = x * exp(-x)
    ratio = rate(ident, x) / rate(exp, x)            # x / e^x, rates separately
    print(f"x={x}: x e^-x = {orig:.9f}, rate ratio 1/e^x = {ratio:.9f}")
    assert abs(ratio - exp(-x)) / exp(-x) < 1e-6
t = bisect(lambda x: x * exp(-x) - tol, 2.0, 20.0)
print(f"x e^-x stays below {tol} once x passes {t:.4f}")
x = 0.01
print(f"mistake, not 0/0: sin x/(x+1) at x={x} is {sin(x) / (x + 1):.6f}; "
      f"rates give {rate(sin, x) / rate(lambda u: u + 1, x):.6f}")
print(f"mistake, quotient rule: rate of sin x / x at x={x} is {rate(lambda u: sin(u) / u, x):.6f}")
for x in (20 * pi, 21 * pi):
    print(f"mistake, swinging rates: x={x:.4f}: (x + sin x)/x = {(x + sin(x)) / x:.6f}, "
          f"rate ratio = {round(rate(lambda u: u + sin(u), x), 6) + 0.0:.6f}")
x = 10
print(f"mistake, wrong rearrangement e^-x/(1/x) at x={x}: rate ratio = "
      f"{rate(lambda u: exp(-u), x) / rate(lambda u: 1 / u, x):.6f}, original {x * exp(-x):.6f}")
print("ALL CHECKS PASS")
