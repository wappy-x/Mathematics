# Polar coordinates -- the check behind the card.  Standard library only.
# Radar: a plane 40 km out on bearing 120 deg. Grid: x km east, y km north.
from math import sin, cos, atan, acos, sqrt, pi
D = pi / 180                                   # one degree, in radians

def forward(r, theta):                         # (r, theta in deg) -> (x, y)
    return r * cos(theta * D), r * sin(theta * D)
def angle_by_arctan(x, y):                     # road one back: arctan(y/x), quadrant fixed
    if x == 0:
        return 90.0 if y > 0 else 270.0
    t = atan(y / x) / D
    return t + 180 if x < 0 else (t + 360 if y < 0 else t)

def angle_by_arccos(x, y):                     # road two back: arccos(x/r), sign of y picks the half
    t = acos(x / sqrt(x * x + y * y)) / D
    return t if y >= 0 else 360 - t

def reach(theta):                              # coverage curve r = 25(1 + cos theta), km
    return 25 * (1 + cos(theta * D))
def inside_by_grid(x, y):                      # the same curve with no angle: r^2 <= 25(r + x)
    r = sqrt(x * x + y * y)
    return r * r <= 25 * (r + x)
yn = lambda b: "yes" if b else "no"
r1, bearing = 40.0, 120.0
theta1 = (90 - bearing) % 360                  # bearing -> maths angle
xa, ya = forward(r1, theta1)                   # road one: through the maths angle
xb, yb = r1 * sin(bearing * D), r1 * cos(bearing * D)   # road two: east = r sin b, north = r cos b
print(f"plane 1: range {r1:.0f} km, bearing {bearing:.0f} deg -> 90 - 120 = {90 - bearing:.0f} -> maths angle {theta1:.0f} deg")
print(f"road 1 (via maths angle): x = {xa:.6f} km east, y = {ya:.6f} km north")
print(f"road 2 (via bearing):     x = {xb:.6f} km east, y = {yb:.6f} km north")
back = {}
for name, (x, y) in (("plane 1", (xa, ya)), ("plane 2", (-30.0, -40.0))):
    r, t1, t2 = sqrt(x * x + y * y), angle_by_arctan(x, y), angle_by_arccos(x, y)
    back[name] = (r, t1, t2)
    print(f"back, {name} at ({x:.3f}, {y:.3f}): r = {r:.6f} km; arctan+fix {t1:.6f} deg;"
          f" arccos+sign {t2:.6f} deg; bearing {(90 - t1) % 360:.6f} deg")
print("reach 25(1 + cos theta) at theta 0, 60, 90, 120, 180 deg:",
      " ".join(f"{reach(t):.6f}" for t in (0, 60, 90, 120, 180)), "km")
cover = []
for name, (x, y) in (("plane 1", (xa, ya)), ("plane 2", (-30.0, -40.0))):
    r, t = back[name][0], back[name][1]
    cover.append((r <= reach(t), inside_by_grid(x, y)))
    print(f"reach toward {name} (theta {t:.2f}): {reach(t):.6f} km; inside by polar test:"
          f" {yn(cover[-1][0])}; by grid test: {yn(cover[-1][1])}")
wx, wy = forward(r1, bearing)
print(f"mistake 1, bearing used as maths angle: x = {wx:.6f}, y = {wy:.6f}")
naive = atan(-40 / -30) / D
print(f"mistake 2, arctan(y/x) for plane 2 with no fix: {naive:.6f} deg, bearing {(90 - naive) % 360:.6f}")
print(f"mistake 3, 330 read as radians: x = {r1 * cos(330):.6f}, y = {r1 * sin(330):.6f}")
wide = forward(reach(60), 60)
print(f"figure 1, 1 km = 4 units, origin (140, 60): plane ({140 + 4 * xa:.3f}, {60 - 4 * ya:.3f})")
print(f"figure 2, 1 km = 3 units, origin (120, 105): plane 1 ({120 + 3 * xa:.3f}, {105 - 3 * ya:.3f}),"
      f" plane 2 ({120 - 90:.3f}, {105 + 120:.3f}), 60 deg point ({120 + 3 * wide[0]:.3f}, {105 - 3 * wide[1]:.3f})")
assert max(abs(xa - xb), abs(ya - yb)) < 1e-9 and abs(xa - 20 * sqrt(3)) < 1e-9 and abs(yb + 20) < 1e-9
assert all(abs(t1 - t2) < 1e-9 for _, t1, t2 in back.values()) and abs(back["plane 1"][1] - theta1) < 1e-9
assert max(abs(a - b) for a, b in zip(forward(*back["plane 2"][:2]), (-30, -40))) < 1e-9
assert cover == [(True, True), (False, False)]
print("ALL CHECKS PASS")
