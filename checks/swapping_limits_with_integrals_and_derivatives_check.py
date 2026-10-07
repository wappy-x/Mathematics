# Swapping limits -- the check behind the card.  math's sin and log are
# primitives; every integral, slope and sum below is built here, and each
# answer is reached by two roads that share no arithmetic.
from math import sin, log

def spike(n, x):                    # tent on [0, 1/n], peak 2n at x = 1/(2n)
    return max(0.0, 2 * n - abs(4 * n * n * x - 2 * n))

def midpoint(f, a, b, m):           # m rectangles, each read at its middle
    h = (b - a) / m
    return h * sum(f(a + (i + 0.5) * h) for i in range(m))

def simpson(f, a, b, m):            # m strips (m even), weights 1 4 2 4 ... 4 1
    h = (b - a) / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(a + i * h) for i in range(m + 1))

def S(x):                           # the sum of (x/2)^k for k = 1, 2, 3, ...
    return x / (2 - x)

for n in (1, 2, 4):
    print(f"chart n={n}:", " ".join(f"{spike(n, i / 8):.2f}" for i in range(9)))
for n in (1, 10, 50, 1000):
    tri = 0.5 * (1 / n) * (2 * n)                               # road one: half base times height
    rect = midpoint(lambda x: spike(n, x), 0.0, 1.0, 100000)    # road two: 100,000 rectangles
    assert abs(tri - rect) < 1e-9
    print(f"spike n={n}: worst gap {2 * n}, area by triangle {tri:.6f}, "
          f"by rectangles {rect:.6f}, height at x=0.01 {spike(n, 0.01):.6f}")
print(f"integral of the limit (0 everywhere): {midpoint(lambda x: 0.0, 0.0, 1.0, 1000):.6f}")
exact = 2 * log(2) - 1                                          # from the antiderivative -x - 2 ln(2 - x)
simp = simpson(S, 0.0, 1.0, 1000)
print(f"integral of S on [0, 1]: antiderivative {exact:.9f}, Simpson {simp:.9f}")
for N in (5, 10, 20):
    worst = max(abs(S(i / 1000) - sum((i / 2000) ** k for k in range(1, N + 1))) for i in range(1001))
    tbt = sum(1 / ((k + 1) * 2 ** k) for k in range(1, N + 1))  # integrate term by term
    assert 0 < simp - tbt <= (1 - 0) * worst                  # miss <= (b - a) * worst gap
    print(f"N={N}: worst gap {worst:.9f}, integrals of terms {tbt:.9f}, miss {exact - tbt:.9f}")
h = 1e-6
for n in (1, 10, 100):
    worst = max(abs(sin(n * i / 10000)) / n for i in range(70001))
    slope0 = (sin(n * h) - sin(-n * h)) / (2 * n * h)           # difference quotient at 0
    assert abs(slope0 - 1) < 1e-6 and abs(worst * n - 1) < 1e-3 # gap 1/n, slope stuck at 1
    print(f"wave n={n}: worst gap {worst:.6f}, slope at 0 {slope0:.6f}; limit 0, its slope 0")
x = 0.5
tbt = sum(k * x ** (k - 1) / 2 ** k for k in range(1, 80))     # slopes of the terms, added
dq = (S(x + h) - S(x - h)) / (2 * h)                            # slope of the sum, measured
assert abs(tbt - dq) < 1e-7
print(f"slope of S at {x}: term by term {tbt:.6f}, difference quotient {dq:.6f}, "
      f"formula 2/(2-x)^2 {2 / (2 - x) ** 2:.6f}")
print(f"caps on the slope terms, k/2^k added to k=60: {sum(k / 2 ** k for k in range(1, 61)):.6f}")
for n in (10, 1000):
    print(f"block n={n} on [0, {n}]: worst gap {1 / n:.6f}, area {midpoint(lambda t: 1 / n, 0.0, n, 1000):.6f}")
print("ALL CHECKS PASS")
