# Sturm-Liouville and orthogonality -- the check behind the card.  Standard library only;
# integrator, Bessel functions and root finder are written here.  Each claim is reached
# twice: Simpson against antiderivatives, J0 zeros by series and by integral, norm by J1.
from math import sin, cos, pi, acos, sqrt

def simpson(f, a, b, n=2000):                  # Simpson's rule, n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))) * h / 3

def z(v): return 0.0 if abs(v) < 5e-10 else v  # print a vanishing number as 0
def j_series(x, order=0):                      # J0 or J1 from its power series
    term, total, k = (x / 2) ** order, (x / 2) ** order, 0
    while abs(term) > 1e-18:
        k += 1
        term *= -(x / 2) ** 2 / (k * (k + order))
        total += term
    return total

def j0_integral(x):                            # J0(x) = (1/pi) * integral of cos(x sin t)
    return simpson(lambda t: cos(x * sin(t)), 0, pi, 200) / pi
def bisect(f, lo, hi):                         # root finder, 60 halvings
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

pairs = ((1, 1), (1, 2), (2, 2), (1, 3), (2, 3))
num = [simpson(lambda x: sin(m * pi * x) * sin(n * pi * x), 0, 1) for m, n in pairs]
anti = [0.5 if m == n else (sin((m - n) * pi) / (m - n) - sin((m + n) * pi) / (m + n)) / (2 * pi)
        for m, n in pairs]
print("string, Simpson:       " + " ".join(f"({m},{n}) {z(v):.6f}" for (m, n), v in zip(pairs, num)))
print("string, antiderivative:" + "".join(f" ({m},{n}) {z(v):.6f}" for (m, n), v in zip(pairs, anti)))
assert max(abs(a - b) for a, b in zip(num, anti)) < 1e-12
lobe = simpson(lambda x: sin(pi * x) * sin(2 * pi * x), 0, 0.5)
print(f"lobes of sin(pi x) sin(2 pi x): +{lobe:.6f} and -{lobe:.6f}; 2/(3 pi) = {2 / (3 * pi):.6f}")
j1, j2 = bisect(j_series, 2, 3), bisect(j_series, 5, 6)
i1, i2 = bisect(j0_integral, 2, 3), bisect(j0_integral, 5, 6)
print(f"drum J0 zeros, series road: {j1:.9f}, {j2:.9f}; integral road: {i1:.9f}, {i2:.9f}")
assert abs(j1 - i1) < 1e-9 and abs(j2 - i2) < 1e-9
wcross = simpson(lambda r: r * j_series(j1 * r) * j_series(j2 * r), 0, 1)
wnorm = simpson(lambda r: r * j_series(j1 * r) ** 2, 0, 1)
bare = simpson(lambda r: j_series(j1 * r) * j_series(j2 * r), 0, 1)
half_j1sq = j_series(j1, 1) ** 2 / 2
print(f"drum, weight r: cross {z(wcross):.9f}; norm {wnorm:.9f}, J1(j1)^2/2 = {half_j1sq:.9f}")
print(f"drum, weight dropped: cross {bare:.6f}, not 0")
assert abs(wcross) < 1e-10 and abs(wnorm - half_j1sq) < 1e-10
cs = [2 * simpson(lambda x: x * (1 - x) * sin(n * pi * x), 0, 1) for n in (1, 2, 3)]
cp = [4 * (1 - (-1) ** n) / (n * pi) ** 3 for n in range(1, 8)]
print("arch x(1 - x), c_1 c_2 c_3 by Simpson: " + " ".join(f"{z(c):.6f}" for c in cs))
print("arch x(1 - x), c_1 c_2 c_3 by parts:   " + " ".join(f"{c:.6f}" for c in cp[:3]))
assert max(abs(a - b) for a, b in zip(cs, cp)) < 1e-12
sums = [sum(cp[k] * sin((k + 1) * pi / 2) for k in range(n)) for n in (1, 3, 5, 7)]
print("partial sums at x = 0.5, target 0.25: " + ", ".join(f"N={2 * i + 1} {s:.6f}" for i, s in enumerate(sums)))
print(f"mistake, norm 1/2 left out: c_1 = {4 / pi ** 3:.6f}, half the true {cp[0]:.6f}")
print(f"mistake, slope-zero mode 1 against sin(pi x): {simpson(lambda x: sin(pi * x), 0, 1):.6f}, not 0")
xp = acos(1 / sqrt(3)) / pi
yp = sin(pi * xp) * sin(2 * pi * xp)
print(f"figure, peak x = {xp:.4f} value {yp:.4f} at ({40 + 280 * xp:.1f}, {120 - 100 * yp:.1f}), "
      f"trough at ({40 + 280 * (1 - xp):.1f}, {120 + 100 * yp:.1f})")
print("ALL CHECKS PASS")
