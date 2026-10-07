# Derivatives of sine and cosine -- the check behind the card.  math.sin and
# math.cos are primitives; every derivative here comes from this script's own
# difference quotient.  A crank of radius 4 cm turns at 50 radians a second;
# a slotted yoke makes the piston's height y = 4 sin x cm at crank angle x.
import math
R, W, L, X = 4.0, 50.0, 14.0, math.pi / 6       # cm, rad/s, cm, 30 degrees

def slope(f, x, h):                             # road two: rise over run
    return (f(x + h) - f(x)) / h

def c2(v):                                      # print a tiny float as 0.00
    return "0.00" if abs(v) < 0.005 else f"{v:.2f}"

height, side = (lambda x: R * math.sin(x)), (lambda x: R * math.cos(x))
tan, sec = (lambda x: math.sin(x) / math.cos(x)), (lambda x: 1 / math.cos(x))
rod = lambda x: R * math.sin(x) + math.sqrt(L * L - (R * math.cos(x)) ** 2)
s, c = math.sin(X), math.cos(X)
for h in (0.5, 0.1, 0.01):
    q, k = math.sin(h) / h, (math.cos(h) - 1) / h
    assert math.cos(h) < q < 1 and abs(k) <= h / 2     # the sandwich and its twin
    print(f"sandwich h = {h:.2f}: cos h = {math.cos(h):.6f} < sin h / h = {q:.6f} < 1; (cos h - 1) / h = {k:.6f}")
g = math.sqrt(0.002)
print(f"within 0.001 of 1: h below {g:.6f} is enough; at h = 0.04, cos h = {math.cos(0.04):.6f}, sin h / h = {math.sin(0.04) / 0.04:.6f}")
split = s * (math.cos(0.1) - 1) / 0.1 + c * math.sin(0.1) / 0.1
direct = (math.sin(X + 0.1) - s) / 0.1
assert abs(split - direct) < 1e-12                  # the addition formula at work
print(f"split at h = 0.10: {s:.6f} x {(math.cos(0.1) - 1) / 0.1:.6f} + {c:.6f} x {math.sin(0.1) / 0.1:.6f} = {split:.6f}; direct quotient {direct:.6f}")
print(f"crank at 30 deg: sin x = {s:.6f}, cos x = {c:.6f}; piston height {R * s:.6f} cm, pin sideways {R * c:.6f} cm")
rules = [("height 4 sin x", height, R * c), ("sideways 4 cos x", side, -R * s),
         ("tan x", tan, 1 / (c * c)), ("sec x", sec, s / (c * c))]
for name, f, rule in rules:
    q = [slope(f, X, h) for h in (0.1, 0.01, 0.001)]
    assert abs(slope(f, X, 1e-6) - rule) < 1e-5     # formula against quotient
    print(f"{name} at 30 deg: rule {rule:.6f}; quotients h = 0.1, 0.01, 0.001: {q[0]:.6f}, {q[1]:.6f}, {q[2]:.6f}")
v = slope(lambda t: height(W * t), X / W, 1e-7)
rr = R * c + R * R * c * s / math.sqrt(L * L - (R * c) ** 2)
qr = slope(rod, X, 1e-7)
assert abs(v - R * c * W) < 1e-3 and abs(qr - rr) < 1e-5   # speed and rod engine, two roads each
print(f"piston speed at 30 deg: rule 4 cos x times 50 = {R * c * W:.3f} cm/s; time quotient {v:.3f} cm/s")
print(f"rod engine, rod 14 cm: rule {rr:.5f} cm/rad; quotient {qr:.5f}; yoke {R * c:.5f}")
deg = slope(lambda u: math.sin(u * math.pi / 180), 0.0, 1e-6)
print(f"mistake, degrees: rate of sine at 0 is {deg:.6f} per degree, not 1; sign dropped: sideways +{R * s:.6f} for {-R * s:.6f}")
print(f"mistake, tan squared: {tan(X) ** 2:.6f} for {1 / (c * c):.6f}; straddling 90 deg, h = 0.01: {(tan(math.pi / 2 + 0.01) - tan(math.pi / 2 - 0.01)) / 0.02:.2f}")
grid = [k * math.pi / 4 for k in range(9)]
print("chart height cm:", ", ".join(c2(height(x)) for x in grid))
print("chart rate cm/rad:", ", ".join(c2(slope(height, x, 1e-6)) for x in grid))
tip = (120 + 20 * R * c - 40 * s, 130 - 20 * R * s - 40 * c)
print(f"figure, centre (120.00, 130.00), pin ({120 + 20 * R * c:.2f}, {130 - 20 * R * s:.2f}), arrow tip ({tip[0]:.2f}, {tip[1]:.2f}), rise {40 * c / 20:.2f} cm")
print("ALL CHECKS PASS")
