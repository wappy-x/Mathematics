# Term by term -- the check behind the card.  math gives pi, sin and cos only.
# Coefficients are integrated by a midpoint rule written here; every series is
# summed here; each answer is met by a second road that shares no arithmetic.
from math import pi, sin, cos

def midpoint(g, a, b, m=200000):            # m slices, each read at its middle
    h = (b - a) / m
    return h * sum(g(a + (k + 0.5) * h) for k in range(m))

def saw(x):  return x                       # the sawtooth on -pi < x < pi
def b(n):    return 2 * (-1) ** (n + 1) / n  # its sine coefficients, closed form

# Road 1 against road 2: coefficients by formula and by integration.
for n in (1, 2, 3):
    num = midpoint(lambda x: saw(x) * sin(n * x), -pi, pi) / pi
    assert abs(num - b(n)) < 1e-8
    print(f"sawtooth b_{n}: formula {b(n):.6f}, integrated {num:.6f}")
# The slope f' = 1 has cosine coefficients 0 for n >= 1, yet n b_n is not 0.
J = saw(pi) - saw(-pi)                      # how far the sawtooth falls when it wraps
for n in (1, 2, 3):
    num = midpoint(lambda x: 1.0 * cos(n * x), -pi, pi) / pi
    jump = 2 * (-1) ** n * J / (2 * pi)     # the jump's share, in cosine form
    assert abs(num - (n * b(n) + jump)) < 1e-8
    print(f"n={n}: n b_n {n * b(n):.6f}, jump term {jump:.6f}, true coefficient of f' {abs(num):.6f}")

# The failure: differentiate x = sum b_n sin(nx) term by term, read at pi/2.
x = pi / 2
true_slope = (saw(x + 1e-6) - saw(x - 1e-6)) / 2e-6
d, partial = 0.0, []
for n in range(1, 1001):
    d += n * b(n) * cos(n * x)
    partial.append(d)
w = 2 * pi * 220                            # radians of phase per second at 220 cycles a second
print(f"slope of the sawtooth at pi/2, difference quotient: {true_slope:.6f} V per radian = {true_slope * w:.1f} V/s")
print(f"term by term claims 0 or 2 V per radian = 0 or {2 * w:.1f} V/s")
print("sawtooth, term-by-term slope at pi/2, N=1..12:", " ".join(f"{abs(v):.4f}" for v in partial[:12]))
assert min(abs(v - true_slope) for v in partial[100:]) > 0.99   # never within 0.99 of 1
fejer = sum(partial) / len(partial)
print(f"average of the first 1000 partial sums: {fejer:.6f}")
assert abs(fejer - true_slope) < 1e-9
top = max(abs(n * b(n) * cos(n * 1.0)) for n in range(1000, 1011))
print(f"largest term size for n=1000..1010 at x=1: {top:.6f} (terms never shrink)")
assert top > 1

# The legal case: the triangle |x|, the integral of the square wave.
tri_a = lambda n: -4 / (pi * n * n) if n % 2 else 0.0
for n in (1, 2, 3):
    num = midpoint(lambda t: abs(t) * cos(n * t), -pi, pi) / pi
    assert abs(num - tri_a(n)) < 1e-8
    print(f"triangle a_{n}: formula {tri_a(n):.6f}, integrated {num if abs(num) > 1e-9 else 0.0:.6f}")
s, rows = 0.0, {}
for n in range(1, 1002):
    s += -n * tri_a(n) * sin(n * x)          # derivative of a_n cos(nx) is -n a_n sin(nx)
    rows[n] = s
print("triangle, term-by-term slope at pi/2, N=1..12:", " ".join(f"{rows[n]:.4f}" for n in range(1, 13)))
for N in (11, 101, 1001):
    err, bound = abs(rows[N] - 1), 4 / (pi * (N + 2))   # alternating: next term caps the miss
    assert err <= bound
    print(f"N={N}: sum {rows[N]:.6f}, miss {err:.6f}, bound from the next term {bound:.6f}")

# Integration: integrate x = sum b_n sin(nx) from 0 to pi/2 term by term.
exact = x * x / 2
quad = midpoint(saw, 0.0, x)
print(f"integral of the sawtooth from 0 to pi/2: x^2/2 = {exact:.6f}, midpoint rule {quad:.6f}")
assert abs(exact - quad) < 1e-9
I = 0.0
for n in range(1, 1001):
    I += b(n) * (1 - cos(n * x)) / n          # integral of sin(ny) from 0 to x is (1 - cos nx)/n
    if n in (1, 2, 3, 10, 100, 1000):
        miss, bound = abs(I - exact), 4 / n
        assert miss <= bound
        print(f"N={n}: integrated terms {I:.6f}, miss {miss:.6f}, tail bound 4/N {bound:.6f}")
no_const = I - sum(b(n) / n for n in range(1, 200001))   # antiderivatives -cos/n, no constant
print(f"forget the constant pi^2/6 = {pi * pi / 6:.6f}: {no_const:.4f}")
assert abs(no_const - (exact - pi * pi / 6)) < 1e-4

# An on-off version of the siren: g = (1 + sgn x)/2, 0 V or 1 V, mean 1/2; integrate to pi/2.
sq = lambda n: 4 / (pi * n) if n % 2 else 0.0          # sgn x = sum sq_n sin(nx)
osc = sum(0.5 * sq(n) * (1 - cos(n * x)) / n for n in range(1, 200001))
print(f"on-off wave, integral to pi/2: true {midpoint(lambda t: 1.0, 0.0, x):.4f}, "
      f"terms only {osc:.4f}, with the mean term {0.5 * x + osc:.4f}")
assert abs(0.5 * x + osc - x) < 1e-5                  # g = 1 V on (0, pi/2): integral pi/2
bounce = [(4 / pi) * sum(cos(k * pi / 4) for k in range(1, N + 1, 2)) for N in (1, 3, 5, 7)]
print("square wave, term-by-term slope at pi/4, N=1,3,5,7:", " ".join(f"{v if abs(v) > 1e-9 else 0.0:.4f}" for v in bounce))
assert abs(bounce[0]) > 0.9 and abs(bounce[2]) > 0.9   # the square wave is flat there: slope 0
print("ALL CHECKS PASS")
