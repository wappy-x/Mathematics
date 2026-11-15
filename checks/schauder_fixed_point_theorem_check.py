# Schauder -- the check behind the card.  Standard library only.
# Part 1 is the finite rehearsal: a three-good market, where Brouwer applies.
# Parts 2-4 cut infinite-dimensional maps to N numbers, at several N.  Floats
# are added in explicit loops, so Python and Rust add in the same order.
import math

ALPHA = ((0.2, 0.5, 0.3), (0.6, 0.1, 0.3))  # spending shares: Ann, Ben
OWN = ((8.0, 1.0, 2.0), (2.0, 9.0, 4.0))    # units owned: grain, cloth, fuel
CAP = 100.0                                 # demand cap, so z stays finite at p_i = 0

def excess(p):                              # z_i(p): units wanted minus units owned
    z = [0.0, 0.0, 0.0]
    for a, w in zip(ALPHA, OWN):
        wealth = p[0] * w[0] + p[1] * w[1] + p[2] * w[2]
        for i in range(3):
            z[i] += min(a[i] * wealth / p[i], CAP) if p[i] > 0 else CAP
            z[i] -= w[i]
    return z

def price_map(p, s):                        # raise short goods by s per unit, rescale to 100
    up = [max(0.0, zi) for zi in excess(p)]
    total = 100.0 + s * (up[0] + up[1] + up[2])
    return [100.0 * (p[i] + s * up[i]) / total for i in range(3)]

def dist(u, v):                             # l2 distance, squares added left to right
    t = 0.0
    for a, b in zip(u, v):
        t += (a - b) * (a - b)
    return math.sqrt(t)

# 1a. Road one: clearing prices by hand.  Fuel: 7.2 p3 = 300.
#     Cloth: 8.6 p2 = 4.2 p1 + 1.4 p3 with p1 = 100 - p2 - p3.
p3 = 300 / 7.2
p2 = (4.2 * (100 - p3) + 1.4 * p3) / 12.8
star = [100 - p2 - p3, p2, p3]
z = excess(star)
print(f"clearing prices (GBP): grain {star[0]:.6f}, cloth {star[1]:.6f}, fuel {star[2]:.6f}")
print(f"wealth there: Ann {star[0] * 8 + star[1] + star[2] * 2:.6f}, Ben {star[0] * 2 + star[1] * 9 + star[2] * 4:.6f}; "
      f"largest excess demand {max(abs(zi) for zi in z):.6f}")
assert max(abs(zi) for zi in z) < 1e-9
for s in (1.0, 20.0):
    move = dist(price_map(star, s), star)
    print(f"s = {s:4.1f}: the price map moves the clearing prices by {move:.6f}")
    assert move < 1e-9

# 1b. Road two: search the price triangle on a 0.25 GBP grid for the point the map moves least.
best, where = 1e9, None
for a in range(401):
    for b in range(401 - a):
        p = [a * 0.25, b * 0.25, 100.0 - a * 0.25 - b * 0.25]
        d = dist(price_map(p, 20.0), p)
        if d < best:
            best, where = d, p
print(f"grid search, s = 20: least move {best:.6f} at ({where[0]:.2f}, {where[1]:.2f}, {where[2]:.2f})")
assert dist(where, star) < 0.25

# 1c. Repeating the map: settles at s = 1, never settles at s = 20.
for s in (1.0, 20.0):
    p, smallest = [100 / 3, 100 / 3, 100 / 3], 1e9
    for n in range(1, 2001):
        new = price_map(p, s)
        if n > 1000:
            smallest = min(smallest, dist(new, p))
        p = new
    print(f"s = {s:4.1f}: after 2000 rounds, distance to clearing {dist(p, star):.6f}; "
          f"smallest move in rounds 1001-2000 {smallest:.6f}")
assert smallest > 1.0
for d in (0.1, 0.01):
    nudged = [star[0] + d, star[1] - d, star[2]]
    ratio = dist(price_map(nudged, 20.0), star) / dist(nudged, star)
    print(f"s = 20, nudge {d:.2f}: the map stretches the gap to the fixed point by {ratio:.6f}")
    assert ratio > 1.0

# 1d. A buyer who wants 10 units of fuel below 50 GBP and none at or above it; 5 for sale.
moves = [2 * ((10 if k * 0.01 < 50 else 0) - 5) for k in range(10001)]  # fuel prices 0 to 100 GBP
print(f"jumping demand, fuel prices 0-100 GBP moved by 2 GBP per unit short: least move {min(map(abs, moves)):.6f} GBP")
assert min(map(abs, moves)) == 2 * min(10 - 5, 5 - 0) and all(0 <= k * 0.01 + m <= 100 for k, m in enumerate(moves))

