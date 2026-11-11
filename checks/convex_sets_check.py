# Convex sets: the three-bean blends costing at most £9 a kilo.  Standard library only.
from fractions import Fraction as Fr
from itertools import combinations
PRICE = (6, 8, 14)                       # £ a kilo: Robusta, Brazil, Ethiopian
# Each wall reads a . x <= b, x being the shares (Robusta, Brazil, Ethiopian).
WALLS = [((-1, 0, 0), 0, "no Robusta"), ((0, -1, 0), 0, "no Brazil"),
         ((0, 0, -1), 0, "no Ethiopian"), (PRICE, 9, "cost 9")]
SUM = ((1, 1, 1), 1, "sum 1")            # the shares add to 1: a wall that must hold exactly
dot = lambda a, x: sum(u * v for u, v in zip(a, x))
show = lambda x: "(" + ", ".join(str(v) for v in x) + ")"
def solve(rows):                         # three walls held tight: elimination, exact fractions
    m = [[Fr(v) for v in a] + [Fr(b)] for a, b, _ in rows]
    for c in range(3):
        p = next((r for r in range(c, 3) if m[r][c] != 0), None)
        if p is None: return None        # the walls do not meet in a single point
        m[c], m[p] = m[p], m[c]
        for r in range(3):
            if r != c: m[r] = [u - m[r][c] / m[c][c] * v for u, v in zip(m[r], m[c])]
    return tuple(m[r][3] / m[r][r] for r in range(3))
def corners(walls, eqs, log=None):       # road one: every choice of three tight walls
    found = []
    for pick in combinations(walls, 3 - len(eqs)):
        x = solve(list(pick) + eqs)
        good = x is not None and all(dot(a, x) <= b for a, b, _ in walls)
        if log is not None:
            log.append(f"{' + '.join(w[2] for w in pick)}: " + ("no single point" if x is None else
                       f"{show(x)} cost {dot(PRICE, x)} -> " + ("corner" if good else "outside")))
        if good and x not in found: found.append(x)
    return found
def turn(a, b, c): return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
def hull(pts):                           # monotone chain on (Robusta, Brazil); anticlockwise
    pts, out = sorted(set(pts)), []
    for seq in (pts, pts[::-1]):
        h = []
        for p in seq:
            while len(h) >= 2 and turn(h[-2], h[-1], p) <= 0: h.pop()
            h.append(p)
        out += h[:-1]
    return out
area = lambda h: sum(turn((0, 0), h[i - 1], h[i]) for i in range(len(h))) / 2
log = []
C = corners(WALLS, [SUM], log)
print("road one, three walls tight at a time:")
for line in log: print("  " + line)
N = 24                                   # road two: every blend in 24ths, then its hull
grid = [(i, j, N - i - j) for i in range(N + 1) for j in range(N + 1 - i)]
good = [g for g in grid if dot(PRICE, g) <= 9 * N]
H = [(Fr(r, N), Fr(b, N), 1 - Fr(r + b, N)) for r, b in hull([g[:2] for g in good])]
print(f"road two: {len(good)} of {len(grid)} blends in 24ths pass; their hull has corners "
      + " ".join(show(h) for h in H))
pairs = [(x, y) for i, x in enumerate(good) for y in good[i + 1:]]
seg = [all(dot(PRICE, [(10 - k) * u + k * v for u, v in zip(x, y)]) <= 90 * N for k in range(1, 10)) for x, y in pairs]
print(f"segment test: {len(pairs)} pairs, 9 points on each, pairs staying inside: {sum(seg)}")
A = area([h[:2] for h in H])
M = 480
tri = [(i + 0.5, j + 0.5) for i in range(M) for j in range(M - i)]   # cell centres in the triangle
cells = sum(8 * r + 6 * b >= 5 * M for r, b in tri) / len(tri)
print(f"area of the passing set 1/2 - {Fr(1, 2) - A} = {A} of the triangle's 1/2: {float(2 * A):.1%}; "
      f"fine grid, {len(tri)} cell centres: {cells:.1%}")
blend = {"Dark": (Fr(50, 100), Fr(50, 100), Fr(0)), "Espresso": (Fr(60, 100), Fr(30, 100), Fr(10, 100)),
         "Bright": (Fr(50, 100), Fr(20, 100), Fr(30, 100)), "Breakfast": (Fr(20, 100), Fr(70, 100), Fr(10, 100)),
         "House": (Fr(40, 100), Fr(40, 100), Fr(20, 100))}
