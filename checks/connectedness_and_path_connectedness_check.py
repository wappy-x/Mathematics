# Connected and path-connected -- the check behind the card.  Standard library
# only.  Part 1 cuts the circle and the line into finitely many pieces (open
# arcs and cut points) and splits what is left into components two independent
# ways; every subset is tested, so those counts are proved for the finite
# models.  Part 2 halves [0, 1] onto the seam of a split that fails.  Part 3
# measures the topologist's sine curve; it illustrates the proofs on the card.
from fractions import Fraction as F
import math

def minimal(p, m):                         # smallest open set round point p
    return {p} if p % 2 == 0 else {(p - 1) % m, p, (p + 1) % m}

def is_open(s, y, m):                      # open in the subspace y
    return all(minimal(p, m) & y <= s for p in s)

def subsets(y):
    pts = sorted(y)
    return [frozenset(p for i, p in enumerate(pts) if b >> i & 1) for b in range(1 << len(pts))]

def connected(y, m):                       # no split into two non-empty open pieces
    return not any(s and s != y and is_open(s, y, m) and is_open(y - s, y, m) for s in subsets(y))

def pieces_by_splits(y, m):                # road 1: union of every connected set round p
    good = [s for s in subsets(y) if s and connected(s, m)]
    return sorted({frozenset().union(*[s for s in good if p in s]) for p in y}, key=min)

def pieces_by_joins(y, m):                 # road 2: join each point to its smallest open set
    boss = {p: p for p in y}
    def find(p):
        while boss[p] != p:
            p = boss[p]
        return p
    for p in sorted(y):
        for q in sorted(minimal(p, m) & y):
            boss[find(q)] = find(p)
    return sorted({frozenset(q for q in y if find(q) == find(p)) for p in y}, key=min)

print("Part 1: the circle and the line cut into open arcs (even) and cut points (odd)")
n = 4
circle, line = 2 * n, 2 * n + 1            # the line's two end pieces are open rays
whole = frozenset(range(circle))
clopen = [s for s in subsets(whole) if is_open(s, whole, circle) and is_open(whole - s, whole, circle)]
print(f"circle of {circle} points: open-and-closed subsets {len(clopen)} of {2 ** circle}: connected {'yes' if len(clopen) == 2 else 'no'}")
counts = []
for k in range(n + 1):
    y = whole - {2 * j + 1 for j in range(k)}
    a, b = pieces_by_splits(y, circle), pieces_by_joins(y, circle)
    assert a == b                                                        # two roads agree
    counts.append(len(a))
    print(f"circle minus {k} cut points: pieces {len(a)}, sizes {[len(c) for c in a]}")
line_counts = []
for k in range(3):
    y = frozenset(range(line)) - {2 * j + 1 for j in range(k)}
    a, b = pieces_by_splits(y, line), pieces_by_joins(y, line)
    assert a == b
    line_counts.append(len(a))
    print(f"line minus {k} cut points: pieces {len(a)}, sizes {[len(c) for c in a]}")
print(f"one cut point out: circle pieces {counts[1]}, line pieces {line_counts[1]}: not homeomorphic")
assert len(clopen) == 2 and counts == [1, 1, 2, 3, 4] and line_counts == [1, 2, 3]

print("Part 2: try to split [0, 1] at U = {t : 2t^2 < 1}, V = {t : 2t^2 >= 1}")
a, i = 0, 0                                # the bracket is a/2^i to (a+1)/2^i
while i < 30:
    a, i = (2 * a + 1, i + 1) if 2 * (2 * a + 1) ** 2 < 4 ** (i + 1) else (2 * a, i + 1)
    if i in (10, 20, 30):
        print(f"after {i} halvings: {a}/2^{i} to {a + 1}/2^{i}"
              f" = 0.{a * 10 ** 12 // 2 ** i:012d} to 0.{(a + 1) * 10 ** 12 // 2 ** i:012d}")
