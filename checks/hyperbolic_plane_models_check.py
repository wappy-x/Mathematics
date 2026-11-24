# Three maps of one hyperbolic plane -- the check behind the card.  Standard library only.
# The same points in the half-plane, the Poincare disc and the Klein disc.  Each distance comes from
# a formula and from thin slices of the map's ruler; each angle is measured on the drawing itself.
from math import log, sqrt, atan, pi; from cmath import phase, rect
DEG, N, EPS = 180 / pi, 100000, 1e-5
def acosh(c): return log(c + sqrt(c * c - 1))
def half_d(z, w): return acosh(1 + abs(z - w) ** 2 / (2 * z.imag * w.imag))   # half-plane formula
def disc_d(p, q): return acosh(1 + 2 * abs(p - q) ** 2 / ((1 - abs(p) ** 2) * (1 - abs(q) ** 2)))
def klein_d(a, b):                       # half the log of the cross-ratio with the chord's two rim ends
    u = b - a; A, B, C = abs(u) ** 2, 2 * (a.conjugate() * u).real, abs(a) ** 2 - 1
    t1, t2 = (-B - sqrt(B * B - 4 * A * C)) / (2 * A), (-B + sqrt(B * B - 4 * A * C)) / (2 * A)
    return 0.5 * log((1 - t1) * t2 / (-t1 * (t2 - 1)))
def to_half(p): return 1j * (1 + p) / (1 - p)            # Cayley map, disc -> half-plane
def to_disc(z): return (z - 1j) / (z + 1j)               # and back
def to_klein(p): return 2 * p / (1 + abs(p) ** 2)         # same ray, radius r -> 2r/(1 + r^2)
def from_klein(k): return k / (1 + sqrt(1 - abs(k) ** 2))
def inv_mirror(p): q = 1 + 2 / (p.conjugate() - 1); return complex(-q.imag, -q.real)   # invert, then mirror in y = -x
def slices(path, ruler, a, b):           # add up ruler x drawn length over N thin pieces of a path
    pts = [path(a + (b - a) * i / N) for i in range(N + 1)]; return sum(abs(q - p) * ruler((p + q) / 2) for p, q in zip(pts, pts[1:]))
xy = lambda z, k=6: f"({z.real + 0.0:.{k}f}, {z.imag + 0.0:.{k}f})"; yn = lambda claim: "yes" if claim else "no"
def px(z, o, s): return f"({o[0] + s * z.real:.1f}, {o[1] - s * z.imag:.1f})"
d12, up = half_d(1j, 2j), slices(lambda t: 1j * t, lambda z: 1 / z.imag, 1, 2)   # straight up, ruler dy/y
disc_up, klein_up = (slices(lambda t: t, lambda p: 2 / (1 - abs(p) ** 2), 0, 1 / 3),      # disc ruler 2/(1 - r^2)
                     slices(lambda t: t, lambda k: 1 / (1 - abs(k) ** 2), 0, 0.6))      # Klein ruler, along a radius
two_roads = all(abs(inv_mirror(rect(0.02 * j, j)) - to_half(rect(0.02 * j, j))) < 1e-12 for j in range(49))
rim = max(abs(to_half(rect(1, t / DEG)).imag) for t in range(5, 360, 5))
print(f"half-plane i to 2i: 1 + 1/(2 x 1 x 2) = {1 + 1 / 4:.6f}, cosh(ln 2) = {(2 + 1 / 2) / 2:.6f}, d = {d12:.6f}")
print(f"half-plane i to 2i, {N} thin slices of dy/y: {up:.6f}; ln 2 = {log(2):.6f}")
print(f"Cayley: disc 0 -> {xy(to_half(0))}, 1/3 -> {xy(to_half(1 / 3))}, 0.5 -> {xy(to_half(0.5))}, rim i -> {xy(to_half(1j))}")
print(f"Cayley: 71 rim points, every 5 degrees, all land on the real line (height under 1e-9): {yn(rim < 1e-9)}")
print(f"inversion in the circle centre 1, radius sqrt 2, sends 1/3 to {1 + 2 / (1 / 3 - 1):.6f}; the mirror in y = -x then gives {xy(inv_mirror(1 / 3 + 0j))}")
print(f"inversion then mirror agrees with Cayley at 49 disc points: {yn(two_roads)}")
print(f"disc 0 to 1/3: formula {disc_d(0, 1 / 3):.6f}, slices {disc_up:.6f}\nKlein: disc 1/3 -> {to_klein(1 / 3):.6f}, back {from_klein(0.6):.6f}; 0 to 0.6: "
      f"chord formula {klein_d(0j, 0.6 + 0j):.6f}, slices {klein_up:.6f}")
