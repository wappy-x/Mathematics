# Picard iteration -- the check behind the card.  Standard library only.
# Road one feeds polynomial coefficients back in, exactly.  Road two feeds a
# curve sampled on a grid back in, adding up trapezoids; it never learns the
# curves are polynomials.  exp and sqrt are primitives; the iteration is ours.
from fractions import Fraction
from math import exp, factorial, sqrt

def coeffs(n, lead=1):                # y' = y, y(0) = 1: integrate, then add lead
    c = [Fraction(1)]
    for _ in range(n):
        c = [Fraction(lead)] + [a / (k + 1) for k, a in enumerate(c)]
    return c

def value(c, t):
    return float(sum(a * Fraction(t) ** k for k, a in enumerate(c)))

def picard_grid(f, y0, T, sweeps, guess, N=1000):   # end value of each iterate
    dt = T / N
    ts = [i * dt for i in range(N + 1)]
    ys = [guess(t) for t in ts]
    ends = [ys[-1]]
    for _ in range(sweeps):
        rate = [f(t, y) for t, y in zip(ts, ys)]
        ys = [y0]
        for i in range(N):
            ys.append(ys[-1] + dt * (rate[i] + rate[i + 1]) / 2)
        ends.append(ys[-1])
    return ends

def euler(h):                         # small steps along the slope, to t = 1
    y = 1.0
    for _ in range(round(1 / h)):
        y += h * y
    return y

e = exp(1)
grid = picard_grid(lambda t, y: y, 1.0, 1.0, 5, lambda t: 1.0)
for n in range(6):
    v, bound = value(coeffs(n), 1), 2 / factorial(n + 1)
    print(f"iterate {n} at t=1: coefficients {v:.6f}, grid {grid[n]:.6f}, gap to e {e - v:.6f}, bound {bound:.6f}")
ts = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
print("figure, t (h): " + " ".join(f"{t:.1f}" for t in ts))
for n in (1, 2, 3):
    print(f"figure, iterate {n}: " + " ".join(f"{value(coeffs(n), Fraction(t).limit_denominator(10)):.2f}" for t in ts))
print("figure, e^t: " + " ".join(f"{exp(t):.2f}" for t in ts))
e1, e2 = euler(0.01), euler(0.001)
print(f"euler's rule to t=1: step 0.01 gives {e1:.6f} (gap {e - e1:.6f}), step 0.001 gives {e2:.6f} (gap {e - e2:.6f})")
bucket = picard_grid(lambda t, h: -0.2 * sqrt(h), 25.0, 10.0, 6, lambda t: 25.0)
exact = (5 - 0.1 * 10) ** 2
print("bucket at t=10 min, iterates 0-6: " + " ".join(f"{b:.4f}" for b in bucket) + f"; exact {exact:.4f}")
root = lambda t, y: sqrt(max(y, 0.0))
zero = picard_grid(root, 0.0, 2.0, 5, lambda t: 0.0)
other = picard_grid(root, 0.0, 2.0, 1, lambda t: t * t / 4)
print(f"y' = sqrt(y), y(0) = 0, at t=2: iterates from 0 give {zero[-1]:.4f}; t^2/4 fed in returns {other[-1]:.4f}")
print(f"mistake, y0 not added after integrating: iterate 5 at t=1 is {value(coeffs(5, 0), 1):.6f}")
assert abs(grid[5] - value(coeffs(5), 1)) < 1e-5               # two roads, one iterate
assert all(0 < e - value(coeffs(n), 1) <= 2 / factorial(n + 1) for n in range(6))
assert abs(bucket[-1] - exact) < 1e-4                          # the bucket converges
assert 9 < (e - e1) / (e - e2) < 11 and abs(e - e2) < 2e-3     # stepping closes in
print("ALL CHECKS PASS")
