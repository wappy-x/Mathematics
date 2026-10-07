# Polar form and argument -- the check behind the card.  Standard library only.
# Wind A: 10 km/h toward the north-east.  Turn-and-double w = 2 at 90 degrees.
# Two roads: products by the pair rule and by lengths-and-angles; the argument
# by atan2 and by a bisection on cos that never calls any inverse trig.
import math
def clean(x): return 0.0 if abs(x) < 5e-7 else x
def fmt(z): return f"{clean(z.real):.6f} {'-' if clean(z.imag) < 0 else '+'} {abs(clean(z.imag)):.6f}i"
def deg(t): return f"{clean(t * 180 / math.pi):.6f}"
def polar(r, t): return complex(r * math.cos(t), r * math.sin(t))
def mod(z): return math.sqrt(z.real * z.real + z.imag * z.imag)
def arg(z): return math.pi if z.imag == 0 and z.real < 0 else math.atan2(z.imag, z.real)  # road one; atan2(-0.0, -1) is -pi
def arg_bisect(z):                                              # road two
    c, lo, hi = z.real / mod(z), 0.0, math.pi                   # cos falls on [0, pi]
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if math.cos(mid) > c else (lo, mid)
    t = (lo + hi) / 2
    return -t if z.imag < 0 else t
def times(z, w):                                                # the pair rule, (a, b)(c, d)
    return complex(z.real * w.real - z.imag * w.imag, z.real * w.imag + z.imag * w.real)
A, w = polar(10, math.pi / 4), polar(2, math.pi / 2)
P1, P2 = times(A, w), polar(mod(A) * mod(w), arg(A) + arg(w))
SW, D, i = -A, 3 + 4j, 1j
up, down = complex(-1, 0.001), complex(-1, -0.001)
Q = times(P1, i)
sc, ox, oy = 9, 170, 150
px = lambda z: f"({ox + sc * z.real:.0f}, {oy - sc * z.imag:.0f})"
print(f"figure, scale {sc} px per km/h, origin {px(0j)}; A {px(A)}; product {px(P1)}; south-west {px(SW)}")
print(f"wind A, 10 at 45 deg = {fmt(A)}; back: r = {mod(A):.6f}, arg = {arg(A):.6f} rad ({deg(arg(A))} deg)")
print(f"turn-and-double w, 2 at 90 deg = {fmt(w)}")
print(f"A times w by the pair rule = {fmt(P1)}")
print(f"A times w by lengths and angles = {fmt(P2)}")
print(f"product: r = {mod(P1):.6f}, arg = {arg(P1):.6f} rad ({deg(arg(P1))} deg)")
for name, z in (("south-west wind", SW), ("drone", D), ("just above -1", up), ("just below -1", down)):
    print(f"{name} {fmt(z)}: arg by atan2 = {arg(z):.6f} ({deg(arg(z))} deg); by bisection = {arg_bisect(z):.6f}")
print(f"-1 - i: arg = {arg(complex(-1, -1)):.6f}; 225 deg = {5 * math.pi / 4:.6f} rad, outside (-pi, pi]; minus one turn = {5 * math.pi / 4 - 2 * math.pi:.6f}")
print(f"jump across the negative real axis: {arg(up) - arg(down):.6f}; one full turn = {2 * math.pi:.6f}; on it, -1 - 0.0i: atan2 = {math.atan2(-0.0, -1):.6f}, arg = {arg(complex(-1, -0.0)):.6f}")
print("sweep at 0, 45, 90, 135, 180, 225, 270, 315 deg round the circle, principal arg in deg:",
      ", ".join(f"{arg(polar(1, k * math.pi / 4)) * 180 / math.pi:.0f}" for k in range(8)))
print(f"product turned by i: {fmt(Q)}; arg = {deg(arg(Q))} deg; arg sum = {deg(arg(P1) + arg(i))} deg")
print(f"undo the turn, product / w = {fmt(P1 / w)}")
print(f"mistake 1, atan(b/a) for the south-west wind: {deg(math.atan(SW.imag / SW.real))} deg, not {deg(arg(SW))}")
print(f"mistake 2, lengths added: 12 at 135 deg = {fmt(polar(12, 3 * math.pi / 4))}, not {fmt(P1)}")
print(f"mistake 3, arg of product as arg sum: {deg(arg(P1) + arg(i))} deg, not {deg(arg(Q))}")
print(f"mistake 4, 45 fed to cos and sin as radians: {fmt(polar(10, 45))}, not {fmt(A)}")
assert all(abs(arg(z) - arg_bisect(z)) < 1e-9 for z in (A, P1, SW, D, up, down, Q))  # two roads to arg
assert abs(P1 - P2) < 1e-12                                     # two roads to the product
assert abs(arg(Q) - (arg(P1) + arg(i) - 2 * math.pi)) < 1e-12   # arg adds up to one whole turn
assert abs(polar(mod(SW), arg(SW)) - SW) < 1e-12                # round trip back to a + bi
print("ALL CHECKS PASS")
