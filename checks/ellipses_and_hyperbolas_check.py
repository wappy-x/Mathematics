# Ellipses and hyperbolas -- the check behind the card.  Only sqrt is imported.
# A planet's orbit: long half-axis a = 100 (million km), eccentricity e = 0.2, the
# Sun at the focus (20, 0).  A comet's hyperbola shares the foci; difference 32.
from math import sqrt
a, e = 100.0, 0.2
c = a * e                                     # road one: the standard-form formulas
b = sqrt(a * a - c * c)
def d(x, y, fx): return sqrt((x - fx) ** 2 + y * y)          # distance to focus (fx, 0)
def total(x, y): return d(x, y, -c) + d(x, y, c)             # the ellipse's sum rule
def diff(x, y): return d(x, y, -c) - d(x, y, c)              # the hyperbola's difference rule
def halve(f, target, lo, hi):                 # road two: find t with f(t) = target, f rising
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return (lo + hi) / 2
def classify(P, Q, U, V, W):                  # P x^2 + Q y^2 + U x + V y + W = 0, no xy term
    if P * Q == 0: return "parabola", 0.0, 0.0
    K = -W + U * U / (4 * P) + V * V / (4 * Q)                 # after completing both squares
    s, t = K / P, K / Q                                        # the two denominators
    if s > 0 and t > 0: return ("circle" if s == t else "ellipse"), max(s, t), min(s, t)
    if s * t < 0: return "hyperbola", max(s, t), -min(s, t)
    return "no curve, a point or two lines", 0.0, 0.0
va, hb = halve(lambda x: total(x, 0), 2 * a, c, 3 * a), halve(lambda y: total(0, y), 2 * a, 0, 2 * a)
yP = halve(lambda y: total(60, y), 2 * a, 0, 2 * a)
sun = [d(x, halve(lambda y: total(x, y), 2 * a, 0, 2 * a), c) for x in (a * (i - 1000) / 1000 for i in range(2001))]
print(f"orbit: a = {a:.2f}, e = {e:.2f}, c = ae = {c:.2f}, b = sqrt(a^2 - c^2) = {b:.2f}")
print(f"formulas: perihelion a - c = {a - c:.2f}, aphelion a + c = {a + c:.2f}, sum 2a = {2 * a:.2f}")
print(f"halving on the sum rule: vertex x = {va:.2f}, height at x = 0: {hb:.2f}, T = (60.00, {yP:.2f}) "
      f"at {d(60, yP, -c):.2f} + {d(60, yP, c):.2f}")
print(f"scan of 2001 points: nearest the Sun {min(sun):.2f}, farthest {max(sun):.2f}; "
      f"x^2/a^2 + y^2/b^2 at T = {60 ** 2 / a ** 2 + yP ** 2 / b ** 2:.6f}")
print(f"directrix x = a/e = {a / e:.2f}; at T {d(60, yP, c):.2f} / {a / e - 60:.2f} = {d(60, yP, c) / (a / e - 60):.4f}")
h = 16.0; k = sqrt(c * c - h * h)             # the comet: half the difference, and its b
hv, x12 = halve(lambda x: diff(x, 0), 2 * h, 0, c), halve(lambda x: diff(x, 12), 2 * h, 0, 1000)
x3k = halve(lambda x: diff(x, 3000), 2 * h, 0, 10000)
print(f"comet: a = {h:.2f}, b = sqrt({c * c:.2f} - {h * h:.2f}) = {k:.2f}, e = c/a = {c / h:.4f}, closest c - a = {c - h:.2f}")
print(f"halving on the difference rule: vertex x = {hv:.2f}, at y = 12 x = {x12:.2f} (formula {h * sqrt(1 + 144 / k ** 2):.2f}), "
      f"left branch {diff(-x12, 12):.2f}, y/x at y = 3000: {3000 / x3k:.4f}")
print(f"comet directrix x = a/e = {h * h / c:.2f}; at the vertex {c - hv:.2f} / {hv - h * h / c:.2f} = {(c - hv) / (hv - h * h / c):.4f}")
ecc, ax = {}, {}
for name0, co in (("orbit", (24, 25, 960, 0, -230400)), ("comet", (9, -16, 0, 0, -2304)),
                  ("round orbit", (1, 1, 0, 0, -10000)), ("escaping comet", (0, 1, -16, 0, -64))):
    name, A2, B2 = classify(*co)
    ecc[name0], ax[name0] = (1.0 if name == "parabola" else sqrt(1 - B2 / A2 if name != "hyperbola" else 1 + B2 / A2)), A2
    print(f"{name0}, P, Q, U, V, W = {', '.join(map(str, co))}: {name}, "
          + (f"a^2 = {A2:.2f}, b^2 = {B2:.2f}, " if A2 else "") + f"e = {ecc[name0]:.4f}")
print(f"mistakes: ellipse c from a^2 + b^2 = {sqrt(a * a + b * b):.2f}; comet c from a^2 - b^2 = {sqrt(h * h - k * k):.2f}; "
      f"perihelion as a - b = {a - b:.2f}")
print(f"figure, orbit, 1 million km = 1 unit: centre (180.00, 120.00), rx {a:.2f}, ry {b:.2f}, empty focus ({180 - c:.2f}, 120.00), "
      f"Sun ({180 + c:.2f}, 120.00), T ({180 + 60:.2f}, {120 - yP:.2f})")
print(f"figure, comet, 1 million km = 3 units: vertices ({180 - 3 * h:.2f}, 120.00) ({180 + 3 * h:.2f}, 120.00), foci ({180 - 3 * c:.2f}, 120.00) "
      f"({180 + 3 * c:.2f}, 120.00), asymptote ends ({180 - 3 * 36 * h / k:.2f}, 12.00) ({180 + 3 * 36 * h / k:.2f}, 228.00)")
br = [(halve(lambda x: diff(x, y), 2 * h, 0, 1000), y) for y in range(-36, 37, 6)]
print("figure, right branch:", " ".join(f"{180 + 3 * x:.2f},{120 - 3 * y:.2f}" for x, y in br))
print("figure, left branch:", " ".join(f"{180 - 3 * x:.2f},{120 - 3 * y:.2f}" for x, y in br))
assert abs(hb - b) < 1e-9                                   # halving on the sum rule meets b
assert abs(min(sun) - (a - c)) + abs(max(sun) - (a + c)) < 1e-9     # nearest, farthest
assert abs(x12 - h * sqrt(1 + 144 / k ** 2)) < 1e-9           # halving on the difference rule
assert abs(ecc["orbit"] - c / va) + abs(ecc["comet"] - c / hv) + abs(sqrt(ax["orbit"]) - va) + abs(sqrt(ax["comet"]) - hv) < 1e-9  # equation vs geometry
print("ALL CHECKS PASS")
