# Green's theorem -- the check behind the card.  Standard library only; pi is
# built here, not imported.  The plot is a house-shaped field fenced at five
# posts, in metres.  The wind is F = (P, Q) = (-y^2/20, x^2/20), in newtons.
HOUSE = [(0, 0), (6, 0), (6, 4), (3, 6), (0, 4)]
RECT, TRI = [(0, 0), (6, 0), (6, 4), (0, 4)], [(0, 4), (6, 4), (3, 6)]

def simpson(f, a, b, n=200):                  # Simpson's rule, n even
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def loop(field, posts, out=False):            # each fence: P dx + Q dy, or outward P dy - Q dx
    works = []
    for a, b in zip(posts, posts[1:] + posts[:1]):
        dx, dy = b[0] - a[0], b[1] - a[1]
        def push(t):
            p, q = field(a[0] + t * dx, a[1] + t * dy)
            return p * dy - q * dx if out else p * dx + q * dy
        works.append(simpson(push, 0, 1))
    return works

top = lambda x: 4 + 2 * x / 3 if x <= 3 else 4 + 2 * (6 - x) / 3   # the roof line over the house

def count(m):                                 # squares of side 1/m wholly inside, whole numbers only
    roof = lambda i: 12 * m + 2 * min(i, 6 * m - i)          # 3 m times the roof height at x = i/m
    return sum(1 for i in range(6 * m) for j in range(6 * m) if 3 * (j + 1) <= min(roof(i), roof(i + 1))) / m / m

wind = lambda x, y: (-y * y / 20, x * x / 20)
curl = lambda x, y: x / 10 + y / 10           # Q_x - P_y, worked by hand
vortex = lambda x, y: (-(y - 3) / ((x - 3) ** 2 + (y - 3) ** 2), (x - 3) / ((x - 3) ** 2 + (y - 3) ** 2))
terms = [xa * yb - xb * ya for (xa, ya), (xb, yb) in zip(HOUSE, HOUSE[1:] + HOUSE[:1])]
shoelace, flux_area = sum(terms) / 2, sum(loop(lambda x, y: (x / 2, y / 2), HOUSE, out=True))
grid = [(m, count(m)) for m in (1, 10, 100)]
rect, tri, house = loop(wind, RECT), loop(wind, TRI), loop(wind, HOUSE)
minus_py = simpson(lambda x: simpson(lambda y: y / 10, 0, 4, 2), 0, 6, 2)
q_x = simpson(lambda x: simpson(lambda y: x / 10, 0, 4, 2), 0, 6, 2)
over = lambda f: sum(simpson(lambda x: simpson(lambda y: f(x, y), 0, top(x), 2), a, b, 20) for a, b in ((0, 3), (3, 6)))
inside = over(curl)
spin, two_pi = sum(loop(vortex, HOUSE)), 8 * simpson(lambda x: 1 / (1 + x * x), 0, 1)
k, pts = 1e-5, [(0.25 + i / 2, 0.25 + j / 2) for i in range(12) for j in range(12) if 0.25 + j / 2 < top(0.25 + i / 2)]
dq = max(abs(vortex(x + k, y)[1] - vortex(x - k, y)[1] - vortex(x, y + k)[0] + vortex(x, y - k)[0]) / (2 * k) for x, y in pts)
fl = lambda v: ", ".join(f"{x:.6f}" for x in v)
print("figure, 30 units per metre, origin (90, 215): " + " ".join(f"({90 + 30 * x}, {215 - 30 * y})" for x, y in HOUSE) + f"; vortex centre ({90 + 30 * 3}, {215 - 30 * 3})")
print(f"shoelace terms: {terms}; sum {sum(terms)}; area {shoelace:.6f} m2")
print(f"area as outward flux of (x, y)/2, fence by fence: {flux_area:.6f}")
for m, a in grid:
    print(f"area from squares of side 1/{m} wholly inside: {a:.6f}, short by {shoelace - a:.6f}")
print(f"area walked clockwise: {sum(loop(lambda x, y: (x / 2, y / 2), HOUSE[::-1], out=True)):.6f}")
print(f"rectangle, wind work fence by fence: {fl(rect)}; total {sum(rect):.6f} J")
print(f"rectangle inside: -P_y summed {minus_py:.6f} (bottom + top), Q_x summed {q_x:.6f} (right + left)")
print(f"house, wind work fence by fence: {fl(house)}; total {sum(house):.6f} J")
print(f"house inside: x summed {over(lambda x, y: x):.6f}, y summed {over(lambda x, y: y):.6f}, curl (x + y)/10 summed {inside:.6f} J")
print(f"shared fence y = 4: rectangle {rect[2]:.6f}, triangle {tri[0]:.6f}; {sum(rect):.6f} + {sum(tri):.6f} = {sum(rect) + sum(tri):.6f}")
print(f"mistake, curl taken as P_y - Q_x: {-inside:.6f}; mistake, half dropped: {sum(terms):.6f}")
print(f"vortex round (3, 3): circulation {spin:.6f}; 2 pi built by Simpson {two_pi:.6f}")
print(f"vortex curl by difference quotient at {len(pts)} points: largest size {dq:.6f}")
assert abs(flux_area - shoelace) < 1e-9 and 0 < shoelace - grid[-1][1] < 0.05    # three roads to the area
assert abs(sum(house) - inside) < 1e-9                                           # the theorem, on the house
assert abs(rect[0] + rect[2] - minus_py) < 1e-9 and abs(rect[1] + rect[3] - q_x) < 1e-9
assert abs(spin - two_pi) < 1e-9 and dq < 1e-6                                    # the hole breaks it
print("ALL CHECKS PASS")
