# Colouring the plane -- the check behind the card.  Standard library only.
# Road 1: every colouring of the Moser spindle tried (3^7 = 2,187 of them).
# Road 2: the same counts by deletion-contraction, which never lists one.
# Road 3: the 7-colouring by hexagons: its two distances by formula and by
# measuring the polygons, then tested on random unit pairs (SplitMix64).
from math import sqrt, floor
from itertools import product

# A number a + b*sqrt3 + c*sqrt11 + d*sqrt33 is held as four integers (a, b, c, d).
def mul(x, y):
    (a, b, c, d), (e, f, g, h) = x, y
    return (a*e + 3*b*f + 11*c*g + 33*d*h, a*f + b*e + 11*c*h + 11*d*g,
            a*g + c*e + 3*b*h + 3*d*f, a*h + d*e + b*g + c*f)

def val(x): return (x[0] + x[1]*sqrt(3) + x[2]*sqrt(11) + x[3]*sqrt(33)) / 12
# The spindle, every coordinate multiplied by 12 so all are whole combinations.
NAMES = "ABCDEFG"
PTS = [((0, 0, 0, 0), (0, 0, 0, 0)), ((0, 1, 3, 0), (-3, 0, 0, 1)),
       ((0, -1, 3, 0), (-3, 0, 0, -1)), ((0, 0, 6, 0), (-6, 0, 0, 0)),
       ((0, 1, 3, 0), (3, 0, 0, -1)), ((0, -1, 3, 0), (3, 0, 0, 1)),
       ((0, 0, 6, 0), (6, 0, 0, 0))]

def dist2(p, q):
    dx, dy = (tuple(s - t for s, t in zip(p[k], q[k])) for k in (0, 1))
    return tuple(s + t for s, t in zip(mul(dx, dx), mul(dy, dy)))

pairs = [(i, j) for i in range(7) for j in range(i + 1, 7)]
edges = [(i, j) for i, j in pairs if dist2(PTS[i], PTS[j]) == (144, 0, 0, 0)]

