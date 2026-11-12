# Monte Carlo integration in many dimensions -- the check behind the card.
# Standard library only.  The volume of a 10-dimensional ball of radius 1,
# reached four ways: the closed form, slicing (a chain of 1-D integrals),
# a grid of cell centres counted exactly, and seeded darts.
from math import pi, exp, sqrt, log, cos
D, N, SEED = 10, 100000, 2026
MASK, state = (1 << 64) - 1, SEED

def u():                                      # one uniform number in [0, 1), SplitMix64
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def darts(d, n):                              # how many of n darts in [-1, 1]^d land in the ball
    hits = 0
    for _ in range(n):
        r2 = 0.0
        for _ in range(d):
            x = 2.0 * u() - 1.0
            r2 += x * x
        hits += r2 <= 1.0
    return hits

def exact(d):                                 # V_d = pi^(d/2) / (d/2)!, by V_d = V_(d-2) 2 pi / d
    v, k = (1.0, 2) if d % 2 == 0 else (2.0, 3)
    while k <= d:
        v, k = v * 2 * pi / k, k + 2
    return v

def sliced(d, slices=2000):                   # V_k = V_(k-1) x integral of cos^k over (-pi/2, pi/2)
    v, h = 1.0, pi / slices
    for k in range(1, d + 1):
        w = sum((1 if i in (0, slices) else 4 if i % 2 else 2) * cos(-pi / 2 + i * h) ** k
                for i in range(slices + 1))
        v *= w * h / 3
    return v

def grid_walk(m, d, left, depth=0):           # road A: visit grid points, drop a branch once outside
    if depth == d:
        return 1
    return sum(grid_walk(m, d, left - c * c, depth + 1)
               for c in range(1 - m, m, 2) if c * c <= left)

def grid_sums(m, d):                          # road B: count by the sum of squares, coordinate by coordinate
    ways = {0: 1}
    for _ in range(d):
        nxt = {}
        for s, w in ways.items():
            for c in range(1 - m, m, 2):
                if s + c * c <= m * m:
                    nxt[s + c * c] = nxt.get(s + c * c, 0) + w
        ways = nxt
    return sum(ways.values())

def mid(m):                                   # 1-D midpoint rule for e^x / (e - 1) on [0, 1]; true value 1
    return sum(exp((j + 0.5) / m) for j in range(m)) / m / (exp(1) - 1)

V, cube = exact(D), 2.0 ** D
p = V / cube
sigma = cube * sqrt(p * (1 - p))
print(f"exact: V_10 = pi^5 / 120 = {V:.6f}; cube [-1, 1]^10 has volume {cube:.0f}; fraction inside p = {p:.8f}, about 1 in {1 / p:.0f}")
print(f"slicing road, Simpson on cos^k with 2000 slices per step: {sliced(D):.6f}")
print(f"one dart's score: {cube:.0f} inside, 0 outside; sigma = 1024 sqrt(p(1 - p)) = {sigma:.4f}")

K = darts(D, N)
est = cube * K / N
s = cube * sqrt(K / N * (1 - K / N) * N / (N - 1))
se = s / sqrt(N)
print(f"darts: {N} in [-1, 1]^10, seed {SEED}: {K} inside; expected {N * p:.1f}")
print(f"  estimate 1024 x {K} / {N} = {est:.4f}; standard error {se:.4f} (true {sigma / sqrt(N):.4f}); s {s:.4f}")
print(f"  95% interval {est - 1.96 * se:.4f} to {est + 1.96 * se:.4f}; miss {est - V:+.4f} = {(est - V) / se:+.2f} standard errors")
print(f"  relative standard error {sigma / sqrt(N) / V:.4f}")

print("grid of cell centres, m per axis: points, inside (walk), inside (by sums), estimate, miss")
grid = {}
for m in (2, 3, 4, 5, 6):
    walk = grid_walk(m, D, m * m) if m <= 5 else -1
    by_sum = grid_sums(m, D)
    grid[m] = cube * by_sum / m ** D
    if m <= 5:
        assert walk == by_sum                           # two counting roads agree
    print(f"  m = {m}: {m ** D:>9} {walk:>7} {by_sum:>7} {grid[m]:.4f} {grid[m] - V:+.4f}")
