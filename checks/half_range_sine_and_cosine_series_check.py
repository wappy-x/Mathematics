# Half-range series -- the check behind the card.  Only math.sin, cos and pi
# are imported.  A 1 m string is pulled 1 cm aside at its middle: the triangle
# f.  Road one: coefficients by integration by parts.  Road two: build the odd
# and even reflections and integrate them over the whole period, -L to L.
from math import sin, cos, pi
L = 1.0
def f(x):                                   # the triangle, in cm, 0 <= x <= L
    return 2 * x / L if x <= L / 2 else 2 * (L - x) / L
def odd(x): return f(x) if x >= 0 else -f(-x)       # reflect with a sign flip
def even(x): return f(abs(x))                       # reflect without one
def simpson(g, a, b, m=2000):               # composite Simpson rule, written out
    h = (b - a) / m
    return h / 3 * (g(a) + g(b) + sum((4 if j % 2 else 2) * g(a + j * h) for j in range(1, m)))
def b(n): return 8 * [0, 1, 0, -1][n % 4] / (n * pi) ** 2     # road one, sine
def a(n):                                                      # road one, cosine
    return 1.0 if n == 0 else 4 * (2 * [1, 0, -1, 0][n % 4] - 1 - (-1) ** n) / (n * pi) ** 2
def S(x, N): return sum(b(n) * sin(n * pi * x / L) for n in range(1, N + 1))
def C(x, N): return a(0) / 2 + sum(a(n) * cos(n * pi * x / L) for n in range(1, N + 1))
def r(v, d=4): return f"{round(v, d) + 0.0:.{d}f}"
def row(vals, d=4): return " ".join(r(v, d) for v in vals)
b_int = [simpson(lambda x: odd(x) * sin(n * pi * x / L), -L, L) / L for n in range(1, 8)]
a_int = [simpson(lambda x: even(x) * cos(n * pi * x / L), -L, L) / L for n in range(0, 7)]
print("sine b1..b7, by parts:      ", row(b(n) for n in range(1, 8)))
print("sine b1..b7, odd reflection:", row(b_int))
print("cosine a0..a6, by parts:      ", row(a(n) for n in range(0, 7)))
print("cosine a0..a6, even reflection:", row(a_int))
print("string peak, sine sum with modes 1 / 1,3 / 1,3,5:", row(S(0.5, N) for N in (1, 3, 5)))
print("rod middle, cosine sum through a2 / through a6:", row(C(0.5, N) for N in (2, 6)))
ends = max(abs(S(x, N)) for x in (0, L) for N in (1, 3, 5, 99))
slopes = max(abs(sum(-a(n) * n * pi / L * sin(n * pi * x / L) for n in range(1, 100))) for x in (0, L))
print("sine sums at both ends below 1e-12:", "yes" if ends < 1e-12 else "no",
      "; cosine end slopes below 1e-12:", "yes" if slopes < 1e-12 else "no")
grid = [k / 100 for k in range(101)]
err_s = max(abs(S(x, 99) - f(x)) for x in grid)
err_c = max(abs(C(x, 99) - f(x)) for x in grid)
tail_s = 8 / pi ** 2 / (2 * 99)             # odd n > 99: sum of 1/n^2 <= 1/198
tail_c = 16 / pi ** 2 / (4 * 98)            # n = 102, 106, ...: sum <= 1/392
print(f"99 modes, 101 points: sine max error {r(err_s, 5)} (tail bound {r(tail_s, 5)}), "
      f"cosine {r(err_c, 5)} (bound {r(tail_c, 5)})")
print("rod, insulated: mean", r(simpson(f, 0, L) / L), "= a0/2 =", r(a(0) / 2))
xs = [k / 10 for k in range(11)]
print("chart, triangle:", row((f(x) for x in xs), 2))
print("chart, mode 1:  ", row((S(x, 1) for x in xs), 2))
print("chart, modes 1,3,5:", row((S(x, 5) for x in xs), 2))
X = lambda x: 190 + 150 * x
for name, g, base in (("odd", odd, 70), ("even", even, 190)):
    print(f"figure, {name}:", " ".join(f"{X(x):.0f},{base - 40 * g(x):.0f}" for x in (-1, -0.5, 0, 0.5, 1)))
print("mistake 1, factor 1/L on half the range: b1 =", r(simpson(lambda x: f(x) * sin(pi * x), 0, L) / L),
      "cm, peak reads", r(S(0.5, 9999) / 2), "cm")
print("mistake 2, cosine modes for the pinned string: end reads", r(C(0, 2)), "cm, not 0")
print("mistake 3, alternating signs dropped: peak reads",
      r(sum(abs(b(n)) * sin(n * pi / 2) for n in range(1, 10000))), "cm, not 1")
assert all(abs(p - q) < 1e-9 for p, q in zip((b(n) for n in range(1, 8)), b_int))  # two roads, sine
assert all(abs(p - q) < 1e-9 for p, q in zip((a(n) for n in range(0, 7)), a_int))  # two roads, cosine
assert err_s <= tail_s + 1e-12 and err_c <= tail_c + 1e-12      # sums land on f
assert abs(S(0.5, 9999) - f(0.5)) < 1e-4                        # the peak is 1 cm
print("ALL CHECKS PASS")
