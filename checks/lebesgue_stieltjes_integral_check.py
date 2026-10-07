# The Lebesgue-Stieltjes integral -- the check behind the card.  Standard
# library only; fractions does exact arithmetic and knows no integrals.  The
# claim X: 0 with probability 0.3, otherwise spread evenly over (0, 1000].
# E[X] is reached four ways: jump plus density (exact), the tail 1 - F
# (midpoint sums), Riemann-Stieltjes sums, and a SplitMix64 simulation.
from fractions import Fraction as Q

P0, DENS, TOP = Q(3, 10), Q(7, 10000), 1000     # jump at 0, density, top of the range

def F(x):                                       # distribution function, in floats
    return 0.0 if x < 0 else (0.3 + 0.0007 * x if x < 1000 else 1.0)

def mono(k, lo, hi):                            # exact integral of x^k from lo to hi
    return Q(hi ** (k + 1) - lo ** (k + 1), k + 1)

def rs_sums(g, n, a=-100.0, b=1000.0):          # left-tag and right-tag Stieltjes sums
    h = (b - a) / n
    left = right = 0.0
    for i in range(n):
        x0, x1 = a + i * h, a + (i + 1) * h
        rise = F(x1) - F(x0)
        left += g(x0) * rise
        right += g(x1) * rise
    return left, right

MASK = (1 << 64) - 1
state = 20260929
def uniform():                                  # SplitMix64, top 53 bits in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def claim():                                    # inverse of F: a draw of X
    u = uniform()
    return 0.0 if u < 0.3 else (u - 0.3) / 0.7 * 1000.0

def mid(fn, lo, hi, n):                         # midpoint sum of fn over (lo, hi]
    h, total = (hi - lo) / n, 0.0
    for i in range(n):                          # a plain loop: sum() compensates
        total += fn(lo + (i + 0.5) * h) * h
    return total

def mid_tail(lo, hi, n):                        # the area under the tail 1 - F
    return mid(lambda x: 1.0 - F(x), lo, hi, n)

# road 1: jump plus density, exact
jump_x, spread_x = P0 * 0, DENS * mono(1, 0, TOP)
ex = jump_x + spread_x
jump_fee, spread_fee = P0 * 50, DENS * (50 * mono(0, 0, TOP) + mono(1, 0, TOP))
print("claim law: P(X = 0) = 0.3; otherwise even on (0, 1000], density 0.0007")
print(f"road 1, jump plus density, exact: E[X] = {float(jump_x):.1f} + {float(spread_x):.1f} = {float(ex):.1f}")
print(f"road 1, with a $50 fee on every policy: E[50 + X] = {float(jump_fee):.1f} + "
      f"{float(spread_fee):.1f} = {float(jump_fee + spread_fee):.1f}")
# road 2: the tail
tail = mid_tail(0.0, 1000.0, 1000)
print(f"road 2, area under the tail 1 - F on (0, 1000], 1000 midpoint slices: {tail:.6f}")
print("tail 1 - F(x) at x = 0, 100, ..., 1000: " + " ".join(f"{1 - F(100 * k):.2f}" for k in range(11)))
parts = {}
for b in (250, 500, 1000):
    lhs = DENS * mono(1, 0, b)                  # exact: integral of x dF over (0, b]
    area, edge = mid_tail(0.0, float(b), b), b * (1.0 - F(b))
    parts[b] = (lhs, area, edge)
    print(f"by parts on (0, {b}]: int x dF = {float(lhs):.3f}; tail area {area:.3f} "
          f"- boundary {edge:.3f} = {area - edge:.3f}")
# road 3: Riemann-Stieltjes sums, g(x) = x, continuous
print("road 3, Riemann-Stieltjes sums for E[X] on (-100, 1000]:")
rs = {}
for n in (11, 110, 1100):
    rs[n] = rs_sums(lambda x: x, n)
    print(f"  n = {n:<5} left tags {rs[n][0]:.4f}   right tags {rs[n][1]:.4f}")
# road 4: simulation
N = 100000
draws = [claim() for _ in range(N)]
total = sq = 0.0
for d in draws:
    total += d
mean = total / N
for d in draws:
    sq += (d - mean) * (d - mean)
