# Harmonic functions and conjugates -- the check behind the card.  Standard library only.
# Road one works from the temperature u alone: finite differences, Simpson sums, loop sums.
# Road two is the closed form: v = 2xy, second derivatives 2 and -2, 2 pi times a residue.
import math
f6 = lambda a: f"{round(a, 6) + 0.0:.6f}"    # six decimals, no -0.000000

def d1(f, x, y, e=1e-5):                     # u_x, u_y by central differences
    return (f(x + e, y) - f(x - e, y)) / (2 * e), (f(x, y + e) - f(x, y - e)) / (2 * e)

def d2(f, x, y, e=1e-3):                     # u_xx, u_yy by second differences
    return ((f(x + e, y) - 2 * f(x, y) + f(x - e, y)) / e ** 2,
            (f(x, y + e) - 2 * f(x, y) + f(x, y - e)) / e ** 2)

def simpson(g, a, b, n=100):                 # our own integrator
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n)))

def conjugate(f, a, x, y, across_first):     # v from u alone: v_x = -u_y, v_y = u_x, v(a, 0) = 0
    if across_first:
        return simpson(lambda s: -d1(f, s, 0)[1], a, x) + simpson(lambda s: d1(f, x, s)[0], 0, y)
    return simpson(lambda s: d1(f, a, s)[0], 0, y) + simpson(lambda s: -d1(f, s, y)[1], a, x)

def loop(f, cx, r, n=400):                   # loop sum of the partner's slope (-u_y, u_x) round a circle
    ts = [2 * math.pi * k / n for k in range(n)]
    return sum(sum(p * q for p, q in zip(d1(f, cx + r * math.cos(t), r * math.sin(t)),
               (r * math.cos(t), r * math.sin(t)))) * 2 * math.pi / n for t in ts)
u, v = lambda x, y: x * x - y * y, lambda x, y: 2 * x * y      # the plate's temperature, its partner
wire = lambda x, y: 0.5 * math.log(x * x + y * y)              # log|z|
print(f"plate at P = (1, 2): temperature u = {f6(u(1, 2))}, partner v = 2xy = {f6(v(1, 2))}")
(uxx, uyy), (vxx, vyy) = d2(u, 1, 2), d2(v, 1, 2)
print(f"Laplacian of u at P: u_xx {f6(uxx)} + u_yy {f6(uyy)} = {f6(uxx + uyy)}")
print(f"Laplacian of v at P: v_xx {f6(vxx)} + v_yy {f6(vyy)} = {f6(vxx + vyy)}")
va, vb, vv = conjugate(u, 0, 1, 2, True), conjugate(u, 0, 1, 2, False), conjugate(v, 0, 1, 2, True)
print(f"v built from u alone, across then up: {f6(va)}; up then across: {f6(vb)}; partner of v itself: {f6(vv)}")
dots = []
for x, y in ((1, 2), (-1.5, 0.5)):
    (ux, uy), (vx, vy) = d1(u, x, y), d1(v, x, y)
    dots.append(ux * vx + uy * vy)
    turn = math.degrees(math.atan2(vy, vx) - math.atan2(uy, ux))
    print(f"at ({x}, {y}): grad u ({f6(ux)}, {f6(uy)}), grad v ({f6(vx)}, {f6(vy)}); dot {f6(dots[-1])}; turn {f6(turn)} deg")
(wxx, wyy), vw = d2(wire, 2, 1), conjugate(wire, 1, 2, 1, True)
print(f"hot wire, log|z| at (2, 1): Laplacian {f6(wxx + wyy)}; v built from anchor (1, 0): {f6(vw)}; atan2(1, 2) = {f6(math.atan2(1, 2))}")
loops = [loop(wire, 0, 1), loop(wire, 0, 0.5), loop(wire, 3, 1)]
print(f"loop sum of the partner's slope round the wire, radius 1: {f6(loops[0])}; radius 0.5: {f6(loops[1])}")
print(f"loop sum round a circle missing the wire (centre 3, radius 1): {f6(loops[2])}")
res = [z * complex(d1(wire, z, 0)[0], -d1(wire, z, 0)[1]) for z in (0.5, 0.1)]   # z (u_x - i u_y)
print(f"residue road: z (u_x - i u_y) at z = 0.5: {f6(res[0].real)}, at z = 0.1: {f6(res[1].real)}; 2 pi x residue = {f6(2 * math.pi * res[1].real)}")
sxx, syy = d2(lambda x, y: x * x + y * y, 1, 2)
bx, by = d1(u, 1, 2)[0], d1(lambda x, y: -2 * x * y, 1, 2)[1]
print(f"mistake 1, |z|^2 = x^2 + y^2 at P: Laplacian {f6(sxx)} + {f6(syy)} = {f6(sxx + syy)}")
print(f"mistake 2, sign slip v = -2xy at P: u_x {f6(bx)} against v_y {f6(by)}")
fig = lambda x, y: f"({40 + 40 * x:.1f},{210 - 40 * y:.1f})"
print("figure, 40 units per 1, 0 at (40,210): P " + fig(1, 2) + "; heat arrow tip " + fig(1 - 0.6 / math.sqrt(5), 2 + 1.2 / math.sqrt(5)))
print("figure, isotherm u = -3: " + " ".join(fig(x / 2, math.sqrt(x * x / 4 + 3)) for x in range(7)))
print("figure, flow line v = 4: " + " ".join(fig(x, 2 / x) for x in (0.5, 0.75, 1, 1.5, 2, 3, 4)))
assert abs(uxx - 2) < 1e-6 and abs(uyy + 2) < 1e-6              # second differences meet 2 and -2 by hand
assert all(abs(a - b) < 1e-9 for a, b in ((va, 4), (vb, 4), (vv, -u(1, 2)), (vw, math.atan2(1, 2))))  # built = closed form
assert all(abs(d) < 1e-8 for d in dots)                          # gradients perpendicular
assert all(abs(s - 2 * math.pi * res[1].real) < 1e-6 for s in loops[:2]) and abs(loops[2]) < 1e-8
print("ALL CHECKS PASS")
