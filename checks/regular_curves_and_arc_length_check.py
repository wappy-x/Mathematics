# Regular curve and arc length -- the check behind the card.  Standard library
# only; math gives sqrt, log, cos, sin, pi as primitives, every sum and solver is here.
# A coaster's airtime hill: rail centre line y = 20 (1 - (x/30)^2) metres over
# ground positions x = -30 .. 30 m.  Its length, and its rail-metre marks.
from math import sqrt, log, pi, cos, sin

H, W = 20.0, 30.0                       # hill height and half-width, metres
k = 2 * H / (W * W)                     # slope per metre of x: 2/45
def y(x):  return H * (1 - (x / W) ** 2)
def yp(x): return -k * x                # slope dy/dx
def asinh(z): return log(z + sqrt(1 + z * z))
def F(x):  return (k * x * sqrt(1 + (k * x) ** 2) + asinh(k * x)) / (2 * k)
def s_of_x(x): return F(x) - F(-W)      # rail metres from the left foot
L = s_of_x(W)                           # road one: closed form

def simpson(g, a, b, n):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3

def speed_u(u):                         # second clock u: x = 15u + 15u^3, regular
    x = 15 * u + 15 * u ** 3
    return sqrt(1 + yp(x) ** 2) * (15 + 45 * u * u)
L_x = simpson(lambda x: sqrt(1 + yp(x) ** 2), -W, W, 1000)      # road two
L_u = simpson(speed_u, -1.0, 1.0, 1000)                         # road three
def chords(n):                                                  # road four: n straight chords
    xs = [-W + 2 * W * i / n for i in range(n + 1)]
    return sum(sqrt((xs[i] - xs[i - 1]) ** 2 + (y(xs[i]) - y(xs[i - 1])) ** 2) for i in range(1, n + 1))
L_c1, L_c = chords(1024), chords(4096)

def x_newton(s):                        # invert s(x) by Newton: ds/dx >= 1, never 0
    x = -W + 2 * W * s / L
    for _ in range(50):
        x -= (s_of_x(x) - s) / sqrt(1 + yp(x) ** 2)
    return x
def x_bisect(s):                        # invert on the u clock by bisection
    lo, hi = -1.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if simpson(speed_u, -1.0, mid, 200) < s: lo = mid
        else: hi = mid
    u = (lo + hi) / 2
    return 15 * u + 15 * u ** 3
def T(x):                               # unit tangent, travelling left to right
    r = sqrt(1 + yp(x) ** 2)
    return 1 / r, yp(x) / r

print(f"hill {H:.0f} m high, {2 * W:.0f} m of ground, y = 20(1 - (x/30)^2), slope -2x/45")
print(f"at the right foot: slope {yp(W):.6f}, stretch sqrt(1 + 16/9) = {sqrt(1 + yp(W) ** 2):.6f}, "
      f"ln 3 = {log(3):.6f}")
print(f"20/9 = {(4 / 3) * (5 / 3):.6f}; 20/9 + ln 3 = {20 / 9 + log(3):.6f}; 45/4 = {1 / (2 * k):.2f}")
print(f"half hill 45/4 x (20/9 + ln 3) = {F(W):.6f} m; whole hill closed form {L:.6f} m, "
      f"{L - 2 * W:.2f} m more than the ground")
print(f"Simpson on the x clock, 1000 strips: {L_x:.6f} m")
print(f"Simpson on the u clock, x = 15u + 15u^3, 1000 strips: {L_u:.6f} m")
print(f"1024 chords: {L_c1:.6f} m, short by {(L - L_c1) * 1e6:.3f} micrometres")
print(f"4096 chords: {L_c:.6f} m, short by {(L - L_c) * 1e6:.3f} micrometres, "
      f"{(L - L_c1) / (L - L_c):.2f} times less")
print("chart, rail metres s at ground x = -30..30 step 10:",
      " ".join(f"{s_of_x(x):.2f}" for x in range(-30, 31, 10)))
