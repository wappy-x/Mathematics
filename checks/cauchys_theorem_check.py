# Cauchy's theorem -- the check behind the card.  Standard library only.
# Road one: the loop integral as a trapezoid sum along each straight leg.
# Road two: Green's theorem, i times the area integral of f_x + i f_y over the
# triangle, with the partial derivatives taken by finite differences.
import math

def show(w):                                 # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

def leg(f, a, b, n=20000):                   # trapezoid sum of f(z) dz from a to b
    d = (b - a) / n
    return d * (sum(f(a + k * d) for k in range(1, n)) + (f(a) + f(b)) / 2)

def loop(f, pts, n=20000):
    return [leg(f, pts[k], pts[(k + 1) % 3], n) for k in range(3)]

def green(f, pts, m=300, h=1e-4):            # i * (f_x + i f_y) dA over m^2 small triangles
    a, u, v = pts[0], (pts[1] - pts[0]) / m, (pts[2] - pts[0]) / m
    cell, total = abs((u.conjugate() * v).imag) / 2, 0j
    cents = [(j + 1 / 3, k + 1 / 3) for j in range(m) for k in range(m - j)]
    cents += [(j + 2 / 3, k + 2 / 3) for j in range(m) for k in range(m - j - 1)]
    for j, k in cents:
        g = a + j * u + k * v
        total += ((f(g + h) - f(g - h)) + 1j * (f(g + 1j * h) - f(g - 1j * h))) / (2 * h) * cell
    return 1j * total

course = [0j, 2 + 0j, 1 + 1j]
area = sum((course[k].conjugate() * course[(k + 1) % 3]).imag for k in range(3)) / 2
print(f"course 0 -> 2 -> 1+i, area by shoelace: {area:.6f}")
expz = lambda z: math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
e1i = complex(math.e * math.cos(1), math.e * math.sin(1))
exact = {"z^2": [8 / 3, (-10 + 2j) / 3, (2 - 2j) / 3], "e^z": [math.e ** 2 - 1, e1i - math.e ** 2, 1 - e1i]}
for name, f in (("z^2", lambda z: z * z), ("e^z", expz)):
    legs, r2 = loop(f, course), green(f, course)
    print(f"{name} legs, sums:           " + " | ".join(show(w) for w in legs))
    print(f"{name} legs, antiderivative: " + " | ".join(show(w) for w in exact[name]))
    print(f"{name} loop: road one {show(sum(legs))}, road two {show(r2)}")
    assert all(abs(p - q) < 1e-6 for p, q in zip(legs, exact[name])) and abs(sum(legs) - r2) < 1e-6
sizes = [abs(sum(loop(expz, course, n))) for n in (10, 100, 1000)]
print("e^z loop, trapezoid with 10, 100, 1000 steps a leg: " + ", ".join(f"{s:.6f}" for s in sizes))
assert sizes[0] > 50 * sizes[1] > 2500 * sizes[2]
via2 = leg(expz, 0j, 2 + 0j) + leg(expz, 2 + 0j, 1 + 1j)
print(f"e^z from 0 to 1+i: straight {show(leg(expz, 0j, 1 + 1j))}, via 2 {show(via2)}, e^(1+i) - 1 = {show(e1i - 1)}")
moved = sum(loop(lambda z: 1 / z, [p + 1 for p in course]))
big = [3 * p - 2 - 1j for p in course]
ring = sum(loop(lambda z: 1 / z, big))
print(f"1/z, course moved to 1 -> 3 -> 2+i: {show(moved)}")
print(f"1/z, course tripled to -2-i -> 4-i -> 1+2i: {show(ring)}, 2 pi i = {show(2j * math.pi)}")
assert abs(moved) < 1e-6 and abs(ring - 2j * math.pi) < 1e-6
bar = lambda z: z.conjugate()
zb, gb = sum(loop(bar, course)), green(bar, course)
print(f"mistake, z-bar round the course: road one {show(zb)}, road two {show(gb)}, 2i x area = {show(2j * area)}")
print(f"mistake, z-bar from 0 to 1+i: straight {show(leg(bar, 0j, 1 + 1j))}, via 2 {show(leg(bar, 0j, 2 + 0j) + leg(bar, 2 + 0j, 1 + 1j))}")
assert abs(zb - 2j * area) < 1e-6 and abs(gb - 2j * area) < 1e-6
print(f"mistake, 1/z round the tripled course clockwise: {show(sum(loop(lambda z: 1 / z, big[::-1])))}")
svg = lambda p: f"({140 + 50 * p.real:.0f}, {150 - 50 * p.imag:.0f})"
print("figure, course " + " ".join(svg(p) for p in course) + ", tripled " + " ".join(svg(p) for p in big))
print("ALL CHECKS PASS")
