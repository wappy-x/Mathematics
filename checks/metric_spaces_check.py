# Metric space -- the check behind the card.  Nothing is imported.
# A corner of the city grid is (east, north), counted in blocks from home.
# Every candidate returns the SQUARE of its distance as a whole number, so a
# root is never rounded: sqrt(A) <= sqrt(B) + sqrt(C) is tested exactly.
GRID = [(e, n) for e in range(6) for n in range(6)]      # 36 corners, 6 by 6
HOME, CAFE = (0, 0), (3, 4)
ANA, BEN = 7, 3                     # walking blocks from the park, all we know

def walk(p, q):                     # east-west blocks plus north-south blocks
    return abs(p[0] - q[0]) + abs(p[1] - q[1])
def line2(p, q):                    # straight line, squared (Pythagoras)
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2
def isqrt(s):                       # whole-number square root, by counting up
    r = 0
    while (r + 1) * (r + 1) <= s:
        r += 1
    return r
def show(s):                        # print a distance from its square
    r = isqrt(s)
    return str(r) if r * r == s else f"sqrt({s})"
def le_root(a, b, c):               # sqrt(a) <= sqrt(b) + sqrt(c), exactly
    t = a - b - c
    return t <= 0 or t * t <= 4 * b * c
def eq_root(a, b, c):               # sqrt(a) == sqrt(b) + sqrt(c), exactly
    t = a - b - c
    return t >= 0 and t * t == 4 * b * c

def rules(points, d2):              # every pair and every triple, in order
    r1 = next(((x, y) for x in points for y in points
               if (d2(x, y) == 0) != (x == y)), None)
    r2 = next(((x, y) for x in points for y in points
               if d2(x, y) != d2(y, x)), None)
    r3 = next(((x, y, z) for x in points for z in points for y in points
               if not le_root(d2(x, z), d2(x, y), d2(y, z))), None)
    return r1, r2, r3

LOOP = ["A", "B", "C", "D"]         # one block, four one-way streets, clockwise
def drive2(p, q):
    return ((LOOP.index(q) - LOOP.index(p)) % 4) ** 2
CANDIDATES = [
    ("walking distance", GRID, lambda p, q: walk(p, q) ** 2),
    ("straight line", GRID, line2),
    ("straight line squared", GRID, lambda p, q: line2(p, q) ** 2),
    ("east-west blocks only", GRID, lambda p, q: (p[0] - q[0]) ** 2),
    ("one-way driving", LOOP, drive2),
    ("try: root of walking", GRID, walk),
    ("try: flat fare, cap 3", GRID, lambda p, q: min(walk(p, q), 3) ** 2),
]

print(f"home {HOME} to cafe {CAFE}: walk {walk(HOME, CAFE)} blocks, "
      f"straight line {show(line2(HOME, CAFE))} blocks; at 100 m a block, "
      f"{100 * walk(HOME, CAFE)} m against {100 * isqrt(line2(HOME, CAFE))} m")
routes = {}                          # road 1: count routes corner by corner
for e in range(4):
    for n in range(5):
        routes[e, n] = 1 if e == 0 or n == 0 else routes[e - 1, n] + routes[e, n - 1]
fact = lambda k: 1 if k == 0 else k * fact(k - 1)
print(f"shortest walking routes: {routes[3, 4]} counted, "
      f"{fact(7) // (fact(3) * fact(4))} by 7!/(3!4!)")
free_w = sum(walk(HOME, y) + walk(y, CAFE) == walk(HOME, CAFE) for y in GRID)
free_l = sum(eq_root(line2(HOME, CAFE), line2(HOME, y), line2(y, CAFE)) for y in GRID)
print(f"corners on the way at no extra cost: walk {free_w}, straight line {free_l}")

dist = {}                            # road 2: walking distance by breadth-first search
for s in GRID:
    seen, frontier, k = {s: 0}, [s], 0
    while frontier:
        k += 1
        nxt = []
        for (e, n) in frontier:
            for q in ((e + 1, n), (e - 1, n), (e, n + 1), (e, n - 1)):
                if q in GRID and q not in seen:
                    seen[q] = k
                    nxt.append(q)
        frontier = nxt
    for q in GRID:
        dist[s, q] = seen[q]
