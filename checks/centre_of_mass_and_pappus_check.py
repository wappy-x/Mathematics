# Centre of mass and Pappus -- the check behind the card.  Standard library
# only: math gives sqrt and pi, and every integral is this file's own Simpson
# sum.  A swim ring's tube is a circle of radius r = 0.1 m whose centre sits
# R = 0.3 m from the axis it spins round.  Metres in, litres out.
import math
R, r, L, N = 0.3, 0.1, 1000.0, 20000        # L: litres per m^3; N: panels

def simpson(f, a, b, n):                    # n even panels, weights 1 4 2 4 ... 4 1
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def w(y):                                   # half-chord of the tube circle at offset y
    return math.sqrt(max(r * r - y * y, 0.0))

def washers(c, n):                          # road two: rings stacked along the axis
    return simpson(lambda y: math.pi * ((c + w(y)) ** 2 - max(c - w(y), 0.0) ** 2), -r, r, n)

area = simpson(lambda x: 2 * w(x - R), R - r, R + r, N)          # vertical strips
xbar = simpson(lambda x: x * 2 * w(x - R), R - r, R + r, N) / area
pappus = area * 2 * math.pi * xbar                                  # road one
exact = 2 * math.pi ** 2 * R * r * r
half = simpson(lambda y: 2 * w(y), 0, r, N)                      # half-disc, flat side down
moment = simpson(lambda y: y * 2 * w(y), 0, r, N)                  # strips times their height
ybar = moment / half
sphere = half * 2 * math.pi * ybar
c = 0.05                                                            # axis cuts the circle
cross_pappus, cross_true = area * 2 * math.pi * c, washers(c, N)

print(f"swim ring: tube radius r = {r} m, {2 * r:.1f} m across, centre R = {R} m from the axis, "
      f"strips from a = {R - r:.1f} m to b = {R + r:.1f} m")
print(f"area by strips {area:.7f} m^2, pi r^2 = {math.pi * r * r:.7f} m^2")
print(f"centroid by integration: xbar = {xbar:.6f} m, path 2 pi xbar = {2 * math.pi * xbar:.6f} m")
print(f"road one, Pappus: area x path = {pappus:.7f} m^3 = {pappus * L:.4f} L")
for n in (10, 100, 1000):
    v = washers(R, n)
    print(f"road two, washers, {n:4d} panels: {v * L:.4f} L, error {abs(v - exact) * L:.6f} L")
print(f"closed form 2 pi^2 R r^2 = {exact * L:.4f} L")
print(f"half-disc moment by strips {moment:.9f} m^3, antiderivative 2 r^3 / 3 = {2 * r ** 3 / 3:.9f} m^3")
print(f"half-disc: area {half:.7f} m^2, ybar = {ybar:.6f} m, 4r/(3 pi) = {4 * r / (3 * math.pi):.6f} m")
print(f"half-disc spun on its flat side, Pappus: {sphere * L:.4f} L, 4/3 pi r^3 = {4 / 3 * math.pi * r ** 3 * L:.4f} L")
print(f"mistake, outer edge R + r as the distance: {area * 2 * math.pi * (R + r) * L:.4f} L")
print(f"mistake, inner edge R - r as the distance: {area * 2 * math.pi * (R - r) * L:.4f} L")
print(f"mistake, half-disc centroid halfway up at r/2: {half * 2 * math.pi * (r / 2) * L:.4f} L")
print(f"axis through the circle, centre {c} m out: Pappus {cross_pappus * L:.4f} L, solid {cross_true * L:.4f} L")
print(f"figure, ring at 1 m = 400: axis x = 180, tube centre ({180 + 400 * R:.0f}, 120), "
      f"radius {400 * r:.0f}, mirror ({180 - 400 * R:.0f}, 120)")
print(f"figure, half-disc at 1 m = 1000: flat side y = 200, centroid y = {200 - 1000 * ybar:.2f}, "
      f"strip 0.08 m up at y = 120, half-width {w(0.08):.2f} m = {1000 * w(0.08):.2f}")
assert abs(pappus - washers(R, N)) < 1e-7          # two roads, one volume
assert abs(washers(R, N) - exact) < 1e-7           # refining sum against the closed form
assert abs(sphere - 4 / 3 * math.pi * r ** 3) < 1e-8  # Pappus against the sphere formula
assert cross_true - cross_pappus > 0.0005             # the dropped hypothesis bites
print("ALL CHECKS PASS")
