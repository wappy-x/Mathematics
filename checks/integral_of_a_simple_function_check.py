# The integral of a simple function -- the check behind the card.  Standard
# library only.  River depth d(x) = 4x(1 - x) metres at x km along a 1 km
# stretch, rounded down to the quarter metre, is a simple function s.
# Road one finds where the depth crosses each level by bisection and adds
# value times length over the pieces {s = value}.  Road two adds the
# overlapping layers {d >= c} with lengths from the square root.  Road three
# averages s over a million-point grid.  Road four cuts every piece at each
# 0.1 km mark.  Then linearity, monotonicity, a die, and what breaks.
import math
from fractions import Fraction

M = 4                                      # steps per metre: quarter-metre levels

def depth(x):
    return 4 * x * (1 - x)

def s(x):                                  # depth rounded down to a quarter metre
    return int(depth(x) * M) / M

def left_end(c):                           # smallest x in [0, 0.5] with depth(x) >= c
    lo, hi = 0.0, 0.5
    for _ in range(100):
        mid = (lo + hi) / 2
        if depth(mid) >= c:
            hi = mid
        else:
            lo = mid
    return hi

L = [left_end(k / M) for k in range(M)] + [0.5, 0.5]   # d = 1 only at x = 0.5: 1 - d = (1 - 2x)^2
print("layer {d >= c}: c, from, to, length (km)")
for k in range(1, M + 1):
    print(f"  c = {k / M:.2f}: {L[k]:.4f} to {1 - L[k]:.4f}, length {1 - 2 * L[k]:.4f}")

# road one: the level sets {s = k/4}, each two intervals, found by bisection
piece = [2 * (L[k + 1] - L[k]) for k in range(M + 1)]
road1 = 0.0
for k in range(M + 1):
    road1 += k / M * piece[k]
    print(f"road 1, piece s = {k / M:.2f} m: length {piece[k]:.4f} km, value x length {k / M * piece[k]:.4f}")
print(f"road 1, level sets by bisection: {road1:.4f} km-m")

# road two: layers {d >= c} overlap; each adds one step of 0.25 m
layer = [math.sqrt(1 - k / M) for k in range(1, M + 1)]
road2 = sum(layer) / M
print(f"road 2, layers {1 / M:g} x ({' + '.join(f'{v:.4f}' for v in layer[:-1])}) = {road2:.4f} km-m"
      f"; (1 + sqrt 2 + sqrt 3)/8 = {road2:.6f}")
assert abs(road1 - road2) < 1e-12
hits = [k / M for k in range(1, M + 1) if depth(0.4) >= k / M]   # the layers holding x = 0.4 km
print(f"point 0.4 km: depth {depth(0.4):.4f}, level {s(0.4):.2f}; in {len(hits)} layers, {1 / M:g} x {len(hits)}"
      f" = {len(hits) / M:.2f}; weighted by level {sum(hits):.2f}")
assert len(hits) / M == s(0.4)

# road three: average of s over a grid of a million midpoints; also t <= s
N = 1_000_000
total, t_below = 0.0, True
for i in range(N):
    x = (i + 0.5) / N
    total += s(x)
    t_below = t_below and int(depth(x) * 2) / 2 <= s(x)
grid = total / N
print(f"road 3, grid of {N} midpoints: {grid:.6f} km-m")
assert abs(grid - road2) < 2 * (M - 1) / M / N   # 2(M - 1) jumps, each off by 1/M m on one cell

# road four: a finer partition -- every piece cut again at each 0.1 km mark
def refined(f, cuts):
    pts = sorted(set([0.0, 1.0] + cuts))
    return sum(f((a + b) / 2) * (b - a) for a, b in zip(pts, pts[1:])), len(pts) - 1
ends = [L[k] for k in range(1, M + 1)] + [1 - L[k] for k in range(1, M + 1)]
road4, cells = refined(s, ends + [j / 10 for j in range(1, 10)])
print(f"road 4, cut again at every 0.1 km: {cells} cells, {road4:.4f} km-m")
assert abs(road4 - road1) < 1e-12

