# The Euler-Lagrange equation -- the check behind the card.  Standard library only.
# A cable runs from pylon A = (0, 0) to pylon B = (400, 300), in metres.  Rocky
# ground past x = 200 m doubles the price, from 80 to 160 pounds a metre.
from math import sqrt, sin, cos, pi
X, Y, M, h = 400.0, 300.0, 0.75, 1e-4               # far pylon, the line's slope, a small step

def simpson(f, a, b, n=2000):                       # Simpson's rule, written out here
    w = (b - a) / n
    return w / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * w) for k in range(1, n)))

length = lambda dy: simpson(lambda x: sqrt(1 + dy(x) ** 2), 0, X)          # L[y], from the slope y'
first_variation = lambda dy, de: simpson(lambda x: dy(x) / sqrt(1 + dy(x) ** 2) * de(x), 0, X)

def quotient(dy, de):                               # the same derivative, by nudging both ways
    return (length(lambda x: dy(x) + h * de(x)) - length(lambda x: dy(x) - h * de(x))) / (2 * h)

def descend(price, n=10):                           # direct method: a route through nodes every X/n metres
    dx, y = X / n, [Y * k / n + 50 * sin(pi * k / n) for k in range(n + 1)]
    for _ in range(2000):
        for i in range(1, n):
            ca, cb, a, b = price((i - 0.5) * dx), price((i + 0.5) * dx), y[i - 1], y[i + 1]
            lo, hi = min(a, b), max(a, b)
            for _ in range(60):                     # bisection: where the local cost stops falling
                m = (lo + hi) / 2
                up = ca * (m - a) / sqrt(dx * dx + (m - a) ** 2) < cb * (b - m) / sqrt(dx * dx + (b - m) ** 2)
                lo, hi = (m, hi) if up else (lo, m)
            y[i] = (lo + hi) / 2
    return y, sum(price((i + 0.5) * dx) * sqrt(dx * dx + (y[i + 1] - y[i]) ** 2) for i in range(n))

line, de = (lambda x: M), (lambda x: 40 * pi / X * cos(pi * x / X))     # bulge eta = 40 sin(pi x / 400)
bow = lambda x: M + 60 * pi / X * cos(pi * x / X)                      # y = 0.75x + 60 sin(pi x / 400)
print(f"straight line y = 0.75x: length {length(line):.6f} m")
print("line plus e x bulge, e = -1, -0.5, 0, 0.5, 1: lengths", ", ".join(f"{length(lambda x: M + e * de(x)):.2f}" for e in (-1, -0.5, 0, 0.5, 1)), "m")
print(f"second-order term, by hand: {simpson(lambda x: de(x) ** 2, 0, X) / (2 * 1.25 ** 3):.6f} m times e^2")
fl, fb, qb = abs(first_variation(line, de)), first_variation(bow, de), quotient(bow, de)
print(f"first variation at the line: formula {fl:.6f} m, quotient {abs(quotient(line, de)):.6f} m")
print(f"first variation at the bowed route: formula {fb:.6f} m, quotient {qb:.6f} m")
print(f"moving pylon B 10 m north: first variation {first_variation(line, lambda x: 10 / X):.6f} m")
yf, lf = descend(lambda x: 1.0)
dev = max(abs(yf[k] - M * 40 * k) for k in range(11))
print(f"direct method, flat ground: length {lf:.6f} m, largest gap from y = 0.75x {dev:.6f} m")
g = lambda s: 80 * s / sqrt(200 ** 2 + s * s) - 160 * (Y - s) / sqrt(200 ** 2 + (Y - s) ** 2)
lo, hi = 0.0, Y
for _ in range(100):                                # bisection on 80 sin = 160 sin
    lo, hi = ((lo + hi) / 2, hi) if g((lo + hi) / 2) < 0 else (lo, (lo + hi) / 2)
s = (lo + hi) / 2
cost = 80 * sqrt(200 ** 2 + s * s) + 160 * sqrt(200 ** 2 + (Y - s) ** 2)
print(f"rocky, Euler-Lagrange road: cross x = 200 at y = {s:.4f} m, cost {cost:.2f} pounds")
yr, cr = descend(lambda x: 80.0 if x < 200 else 160.0)
sg, sr = [(yr[j + 1] - yr[j]) / sqrt(1600 + (yr[j + 1] - yr[j]) ** 2) for j in (0, 9)]
print(f"rocky, direct road: cross at y = {yr[5]:.4f} m, cost {cr:.2f} pounds")
print(f"rocky, sines {sg:.4f} and {sr:.4f}; 80 x {sg:.4f} = {80 * sg:.4f}, 160 x {sr:.4f} = {160 * sr:.4f}")
print(f"mistake, straight line on rocky ground: {80 * 250 + 160 * 250:.2f} pounds, {60000 - cost:.2f} too much")
print(f"mistake, least rock (straight across it): {80 * sqrt(200 ** 2 + Y ** 2) + 160 * 200:.2f} pounds")
print(f"figure, px = 50 + 0.6x, py = 210 - 0.6y: A (50, 210), B (290, 30), crossings (170, 120.0), (170, {210 - 0.6 * s:.1f})")
assert abs(lf - 500) < 1e-6 and dev < 1e-6                  # direct method finds the Euler-Lagrange line
assert abs(fb - qb) < 1e-5 and abs(fb) > 1 and fl < 1e-9    # formula = derivative; zero only at the line
assert abs(cr - cost) < 1e-4 and abs(yr[5] - s) < 1e-4       # two roads, one bent route
assert abs(sg / sr - 2) < 1e-6                              # 80 sin on grass = 160 sin on rock
print("ALL CHECKS PASS")
