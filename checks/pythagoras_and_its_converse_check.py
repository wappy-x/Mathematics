# Pythagoras and its converse -- the check behind the card.  Nothing is imported.
# Truss: rafters 3 m and 4 m, square at the ridge.  Roads: the rule, the dissection,
# the tilted square's corner coordinates; the converse by a search round a circle.

def root(x):                             # square root by halving an interval
    lo, hi = 0.0, max(1.0, x)
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if mid * mid < x else (lo, mid)
    return lo

def shoelace(pts):                       # area of a polygon from its corners
    s = 0
    for (x, y), (u, v) in zip(pts, pts[1:] + pts[:1]):
        s += x * v - y * u
    return abs(s) / 2

def centre(a, b):                        # the tilted square inside the (a+b) square
    return [(a, 0), (a + b, a), (b, a + b), (0, b)]

def corner_x(a, b, c):                   # search for the far end of rafter b
    lo, hi = 0.0, 1000.0                 # t walks it round a circle of radius b
    for _ in range(200):
        t = (lo + hi) / 2
        x, y = b * (1 - t * t) / (1 + t * t), 2 * b * t / (1 + t * t)
        lo, hi = (t, hi) if (x - a) ** 2 + y * y < c * c else (lo, t)
    return x                             # x = 0 means the corner is square

for a, b in [(3, 4), (3, 3)]:
    rule, box = a * a + b * b, (a + b) ** 2 - 4 * (a * b / 2)
    area = shoelace(centre(a, b))
    print(f"rafters {a} and {b}: rule {a}^2 + {b}^2 = {rule}, span {root(rule):.10f}")
    print(f"  dissection: outer {a + b} x {a + b} = {(a + b) ** 2}, four triangles 4 x {a * b // 2} = {2 * a * b},"
          f" left {box:.0f}; corner coordinates give {area:.0f}; root {root(area):.10f}")
    assert rule == area and box == area                # three roads to one area
leg = root(5 * 5 - 3 * 3)
print(f"missing rafter, span 5 and rafter 3: {leg:.10f}")
c = root(25); p, q = 9 / c, 16 / c                     # the altitude's two pieces
print(f"altitude from C: pieces {p:.1f} + {q:.1f} = {p + q:.1f}, height {12 / c:.1f};"
      f" 5 x {p:.1f} = {c * p:.0f}, 5 x {q:.1f} = {c * q:.0f}")
assert abs(leg - 4) < 1e-9                             # the rafter actually cut
for c in [5.0, 5.1, 4.9, 5.001]:
    res = 3 * 3 + 4 * 4 - c * c
    x = corner_x(3, 4, c)
    x = 0.0 if abs(x) < 1e-12 else x
    verdict = "square" if x == 0 else ("opened" if x < 0 else "closed") + f" by {abs(x):.4f} m"
    print(f"corner test, diagonal {c:.3f}: 9 + 16 - {c * c:.6f} = {res:.6f}; search: {verdict}")
    assert abs(x - res / 6) < 1e-9                     # the search agrees with the residual
print(f"mistakes: add the rafters {3 + 4}; stop before the root {3 * 3 + 4 * 4};"
      f" 4 m rafter as the span {root(4 * 4 - 3 * 3):.10f}; 3, 5, 4 in place {9 + 25 - 16}")
print(f"try: rafters 6 and 8 span {root(6 * 6 + 8 * 8):.4f}; 5 and 12 span {root(5 * 5 + 12 * 12):.4f};"
      f" diagonal 5.01 opened by {-corner_x(3, 4, 5.01):.4f} m")
k = 60                                                 # truss figure: 1 m = 60 units
cx, cy = 30 + k * 16 / 5, 200 - k * 12 / 5
print(f"figure, truss 1 m = {k}: A (30, 200) B ({30 + 5 * k}, 200) C ({cx:.0f}, {cy:.0f})")
print(f"figure, square marker ({cx - 9.6:.1f}, {cy + 7.2:.1f}) ({cx - 2.4:.1f}, {cy + 16.8:.1f})"
      f" ({cx + 7.2:.1f}, {cy + 9.6:.1f})")
pts = [(20 + 30 * x, 220 - 30 * y) for x, y in centre(3, 4)]
print(f"figure, dissection 1 m = 30: outer (20, 10) to (230, 220); centre {pts}")
print("ALL CHECKS PASS")
