# Product measure -- the check behind the card.  Standard library only:
# fractions for exact sums, math.sqrt for square roots.  A dart lands
# uniformly on a 1 m by 1 m board; the disc of radius 0.5 m centred at
# (0.5, 0.5) should have chance pi/4.  Roads: vertical section lengths
# integrated in x; horizontal sections found by bisection and integrated
# in y; inner and outer squares of a grid; polar coordinates with the
# Jacobian r; SplitMix64 darts; a six-cell board listed in full.
from fractions import Fraction as Fr
from math import sqrt

def atan_inv(k):                             # arctan(1/k) by its series
    s, t, n, sign = 0.0, 1.0 / k, 1, 1
    while t > 1e-18:
        s += sign * t / n
        t, n, sign = t / (k * k), n + 2, -sign
    return s

PI = 16 * atan_inv(5) - 4 * atan_inv(239)    # Machin's formula, no math.pi
AREA = PI / 4

def inside(x, y):
    return (x - 0.5) ** 2 + (y - 0.5) ** 2 <= 0.25

def sec_len(x):                              # the vertical section at x
    return 2 * sqrt(max(0.0, 0.25 - (x - 0.5) ** 2))

def edge(y, lo, hi, want_in_at_hi):          # bisection for a section's end
    for _ in range(60):
        mid = (lo + hi) / 2
        if inside(mid, y) == want_in_at_hi: hi = mid
        else: lo = mid
    return (lo + hi) / 2

def vertical(n):                             # sum of section length x slice width
    tot = 0.0
    for i in range(n):
        tot += sec_len((i + 0.5) / n)
    return tot / n

def horizontal(n):                           # never uses the square-root formula
    tot = 0.0
    for j in range(n):
        y = (j + 0.5) / n
        tot += edge(y, 0.5, 1.0, False) - edge(y, 0.0, 0.5, True)
    return tot / n

def grid(n):                                 # squares of side 1/n, scaled by 2n
    inner = outer = 0
    for i in range(n):
        far_x = max(abs(2 * i - n), abs(2 * i + 2 - n))
        near_x = 0 if 2 * i <= n <= 2 * i + 2 else min(abs(2 * i - n), abs(2 * i + 2 - n))
        for j in range(n):
            far_y = max(abs(2 * j - n), abs(2 * j + 2 - n))
            near_y = 0 if 2 * j <= n <= 2 * j + 2 else min(abs(2 * j - n), abs(2 * j + 2 - n))
            inner += far_x ** 2 + far_y ** 2 <= n * n
            outer += near_x ** 2 + near_y ** 2 < n * n
    return inner / (n * n), outer / (n * n)

MASK = (1 << 64) - 1
def splitmix(seed):                          # SplitMix64, uniform in [0, 1)
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & MASK
        z = s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

print(f"pi by Machin's formula: {PI:.9f}; the disc's area pi/4 = {AREA:.6f}, to four places {AREA:.4f}")
print("sections at x = 0.1, 0.2, 0.5: " + ", ".join(f"{sec_len(x):.4f}" for x in (0.1, 0.2, 0.5)))
print("chart, x: " + ", ".join(f"{i / 10:.1f}" for i in range(11)))
print("chart, section length: " + ", ".join(f"{sec_len(i / 10):.2f}" for i in range(11)))
V, H = {}, {}
for n in (10, 100, 1000, 10000):
    V[n], H[n] = vertical(n), horizontal(n)
    print(f"n = {n:5d}: vertical sections {V[n]:.9f}, horizontal by bisection {H[n]:.9f}, error {V[n] - AREA:.1e}")
G = {}
for n in (10, 100, 1000):
    G[n] = grid(n)
    print(f"grid {n:4d} x {n:<4d}: inner squares {G[n][0]:.6f} <= area <= touching squares {G[n][1]:.6f}")
polar = 0.0                                  # r from 0 to 0.5, theta from 0 to 2 pi
for k in range(1000):
    polar += (k + 0.5) * 0.0005 * 0.0005     # r times dr, midpoint rule
polar *= 2 * PI
print(f"polar, integral of r dr dtheta: {polar:.6f}; without the Jacobian r: {0.5 * 2 * PI:.6f}")
rng, N, hits = splitmix(2026), 200000, 0
for _ in range(N):
    hits += inside(next(rng), next(rng))