same = all(dist[p, q] == walk(p, q) for p in GRID for q in GRID)
print(f"search on the street graph equals the block formula on all "
      f"{len(GRID) ** 2} pairs of the {len(GRID)} corners: {'yes' if same else 'no'}")

for name, pts, d2 in CANDIDATES:
    r1, r2, r3 = rules(pts, d2)
    verdict = "a metric" if (r1, r2, r3) == (None, None, None) else "NOT a metric"
    print(f"{name}: {len(pts) ** 3} triples, {verdict}")
    if r1:
        print(f"  rule 1 fails: {r1[0]} and {r1[1]} are {show(d2(*r1))} apart")
    if r2:
        print(f"  rule 2 fails: {r2[0]} to {r2[1]} is {show(d2(*r2))}, back is "
              f"{show(d2(r2[1], r2[0]))}")
    if r3:
        x, y, z = r3
        print(f"  rule 3 fails: {x} to {z} is {show(d2(x, z))}, via {y} is "
              f"{show(d2(x, y))} + {show(d2(y, z))}")

dr = lambda p, q: isqrt(drive2(p, q))  # one-way loop: does the lower bound survive?
lb = next((x, y, z) for x in LOOP for y in LOOP for z in LOOP
          if abs(dr(x, y) - dr(y, z)) > dr(x, z))
print(f"one-way lower bound fails: {lb[0]} to {lb[1]} is {dr(*lb[:2])}, {lb[1]} to "
      f"{lb[2]} is {dr(*lb[1:])}, so {lb[0]} to {lb[2]} is at least "
      f"{abs(dr(*lb[:2]) - dr(*lb[1:]))}, yet it is {dr(lb[0], lb[2])}")

def gaps(a, b):                     # brute force: every place the two could be
    box = [(e, n) for e in range(-10, 11) for n in range(-10, 11)]
    at_a = [p for p in box if walk(p, (0, 0)) == a]
    at_b = [p for p in box if walk(p, (0, 0)) == b]
    g = [walk(p, q) for p in at_a for q in at_b]
    return len(at_a), len(at_b), min(g), max(g)
na, nb, lo, hi = gaps(ANA, BEN)
print(f"Ana {ANA}, Ben {BEN} blocks from the park: bound {abs(ANA - BEN)} to {ANA + BEN}"
      f" blocks, {100 * abs(ANA - BEN)} m to {100 * (ANA + BEN)} m")
print(f"  brute force over {na} x {nb} = {na * nb} placings: {lo} to {hi}")
_, _, tlo, thi = gaps(ANA, 7)
print(f"try: Ben also 7 out: bound {abs(ANA - 7)} to {ANA + 7}, brute force {tlo} to {thi}")
print(f"wrong: bound without the bars, {BEN} - {ANA} = {BEN - ANA}")
print(f"wrong: the sum read as the answer, {ANA + BEN}; the truth can be {lo}")
print("figure, 1 block = 60 units: home (60, 360), turn (240, 360), cafe (240, 120)")

assert routes[3, 4] == fact(7) // (fact(3) * fact(4)) == 35  # two roads to 35
assert same and walk(HOME, CAFE) == 7 and line2(HOME, CAFE) == 25
assert (free_w, free_l) == (20, 2)
assert [rules(p, d) == (None, None, None) for _, p, d in CANDIDATES] == \
       [True, True, False, False, False, True, True]
assert rules(GRID, CANDIDATES[2][2])[2] == ((0, 0), (0, 1), (0, 2))
assert lb == ("A", "B", "A") and (dr("A", "B"), dr("B", "A")) == (1, 3)
assert (lo, hi) == (abs(ANA - BEN), ANA + BEN) and (tlo, thi) == (0, 14)
print("ALL CHECKS PASS")
