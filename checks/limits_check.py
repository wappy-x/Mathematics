# Limits -- the check behind the card.  Nothing is imported.
# f(x) = (x^2 - 1)/(x - 1) has no value at x = 1.  Road one works the original
# fraction; road two the cancelled form x + 1.  A bisection search then finds,
# by brute force over a window of sampled inputs, the widest distance from 1
# that keeps every output within a tolerance of the limit; the card's proof
# says that distance equals the tolerance for f, and a third of it for 3x - 1.
def f(x): return (x * x - 1) / (x - 1)       # the original fraction, x != 1
def line(x): return x + 1                    # the cancelled form
def steep(x): return 3 * x - 1               # a second straight line through (1, 2)
def jump(x): return 0.0 if x < 1 else 1.0    # a rule that jumps at 1

def worst(rule, L, r, n=200):                # biggest miss from L, 0 < |x - 1| <= r
    return max(abs(rule(1 + s * r * k / n) - L) for k in range(1, n + 1) for s in (-1, 1))

def radius(rule, L, t):                      # bisection: widest window whose misses stay under t
    lo, hi = 0.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if worst(rule, L, mid) < t: lo = mid
        else: hi = mid
    return lo

xs = [0.9, 0.99, 0.999, 1.001, 1.01, 1.1]
for x in xs:
    print(f"x = {x:.3f}: top {x * x - 1:.6f} / bottom {x - 1:.6f} = {f(x):.6f}; x + 1 = {line(x):.6f}")
print(f"x = 1: top {1 * 1 - 1}, bottom {1 - 1}, no value; cancelled form gives {line(1.0):.6f}")
found = {}
for t in (0.1, 0.01, 0.001):
    found[t] = (radius(f, 2, t), radius(steep, 2, t))
    print(f"tolerance {t:.3f}: widest distance for f {found[t][0]:.6f}, for 3x - 1 {found[t][1]:.6f}")
x = 1.0009
print(f"distance 0.001 used for 3x - 1: x = {x:.4f} misses 2 by {abs(steep(x) - 2):.6f}")
print("patched rule, value 100 at x = 1: widest distance at tolerance 0.001 "
      f"{radius(lambda u: 100.0 if u == 1 else f(u), 2, 0.001):.6f}")
best = min((worst(jump, -1 + i / 1000, 0.001), -1 + i / 1000) for i in range(3001))
print(f"jump at 1: best candidate {best[1]:.3f}, smallest possible miss {best[0]:.6f}, over tolerance 0.25")
r = radius(f, 2, 0.5)
X, Y = (lambda u: 50 + 70 * u), (lambda v: 220 - 70 * v)
print(f"figure, 70 px per unit, tolerance 0.5, distance {r:.3f}: hole ({X(1):.0f}, {Y(2):.0f}); line ({X(0):.0f}, {Y(1):.0f}) "
      f"to ({X(2):.0f}, {Y(3):.0f}); band y {Y(2.5):.0f} to {Y(1.5):.0f}; window x {X(1 - r):.0f} to {X(1 + r):.0f}")
assert all(abs(f(x) - line(x)) < 1e-9 for x in xs)                  # two roads agree
assert all(abs(found[t][0] - t) < 1e-6 * t for t in found)          # search matches: distance = tolerance
assert all(abs(found[t][1] - t / 3) < 1e-6 * t for t in found)      # search matches: tolerance / slope
assert abs(best[0] - 0.5) < 1e-9 and best[0] > 0.25                 # the jump defeats tolerance 0.25
print("ALL CHECKS PASS")
