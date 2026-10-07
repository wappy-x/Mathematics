# The semicircle contour -- the check behind the card.  Standard library only.
# Road one: 2 pi i times the residue at i, the one pole above the real axis.
# Road two: the lighthouse's own angle, x = tan t, summed along the real line.
# Road three: segment plus arc at finite R, each a trapezoid sum, against road one.
import math

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def f(z, k): return 1 / (1 + z * z) ** k      # k = 1: the lighthouse curve; k = 2: its square
def gap1(z, k): return z / (1 + z * z)        # degree gap only 1: breaks the method
def trap(g, a, b, n=20000):                   # trapezoid sum of g from a to b
    h = (b - a) / n
    return h * (sum(g(a + j * h) for j in range(1, n)) + (g(a) + g(b)) / 2)
def arc(R, k, g=f):                           # z = R e^(it), dz = i z dt, t from 0 to pi
    return trap(lambda t: g(R * complex(math.cos(t), math.sin(t)), k) * 1j * R * complex(math.cos(t), math.sin(t)), 0, math.pi)
def angle_road(k, n=4000):                    # x = tan t, dx = dt / cos^2 t, midpoints only
    h = math.pi / n
    return h * sum(f(math.tan(-math.pi / 2 + (j + 0.5) * h), k) / math.cos(-math.pi / 2 + (j + 0.5) * h) ** 2 for j in range(n))

res1 = 1 / (1j + 1j)                          # (z - i) f(z) = 1/(z + i), at z = i
res2 = -2 / (1j + 1j) ** 3                    # d/dz of 1/(z + i)^2 = -2/(z + i)^3, at z = i
road1 = (2j * math.pi * res1, 2j * math.pi * res2)
road2 = (angle_road(1), angle_road(2))
share = lambda R: trap(lambda x: f(x, 1) / math.pi, -R, R)
print(f"lighthouse: share per km at the foot {1 / math.pi:.6f}; within 1 km {share(1):.6f}; within 2 km {share(2):.6f}")
print(f"residue at i of 1/(1+z^2): {show(res1)}; of 1/(1+z^2)^2: {show(res2)}")
print(f"road 1, 2 pi i x residue: {show(road1[0])} and {show(road1[1])}")
print(f"road 2, beam angle x = tan t, 4000 steps: {road2[0]:.6f} and {road2[1]:.6f}")
print(f"share of the whole shore: {road2[0] / math.pi:.6f}")
arcs = {}
for R in (2, 4, 8, 16):
    arcs[R] = (arc(R, 1), arc(R, 2))
    ml = (math.pi * R / (R * R - 1), math.pi * R / (R * R - 1) ** 2)
    print(f"R = {R}: arc {show(arcs[R][0])} (ML {ml[0]:.6f}); squared {show(arcs[R][1])} (ML {ml[1]:.6f})")
    assert abs(arcs[R][0]) <= ml[0] and abs(arcs[R][1]) <= ml[1]
seg = (trap(lambda x: f(x, 1), -2, 2), trap(lambda x: f(x, 2), -2, 2))
print(f"R = 2 closed: segment {seg[0]:.6f} + arc = {show(seg[0] + arcs[2][0])}; squared {seg[1]:.6f} + arc = {show(seg[1] + arcs[2][1])}")
print(f"mistake, arc dropped at R = 2: {seg[0]:.6f} instead of {math.pi:.6f}")
print(f"mistake, both poles summed: {show(2j * math.pi * (res1 + 1 / (-1j - 1j)))}")
print(f"mistake, simple-pole rule at the double pole: {show(2j * math.pi / (1j + 1j) ** 2)}")
g2, g16 = arc(2, 1, gap1), arc(16, 1, gap1)
print(f"degree gap 1, z/(1+z^2): arc at R = 2 {show(g2)}, at R = 16 {show(g16)}, ML at 16 {math.pi * 256 / 255:.6f}")
o, s = (180, 150), 40                         # figure: 0 at (180, 150), 40 units per 1, R = 2
print(f"figure, segment ({o[0] - 2 * s:.2f}, {o[1]:.2f}) to ({o[0] + 2 * s:.2f}, {o[1]:.2f}), arc top ({o[0]:.2f}, {o[1] - 2 * s:.2f}), poles ({o[0]:.2f}, {o[1] - s:.2f}) and ({o[0]:.2f}, {o[1] + s:.2f})")
assert abs(road1[0] - road2[0]) < 1e-9 and abs(road1[1] - road2[1]) < 1e-9
assert abs(seg[0] + arcs[2][0] - road1[0]) < 1e-7 and abs(seg[1] + arcs[2][1] - road1[1]) < 1e-7
assert abs(arcs[16][0]) < abs(arcs[8][0]) < abs(arcs[4][0]) < abs(arcs[2][0]) and abs(g16 - g2) < 1e-7
print("ALL CHECKS PASS")