for k, x in blend.items(): print(f"{k}: shares {show(x)}, £{float(dot(PRICE, x)):.2f} a kilo")
name = {v[:2]: k for k, v in blend.items()}
H5 = hull([v[:2] for v in blend.values()])
print("hull of the five blends: " + " ".join(name[p] for p in H5) + f"; House inside: {'House' not in [name[p] for p in H5]}")
mix = [(a, b, 6 - a - b) for a in range(7) for b in range(7 - a)]
vals = [dot(PRICE, [(a * d + b * e + c * f) / 6 for d, e, f in zip(blend["Dark"], blend["Bright"], blend["Breakfast"])]) for a, b, c in mix]
print(f"{len(mix)} tip-togethers of Dark, Bright, Breakfast in sixths: £{float(min(vals)):.2f} to £{float(max(vals)):.2f}")
D, Bt, Bk, Ho = blend["Dark"], blend["Bright"], blend["Breakfast"], blend["House"]
w = solve([((D[0], Bt[0], Bk[0]), Ho[0], ""), ((D[1], Bt[1], Bk[1]), Ho[1], ""), ((1, 1, 1), 1, "")])
rebuilt = tuple(w[0] * d + w[1] * e + w[2] * f for d, e, f in zip(D, Bt, Bk))
print(f"House = {w[0]} Dark + {w[1]} Bright + {w[2]} Breakfast: shares {show(rebuilt)}, "
      f"cost {float(dot(PRICE, rebuilt)):.2f} = {float(w[0] * dot(PRICE, D) + w[1] * dot(PRICE, Bt) + w[2] * dot(PRICE, Bk)):.2f}")
rule = lambda x: all(s == 0 or s >= Fr(3, 10) for s in x)
p, q = (Fr(7, 10), Fr(3, 10), Fr(0)), (Fr(7, 10), Fr(0), Fr(3, 10))
mid = tuple((u + v) / 2 for u, v in zip(p, q))
print(f"30% rule: {show(p)} £{float(dot(PRICE, p)):.2f} {rule(p)}, {show(q)} £{float(dot(PRICE, q)):.2f} {rule(q)}, "
      f"midpoint {show(mid)} £{float(dot(PRICE, mid)):.2f} {rule(mid)}")
g30 = [g for g in good if rule([Fr(s, N) for s in g])]
bad = sum(not rule([Fr(u + v, 2 * N) for u, v in zip(x, y)]) for i, x in enumerate(g30) for y in g30[i + 1:])
print(f"30% rule on the grid: {len(g30)} blends pass both rules; pairs whose midpoint breaks the rule: {bad}")
free = corners(WALLS, [])
print("mistake, no sum-to-1 wall: corners " + " ".join(show(x) for x in free)
      + f"; cheapest point £{min(dot(PRICE, x) for x in free)}")
print(f"mistake, corners taken as the passing pure beans: hull of (1, 0, 0) and (0, 1, 0), area {area(hull([(1, 0), (0, 1)])):.1f}; "
      f"House has Ethiopian share {Ho[2]}, so it is left out")
STRONG = ((24, 12, 12), 18, "caffeine 1.8%")   # caffeine in tenths of a percent: 2.4, 1.2, 1.2
C2 = corners(WALLS + [STRONG], [SUM])
print(f"try: add caffeine at most 1.8%: {len(C2)} corners " + " ".join(show(x) for x in C2))
fig = lambda x: f"({float(95 + 200 * x[0]):.1f}, {float(230 - 200 * x[1]):.1f})"
print("figure, 1 share = 200: corners " + " ".join(fig(x) for x in C) + "; blends "
      + " ".join(k + " " + fig(x) for k, x in blend.items()))
assert sorted(C) == sorted(H)                              # walls against the grid's hull
assert all(seg) and len(C) == 4                            # no segment leaves the set
assert min(w) > 0 and rebuilt == Ho                        # House really is a mix of the three
assert abs(cells - float(2 * A)) < 0.005                   # area: shoelace against counting
assert rule(p) and rule(q) and not rule(mid) and bad > 0   # the 30% rule dents the set
print("ALL CHECKS PASS")