var = sq / (N - 1)
se = (var / N) ** 0.5
print(f"road 4, {N} simulated claims, SplitMix64 seed 20260929: mean {mean:.4f}, standard error {se:.4f}")
# integration by parts: F against itself on (-100, 1000]
jumpsq = P0 * P0                                # F(0) times the jump 0.3
strip = P0 * DENS * mono(0, 0, TOP)             # the constant 0.3 of F, against the spread
tri = DENS * DENS * mono(1, 0, TOP)             # the rising part of F, against the spread
direct = jumpsq + strip + tri
Fa, Fb = Q(F(-100.0)), Q(F(1000.0))            # F at the two ends: 0 and 1
formula = (Fb * Fb - Fa * Fa + P0 * P0) / 2     # (F(b)G(b) - F(a)G(a) + jump x jump) / 2
leftlim = 0 * P0 + strip + tri                  # F(0-) = 0 at the atom
print("integration by parts, F against itself on (-100, 1000]:")
print(f"  direct: jump {float(jumpsq):.3f} + strip {float(strip):.3f} + triangle {float(tri):.3f} = {float(direct):.3f}")
print(f"  by parts with the jump term: (1 - 0 + 0.3 x 0.3) / 2 = {float(formula):.3f}")
print(f"  left-limit form: int F(x-) dF = {float(leftlim):.3f}; sum with {float(direct):.3f} = {float(leftlim + direct):.3f}")
pairs = sum(1 for _ in range(N) if claim() <= claim()) / N
pse = (pairs * (1 - pairs) / N) ** 0.5
print(f"  simulation: share of {N} pairs with X' <= X: {pairs:.4f}, standard error {pse:.4f}")
# what breaks
print("mistakes:")
print(f"  density only, fee case: {float(spread_fee):.1f} (true {float(jump_fee + spread_fee):.1f})")
print(f"  by parts without the jump term: {float(Q(1, 2)):.3f} (true {float(direct):.3f})")
step = lambda x: 1.0 if x >= 0 else 0.0         # g = 1 on [0, infinity): jumps where F jumps
bad = {n: rs_sums(step, n) for n in (11, 110, 1100)}
print("  Riemann-Stieltjes, g = 1 on [0, inf), n = 11, 110, 1100: left "
      + " ".join(f"{l:.4f}" for l, r in bad.values()) + ", right "
      + " ".join(f"{r:.4f}" for l, r in bad.values()) + "; Lebesgue-Stieltjes 1.0")
print(f"  F in place of 1 - F: {mid(F, 0.0, 1000.0, 1000):.1f} (true {float(ex):.1f})")
print(f"  density 0.001 with no 0.7 weight: {float(Q(1, 1000) * mono(1, 0, TOP)):.1f}")
lhs, area, edge = parts[500]
print(f"  boundary term dropped at b = 500: {area:.1f} (true {float(lhs):.1f})")
print("Cantor function: rise 1; length where it can rise, (2/3)^n at n = 1, 5, 10, 20: "
      + " ".join(f"{(2 / 3) ** n:.6f}" for n in (1, 5, 10, 20)))
px = lambda u: 50 + 180 * u                     # F-coordinates to drawing units
py = lambda v: 200 - 180 * v
print(f"figure, 180 units per unit of F, corner ({px(0):.0f}, {py(0):.0f}); atom block to "
      f"({px(0.3):.0f}, {py(0.3):.0f}); diagonal to ({px(1):.0f}, {py(1):.0f}); "
      f"shaded area {float(direct):.3f}, unshaded {1 - float(direct):.3f}")
assert abs(tail - float(ex)) < 1e-6                         # tail road meets the exact road
assert all(rs[n][0] < float(ex) < rs[n][1] for n in rs)     # Stieltjes sums bracket 350
assert rs[1100][1] - rs[1100][0] < 1.01                     # and close in on it
assert direct == formula                                    # measure road = by-parts road
assert leftlim + direct == 1                                # the square: s <= t plus s > t
assert abs(mean - float(ex)) < 4 * se                       # simulation, within 4 errors
assert abs(pairs - float(direct)) < 4 * pse
assert abs(float(lhs) - (area - edge)) < 1e-6               # by parts with a boundary
print("ALL CHECKS PASS")