z, w = 1j, 1 + 1j; p, q = to_disc(z), to_disc(w); kq = to_klein(q)            # a pair off one vertical line
arc = slices(lambda t: 0.5 + rect(sqrt(1.25), t), lambda z: 1 / z.imag, phase(w - 0.5), phase(z - 0.5))
pair = [half_d(z, w), disc_d(p, q), klein_d(to_klein(p), kq), arc]
print(f"pair i, 1 + i: cosh d = 1 + 1/2 = {1 + abs(w - z) ** 2 / 2:.6f}; disc 0 and {xy(q)}, Klein 0 and {xy(kq)}\n  half-plane {pair[0]:.6f} | disc {pair[1]:.6f} | Klein {pair[2]:.6f} | slices on the arc {pair[3]:.6f}")
A, B, c = 0.5 + 0j, 0.5j, 1.25 + 1.25j; k = abs(A - c); fA = phase(A - c)    # card 02's triangle O, A, B
on_arc = lambda t: c + rect(k, t)                                            # side AB, by its angle at c
def angle_at_A(f):                        # angle between the image of side AO and the image of side AB
    return abs(phase((f(on_arc(fA - EPS)) - f(on_arc(fA + EPS))) / (f(A - EPS) - f(A + EPS)))) * DEG
ang = [angle_at_A(f) for f in (lambda p: p, to_half, to_klein)]
side = [on_arc(fA - j * 0.01) for j in range(49)]                           # 49 points along side AB
miss_k, miss_h = max(abs(to_klein(s).real + to_klein(s).imag - 0.8) for s in side), max(abs(abs(to_half(s) - 5) - sqrt(34)) for s in side)
print(f"triangle: half-plane B {xy(to_half(B), 1)}; Klein A {to_klein(A).real:.1f}, B {to_klein(B).imag:.1f}i; disc arc radius {k:.6f}")
print(f"angle at A: disc {ang[0]:.6f} | half-plane {ang[1]:.6f} | atan(3/5) {atan(0.6) * DEG:.6f} | Klein drawn {ang[2]:.6f}"
      f"\ntriangle sum: true {90 + 2 * ang[0]:.6f} | Klein drawn {90 + 2 * ang[2]:.6f}")
print(f"side AB, 49 points: on the Klein chord x + y = 0.8: {yn(miss_k < 1e-9)}; on the half-plane circle centre 5, radius {sqrt(34):.6f}: {yn(miss_h < 1e-9)}")
print(f"figure, disc R 85 at (100, 115): A {px(A, (100, 115), 85)} B {px(B, (100, 115), 85)} Q {px(1 / 3 + 0j, (100, 115), 85)} arc r {85 * k:.1f}; "
      f"Klein: A {px(to_klein(A), (300, 115), 85)} B {px(to_klein(B), (300, 115), 85)} Q {px(0.6 + 0j, (300, 115), 85)}; "
      f"half-plane x55 at (500, 205): O {px(1j, (500, 205), 55)} A {px(3j, (500, 205), 55)} B {px(to_half(B), (500, 205), 55)} Q {px(2j, (500, 205), 55)} arc r {55 * sqrt(34):.1f}")
print(f"mistakes: drawn gap |2i - i| {abs(2j - 1j):.6f}; Klein 0.6 in the disc's formula {log(1.6 / 0.4):.6f}; "
      f"one ruler reading at height 1.5 {1 / 1.5:.6f}; straight across i to 1 + i {slices(lambda t: t + 1j, lambda z: 1 / z.imag, 0, 1):.6f}")
assert abs(d12 - log(2)) < 1e-12 and abs(up - log(2)) < 1e-9                # formula against slices
assert abs(disc_up - log(2)) < 1e-9 and abs(klein_up - log(2)) < 1e-9        # the same gap in the two discs
assert max(pair) - min(pair) < 1e-9 and abs(to_disc(to_half(0.3 - 0.4j)) - (0.3 - 0.4j)) < 1e-12
assert abs(ang[0] - atan(0.6) * DEG) < 1e-6 and abs(ang[1] - ang[0]) < 1e-6 and abs(ang[2] - 45) < 1e-6
assert miss_k < 1e-9 and miss_h < 1e-9 and rim < 1e-9 and two_roads and abs(from_klein(to_klein(0.3 - 0.4j)) - (0.3 - 0.4j)) < 1e-12
print("ALL CHECKS PASS")
