# Eight trees, one fence: monotone chain against gift wrapping.  Nothing imported.
T = {"A": (2, 0), "B": (14, 2), "C": (18, 10), "D": (12, 16),
     "E": (4, 14), "F": (0, 6), "G": (8, 6), "H": (11, 8), "I": (20, 4)}
P, name = sorted(v for k, v in T.items() if k != "I"), {v: k for k, v in T.items()}
def turn(a, b, c):                       # > 0: a -> b -> c bends left
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
def root(v):                             # square root by Newton's rule
    r = max(v, 1.0)
    for _ in range(60): r = (r + v / r) / 2
    return r
def chain(pts, log):                     # one half of the monotone chain
    h = []
    for p in pts:
        while len(h) >= 2 and turn(h[-2], h[-1], p) <= 0:  # a right turn or straight: drop
            log.append(f"{name[h[-1]]} {turn(h[-2], h[-1], p)}"); h.pop()
        h.append(p)
    return h[:-1]
def wrap(pts):                           # gift wrapping from the lowest leftmost tree
    hull = [min(pts)]
    while True:
        q = next(p for p in pts if p != hull[-1])
        for r in pts:
            if turn(hull[-1], q, r) < 0:
                q = r                    # r lies right of the string: swing to it
        if q == hull[0]: return hull
        hull.append(q)
area = lambda h: sum(turn((0, 0), h[i - 1], h[i]) for i in range(len(h))) / 2
fence = lambda h: sum(root((h[i][0] - h[i - 1][0]) ** 2 + (h[i][1] - h[i - 1][1]) ** 2) for i in range(len(h)))
inside = lambda h, p: all(turn(h[i - 1], h[i], p) >= -1e-9 for i in range(len(h)))
names = lambda h: " ".join(name[p] for p in h)
mono, gift = chain(P, low := []) + chain(P[::-1], up := []), wrap(P)
brute = sorted(name[a] + name[b] for a in P for b in P if a != b and all(turn(a, b, r) >= 0 for r in P))
edges = sorted(name[mono[i - 1]] + name[mono[i]] for i in range(len(mono)))
cells = sum(inside(mono, ((i + 0.5) / 20, (j + 0.5) / 20)) for i in range(360) for j in range(320))
seg = [((10 - t) * a[0] / 10 + t * b[0] / 10, (10 - t) * a[1] / 10 + t * b[1] / 10) for a in P for b in P if a < b for t in range(1, 10)]
A, B, C, D, F, G, H = (T[k] for k in "ABCDFGH")
w = [turn(G, B, D) / turn(F, B, D), turn(F, G, D) / turn(F, B, D), turn(F, B, G) / turn(F, B, D)]
mix = [w[0] * F[k] + w[1] * B[k] + w[2] * D[k] for k in (0, 1)]
dent, nine = [T[k] for k in "FAGBHCDE"], wrap(P + [T["I"]])
print(f"road one, monotone chain: {names(mono)}\nroad two, gift wrapping: {names(gift)}")
print(f"brute force, of {len(P) * (len(P) - 1)} ordered pairs, edges with every tree on the left: {' '.join(brute)}")
print("turns at the corners: " + ", ".join(f"{name[mono[i]]} {turn(mono[i - 1], mono[i], mono[(i + 1) % 6])}" for i in range(6))
      + f"; dented fence at G {turn(A, G, B)}, at H {turn(B, H, C)}")
print(f"lower sweep drops: {', '.join(low)}; upper sweep drops: {', '.join(up)}")
print("shoelace terms: " + ", ".join(f"{turn((0, 0), mono[i - 1], mono[i % 6]):.0f}" for i in range(1, 7)) + f"; sum {2 * area(mono):.0f}")
print("edges: " + ", ".join(f"{name[mono[i - 1]]}{name[mono[i % 6]]} {fence([mono[i - 1], mono[i % 6]]) / 2:.3f}" for i in range(1, 7)))
print(f"hull: {len(mono)} corners, area {area(mono):.1f} m^2, fence {fence(mono):.3f} m")
print(f"fine grid, 0.05 m cells inside: {cells} = {cells / 400:.2f} m^2")
print(f"segment rule: {len(seg)} points on the 28 tree-to-tree segments, inside the hull: {sum(inside(mono, p) for p in seg)}")
print(f"G as a mix of F, B, D: weights {w[0]:.4f}, {w[1]:.4f}, {w[2]:.4f}; sum {sum(w):.4f}; point ({mix[0]:.1f}, {mix[1]:.1f})")
print(f"midpoint of A and H (6.5, 4.0) in the notch A B G: {inside([A, B, G], (6.5, 4))}")
print(f"mistake, fence through all eight F A G B H C D E: area {area(dent):.1f} m^2, fence {fence(dent):.3f} m")
print(f"mistake, trees fenced left to right {names(P)}: area {area(P):.1f} m^2, fence {fence(P):.3f} m")
print(f"ninth tree I at (20, 4): hull {names(nine)}, area {area(nine):.1f} m^2, fence {fence(nine):.3f} m")
print("figure, 1 m = 12: " + " ".join(f"{k} ({40 + 12 * T[k][0]}, {216 - 12 * T[k][1]})" for k in "ABCDEFGH"))
assert mono == gift                                        # two sweeps, one fence
assert brute == edges                                      # every edge found by brute force
assert abs(cells / 400 - area(mono)) < 0.5                 # grid count against shoelace
assert min(w) > 0 and abs(mix[0] - G[0]) < 1e-9 and abs(mix[1] - G[1]) < 1e-9
print("ALL CHECKS PASS")