assert 2 * a * a < 4 ** i <= 2 * (a + 1) ** 2                            # seam inside
seam = math.sqrt(0.5)
assert a / 2 ** i < seam < (a + 1) / 2 ** i                             # bracket meets root
print(f"the seam: 1/root 2 = {seam:.12f}; in V, and every window round it meets U")
none = all(2 * p * p != q * q for q in range(1, 1001) for p in range(q + 1))
print(f"no fraction p/q in [0, 1] with q up to 1000 sits on the seam: {'yes' if none else 'no'}")
print("so the fractions in [0, 1] do split: U and V are both open there")
assert none

print("Part 3: the topologist's sine curve, y = sin(1/x) for 0 < x <= 1, plus x = 0")
PI = math.pi
print(f"start of the graph: (1, {math.sin(1.0):.9f})")
for d in (0.1, 0.01, 0.001):
    kp, km = 0, 0
    while 1 / (PI / 2 + 2 * PI * kp) >= d:
        kp += 1
    while 1 / (3 * PI / 2 + 2 * PI * km) >= d:
        km += 1
    xp, xm = 1 / (PI / 2 + 2 * PI * kp), 1 / (3 * PI / 2 + 2 * PI * km)
    yp, ym = math.sin(1 / xp), math.sin(1 / xm)
    print(f"x below {d}: peak k = {kp} at x = {xp:.9f}, y = {yp:.9f}; trough k = {km} at x = {xm:.9f}, y = {ym:.9f}")
    hi = max(math.sin(1 / d + j / (d * 10000)) for j in range(10001))
    lo = min(math.sin(1 / d + j / (d * 10000)) for j in range(10001))
    damp = max(abs(math.sin(u) / u) for u in (1 / d + j / (d * 10000) for j in range(10001)))
    print(f"  scan of 10001 points, x from {d / 2} to {d}: highest y {hi:.6f}, lowest y {lo:.6f};"
          f" damped x sin(1/x) at most {damp:.6f}")
    step = 1 / (d * 10000)                                               # scan step in 1/x
    u_hi = max((1 / d + j / (d * 10000) for j in range(10001)), key=math.sin)   # where it peaks
    u_lo = min((1 / d + j / (d * 10000) for j in range(10001)), key=math.sin)
    k_hi, k_lo = round((u_hi - PI / 2) / (2 * PI)), round((u_lo - 3 * PI / 2) / (2 * PI))
    gap_hi, gap_lo = abs(u_hi - PI / 2 - 2 * PI * k_hi), abs(u_lo - 3 * PI / 2 - 2 * PI * k_lo)
    print(f"  scan's highest point x = {1 / u_hi:.9f}: formula peak k = {k_hi}; lowest x = {1 / u_lo:.9f}:"
          f" formula trough k = {k_lo}; each within one scan step: {'yes' if max(gap_hi, gap_lo) <= step else 'no'}")
    assert xp < d and xm < d and yp > 0.999999 and ym < -0.999999       # formula road
    assert hi > 0.998 and lo < -0.998 and damp <= d                       # scan road
    assert gap_hi <= step and gap_lo <= step                              # the two roads meet
for k in (1, 10, 100, 1000):
    xk = 1 / (PI / 6 + 2 * PI * k)
    print(f"towards (0, 0.5): k = {k}, x = {xk:.9f}, y = {math.sin(1 / xk):.9f}, distance {xk:.9f}")
    assert abs(math.sin(1 / xk) - 0.5) < 1e-9
print("components of the curve: 1; path components: 2 (the graph, and the segment)")
print("figure, scale 400 per unit of x, 110 per unit of y; graph from (1, 0.841470985) drawn to x = 0.0125; segment (0, -1) to (0, 1);"
      f" peaks x = {2 / PI:.9f}, {2 / (5 * PI):.9f}; trough x = {2 / (3 * PI):.9f}")
print("ALL CHECKS PASS")
