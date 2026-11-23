# Working on a problem -- the check behind the card.  Standard library only.
# The problem: u(n), the most pairs among n points in the plane at distance
# exactly 1.  The working file needs lower bounds (point sets, counted here in
# exact arithmetic), upper bounds (a counting argument, done two ways), and the
# literature's table, tested against both.  A point is (xa, xb, ya, yb):
# x = (xa + xb*sqrt3)/10 and y = (ya + yb*sqrt3)/10, so no rounding ever enters.
from itertools import combinations
from math import atan2, degrees, isqrt, sqrt

def is_unit(p, q):                      # squared distance exactly 1, in Z[sqrt3]/100
    a, b, c, d = (p[i] - q[i] for i in range(4))
    return a * a + 3 * b * b + c * c + 3 * d * d == 100 and a * b + c * d == 0

def pairs(pts):
    return [(i, j) for i, j in combinations(range(len(pts)), 2) if is_unit(pts[i], pts[j])]

def most_common_neighbours(pts):        # two unit circles meet in at most 2 points
    nb = [{j for j in range(len(pts)) if j != i and is_unit(pts[i], pts[j])} for i in range(len(pts))]
    return max(len(nb[i] & nb[j]) for i, j in combinations(range(len(pts)), 2))

def lattice(a, b):                      # a + b*omega, omega at 60 degrees
    return (10 * a + 5 * b, 0, 0, 5 * b)

# ---- lower bounds: point sets, counted exactly ----
grid = [(10 * i, 0, 10 * j, 0) for i in range(3) for j in range(3)]
patch = [lattice(a, b) for a in range(-2, 3) for b in range(-2, 3) if abs(a + b) <= 2]
adj = [sum(1 << j for j in range(len(patch)) if j != i and is_unit(patch[i], patch[j]))
       for i in range(len(patch))]
best = {}                               # best subset of the 19-point patch, by brute force
for n in range(2, 10):
    best[n] = max(sum(bin(adj[i] & sum(1 << j for j in s)).count("1") for i in s) // 2
                  for s in combinations(range(len(patch)), n))
harborth = {n: 3 * n - isqrt(12 * n - 3) - (0 if isqrt(12 * n - 3) ** 2 == 12 * n - 3 else 1)
            for n in range(2, 10)}      # floor(3n - sqrt(12n - 3)), in integers
tri = [(0, 0, 0, 0), (10, 0, 0, 0), (5, 0, 0, 5)]          # a unit triangle
turned = [(0, 0, 0, 0), (6, 0, 8, 0), (3, -4, 4, 3)]       # the same, turned by (3/5, 4/5)
mink = [tuple(x + y for x, y in zip(a, b)) for a in tri for b in turned]
cube = [tuple(sum(v[k] for v, bit in zip([(10, 0, 0, 0), (0, 0, 10, 0), (6, 0, 8, 0)], m) if bit)
              for k in range(4)) for m in [(i & 1, i >> 1 & 1, i >> 2 & 1) for i in range(8)]]

# ---- upper bound: each pair of points has at most 2 common neighbours ----
def bound_degrees(n):                   # largest e whose most even degrees pass the count
    e = 0
    while True:
        q, r = divmod(2 * (e + 1), n)
        if r * (q + 1) * q // 2 + (n - r) * q * (q - 1) // 2 > n * (n - 1) or e == n * (n - 1) // 2:
            return e
        e += 1

