# Voronoi cells and the Delaunay triangulation -- the check behind the card. Nothing is imported.
# Road one tests every triple of hospitals for an empty circle; road two cuts the county along bisectors.
H = {"A": (1, 3), "B": (9, 3), "C": (9, 7), "D": (3, 7), "E": (7, 5)}
NAMES, HOUSE, W, n = sorted(H), (4, 5), 10, 5
d2 = lambda p, q: (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2
km = lambda p, q: d2(p, q) ** 0.5
pt = lambda p: f"({p[0]:.2f}, {p[1]:.2f})"
key = lambda p: (round(p[0], 6) + 0.0, round(p[1], 6) + 0.0)
def centre(a, b, c):  # equal distance to a, b and c: two straight-line equations, solved
    a1, b1, c1 = 2 * (b[0] - a[0]), 2 * (b[1] - a[1]), d2(b, (0, 0)) - d2(a, (0, 0))
    a2, b2, c2 = 2 * (c[0] - a[0]), 2 * (c[1] - a[1]), d2(c, (0, 0)) - d2(a, (0, 0))
    return ((c1 * b2 - c2 * b1) / (a1 * b2 - a2 * b1), (a1 * c2 - a2 * c1) / (a1 * b2 - a2 * b1))
def clip(poly, p, q):  # keep the part of a convex polygon at least as close to p as to q
    f, out = (lambda v: d2(v, p) - d2(v, q)), []
    for u, v in zip(poly, poly[1:] + poly[:1]):
        if f(u) <= 0: out.append(u)
        if f(u) * f(v) < 0:
            t = f(u) / (f(u) - f(v)); out.append((u[0] + t * (v[0] - u[0]), u[1] + t * (v[1] - u[1])))
    return out
print("hospitals " + " ".join(f"{k} {H[k]}" for k in NAMES) + f"; county {W} km x {W} km")
print(f"house {HOUSE}: " + " ".join(f"{k} {km(HOUSE, H[k]):.2f}" for k in NAMES) + " km -> nearest " + min(NAMES, key=lambda k: d2(HOUSE, H[k])))
triples = [a + b + c for a in NAMES for b in NAMES for c in NAMES if a < b < c]
tris, edges1 = [], set()                                            # road one: empty circles
for t in triples:
    o = centre(*(H[k] for k in t)); r = km(o, H[t[0]]); near = min(km(o, H[k]) for k in NAMES if k not in t)
    if near > r + 1e-9:
        tris.append(key(o)); edges1 |= {t[0] + t[1], t[0] + t[2], t[1] + t[2]}
        print(f"triangle {' '.join(t)}: centre {pt(o)}, radius {r:.2f}, next hospital {near:.2f} km")
print(f"triples tested {len(triples)}, empty circles {len(tris)}; Delaunay edges {' '.join(sorted(edges1))}")
cells = {k: [(0.0, 0.0), (W, 0.0), (W, W), (0.0, W)] for k in NAMES}     # road two: cut the county
for k, q in [(k, q) for k in NAMES for q in NAMES if k != q]: cells[k] = clip(cells[k], H[k], H[q])
ties = lambda v: sum(abs(d2(v, H[q]) - min(d2(v, H[s]) for s in NAMES)) < 1e-9 for q in NAMES)
corners = sorted({key(v) for c in cells.values() for v in c if ties(v) >= 3})
edges2 = [p + q for p in NAMES for q in NAMES if p < q and sum(abs(d2(v, H[p]) - d2(v, H[q])) < 1e-9 for v in cells[p]) >= 2]
print("road two, corners shared by three cells: " + " ".join(pt(v) for v in corners))
print("road two, cells sharing an edge: " + " ".join(edges2))
areas = {k: sum(u[0] * v[1] - v[0] * u[1] for u, v in zip(c, c[1:] + c[:1])) / 2 for k, c in cells.items()}
count = dict.fromkeys(NAMES, 0)                           # 400 x 400 houses, 1/40 km apart
for i in range(400):
    for j in range(400):
        count[min(NAMES, key=lambda k: d2((2 * i + 1, 2 * j + 1), (80 * H[k][0], 80 * H[k][1])))] += 1
print("cell areas by shoelace, km^2: " + " ".join(f"{k} {areas[k]:.2f}" for k in NAMES) + f"; total {sum(areas.values()):.2f}")
print("cell areas by counting 160000 houses: " + " ".join(f"{k} {count[k] / 1600:.2f}" for k in NAMES) + f"; total {sum(count.values()) / 1600:.2f}")
h = sum(any(min(v) < 1e-9 or max(v) > W - 1e-9 for v in cells[k]) for k in NAMES)
print(f"hull hospitals (open-ended cells) h = {h}; triangles 2n-2-h = {2 * n - 2 - h}; edges 3n-3-h = {3 * n - 3 - h}")
worst = max((km(v, H[k]), key(v)) for k in NAMES for v in cells[k])
brute = max((min(km((x, y), H[k]) for k in NAMES), (x, y)) for x in range(W + 1) for y in range(W + 1))
print(f"worst-served spot, from the cells: {pt(worst[1])} at {worst[0]:.2f} km; by grid search: {pt(brute[1])} at {brute[0]:.2f} km")
g = ((1 + 9 + 7) / 3, (3 + 3 + 5) / 3); o = centre(H["A"], H["B"], H["D"])
print(f"mistake 1, centroid {pt(g)} of A B E: " + " ".join(f"{k} {km(g, H[k]):.2f}" for k in "ABE") + " km, not equal")
print(f"mistake 2, triangle A B D: centre {pt(o)}, radius {km(o, H['A']):.2f}, but E is {km(o, H['E']):.2f} km away")
print(f"mistake 3, every triple as a corner: {len(triples)} centres, the map has {len(corners)}")
px = lambda p: f"({70 + 22 * p[0]:g},{230 - 22 * p[1]:g})"
print("figure, 1 km = 22 units, hospitals " + " ".join(px(H[k]) for k in NAMES) + ", corners " + " ".join(px(v) for v in corners))
print("figure, edge ends " + " ".join(px(v) for v in sorted({key(v) for c in cells.values() for v in c if ties(v) == 2})) + f", house {px(HOUSE)}, circle A D E radius {22 * km(corners[0], H['A']):.2f}")
assert corners == sorted(tris)                                      # two roads, one set of corners
assert edges2 == sorted(edges1) and len(tris) == 2 * n - 2 - h      # two roads, one triangulation
assert all(abs(areas[k] - count[k] / 1600) < 0.2 for k in NAMES)    # shoelace against counting
assert abs(worst[0] - brute[0]) < 1e-9                              # cells against brute search
print("ALL CHECKS PASS")
