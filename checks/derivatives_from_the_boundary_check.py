# Derivatives from the boundary.  Standard library; built-in complex.  f(z) = z^3,
# a = 1, rim |z - 1| = 1 anticlockwise.  Road one: the power rule on coefficients.
# Road two: n!/(2 pi i) times the loop integral, a trapezoid sum round the rim.
import math

def loop(g, c, r, n=64):                  # trapezoid sum of g(z) dz round |z - c| = r
    total = 0
    for k in range(n):
        w = complex(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n))
        total += g(c + r * w) * (1j * r * w) * (2 * math.pi / n)
    return total

fact = lambda n: 1 if n == 0 else n * fact(n - 1)   # n! = 1 x 2 x ... x n

def rim(g, a, n, r=1.0, pts=64):          # n!/(2 pi i) x loop of g(z)/(z - a)^(n+1)
    return fact(n) / (2j * math.pi) * loop(lambda z: g(z) / (z - a) ** (n + 1), a, r, pts)

def power_rule(coeffs, n, a):             # differentiate c0 + c1 z + ... n times, then evaluate
    for _ in range(n):
        coeffs = [k * coeffs[k] for k in range(1, len(coeffs))]
    return sum(c * a ** k for k, c in enumerate(coeffs))

def edge_sum(g, p, q, m=10):              # Simpson's rule for g(z) dz along the segment p -> q
    h = (q - p) / m
    return sum((1 if j in (0, m) else 4 if j % 2 else 2) * g(p + j * h) for j in range(m + 1)) * h / 3

def show(v):                              # a + bi, six decimals, rounding noise shown as 0
    re, im = (0.0 if abs(x) < 5e-7 else x for x in (v.real, v.imag))
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def sci(x):                               # 1.2e-5 style, the same in both languages
    e = math.floor(math.log10(x)); m = round(x / 10 ** e, 1)
    return f"{m / 10:.1f}e{e + 1}" if m >= 10 else f"{m:.1f}e{e}"

f, cube = (lambda z: z ** 3), [0, 0, 0, 1]
peak = lambda r: max(abs(f(1 + r * complex(math.cos(k * math.pi / 180), math.sin(k * math.pi / 180)))) for k in range(360))
M = peak(1)                               # largest |z^3| over 360 rim points: 8, at z = 2
print("figure, 80 units per 1: 0 at (100, 120), a = 1 at (180, 120), rim radius 80, 2 at (260, 120), 1 + i at (180, 40)")
for n in range(5):
    print(f"n = {n}: power rule {power_rule(cube, n, 1)}; rim, 64 points = {show(rim(f, 1, n))}; bound {n}! x 8 / 1^{n} = {fact(n) * M:g}")
print("f''(1) from the rim with 2, 3, 4 points: " + ", ".join(show(rim(f, 1, 2, pts=p)) for p in (2, 3, 4)))
exp = lambda z: math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))   # e^z from exp, cos, sin
print("second case, e^z at 0, f''(0) = 1, error with 4, 8, 12 points: " + ", ".join(sci(abs(rim(exp, 0, 2, pts=p) - 1)) for p in (4, 8, 12)))
print("bound on |f''(1)| from radius r, 2 (1 + r)^3 / r^2: " + ", ".join(f"r = {r:g}: {2 * peak(r) / r ** 2:.6f}" for r in (0.5, 1, 2, 3, 4)))
grid = min((2 * peak(r / 100) / (r / 100) ** 2, r / 100) for r in range(10, 501))     # M measured per radius
tri = (0, 2, 1 + 1j)
around = lambda g: sum(edge_sum(g, tri[k], tri[(k + 1) % 3]) for k in range(3))
area = 0.5 * sum(tri[k].real * tri[(k + 1) % 3].imag - tri[(k + 1) % 3].real * tri[k].imag for k in range(3))
print(f"regatta triangle 0 -> 2 -> 1 + i: loop of z^3 = {show(around(f))}; loop of z-bar = {show(around(lambda z: z.conjugate()))}; shoelace area {area:g}")
bad = rim(lambda z: 1 / z, 1, 2, r=1.5, pts=128)
print(f"mistake 1, f = 1/z on |z - 1| = 1.5, which circles 0: rim gives {show(bad)}, not f''(1) = 2 / 1^3 = {2 / 1 ** 3:g}")
print(f"mistake 2, n! left off: rim gives {show(rim(f, 1, 2) / 2)}, not 6")
print(f"mistake 3, M read at the centre, |f(1)| = 1: bound 2! x 1 / 1^2 = {fact(2) * abs(f(1)):g}, below the true 6")
print(f"real contrast, x|x| has slope 2|x|; its difference quotients at 0, right and left: "
      f"{(2 * abs(1e-3) - 0) / 1e-3:.6f} and {(2 * abs(-1e-3) - 0) / -1e-3:.6f}")
assert all(abs(rim(f, 1, n, r) - power_rule(cube, n, 1)) < 1e-12 for n in range(5) for r in (0.5, 1))  # two roads
assert M == 8 and all(abs(power_rule(cube, n, 1)) <= fact(n) * M for n in range(5)) and abs(grid[0] - 13.5) < 1e-12 and grid[1] == 2
assert abs(around(f)) < 1e-12 and abs(around(lambda z: z.conjugate()) - 2j * area) < 1e-12   # Morera's test, and z-bar
assert abs(bad - (2 / 1 ** 3 + fact(2) / (0 - 1) ** 3)) < 1e-12                        # the pole at 0 adds 2! x 1/(0 - 1)^3
print("ALL CHECKS PASS")
