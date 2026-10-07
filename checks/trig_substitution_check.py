# Trig substitution -- the check behind the card.  Standard library only; sin, cos,
# sqrt and log are primitives, and no built-in pi is used.  A pond of radius 3 m:
# its area by x = 3 sin(theta) and by midpoint sums; a relative by x = 3 tan(theta).
import math
R = 3.0

def bisect(fn, lo, hi):                     # a root of fn between lo and hi
    for _ in range(200):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if (fn(lo) > 0) == (fn(m) > 0) else (lo, m)
    return (lo + hi) / 2

def mid(fn, a, b, n):                       # midpoint sum: n strips, height at each centre
    w = (b - a) / n
    return w * sum(fn(a + (k + 0.5) * w) for k in range(n))

quarter = bisect(math.cos, 1.0, 2.0)        # the quarter turn: cos first reaches 0
s, sides = 1.0, 6                           # hexagon in a circle of radius 1: side 1
for _ in range(20):
    s, sides = s / math.sqrt(2 + math.sqrt(4 - s * s)), sides * 2
pi_poly = sides * s / 2                     # half the perimeter, square roots only
root = lambda x: math.sqrt(max(R * R - x * x, 0.0))
F_theta = lambda t: R * R / 2 * (t + math.sin(t) * math.cos(t))   # antiderivative of 9 cos^2
area = 2 * (F_theta(quarter) - F_theta(-quarter))
print(f"pond radius 3 m; quarter turn, first zero of cos: {quarter:.12f}")
print(f"pi from the zero of cos: {2 * quarter:.12f}; from {sides} sides: {pi_poly:.12f}")
print(f"road 1, substitution, 2 x (9/2)(pi/2 + pi/2) = {area:.6f} m^2")
errs = []
for n in (10, 100, 1000, 10000):
    v = mid(lambda x: 2 * root(x), -R, R, n)
    errs.append(v - area)
    print(f"road 2, midpoint sum in x, n = {n:5}: {v:.6f}  error {v - area:.9f}")
th = mid(lambda t: 2 * R * R * math.cos(t) ** 2, -quarter, quarter, 10)
print(f"road 3, midpoint sum in theta, n = 10: {th:.6f}  error {th - area:.9f}")
t1 = bisect(lambda t: R * math.sin(t) - 1.5, -quarter, quarter)   # the branch's own angle
strip, sector, tri = F_theta(t1) - F_theta(0), R * R * t1 / 2, 1.5 * root(1.5) / 2
xs = mid(root, 0, 1.5, 10000)
print(f"strip x = 0 to 1.5: theta = {t1:.6f}; formula {strip:.6f} = sector {sector:.6f}"
      f" + triangle {tri:.6f}; x sum {xs:.6f}")
other = 5 * quarter / 3                     # 5 pi / 6, off the branch
print(f"branch: theta = 5pi/6 gives x = {R * math.sin(other):.6f}; root {root(1.5):.6f};"
      f" 3 cos theta {R * math.cos(other):.6f}")
rel = mid(lambda x: 1 / math.sqrt(9 + x * x), 0, 4, 10000)
sec, tan = math.sqrt(9 + 16) / 3, 4 / 3     # the 3-4-5 triangle at x = 4
print(f"relative, 1/sqrt(9 + x^2) from 0 to 4: sec {sec:.6f} + tan {tan:.6f};"
      f" ln 3 = {math.log(sec + tan):.6f}; x sum {rel:.6f}")
print(f"mistake, dx factor dropped: {2 * R * (math.sin(quarter) - math.sin(-quarter)):.6f}, not {area:.6f}")
print(f"mistake, x limits -3 and 3 kept as angles: {2 * (F_theta(3) - F_theta(-3)):.6f}")
naive = mid(lambda t: R * R * math.cos(t) ** 2, quarter, 3 * quarter, 1000)
true = -mid(root, -R, R, 100000)            # x runs from 3 back to -3
print(f"mistake, root read as 3 cos theta on theta from pi/2 to 3pi/2: {naive:.6f}; true {true:.6f}")
sc, cx, cy = 32, 180, 124                   # figure: 32 px per metre, centre at (180, 124)
print(f"figure, centre ({cx}, {cy}), top ({cx}, {cy - sc * R:.2f}), P ({cx + sc * 1.5:.2f},"
      f" {cy - sc * root(1.5):.2f}), Q ({cx + sc * 1.5:.2f}, {cy}), arc end"
      f" ({cx + 24 * math.sin(t1):.2f}, {cy - 24 * math.cos(t1):.2f})")
assert abs(2 * quarter - pi_poly) < 1e-9                        # radian pi meets polygon pi
assert abs(errs[3]) < 1e-4 and abs(th - R * R * pi_poly) < 1e-9   # road 1 meets road 2; road 3 meets 9 pi
assert abs(xs - strip) < 1e-6 and abs(errs[3]) < abs(errs[2]) / 20
assert abs(rel - math.log(sec + tan)) < 1e-6 and abs(naive + true) < 1e-6   # tangent relative; off-branch sign flip
print("ALL CHECKS PASS")
