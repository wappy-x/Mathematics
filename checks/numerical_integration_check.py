# Numerical integration -- the check behind the card.  Only math is imported.
# The bell curve f(x) = exp(-x^2/2) / sqrt(2 pi) on [0, 1].  Road one: midpoint,
# trapezoid and Simpson sums.  Road two: the exp series integrated term by term,
# with Taylor's remainder bounding the terms left off.
import math
C = 1 / math.sqrt(2 * math.pi)
def f(x): return C * math.exp(-x * x / 2)
def mid(g, n, a=0.0, b=1.0):
    h = (b - a) / n
    return h * sum(g(a + (i + 0.5) * h) for i in range(n))
def trap(g, n, a=0.0, b=1.0):
    h = (b - a) / n
    return h * ((g(a) + g(b)) / 2 + sum(g(a + i * h) for i in range(1, n)))
def simp(g, n, a=0.0, b=1.0, third=3):
    h = (b - a) / n
    return h / third * (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n)))
K2, K4 = C, 3 * C                      # |f''| = |x^2 - 1| f, |f''''| = |x^4 - 6x^2 + 3| f, largest at x = 0
def bounds(n): return K2 / (24 * n * n), K2 / (12 * n * n), K4 / (180 * n ** 4)
def row(xs, d): return ", ".join(f"{x:.{d}f}" for x in xs)
fact, total = 1, 0.0
for k in range(13):                    # integral of (-x^2/2)^k / k! from 0 to 1
    fact *= max(k, 1)
    total += (-1) ** k / (2 ** k * fact * (2 * k + 1))
exact, tail = C * total, C * 0.5 ** 13 / (fact * 13)
print(f"f at x = 0, 1/8, ..., 1: {row([f(k / 8) for k in range(9)], 6)}")
print(f"series road: 13 terms give {exact:.12f}, tail below {tail:.1e}")
for name, rule, bd in zip(("midpoint", "trapezoid", "Simpson"), (mid, trap, simp), bounds(4)):
    v = rule(f, 4)
    print(f"n = 4 {name}: {v:.9f}, error {abs(v - exact):.9f}, bound {bd:.9f}")
    assert abs(v - exact) <= bd                                  # road 1 inside the proved window
err = lambda rule, n: abs(rule(f, n) - exact)
r = [err(rule, 8) / err(rule, 16) for rule in (mid, trap, simp)]
print(f"error ratio, n = 8 to n = 16: midpoint {r[0]:.2f}, trapezoid {r[1]:.2f}, Simpson {r[2]:.2f}")
d, xs = 0.01, [i / 1000 for i in range(1001)]
q2 = max(abs(f(x + d) - 2 * f(x) + f(x - d)) / d ** 2 for x in xs)
q4 = max(abs(f(x + 2 * d) - 4 * f(x + d) + 6 * f(x) - 4 * f(x - d) + f(x - 2 * d)) / d ** 4 for x in xs)
print(f"difference quotients on 1001 points: max |f''| {q2:.6f} vs K2 {K2:.6f}; max |f''''| {q4:.6f} vs K4 {K4:.6f}")
assert (abs(r[0] - 4) < 0.05 and abs(r[1] - 4) < 0.05 and abs(r[2] - 16) < 0.5     # h^2, h^2, h^4
        and abs(q2 - K2) < 1e-4 and abs(q4 - K4) < 1e-3)                  # ceilings by a second road
eps = 5e-7
nm, nt = math.ceil(math.sqrt(K2 / (24 * eps))), math.ceil(math.sqrt(K2 / (12 * eps)))
ns = math.ceil((K4 / (180 * eps)) ** 0.25); ns += ns % 2
print(f"target 5e-7: bounds ask for midpoint n = {nm}, trapezoid n = {nt}, Simpson n = {ns}")
e3 = (err(mid, nm), err(trap, nt), err(simp, ns))
print(f"errors there: midpoint {e3[0]:.1e}, trapezoid {e3[1]:.1e}, Simpson {e3[2]:.1e}")
first = [next(n for n in range(s, 999, s) if err(rule, n) < eps) for rule, s in ((mid, 1), (trap, 1), (simp, 2))]
print(f"smallest n that actually works: midpoint {first[0]}, trapezoid {first[1]}, Simpson {first[2]}")
print(f"six decimals: Simpson n = {ns} gives {simp(f, ns):.6f}, trapezoid n = {nt} gives {trap(f, nt):.6f}, series {exact:.6f}")
assert max(e3) < eps and f"{simp(f, ns):.6f}" == f"{exact:.6f}"      # the chosen step delivers
v = [rule(lambda t: 3 + 2 * t, 10, 0, 10) for rule in (mid, trap, simp)]
print(f"tank 3 + 2t over 10 minutes, n = 10: midpoint {v[0]:.6f}, trapezoid {v[1]:.6f}, Simpson {v[2]:.6f}")
assert all(abs(x - (3 * 10 + 10 * 20 / 2)) < 1e-9 for x in v)        # geometry: 30 + 100 litres
print(f"figure, 280 px per unit across, 400 px per unit up; x = {row([40 + 280 * k / 16 for k in range(17)], 1)}")
print(f"figure, curve y = {row([215 - 400 * f(k / 16) for k in range(17)], 1)}")
print(f"figure, rectangle tops y = {row([215 - 400 * f(k / 8) for k in (1, 3, 5, 7)], 1)}; ticks 0.2 at y = {215 - 400 * 0.2:.0f}, 0.4 at y = {215 - 400 * 0.4:.0f}")
print(f"mistake 1, K2 read at x = 1: |f''(1)| = |1 - 1| f(1) = {abs((1 * 1 - 1) * f(1)):.6f}, yet n = 1 midpoint gives {mid(f, 1):.6f}, error {err(mid, 1):.6f}")
print(f"mistake 2, Simpson n = 4 with h instead of h/3: {simp(f, 4, third=1):.6f}")
print(f"mistake 3, Simpson weights on odd n = 5: {simp(f, 5):.6f}, error {err(simp, 5):.6f}")
print("ALL CHECKS PASS")
