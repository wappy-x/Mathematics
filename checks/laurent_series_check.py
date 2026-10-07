# Laurent series -- the check behind the card.  Standard library only.
# f(z) = 1/(z(z - 1)) has one expansion in the ring 0 < |z| < 1 and another in
# |z| > 1.  Road one: geometric-series algebra.  Road two: a trapezoid sum round
# a circle of radius rho, c_n = the average of f(z) z^(-n) over m equal steps.
from math import cos, sin, exp, pi

def f(z): return 1 / (z * (z - 1))
def g(z): return complex(exp(z.real) * cos(z.imag), exp(z.real) * sin(z.imag)) / z**3
def inner(n): return -1.0 if n >= -1 else 0.0          # -1/z - 1 - z - z^2 - ...
def outer(n): return 1.0 if n <= -2 else 0.0           # 1/z^2 + 1/z^3 + ...
def exp_coef(n):                                        # e^z/z^3: 1/(n + 3)! for n >= -3
    out = 1.0 if n >= -3 else 0.0
    for k in range(2, n + 4): out /= k
    return out
def contour(h, n, rho, m=128):                         # (1/2 pi i) loop of h(z)/z^(n+1) dz
    total = 0j
    for j in range(m):
        z = rho * complex(cos(2 * pi * j / m), sin(2 * pi * j / m))
        total += h(z) * z ** (-n)
    return total / m
def partial(ring, z, lo, hi): return sum(ring(n) * z**n for n in range(lo, hi + 1))
def c(w):
    re, im = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

tails = []
for name, ring, lo, hi, z in (("inner", inner, -1, 3, 0.5 + 0j), ("inner", inner, -1, 3, 0.3 + 0.4j),
                              ("outer", outer, -6, -2, 2 + 0j), ("outer", outer, -6, -2, 1.2 + 1.6j)):
    s = partial(ring, z, lo, hi)
    tail = -z**4 / (1 - z) if name == "inner" else z**-7 / (1 - 1 / z)   # geometric remainder
    tails.append(abs(f(z) - s - tail))
    print(f"{name} ring, z = {c(z)}: five terms {c(s)}, exact {c(f(z))}, gap {abs(f(z) - s):.6f}")
coef_gap = []
for name, ring, rho in (("inner", inner, 0.5), ("inner", inner, 0.75), ("outer", outer, 1.5), ("outer", outer, 2.0)):
    got = [contour(f, n, rho) for n in (-2, -1, 0)]
    coef_gap += [abs(w - ring(n)) for w, n in zip(got, (-2, -1, 0))]
    print(f"{name} ring, loop radius {rho:.2f}: c[-2] = {c(got[0])}, c[-1] = {c(got[1])}, c[0] = {c(got[2])}")
alias = [(abs(contour(f, -1, 0.5, m) - inner(-1)), 0.5**m / (1 - 0.5**m)) for m in (4, 8, 16)]
print("c[-1] error, radius 0.50, m = 4, 8, 16 steps: " + ", ".join(f"{e:.6f}" for e, _ in alias))
series = [exp_coef(n) for n in (-3, -2, -1, 0)]
loop = [contour(g, n, 1.0) for n in (-3, -2, -1, 0)]
print("e^z/z^3 by series, c[-3] c[-2] c[-1] c[0]: " + ", ".join(f"{v:.6f}" for v in series))
print("e^z/z^3 by loop radius 1, same four:      " + ", ".join(c(w) for w in loop))
print("loop integral of e^z/z^3 = 2 pi i c[-1]: " + c(2j * pi * contour(g, -1, 1.0)))
print("loop integral of z^k, k = -3..1: " + ", ".join(c(2j * pi * contour(lambda z: z**k, -1, 0.5)) for k in range(-3, 2)))
print(f"mistake 1, inner series at z = 2: {partial(inner, 2, -1, 3):.6f}, not {f(2):.6f}")
print(f"mistake 2, outer series at z = 0.5: {partial(outer, 0.5, -6, -2):.6f}, not {f(0.5):.6f}")
print(f"mistake 3, e^z/z^3 c[-1] read as 1/3!: {exp_coef(0):.6f}, not {exp_coef(-1):.6f}")
s = 50
pts = [(150 + s * z.real, 120 - s * z.imag) for z in (0j, 1 + 0j, 0.3 + 0.4j, 1.2 + 1.6j)]
print("figure, 50 units per 1: 0, 1, 0.3+0.4i, 1.2+1.6i at " + " ".join(f"({x:.0f}, {y:.0f})" for x, y in pts)
      + f"; radii {0.5 * s:.0f}, {1.0 * s:.0f}, {2.0 * s:.0f}")
assert max(coef_gap) < 1e-12                            # loop sums agree with the algebra
assert max(tails) < 1e-12                               # five terms + geometric tail = f
assert all(abs(w - v) < 1e-12 for w, v in zip(loop, series))
assert all(abs(e - p) < 1e-12 for e, p in alias)        # error is exactly rho^m/(1 - rho^m)
print("ALL CHECKS PASS")
