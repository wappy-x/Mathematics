# Bounded variation -- the check behind the card.  Standard library only.
# A 12 km trail, its total variation found three ways, its Jordan split,
# a trail with a ladder (a jump), and three oscillating functions near zero.
from math import sin, pi, log

TURNS = [(0, 1000), (4, 1600), (6, 1300), (10, 1600), (12, 1200)]  # (km, metres)

def trail(x):                        # elevation, straight lines between turning points
    for (x0, y0), (x1, y1) in zip(TURNS, TURNS[1:]):
        if x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return TURNS[-1][1]

def ladder(x):                       # the same trail with a 50 m ladder at km 8
    return trail(x) + (50 if x >= 8 else 0)

def partition_sum(f, pts, g=abs):    # sum of g(change) over one partition
    return sum(g(f(b) - f(a)) for a, b in zip(pts, pts[1:]))

def best_on_grid(f, end, g=abs, step=0.25):
    # Road 2: the definition.  Best partition using any points of a 0.25 km grid,
    # found by dynamic programming over "last point used".
    grid = [i * step for i in range(int(end / step) + 1)]
    best = [0.0] * len(grid)
    for j in range(1, len(grid)):
        best[j] = max(best[i] + g(f(grid[j]) - f(grid[i])) for i in range(j))
    return best[-1]

up = lambda d: max(d, 0.0)           # climb in one step
down = lambda d: max(-d, 0.0)        # descent in one step

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return z ^ (z >> 31)
    def unit(self): return (self.next() >> 11) * 2.0 ** -53

# Road 1: piecewise monotone, so add the rises and falls between turning points.
V_turns = sum(abs(y1 - y0) for (_, y0), (_, y1) in zip(TURNS, TURNS[1:]))
V_grid = best_on_grid(trail, 12)
# Road 3: 20,000 random partitions with points anywhere; none may beat the turning-point sum.
rng, V_rand, beaten = SplitMix64(2026), 0.0, 0
for _ in range(20000):
    m = 1 + rng.next() % 30
    pts = [0.0] + sorted(12 * rng.unit() for _ in range(m)) + [12.0]
    s = partition_sum(trail, pts)
    V_rand, beaten = max(V_rand, s), beaten + (s > V_turns + 1e-9)
print(f"variation, turning points     {V_turns:10.2f}")
print(f"variation, best grid partition{V_grid:10.2f}")
print(f"variation, best of 20000 random{V_rand:9.2f}   beat it: {beaten}")
print(f"net change f(12) - f(0)       {trail(12) - trail(0):10.2f}")
print(f"Lipschitz ceiling 200 x 12    {200 * 12:10.2f}")
assert abs(V_grid - V_turns) < 1e-9, "definition and turning points disagree"
assert beaten == 0 and V_rand > 0.97 * V_turns, "a random partition beat the sup"

print("equal pieces n : sum collected")
for n in (1, 2, 3, 4, 5, 6, 12):
    print(f"  n = {n:2d}        {partition_sum(trail, [12 * i / n for i in range(n + 1)]):10.2f}")

print("km  elevation  climb P  descent N  P - N  P + N")
for km in range(13):
    P, N, V = (best_on_grid(trail, km, g) for g in (up, down, abs))
    print(f"{km:2d} {trail(km):10.2f} {P:8.2f} {N:10.2f} {P - N:6.2f} {P + N:7.2f}")
    assert abs((P - N) - (trail(km) - trail(0))) < 1e-9, "Jordan: P - N is not the net change"
    assert abs((P + N) - V) < 1e-9, "Jordan: P + N is not the variation"

V_lad = best_on_grid(ladder, 12)
print(f"ladder: variation {V_lad:.2f}, climb {best_on_grid(ladder, 12, up):.2f}")
assert abs(V_lad - (V_turns + 50)) < 1e-9, "the ladder should add exactly its height"
for k in (1, 2, 3, 6):
    print(f"ladder: f(8 - 1e-{k}) = {ladder(8 - 10.0 ** -k):9.4f}   f(8 + 1e-{k}) = {ladder(8 + 10.0 ** -k):9.4f}")

# Oscillation near zero on [0, 2/pi]: peaks of sin(1/x) at x_k = 2 / ((2k + 1) pi).
xk = lambda k: 2 / ((2 * k + 1) * pi)
def peak_sum(f, n):                  # partition 0 < x_n < ... < x_0, evaluated directly
    return partition_sum(f, [0.0] + [xk(k) for k in range(n, -1, -1)])
wild = lambda x: x * sin(1 / x) if x else 0.0
damp = lambda x: x * x * sin(1 / x) if x else 0.0
print("peaks n   x sin(1/x)   x^2 sin(1/x)")
S, D = {}, {}
for n in (1, 10, 100, 1000, 10000, 100000):
    S[n], D[n] = peak_sum(wild, n), peak_sum(damp, n)
    print(f"{n:7d} {S[n]:12.4f} {D[n]:14.4f}")
print("chart, x sin(1/x):  ", " ".join(f"{v:.2f}" for v in S.values()))
print("chart, x^2 sin(1/x):", " ".join(f"{v:.2f}" for v in D.values()))
closed = xk(0) + 2 * sum(xk(k) for k in range(1, 1001))   # x_0 + 2(x_1 + ... + x_n)
print(f"x sin(1/x), n = 1000 by the formula x_0 + 2 sum x_k  {closed:.4f}")
print(f"x sin(1/x), gain per tenfold n {S[100000] - S[10000]:.4f}   (2/pi) ln 10 = {2 / pi * log(10):.4f}")
print(f"x^2 sin(1/x): limit 1 - 4/pi^2 = {1 - 4 / pi ** 2:.4f}   Lipschitz ceiling {(1 + 4 / pi) * 2 / pi:.4f}")
assert abs(S[1000] - closed) < 1e-9, "direct sum and formula disagree"
assert abs((S[100000] - S[10000]) - 2 / pi * log(10)) < 1e-3, "growth is not logarithmic"
assert abs(D[100000] - (1 - 4 / pi ** 2)) < 1e-5, "damped sums miss their limit"

swing = lambda x: sin(1 / x)
for n in (10, 100):
    got = partition_sum(swing, [xk(k) for k in range(n, -1, -1)])   # peaks only: no value at 0
    print(f"sin(1/x): {n} swings collect {got:.2f}")
    assert abs(got - 2 * n) < 1e-9, "each swing from +1 to -1 should add 2"
print("All checks passed.")