# 2. The tank: h' = q - k sqrt(h), h(0) = 0.  q = 0.01 m/s, k = 0.01 m^0.5/s, window 100 s.
Q, K, TAU = 0.01, 0.01, 100.0

def time_to(u):                             # closed form: seconds to reach depth u^2
    return (2 / K) * (-u - (Q / K) * math.log(1 - K * u / Q))

def depth(t):                               # road one: invert the closed form by halving
    lo, hi = 0.0, Q / K
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if time_to(mid) < t else (lo, mid)
    return lo * lo

print(f"tank closed form: depth at 25 s {depth(25):.6f} m, 50 s {depth(50):.6f} m, "
      f"100 s {depth(100):.6f} m; level it tends to {(Q / K) * (Q / K):.6f} m")
print(f"self-map test: inflow alone over the window, q * tau = {Q * TAU:.6f} m, cap 1 m")
for d in (1e-2, 1e-4, 1e-6):                # T(d) - T(0) = -k sqrt(d) t, largest at t = tau
    print(f"start gap {d:.6f} m: gap after the integral map {K * math.sqrt(d) * TAU:.6f} m, "
          f"ratio {K * math.sqrt(d) * TAU / d:.1f}")
errs = []
for n in (10, 100, 1000, 10000):           # road two: Euler polygons, the Peano construction
    h, dt = 0.0, TAU / n
    for _ in range(n):
        h += dt * (Q - K * math.sqrt(h))
    errs.append(abs(h - depth(TAU)))
    print(f"N = {n:5d} steps: depth at 100 s {h:.6f} m, error {errs[-1]:.6f} m, "
          f"log10 N {math.log10(n):.0f}, log10 error {math.log10(errs[-1]):.3f}")
assert errs[-1] < 1e-4 and 8 < errs[0] / errs[1] < 12 and 8 < errs[2] / errs[3] < 12

# 3. The tank run backwards from empty: y' = k sqrt(y), y(0) = 0.  Two fixed points.
n, ds = 10000, TAU / 10000
y = [(K * i * ds / 2) * (K * i * ds / 2) for i in range(n + 1)]
acc, worst = 0.0, 0.0                       # apply the integral map by the trapezoid rule
for i in range(n):
    acc += ds * K * (math.sqrt(y[i]) + math.sqrt(y[i + 1])) / 2
    worst = max(worst, abs(acc - y[i + 1]))
print(f"backwards tank: h = 0 and h = (k t / 2)^2 both solve; trapezoid residual {worst:.6f} m; "
      f"gap at 100 s {y[n]:.6f} m")
assert worst < 1e-9 and abs(y[n] - 0.25) < 1e-12

# 4. Kakutani's map on the l2 ball, cut to N entries: (sqrt(1 - |x|^2), x_1, ..., x_{N-1}).
def kak(x):
    r = dist(x, [0.0] * len(x))
    return [math.sqrt(max(0.0, 1 - r * r))] + x[:-1]

for n in (10, 100, 1000):
    lo, hi = 0.0, 1.0                       # road one: halve on c = sqrt(1 - N c^2)
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if mid < math.sqrt(max(0.0, 1 - n * mid * mid)) else (lo, mid)
    x = [lo] * n
    res = dist(kak(x), x)                   # the cut map leaves x in place
    true_move = dist(kak(x + [0.0]), x + [0.0])  # the next entry: the full map moves it
    far = 1 / math.sqrt(10 * n + 1)         # fixed point of the 10N cut, road two: closed form
    gap = math.sqrt(n * (lo - far) * (lo - far) + 9 * n * far * far)
    print(f"N = {n:4d}: c = {lo:.6f} (1/sqrt(N+1) = {1 / math.sqrt(n + 1):.6f}), size "
          f"{math.sqrt(n) * lo:.6f}, residual {res:.6f}, full map moves it {true_move:.6f}, "
          f"gap to the N = {10 * n} point {gap:.6f}")
    assert abs(lo - 1 / math.sqrt(n + 1)) < 1e-12 and res < 1e-9 and gap > 1.0
    assert abs(true_move - 1 / math.sqrt(n + 1)) < 1e-12
print("ALL CHECKS PASS")
