# Pick's theorem -- the check behind the card.  Nothing is imported.  A polygon
# with corners on grid points has area I + B/2 - 1: I grid points inside, B on
# the edges.  Roads: Pick from points counted one by one, against the shoelace
# sum; the gcd edge count against a point-by-point count; every grid triangle.
HOUSE = [(0, 0), (4, 0), (4, 3), (2, 5), (0, 3)]
SURVEY = [(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)]
RECT, ROOF = [(0, 0), (4, 0), (4, 3), (0, 3)], [(0, 3), (4, 3), (2, 5)]
DOUBLE = [(2 * x, 2 * y) for x, y in HOUSE]

def gcd(a, b):                               # Euclid's algorithm
    return abs(a) if b == 0 else gcd(b, a % b)
def edges(P):
    return [(P[i], P[(i + 1) % len(P)]) for i in range(len(P))]
def cross(a, b, p):                          # turn test: which side of a->b is p
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
def twice_area(P):                           # road one: the shoelace sum
    return abs(sum(a[0] * b[1] - a[1] * b[0] for a, b in edges(P)))
def gcd_b(P):                                # B from one gcd per edge
    return sum(gcd(b[0] - a[0], b[1] - a[1]) for a, b in edges(P))

def count(P):                                # road two: visit every grid point
    i = b = 0
    for x in range(min(p[0] for p in P), max(p[0] for p in P) + 1):
        for y in range(min(p[1] for p in P), max(p[1] for p in P) + 1):
            if any(cross(a, c, (x, y)) == 0 and min(a[0], c[0]) <= x <= max(a[0], c[0])
                   and min(a[1], c[1]) <= y <= max(a[1], c[1]) for a, c in edges(P)):
                b += 1                       # on an edge
            elif sum((a[1] > y) != (c[1] > y) and cross(a, c, (x, y)) * (c[1] - a[1]) > 0
                     for a, c in edges(P)) % 2:
                i += 1                       # ray casting: odd count means inside
    return i, b, (2 * i + b - 2) / 2         # Pick's area

def vol6(a, b, c, d):                        # six times a tetrahedron's signed volume
    u, v, w = [[q[k] - a[k] for k in range(3)] for q in (b, c, d)]
    return u[0] * (v[1] * w[2] - v[2] * w[1]) - u[1] * (v[0] * w[2] - v[2] * w[0]) + u[2] * (v[0] * w[1] - v[1] * w[0])
def reeve(r):                                # grid points in tetrahedron 0, x, y, (1, 1, r)
    V, pts = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, r)], [(x, y, z) for x in (0, 1) for y in (0, 1) for z in range(r + 1)]
    inside = [p for p in pts if all(vol6(*[p if j == k else V[j] for j in range(4)]) * vol6(*V) >= 0 for k in range(4))]
    return len(inside), abs(vol6(*V))

(I, B, A), S, (ir, br, ar), (io, bo, ao) = count(HOUSE), twice_area(HOUSE), count(RECT), count(ROOF)
print("corners:", ", ".join(f"({x}, {y})" for x, y in HOUSE))
print("edge steps and gcd:", ", ".join(f"({b[0]-a[0]}, {b[1]-a[1]}) {gcd(b[0]-a[0], b[1]-a[1])}" for a, b in edges(HOUSE)), "; B =", gcd_b(HOUSE))
print(f"counted one by one: {B} on the edges, {I} inside; Pick {I} + {B}/2 - 1 = {A:g}; shoelace {S}/2 = {S / 2:g}")
print(f"at 10 m a grid step: {A:g} x 100 = {A * 100:,.0f} m^2; inside from corners alone: {S / 2:g} - {gcd_b(HOUSE)}/2 + 1 = {(S - gcd_b(HOUSE) + 2) // 2}")
print(f"cut at y = 3: box I {ir}, B {br}, Pick {ar:g}; roof I {io}, B {bo}, Pick {ao:g}; roof = 8 - 2 - 2 = {8 - 2 - 2}; cut holds {gcd(4, 0) + 1} points, {I - ir - io} move inside")
grid = [(x, y) for x in range(5) for y in range(5)]
tris = [[p, q, r] for n, p in enumerate(grid) for m, q in enumerate(grid[n + 1:], n + 1) for r in grid[m + 1:] if cross(p, q, r)]
agree = sum(2 * count(T)[2] == twice_area(T) and count(T)[1] == gcd_b(T) for T in tris)
print(f"every triangle with corners in a 5 x 5 grid: {len(tris)} checked, {agree} agree")
(si, sb, sa), (di, db, da) = count(SURVEY), count(DOUBLE)
print(f"survey field A to F: B {sb}, I {si}, Pick {sa:g}, shoelace {twice_area(SURVEY) / 2:g}; house doubled: B {db}, I {di}, area {da:g}")
R = [reeve(r) for r in (1, 2, 3)]
print("Reeve tetrahedra r = 1, 2, 3: grid points", ", ".join(str(p) for p, v in R), "; six times volume", ", ".join(str(v) for p, v in R))
print(f"what breaks: -1 left out {I + B / 2:g}; corners only as B {I + 5 / 2 - 1:g}; gcd + 1 per edge {I + (B + 5) / 2 - 1:g}")
print("figure, 1 step = 60 svg units:", ", ".join(f"({70 + 60 * x}, {340 - 60 * y})" for x, y in HOUSE))
assert B == gcd_b(HOUSE) and sb == gcd_b(SURVEY) and 2 * A == S and 2 * sa == twice_area(SURVEY)
assert ar + ao == A and I == ir + io + 3 and ar == 4 * 3 and ao == 8 - 2 - 2  # gluing adds
assert agree == len(tris) and 2 * da == twice_area(DOUBLE) and R == [(4, 1), (4, 2), (4, 3)]
print("ALL CHECKS PASS")
