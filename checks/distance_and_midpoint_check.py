# Distance and midpoint -- the check behind the card.  Nothing is imported.
# Van grid in km, depot at (0, 0), drops A (3, 4) and B (8, 1).  In space, a
# cable in metres from (1, 2, 0) to (4, 6, 12).  Roads: the formula, the square
# on the segment by corner coordinates, the depot's dot products, a search.

def root(x):                               # square root by Newton: average guess and x / guess
    r = max(x, 1.0)
    for _ in range(80):
        r = (r + x / r) / 2
    return r

def sq(a, b):                              # road one: square each change and add
    return sum((q - p) ** 2 for p, q in zip(a, b))

def dot(a, b):
    return sum(p * q for p, q in zip(a, b))

def shoelace(pts):                         # area of a polygon from its corners
    return abs(sum(x * v - y * u for (x, y), (u, v) in zip(pts, pts[1:] + pts[:1]))) / 2

def search_mid(a, b):                      # walk along the segment until equally far
    lo, hi = 0.0, 1.0
    for _ in range(100):
        t = (lo + hi) / 2
        p = [x + t * (y - x) for x, y in zip(a, b)]
        lo, hi = (t, hi) if sq(a, p) < sq(p, b) else (lo, t)
    return [round(x + t * (y - x), 9) + 0.0 for x, y in zip(a, b)]

for a, b in [((3, 4), (8, 1)), ((1, 2, 0), (4, 6, 12))]:
    ch = [q - p for p, q in zip(a, b)]
    s, d = sq(a, b), root(sq(a, b))
    m = [(p + q) / 2 for p, q in zip(a, b)]
    road2 = dot(a, a) + dot(b, b) - 2 * dot(a, b)
    am, mb = root(sq(a, m)), root(sq(m, b))
    print(f"{a} to {b}: changes {ch}, squares {[c * c for c in ch]}, sum {s}, distance {d:.10f}")
    print(f"  depot road: {dot(a, a)} + {dot(b, b)} - 2 x {dot(a, b)} = {road2}")
    print(f"  midpoint by averaging {m}; by searching the segment {search_mid(a, b)}")
    print(f"  halves {am:.10f} + {mb:.10f} = {am + mb:.10f}; 2M - A = {[2 * x - p for x, p in zip(m, a)]}")
    assert s == road2                                          # two roads to the square
    assert m == search_mid(a, b)                               # two roads to the midpoint
    assert abs(am - mb) < 1e-12 and abs(am + mb - root(road2)) < 1e-12
w = (3, 5)                                 # the change (5, -3) turned a quarter turn
tilt = [(3, 4), (8, 1), (8 + w[0], 1 + w[1]), (3 + w[0], 4 + w[1])]
print(f"square on AB, corners {tilt}: area by corners {shoelace(tilt):.0f}; box 8 x 8 - 4 x 7.5 = {64 - 30}")
assert shoelace(tilt) == sq((3, 4), (8, 1))                    # the square Pythagoras names
print(f"depot to A {root(25):.10f}, depot to B {root(65):.10f}; floor diagonal {root(9 + 16):.10f}; corner {(8, 1)[0], (3, 4)[1]}")
print(f"mistakes: add the legs 5 + 3 = {5 + 3}; stop before the root {5 * 5 + 3 * 3}; "
      f"halve the change ({(8 - 3) / 2}, {(1 - 4) / 2})")
print(f"try: shifted by (10, -7) to {(3 + 10, 4 - 7)} and {(8 + 10, 1 - 7)} distance {root(sq((13, -3), (18, -6))):.10f}; "
      f"B moved to (9, 12) gives {root(sq((3, 4), (9, 12))):.10f}")
k, ox, oy = 30, 40, 190                    # figure: 1 km = 30 units, y points down
px = lambda p: f"({ox + k * p[0]:.0f}, {oy - k * p[1]:.0f})"
print(f"figure, 1 km = {k}: depot {px((0, 0))} A {px((3, 4))} B {px((8, 1))} "
      f"M {px((5.5, 2.5))} corner {px((8, 4))}")
print(f"figure, marker {px((7 + 2 / 3, 4))} {px((7 + 2 / 3, 3 + 2 / 3))} {px((8, 3 + 2 / 3))}; axes to {px((10, 0))} {px((0, 5))}")
n = [z * 6 / root(150 ** 2 + 90 ** 2) for z in (-90, 150)]  # tick half-length 6
for c in [(167.5, 92.5), (242.5, 137.5)]:
    print(f"figure, tick ({c[0] + n[0]:.1f}, {c[1] + n[1]:.1f}) ({c[0] - n[0]:.1f}, {c[1] - n[1]:.1f})")
print("ALL CHECKS PASS")
