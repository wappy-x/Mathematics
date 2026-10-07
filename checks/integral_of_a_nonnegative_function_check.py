# The integral of a non-negative function -- the check behind the card.
# Standard library only.  River depth d(x) = 4x(1 - x) metres at x km along a
# 1 km stretch.  Staircases below d (depth rounded down to steps of 1/k m) are
# integrated by three roads: piece lengths from the quadratic formula, piece
# lengths from a bisection root finder, and a fine grid of midpoints in x.
from fractions import Fraction

def depth(x):
    return 4 * x * (1 - x)

def length_formula(t):                   # length of {d >= t}: x from (1 - r)/2 to (1 + r)/2
    return (1 - t) ** 0.5 if t < 1 else 0.0

def length_bisect(t):                    # road two: halve [0, 0.5] onto the left crossing
    if t >= 1:
        return 0.0                       # {d >= 1} is the single point x = 0.5
    lo, hi = 0.0, 0.5
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if depth(mid) >= t else (mid, hi)
    return 1 - 2 * hi

def staircase(k, length, up=0):          # sum of value x length of piece {j/k <= d < (j+1)/k}
    return sum((j + up) / k * (length(j / k) - length((j + 1) / k)) for j in range(k))

def grid(func, M):                       # road three: midpoint sum of a step function
    return sum(func((i + 0.5) / M) for i in range(M)) / M

def ln(y):                               # natural log by the series 2(z + z^3/3 + ...)
    z, total, i = (y - 1) / (y + 1), 0.0, 0
    p = z
    while abs(p) > 1e-17:
        total += p / (2 * i + 1)
        p, i = p * z * z, i + 1
    return 2 * total

exact = Fraction(2) - Fraction(4, 3)     # antiderivative 2x^2 - 4x^3/3 from 0 to 1
M = 100_000
print(f"area under d by the antiderivative 2x^2 - 4x^3/3: {exact} = {float(exact):.6f} km m")
print("k levels, staircase by formula, by bisection, by grid of 100000 midpoints, upper staircase, gap to 2/3")
lows, ups = [], []
for n in range(1, 9):
    k = 2 ** n
    a, b = staircase(k, length_formula), staircase(k, length_bisect)
    c = grid(lambda x: int(k * depth(x)) / k, M)
    u = staircase(k, length_formula, up=1)
    assert abs(a - b) < 1e-12 and abs(a - c) <= 2 / M + 1e-12   # three roads, bound 2/M
    assert a < exact < u and (not lows or lows[-1] < a)         # squeezed, and rising
    lows.append(a); ups.append(u)
    print(f"{k:3d}, {a:.6f}, {b:.6f}, {c:.6f}, {u:.6f}, {float(exact) - a:.6f}")
print("chart, lower:", ", ".join(f"{v:.2f}" for v in lows))
print("chart, upper:", ", ".join(f"{v:.2f}" for v in ups))
near = sum(length_formula((j - 0.5) / 2) for j in (1, 2)) / 2
print(f"k = 2 rounded to nearest, not down: {near:.6f}, above {float(exact):.6f}")

covers = [2 * e for e in (0.1, 0.001, 0.00001)]
print("covers of the point x = 0.5 by [0.5 - e, 0.5 + e], e = 0.1, 0.001, 0.00001:",
      ", ".join(f"{v:.5f}" for v in covers))
left = sum(depth(j / 1000) for j in range(1000)) / 1000
print(f"1000 left-end samples: {left:.6f}; with the 1000 m spike sampled: {left + 999 / 1000:.6f}")

print("t, length of {d >= t} by formula, by bisection, Markov bound (2/3)/t, t x length")
for t in (0.25, 0.5, 0.75, 0.9):
    L, Lb, bound = length_formula(t), length_bisect(t), float(exact) / t
    assert abs(L - Lb) < 1e-12 and L <= bound and t * L < float(exact)
    print(f"{t:.2f}, {L:.6f}, {Lb:.6f}, {bound:.6f}, {t * L:.6f}")
f_tight = lambda x: 0.75 if 0.25 <= x <= 0.75 else 0.0  # f = 0.75 on [0.25, 0.75], 0 elsewhere
tight = grid(f_tight, M)                                  # its integral, on the grid
t_len = grid(lambda x: float(f_tight(x) >= 0.75), M)      # size of {f >= 0.75}, measured on the grid
assert abs(tight / 0.75 - t_len) < 1e-12                  # Markov met with equality
print(f"tight: f = 0.75 on [0.25, 0.75], integral {tight:.3f}, bound at t = 0.75: {tight / 0.75:.3f}, true {t_len:.3f}")
signed_f = lambda x: 2.0 if x < 0.5 else -2.0
s_int, s_len = grid(signed_f, M), grid(lambda x: float(signed_f(x) >= 1), M)
assert s_len > s_int / 1                                  # Markov fails once f may be negative
print(f"signed f = +2 then -2: integral {s_int:.1f}, length of {{f >= 1}} {s_len:.1f}, Markov bound {s_int / 1:.1f}")

print("n, staircase of 1/x: layers, grid of 200000, 1 + ln n; staircase of 1/sqrt(x): layers, grid")
rec, rsq = [], []
for n in (1, 2, 4, 8, 16):
    m = 2 ** n
    lay_r = sum(min(1.0, m / j) for j in range(1, n * m + 1)) / m       # sizes of {f >= j/m}
    lay_s = sum(min(1.0, (m / j) ** 2) for j in range(1, n * m + 1)) / m
    g_r = grid(lambda x: min(n, int(m / x) / m), 200_000)
    g_s = grid(lambda x: min(n, int(m / x ** 0.5) / m), 200_000)
    assert abs(lay_r - g_r) <= n / 200_000 and abs(lay_s - g_s) <= n / 200_000
    lo_r = 1 + ln((n * m + 1) / (m + 1))                  # sum of 1/j beats the integral of 1/x
    lo_s = 1 + m / (m + 1) - m / (n * m + 1)
    assert lo_r <= lay_r <= 1 + ln(n) + 1e-12 and lo_s <= lay_s <= 2 - 1 / n + 1e-12
    rec.append(lay_r); rsq.append(lay_s)
    print(f"{n:2d}, {lay_r:.4f}, {g_r:.4f}, {1 + ln(n):.4f}; {lay_s:.4f}, {g_s:.4f}")
print("chart, 1/x:", ", ".join(f"{v:.2f}" for v in rec))
print("chart, 1/sqrt(x):", ", ".join(f"{v:.2f}" for v in rsq))
steps = [30 + 300 * (1 - length_formula(t)) / 2 for t in (0.25, 0.5, 0.75)]
print("figure, x px " + ", ".join(f"{v:.1f}" for v in steps + [360 - s for s in reversed(steps)])
      + "; y px 80, 120, 160; bed bottom (180, 200)")
print("ALL CHECKS PASS")
