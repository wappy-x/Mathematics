# Exp, log, sine, cosine and pi from series alone -- the check behind the card.
# Nothing is imported.  Road one builds every function from its power series.
# Road two shares no series: a step-by-step solver for y' = y, a polygon in the
# unit circle (square roots only), and an area under 1/t by Simpson's rule.
def E(x, n=60):                          # exp: 1 + x + x^2/2! + ...
    s, t = 0.0, 1.0
    for k in range(n):
        s, t = s + t, t * x / (k + 1)
    return s
def trig(x, odd, n=40):                  # cos (odd = 0) or sin (odd = 1)
    s, t, k = 0.0, (x if odd else 1.0), odd
    for _ in range(n):
        s, t, k = s + t, -t * x * x / ((k + 1) * (k + 2)), k + 2
    return s
C, S = (lambda x: trig(x, 0)), (lambda x: trig(x, 1))
fact = lambda n: 1 if n == 0 else n * fact(n - 1)
def root(f, lo, hi):                     # bisection: f(lo) > 0 > f(hi), 50 halvings
    for _ in range(50):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) > 0 else (lo, mid)
    return lo
cauchy = [sum(1 / (fact(k) * fact(n - k)) for k in range(n + 1)) for n in range(30)]
y, h = 1.0, 0.001                        # road two for exp(2): step y' = y from 0 to 2
for _ in range(2000):
    a = y; b = y + h * a / 2; c = y + h * b / 2; d = y + h * c
    y += h * (a + 2 * b + 2 * c + d) / 6
half = root(C, 1.5, 1.6); pi = 2 * half
side, sides = 1.0, 6                     # road two for pi: double a hexagon 12 times
for _ in range(12):
    side, sides = side / (2 + (4 - side * side) ** 0.5) ** 0.5, 2 * sides
poly = sides * side / 2
log = lambda v: root(lambda t: v - E(t), 0.0, v)
area = sum((1 if i in (0, 1000) else 4 if i % 2 else 2) / (1 + i / 1000) for i in range(1001)) / 3000
wrong, cut = sum(1 / fact(n) ** 2 for n in range(30)), root(lambda x: 1 - x * x / 2, 1.0, 2.0)
f6 = lambda v: f"{v:.6f}"
print(f"exp(1) = {f6(E(1))}, exp(2) = {f6(E(2))}")
print("Cauchy terms of exp(1) x exp(1), n = 0..5: " + " ".join(f6(v) for v in cauchy[:6]))
print(f"exp(1) x exp(1) = {f6(E(1) ** 2)}; Cauchy terms summed = {f6(sum(cauchy))}")
print(f"exp(2) by stepping y' = y, 2000 steps, no series = {f6(y)}")
terms = [(-1) ** k * 1.5 ** (2 * k) / fact(2 * k) for k in range(5)]
print("cos 1.5, first five terms: " + " ".join(f6(v) for v in terms) + f"; they sum to {f6(sum(terms))}")
print(f"cos 0 = {C(0):.4f}, cos 1.5 = {C(1.5):.4f}, cos 1.6 = {C(1.6):.4f}, cos 2 = {C(2):.4f}")
print(f"first zero of cos, by bisection = {f6(half)}, so pi = {f6(pi)}")
print(f"pi from a {sides}-sided polygon in the unit circle, no series = {f6(poly)}")
print(f"sin(pi/2) = {f6(S(half))}, cos(pi) = {f6(C(pi))}, cos(2 pi) = {f6(C(2 * pi))}")
print(f"cos 1 = {f6(C(1))}, cos(1 + 2 pi) = {f6(C(1 + 2 * pi))}; sin 1 = {f6(S(1))}, sin(1 + 2 pi) = {f6(S(1 + 2 * pi))}")
print(f"sin(1)^2 + cos(1)^2 = {f6(S(1) ** 2 + C(1) ** 2)}")
print(f"log 2 by bisection on exp = {f6(log(2))}; area under 1/t from 1 to 2 = {f6(area)}")
print(f"log 2 + log 3 = {f6(log(2) + log(3))}, log 6 = {f6(log(6))}")
print("chart, cos x at x = 0, 0.4, ..., 3.2: " + " ".join(f"{C(i * 0.4):.2f}" for i in range(9)))
print("chart, 1 - x^2/2 at the same x: " + " ".join(f"{1 - (i * 0.4) ** 2 / 2:.2f}" for i in range(9)))
print(f"mistake, n-th term times n-th term: {f6(wrong)}, not {f6(E(2))}")
print(f"mistake, cos cut to 1 - x^2/2: zero {f6(cut)}, so pi would be {f6(2 * cut)}")
print(f"mistake, exp(1) + exp(1) = {f6(2 * E(1))}, not exp(2)")
assert all(abs(cauchy[n] - 2 ** n / fact(n)) < 1e-12 for n in range(30))   # binomial theorem
assert abs(E(1) ** 2 - E(2)) < 1e-12 and abs(y - E(2)) < 1e-9               # series against stepping
assert abs(pi - poly) < 1e-7 and C(1.5) > 0 > C(1.6)                         # series against polygon
assert abs(C(1 + 2 * pi) - C(1)) < 1e-12 and abs(S(1 + 2 * pi) - S(1)) < 1e-12
assert abs(log(2) - area) < 1e-9 and abs(log(2) + log(3) - log(6)) < 1e-12
print("ALL CHECKS PASS")
