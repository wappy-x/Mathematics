# Reflexive spaces -- the check behind the card.  Standard library only.
# A schedule x lists the MWh a battery moves each hour (+ sells, - buys); a
# price list y (pounds/MWh, illustrative) values it by the revenue sum y_k x_k.
# Every list here is cut to N hours: a truncation is finite-dimensional, so it
# is always reflexive.  The infinite claims rest on the proofs; the code shows
# the trends over N that never close.
from fractions import Fraction as Q
from itertools import product
import math

def rev(y, x):                                   # revenue: sum of y_k x_k
    return sum(a * b for a, b in zip(y, x))

def bump(n, N):                                  # e_n: 1 MWh sold in hour n
    return [1 if k == n else 0 for k in range(1, N + 1)]

# 1. Six-hour rehearsal: ||Jx|| = sup |revenue| over |y_k| <= 100, against 100 ||x||_1
x = [Q(-3, 10), Q(-2, 10), Q(0), Q(1, 10), Q(25, 100), Q(15, 100)]
day = [40, 35, 45, 70, 90, 60]
corners = [rev([100 * s for s in signs], x) for signs in product((-1, 1), repeat=6)]
norm1 = sum(abs(v) for v in x)
print("rehearsal, 6 hours: x =", ", ".join(f"{float(v):.2f}" for v in x), "MWh")
print(f"  ||x||_1 = {float(norm1):.2f} MWh; revenue at prices {", ".join(map(str, day))}: {float(rev(day, x)):.2f}")
print(f"  best |revenue| over 64 corner lists, |y_k| <= 100: {float(max(corners)):.2f}; 100 ||x||_1 = {float(100 * norm1):.2f}")

# 2. Bumps in l1: three price lists read the bump at hour n
print("l1 bumps e_n read by: flat 50 | 50 at hour 18 only | sup and 2-norm of the flat list")
flat_norm2 = []
for N in (168, 336, 672, 1344):
    flat, h18 = [50] * N, [50 if k == 18 else 0 for k in range(1, N + 1)]
    e = bump(N, N)
    s2 = math.sqrt(sum(v * v for v in flat))
    flat_norm2.append(s2)
    print(f"  N={N:4d} bump at hour {N:4d}: {rev(flat, e)} | {rev(h18, e)} | {max(flat)}, {s2:.2f}"
          f" (50 sqrt N = {50 * math.sqrt(N):.2f})")
days = [18 + 24 * (k - 1) for k in range(1, 8)]  # the 18:00 bump on days 1..7
alt = [50] * 168
for k, n in enumerate(days):
    alt[n - 1] = 60 if k % 2 == 0 else 40
read_alt = [rev(alt, bump(n, 168)) for n in days]
read_h18 = [rev([50 if k == 18 else 0 for k in range(1, 169)], bump(n, 168)) for n in days]
read_flat = [rev([50] * 168, bump(n, 168)) for n in days]
print("  18:00 bumps, hours", ", ".join(map(str, days)))
print("  flat list reads", ", ".join(map(str, read_flat)))
print("  alternating list reads", ", ".join(map(str, read_alt)), "; hour-18 list reads", ", ".join(map(str, read_h18)))
settle = [rev([50 + 30 / k for k in range(1, N + 1)], bump(N, N)) for N in (18, 168, 1344)]
print("  settling list 50 + 30/k reads the bump at hours 18, 168, 1344 as",
      ", ".join(f"{v:.4f}" for v in settle), "-> long-run price 50")
gaps = [abs(a - b) for a, b in zip(read_alt, read_alt[1:])]
dist = {sum(abs(a - b) for a, b in zip(bump(m, 168), bump(n, 168))) for m in days for n in days if m != n}
print(f"  gaps between neighbours: {sorted(set(gaps))}; ||e_m - e_n||_1 for m != n: {sorted(dist)}")

# 3. The same bumps in l2: an allowed price list must be square-summable, so it dies away
ysq = lambda k: 50 / k
tail = [math.sqrt(sum(ysq(k) ** 2 for k in range(1, N + 1))) for N in (168, 1344)]
lim2 = 50 * math.pi / math.sqrt(6)
print(f"l2: price list 50/k has 2-norm {tail[0]:.4f} (N=168), {tail[1]:.4f} (N=1344), limit 50 pi/sqrt 6 = {lim2:.4f}")
reads2 = [rev([ysq(k) for k in range(1, N + 1)], bump(N, N)) for N in (18, 168, 1344)]
print("  it reads the bump at hours 18, 168, 1344 as", ", ".join(f"{v:.4f}" for v in reads2), "-> 0; ||e_n||_2 = 1")

# 4. The promise in l2: x_n = sin(n) e_1 + e_(n+1), bounded by sqrt 2.  Bisection keeps the
#    half of [-1, 1] holding more later terms and takes the next term there.
S = [math.sin(n) for n in range(1, 100001)]
def bisect(K):
    lo, hi, last, picks, boxes = -1.0, 1.0, 0, [], []
    for k in range(K):
        mid = (lo + hi) / 2
        low = sum(1 for n in range(last + 1, 100001) if lo <= S[n - 1] < mid)
        upp = sum(1 for n in range(last + 1, 100001) if mid <= S[n - 1] <= hi)
        lo, hi = (lo, mid) if low >= upp else (mid, hi)
        last = next(n for n in range(last + 1, 100001) if lo <= S[n - 1] <= hi)
        picks.append(last)
        boxes.append((lo, hi))
    return picks, boxes

