# Kakeya: the check behind the card. Standard library only.
# A Perron tree: cut a triangle of height 1 into 2^k thin triangles and slide them
# sideways so they pile up. Sliding never turns a triangle, so every needle
# direction survives while the area shrinks. Every area is computed here.
import math

B = 1 / math.sqrt(3)  # half-base of the equilateral triangle of height 1
T = B                 # its area: base 2B times height 1, halved

def tree(k, al):
    # thin triangles [left base x, right base x, apex x]; base at y = 0, apex at y = 1
    n = 2 ** k
    tris = [[-B + 2 * B * i / n, -B + 2 * B * (i + 1) / n, 0.0] for i in range(n)]
    groups = [([i], (tris[i][0], tris[i][1], 0.0, 1.0)) for i in range(n)]
    while len(groups) > 1:  # each round merges neighbouring groups in pairs
        new = []
        for (i1, (a1, b1, p1x, p1y)), (i2, (a2, b2, p2x, p2y)) in zip(groups[0::2], groups[1::2]):
            s = b1 - a2  # close the gap: the two main triangles become one triangle M
            b2, p2x = b2 + s, p2x + s
            assert abs(p1x - p2x) < 1e-12 and abs(p1y - p2y) < 1e-12  # common apex
            t = (1 - al) * (b2 - a1)  # then slide the right group left by (1 - alpha) of M's base
            for i in i2:
                for j in range(3):
                    tris[i][j] += s - t
            new.append((i1 + i2, (a1, b2 - t, a1 + al * (p1x - a1), al * p1y)))
        groups = new
    return tris

def width(tris, y):  # length of the union of the triangles' cross-sections at height y
    iv = sorted((l + (a - l) * y, r + (a - r) * y) for l, r, a in tris)
    tot, (cl, cr) = 0.0, iv[0]
    for l, r in iv[1:]:
        if l > cr:
            tot, cl, cr = tot + cr - cl, l, r
        else:
            cr = max(cr, r)
    return tot + cr - cl

def area_exact(tris):  # road 1: between edge crossings the width is linear, so midpoints are exact
    lines = [e for l, r, a in tris for e in ((l, a - l), (r, a - r))]
    ys = {0.0, 1.0}
    for i, (c1, m1) in enumerate(lines):
        for c2, m2 in lines[i + 1:]:
            if m1 != m2 and 0 < (c2 - c1) / (m1 - m2) < 1:
                ys.add((c2 - c1) / (m1 - m2))
    ys = sorted(ys)
    return sum((y2 - y1) * width(tris, (y1 + y2) / 2) for y1, y2 in zip(ys, ys[1:]))

def area_sampled(tris, m=20000):  # road 2: plain midpoint rule on m slices
    return sum(width(tris, (j + 0.5) / m) for j in range(m)) / m

def bound(k, al):  # main triangle alpha^(2k), plus 2(1 - alpha)^2 of each merged triangle
    return al ** (2 * k) + 2 * (1 - al) ** 2 * (1 - al ** (2 * k)) / (1 - al * al)

pts = [(-B, 0.0), (B, 0.0), (0.0, 1.0)]
shoe = abs(sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]))) / 2
assert abs(shoe - 1 / math.sqrt(3)) < 1e-15
print(f"starting triangle, height 1: area {shoe:.6f} (1/sqrt 3 = {1 / math.sqrt(3):.6f}); disc pi/4 = {math.pi / 4:.6f}")
print("one merge (k=1): exact area = (alpha^2 + 2(1-alpha)^2) T")
for al in (1.0, 2 / 3, 0.5):
    a, f = area_exact(tree(1, al)), (al * al + 2 * (1 - al) ** 2) * T
    assert abs(a - f) < 1e-12
    print(f"  alpha={al:.4f}: sweep {a:.6f}, formula {f:.6f}, share of T {a / T:.4f}")
a4, f4 = area_exact(tree(1, 0.4)) / T, 0.4 * 0.4 + 2 * 0.6 * 0.6  # alpha below 1/2: the formula fails
print(f"  alpha=0.4000: sweep share {a4:.4f}, formula share {f4:.4f}: below 1/2 the formula overstates")
assert f4 - a4 > 0.01
print("k  alpha     area(exact)  area(sampled) share  bound   3 trees")
bars = []
for k in range(1, 9):
    al = 1 - math.log(k + 1) / (2 * k)
    tr = tree(k, al)
    a, b = area_exact(tr), area_sampled(tr)
    assert abs(a - b) < 1e-6 and a <= bound(k, al) * T + 1e-12
    assert a > 0.95 * bound(k, al) * T  # the sprouts barely overlap
    bars.append(a / T)
    print(f"{k}  {al:.6f}  {a:.6f}     {b:.6f}       {a / T:.4f}  {bound(k, al):.4f}  {3 * a:.6f}")
    if k == 8:
        a8 = a
        # every direction in the 60-degree wedge: a needle from some apex to the base
        hit = 0
        for j in range(2001):
            u = -B + 2 * B * j / 2000  # base point x - apex x, for a needle from the apex
            hit += any(l - 1e-12 <= a0 + u <= r + 1e-12 for l, r, a0 in tr)
        assert hit == 2001
        print(f"k=8: directions with a needle from apex to base: {hit} of 2001; "
              f"x from {min(t[0] for t in tr):.4f} to {max(t[1] for t in tr):.4f}")
print("bars:", ", ".join(f"{v:.4f}" for v in bars))
fixed = area_exact(tree(8, 2 / 3)) / T
print(f"fixed alpha=2/3 at k=8: share {fixed:.4f}, bound floor 2(1-a)/(1+a) = {2 * (1 / 3) / (5 / 3):.4f}")
assert fixed > bars[-1]

# Pal join: move a needle to a parallel line h away by turning theta, sliding, turning back
for th in (0.01, 0.001):
    m = 100000  # fan of thin triangles: the sector swept by one turn, by shoelace
    fan = sum(0.5 * math.sin(th / m) for _ in range(m))
    assert abs(fan - th / 2) < 1e-9
    print(f"Pal join theta={th}: two sectors {2 * fan:.6f} (formula theta {th}), slide 1/sin = {1 / math.sin(th):.4f}")
joins = 3 * 2 ** 8 - 1
print(f"whole half-turn, k=8, theta=1e-7: at most {3 * a8:.6f} + {joins} x 1e-7 = {3 * a8 + joins * 1e-7:.6f}"
      f" (deltoid pi/8 = {math.pi / 8:.6f})")
assert 3 * a8 + joins * 1e-7 < math.pi / 8
room = math.pi / 8 - 3 * a8
print(f"room under the deltoid: {room:.6f}, so each of {joins} joins may use theta up to {room / joins:.4e}")

# Hausdorff sums for the middle-thirds Cantor set: 2^k pieces of length 3^-k
s0 = math.log(2) / math.log(3)
print(f"Cantor set: critical s = log 2 / log 3 = {s0:.6f}")
for s in (0.5, s0, 0.7):
    sums = [2 ** k * 3.0 ** (-k * s) for k in (10, 20, 40)]
    print(f"  s={s:.4f}: k=10 {sums[0]:.4e}, k=20 {sums[1]:.4e}, k=40 {sums[2]:.4e}")
    if s == s0:
        assert abs(sums[2] - 1) < 1e-9
    else:
        assert (sums[2] > sums[0]) == (s < s0)

tr = tree(3, 1 - math.log(4) / 6)
print("figure, k=3 tree, base x and apex x:", "; ".join(f"{l:.4f} {r:.4f} {a:.4f}" for l, r, a in tr))
print("ALL CHECKS PASS")