def brute(n, es, k):                                   # road 1: list them all
    count = 0
    for code in range(k ** n):
        col = [code // k ** i % k for i in range(n)]
        count += all(col[u] != col[v] for u, v in es)
    return count

def dc(n, es, k):                                      # road 2: P(G) = P(G-e) - P(G/e)
    if not es: return k ** n
    (u, v), rest = es[0], es[1:]
    merged = sorted({(min(a, b), max(a, b)) for a, b in
                     ((u if a == v else a, u if b == v else b) for a, b in rest) if a != b})
    return dc(n, rest, k) - dc(n - 1, merged, k)

def clique(es):                                        # largest all-joined set
    best = 0
    for m in range(1 << 7):
        vs = [i for i in range(7) if m >> i & 1]
        if all((a, b) in es for a in vs for b in vs if a < b):
            best = max(best, len(vs))
    return best

R3 = sqrt(3)
CORNERS = [(R3 / 2, 0.5), (0.0, 1.0), (-R3 / 2, 0.5), (-R3 / 2, -0.5), (0.0, -1.0), (R3 / 2, -0.5)]

def centre(a, b, s):
    return (R3 * s * (a + b / 2), 1.5 * s * b)

def hexagon(a, b, s):
    cx, cy = centre(a, b, s)
    return [(cx + s * x, cy + s * y) for x, y in CORNERS]

def seg(p, a, b):                                      # point to segment distance
    vx, vy, wx, wy = b[0] - a[0], b[1] - a[1], p[0] - a[0], p[1] - a[1]
    t = max(0.0, min(1.0, (vx * wx + vy * wy) / (vx * vx + vy * vy)))
    return sqrt((wx - t * vx) ** 2 + (wy - t * vy) ** 2)

def gap(s):                                            # measured, polygon to polygon
    h0, best = hexagon(0, 0, s), 9.0
    for a, b in product(range(-5, 6), repeat=2):
        if (a + 3 * b) % 7 == 0 and (a, b) != (0, 0):
            h = hexagon(a, b, s)
            for P, Q in ((h0, h), (h, h0)):
                for p in P:
                    for i in range(6):
                        best = min(best, seg(p, Q[i], Q[(i + 1) % 6]))
    return best

def colour(x, y, s):                                   # colour of the nearest centre
    b0 = floor(y / (1.5 * s))
    a0 = floor(x / (R3 * s) - b0 / 2)
    best, col = 9e9, -1
    for a, b in product(range(a0 - 1, a0 + 3), range(b0 - 1, b0 + 3)):
        cx, cy = centre(a, b, s)
        d = (x - cx) ** 2 + (y - cy) ** 2
        if d < best:
            best, col = d, (a + 3 * b) % 7
    return col

M64 = (1 << 64) - 1
def unit_pairs(s, n, seed):                            # same-coloured pairs at distance 1
    st, bad = seed, 0
    def nxt():
        nonlocal st
        st = (st + 0x9E3779B97F4A7C15) & M64
        z = ((st ^ (st >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (z ^ (z >> 31)) >> 11
    for _ in range(n):
        x, y = 20 * nxt() / 2**53, 20 * nxt() / 2**53
        while True:
            dx, dy = 2 * nxt() / 2**53 - 1, 2 * nxt() / 2**53 - 1
            r = sqrt(dx * dx + dy * dy)
            if 0 < r <= 1:
                break
        bad += colour(x, y, s) == colour(x + dx / r, y + dy / r, s)
    return bad

cut = [e for e in edges if e != (3, 6)]                # the spindle without edge DG
print("Moser spindle: 7 points, unit pairs found by exact arithmetic:", len(edges), "of", len(pairs))
print("edges:", " ".join(NAMES[i] + NAMES[j] for i, j in edges))
print("figure, " + ", ".join(f"{NAMES[i]} ({val(p[0]):.4f}, {val(p[1]):.4f})" for i, p in enumerate(PTS)))
print("largest all-joined set:", clique(edges), "points")
b3, d3, b4, d4 = brute(7, edges, 3), dc(7, edges, 3), brute(7, edges, 4), dc(7, edges, 4)
print(f"proper 3-colourings: {b3} of {3**7} by listing, {d3} by deletion-contraction")
print(f"proper 4-colourings: {b4} of {4**7} by listing, {d4} by deletion-contraction")
c3, c4 = brute(7, cut, 3), brute(7, cut, 4)
hand = [k * (k - 1) ** 2 * (k - 2) ** 4 for k in (3, 4)]   # two diamonds sharing A
print(f"without edge DG: {c3} 3-colourings, {c4} 4-colourings; k(k-1)^2(k-2)^4 at 3 and 4: "
      f"{hand[0]}, {hand[1]}")
same = sum(1 for code in range(3**7) for col in [[code // 3**i % 3 for i in range(7)]]
           if all(col[u] != col[v] for u, v in cut) and col[0] == col[3] == col[6])
print(f"of those 3-colourings, A, D and G share one colour in {same}")
for s in (0.4, 0.55, 0.35):
    print(f"hexagons of side {s}: widest inside one {2 * s:.4f}; nearest same colour "
          f"{gap(s):.4f} measured, {sqrt(7) * s:.4f} by sqrt(7) x side")
nb = [(a + 3 * b) % 7 for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1))]
d12 = sqrt(sum(t * t for t in centre(1, 2, 0.4)))         # nearest same-colour centre
print(f"colours of the 6 neighbours of colour 0: {nb}; nearest colour-0 centre (1, 2), {d12:.4f} away at side 0.4")
print(f"side must lie between 1/sqrt(7) = {1 / sqrt(7):.4f} and 1/2 = 0.5000")
tests = [(s, unit_pairs(s, 100000, 2026)) for s in (0.4, 0.55, 0.35)]
for s, bad in tests:
    print(f"side {s}: 100000 random unit pairs, same-coloured pairs {bad}")
print("quoted, not checked here: de Grey 2018 graph 1581 points; Heule 2018 graph 553 points; Parts 2020 graph 509 points")
assert len(edges) == 11 and clique(edges) == 3
assert b3 == d3 == 0 and b4 == d4 > 0                  # two roads agree
assert [c3, c4] == [dc(7, cut, 3), dc(7, cut, 4)] == hand and same == c3
assert abs(gap(0.4) - sqrt(7) * 0.4) < 1e-12 and gap(0.35) < 1 < gap(0.4)
assert sorted(nb) == list(range(1, 7)) and abs(d12 - sqrt(21) * 0.4) < 1e-12
assert tests[0][1] == 0 and tests[1][1] > 0 and tests[2][1] > 0
print("ALL CHECKS PASS")
