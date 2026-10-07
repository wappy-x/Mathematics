# Zeros and the identity theorem -- the check behind the card.  Standard library only.
# Road one: Taylor coefficients by formula, sin and cos at 1 + 2i by their own series.
# Road two: coefficients by a trapezoid sum round |z| = 0.5, sin and cos from exponentials.
# The identity's own Taylor series is then summed exactly, in whole numbers.
import math

def show(x):                                        # six decimals, no -0.000000
    return f"{round(x, 6) + 0.0:.6f}"
def showc(w):                                       # 'a + bi', six decimals
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def cexp(w):                                        # e^w from real exp, cos, sin
    return math.exp(w.real) * complex(math.cos(w.imag), math.sin(w.imag))
def sin_exp(z): return (cexp(1j * z) - cexp(-1j * z)) / 2j
def cos_exp(z): return (cexp(1j * z) + cexp(-1j * z)) / 2
def p(z): return z * z * (z - 1)
def series(z, start):                               # sin (start 1) or cos (start 0), term by term
    term, total = z ** start / math.factorial(start), 0j
    for k in range(start, 60, 2):
        total += term
        term *= -z * z / ((k + 1) * (k + 2))
    return total
def contour(f, n, r=0.5, steps=256):                # c_k = (1/(2 pi i)) loop f(z) / z^(k+1) dz
    pts = [r * cexp(2j * math.pi * j / steps) for j in range(steps)]
    return [sum(f(z) / z ** k for z in pts).real / steps for k in range(n)]
def order(c): return next(k for k, x in enumerate(c) if abs(x) > 1e-9)

sin_c = [0 if k % 2 == 0 else (-1) ** (k // 2) / math.factorial(k) for k in range(6)]
sq, lin = [0, 0, 1], [-1, 1]                        # z^2 and z - 1 as coefficient lists
p_c = [sum(sq[i] * lin[k - i] for i in range(3) if 0 <= k - i < 2) for k in range(6)]   # multiplied out
sin_k, p_k = contour(sin_exp, 6), contour(p, 6)
print("sin z, c0..c3 by formula: " + ", ".join(show(x) for x in sin_c[:4]) + "; by contour: " + ", ".join(show(x) for x in sin_k[:4]))
print("z^2(z - 1), c0..c3 by formula: " + ", ".join(show(x) for x in p_c[:4]) + "; by contour: " + ", ".join(show(x) for x in p_k[:4]))
print(f"order at 0: sin {order(sin_c)} and {order(sin_k)}, z^2(z - 1) {order(p_c)} and {order(p_k)}")
print("sin(r)/r at r = 0.1, 0.01, 0.001: " + ", ".join(show(math.sin(r) / r) for r in (0.1, 0.01, 0.001)))
print("p(r)/r^2 at r = 0.1, 0.01, 0.001: " + ", ".join(show(p(r) / r ** 2) for r in (0.1, 0.01, 0.001)))
x = 3.0
for _ in range(6): x -= math.sin(x) / math.cos(x)   # Newton's method from 3
print(f"next zero of sin along the real line, Newton from 3: {show(x)}; pi = {show(math.pi)}")
z = 1 + 2j
s1, c1, s2, c2 = series(z, 1), series(z, 0), sin_exp(z), cos_exp(z)
print(f"sin(1 + 2i) by series {showc(s1)}, by exponentials {showc(s2)}")
print(f"cos(1 + 2i) by series {showc(c1)}, by exponentials {showc(c2)}")
print(f"sin^2 = {showc(s1 * s1)}, cos^2 = {showc(c1 * c1)}, sum = {showc(s1 * s1 + c1 * c1)}")
sg, cg = [0, 1, 0, -1], [1, 0, -1, 0]               # derivatives of sin and cos at 0, cycling
exact = [sum(math.comb(n, k) * (sg[k % 4] * sg[(n - k) % 4] + cg[k % 4] * cg[(n - k) % 4])
             for k in range(n + 1)) for n in range(11)]
print(f"n! x coefficient of z^n in sin^2 + cos^2, n = 0..10: {exact}")
print("drop 'inside D': zeros of sin(1/z) at 1/(k pi), k = 1..4: " + ", ".join(show(1 / (k * math.pi)) for k in range(1, 5)) + f"; sin(1/0.2) = {show(math.sin(5))}")
print(f"drop 'connected': 0 on the disc |z| < 1, 1 on |z - 3| < 1; value at 3: {show(1.0)}")
print(f"drop 'holomorphic': e^(-1/x^2) at x = 0.5 is {show(math.exp(-4))}; at z = 0.5i it is {show(cexp(-1 / (0.5j) ** 2).real)}")
print("figure, 35 per unit, origin (180, 120): zeros at x = " + ", ".join(f"{180 + 35 * t:.2f}" for t in (-math.pi, 0, math.pi))
      + "; points 1/n at x = " + ", ".join(f"{180 + 35 / n:.2f}" for n in range(1, 5)) + f"; 1 + 2i at ({180 + 35:.2f}, {120 - 70:.2f})")
assert all(abs(x - y) < 1e-9 for x, y in zip(sin_c + p_c, sin_k + p_k))      # two roads, same coefficients
assert order(sin_k) == 1 and order(p_k) == 2 and abs(s1 - s2) < 1e-12 and abs(c1 - c2) < 1e-12   # orders; series = exp
assert abs(s1 * s1 + c1 * c1 - 1) < 1e-12                                      # the identity off the line
assert exact == [1] + [0] * 10                                                 # its series is exactly 1
print("ALL CHECKS PASS")