se = sqrt(AREA * (1 - AREA) / N)
print(f"darts: {hits} of {N} in the disc, fraction {hits / N:.4f}, standard error {se:.4f}")
# ---- a coarse board listed in full: x bands 0.2, 0.5, 0.3; y bands 0.4, 0.6 ----
mu, nu = [Fr(2, 10), Fr(5, 10), Fr(3, 10)], [Fr(4, 10), Fr(6, 10)]
cells = [(i, j) for i in range(3) for j in range(2)]
def order_x(E):                              # integrate nu(section at x) against mu
    return sum(mu[i] * sum(nu[j] for j in range(2) if (i, j) in E) for i in range(3))
def order_y(E):
    return sum(nu[j] * sum(mu[i] for i in range(3) if (i, j) in E) for j in range(2))
events = [frozenset(c for k, c in enumerate(cells) if m >> k & 1) for m in range(64)]
agree = sum(order_x(E) == order_y(E) == sum(mu[i] * nu[j] for i, j in E) for E in events)
rects = {frozenset((i, j) for i in range(3) if a >> i & 1 for j in range(2) if b >> j & 1)
         for a in range(8) for b in range(4)}
pi_sys = all(A & B in rects for A in rects for B in rects)
sig, full = set(rects), frozenset(cells)
while True:
    new = {full - A for A in sig} | {A | B for A in sig for B in sig}
    if new <= sig: break
    sig |= new
E = frozenset(c for c in cells if c[0] == 1 or c[1] == 1)       # middle band or high band
print(f"coarse board: {len(rects)} distinct rectangles, closed under overlap: {'yes' if pi_sys else 'no'}; they generate {len(sig)} sets")
print(f"all {len(events)} events: x-order, y-order and cell sums agree on {agree}")
print(f"middle band or high band: x-order {float(order_x(E)):.2f}, y-order {float(order_y(E)):.2f}")
print("  x-order pieces " + ", ".join(f"{float(mu[i] * sum(nu[j] for j in range(2) if (i, j) in E)):.2f}" for i in range(3))
      + "; y-order pieces " + ", ".join(f"{float(nu[j] * sum(mu[i] for i in range(3) if (i, j) in E)):.2f}" for j in range(2)))
# ---- what breaks ----
naive = 10 * V[10]                           # the lengths themselves, not times 1/n
print(f"section lengths added without the width 1/n: n = 10 gives {naive:.4f}, n = 100 gives {100 * V[100]:.4f}")
diag = [(t, t) for t in ((i + 0.5) / 1000 for i in range(1000))]   # the diagonal at 1000 points; counting on y is not sigma-finite
d1 = sum(sum(1 for u, v in diag if u == x) for x, _ in diag) / 1000   # count each vertical section, times width 1/1000
d2 = sum(max(u for u, v in diag if v == y) - min(u for u, v in diag if v == y) for _, y in diag)   # each horizontal section [y, y]: its length, counted once
print(f"diagonal at 1000 points, lambda x counting: vertical order {d1:.6f}, horizontal order {d2:.6f}")
qs = sorted({Fr(p, q) for q in range(1, 31) for p in range(q + 1)})
cover = sum(Fr(1, 100) / 2 ** k for k in range(1, len(qs) + 1))   # k-th strip 0.01 / 2^k wide
print(f"rational-x strip: {len(qs)} rationals with denominator <= 30, strips of total area {float(cover):.6f} = 0.01 x (1 - 2^-{len(qs)})")
print("figure, x = 80 + 200u, y = 220 - 200v: centre (180, 120), radius 100; "
      f"section at u = 0.2 from ({80 + 200 * 0.2:.0f}, {220 - 200 * (0.5 - sec_len(0.2) / 2):.0f}) "
      f"to ({80 + 200 * 0.2:.0f}, {220 - 200 * (0.5 + sec_len(0.2) / 2):.0f})")
assert abs(V[10000] - AREA) < 3e-7                            # sections against Machin's pi
assert all(abs(H[n] - V[n]) < 1e-9 for n in V)                # the other order; by symmetry it checks the ends
assert all(G[n][0] < AREA < G[n][1] for n in G) and G[1000][1] - G[1000][0] < 0.01
assert abs(hits / N - V[10000]) < 4 * se                      # darts against the sections
assert agree == 64 and pi_sys and len(sig) == 64              # finite board, every event
assert abs(polar - V[10000]) < 3e-7                           # the Jacobian road
print("ALL CHECKS PASS")
