# Power series at an ordinary point -- the check behind the card.  Standard library
# only.  A 2 mm steel rod hangs from a tilted clamp; its tilt y at height x above the
# free tip (x in natural lengths) obeys Airy's y'' = x y, y(0) = 1, y'(0) = 0.  Road one:
# the coefficient recurrence, summed.  Road two: Runge-Kutta 4.  Second case: arctan.
import math

def horner(a, x):                        # a[0] + a[1] x + a[2] x^2 + ...
    s = 0.0
    for c in reversed(a):
        s = s * x + c
    return s

def rk4(f, x, s, x1, n):                 # s = [y, y'], f returns [y', y'']
    h = (x1 - x) / n
    for _ in range(n):
        k1 = f(x, s)
        k2 = f(x + h / 2, [s[i] + h / 2 * k1[i] for i in (0, 1)])
        k3 = f(x + h / 2, [s[i] + h / 2 * k2[i] for i in (0, 1)])
        k4 = f(x + h, [s[i] + h * k3[i] for i in (0, 1)])
        s = [s[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)]
        x += h
    return s[0]

airy = lambda x, s: [s[1], x * s[0]]
atan_eq = lambda x, s: [s[1], -2 * x * s[1] / (1 + x * x)]
a = [1.0, 0.0, 0.0] + [0.0] * 30         # a_(n+3) = a_n / ((n + 3)(n + 2))
for n in range(30):
    a[n + 3] = a[n] / ((n + 3) * (n + 2))
b = [0.0, 1.0] + [0.0] * 400             # a_(n+2) = -n a_n / (n + 2)
for n in range(1, 400):
    b[n + 2] = -n * b[n] / (n + 2)
ell = (200e9 * 0.002 ** 2 / (16 * 7850 * 9.81)) ** (1 / 3)
print(f"natural length (E d^2 / (16 rho g))^(1/3), 2 mm steel: {ell * 1000:.1f} mm")
print("1/a3, 1/a6, 1/a9, 1/a12:", " ".join(f"{1 / a[k]:.0f}" for k in (3, 6, 9, 12)))
print("partial sums at x = 1, degree 3/6/9/12:", " ".join(f"{horner(a[:d + 1], 1.0):.9f}" for d in (3, 6, 9, 12)))
y1 = horner(a, 1.0)
print(f"series to degree 30 at x = 1: {y1:.12f}")
errs = [rk4(airy, 0.0, [1.0, 0.0], 1.0, n) - y1 for n in (5, 10, 20)]
print("RK4 errors x 1e9 at h = 0.2/0.1/0.05:", " ".join(f"{e * 1e9:.1f}" for e in errs))
print(f"error ratio when h halves: {errs[0] / errs[1]:.1f}, {errs[1] / errs[2]:.1f}")
print(f"clamp tilted 2.000 deg: tip tilt {2 / y1:.3f} deg")
print("Airy ratio ((n+3)(n+2))^(1/3) at n = 30, 300:", " ".join(f"{((n + 3) * (n + 2)) ** (1 / 3):.1f}" for n in (30, 300)))
dist = math.sqrt(4 * 1 * 1 - 0 * 0) / 2  # 1 + x^2 = 0: roots 0 +/- (sqrt(4ac - b^2) / 2a) i
print(f"second case: 1 + x^2 = 0 at 0 +/- {dist:.3f}i, distance {dist:.3f}")
est = math.sqrt(abs(b[399] / b[401]))
print(f"ratio estimate sqrt|a_399 / a_401|: {est:.5f}")
s05, r05 = horner(b[:41], 0.5), rk4(atan_eq, 0.0, [0.0, 1.0], 0.5, 40)
print(f"at x = 0.5: series 20 terms {s05:.9f}, RK4 {r05:.9f}")
r2 = rk4(atan_eq, 0.0, [0.0, 1.0], 2.0, 200)
print("at x = 2: series 5/10/20 terms", " ".join(f"{horner(b[:2 * k + 1], 2.0):.1f}" for k in (5, 10, 20)) + f"; RK4 {r2:.9f}")
print(f"mistake, x frozen at 1 (y'' = y, y = cosh x): y(1) = {(math.exp(1) + math.exp(-1)) / 2:.6f}")
xs = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
print("figure, x:          ", " ".join(f"{x:5.2f}" for x in xs))
print("figure, series y:   ", " ".join(f"{horner(a, x):5.2f}" for x in xs))
print("figure, 1 + x^3/6:  ", " ".join(f"{1 + x ** 3 / 6:5.2f}" for x in xs))
assert abs(rk4(airy, 0.0, [1.0, 0.0], 1.0, 80) - y1) < 1e-9          # two roads, one tilt
assert 14 < errs[0] / errs[1] < 18 and 14 < errs[1] / errs[2] < 18  # fourth order
assert abs(s05 - r05) < 1e-9 and abs(horner(b[:41], 2.0)) > 100 * r2  # inside vs outside radius
assert abs(est - dist) < 0.01                                        # radius = distance to +/- i
print("ALL CHECKS PASS")