dart_se_3 = sigma / sqrt(3 ** D)
print(f"darts at the 3-per-axis budget of {3 ** D}: standard error {dart_se_3:.4f}")
print(f"6 per axis: {6 ** D / N:.0f} times the darts' points, {abs(grid[6] - V) / abs(est - V):.2f} times the darts' miss")

print("error rate exponents: error falls like N^-rate; d, midpoint 2/d, Simpson 4/d, Monte Carlo 1/2")
for d in range(1, 13):
    print(f"  {d:>2} {2 / d:.2f} {4 / d:.2f} 0.50")
print(f"crossover: midpoint loses past d = {2 / 0.5:.0f}, Simpson past d = {4 / 0.5:.0f}; a jump edge gives 1/d = {1 / D:.2f} in 10-D")
print(f"points per axis for {N} grid points in 10-D: {N ** (1 / D):.4f}")
print(f"cost of one more decimal place in 10-D: darts x{10 ** 2}, Simpson x{10 ** 2.5:.0f}, midpoint x{10 ** 5}")

e = [abs(mid(m) ** D - 1) for m in (3, 6, 12)]
rate = log(e[0] / e[1]) / log(2 ** D)
print(f"smooth test, e^(x1 + ... + x10) / (e - 1)^10 on [0, 1]^10, true integral 1, midpoint grid:")
print(f"  3 per axis ({3 ** D} points) miss {e[0]:.5f}; 6 per axis ({6 ** D}) miss {e[1]:.5f}; 12 per axis miss {e[2]:.6f}")
print(f"  1024 times the points cut the miss {e[0] / e[1]:.2f} times; measured rate {rate:.3f}, theory 0.200; darts: {sqrt(2 ** D):.2f} times")

print("same N = 1000 darts, 200 runs each: d, sigma / root N, observed root-mean-square miss")
rms = {}
for d in (2, 5, 10):
    vd, cd = exact(d), 2.0 ** d
    pd = vd / cd
    sq = sum((cd * darts(d, 1000) / 1000 - vd) ** 2 for _ in range(200))
    rms[d] = (sqrt(sq / 200), cd * sqrt(pd * (1 - pd) / 1000), vd)
    print(f"  {d:>2} {rms[d][1]:.4f} {rms[d][0]:.4f}  (ratio {rms[d][0] / rms[d][1]:.3f}; relative to the volume {rms[d][1] / vd:.3f})")

V20 = exact(20)
K20 = darts(20, N)
print(f"what breaks, the right answer is {V:.4f} +/- {se:.4f}")
print(f"  20-D ball: true {V20:.6f}, fraction of cube {V20 / 2 ** 20:.10f}; {N} darts hit {K20}, estimate {2 ** 20 * K20 / N:.4f}")
print(f"  darts for one expected hit in 20-D: {2 ** 20 / V20:.0f}")
print(f"  grid of 1,048,576 points (4 per axis): {grid[4]:.4f}, its 1024 inside points all sit at distance {sqrt(D) / 4:.4f},"
      f" the next shell at {sqrt((9 + D - 1) / 16):.4f} is all outside")
print(f"  forgetting the cube's volume: {K / N:.6f}")
print(f"  error bar s / N instead of s / root N: +/- {s / N:.6f}, {sqrt(N):.0f} times too narrow")
print(f"try: 400000 darts, standard error {sigma / sqrt(4 * N):.4f}; 10,000,000 darts {sigma / sqrt(100 * N):.4f}")

assert abs(sliced(D) - V) < 1e-9                       # slicing agrees with the closed form
assert abs(est - V) < 3 * sigma / sqrt(N)               # darts land within 3 standard errors
assert grid_walk(3, D, 9) == 1 + 20 + 180               # 0, 1 or 2 coordinates off-centre fit
assert all(abs(rms[d][0] / rms[d][1] - 1) < 0.2 for d in rms)   # sigma / root N in every dimension
assert abs(rate - 0.2) < 0.01                           # grid error falls like N^(-2/d)
assert abs(grid[3] - V) > 4 * dart_se_3                 # the grid misses by more than 4 dart errors
assert K20 == 0
print("ALL CHECKS PASS")
