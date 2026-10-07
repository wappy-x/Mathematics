# Substitution -- the check behind the card.  Standard library only; math.exp
# and math.log are primitives.  The area under x e^(x^2) is found by two roads:
# the antiderivative e^u / 2 at the moved limits, with e^u built from its own
# series, and midpoint sums in x and in u, refined until the error closes.
import math

def exp_series(t):                        # e^t = 1 + t + t^2/2! + ..., 60 terms
    term, total = 1.0, 1.0
    for k in range(1, 60):
        term *= t / k
        total += term
    return total

def mid(fn, a, b, n):                     # midpoint sum: n strips, height at each centre
    w = (b - a) / n
    return w * sum(fn(a + (k + 0.5) * w) for k in range(n))

f_x = lambda x: x * math.exp(x * x)       # the integrand, written in x
f_u = lambda u: math.exp(u) / 2           # the same integrand, written in u = x^2
F = lambda u: exp_series(u) / 2           # an antiderivative in u
exact = F(1) - F(0)
print(f"road 1, e^u/2 from u = 0 to u = 1: {exact:.6f}  (e = {exp_series(1):.6f})")
errors = []
for n in (10, 100, 1000):
    s = mid(f_x, 0, 1, n)
    errors.append(s - exact)
    print(f"road 2, midpoint sum in x, n = {n:4}: {s:.6f}  error {s - exact:.9f}")
u_sum = mid(f_u, 0, 1, 1000)
print(f"road 2, midpoint sum in u, n = 1000: {u_sum:.6f}")
x0, h = 0.7, 1e-5
dq = (F((x0 + h) ** 2) - F((x0 - h) ** 2)) / (2 * h)
print(f"chain rule at x = 0.7: slope of e^(x^2)/2 {dq:.6f}, integrand {f_x(x0):.6f}")
for a, b in ((1, 2), (1, 0), (-1, 1), (-1, 2)):
    s = round(mid(f_x, a, b, 30000), 9) + 0.0
    print(f"x from {a} to {b}: u from {a * a} to {b * b}; e^u/2 gives {F(b * b) - F(a * a):.6f}; x sum {s:.6f}")
print(f"mistake, x limits 1 and 2 kept on u: {F(2) - F(1):.6f}, not {F(4) - F(1):.6f}")
print(f"mistake, the 1/2 dropped: {2 * exact:.6f}, not {exact:.6f}")
g = lambda x: 2 * x / (x * x - 1)          # u = x^2 - 1 passes through 0, where 1/u fails
print(f"mistake, 2x/(x^2 - 1) on 0 to 2: formula ln 3 = {math.log(3):.6f}; area 0 to 0.99 = "
      f"{math.log(0.0199):.6f} (sum {mid(g, 0, 0.99, 200000):.6f}); 0 to 0.9999 = "
      f"{math.log(0.00019999):.6f} (sum {mid(g, 0, 0.9999, 200000):.6f})")
pts = [i / 5 for i in range(6)]
print("chart, x e^(x^2) at x = 0, 0.2, ..., 1:", " ".join(f"{f_x(p):.2f}" for p in pts))
print("chart, e^u/2 at u = 0, 0.2, ..., 1:", " ".join(f"{f_u(p):.2f}" for p in pts))
ticks = [i / 4 for i in range(5)]
print("figure, x ticks", " ".join(f"{t:.4f}" for t in ticks), "at px", " ".join(f"{30 + 300 * t:.2f}" for t in ticks))
print("figure, u marks", " ".join(f"{t * t:.4f}" for t in ticks), "at px", " ".join(f"{30 + 300 * t * t:.2f}" for t in ticks))
print("figure, u strip widths", " ".join(f"{b * b - a * a:.4f}" for a, b in zip(ticks, ticks[1:])),
      "= 2 x centre x 0.25, centres", " ".join(f"{a + 0.125:.4f}" for a in ticks[:4]))
assert abs(mid(f_x, 0, 1, 1000) - exact) < 1e-6          # x-road meets the moved-limit antiderivative
assert abs(u_sum - exact) < 1e-6                          # u-road meets it too
assert abs(dq - f_x(x0)) < 1e-6                           # the chain rule, by difference quotient
assert abs(mid(f_x, -1, 2, 30000) - (F(4) - F(1))) < 1e-5 and abs(errors[2]) < abs(errors[1]) / 50
print("ALL CHECKS PASS")
