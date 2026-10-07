# The 7-8-9 m bed. Road one: Heron. Road two: grid, Pythagoras, thin strips.

def root(v):                               # square root by Newton's rule
    r = max(v, 1.0)
    for _ in range(60):
        r = (r + v / r) / 2
    return r

def product(a, b, c):                      # Heron's product s(s-a)(s-b)(s-c)
    s = (a + b + c) / 2
    return s * (s - a) * (s - b) * (s - c)
def heron(a, b, c):
    return root(product(a, b, c))

def corner(a, b, c):                       # C above base AB, with A at (0, 0)
    x = (b * b + c * c - a * a) / (2 * c)  # from b^2 = x^2 + h^2, a^2 = (c - x)^2 + h^2
    return x, root(b * b - x * x)

def strips(c, x, h, n):                    # n strips, each read at its middle
    w, total = c / n, 0.0
    for i in range(n):
        t = (i + 0.5) * w
        total += w * (h * t / x if t < x else h * (c - t) / (c - x))
    return total

def height_to(p, q, r):                    # distance from p to the line through q, r
    dx, dy = r[0] - q[0], r[1] - q[1]
    k = ((p[0] - q[0]) * dx + (p[1] - q[1]) * dy) / (dx * dx + dy * dy)
    fx, fy = q[0] + k * dx, q[1] + k * dy  # the foot, found with the dot product
    return root((p[0] - fx) ** 2 + (p[1] - fy) ** 2)

a, b, c = 7, 8, 9
K, (x, h) = heron(a, b, c), corner(a, b, c)
A, B, C = (0.0, 0.0), (float(c), 0.0), (x, h)
ha, hb = height_to(A, B, C), height_to(B, C, A)
f16 = (a + b + c) * (-a + b + c) * (a - b + c) * (a + b - c)
g16 = 2 * (a * a * b * b + b * b * c * c + c * c * a * a) - (a ** 4 + b ** 4 + c ** 4)
trap, top, (x2, h2) = (c + c / 2) / 2 * (h / 2), (c / 2) * (h / 2) / 2, corner(8, 5, 4)
print(f"sides 7, 8, 9; s = {(a + b + c) / 2:.0f}; s(s-a)(s-b)(s-c) = {product(a, b, c):.0f}")
print(f"road one, Heron: area = {K:.6f}")
print(f"road two, grid: foot at x = {x:.6f}, height h = {h:.6f}, 9 x h / 2 = {c * h / 2:.6f}")
print("10, 100, 1000 strips: " + ", ".join(f"{strips(c, x, h, n):.6f}" for n in (10, 100, 1000)))
print(f"heights to a, b, c: {ha:.6f}, {hb:.6f}, {h:.6f}")
print(f"base x height, three ways: {a * ha:.6f}, {b * hb:.6f}, {c * h:.6f}")
print(f"16 x area^2: factored {f16}, expanded {g16}")
print(f"two beds, parallelogram: {c * h:.6f}")
print(f"cut halfway up: trapezoid {trap:.6f} + top {top:.6f} = {trap + top:.6f}")
print(f"second case 4, 5, 8: Heron {heron(4, 5, 8):.6f}; foot x = {x2:.6f}, h = {h2:.6f}, 4 x h / 2 = {4 * h2 / 2:.6f}")
print(f"mistake, slope as height: 9 x 8 / 2 = {c * b / 2:.6f}")
print(f"mistake, perimeter for s: {root(24 * 17 * 16 * 15):.6f}")
print(f"mistake, sum of bases for trapezoid: {(c + c / 2) * (h / 2):.6f}")
print(f"doubled sides 14, 16, 18: {heron(14, 16, 18):.6f}, {heron(14, 16, 18) / K:.6f} x the bed")
print(f"sides 2, 3, 6: s(s-a)(s-b)(s-c) = {product(2, 3, 6):.4f}, no triangle")
print(f"figure 1, 1 m = 30: A (45, 215), B (315, 215), C ({45 + 30 * x:.2f}, {215 - 30 * h:.2f})")
print(f"figure 2, 1 m = 20: A (40, 200), B (220, 200), D ({220 + 20 * x:.2f}, {200 - 20 * h:.2f}), C ({40 + 20 * x:.2f}, {200 - 20 * h:.2f})")
assert abs(strips(c, x, h, 1000) - K) < 1e-4             # strips against Heron
assert abs(16 * K * K - g16) < 1e-6                      # Heron against the expanded form
assert all(abs(v - 2 * K) < 1e-9 for v in (a * ha, b * hb, c * h))  # any base
assert abs(4 * h2 / 2 - heron(4, 5, 8)) < 1e-9           # obtuse case, two roads
print("ALL CHECKS PASS")
