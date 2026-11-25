# Schanuel's conjecture, status card: what it says for z = 1 and z = i*pi, the algebra step
# from "e and pi algebraically independent" to "e + pi transcendental", and small searches.
# Standard library only.  Schanuel is open, so every search here is evidence, not proof.
# Roads: constants by written-out series against the library; relation searches calibrated
# on numbers that do satisfy a relation; g(e + pi) against the expanded P(e, pi) = g(X + Y).
import math
from itertools import product
from math import comb

def exp_series(x):                          # e^x = sum x^k / k!, only +, * and /
    s, t = 0.0, 1.0
    for k in range(1, 80): s, t = s + t, t * x / k
    return s
def atan_inv(n):                            # arctan(1/n) = sum (-1)^k / ((2k+1) n^(2k+1))
    s, p, k = 0.0, 1.0 / n, 0
    while p > 1e-30: s, p, k = s + (-1) ** k * p / (2 * k + 1), p / (n * n), k + 1
    return s
def cexp_series(a, b):                      # e^(a + bi) by the series, complex product written out
    sr, si, tr, ti = 0.0, 0.0, 1.0, 0.0
    for k in range(1, 80):
        sr, si = sr + tr, si + ti
        tr, ti = (tr * a - ti * b) / k, (tr * b + ti * a) / k
    return sr, si

# ---- the constants, two roads each ----
e, pi = exp_series(1.0), 16 * atan_inv(5) - 4 * atan_inv(239)
assert abs(e - math.e) < 1e-15 and abs(pi - math.pi) < 1e-15        # series against library
print(f"e  = {e:.12f}   (series; library {math.e:.12f})")
print(f"pi = {pi:.12f}   (Machin; library {math.pi:.12f})")
er, ei = cexp_series(0.0, pi)
assert abs(er + 1) < 1e-12 and abs(ei) < 1e-12                       # e^(i pi) = -1
print(f"e^(i pi) by the series: real part {er:.12f}, |imaginary part| below 1e-12")
epi = exp_series(pi)
assert abs(epi - math.exp(pi)) < 1e-12 * epi
print(f"e^pi = {epi:.9f}   e^sqrt2 = {exp_series(math.sqrt(2)):.9f}   e^e = {exp_series(e):.9f}")
s, p = e + pi, e * pi
print(f"e + pi = {s:.9f}   e * pi = {p:.9f}")
assert abs(e * e - s * e + p) < 1e-12 and abs(pi * pi - s * pi + p) < 1e-12
print("e and pi are the roots of t^2 - (e + pi) t + e pi: both residuals below 1e-12")

# ---- linear independence over Q: smallest |a z1 + b z2|, a, b whole, |a|, |b| <= 50 ----
def lin_min(z1, z2):
    best = None
    for a, b in product(range(-50, 51), repeat=2):
        if (a, b) != (0, 0):
            w = a * z1 + b * z2
            v = math.sqrt(w.real * w.real + w.imag * w.imag)
            if best is None or v < best[0]: best = (v, a, b)
    return best
print("\nsmallest |a z1 + b z2| with whole a, b of size at most 50, not both 0")
for name, z1, z2 in [("1, sqrt2", 1.0, math.sqrt(2)), ("1, e", 1.0, e), ("1, i pi", 1.0, complex(0, pi)),
                     ("pi, i pi", complex(pi), complex(0, pi)), ("1, 2", 1.0, 2.0)]:
    v, a, b = lin_min(z1, z2)
    print(f"  {name:9s}  {v:.9f}  at a = {a}, b = {b}")
    if name == "1, 2": assert v == 0 and a == -2 * b                       # dependent: relation found
    else: assert v > 1e-3                                                   # independent: none

# ---- one-variable search: whole-number g of degree <= 3, coefficients of size <= 10 ----
def best_g(x):
    best = None
    for c in product(range(-10, 11), repeat=4):          # c = (a3, a2, a1, a0)
        if any(c):
            v = abs(((c[0] * x + c[1]) * x + c[2]) * x + c[3])
            if best is None or v < best[0]: best = (v, c)
    return best
