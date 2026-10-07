# Gradient and directional derivatives -- the check behind the card.  Standard
# library only.  The slope: height h(x, y) = 500 - x^2/800 - y^2/400 metres, x metres
# east and y metres north of the summit.  The skier stands at p = (120, 80).
from math import sqrt, cos, sin, pi
def h(x, y): return 500 - x * x / 800 - y * y / 400
X, Y = 120.0, 80.0
gx, gy = -X / 400, -Y / 200                  # road 1: partials by hand, per metre
size = sqrt(gx * gx + gy * gy)
down = (-gx / size, -gy / size)              # steepest descent: minus the gradient, unit length
def dot(u): return gx * u[0] + gy * u[1]
def quot(f, x, y, u, t): return (f(x + t * u[0], y + t * u[1]) - f(x, y)) / t   # road 2
def contour_y(x, level):                     # own bisection: the y that puts x on the contour
    lo, hi = 0.0, 200.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if h(x, mid) > level else (lo, mid)
    return (lo + hi) / 2
r2 = sqrt(2)
print(f"height at p {h(X, Y):.3f} m; gradient ({gx:.6f}, {gy:.6f}); length {size:.6f}")
print(f"rate east {dot((1, 0)):.6f}, north {dot((0, 1)):.6f}, northeast {dot((1 / r2, 1 / r2)):.6f}")
print(f"steepest descent direction ({down[0]:.6f}, {down[1]:.6f}); rate {dot(down):.6f}")
for t in (10, 1, 0.01):
    q = quot(h, X, Y, down, t)
    print(f"difference quotient downhill, step {t:g} m: {q:.7f}; gap per metre of step {(q - dot(down)) / t:.5f}")
best = min(range(3600), key=lambda k: quot(h, X, Y, (cos(k * pi / 1800), sin(k * pi / 1800)), 1e-6))
bu = (cos(best * pi / 1800), sin(best * pi / 1800))
brate = quot(h, X, Y, bu, 1e-6)
print(f"search of 3600 headings: best {best / 10:.1f} deg, ({bu[0]:.6f}, {bu[1]:.6f}), rate {brate:.6f}")
tang = (-down[1], down[0])
print(f"level direction ({tang[0]:.6f}, {tang[1]:.6f}): rate {dot(tang):.6f}")
lev = h(X, Y)
for d in (10, 1, 0.01):
    cx, cy = 2 * d, contour_y(X + d, lev) - contour_y(X - d, lev)
    n = sqrt(cx * cx + cy * cy)
    print(f"contour chord, x = 120 +- {d:g}: slope {cy / cx:.6f}; gradient dot unit chord {dot((cx / n, cy / n)):.6f}")
print(f"tangent slope from the gradient: {-gx / gy:.6f}")
print(f"straight traverse 20 m along the level direction: height change {h(X + 20 * tang[0], Y + 20 * tang[1]) - lev:.6f} m")
print(f"mistake, direction (1, 1) not unit length: rate {dot((1, 1)):.6f}")
print(f"mistake, skiing along +gradient: rate {dot((-down[0], -down[1])):.6f}")
def crease(x, y): return 0.0 if x == 0 and y == 0 else x * x * y / (x * x + y * y)
cq = [quot(crease, 0, 0, (1 / r2, 1 / r2), t) for t in (0.1, 0.001)]
cg = (quot(crease, 0, 0, (1, 0), 1e-6), quot(crease, 0, 0, (0, 1), 1e-6))
print(f"crease at origin: partials ({cg[0]:.6f}, {cg[1]:.6f}); formula gives 0; quotients {cq[0]:.6f}, {cq[1]:.6f}")
S, OX, OY = 1.5, 30, 225                     # figure: 1.5 px per metre, summit at (30, 225)
def px(x, y): return f"({OX + S * x:.2f}, {OY - S * y:.2f})"
print(f"figure, p {px(X, Y)}; arrow end {px(X + 40 * down[0], Y + 40 * down[1])}; "
      f"level ends {px(X + 30 * tang[0], Y + 30 * tang[1])} {px(X - 30 * tang[0], Y - 30 * tang[1])}")
print("figure, contour radii px " + "; ".join(f"{L} m: {S * sqrt(800 * (500 - L)):.2f} x {S * sqrt(400 * (500 - L)):.2f}" for L in (480, 466, 450)))
assert abs(brate - (-size)) < 1e-5 and abs(bu[0] - down[0]) < 1e-3   # search vs formula
assert abs(quot(h, X, Y, down, 1e-6) - dot(down)) < 1e-5             # quotient vs dot product
cy = contour_y(X + 0.01, lev) - contour_y(X - 0.01, lev)
assert abs(cy / 0.02 - (-gx / gy)) < 1e-4                           # bisected contour vs gradient
assert cq[1] - (cg[0] / r2 + cg[1] / r2) > 0.3                      # crease: formula fails
print("ALL CHECKS PASS")
