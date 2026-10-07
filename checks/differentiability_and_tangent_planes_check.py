# Tangent planes -- the check behind the card.  A hill's height is
# f(x, y) = 80 - 0.001x^2 - 0.0005xy - 0.002y^2 metres, x metres east and y
# metres north of a survey peg.  Road one: slopes by formula, remainder expanded
# by hand.  Road two: slopes from difference quotients, heights evaluated
# directly.  Then the crease g(x, y) = xy / sqrt(x^2 + y^2), whose slopes lie.
from math import sqrt, cos, sin, pi

def f(x, y): return 80 - 0.001 * x * x - 0.0005 * x * y - 0.002 * y * y
def fx(x, y): return -0.002 * x - 0.0005 * y           # slope east, by formula
def fy(x, y): return -0.0005 * x - 0.004 * y           # slope north, by formula
def hand(h, k): return -(0.001 * h * h + 0.0005 * h * k + 0.002 * k * k)
def g(x, y): return 0.0 if x == 0 and y == 0 else x * y / sqrt(x * x + y * y)

A, B = 100.0, 50.0
Z, SX, SY = f(A, B), fx(A, B), fy(A, B)
def plane(x, y): return Z + SX * (x - A) + SY * (y - B)
print(f"hill: f(100, 50) = {Z:.6f} m; slopes by formula f_x = {SX:.6f}, f_y = {SY:.6f}")
qs = [((f(A + s, B) - Z) / s, (f(A, B + s) - Z) / s) for s in (1, 0.1, 0.01, 1e-6)]
print("forward differences, steps 1, 0.1, 0.01: f_x " + ", ".join(f"{q[0]:.6f}" for q in qs[:3])
      + "; f_y " + ", ".join(f"{q[1]:.6f}" for q in qs[:3]))
print(f"normal (-f_x, -f_y, 1) = ({-SX:.3f}, {-SY:.3f}, 1)")
east, north = f(110, 50) - Z, f(110, 70) - f(110, 50)
print(f"two legs: east {east:.6f} = 10 x {fx(105, 50):.6f}, north {north:.6f} = 20 x {fy(110, 60):.6f},"
      f" total {east + north:.6f}")
assert abs(qs[3][0] - SX) + abs(qs[3][1] - SY) < 1e-5 and abs(east - 10 * fx(105, 50)) + abs(north - 20 * fy(110, 60)) < 1e-9
for h, k in ((10, 20), (1, 2), (0.1, 0.2)):
    rho, act = sqrt(h * h + k * k), f(A + h, B + k)
    rem = act - plane(A + h, B + k)
    assert abs(rem - hand(h, k)) < 1e-9               # direct height minus plane = hand expansion
    print(f"step ({h}, {k}): rho {rho:.6f}, actual {act:.6f}, plane {plane(A + h, B + k):.6f},"
          f" remainder {rem:.6f}, by hand {hand(h, k):.6f}, ratio {rem / rho:.6f}")
R0 = 0.44
dirs = [2 * pi * i / 360 for i in range(360)]
worst = max(abs(f(A + R0 * cos(t), B + R0 * sin(t)) - plane(A + R0 * cos(t), B + R0 * sin(t))) for t in dirs) / R0
print(f"worst ratio over 360 directions at rho 0.44 m: {worst:.6f}; hand bound 0.00225 x 0.44 = {0.00225 * R0:.6f}")
assert worst < 0.001 and worst <= 0.00225 * R0
for t in (0.1, 0.01, 0.001):
    ax, ay = (g(t, 0) - g(0, 0)) / t, (g(0, t) - g(0, 0)) / t
    rho = sqrt(2 * t * t)
    ratio, slope = g(t, t) / rho, (g(t + t * 1e-6, t) - g(t, t)) / (t * 1e-6)
    print(f"crease t = {t}: axis quotients {ax:.1f}, {ay:.1f}; g(t, t) = {g(t, t):.6f}, rho {rho:.6f},"
          f" ratio {ratio:.6f}; east slope at (t, t) {slope:.6f}")
    assert ax == ay == 0 and abs(ratio - 0.5) < 1e-9 and abs(slope - 1 / (2 * sqrt(2))) < 1e-5
S = [-2, -1, 0, 1, 2, 3]
print("chart, steps of (10 m east, 20 m north): " + ", ".join(str(s) for s in S))
print("chart, hill (m): " + ", ".join(f"{f(A + 10 * s, B + 20 * s):.2f}" for s in S))
print("chart, plane (m): " + ", ".join(f"{plane(A + 10 * s, B + 20 * s):.2f}" for s in S))
print(f"mistake, plane without the shift, at (110, 70): {Z + SX * 110 + SY * 70:.6f} m")