picks, boxes = bisect(8)
lo, hi = boxes[-1]
c = (lo + hi) / 2
print("bisection picks n_k =", ", ".join(map(str, picks)))
print("  sin(n_k) =", ", ".join(f"{S[n - 1]:.4f}" for n in picks))
print(f"  last interval [{lo:.6f}, {hi:.6f}], width {hi - lo:.6f}; weak limit about {c:.4f} e_1")
count = sum(1 for v in S if lo <= v <= hi)
law = (math.asin(hi) - math.asin(lo)) / math.pi        # share of sin(n) in [lo, hi] as n runs on
print(f"  terms n <= 100000 inside it: {count}, share {count / 100000:.4f}; arcsine law {law:.4f}")
print(f"  ||x_(n_8)||_2 = {math.sqrt(1 + S[picks[-1] - 1] ** 2):.4f}; ||limit||_2 about {abs(c):.4f}")

# 5. Uniform convexity in the plane: delta_p(1) = least dent 1 - ||(u+v)/2||_p over unit
#    u, v at distance >= 1, by a 720-angle grid; Clarkson's formula 1 - (1 - 2^-p)^(1/p)
def norm(v, p):
    return max(abs(v[0]), abs(v[1])) if p == 0 else (abs(v[0]) ** p + abs(v[1]) ** p) ** (1 / p)

def dent(p, M=720):
    pts = []
    for i in range(M):
        t = 2 * math.pi * i / M
        r = norm((math.cos(t), math.sin(t)), p)
        pts.append((math.cos(t) / r, math.sin(t) / r))
    best = 1.0
    for u in pts:
        for v in pts:
            if norm((u[0] - v[0], u[1] - v[1]), p) >= 1 - 1e-9:
                best = min(best, 1 - norm(((u[0] + v[0]) / 2, (u[1] + v[1]) / 2), p))
    return max(best, 0.0)

dents = {p: dent(p) for p in (1, 2, 4, 0)}
clark = {p: 1 - (1 - 2.0 ** -p) ** (1 / p) for p in (2, 4)}
print("dent delta_p(1): p=1 {:.4f}, p=2 {:.4f} (Clarkson {:.4f}), p=4 {:.4f} (Clarkson {:.4f}), p=inf {:.4f}".format(
    dents[1], dents[2], clark[2], dents[4], clark[4], dents[0]))
mid = norm((0.5, 0.5), 1)
print(f"  l1 flat face: e_1, e_2 at distance 2, midpoint 1-norm {mid:.4f}; in 2-norm {norm((0.5, 0.5), 2):.4f}")

p12, b12 = bisect(12)
print(f"try: 12 halvings pick n_12 = {p12[-1]}, interval [{b12[-1][0]:.6f}, {b12[-1][1]:.6f}]")
print(f"try: dent p=1.5 {dent(1.5):.4f}; p=3 {dent(3):.4f} (Clarkson {1 - (1 - 2.0 ** -3) ** (1 / 3):.4f})")
root = [math.sqrt(sum(2500 / k for k in range(1, N + 1))) for N in (168, 1344)]
print(f"try: price list 50/sqrt k has 2-norm {root[0]:.2f} (N=168), {root[1]:.2f} (N=1344), still growing")

assert max(corners) == 100 * norm1 == 100               # ||Jx|| = ||x|| two roads
assert rev(day, x) == Q(195, 10)
assert read_alt == [60, 40, 60, 40, 60, 40, 60] and read_h18 == [50, 0, 0, 0, 0, 0, 0]
assert gaps == [20] * 6 and dist == {2}
assert all(abs(s - 50 * math.sqrt(N)) < 1e-9 for s, N in zip(flat_norm2, (168, 336, 672, 1344)))
assert tail[0] < tail[1] < lim2 and lim2 - tail[1] < 0.03     # partial sums climb to the limit
assert all(a <= S[n - 1] <= b for n, (a, b) in zip(picks, boxes)) and picks == sorted(set(picks))
assert all(a2 >= a1 and b2 <= b1 and b2 - a2 == (b1 - a1) / 2 for (a1, b1), (a2, b2) in zip(boxes, boxes[1:]))
assert p12[:8] == picks and abs(b12[-1][1] - b12[-1][0] - 2 / 2 ** 12) < 1e-12
assert abs((hi - lo) - 2 / 2 ** 8) < 1e-12 and read_flat == [50] * 7
assert count > 1000 and abs(count / 100000 - law) < 2e-3      # plenty left: the run can go on
assert all(abs(v - (50 + 30 / n)) < 1e-12 for v, n in zip(settle, (18, 168, 1344)))
assert abs(dents[2] - clark[2]) < 2e-3 and abs(dents[4] - clark[4]) < 2e-3
assert dents[1] < 1e-9 and dents[0] < 1e-9 and mid == 1.0
print("ALL CHECKS PASS")