marks, prev = [], (-W, 0.0)
for j in range(1, 8):
    s = 10.0 * j
    xa, xb = x_newton(s), x_bisect(s)
    h = 1e-3
    pa, pb = (x_newton(s + h), y(x_newton(s + h))), (x_newton(s - h), y(x_newton(s - h)))
    sp = sqrt((pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2) / (2 * h)
    ch = sqrt((xa - prev[0]) ** 2 + (y(xa) - prev[1]) ** 2)
    tx, ty = T(xa)
    print(f"mark {s:4.1f} m: x = {xa:8.4f} (bisection {xb:8.4f}), height {y(xa):7.4f}, "
          f"T = ({tx:.4f}, {ty:.4f}), speed {sp:.6f}, chord from last {ch:.4f}")
    marks.append((xa, xb, sp, ch))
    prev = (xa, y(xa))
gap = max(abs(xa - xb) for xa, xb, _, _ in marks)
print(f"largest gap between the two inversions: {gap * 1e6:.1f} micrometres")
tx, ty = T(W)
print(f"unit tangent at the right foot: ({tx:.6f}, {ty:.6f})")
steps = [s_of_x(-W + 10 * (i + 1)) - s_of_x(-W + 10 * i) for i in range(6)]
print("mistake 1, equal 10 m ground steps, rail in each:", " ".join(f"{d:.3f}" for d in steps))
err = max(abs(s_of_x(-W + 2 * W * 10 * j / L) - 10 * j) for j in range(1, 8))
print(f"mistake 2, marks spaced in proportion to ground: worst error {err:.3f} m of rail")
def cusp_v(t): return 2 * t, 3 * t * t           # velocity of (t^2, t^3)
def cusp_T(t):
    vx, vy = cusp_v(t)
    return vx / sqrt(vx * vx + vy * vy), vy / sqrt(vx * vx + vy * vy)
a, b = cusp_T(-0.001), cusp_T(0.001)
cusp_len = (13 ** 1.5 - 8) / 27
cusp_simp = simpson(lambda t: sqrt(sum(c * c for c in cusp_v(t))), 0.0, 1.0, 1000)
print(f"cusp (t^2, t^3): speed at t = 0 is {sqrt(sum(c * c for c in cusp_v(0.0))):.1f}; "
      f"T at t = -0.001 ({a[0]:.4f}, {a[1]:.4f}), at t = +0.001 ({b[0]:.4f}, {b[1]:.4f})")
print(f"cusp: dt/ds at t = 0.001 is {1 / sqrt(sum(c * c for c in cusp_v(0.001))):.1f}; "
      f"length t = 0..1 closed {cusp_len:.6f}, Simpson {cusp_simp:.6f}")
print(f"one straight rail, two clocks: (t, t) speed at 0 {sqrt(1 + 1):.6f}; "
      f"(t^3, t^3) speed at 0 {sqrt(2 * (3 * 0.0 ** 2) ** 2):.6f}")
turn = sqrt((2 * pi * 3) ** 2 + 12 ** 2)               # corkscrew: closed form
def turn_chords(n):                                    # corkscrew: n chords per turn
    pts = [(3 * cos(2 * pi * i / n), 3 * sin(2 * pi * i / n), 12 * i / n) for i in range(n + 1)]
    return sum(sqrt(sum((p - q) ** 2 for p, q in zip(pts[i], pts[i - 1]))) for i in range(1, n + 1))
turn_c1, turn_c = turn_chords(90), turn_chords(360)
print(f"corkscrew, radius 3 m, 12 m per turn: circle part {2 * pi * 3:.4f} m, {turn:.4f} m of rail per turn")
print(f"corkscrew chords: 90 give {turn_c1:.4f} m, short by {(turn - turn_c1) * 1e3:.2f} mm; "
      f"360 give {turn_c:.4f} m, short by {(turn - turn_c) * 1e3:.2f} mm")
print(f"try: 24 m per turn gives {sqrt((2 * pi * 3) ** 2 + 24 ** 2):.2f} m of rail per turn, "
      f"not twice {turn:.4f} = {2 * turn:.2f} m")
assert abs(L - L_x) < 1e-9                             # closed form against Simpson
assert abs(L - L_u) < 1e-9                             # a second clock, the same length
assert 0 < L - L_c < 1e-4                              # chords close in from below,
assert abs((L - L_c1) / (L - L_c) - 16) < 0.1          # 16 times closer for 4 times the chords
assert gap < 1e-6                                      # two inversions agree
assert all(abs(sp - 1) < 1e-6 for _, _, sp, _ in marks)     # unit speed in rail metres
assert all(9.9 < ch < 10 for _, _, _, ch in marks)          # a chord undershoots its arc
assert abs(cusp_len - cusp_simp) < 1e-9               # cusp length: closed form, Simpson
assert a[0] < -0.99                                    # the cusp flips the tangent:
assert b[0] > 0.99                                     # back, then forward
assert 0 < turn - turn_c < 1e-3                        # corkscrew: chords from below,
assert abs((turn - turn_c1) / (turn - turn_c) - 16) < 0.1   # again 16 times closer
print("ALL CHECKS PASS")
