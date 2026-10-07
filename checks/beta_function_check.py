# The beta function -- the check behind the card.  Python standard library only.
# Road 1 is the defining integral itself, after x = sin^2 of an angle.  Road 2 is the Gamma
# ratio, with Gamma computed from its own integral.  Nothing imported knows either.
from math import sin, cos, exp, log, pi, sqrt

def simpson(f, lo, hi, n):                      # Simpson's rule, n panels (n even)
    h = (hi - lo) / n
    s = f(lo) + f(hi) + sum((4 if k % 2 else 2) * f(lo + k * h) for k in range(1, n))
    return s * h / 3

def beta_direct(a, b):                          # road 1: B = 2 * integral of sin^(2a-1) cos^(2b-1) of the angle
    return 2 * simpson(lambda th: sin(th) ** (2 * a - 1) * cos(th) ** (2 * b - 1), 0.0, pi / 2, 2000)

def gamma(x):                                   # Gamma(x) = 2 * integral of w^(2x-1) e^(-w^2), w from 0 to 10
    return 2 * simpson(lambda w: w ** (2 * x - 1) * exp(-w * w), 0.0, 10.0, 4000)

def beta_gamma(a, b):                           # road 2: Gamma(a) Gamma(b) / Gamma(a + b)
    return gamma(a) * gamma(b) / gamma(a + b)

cases = [("B(2, 3) ramp", 2, 3, "1!2!/4!", 1 / 12),
         ("B(3/2, 3/2) arch", 1.5, 1.5, "half disc pi(1/2)^2/2", pi * 0.25 / 2),
         ("B(1/2, 1/2)", 0.5, 0.5, "pi", pi),
         ("B(3, 3/2)", 3, 1.5, "16/105", 16 / 105)]
print("road 1: the integral, x = sin^2 of an angle, Simpson 2000 panels; road 2: Gamma ratio, Gamma by its own integral")
r1, r2 = [], []
for label, a, b, name, exact in cases:
    r1.append(beta_direct(a, b)); r2.append(beta_gamma(a, b))
    print(f"{label:16} road 1 {r1[-1]:.9f}  road 2 {r2[-1]:.9f}  {name} = {exact:.9f}")
print(f"swap the two: B(3, 2) = {beta_gamma(3, 2):.9f}, B(3/2, 3) = {beta_direct(1.5, 3):.9f}")
print(f"Gamma(1/2) = {gamma(0.5):.9f}, squared {gamma(0.5) ** 2:.9f}; Gamma(5) = {gamma(5):.9f}")
xs = [k / 10 for k in range(11)]
print("chart x = 0, 0.1, ..., 1")
print("  ramp x(1-x)^2:  " + " ".join(f"{x * (1 - x) ** 2:.2f}" for x in xs))
print("  arch sqrt(x(1-x)): " + " ".join(f"{sqrt(x * (1 - x)):.2f}" for x in xs))
print(f"ramp peak at x = 1/3: {(1 / 3) * (2 / 3) ** 2:.6f}; arch peak at x = 1/2: {0.5:.6f}")
wrong1 = beta_gamma(3, 4)
wrong2 = 2 * 6 / 120
wrong3 = gamma(2) * gamma(3) / gamma(4)
print(f"mistake 1, minus 1 dropped, x^2(1-x)^3: B(3, 4) = {wrong1:.6f}, not {1 / 12:.6f}")
print(f"mistake 2, factorials with no shift: 2!3!/5! = {wrong2:.6f}")
print(f"mistake 3, stretch factor u dropped: Gamma(2)Gamma(3)/Gamma(4) = {wrong3:.6f}")
tails = [simpson(lambda x: 1 / (1 - x), 0.0, 1 - e, 20000) for e in (0.1, 0.01, 0.001)]
print("b = 0: area under 1/(1-x) from 0 to 1-e, e = 0.1, 0.01, 0.001: " + " ".join(f"{v:.4f}" for v in tails))
assert all(abs(p - q) < 1e-9 for p, q in zip(r1, r2))                   # two roads agree
assert all(abs(p - c[4]) < 1e-9 for p, c in zip(r1, cases))            # road 1 hits each closed form
assert abs(gamma(0.5) - sqrt(pi)) < 1e-9 and abs(gamma(5) - 24) < 1e-9  # Gamma from its integral
assert all(abs(v - log(1 / e)) < 1e-4 for v, e in zip(tails, (0.1, 0.01, 0.001)))
print("ALL CHECKS PASS")