def gtext(c): return " ".join(f"{t:+d}{m}" for t, m in zip(c, ["x^3", "x^2", "x", ""]) if t)
print("\nsmallest |g(x)|, g whole-number, degree <= 3, coefficients of size <= 10")
cal = best_g(1 + math.sqrt(2))
assert cal[0] < 1e-12                                                  # calibration: a root is found
print(f"  x = 1 + sqrt2 (algebraic):  below 1e-12, g = {gtext(cal[1])}")
gs, gp = best_g(s), best_g(p)
assert gs[0] > 1e-4 and gp[0] > 1e-4
print(f"  x = e + pi:  {gs[0]:.9f}  g = {gtext(gs[1])}")
print(f"  x = e pi:    {gp[0]:.9f}  g = {gtext(gp[1])}")

# ---- the algebra step: P(X, Y) = g(X + Y) is a nonzero polynomial ----
def expand_sum(c):                                     # g(X + Y) as {(i, j): coefficient of X^i Y^j}
    P, d = {}, len(c) - 1
    for k, a in enumerate(c):                          # a is the coefficient of x^(d - k)
        n = d - k
        for i in range(n + 1): P[(i, n - i)] = P.get((i, n - i), 0) + a * comb(n, i)
    return {m: v for m, v in P.items() if v}
c = gs[1]
lead = next(k for k, a in enumerate(c) if a)
P = expand_sum(c)
deg = len(c) - 1 - lead
assert P[(deg, 0)] == c[lead]                          # coefficient of X^d equals g's leading coefficient
val_P = sum(v * e ** i * pi ** j for (i, j), v in sorted(P.items()))
gval = ((c[0] * s + c[1]) * s + c[2]) * s + c[3]
assert abs(val_P - gval) < 1e-9                        # two roads to the same number
print(f"\ng(X + Y) for that g: {len(P)} nonzero terms, X^{deg} coefficient {P[(deg, 0)]}")
print(f"  g(e + pi) = {gval:.9f}   P(e, pi) from the expansion = {val_P:.9f}")

# ---- two-variable search: P(x, y) of total degree <= 2, coefficients of size <= 4 ----
def best_P(x, y):
    m, best = (1.0, x, y, x * x, x * y, y * y), None
    for c in product(range(-4, 5), repeat=6):
        if any(c):
            v = abs(c[0] * m[0] + c[1] * m[1] + c[2] * m[2] + c[3] * m[3] + c[4] * m[4] + c[5] * m[5])
            if best is None or v < best[0]: best = (v, c)
    return best
def ptext(c): return " ".join(f"{t:+d}{m}" for t, m in zip(c, ["", "x", "y", "x^2", "xy", "y^2"]) if t)
print("\nsmallest |P(x, y)|, total degree <= 2, coefficients of size <= 4")
for name, x, y in [("e, e^2", e, e * e), ("e, 1/e", e, 1 / e), ("e, pi", e, pi)]:
    v, cc = best_P(x, y)
    if name == "e, pi":
        assert v > 1e-4; print(f"  {name:7s} {v:.9f}  P = {ptext(cc)}")
    else:
        assert v < 1e-12; print(f"  {name:7s} below 1e-12  P = {ptext(cc)}")

# ---- what breaks, and the generator count ----
print("\nwhat breaks")
assert abs(exp_series(2.0) - e * e) < 1e-12
print("z = 1, 2 (dependent): e^2 - e*e below 1e-12, so x^2 - y vanishes at e, e^2: only 1 of 2 forced")
print("z = 1, i pi: generators 1, i pi, e, -1; algebraic: 1 and -1; so at most 4 - 2 = 2, never 2n = 4")
print("e and 1/e: each transcendental, yet xy - 1 = 0: 'each transcendental' is not 'independent'")

print("\ntry changing")
print(f"e^pi - pi = {epi - pi:.9f}")
print(f"z = 1, sqrt3:  smallest |a + b sqrt3| = {lin_min(1.0, math.sqrt(3))[0]:.9f}")
print(f"x = e - pi = {e - pi:.9f}:  smallest |g| = {best_g(e - pi)[0]:.9f}")
print("ALL CHECKS PASS")
