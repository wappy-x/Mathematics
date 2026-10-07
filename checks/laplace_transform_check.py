# The Laplace transform -- the check behind the card.  Standard library only.
# F(s) = integral from 0 to infinity of f(t) e^(-st) dt, for a complex number s.
# Road 1: the closed forms proved on the card.  Road 2: the integral itself, summed
# by Simpson's rule, and the braking car v' = -2v stepped forward in time by RK4.
import math

def cexp(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def show(z):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def simpson(g, lo, hi, n=40000):               # Simpson's rule, n even
    h = (hi - lo) / n
    return h / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * g(lo + j * h) for j in range(n + 1))
def lap(f, s, T=40.0): return simpson(lambda t: f(t) * cexp(-s * t), 0, T)

pairs = [("1", lambda t: 1.0, lambda s: 1 / s), ("t", lambda t: t, lambda s: 1 / (s * s)),
         ("e^(-2t)", lambda t: math.exp(-2 * t), lambda s: 1 / (s + 2)),
         ("cos t", math.cos, lambda s: s / (s * s + 1))]
worst = 0.0
for s in (3, 1 + 1j):
    closed, summed = [F(s) for _, _, F in pairs], [lap(f, s) for _, f, _ in pairs]
    worst = max([worst] + [abs(a - b) for a, b in zip(closed, summed)])
    for label, vals in (("closed form", closed), ("Simpson to t = 40", summed)):
        print(f"s = {show(s)}, {label}: " + "; ".join(f"{n} -> {show(v)}" for (n, _, _), v in zip(pairs, vals)))
cut = {s: simpson(lambda t: math.exp((1 - s) * t), 0, 10) for s in (3, 1.5, 1, 0.5)}
print("e^t cut at T = 10: " + "; ".join(f"s = {s} -> {v:.6f}" for s, v in cut.items())
      + f"; formula 1/(s - 1) at s = 0.5 gives {1 / (0.5 - 1):.6f}")
chart = {s: [simpson(lambda t: math.exp((1 - s) * t), 0, T, 4000) for T in range(9)] for s in (3, 1.5, 1)}
for s, row in chart.items():
    print(f"chart, e^t cut at T = 0 to 8, s = {s}: " + ", ".join(f"{v:.2f}" for v in row))
v = lambda t: 5 * math.exp(-2 * t)             # the braking car's speed, m/s
V = lambda s: 5 / (s + 2)                      # its transform, from the e^(at) row with a = -2
d1, d2 = lap(lambda t: -2 * v(t), 3), lap(lambda t: -math.sin(t), 1 + 1j)
print(f"derivative rule, s = 3, f = 5e^(-2t): Simpson on f' {show(d1)}; s F - f(0) = 3 x 1 - 5 = {3 * V(3) - v(0):.6f}; "
      f"without f(0): {3 * V(3):.6f}")
print(f"derivative rule, s = 1 + i, f = cos t: Simpson on f' {show(d2)}; s F - f(0) = {show((1 + 1j) * pairs[3][2](1 + 1j) - 1)}")
x, u, h = 0.0, 5.0, 0.001                      # RK4 on distance x' = u, speed u' = -2u
for k in range(20000):
    a1, b1 = u, -2 * u; a2, b2 = u + h / 2 * b1, -2 * (u + h / 2 * b1)
    a3, b3 = u + h / 2 * b2, -2 * (u + h / 2 * b2); a4, b4 = u + h * b3, -2 * (u + h * b3)
    x, u = x + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), u + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
    if k == 999: v_one = u
print(f"braking car: V(3) = 5/(3 + 2) = {V(3):.6f}, Simpson on 5e^(-2t) {show(lap(v, 3))}; V(0) = {V(0):.6f}")
print(f"stepped by RK4: v(1) = {v_one:.6f} against 5e^(-2) = {v(1):.6f}; distance to t = 20 {x:.6f} m")
p = lambda s: (1 - cexp(-s)) / s               # the one-second pulse on 0 to 1
print(f"pulse: (1 - e^(-s))/s at s = 3 {show(p(3))}, Simpson {show(lap(lambda t: 1.0, 3, 1.0))}; "
      f"at s = i {show(p(1j))}, size {abs(p(1j)):.6f}; its jump breaks the rule: s F - f(0) at s = 3 {show(3 * p(3) - 1)}")
print(f"mistake, 5/(s + 2) read as 5e^(2t): speed at t = 1 {5 * math.exp(2):.6f} m/s")
print("mistake, e^(t^2) at s = 10 cut at T = 10, 11, 12: "
      + ", ".join(f"{simpson(lambda t: math.exp(t * t - 10 * t), 0, T):.1f}" for T in (10, 11, 12)))
print("figure, 40 units per unit, origin (200, 130): pole -2 at (120, 130), s = 3 at (320, 130), s = 1 + i at (240, 90)")
assert worst < 1e-9 and abs(lap(lambda t: 1.0, 3, 1.0) - p(3)) < 1e-12   # closed forms against the integral
assert abs(d1 - (3 * V(3) - 5)) < 1e-9 and abs(d2 - ((1 + 1j) * pairs[3][2](1 + 1j) - 1)) < 1e-9
assert abs(v_one - v(1)) < 1e-10 and abs(x - V(0)) < 1e-9                 # the stepped car against V(s)
assert all(abs(chart[1][T] - T) < 1e-9 for T in range(9)) and abs(cut[0.5] - 2 * (math.exp(5) - 1)) < 1e-6
print("ALL CHECKS PASS")
