# Polyhedra and Euler's formula -- the check behind the card.  Standard library only.
# A football of 12 pentagons and 20 hexagons, then the five regular solids, two roads each.
from itertools import combinations, product
from math import cos, sin, radians
def angle(p): return 180 * (p - 2) / p              # one corner of a regular p-sided face
def share(n): return 2 * n - 3 * n + 6               # an n-sided ball panel's part of V - E + F, in sixths
def measure(pts):                                     # road two: p, q, V, E, F from positions
    d = lambda a, b: sum((u - v) ** 2 for u, v in zip(a, b))
    short = min(d(a, b) for a, b in combinations(pts, 2))
    E, faces = sum(abs(d(a, b) - short) < 1e-9 for a, b in combinations(pts, 2)), set()
    for a, b, c in combinations(pts, 3):              # a face: corners on one plane with
        u, w = [b[i] - a[i] for i in range(3)], [c[i] - a[i] for i in range(3)]
        n = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        s = [sum(n[i] * (x[i] - a[i]) for i in range(3)) for x in pts]
        if min(s) > -1e-9 or max(s) < 1e-9:           # the whole solid on one side of it
            faces.add(frozenset(k for k, v in enumerate(s) if abs(v) < 1e-9))
    return len(next(iter(faces))), 2 * E // len(pts), len(pts), E, len(faces)
g = (1 + 5 ** 0.5) / 2                                # the golden ratio
def turn(pts): return [t for x, y, z in pts for t in ((x, y, z), (y, z, x), (z, x, y))]
cube = list(product((-1, 1), repeat=3))
seen = {name: measure(pts) for name, pts in [("tetrahedron", [c for c in cube if c[0] * c[1] * c[2] == 1]),
        ("cube", cube), ("octahedron", turn([(s, 0, 0) for s in (-1, 1)])),
        ("dodecahedron", cube + turn([(0, a / g, b * g) for a in (-1, 1) for b in (-1, 1)])),
        ("icosahedron", turn([(0, a, b * g) for a in (-1, 1) for b in (-1, 1)]))]}
P, H = 12, 20                                         # road one for the ball: count sides
sides = 5 * P + 6 * H
V, E, F = sides // 3, sides // 2, P + H               # three panels per corner, two per seam
p, q, Vi, Ei, Fi = seen["icosahedron"]                # road two: slice off its 12 corners
cut, gap = (q * Vi, Ei + q * Vi, Fi + Vi), 360 - angle(5) - 2 * angle(6)
by_shares = (2 * 6 - H * share(6)) // share(5)       # shares total 2: solve for the pentagons
by_count = sorted({a for a in range(200) for b in range(200) for s in [5 * a + 6 * b] if s % 6 == 0 and s // 3 - s // 2 + a + b == 2})
print(f"football by panels: F = {F}, sides {sides}, E = {sides}/2 = {E}, V = {sides}/3 = {V}; V - E + F = {V - E + F}")
print(f"football by slicing the icosahedron's {Vi} corners: V = {cut[0]}, E = {cut[1]}, F = {cut[2]}")
print(f"shares: hexagon 6/3 - 6/2 + 1 = {share(6) // 6}, pentagon 5/3 - 5/2 + 1 = {share(5)}/6, so 2 / ({share(5)}/6) = {by_shares} pentagons")
print(f"one corner: {angle(5):.0f} + {angle(6):.0f} + {angle(6):.0f} = {360 - gap:.0f} degrees, gap {gap:.0f}; {V} corners x {gap:.0f} = {V * gap:.0f}")
print(f"pentagons by angles: 720 / (5 x {gap:.0f}) = {720 / (5 * gap):.0f}; by V - E + F = 2, 0 to 199 of each: {by_count}")
euler = [(p, q) for p in range(3, 101) for q in range(3, 101) if 2 * p + 2 * q - p * q > 0]
corners = [(p, q) for p in range(3, 101) for q in range(3, 101) if q * angle(p) < 360]
formula = sorted((p, q, 4 * p // d, 2 * p * q // d, 4 * q // d) for p, q in euler for d in [2 * p + 2 * q - p * q])
print("solid          p  q   V   E   F  V-E+F  (p-2)(q-2)  gap per corner x V")
for name, (p, q, v, e, f) in seen.items():
    print(f"{name:<13}{p:>3}{q:>3}{v:>4}{e:>4}{f:>4}{v - e + f:>5}{(p - 2) * (q - 2):>9}    {360 - q * angle(p):>9.0f} x {v} = {v * (360 - q * angle(p)):.0f}")
print(f"(p, q) to 100 with 2p + 2q - pq > 0: {euler}; by corners under 360: {'same' if corners == euler else 'differ'}")
print(f"rows above measured from corner positions; E = 2pq/(2p + 2q - pq) agrees: {'yes' if sorted(seen.values()) == formula else 'no'}")
print(f"breaks: seams not halved {V} - {sides} + {F} = {V - sides + F}; 20 hexagons alone {6 * 20 // 3} - {6 * 20 // 2}"
      f" + 20 = {6 * 20 // 3 - 6 * 20 // 2 + 20}; p = 6, q = 3: 2p + 2q - pq = {2 * 6 + 2 * 3 - 6 * 3}")
for group in ([("open box", 8, 12, 5), ("two open boxes", 16, 24, 10), ("two dice", 16, 24, 12)],
              [("picture frame", 16, 32, 16), ("cube on a cube", 16, 24, 11), ("small stellated dodecahedron", 12, 30, 12)]):
    print("conditions: " + "; ".join(f"{n} {v} - {e} + {f} = {v - e + f}" for n, v, e, f in group))
R = 20 / sin(radians(36)); c = R * cos(radians(36)) + 20 * 3 ** 0.5    # figure: seam 40 units
pent = [(R * cos(radians(90 + 72 * k)), R * sin(radians(90 + 72 * k))) for k in range(5)]
hexa = [(c * cos(radians(54)) + 40 * cos(radians(204 + 60 * k)),       # the hexagon on the
         c * sin(radians(54)) + 40 * sin(radians(204 + 60 * k))) for k in range(6)]  # top-right seam
for label, pts in (("seam 40, centre 180,117, pentagon", pent), ("top-right hexagon, turn by 72 for the rest", hexa)):
    print(f"figure, {label} " + " ".join(f"{180 + x:.2f},{117 - y:.2f}" for x, y in pts))
assert euler == corners and len(euler) == 5                    # two reasons, the same five pairs
assert sorted(seen.values()) == formula                        # corner positions against the formula
assert (V, E, F) == cut                                        # the ball two ways
assert by_count == [round(720 / (5 * gap))] == [by_shares]     # twelve pentagons three ways
print("ALL CHECKS PASS")
