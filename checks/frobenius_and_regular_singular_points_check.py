# Frobenius check for the wire 2x y'' + y' + y = 0, tip at x = 0.  Road 1: the
# series from the recurrence.  Road 2: s = sqrt(2x) makes it y'' + y = 0 in s,
# so cos s and sin s.  Road 3: Runge-Kutta 4 from x = 1 to x = 2.
from math import sqrt, cos, sin, log
from itertools import accumulate

def series(r, x, terms=30):               # y and y' of the series with a0 = 1
    a, y, dy = 1.0, 0.0, 0.0
    for n in range(terms):
        if n > 0:
            a = -a / ((n + r) * (2 * n + 2 * r - 1))
        y += a * x ** (n + r)
        if n + r > 0 and x > 0: dy += a * (n + r) * x ** (n + r - 1)
    return y, dy
def exact(r2):                            # a0..a4 as fractions; r2 is 2r
    d, out = 1, ["1"]
    for n in range(1, 5):
        d *= (2 * n + r2) * (2 * n + r2 - 1) // 2
        out.append(("-" if n % 2 else "") + ("1" if d == 1 else f"1/{d}"))
    return ", ".join(out)
def rk4(y, v, x, h, steps):               # road 3: y'' = -(y' + y) / (2x)
    f = lambda x, y, v: (v, -(v + y) / (2 * x))
    for _ in range(steps):
        k1 = f(x, y, v)
        k2 = f(x + h / 2, y + h / 2 * k1[0], v + h / 2 * k1[1])
        k3 = f(x + h / 2, y + h / 2 * k2[0], v + h / 2 * k2[1])
        k4 = f(x + h, y + h * k3[0], v + h * k3[1])
        y += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        v += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        x += h
    return y

P0, Q0 = 0.5, 0.0                          # x p and x^2 q at the tip
b, disc = P0 - 1, sqrt((P0 - 1) ** 2 - 4 * Q0)
print(f"indicial r(r-1) + {P0:.1f} r + {Q0:.1f} = 0: roots {(-b - disc) / 2:.1f} and {(-b + disc) / 2:.1f}")
print(f"r = 0 series: {exact(0)}\nr = 1/2 series: {exact(1)}")
y1, y2, c1, c2 = series(0, 1)[0], series(0.5, 1)[0], cos(sqrt(2)), sin(sqrt(2)) / sqrt(2)
print(f"x = 1: r = 0 series {y1:.12f} (five terms {series(0, 1, 5)[0]:.12f}), cos(sqrt(2x)) {c1:.12f}")
print(f"x = 1: r = 1/2 series {y2:.12f}, sin(sqrt(2x))/sqrt(2) {c2:.12f}")
w = [(series(0, x)[0] * series(0.5, x)[1] - series(0, x)[1] * series(0.5, x)[0]) * sqrt(x) for x in (0.5, 1, 2)]
print("Wronskian times sqrt(x) at x = 0.5, 1, 2: " + ", ".join(f"{t:.12f}" for t in w))
e1, e2 = (abs(rk4(*series(0, 1), 1.0, h, n) - cos(2)) for h, n in ((0.1, 10), (0.05, 20)))
print(f"RK4 from x = 1 to 2, error: h = 0.1 {e1:.12f}, h = 0.05 {e2:.12f}, ratio {e1 / e2:.1f}")
f1, f2 = (sqrt(1e-6) * series(r, 1e-6)[1] for r in (0, 0.5))
print(f"tip heat flow sqrt(x) y' at x = 0.000001: r = 0 mode {f1:.3f}, r = 1/2 mode {f2:.3f}")
for r in (0, 0.5):
    print(f"chart r = {r:.1f}: " + ", ".join(f"{series(r, k / 2)[0]:.2f}" for k in range(11)))
g, h = (lambda x: 1 + x * log(x)), 1e-4                 # residual by finite differences
res = max(abs(x * (1 - x) * (g(x + h) - 2 * g(x) + g(x - h)) / (h * h) + x * (g(x + h) - g(x - h)) / (2 * h) - g(x)) for x in (0.25, 0.5, 0.75))
print(f"log case x(1-x)y'' + xy' - y = 0, roots 0 and 1: r = 0, n = 1 asks {1 * (1 - 1) + 0 * 1 + 0} * a1 = {-(1 * 0 + -1) * 1}")
print(f"log case: 1 + x ln x at x = 0.5 is {g(0.5):.9f}, largest residual at x = 0.25, 0.5, 0.75: {res:.9f}")
print(f"mistake, forgetting -r: roots 0 and -0.5; x^-0.5 leaves {-0.5 * (2 * -0.5 - 1):.1f} x^-1.5")
terms = [f"{t:.6f}" for t in accumulate((n * 0.1 for n in range(1, 31)), lambda a, b: a * b)][9::10]
print("mistake, irregular x^2 y'' + (3x-1) y' + y = 0, n! 0.1^n at n = 10, 20, 30: " + ", ".join(terms))
print(f"mistake, a log forced on x^2 y'' - 2x y' + 2y = 0: x ln x leaves {1 - 2 * (log(1) + 1) + 2 * log(1):.3f} at x = 1")
assert abs(y1 - c1) < 1e-12 and abs(y2 - c2) < 1e-12        # road 1 = road 2
assert all(abs(t - 0.5) < 1e-12 for t in w)                # Abel: W = (1/2) x^(-1/2)
assert e2 < 1e-8 and 14 < e1 / e2 < 18                     # road 3, fourth order
assert res < 1e-6                                          # the log partner solves it
print("ALL CHECKS PASS")