def bound_formula(n):                   # u <= n(1 + sqrt(8n - 7))/4, and never above n(n - 1)/2
    return min(int(n * (1 + sqrt(8 * n - 7)) / 4), n * (n - 1) // 2)

known = [0, 0, 1, 3, 5, 7, 9, 12, 14, 18, 20, 23, 27, 30, 33, 37, 41, 43, 46, 50, 54, 57]

def erdos_grid(side, m):                # pairs at squared distance m in a side x side grid
    vecs = [(dx, dy) for dx in range(0, side) for dy in range(-side + 1, side)
            if dx * dx + dy * dy == m and (dx > 0 or dy > 0)]
    return len(vecs), sum((side - abs(dx)) * (side - abs(dy)) for dx, dy in vecs)

def erdos_brute(side, m):
    pts = [(i, j) for i in range(side) for j in range(side)]
    return sum((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 == m for p, q in combinations(pts, 2))

print("statement: u(n) = most pairs at distance exactly 1 among n distinct points in the plane")
print(f"3 x 3 square grid: {len(grid)} points, {len(pairs(grid))} unit pairs")
print(f"triangular patch: {len(patch)} points; best n-point subsets by brute force:")
for n in range(2, 10):
    print(f"  n = {n}: lattice best {best[n]}, formula floor(3n - sqrt(12n - 3)) = {harborth[n]}, known u(n) = {known[n]}")
print(f"two triangles summed: {len(set(mink))} points, {len(pairs(mink))} unit pairs")
degs = [sum(is_unit(p, q) for q in mink if q != p) for p in mink]
print(f"  degrees {degs}; cherries {sum(d * (d - 1) // 2 for d in degs)} <= 2 x {9 * 8 // 2} = {9 * 8}; "
      f"second triangle turned {degrees(atan2(8, 6)):.2f} degrees")
print(f"cube shadow from (1,0), (0,1), (3/5,4/5): {len(set(cube))} points, {len(pairs(cube))} unit pairs, known u(8) = {known[8]}")
print(f"most common neighbours of a pair: grid {most_common_neighbours(grid)}, patch "
      f"{most_common_neighbours(patch)}, two triangles {most_common_neighbours(mink)}")
print("upper bound from common neighbours, against the literature (n <= 21):")
for n in range(2, 22):
    print(f"  n = {n}: by degrees {bound_degrees(n)}, by formula {bound_formula(n)}, known {known[n]}, gap {bound_degrees(n) - known[n]}")
print(f"cherry bound at n = 9: sqrt(65) = {sqrt(65):.3f}, 9 x {1 + sqrt(65):.3f} / 4 = {9 * (1 + sqrt(65)) / 4:.2f}")
ring = [(1, 7), (5, 5), (7, 1), (7, -1), (5, -5)]        # on x^2 + y^2 = 50: radius 1/sqrt2, scaled by 10
four = [(a, b, 0, 0) for a, b in ring] + [(0, 0, a, b) for a, b in ring]
def unit4(p, q):
    return sum((x - y) ** 2 for x, y in zip(p, q)) == 100
across = sum(unit4(p, q) for p in four[:5] for q in four[5:])
print(f"four dimensions, two circles of 5 points: {sum(unit4(p, q) for p, q in combinations(four, 2))} "
      f"unit pairs among 10 points, {across} across the circles; the plane allows u(10) = {known[10]}")
cross = next(n for n in range(2, 10 ** 6) if 1.94 * n ** (4 / 3) < n * (1 + sqrt(8 * n - 7)) / 4)
print(f"1.94 n^(4/3) at n = 21: {1.94 * 21 ** (4 / 3):.1f}; it first beats the counting bound at n = {cross}")
print("quoted, not computed: u(n) > n^1.014 for infinitely many n (preprint, 2026-05-20); checked write-up exponent 1 + 6.24e-38")
SIDE, SQUARES = 30, (1, 25, 65)           # Erdos's idea: a big grid and a well-chosen distance
for m in SQUARES:
    dirs, count = erdos_grid(SIDE, m)
    print(f"{SIDE} x {SIDE} grid, squared distance {m}: {2 * dirs} directions, {count} pairs (brute force {erdos_brute(SIDE, m)})")
print(f"same idea on the 3 x 3 grid, squared distance 65: {erdos_grid(3, 65)[1]} pairs")
wrong = [n for n in range(2, 10) if harborth[n] != known[n]]
print(f"lattice pattern guessed as u(n): first fails at n = {wrong[0]}, {harborth[wrong[0]]} against {known[wrong[0]]}")
print(f"counting bound read as u(n): first fails at n = {next(n for n in range(2, 22) if bound_degrees(n) != known[n])}")
f = [((p[0] + p[1] * sqrt(3)) / 10, (p[2] + p[3] * sqrt(3)) / 10) for p in mink]
print("figure," + ",".join(f"({x:.3f} {y:.3f})" for x, y in f))
assert all(best[n] == harborth[n] for n in range(2, 10))        # brute force against formula
assert len(set(mink)) == 9 and len(pairs(mink)) == known[9]   # construction meets the table
assert all(bound_degrees(n) == bound_formula(n) for n in range(2, 22))   # two roads to the bound
assert all(known[n] <= bound_degrees(n) for n in range(2, 22))  # literature passes the proved bound
assert all(best[n] <= known[n] for n in range(2, 10))           # constructions never beat the table
assert all(erdos_grid(SIDE, m)[1] == erdos_brute(SIDE, m) for m in SQUARES)
assert across == 25 and across > known[10]                      # 4D beats the plane's table
assert max(most_common_neighbours(s) for s in (grid, patch, mink, cube)) <= 2
print("ALL CHECKS PASS")
