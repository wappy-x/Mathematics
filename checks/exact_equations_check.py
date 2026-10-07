# Exact equations -- the check behind the card.  Standard library only.  A valley:
# x, y in km east and north of its floor, height in hundreds of metres.  Road one:
# F = x^2 + xy + y^2 by integrating twice.  Road two: climbs and Euler steps, blind to F.
import math

M = lambda x, y: 2 * x + y                        # eastward slope, 100 m per km
N = lambda x, y: x + 2 * y                        # northward slope, 100 m per km
F = lambda x, y: x * x + x * y + y * y            # road one: integrate M in x, match N
contour = lambda x: (-x + math.sqrt(4 - 3 * x * x)) / 2   # F = 1 solved for y, through (0, 1)
d = 1e-5

def simpson(f, a, b, n=200):                      # area under f from a to b, n even
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * (b - a) / n) for i in range(1, n))
    return s * (b - a) / (3 * n)

def climb(p, v, m=M, n=N):                        # sum of m dx + n dy along s -> p(s), s from 0 to 1
    return simpson(lambda s: m(*p(s)) * v(s)[0] + n(*p(s)) * v(s)[1], 0, 1)

def euler(x_end, h):                              # small steps along the slope y' = -M/N
    x, y = 0.0, 1.0
    for _ in range(round(x_end / h)):
        x, y = x + h, y - h * M(x, y) / N(x, y)
    return y

my, nx = (M(1, 2 + d) - M(1, 2 - d)) / (2 * d), (N(1 + d, 2) - N(1 - d, 2)) / (2 * d)
east, north = climb(lambda s: (s, 0), lambda s: (1, 0)), climb(lambda s: (1, 2 * s), lambda s: (0, 2))
curve = climb(lambda s: (s, 2 * s * s), lambda s: (1, 4 * s))
eul = [euler(0.5, h) for h in (0.05, 0.025, 0.0125)]
err = [abs(e - contour(0.5)) for e in eul]
sl, secant = -M(0.5, contour(0.5)) / N(0.5, contour(0.5)), (contour(0.5 + d) - contour(0.5 - d)) / (2 * d)
xv, yv = 2 / math.sqrt(3), -1 / math.sqrt(3)
bad_my = (M(1, d) / N(1, d) - M(1, -d) / N(1, -d)) / (2 * d)   # the equation divided by N first
angle = climb(lambda s: (math.cos(2 * math.pi * s), math.sin(2 * math.pi * s)),
              lambda s: (-2 * math.pi * math.sin(2 * math.pi * s), 2 * math.pi * math.cos(2 * math.pi * s)),
              lambda x, y: -y / (x * x + y * y), lambda x, y: x / (x * x + y * y))
px = lambda x, y: (170 + 50 * x, 120 - 50 * y)   # figure: 50 px per km, floor at (170, 120)
(ax, ay), r = px(0.5, contour(0.5)), math.hypot(1, sl)   # arrow on the contour, pointing along it
arrow = [ax + 8 / r, ay - 8 * sl / r, ax + 4 * sl / r, ay + 4 / r, ax - 4 * sl / r, ay - 4 / r]
print(f"exactness test at (1, 2): dM/dy {my:.6f}, dN/dx {nx:.6f}")
print(f"F(1, 2) by integrating twice {F(1, 2):.6f}; climbed east then north {east:.6f} + {north:.6f}; along y = 2x^2 {curve:.6f}")
print(f"start (0, 1): M = {M(0, 1)}, N = {N(0, 1)}, level C = {F(0, 1):.4f}, slope -M/N = {-M(0, 1) / N(0, 1):.4f}")
print("contour y at x = 0, 0.5, 1:", " ".join(f"{contour(x):.4f}" for x in (0, 0.5, 1)))
print(f"slope at x = 0.5: -M/N {sl:.4f}; secant of the contour {secant:.4f}")
print("Euler y(0.5), h = 0.05, 0.025, 0.0125:", " ".join(f"{e:.4f}" for e in eul))
print("Euler errors:", " ".join(f"{e:.4f}" for e in err) + f"; ratios {err[0] / err[1]:.3f} {err[1] / err[2]:.3f}")
print(f"height on the Euler path at x = 0.5, h = 0.05: {F(0.5, eul[0]):.4f}, not 1")
print(f"vertical tangent at ({xv:.4f}, {yv:.4f}): M = {M(xv, yv):.4f}, N = {abs(N(xv, yv)):.4f}")
print(f"contour C = 1 half-widths: {math.sqrt(2 / 3):.4f} km along y = x, {math.sqrt(2):.4f} km along y = -x")
print(f"mistake, g(y) dropped: x^2 + xy at (1, 2) = {F(1, 2) - 2 ** 2}, not 7")
print(f"mistake, divided by N first: at (1, 0) dM/dy {bad_my:.4f}, dN/dx 0")
print(f"mistake, (2x + 2y)dx + (x + 2y)dy: dM/dy 2, dN/dx 1; g'(1) at x = 0 is {N(0, 1) - 2 * 0}, at x = 1 is {N(1, 1) - 2 * 1}")
print(f"mistake, angle form round the unit circle: {angle:.4f}, not 0")
print("figure, rings C = 0.25, 1, 2.25 (25, 100, 225 m), rx ry:", " ".join(f"{50 * math.sqrt(2 * c / 3):.2f} {50 * math.sqrt(2 * c):.2f}" for c in (0.25, 1, 2.25)))
print("figure, 50 px per km, floor 170 120; start {:.1f} {:.1f}; tangent {:.1f} {:.1f}; arrow".format(*px(0, 1), *px(xv, yv)), " ".join(f"{a:.1f}" for a in arrow))
assert abs(east + north - F(1, 2)) < 1e-9 and abs(curve - F(1, 2)) < 1e-9   # road two meets road one
assert abs(my - nx) < 1e-6 and abs(bad_my + 3) < 1e-4               # exact; divided form is not
assert abs(secant - sl) < 1e-6 and err[2] < 0.003                    # the contour obeys the law
assert 1.8 < err[0] / err[1] < 2.2 and abs(angle - 2 * math.pi) < 1e-9
print("ALL CHECKS PASS")
