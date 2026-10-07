# Complex numbers -- the check behind the card.  Nothing is imported.
# A complex number is a pair (a, b) of reals, written a + bi.  The drone sits at
# z = 3 + 4i km from its depot; the multiplier is w = 1 + 2i.  Two roads to each
# product: the pair rule, and turn-and-add (w = c + di means c copies of z plus
# d copies of z turned a quarter left), which never calls the pair rule.
def add(p, q): return (p[0] + q[0], p[1] + q[1])
def scale(k, p): return (k * p[0], k * p[1])
def mul(p, q):                        # road one: (a + bi)(c + di) = (ac - bd) + (ad + bc)i
    (a, b), (c, d) = p, q
    return (a * c - b * d, a * d + b * c)
def quarter(p): return (-p[1], p[0])  # a quarter turn left: the point (a, b) goes to (-b, a)
def turn_and_add(p, q):               # road two: c copies of p, plus d copies of p turned
    return add(scale(q[0], p), scale(q[1], quarter(p)))
def length(p): return (p[0] * p[0] + p[1] * p[1]) ** 0.5
def dot(p, q): return p[0] * q[0] + p[1] * q[1]
def fmt(p):
    re, im = p[0] + 0.0, p[1] + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

I, z, w = (0.0, 1.0), (3.0, 4.0), (1.0, 2.0)
sc, ox, oy = 20, 200, 215
pix = lambda p: f"({ox + sc * p[0]:.0f}, {oy - sc * p[1]:.0f})"
zw, zw2, iz = mul(z, w), turn_and_add(z, w), mul(I, z)
turns, p = [], z
for _ in range(4):
    p = mul(I, p)
    turns.append(fmt(p))
b, c = 2.0, 5.0                       # second case: x^2 + 2x + 5 = 0, by the quadratic formula
disc = b * b - 4 * c
roots = [(-b / 2, s * (-disc) ** 0.5 / 2) for s in (1, -1)]
plug = [add(add(mul(r, r), scale(b, r)), (c, 0.0)) for r in roots]
left, right = mul(mul(z, w), I), mul(z, mul(w, I))
print(f"figure, scale {sc} px per km, depot {pix((0, 0))}; z {pix(z)}; iz {pix(iz)}; "
      f"w {pix(w)}; zw {pix(zw)}; arc radius {sc * length(z):.0f}")
print(f"i times i = {fmt(mul(I, I))}")
print(f"z + w = {fmt(add(z, w))}; z - w = {fmt(add(z, scale(-1, w)))}")
print(f"pair rule parts: ac = {z[0] * w[0]:.6f}, bd = {z[1] * w[1]:.6f}, ad = {z[0] * w[1]:.6f}, bc = {z[1] * w[0]:.6f}")
print(f"zw by the pair rule = {fmt(zw)}")
print(f"zw by z + 2(iz), turn and add = {fmt(zw2)}")
print(f"wz by the pair rule = {fmt(mul(w, z))}")
print(f"iz by the pair rule = {fmt(iz)}; by the quarter turn = {fmt(quarter(z))}")
print(f"|z| = {length(z):.6f}; |iz| = {length(iz):.6f}; z dot iz = {dot(z, iz):.6f}")
print(f"one to four quarter turns of z: {'; '.join(turns)}")
print(f"on the real axis: (2 + 0i)(-3 + 0i) = {fmt(mul((2.0, 0.0), (-3.0, 0.0)))}")
print(f"(zw)i = {fmt(left)}; z(wi) = {fmt(right)}")
print(f"x^2 + 2x + 5 = 0: discriminant {disc:.6f}; roots {fmt(roots[0])} and {fmt(roots[1])}")
print(f"root squared = {fmt(mul(roots[0], roots[0]))}; 2 times root = {fmt(scale(b, roots[0]))}")
print(f"each root put back in: {fmt(plug[0])} and {fmt(plug[1])}")
print(f"mistake 1, multiplying part by part: {fmt((z[0] * w[0], z[1] * w[1]))}, not {fmt(zw)}")
print(f"mistake 2, i squared taken as +1: {fmt((z[0] * w[0] + z[1] * w[1], z[0] * w[1] + z[1] * w[0]))}, not {fmt(zw)}")
print(f"mistake 3, turned the wrong way, (b, -a): {fmt((z[1], -z[0]))}, not {fmt(iz)}")
assert abs(zw[0] - zw2[0]) < 1e-12 and abs(zw[1] - zw2[1]) < 1e-12      # two roads, one product
assert abs(length(iz) - length(z)) < 1e-12 and abs(dot(z, iz)) < 1e-12   # times i: same length, square corner
assert all(abs(v[0]) < 1e-12 and abs(v[1]) < 1e-12 for v in plug)        # the formula's roots solve it
assert abs(left[0] - right[0]) < 1e-12 and abs(left[1] - right[1]) < 1e-12  # grouping does not matter
print("ALL CHECKS PASS")