# linearity: silt u = 0.2 m on [0.3, 0.8), 0.1 m on [0.8, 1]; and scaling to centimetres
def u(x):
    return 0.2 if 0.3 <= x < 0.8 else (0.1 if x >= 0.8 else 0.0)
int_u = 0.2 * 0.5 + 0.1 * 0.2
both, cells2 = refined(lambda x: s(x) + u(x), ends + [0.3, 0.8])
print(f"linearity: integral of silt u = {int_u:.4f}; of s + u on {cells2} cells = {both:.4f}"
      f"; sum of the two = {road1 + int_u:.4f}")
assert abs(both - (road1 + int_u)) < 1e-12
cm, _ = refined(lambda x: 100 * s(x), ends)
print(f"scaling: depth in centimetres, integral {cm:.2f} km-cm = 100 x {road1:.4f}")
assert abs(cm - 100 * road1) < 1e-9

# monotonicity: t = depth rounded down to the half metre sits below s
int_t, _ = refined(lambda x: int(depth(x) * 2) / 2, ends)
print(f"monotonicity: t <= s at every grid point: {'yes' if t_below else 'no'}; integral of t = {int_t:.4f} <= {road1:.4f}")
assert t_below
assert abs(int_t - 0.5 * math.sqrt(0.5)) < 1e-12

# the same formula against a probability: a die paying 0, 0, 0, 2, 2, 6
pay = [0, 0, 0, 2, 2, 6]
by_point = sum(Fraction(p, 6) for p in pay)
by_level = sum(v * Fraction(pay.count(v), 6) for v in set(pay))
print(f"die: point by point {by_point}, by level sets {by_level} = {float(by_level):.4f}")
assert by_point == by_level == Fraction(5, 3)

# finer steps rise toward the true area 2/3 (the next card's limit)
for m in (2, 4, 8, 16):
    low = sum(math.sqrt(1 - k / m) for k in range(1, m + 1)) / m
    print(f"step 1/{m} m: lower staircase {low:.4f}")
    assert low <= 2 / 3
print(f"true area under d: 2/3 = {2 / 3:.4f}; staircase average depth {road1:.4f} m, short by {2 / 3 - road1:.4f}")

# what breaks
up, _ = refined(lambda x: math.ceil(depth(x) * M) / M, ends)
print(f"breaks, rounding up: {up:.4f} km-m, above 2/3; gap to s = {up - road1:.4f} = {1 / M:g} m x 1 km")
assert abs(up - road1 - 1 / M) < 1e-12
assert up > 2 / 3
levels_only = sum(k / M for k in range(1, M))
print(f"breaks, levels added without lengths: {' + '.join(f'{k / M:.2f}' for k in range(1, M))} = {levels_only:.2f}")
wrong_layers = sum(k / M * (1 - 2 * L[k]) for k in range(1, M + 1))
print(f"breaks, overlapping layers weighted by their level: {wrong_layers:.4f}, not {road1:.4f}")
assert abs(wrong_layers - road1) > 0.1
n = 1000                                   # +1 on [0, inf), -1 on (-inf, 0), summed unit by unit
cut = [sum(1 if j >= 0 else -1 for j in range(-n, b)) for b in (n, 2 * n)]
print(f"breaks, signed pieces +1 on [0, inf), -1 on (-inf, 0): cut at [-{n}, {n}] gives {cut[0]},"
      f" at [-{n}, {2 * n}] gives {cut[1]}")
assert cut == [0, n]

xs = ", ".join(f"{40 + 300 * v:.1f}" for v in sorted(e for e in ends if e != 0.5))
ys = ", ".join(f"{200 - 160 * k / M:.0f}" for k in range(1, M))
print(f"figure, x = 40 + 300 x, y = 200 - 160 d; ends x = {xs}; levels y = {ys}; apex (190, 40)")
assert 200 - 160 * depth(0.5) == 40
print("ALL CHECKS PASS")
